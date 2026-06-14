/* VrDeviceInfo-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    puts(";; VrDeviceInfo layout");
    printf("(define VrDeviceInfo-size %zu)\n", sizeof(VrDeviceInfo));
    printf("(define VrDeviceInfo-hResolution-off %zu)\n", offsetof(VrDeviceInfo, hResolution));
    printf("(define VrDeviceInfo-vResolution-off %zu)\n", offsetof(VrDeviceInfo, vResolution));
    printf("(define VrDeviceInfo-hScreenSize-off %zu)\n", offsetof(VrDeviceInfo, hScreenSize));
    printf("(define VrDeviceInfo-vScreenSize-off %zu)\n", offsetof(VrDeviceInfo, vScreenSize));
    printf("(define VrDeviceInfo-eyeToScreenDistance-off %zu)\n", offsetof(VrDeviceInfo, eyeToScreenDistance));
    printf("(define VrDeviceInfo-lensSeparationDistance-off %zu)\n", offsetof(VrDeviceInfo, lensSeparationDistance));
    printf("(define VrDeviceInfo-interpupillaryDistance-off %zu)\n", offsetof(VrDeviceInfo, interpupillaryDistance));
    printf("(define VrDeviceInfo-lensDistortionValues-off %zu)\n", offsetof(VrDeviceInfo, lensDistortionValues));
    printf("(define VrDeviceInfo-chromaAbCorrection-off %zu)\n", offsetof(VrDeviceInfo, chromaAbCorrection));
    return 0;
}
