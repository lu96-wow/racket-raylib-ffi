/* Wave-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    puts(";; Wave layout");
    printf("(define Wave-size %zu)\n", sizeof(Wave));
    printf("(define Wave-frameCount-off %zu)\n", offsetof(Wave, frameCount));
    printf("(define Wave-sampleRate-off %zu)\n", offsetof(Wave, sampleRate));
    printf("(define Wave-sampleSize-off %zu)\n", offsetof(Wave, sampleSize));
    printf("(define Wave-channels-off %zu)\n", offsetof(Wave, channels));
    printf("(define Wave-data-off %zu)\n", offsetof(Wave, data));
    return 0;
}
