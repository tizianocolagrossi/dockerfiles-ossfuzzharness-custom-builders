#include "libhfnetdriver/netdriver.h"

#include <stdatomic.h>
#include <arpa/inet.h>
#include <errno.h>
#include <inttypes.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/un.h>
#include <unistd.h>
#if defined(_HF_ARCH_LINUX)
#include <sched.h>
#endif /* defined(_HF_ARCH_LINUX) */
#if defined(__FreeBSD__)
#define SOL_TCP IPPROTO_TCP
#endif

#include "honggfuzz.h"
#include "libhfcommon/common.h"
#include "libhfcommon/files.h"
#include "libhfcommon/log.h"
#include "libhfcommon/ns.h"
#include "libhfcommon/util.h"

__attribute__((visibility("default"))) __attribute__((used))
const char *const LIBHFNETDRIVER_module_netdriver = _HF_NETDRIVER_SIG;

#define HFND_TCP_PORT_ENV     "HFND_TCP_PORT"
#define HFND_SOCK_PATH_ENV    "HFND_SOCK_PATH"
#define HFND_SKIP_FUZZING_ENV "HFND_SKIP_FUZZING"

/* Define this to use receiving timeouts
#define HFND_RECVTIME 10
*/

static char *initial_server_argv[] = {"fuzzer", NULL};

static struct {
    int    argc_server;
    char **argv_server;
    struct {
        struct sockaddr_storage addr;
        socklen_t               slen;
        int                     type;     /* as per man 2 socket */
        int                     protocol; /* as per man 2 socket */
    } dest_addr;
} hfnd_globals = {
    .argc_server = 1,
    .argv_server = initial_server_argv,
    .dest_addr =
        {
            .addr.ss_family = AF_UNSPEC,
        },
};

extern int HonggfuzzNetDriver_main(int argc, char **argv);

static void *netDriver_mainProgram(void *unused HF_ATTR_UNUSED) {
    int ret = HonggfuzzNetDriver_main(hfnd_globals.argc_server, hfnd_globals.argv_server);
    LOG_I("Honggfuzz Net Driver (pid=%d): HonggfuzzNetDriver_main() function exited with: %d",
        (int)getpid(), ret);
    _exit(ret);
}

static void *netDriver_startOriginalProgramInThread(void *unused HF_ATTR_UNUSED) {
    pthread_t      t;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setstacksize(&attr, 1024ULL * 1024ULL * 8ULL);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);

    if (pthread_create(&t, &attr, netDriver_mainProgram, NULL) != 0) {
        PLOG_F("Couldn't create the 'netDriver_mainProgram' thread");
    }
    pthread_attr_destroy(&attr);
    return (void *) 0x0;
}

#if defined(_HF_ARCH_LINUX)
static void netDriver_mountTmpfs(const char *path) {
    if (mkdir(path, 0755) == -1 && errno != EEXIST) {
        PLOG_F("mkdir('%s', 0755)", path);
    }
    if (!nsMountTmpfs(path, NULL)) {
        LOG_F("nsMountTmpfs('%s') failed", path);
    }
}
#endif /* defined(_HF_ARCH_LINUX) */

/**
 * @brief Initializes network namespaces and tmpfs for NetDriver (Linux-only).
 *
 * Ensures one-time setup of user, net, mount, IPC, and UTS namespaces,
 * brings up the loopback interface, and mounts tmpfs (both dynamic and legacy paths).
 * Logs a warning if namespaces are unsupported on non-Linux platforms.
 */
static void netDriver_initNsIfNeeded(void) {
    static bool initialized = false;
    if (initialized) {
        return;
    }
    initialized = true;

    #if defined(_HF_ARCH_LINUX)
    if (!nsEnter(CLONE_NEWUSER | CLONE_NEWNET | CLONE_NEWNS | CLONE_NEWIPC | CLONE_NEWUTS)) {
        LOG_F("nsEnter(CLONE_NEWUSER|CLONE_NEWNET|CLONE_NEWNS|CLONE_NEWIPC|CLONE_NEWUTS) failed");
    }
    if (!nsIfaceUp("lo")) {
        LOG_F("nsIfaceUp('lo') failed");
    }

    char tmpdir[PATH_MAX] = {};
    int  ret              = HonggfuzzNetDriverTempdir(tmpdir, sizeof(tmpdir));
    if (ret < 0) {
        LOG_F("HonggfuzzNetDriverTempdir failed");
    }

    if (strlen(tmpdir) > 0) {
        netDriver_mountTmpfs(tmpdir);
    }

    /* Legacy path */
    netDriver_mountTmpfs(HFND_TMP_DIR_OLD);

    return;
    #endif /* defined(_HF_ARCH_LINUX) */
    LOG_W("Honggfuzz Net Driver (pid=%d): Namespaces not enabled for this OS platform",
        (int)getpid());
}

