# 任务：审查所有结构体偏移

## 背景

raylib C 结构体在不同编译器上的 padding/对齐不可预测。之前部分绑定的 `_list-struct` 和 `ptr-ref`/`ptr-add` 偏移是手工推算的，可能存在错误。

本任务需要逐结构体与 C 编译器的 `offsetof`/`sizeof` 对照，发现并修复不一致。

## 工具

```
tools/gen-layout.c   # 编译运行输出所有结构体的真实偏移
```

用法：

```bash
cd /home/debian/raylib/racket-raylib-ffi/tools
gcc -I../../src gen-layout.c -o gen-layout && ./gen-layout
```

## 需要审查的文件

1. **`raylib/types.rkt`** — `define-cstruct` 定义（FFI 自动处理 padding，通常正确，但需验证字段名是否匹配 raylib.h）

2. **`raylib/rtextures.rkt`** — `set-material-color` 手工指针操作
   - `Material-maps-off` 当前用 16，gen-layout 确认是否=16
   - `MaterialMap-color-off` 当前用 20，确认
   - 已知问题：`ptr-ref _pointer Material-maps-off` 读到无效指针，待查因

3. **`raylib/rmodels.rkt`** — `_mesh-bytes` / `_model-bytes` / `_material-bytes` / `_model-animation-bytes`
   - `_mesh-bytes`：已修复为 120 字节（加了两处 padding），确认
   - `_model-bytes`：需对照 gen-layout 验证 Model 各字段偏移
   - `_material-bytes`：已验证有 Shader padding（offset 4），确认 Material-size=40

4. **`raylib/rcore.rkt`** — `get-mesh-bounding-box` 等用 `_mesh-bytes` 传值的函数，确认传值布局与 C struct 一致

5. **`raylib-var/core.rkt`** — `vector3`/`rectangle`/`bounding-box`/`camera3d`/`ray`/`ray-collision` 等指针构造器
   - 手工 `ptr-set!` 偏移是否与 `_Vector3` 等 cstruct 布局一致
   - 重点：`camera3d` 布局（float×10 + int）

6. **`examples/models/`** — 所有文件中的 `ptr-add` 和 `list-ref` 硬编码数字
   - `models_mesh_picking.rkt`：`(* m 120)`（已修复），其他 list-ref 索引
   - `models_loading.rkt`：`list-ref model 19`（materials 指针），确认 Model 布局中 materials 的偏移
   - 其他使用 `list-ref model N` 的文件

## 验证方法

对每个结构体：

1. 运行 gen-layout 获取真实偏移
2. 在绑定代码中找到对应字段访问
3. 如果手工偏移 ≠ gen-layout 输出 → 修复
4. 修复后运行相关示例验证不崩溃

## gen-layout.c 当前覆盖的结构体

- Shader, MaterialMap, Material
- Mesh, Transform, BoneInfo
- ModelSkeleton, Model, ModelAnimation

**如果审查发现需要但 gen-layout.c 未覆盖的结构体**（如 Light[rlights], Texture2D, NPatchInfo 等），先在 gen-layout.c 添加再查。

## 已知不一致（已修复）

| 位置 | 旧值 | 正确值 | 原因 |
|------|------|--------|------|
| `_mesh-bytes` | 112 字节 | 120 字节 | 缺 boneCount 后和 vaoId 后的 padding |
| `models_mesh_picking.rkt` ptr-add | `(* m 112)` | `(* m 120)` | 同上 |

## 已知问题（未修复）

| 位置 | 问题 | 状态 |
|------|------|------|
| `set-material-color` 中 `ptr-ref mat-ptr _pointer 16` | 读到无效指针，但同偏移 C 函数正常 | 待查（可能 Racket FFI ABI 边界问题） |
