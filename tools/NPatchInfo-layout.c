/* NPatchInfo-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    puts(";; NPatchInfo layout");
    printf("(define NPatchInfo-size %zu)\n", sizeof(NPatchInfo));
    printf("(define NPatchInfo-source-off %zu)\n", offsetof(NPatchInfo, source));
    printf("(define NPatchInfo-left-off %zu)\n", offsetof(NPatchInfo, left));
    printf("(define NPatchInfo-top-off %zu)\n", offsetof(NPatchInfo, top));
    printf("(define NPatchInfo-right-off %zu)\n", offsetof(NPatchInfo, right));
    printf("(define NPatchInfo-bottom-off %zu)\n", offsetof(NPatchInfo, bottom));
    printf("(define NPatchInfo-layout-off %zu)\n", offsetof(NPatchInfo, layout));
    return 0;
}
