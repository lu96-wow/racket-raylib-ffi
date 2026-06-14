/* Camera3D-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    puts(";; Camera3D layout");
    printf("(define Camera3D-size %zu)\n", sizeof(Camera3D));
    printf("(define Camera3D-position-off %zu)\n", offsetof(Camera3D, position));
    printf("(define Camera3D-target-off %zu)\n", offsetof(Camera3D, target));
    printf("(define Camera3D-up-off %zu)\n", offsetof(Camera3D, up));
    printf("(define Camera3D-fovy-off %zu)\n", offsetof(Camera3D, fovy));
    printf("(define Camera3D-projection-off %zu)\n", offsetof(Camera3D, projection));
    return 0;
}
