/* Image-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    puts(";; Image layout");
    printf("(define Image-size %zu)\n", sizeof(Image));
    printf("(define Image-data-off %zu)\n", offsetof(Image, data));
    printf("(define Image-width-off %zu)\n", offsetof(Image, width));
    printf("(define Image-height-off %zu)\n", offsetof(Image, height));
    printf("(define Image-mipmaps-off %zu)\n", offsetof(Image, mipmaps));
    printf("(define Image-format-off %zu)\n", offsetof(Image, format));
    return 0;
}
