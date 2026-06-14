# AI Prompt — 结构体布局工作流

你在操作 `racket-raylib-ffi` 项目。当需要读写 raylib C 结构体的字段时：

## 规则

1. **禁止手工推算** `ptr-ref` / `ptr-add` 的偏移量（如 `16`、`112`）。
   必须用 C 编译器的 `offsetof`/`sizeof` 确认后硬编码，并加注释注明来源。

2. **查偏移**：
   ```bash
   cd tools
   # 单个结构体:
   gcc -I../../src Material-layout.c -o Material-layout && ./Material-layout
   # → (define Material-maps-off 16)
   # → (define Material-size 40)

   # 全部结构体生成 layout.rkt:
   bash build-all.sh > ../raylib/layout.rkt
   ```

3. **硬编码到代码**，加注释：
   ```racket
   (ptr-ref mat-ptr _pointer 16)   ; offsetof(Material,maps)
   (ptr-add p (* i 120))           ; sizeof(Mesh)
   ```

4. **如果 tools/ 没有目标结构体的 layout 文件** → 参考已有文件创建 `Xxx-layout.c`，在 `build-all.sh` 的 `STRUCTS` 数组中添加，运行 `bash build-all.sh > ../raylib/layout.rkt`。

## 记住

`gen-layout.c` 编译时会 link 到 raylib.so 同源的头文件，所以偏移量**与运行时一致**。
