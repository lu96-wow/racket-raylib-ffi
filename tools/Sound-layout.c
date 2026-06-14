/* Sound-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    puts(";; Sound layout");
    printf("(define Sound-size %zu)\n", sizeof(Sound));
    printf("(define Sound-stream-off %zu)\n", offsetof(Sound, stream));
    printf("(define Sound-frameCount-off %zu)\n", offsetof(Sound, frameCount));
    return 0;
}
