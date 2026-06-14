/* ModelAnimation-layout.c — offsetof/sizeof for ModelAnimation
 * compile: gcc -I../../src ModelAnimation-layout.c -o ModelAnimation-layout && ./ModelAnimation-layout
 */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"

int main() {
    puts(";; ModelAnimation layout — auto-generated, do not edit\n");
    printf("(define ModelAnimation-size %zu)\n", sizeof(ModelAnimation));
    printf("(define ModelAnimation-name-off %zu)\n", offsetof(ModelAnimation, name));
    printf("(define ModelAnimation-boneCount-off %zu)\n", offsetof(ModelAnimation, boneCount));
    printf("(define ModelAnimation-keyframeCount-off %zu)\n", offsetof(ModelAnimation, keyframeCount));
    printf("(define ModelAnimation-keyframePoses-off %zu)\n", offsetof(ModelAnimation, keyframePoses));
    return 0;
}
