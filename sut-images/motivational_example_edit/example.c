#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdlib.h>

enum ConnState { S_INIT = 0, S_AUTHED = 1, S_READY = 2 };

enum ConnState state = S_INIT;

void foo(char *msg, int *buf) {
    size_t len = strlen(msg);
    int j;

    if (len < 1 || len >= 64) return;

    if (state == S_AUTHED) {
        j = 1;
    } else {
        j = 0;
    }

    switch (msg[0]) {
        case 'A': state = S_AUTHED; break;
        case 'R': state = S_READY;  break;
        default:  state = S_INIT;   break;
    }

    if (state == S_READY) {
        buf[len + j] = 0xdead;
    } else {
        buf[j] = 0;
    }
}

int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
    if (Size == 0 || Size >= 1024) return 0;

    char *input = (char *)malloc(Size + 1);
    if (!input) return 0;

    memcpy(input, Data, Size);
    input[Size] = '\0';

    int buf[64] = {0};

    state = S_INIT;

    char *msg = strtok(input, "\n");
    while (msg != NULL) {
        foo(msg, buf);
        msg = strtok(NULL, "\n");
    }

    free(input);
    return 0;
}
