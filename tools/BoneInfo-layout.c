/* BoneInfo-layout.c — offsetof/sizeof for BoneInfo
 * compile: gcc -I../../src BoneInfo-layout.c -o BoneInfo-layout && ./BoneInfo-layout
 */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"

int main() {
    puts(";; BoneInfo layout — auto-generated, do not edit\n");
    printf("(define BoneInfo-size %zu)\n", sizeof(BoneInfo));
    printf("(define BoneInfo-name-off %zu)\n", offsetof(BoneInfo, name));
    printf("(define BoneInfo-parent-off %zu)\n", offsetof(BoneInfo, parent));
    return 0;
}
