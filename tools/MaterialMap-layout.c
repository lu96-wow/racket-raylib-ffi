/* MaterialMap-layout.c — offsetof/sizeof for MaterialMap
 * compile: gcc -I../../src MaterialMap-layout.c -o MaterialMap-layout && ./MaterialMap-layout
 */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"

int main() {
    puts(";; MaterialMap layout — auto-generated, do not edit\n");
    printf("(define MaterialMap-size %zu)\n", sizeof(MaterialMap));
    printf("(define MaterialMap-texture-off %zu)\n", offsetof(MaterialMap, texture));
    printf("(define MaterialMap-color-off %zu)\n", offsetof(MaterialMap, color));
    printf("(define MaterialMap-value-off %zu)\n", offsetof(MaterialMap, value));
    return 0;
}
