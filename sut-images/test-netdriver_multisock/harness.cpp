#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

char *foo = NULL;

// Pattern-matching logic from your example
int __attribute__((noinline)) crashme(const uint8_t *Data, size_t Size) {

    printf("DATA: %s\n", Data);
    printf("DATA LEN: %zu\n", Size);

    if (Size < 5) return -1;

    if (Data[0] == 'F')
    if (Data[1] == 'A')
    if (Data[2] == '$')
    if (Data[3] == '$')
    if (Data[4] == '$')
        *foo = 1; 
        
    if (Data[0] == 'F')
    if (Data[1] == 'A')
    if (Data[2] == '$')
    if (Data[3] == 'J')
    if (Data[4] == '$')
        *foo = 1; // Intentional crash 
    
    if (Data[0] == 'F')
    if (Data[1] == 'A')
    if (Data[2] == '$')
    if (Data[3] == 'J')
    if (Data[4] == 'u')
        abort(); // Intentional crash
    
    if (Data[0] == 'F')
    if (Data[1] == 'A')
    if (Data[2] == 'U')
    if (Data[3] == 'J')
    if (Data[4] == '$'){
        int *ptr = (int *)malloc(sizeof(int));
        *ptr = 42;
        free(ptr);
        *ptr = 99;     
    }
    return 0;
}

// Accept and process input from the socket
void handle_connection(int client_fd) {
    uint8_t buffer[4096];
    ssize_t n = read(client_fd, buffer, sizeof(buffer));
    printf("read %zu bytes\n", n);
    if (n > 0) {
        crashme(buffer, static_cast<size_t>(n));
    }
}

// Dumps all command-line arguments
void dump_argv(int argc, char** argv) {
    fprintf(stderr, "[+] Program arguments:\n");
    for (int i = 0; i < argc; i++) {
        fprintf(stderr, "  argv[%d]: %s\n", i, argv[i]);
    }
}

int main(int argc, char **argv) {
    dump_argv(argc, argv);
    // Setup socket with libhgnetdriver hooks
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("socket");
        return 1;
    }

    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(8080);
    addr.sin_addr.s_addr = htonl(INADDR_ANY);

    if (bind(server_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("bind");
        close(server_fd);
        return 1;
    }

    if (listen(server_fd, 5) < 0) {
        perror("listen");
        close(server_fd);
        return 1;
    }

    
    sockaddr_in client_addr{};
    socklen_t client_len = sizeof(client_addr);
    int client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &client_len);
    if (client_fd < 0) {
        perror("accept");
        return 0;
    }

    handle_connection(client_fd);
    close(client_fd);
    

    close(server_fd);
    
    return 0;
}
