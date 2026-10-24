#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdlib.h>

enum ConnState { S_INIT = 0, S_AUTHED = 1, S_READY = 2 };

enum ConnState state = S_INIT;

void foo(char *msg, int *buf) {
    size_t len = strlen(msg);
    if (len < 1 || len >= 64) return; // meh

    int j = (state == S_AUTHED); // j is 0 or 1
    int offset = 0;

    switch (msg[0]) {
        case 'A': state = S_AUTHED; break;
        case 'R': state = S_READY; offset = len; break;
        default:  state = S_INIT; break;
    }

    buf[offset+j] = 0xff; // this: bug only if S_AUTHED -> S_READY
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
