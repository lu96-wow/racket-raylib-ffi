/* Shader-layout.c — offsetof/sizeof for Shader
 * compile: gcc -I../../src Shader-layout.c -o Shader-layout && ./Shader-layout
 */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"

int main() {
    puts(";; Shader layout — auto-generated, do not edit\n");
    printf("(define Shader-size %zu)\n", sizeof(Shader));
    printf("(define Shader-id-off %zu)\n", offsetof(Shader, id));
    printf("(define Shader-locs-off %zu)\n", offsetof(Shader, locs));
    return 0;
}
