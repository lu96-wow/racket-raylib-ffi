/* Model-layout.c — offsetof/sizeof for Model
 * compile: gcc -I../../src Model-layout.c -o Model-layout && ./Model-layout
 */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"

int main() {
    puts(";; Model layout — auto-generated, do not edit\n");
    printf("(define Model-size %zu)\n", sizeof(Model));
    printf("(define Model-transform-off %zu)\n", offsetof(Model, transform));
    printf("(define Model-meshCount-off %zu)\n", offsetof(Model, meshCount));
    printf("(define Model-materialCount-off %zu)\n", offsetof(Model, materialCount));
    printf("(define Model-meshes-off %zu)\n", offsetof(Model, meshes));
    printf("(define Model-materials-off %zu)\n", offsetof(Model, materials));
    printf("(define Model-meshMaterial-off %zu)\n", offsetof(Model, meshMaterial));
    printf("(define Model-skeleton-off %zu)\n", offsetof(Model, skeleton));
    printf("(define Model-currentPose-off %zu)\n", offsetof(Model, currentPose));
    printf("(define Model-boneMatrices-off %zu)\n", offsetof(Model, boneMatrices));
    return 0;
}
