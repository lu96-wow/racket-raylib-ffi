/* FilePathList-layout.c */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"
int main() {
    printf("(define FilePathList-size %zu)\n", sizeof(FilePathList));
    printf("(define FilePathList-count-off %zu)\n", offsetof(FilePathList, count));
    printf("(define FilePathList-paths-off %zu)\n", offsetof(FilePathList, paths));
    return 0;
}
