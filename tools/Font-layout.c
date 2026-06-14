/* Font-layout.c — offsetof/sizeof for Font
 * compile: gcc -I../../src Font-layout.c -o Font-layout && ./Font-layout
 */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"

int main() {
    puts(";; Font layout — auto-generated, do not edit\n");
    printf("(define Font-size %zu)\n", sizeof(Font));
    printf("(define Font-baseSize-off %zu)\n", offsetof(Font, baseSize));
    printf("(define Font-glyphCount-off %zu)\n", offsetof(Font, glyphCount));
    printf("(define Font-glyphPadding-off %zu)\n", offsetof(Font, glyphPadding));
    printf("(define Font-texture-off %zu)\n", offsetof(Font, texture));
    printf("(define Font-recs-off %zu)\n", offsetof(Font, recs));
    printf("(define Font-glyphs-off %zu)\n", offsetof(Font, glyphs));
    return 0;
}
