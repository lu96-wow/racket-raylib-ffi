/* AutomationEventList-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    printf("(define AutomationEventList-size %zu)\n", sizeof(AutomationEventList));
    printf("(define AutomationEventList-capacity-off %zu)\n", offsetof(AutomationEventList, capacity));
    printf("(define AutomationEventList-count-off %zu)\n", offsetof(AutomationEventList, count));
    printf("(define AutomationEventList-events-off %zu)\n", offsetof(AutomationEventList, events));
    return 0;
}
