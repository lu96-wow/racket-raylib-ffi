#include <stdio.h>
#include <stddef.h>
#include <stdint.h>

typedef struct Texture {
    unsigned int id;
    int width;
    int height;
    int mipmaps;
    int format;
} Texture;

typedef struct RenderTexture {
    unsigned int id;
    Texture texture;
    Texture depth;
} RenderTexture;

int main() {
    printf("Texture size: %zu bytes\n", sizeof(Texture));
    printf("  id offset: %zu\n", offsetof(Texture, id));
    printf("  width offset: %zu\n", offsetof(Texture, width));
    printf("  height offset: %zu\n", offsetof(Texture, height));
    printf("  mipmaps offset: %zu\n", offsetof(Texture, mipmaps));
    printf("  format offset: %zu\n", offsetof(Texture, format));
    printf("RenderTexture size: %zu bytes\n", sizeof(RenderTexture));
    printf("  id offset: %zu\n", offsetof(RenderTexture, id));
    printf("  texture offset: %zu\n", offsetof(RenderTexture, texture));
    printf("  depth offset: %zu\n", offsetof(RenderTexture, depth));
    printf("RenderTexture struct field sizes:\n");
    printf("  id: %zu, tex.id: %zu, tex.w: %zu, tex.h: %zu\n",
           sizeof(unsigned int), sizeof(unsigned int), sizeof(int), sizeof(int));
    printf("  tex.mip: %zu, tex.fmt: %zu\n", sizeof(int), sizeof(int));
    return 0;
}
