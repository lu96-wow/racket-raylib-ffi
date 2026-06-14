# 任务：审查所有结构体偏移

## 背景

raylib C 结构体在不同编译器上的 padding/对齐不可预测。之前部分绑定的 `_list-struct` 和 `ptr-ref`/`ptr-add` 偏移是手工推算的，可能存在错误。

本任务需要逐结构体与 C 编译器的 `offsetof`/`sizeof` 对照，发现并修复不一致。

## 工具

```
tools/Shader-layout.c         # 单个结构体偏移探测
tools/MaterialMap-layout.c
tools/Material-layout.c
tools/Mesh-layout.c
tools/Transform-layout.c
tools/BoneInfo-layout.c
tools/ModelSkeleton-layout.c
tools/Model-layout.c
tools/ModelAnimation-layout.c
tools/build-all.sh             # 一键编译运行全部，输出完整 layout.rkt
tools/gen-layout.c             # (legacy) all-in-one 版本，已废弃
```

用法：

```bash
cd /home/debian/raylib/racket-raylib-ffi/tools

# 查询单个结构体:
gcc -I../../src Shader-layout.c -o Shader-layout && ./Shader-layout

# 生成完整 layout.rkt:
bash build-all.sh > ../raylib/layout.rkt
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

| 结构体 | 文件 | sizeof | 验证 |
|--------|------|--------|:--:|
| Shader | `Shader-layout.c` | 16 | ✅ |
| MaterialMap | `MaterialMap-layout.c` | 28 | ✅ |
| Material | `Material-layout.c` | 40 | ✅ |
| Mesh | `Mesh-layout.c` | 120 | ✅ |
| Transform | `Transform-layout.c` | 40 | ✅ |
| BoneInfo | `BoneInfo-layout.c` | 36 | ✅ |
| ModelSkeleton | `ModelSkeleton-layout.c` | 24 | ✅ |
| Model | `Model-layout.c` | 136 | ✅ |
| ModelAnimation | `ModelAnimation-layout.c` | 48 | ✅ |
| RayCollision | `RayCollision-layout.c` | 32 | ✅ |
| Font | `Font-layout.c` | 48 | ✅ |
| Camera3D | `Camera3D-layout.c` | 44 | ✅ |
| RenderTexture | `RenderTexture-layout.c` | 44 | ✅ |
| Image | `Image-layout.c` | 24 | ✅ |
| Texture | `Texture-layout.c` | 20 | ✅ |
| NPatchInfo | `NPatchInfo-layout.c` | 36 | ✅ |
| GlyphInfo | `GlyphInfo-layout.c` | 40 | ✅ |
| Wave | `Wave-layout.c` | 24 | ✅ |
| AudioStream | `AudioStream-layout.c` | 32 | ✅ |
| Sound | `Sound-layout.c` | 40 | ✅ |
| Music | `Music-layout.c` | 56 | ✅ |
| VrDeviceInfo | `VrDeviceInfo-layout.c` | 60 | ✅ |
| FilePathList | `FilePathList-layout.c` | 16 | ✅ |
| AutomationEvent | `AutomationEvent-layout.c` | 24 | ✅ |
| AutomationEventList | `AutomationEventList-layout.c` | 16 | ✅ |

以下纯同类型结构体无需 layout 文件：Color, Vector2/3/4, Rectangle, Camera2D, Ray, BoundingBox, Matrix, VrStereoConfig(76×float)。

## 已知不一致（已修复）

| 位置 | 旧值 | 正确值 | 原因 |
|------|------|--------|------|
| `_mesh-bytes` | 112 字节 | 120 字节 | 缺 boneCount 后和 vaoId 后的 padding |
| `models_mesh_picking.rkt` ptr-add | `(* m 112)` | `(* m 120)` | 同上 |
| `_ray-collision-bytes` | `_stdbool`+9×`_float` (40B) | `_stdbool`+7×`_float` (32B) | 多了 2 个末尾 float，C 返回 32B 但 Racket 读 40B |
| `font-list->ptr` (2 文件) | `_pointer 8/9` | `_pointer 4/5` | Font.recs@32 写成 byte64, glyphs@40 写成 byte72 |
| `set-material-color` | `_pointer 16` | `_pointer 2` | `_pointer` 索引×8, maps@byte16 需 idx=2 非 16 |

## 已知问题（未修复）

| 位置 | 问题 | 状态 |
|------|------|------|
| — | (当前无) | — |
