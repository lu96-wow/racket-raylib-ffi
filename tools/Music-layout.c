/* Music-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    puts(";; Music layout");
    printf("(define Music-size %zu)\n", sizeof(Music));
    printf("(define Music-stream-off %zu)\n", offsetof(Music, stream));
    printf("(define Music-frameCount-off %zu)\n", offsetof(Music, frameCount));
    printf("(define Music-looping-off %zu)\n", offsetof(Music, looping));
    printf("(define Music-ctxType-off %zu)\n", offsetof(Music, ctxType));
    printf("(define Music-ctxData-off %zu)\n", offsetof(Music, ctxData));
    return 0;
}
