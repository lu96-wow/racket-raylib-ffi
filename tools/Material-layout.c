/* Material-layout.c — offsetof/sizeof for Material
 * compile: gcc -I../../src Material-layout.c -o Material-layout && ./Material-layout
 */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"

int main() {
    puts(";; Material layout — auto-generated, do not edit\n");
    printf("(define Material-size %zu)\n", sizeof(Material));
    printf("(define Material-shader-off %zu)\n", offsetof(Material, shader));
    printf("(define Material-maps-off %zu)\n", offsetof(Material, maps));
    printf("(define Material-params-off %zu)\n", offsetof(Material, params));
    return 0;
}
