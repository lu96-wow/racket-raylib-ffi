/* RenderTexture-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    puts(";; RenderTexture layout");
    printf("(define RenderTexture-size %zu)\n", sizeof(RenderTexture));
    printf("(define RenderTexture-id-off %zu)\n", offsetof(RenderTexture, id));
    printf("(define RenderTexture-texture-off %zu)\n", offsetof(RenderTexture, texture));
    printf("(define RenderTexture-depth-off %zu)\n", offsetof(RenderTexture, depth));
    return 0;
}
