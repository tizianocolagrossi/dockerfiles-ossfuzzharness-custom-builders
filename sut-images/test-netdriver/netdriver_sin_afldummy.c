#include "libhfnetdriver/netdriver.h"

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
static pthread_once_t server_once = PTHREAD_ONCE_INIT;

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

static void netDriver_startOriginalProgramInThread(void) {
    pthread_t      t;
    pthread_attr_t attr;
    
    pthread_attr_init(&attr);
    pthread_attr_setstacksize(&attr, 1024ULL * 1024ULL * 8ULL);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);

    if (pthread_create(&t, &attr, netDriver_mainProgram, NULL) != 0) {
        PLOG_F("Couldn't create the 'netDriver_mainProgram' thread");
    }
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

static int netDriver_sockConnAddr(
    const struct sockaddr *addr, socklen_t socklen, int type, int protocol) {
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
    (void) netDriver_bindToRndLoopback;
    // netDriver_bindToRndLoopback(sock, addr->sa_family);

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
    *server_argv = argv;
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

static void initializeGlobalAddress() {
    
    /* Next, try TCP4 connections to the localhost */
    const uint16_t           tcp_port = netDriver_getTCPPort();
    const struct sockaddr_in addr4    = {
        .sin_family      = AF_INET,
        .sin_port        = htons(tcp_port),
        .sin_addr.s_addr = htonl(INADDR_LOOPBACK),
    };
    
    memcpy(&hfnd_globals.dest_addr.addr, (const struct sockaddr *)&addr4, sizeof(addr4));
    hfnd_globals.dest_addr.slen     = sizeof(addr4);
    hfnd_globals.dest_addr.type     = SOCK_STREAM;
    hfnd_globals.dest_addr.protocol = 0;

}

int LLVMFuzzerInitialize(int *argc, char ***argv) {
    if (getenv(HFND_SKIP_FUZZING_ENV)) {
        LOG_I(
            "Honggfuzz Net Driver (pid=%d): '%s' is set, skipping fuzzing, calling main() directly",
            (int)getpid(), HFND_SKIP_FUZZING_ENV);
        exit(HonggfuzzNetDriver_main(*argc, *argv));
    }

    /* Make sure LIBHFNETDRIVER_module_netdriver (NetDriver signature) is used */
    LOG_D("Module: %s", LIBHFNETDRIVER_module_netdriver);

    *argc = HonggfuzzNetDriverArgsForServer(
        *argc, *argv, &hfnd_globals.argc_server, &hfnd_globals.argv_server);
    
    initializeGlobalAddress();
    return 0;
}

int LLVMFuzzerTestOneInput(const uint8_t *buf, size_t len) {

    printf("LLVMFuzzerTestOneInput buf: %s\n", buf);
    
    if(strncmp(buf, "##SI", 4) == 0){
        return 0;
    }

    (void) server_once;
    // pthread_once(&server_once, netDriver_startOriginalProgramInThread);
    netDriver_startOriginalProgramInThread();
    util_sleepForMSec(10);


    LOG_I("Honggfuzz Net Driver (pid=%d): The server process is ready to accept connections at "
          "'%s'. Fuzzing starts now!",
        (int)getpid(),
        files_sockAddrToStr(
            (const struct sockaddr *)&hfnd_globals.dest_addr.addr, hfnd_globals.dest_addr.slen));



    int sock = netDriver_sockConnAddr((const struct sockaddr *)&hfnd_globals.dest_addr.addr,
        hfnd_globals.dest_addr.slen, hfnd_globals.dest_addr.type, hfnd_globals.dest_addr.protocol);
    if (sock == -1) {
        /* netDriver_sockConnAddr() preserves errno */
        PLOG_F("Couldn't connect to the server socket at '%s'",
            files_sockAddrToStr((const struct sockaddr *)&hfnd_globals.dest_addr.addr,
                hfnd_globals.dest_addr.slen));
    }
    if (!files_sendToSocket(sock, buf, len)) {
        PLOG_W("files_sendToSocket(addr='%s', sock=%d, len=%zu) failed",
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
        PLOG_F("shutdown(sock=%d, SHUT_WR)", sock);
    }

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

        if (ret == -1) {
            PLOG_W("Honggfuzz Net Driver (pid=%d): Connection to the server (sock=%d) closed with "
                   "error",
                (int)getpid(), sock);
            break;
        }
    }

    close(sock);

    return 0;
}