/*
 * Try to bind the client socket to a random loopback address, to avoid problems with exhausted
 * ephemeral ports. We run out of them, because the TIME_WAIT state is imposed on recently closed
 * TCP connections originating from the same IP address (127.0.0.1), and connecting to the singular
 * IP address (again, 127.0.0.1) on a single port
 */
static void netDriver_bindToRndLoopback(int sock, sa_family_t sa_family) {
    if (sa_family != AF_INET) {
        return;
    }
    const struct sockaddr_in bsaddr = {
        .sin_family      = AF_INET,
        .sin_port        = htons(0),
        .sin_addr.s_addr = htonl((((uint32_t)util_rnd64()) & 0x00FFFFFF) | 0x7F000000),
    };
    if (bind(sock, (struct sockaddr *)&bsaddr, sizeof(bsaddr)) == -1) {
        PLOG_W("Could not bind to a random IPv4 Loopback address");
    }
}

/**
 * @brief Creates, configures, and connects a socket to a given address.
 *
 * Opens a socket of the specified type and protocol, applies common options
 * (e.g. SO_REUSEADDR, TCP_NODELAY, TCP_QUICKACK), binds it to a random loopback
 * address, and attempts to connect to the given address.
 *
 * @return Connected socket descriptor on success, -1 on failure.
 */
static int netDriver_sockConnAddr(
    const struct sockaddr *addr, socklen_t socklen, int type, int protocol) {
    
    printf("in sockConnAddr socket family %d, type %d, proto %d\n", addr->sa_family, type, protocol);
    int sock = socket(addr->sa_family, type, protocol);
    if (sock == -1) {
        PLOG_W("socket(family=%d for dst_addr='%s', type=%d, protocol=%d)", addr->sa_family,
            files_sockAddrToStr(addr, socklen), type, protocol);
        return -1;
    }
    if (addr->sa_family == AF_INET || addr->sa_family == AF_INET6) {
        int val = 1;
        if (setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &val, (socklen_t)sizeof(val)) == -1 &&
            errno == ENOPROTOOPT) {
            PLOG_W("setsockopt(sock=%d, SOL_SOCKET, SO_REUSEADDR, %d)", sock, val);
        }
    #if defined(SOL_TCP) && defined(TCP_NODELAY)
        if (setsockopt(sock, SOL_TCP, TCP_NODELAY, &val, (socklen_t)sizeof(val)) == -1) {
            PLOG_W("setsockopt(sock=%d, SOL_TCP, TCP_NODELAY, %d)", sock, val);
        }
    #endif /* defined(SOL_TCP) && defined(TCP_NODELAY) */
    #if defined(SOL_TCP) && defined(TCP_QUICKACK)
        val = 1;
        if (setsockopt(sock, SOL_TCP, TCP_QUICKACK, &val, (socklen_t)sizeof(val)) == -1) {
            PLOG_D("setsockopt(sock=%d, SOL_TCP, TCP_QUICKACK, %d)", sock, val);
        }
    #endif /* defined(SOL_TCP) && defined(TCP_QUICKACK) */
    }

    netDriver_bindToRndLoopback(sock, addr->sa_family);

    LOG_D("Connecting to '%s'", files_sockAddrToStr(addr, socklen));
    if (TEMP_FAILURE_RETRY(connect(sock, addr, socklen)) == -1) {
        int saved_errno = errno;
        PLOG_D("connect(addr='%s', type=%d protocol=%d)", files_sockAddrToStr(addr, socklen), type,
            protocol);
        close(sock);
        errno = saved_errno;
        return -1;
    }
    return sock;
}

/*
 * The return value is a number of arguments passed returned to libfuzzer (if used)
 *
 * Define this function in your code to describe which arguments are passed to the fuzzed
 * TCP server, and which to the fuzzing engine.
 */
__attribute__((weak)) int HonggfuzzNetDriverArgsForServer(
    int argc, char **argv, int *server_argc, char ***server_argv) {
    *server_argc = argc;
    *server_argv = &argv[0];
    return argc;
}

/*
 * Retrieve path where to mount temporary filesystem (tmpfs) for the duration
 * of a main program. Return empty array (length 0) to not use tmpfs.
 */
