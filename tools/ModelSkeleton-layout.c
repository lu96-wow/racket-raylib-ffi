/* ModelSkeleton-layout.c — offsetof/sizeof for ModelSkeleton
 * compile: gcc -I../../src ModelSkeleton-layout.c -o ModelSkeleton-layout && ./ModelSkeleton-layout
 */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"

int main() {
    puts(";; ModelSkeleton layout — auto-generated, do not edit\n");
    printf("(define ModelSkeleton-size %zu)\n", sizeof(ModelSkeleton));
    printf("(define ModelSkeleton-boneCount-off %zu)\n", offsetof(ModelSkeleton, boneCount));
    printf("(define ModelSkeleton-bones-off %zu)\n", offsetof(ModelSkeleton, bones));
    printf("(define ModelSkeleton-bindPose-off %zu)\n", offsetof(ModelSkeleton, bindPose));
    return 0;
}
