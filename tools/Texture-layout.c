/* Texture-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    puts(";; Texture layout");
    printf("(define Texture-size %zu)\n", sizeof(Texture));
    printf("(define Texture-id-off %zu)\n", offsetof(Texture, id));
    printf("(define Texture-width-off %zu)\n", offsetof(Texture, width));
    printf("(define Texture-height-off %zu)\n", offsetof(Texture, height));
    printf("(define Texture-mipmaps-off %zu)\n", offsetof(Texture, mipmaps));
    printf("(define Texture-format-off %zu)\n", offsetof(Texture, format));
    return 0;
}