__attribute__((weak)) int HonggfuzzNetDriverTempdir(char *str, size_t size) {
    return snprintf(str, size, "%s", HFND_TMP_DIR);
}

/* Put a custom sockaddr here (e.g. based on AF_UNIX), sety *type and *protocol as per man 2 socket
 */
__attribute__((weak)) socklen_t HonggfuzzNetDriverServerAddress(
    struct sockaddr_storage *addr HF_ATTR_UNUSED, int *type HF_ATTR_UNUSED,
    int *protocol HF_ATTR_UNUSED) {
    return 0;
}

static uint16_t netDriver_getTCPPort() {
    const char *port_str = getenv(HFND_TCP_PORT_ENV);
    if (port_str) {
        errno              = 0;
        signed long portsl = strtol(port_str, NULL, 0);
        if (errno != 0) {
            PLOG_F("Couldn't convert '%s'='%s' to a number", HFND_TCP_PORT_ENV, port_str);
        }
        if (portsl < 1) {
            LOG_F("Specified TCP port '%s'='%s' (%ld) cannot be < 1", HFND_TCP_PORT_ENV, port_str,
                portsl);
        }
        if (portsl > 65535) {
            LOG_F("Specified TCP port '%s'='%s' (%ld) cannot be > 65535", HFND_TCP_PORT_ENV,
                port_str, portsl);
        }
        return (uint16_t)portsl;
    }

    return HFND_DEFAULT_TCP_PORT;
}

static const char *netDriver_getSockPath() {
    char tmpdir[PATH_MAX] = {};
    if (HonggfuzzNetDriverTempdir(tmpdir, sizeof(tmpdir)) == -1) {
        snprintf(tmpdir, sizeof(tmpdir), HFND_TMP_DIR);
    }

    static __thread char path[PATH_MAX] = {};
    const char          *sock_path      = getenv(HFND_SOCK_PATH_ENV);
    /* If it starts with '/' it's an absolute path */
    if (sock_path && sock_path[0] == '/') {
        snprintf(path, sizeof(path), "%s", sock_path);
    } else if (sock_path) {
        snprintf(path, sizeof(path), "%s/%s", tmpdir, sock_path);
    } else {
        snprintf(path, sizeof(path), "%s/%s", tmpdir, HFND_DEFAULT_SOCK_PATH);
    }
    return path;
}

static void netDriver_Assign(
    const struct sockaddr *addr, socklen_t slen, int type, int protocol) {
    if ((size_t)slen > sizeof(hfnd_globals.dest_addr.addr)) {
        LOG_F("Provided address '%s' is bigger than sizeof(struct sockaddr_storage): %zu > %zu",
            files_sockAddrToStr(addr, slen), (size_t)slen, sizeof(hfnd_globals.dest_addr.addr));
    }
    memcpy(&hfnd_globals.dest_addr.addr, addr, slen);
    hfnd_globals.dest_addr.slen     = slen;
    hfnd_globals.dest_addr.type     = type;
    hfnd_globals.dest_addr.protocol = protocol;

    LOG_I("Assigned binding to address: %s (type: %d, protocol: %d)",
          files_sockAddrToStr(addr, slen), type, protocol);

}
static bool netDriver_connAndAssign(
    const struct sockaddr *addr, socklen_t slen, int type, int protocol) {
    if ((size_t)slen > sizeof(hfnd_globals.dest_addr.addr)) {
        LOG_F("Provided address '%s' is bigger than sizeof(struct sockaddr_storage): %zu > %zu",
            files_sockAddrToStr(addr, slen), (size_t)slen, sizeof(hfnd_globals.dest_addr.addr));
    }
    int fd = netDriver_sockConnAddr(addr, slen, type, protocol);
    if (fd >= 0) {
        close(fd);
        memcpy(&hfnd_globals.dest_addr.addr, addr, slen);
        hfnd_globals.dest_addr.slen     = slen;
        hfnd_globals.dest_addr.type     = type;
        hfnd_globals.dest_addr.protocol = protocol;
        return true;
    }
    return false;
}

static void setGlobalsAddress(){
    /* Next, try TCP4 and TCP6 connections to the localhost */
    const uint16_t           tcp_port = netDriver_getTCPPort();
    const struct sockaddr_in addr4    = {
           .sin_family      = PF_INET,
           .sin_port        = htons(tcp_port),
           .sin_addr.s_addr = htonl(INADDR_LOOPBACK),
    };
    netDriver_Assign((const struct sockaddr *)&addr4, sizeof(addr4), SOCK_STREAM, 0);
}

