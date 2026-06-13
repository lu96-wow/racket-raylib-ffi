# models 示例翻译指南

## 多指针嵌套访问

raylib 的 `Model`、`ModelAnimation` 等结构体包含指向嵌套结构体数组的指针（如 `Material *materials`、`BoneInfo *bones`、`Transform *bindPose`）。

### 问题

FFI 用 `_list-struct` 将结构体展平为 Racket list，指针字段保留为原始 `_pointer` 值。Racket 侧无法直接解引用。

### 解决方案

`types.rkt` 已用 `define-cstruct` 定义了所有嵌套类型的完整内存布局。通过三个设施安全访问：

```racket
;; 1. ctype-sizeof — 运行时获取结构体字节大小
(sizeof-transform)   → 40   ;; sizeof(Transform)

;; 2. ptr-add — 对裸指针做字节偏移，前进到数组中第 i 个元素
(ptr-add frame-poses (* i sizeof-transform))   ;; &frame_poses[i]

;; 3. raw-types.rkt 字段访问器 — 从结构体指针读取具体字段
(transform-trans-x bone-ptr)   ;; bone_ptr->translation.x
(bone-info-parent bi-ptr)      ;; bone_ptr->parent
```

### 关键结构体布局

| 结构体 | sizeof | 布局 | raw 访问器 |
|--------|--------|------|-----------|
| `Transform` | 40B | trans(12B) + rot(16B) + scale(12B) | `transform-trans-x/y/z`, `transform-rot-*`, `transform-scale-*` |
| `BoneInfo` | 36B | name[32](32B) + parent(4B) | `bone-info-parent` |
| `ModelAnimation` (list) | — | 32 _ubyte + _int + _int + _pointer | `anim-keyframe-count-index`=33, `anim-keyframe-poses-index`=34 |

### 典型用法 (models_loading_m3d)

```racket
;; frame_poses 是 Transform*, 取第 i 个 Transform
(define bone-ptr (ptr-add frame-poses (* i sizeof-transform)))
;; 读字段
(define x (transform-trans-x bone-ptr))
(define y (transform-trans-y bone-ptr))
(define z (transform-trans-z bone-ptr))

;; bones 是 BoneInfo*, 取第 i 个 BoneInfo
(define bi-ptr (ptr-add bones-ptr (* i sizeof-boneinfo)))
(define parent (bone-info-parent bi-ptr))
```

### 需要新增绑定的函数

某些示例需要额外的 C 函数（当前未绑定），可在对应 `.rkt` 模块添加：

```racket
;; 例: LoadImageColors (models_first_person_maze)
(define load-image-colors
  (get-ffi-obj "LoadImageColors" lib (_fun _pointer -> _pointer)))
```

## 翻译限制

以下类型示例当前无法翻译（需要 raygui/rlgl/shader/内部指针操作）：

| 示例 | 原因 |
|------|------|
| `models_animation_blending` | raygui UI |
| `models_animation_timing` | raygui UI |
| `models_basic_voxel` | rlights.h + custom shader |
| `models_skybox_rendering` | rlgl + custom shader |
| `models_textured_cube` | rlgl immediate mode |
| `models_rlgl_solar_system` | rlgl |
| `models_animation_gpu_skinning` | GPU skinning shader |
| `models_bone_socket` | 多层骨骼指针 + 矩阵运算 |

## exact → inexact 陷阱

Racket 的 `/` 在 `(/ 0 30.0)` 时优化返回 exact `0`，后续 `(* inexact exact-0)` 保持 exact。FFI `_float` 拒绝 exact 值。

**修复：** `(exact->inexact (/ (+ x y z) 30.0))` 或在计算链中加入浮点因子。
