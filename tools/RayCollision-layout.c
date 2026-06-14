/* RayCollision-layout.c — offsetof/sizeof for RayCollision
 * compile: gcc -I../../src RayCollision-layout.c -o RayCollision-layout && ./RayCollision-layout
 */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"

int main() {
    puts(";; RayCollision layout — auto-generated, do not edit\n");
    printf("(define RayCollision-size %zu)\n", sizeof(RayCollision));
    printf("(define RayCollision-hit-off %zu)\n", offsetof(RayCollision, hit));
    printf("(define RayCollision-distance-off %zu)\n", offsetof(RayCollision, distance));
    printf("(define RayCollision-point-off %zu)\n", offsetof(RayCollision, point));
    printf("(define RayCollision-normal-off %zu)\n", offsetof(RayCollision, normal));
    return 0;
}