static bool netDriver_checkIfServerReady() {
    struct sockaddr_storage addr     = {.ss_family = AF_UNSPEC};
    int                     type     = SOCK_STREAM;
    int                     protocol = 0;
    socklen_t               slen     = HonggfuzzNetDriverServerAddress(&addr, &type, &protocol);
    /* User provided specific destination address */
    if (slen > 0) {
        if (netDriver_connAndAssign((struct sockaddr *)&addr, slen, type, protocol)) {
            return true;
        }

        LOG_I("[checkIfServerReady] (pid=%d): WAIT for server to start "
              "accepting conn at '%s'",
            (int)getpid(), files_sockAddrToStr((struct sockaddr *)&addr, slen));
        return false;
    }

    /* Try to connect to ${HFND_TMP_DIR}/${HFND_DEFAULT_SOCK_PATH} first via a PF_UNIX socket */
    struct sockaddr_un sun = {
        .sun_family = PF_UNIX,
        .sun_path   = {},
    };
    snprintf(sun.sun_path, sizeof(sun.sun_path), "%s", netDriver_getSockPath());
    if (netDriver_connAndAssign((const struct sockaddr *)&sun, sizeof(sun), SOCK_STREAM, 0)) {
        return true;
    }
    if (netDriver_connAndAssign((const struct sockaddr *)&sun, sizeof(sun), SOCK_DGRAM, 0)) {
        return true;
    }
    #if defined(SOCK_SEQPACKET)
    if (netDriver_connAndAssign((const struct sockaddr *)&sun, sizeof(sun), SOCK_SEQPACKET, 0)) {
        return true;
    }
    #endif /* defined(SOCK_SEQPACKET) */
    /* Next, try TCP4 and TCP6 connections to the localhost */
    const uint16_t           tcp_port = netDriver_getTCPPort();
    const struct sockaddr_in addr4    = {
           .sin_family      = PF_INET,
           .sin_port        = htons(tcp_port),
           .sin_addr.s_addr = htonl(INADDR_LOOPBACK),
    };
    if (netDriver_connAndAssign((const struct sockaddr *)&addr4, sizeof(addr4), SOCK_STREAM, 0)) {
        return true;
    }
    const struct sockaddr_in6 addr6 = {
        .sin6_family   = PF_INET6,
        .sin6_port     = htons(tcp_port),
        .sin6_flowinfo = 0,
        .sin6_addr     = in6addr_loopback,
        .sin6_scope_id = 0,
    };
    if (netDriver_connAndAssign((const struct sockaddr *)&addr6, sizeof(addr6), SOCK_STREAM, 0)) {
        return true;
    }

    LOG_I("[checkIfServerReady] (pid=%d): WAIT server conn at TCP4/TCP6 port: %hu or at the socket path: '%s'",
        (int)getpid(), tcp_port, files_sockAddrToStr((const struct sockaddr *)&sun, slen));
    return false;
}

int LLVMFuzzerInitialize(int *argc, char ***argv) {
    /* Make sure LIBHFNETDRIVER_module_netdriver (NetDriver signature) is used */
    LOG_D("Module: %s", LIBHFNETDRIVER_module_netdriver);

    *argc = HonggfuzzNetDriverArgsForServer(
        *argc, *argv, &hfnd_globals.argc_server, &hfnd_globals.argv_server);

    return 0;
}

int LLVMFuzzInitializePostForkInit(int *argc, char ***argv) {
    (void) argc;
    (void) argv;
    printf("INSIDE LLVMFuzzInitializePostForkInit\n");
    printf("INSIDE LLVMFuzzInitializePostForkInit\n");
    printf("INSIDE LLVMFuzzInitializePostForkInit\n");
    printf("INSIDE LLVMFuzzInitializePostForkInit\n");
    printf("INSIDE LLVMFuzzInitializePostForkInit\n");
    printf("INSIDE LLVMFuzzInitializePostForkInit\n");
    printf("INSIDE LLVMFuzzInitializePostForkInit\n");
    netDriver_initNsIfNeeded();
    const struct sockaddr * tmpaddr = (const struct sockaddr *)&hfnd_globals.dest_addr.addr;
    printf("pre set socket family %d, type %d, proto %d\n", tmpaddr->sa_family, hfnd_globals.dest_addr.type, hfnd_globals.dest_addr.protocol);
    setGlobalsAddress();
    printf("post set socket family %d, type %d, proto %d\n", tmpaddr->sa_family, hfnd_globals.dest_addr.type, hfnd_globals.dest_addr.protocol);
    // netDriver_startOriginalProgramInThread();

    pthread_t monitor;
    if (pthread_create(&monitor, NULL, netDriver_startOriginalProgramInThread, NULL) != 0) {
        perror("pthread_create monitor");
        exit(EXIT_FAILURE);
    }

    (void) setGlobalsAddress;
    (void) netDriver_checkIfServerReady;

    LOG_I("[INITIALIZER] (pid=%d): The server process is ready to accept connections at "
          "'%s'. Fuzzing starts now!",
        (int)getpid(),
        files_sockAddrToStr(
            (const struct sockaddr *)&hfnd_globals.dest_addr.addr, hfnd_globals.dest_addr.slen));
    return 0;
}

