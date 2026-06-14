/* AutomationEvent-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    printf("(define AutomationEvent-size %zu)\n", sizeof(AutomationEvent));
    printf("(define AutomationEvent-frame-off %zu)\n", offsetof(AutomationEvent, frame));
    printf("(define AutomationEvent-type-off %zu)\n", offsetof(AutomationEvent, type));
    printf("(define AutomationEvent-params-off %zu)\n", offsetof(AutomationEvent, params));
    return 0;
}
