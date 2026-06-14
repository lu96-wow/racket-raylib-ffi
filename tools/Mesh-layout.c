/* Mesh-layout.c — offsetof/sizeof for Mesh
 * compile: gcc -I../../src Mesh-layout.c -o Mesh-layout && ./Mesh-layout
 */
#include <stdio.h>
#include <stddef.h>
#include "../../src/raylib.h"

int main() {
    puts(";; Mesh layout — auto-generated, do not edit\n");
    printf("(define Mesh-size %zu)\n", sizeof(Mesh));
    printf("(define Mesh-vertexCount-off %zu)\n", offsetof(Mesh, vertexCount));
    printf("(define Mesh-triangleCount-off %zu)\n", offsetof(Mesh, triangleCount));
    printf("(define Mesh-vertices-off %zu)\n", offsetof(Mesh, vertices));
    printf("(define Mesh-texcoords-off %zu)\n", offsetof(Mesh, texcoords));
    printf("(define Mesh-texcoords2-off %zu)\n", offsetof(Mesh, texcoords2));
    printf("(define Mesh-normals-off %zu)\n", offsetof(Mesh, normals));
    printf("(define Mesh-tangents-off %zu)\n", offsetof(Mesh, tangents));
    printf("(define Mesh-colors-off %zu)\n", offsetof(Mesh, colors));
    printf("(define Mesh-indices-off %zu)\n", offsetof(Mesh, indices));
    printf("(define Mesh-boneCount-off %zu)\n", offsetof(Mesh, boneCount));
    printf("(define Mesh-boneIndices-off %zu)\n", offsetof(Mesh, boneIndices));
    printf("(define Mesh-boneWeights-off %zu)\n", offsetof(Mesh, boneWeights));
    printf("(define Mesh-animVertices-off %zu)\n", offsetof(Mesh, animVertices));
    printf("(define Mesh-animNormals-off %zu)\n", offsetof(Mesh, animNormals));
    printf("(define Mesh-vaoId-off %zu)\n", offsetof(Mesh, vaoId));
    printf("(define Mesh-vboId-off %zu)\n", offsetof(Mesh, vboId));
    return 0;
}
