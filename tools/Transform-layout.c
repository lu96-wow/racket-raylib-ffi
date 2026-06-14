/* Transform-layout.c — offsetof/sizeof for Transform
 * compile: gcc -I../../src Transform-layout.c -o Transform-layout && ./Transform-layout
 */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"

int main() {
    puts(";; Transform layout — auto-generated, do not edit\n");
    printf("(define Transform-size %zu)\n", sizeof(Transform));
    printf("(define Transform-translation-off %zu)\n", offsetof(Transform, translation));
    printf("(define Transform-rotation-off %zu)\n", offsetof(Transform, rotation));
    printf("(define Transform-scale-off %zu)\n", offsetof(Transform, scale));
    return 0;
}
