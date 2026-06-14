/* AudioStream-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    puts(";; AudioStream layout");
    printf("(define AudioStream-size %zu)\n", sizeof(AudioStream));
    printf("(define AudioStream-buffer-off %zu)\n", offsetof(AudioStream, buffer));
    printf("(define AudioStream-processor-off %zu)\n", offsetof(AudioStream, processor));
    printf("(define AudioStream-sampleRate-off %zu)\n", offsetof(AudioStream, sampleRate));
    printf("(define AudioStream-sampleSize-off %zu)\n", offsetof(AudioStream, sampleSize));
    printf("(define AudioStream-channels-off %zu)\n", offsetof(AudioStream, channels));
    return 0;
}
