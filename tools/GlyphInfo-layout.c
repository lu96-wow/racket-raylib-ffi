/* GlyphInfo-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    puts(";; GlyphInfo layout");
    printf("(define GlyphInfo-size %zu)\n", sizeof(GlyphInfo));
    printf("(define GlyphInfo-value-off %zu)\n", offsetof(GlyphInfo, value));
    printf("(define GlyphInfo-offsetX-off %zu)\n", offsetof(GlyphInfo, offsetX));
    printf("(define GlyphInfo-offsetY-off %zu)\n", offsetof(GlyphInfo, offsetY));
    printf("(define GlyphInfo-advanceX-off %zu)\n", offsetof(GlyphInfo, advanceX));
    printf("(define GlyphInfo-image-off %zu)\n", offsetof(GlyphInfo, image));
    return 0;
}