// static pthread_once_t server_once = PTHREAD_ONCE_INIT;

int LLVMFuzzerTestOneInput(const uint8_t *buf, size_t len) {
    // const char afl_test[5] = "##SI";
    if (len == 0) return 0;

    if (hfnd_globals.dest_addr.addr.ss_family == AF_UNSPEC) {
        printf("Destination address not set before fuzzing started");
    }

    int sock = -1;
    for (;;){
        const struct sockaddr * tmpaddr = (const struct sockaddr *)&hfnd_globals.dest_addr.addr;
        printf("socket family %d, type %d, proto %d\n", tmpaddr->sa_family, hfnd_globals.dest_addr.type, hfnd_globals.dest_addr.protocol);
        sock = netDriver_sockConnAddr((const struct sockaddr *)&hfnd_globals.dest_addr.addr,
            hfnd_globals.dest_addr.slen, hfnd_globals.dest_addr.type, hfnd_globals.dest_addr.protocol);
        if (sock>=0) break;
        // LOG_I("[INITIALIZER] (pid=%d) Waiting for server to spin: Sleeping for 0.001s", (int)getpid());
        util_sleepForMSec(1);
    }
    if (sock == -1) {
        /* netDriver_sockConnAddr() preserves errno */
        PLOG_F("[TEST ONE] CONN FAILED @ '%s'",
            files_sockAddrToStr((const struct sockaddr *)&hfnd_globals.dest_addr.addr,
                hfnd_globals.dest_addr.slen));
    }
    if (!files_sendToSocket(sock, buf, len)) {
        PLOG_W("[TEST ONE] files_sendToSocket(addr='%s', sock=%d, len=%zu) FAILED",
            files_sockAddrToStr(
                (const struct sockaddr *)&hfnd_globals.dest_addr.addr, hfnd_globals.dest_addr.slen),
            sock, len);
        close(sock);
        return 0;
    }
    /*
     * Indicate EOF (via the FIN flag) to the TCP server
     *
     * Well-behaved TCP servers should process the input and respond/close the TCP connection at
     * this point
     */
    if (TEMP_FAILURE_RETRY(shutdown(sock, SHUT_WR)) == -1) {
        if (errno == ENOTCONN) {
            close(sock);
            return 0;
        }
        PLOG_F("[TEST ONE] shutdown(sock=%d, SHUT_WR)", sock);
    }

#ifdef HFND_RECVTIME
    const struct timeval timeout = {.tv_sec = 1, .tv_usec = 0};
    if (setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout)) == -1) {
        PLOG_W("[TEST ONE] (pid=%d): Couldn't set setsockopt(sock=%d, SO_RCVTIMEO, 1s)",
            (int)getpid(), sock);
    }
    time_t start = time(NULL);
#endif

    /*
     * Try to read data from the server, assuming that an early TCP close would sometimes cause the
     * TCP server to drop the input data, instead of processing it. Use BSS to avoid putting
     * pressure on the stack size
     */
    static char b[1024ULL * 1024ULL * 4ULL];
    for (;;) {
        int ret = TEMP_FAILURE_RETRY(recv(sock, b, sizeof(b), MSG_WAITALL));
        if (ret == 0) {
            break;
        }
#ifdef HFND_RECVTIME
        if (ret == -1 && errno == EWOULDBLOCK) {
            time_t end = time(NULL);
            if ((end - start) > HFND_RECVTIME) {
                LOG_W("[TEST ONE] (pid=%d): Server didn't close the connection(fd=%d) "
                      "within %d seconds. Closing it.",
                    (int)getpid(), sock, HFND_RECVTIME);
                break;
            }
            continue;
        }
#endif
        if (ret == -1) {
            PLOG_W("[TEST ONE] (pid=%d): CONN (sock=%d) closed with ERROR",
                (int)getpid(), sock);
            break;
        }
    }

    close(sock);

    return 0;
}