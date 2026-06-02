# raylib Racket FFI 绑定 — 项目上下文

## 项目结构

```
racket-bind/
├── raylib/                  # FFI 绑定（纯函数绑定 + 结构体类型）
│   ├── raylib.rkt           # 主入口，re-export 所有子模块 + raylib-var
│   ├── types.rkt            # 结构体定义（_Color, _Vector2, 等）
│   ├── rcore.rkt            # core 函数绑定 + def-ffi 宏
│   ├── rshapes.rkt          # shapes 函数绑定
│   ├── rtextures.rkt        # (骨架)
│   ├── rtext.rkt            # (骨架)
│   ├── rmodels.rkt          # (骨架)
│   ├── raudio.rkt           # (骨架)
│   └── rcamera.rkt          # (骨架)
│
 ├── raylib-var/              # 预定义常量（与 FFI 绑定分离）
├── raylib-var/              # 预定义常量（与 FFI 绑定分离）
│   ├── var.rkt              # 主入口
│   └── core.rkt             # 颜色、键盘键值、窗口标志等所有常量
│
 │   └── core.rkt             # 颜色、键盘键值、窗口标志等所有常量
 │
 ├── raylib-racket/            # 纯 Racket 兼容实现层
 │   └── automation.rkt       # Automation Events 录制/导出/加载（纯 Racket）
 │                            # FFI 只有 play-automation-event 在 raylib/rcore.rkt 中
 │
├── examples/core/           # core 示例的 Racket 翻译
│   ├── core_basic_window.rkt
│   └── core_delta_time.rkt
│
├── work/core/               # 分析工作区
│   ├── total.txt            # 全量去重结构体 + 来源对照表
│   ├── SUMMARY_deduplicated_structs.txt
│   └── core_*.txt           # 49 个示例各自的结构体分析
│
└── ai-info/
    └── context.md           # 本文件
```

## 设计原则

### 1. 结构体统一用 malloc 分配，Racket 持裸指针

所有结构体在 Racket 侧通过 `(malloc _Type 'atomic)` 分配，返回裸 `cpointer`（不是 `define-cstruct` 的 tagged pointer）。

```racket
;; ✅ 正确: raylib-var/core.rkt 中的辅助函数
(define (vector2 x y)
  (let ([v (malloc T:_Vector2 'atomic)])
    (ptr-set! v _float 0 (exact->inexact x))
    (ptr-set! v _float 1 (exact->inexact y))
    v))
```

为什么不用 `define-cstruct` 的 `make-Color` / `make-Vector2`？
- 它们返回 tagged pointer，`Color?` / `Vector2?` 有契约检查
- 跨模块使用时访问器契约会拒绝裸 `cpointer`
- 统一用 malloc 避免二义性

### 2. 传值和传指针分离

在 `raylib/rcore.rkt` 中定义了两个宏：

```racket
;; 直接传，无包装 — 用于基础类型、指针参数
(def-ffi fn-name "CName" (_fun _int _int -> _void))

;; 自动解引用指针传值 — 用于小结构体传值参数
(def-ffi/unwrap fn-name "CName"
  (_fun (c : _xxx-bytes) -> _void)
  xxx->bytes)
```

`def-ffi/unwrap` 展开为：
```racket
(define fn-name
  (let ([f (get-ffi-obj "CName" lib (_fun (c : _xxx-bytes) -> _void))])
    (λ (x) (f (unwrap x)))))
```

### 3. 常量与绑定分离

- `raylib/` 下只放函数绑定和结构体类型定义
- `raylib-var/` 下放所有固定值（颜色、键值、标志等）
- `raylib-var/core.rkt` 中定义 `make-color`、`vector2` 等辅助构造器
- 用户通过 `(require "raylib/raylib.rkt")` 同时拿到绑定和常量

### 4. 按需绑定

不预先绑定全部 API。从 core 示例开始，用到哪个函数就绑哪个。
每绑一个函数都要有对应的示例可以运行验证。

## 坑和注意事项

### ⚠️ ptr-ref / ptr-set! 的偏移量是元素索引，不是字节

这是最容易出错的坑。`(ptr-ref ptr _float 4)` 读的是**第 4 个 float**（字节 16），不是"字节 4 处的 float"！

```racket
_Vector2 布局: [float x (4B)] [float y (4B)]
                                ^
                        字节 0       字节 4

;; 正确:
(ptr-ref v _float 0)   ;; 第 0 个 float → x  ✅
(ptr-ref v _float 1)   ;; 第 1 个 float → y  ✅

;; 错误:
(ptr-ref v _float 4)   ;; 第 4 个 float → 越界 ❌
```

同理 `ptr-set!`：
```racket
(ptr-set! v _float 0 100.0)  ;; 写 x ✅
(ptr-set! v _float 1 200.0)  ;; 写 y ✅
(ptr-set! v _float 4 200.0)  ;; 写到字节 16 去了 ❌
```

对于 `_ubyte`（1 字节），元素索引 = 字节偏移，所以 `(ptr-ref c _ubyte 0)` 到 `(ptr-ref c _ubyte 3)` 是正确的。

### ⚠️ define-cstruct 的访问器/构造器有契约检查

`define-cstruct` 生成的 `Color-r`、`set-Color-r!`、`make-Color` 等函数有契约检查——它们只接受/返回 tagged pointer（满足 `Color?` 谓词）。

但我们用 `(malloc _Color 'atomic)` 返回的是裸 `cpointer`，不满足 `Color?`。所以必须用 `ptr-ref` / `ptr-set!`。

```racket
;; ❌ 不工作: Color-r 要求 Color? 标签
(T:Color-r c)

;; ✅ 工作: ptr-ref 接受裸 cpointer
(ptr-ref c _ubyte 0)

;; ❌ 不工作: set-Color-r! 要求 Color? 标签
(T:set-Color-r! c 255)

;; ✅ 工作: ptr-set! 接受裸 cpointer
(ptr-set! c _ubyte 0 255)
```

### ⚠️ _list-struct 不能用于 make-ctype

`(_list-struct _ubyte _ubyte _ubyte _ubyte)` 返回的值可以作为 `_fun` 的参数类型，但不是 `ctype?`，不能传给 `make-ctype`。

正确的做法：定义 `_xxx-bytes` 作为底层传值类型，再用 λ 包装做转换。

### ⚠️ malloc 'atomic 不是 C malloc

`(malloc _Color 'atomic)` 用的是 Chez Scheme 的 GC 协作分配器，不是 C 的 `malloc`。比 C malloc 更快，且 GC 自动释放。

文档参考：`'raw`（真 C malloc）最慢，`'atomic`（GC 协作、pinned）中等，Chez 原生分配器最快。这里用 `'atomic` 是因为需要 pinned 内存（可安全传 C 指针）。

### ⚠️ 跨模块前缀 require

`raylib/rcore.rkt` 用 `(prefix-in T: "types.rkt")`，所以引用 types.rkt 的导出时加 `T:` 前缀：

```racket
(define _color-bytes (_list-struct _ubyte _ubyte _ubyte _ubyte))
;; _list-struct 来自 ffi/unsafe，不需要 T: 前缀
```

`raylib-var/core.rkt` 也用 `(prefix-in T: "../raylib/types.rkt")`。

`raylib/rshapes.rkt` 同时引用 types.rkt 和 rcore.rkt：
```racket
(require (prefix-in T: "types.rkt")
         (prefix-in C: "rcore.rkt"))
;; 使用时: T:make-Color, C:color->bytes
```

## 如何实现新绑定

### 步骤

1. 看要翻译的 C 示例 → 确定需要用哪些 C 函数
2. 如果是新结构体 → 在 `types.rkt` 加 `define-cstruct`
3. 如果是新常量（颜色、键值等）→ `raylib-var/core.rkt`
4. 函数绑定：

```racket
;; 简单情况（基础类型参数）:
(def-ffi fn-name "CFunctionName" (_fun _int _float -> _void))

;; 结构体传值（需要 _xxx-bytes + xxx->bytes）:
;;   先在模块中定义 _xxx-bytes 和 xxx->bytes
;;   然后用 def-ffi/unwrap 或手动 λ 包装

;; 手动 λ 包装（多参数混搭）:
(define fn-name
  (let ([f (get-ffi-obj "CFunctionName" T:lib
             (_fun _string _int (c : _color-bytes) -> _void))])
    (λ (a b c) (f a b (color->bytes c)))))
```

5. 在对应模块的 `provide` 列表加新导出
6. 在 `raylib.rkt` 加 `(require ...)` 和 `(all-from-out ...)`
7. 创建示例翻译并验证运行

### 查找 C 函数签名

所有 C 函数声明在 `src/raylib.h`。用 `grep -n "RLAPI.*FunctionName" /home/debian/raylib/src/raylib.h` 查找。

### 运行测试

```bash
cd /home/debian/raylib/racket-bind
timeout 3 racket examples/core/core_xxx.rkt
```

## 已完成示例

| 示例 | 涉及模块 | 新增函数/类型 |
|------|---------|-------------|
| core_basic_window | types, rcore, raylib-var | Color, init-window, close-window, window-should-close?, set-target-fps, begin-drawing, end-drawing, clear-background, draw-text, 26 colors |
| core_delta_time | rcore, rshapes, raylib-var | Vector2, get-frame-time, get-fps, get-mouse-wheel-move, draw-fps, is-key-pressed, draw-circle-v, vector2/x/y/set-x!/set-y! |
| core_input_keys | rcore, rshapes, raylib-var | is-key-down, draw-rectangle, use existing KEY-LEFT/RIGHT/UP/DOWN, draw-circle-v |
| core_input_mouse | rcore, rshapes, raylib-var | is-mouse-button-pressed, get-mouse-position, is-cursor-hidden?, show-cursor, hide-cursor, get-mouse-x/y |
| core_input_mouse_wheel | rcore, rshapes, raylib-var | get-mouse-wheel-move (existing), draw-rectangle |
| core_input_gamepad | rcore, rshapes, rtextures, raylib-var | set-config-flags, is-gamepad-available?, get-gamepad-name, is-gamepad-button-down, get-gamepad-axis-count, get-gamepad-axis-movement, set-gamepad-vibration, get-gamepad-button-pressed, load-texture, unload-texture, draw-texture, draw-circle, draw-rectangle-rounded, draw-triangle, check-collision-point-rec, Rectangle |
| core_input_multitouch | rcore, raylib-var | get-touch-point-count, get-touch-position, get-touch-x/y, get-touch-point-id |
| core_input_gestures | rcore, rshapes, raylib-var | get-gesture-detected, fade, draw-rectangle-rec, draw-rectangle-lines, check-collision-point-rec, get-touch-position |
| core_input_gestures_testbed | rcore, rshapes, raylib-var | draw-line-ex, draw-ring, get-gesture-drag-angle, get-gesture-pinch-angle, is-mouse-button-released, all gestures functions |
| core_2d_camera_mouse_zoom | rcore, raylib-var | Camera2D (already defined), get-screen-width, get-screen-height, get-screen-to-world-2d, draw-grid, rl-push-matrix, rl-pop-matrix, rl-translate-f, rl-rotate-f |
| core_2d_camera_platformer | rcore, raylib-var | get-world-to-screen-2d, 自定义 player/environment struct, 5 种相机跟随模式 (纯 Racket 实现) |
| core_2d_camera_split_screen | rcore, rshapes, rtextures, raylib-var | draw-line-v, load-render-texture, unload-render-texture, begin-texture-mode, end-texture-mode, draw-texture-rec, RenderTexture |
| core_3d_camera_mode | types, rcore, rmodels, raylib-var | Vector3, Camera3D, begin-mode-3d, end-mode-3d, draw-cube, draw-cube-wires, vector3 辅助函数 |
| core_3d_camera_free | types, rcore, rmodels, raylib-var | update-camera, disable-cursor (已有), 复用 core_3d_camera_mode 全部绑定 |
| core_3d_camera_first_person | types, rcore, rmodels, rcamera, raylib-var | draw-plane, camera-yaw, camera-pitch, 复用全部已有绑定 |
| core_3d_camera_split_screen | types, rcore, rshapes, rtextures, rmodels, raylib-var | 复用全部已有绑定（无需新增） |
| core_3d_camera_fps | types, rcore, rshapes, rtextures, rmodels, rcamera, raymath, raylib-var | draw-cube-v, draw-cube-wires-v, draw-sphere, raymath (clamp/lerp/vec2-length/vec2-normalize/vec3-add/vec3-scale/vec3-cross-product/vec3-length/vec3-dot-product/vec3-angle/vec3-negate/vec3-normalize/vec3-rotate-by-axis-angle/vec3-lerp) |
| core_3d_camera_fps | types, rcore, rshapes, rtextures, rmodels, rcamera, raymath, raylib-var | draw-cube-v, draw-cube-wires-v, draw-sphere, raymath (clamp/lerp/vec2-length/vec2-normalize/vec3-add/vec3-scale/vec3-cross-product/vec3-length/vec3-dot-product/vec3-angle/vec3-negate/vec3-normalize/vec3-rotate-by-axis-angle/vec3-lerp) |
| core_3d_picking | types, rcore, rshapes, rmodels, raylib-var | Ray, BoundingBox, RayCollision, get-screen-to-world-ray, get-ray-collision-box, draw-ray, measure-text |
| core_world_screen | types, rcore, rmodels, raylib-var | get-world-to-screen（仅此一个新增） |
| core_window_flags | types, rcore, rshapes, raylib-var | toggle-fullscreen, toggle-borderless-windowed, is-window-state?, set-window-state, clear-window-state, minimize-window, maximize-window, restore-window, draw-rectangle-lines-ex |
| core_window_letterbox | types, rcore, rshapes, rtextures, raymath, raylib-var | set-window-min-size, set-texture-filter, draw-texture-pro, vec2-clamp, TEXTURE-FILTER-BILINEAR |
| core_window_should_close | types, rcore, rshapes, raylib-var | 无需新增绑定 (set-exit-key, KEY-NULL 均已存在) |
| core_monitor_detector | types, rcore, rshapes, raylib-var | get-monitor-count, get-current-monitor, get-monitor-position, get-monitor-name, get-monitor-width, get-monitor-height, get-monitor-physical-width, get-monitor-physical-height, get-monitor-refresh-rate, set-window-monitor, get-window-position, draw-rectangle-v |
| core_scissor_test | rcore, rshapes, raylib-var | begin-scissor-mode, end-scissor-mode (无需新结构体) |
| core_custom_frame_control | rcore, rshapes, raylib-var | get-time, swap-screen-buffer, wait-time (无需新结构体) |
| core_smooth_pixelperfect | rcore, rshapes, rtextures, raylib-var | draw-rectangle-pro (新增), 复用 render-texture/texture-pro/camera2d |
| core_random_sequence | rcore, rshapes, raymath, raylib-var | load-random-sequence (FFI包装), remap (纯Racket) |
| core_custom_logging | types, rcore, raylib-var | set-trace-log-callback, vsnprintf（需 ffi/unsafe 的 function-ptr 创建回调） |
| core_drop_files | rcore, raylib-var | _filepathlist-bytes, is-file-dropped, load-dropped-files（自动读取 C 字符串并释放内存，返回 Racket 字符串列表） |
| core_random_values | rcore, raylib-var | set-random-seed（TextFormat 用 format 替代，不绑定 C 变参函数） |
| core_storage_values | rcore, raylib-var | 无需新增绑定（LoadFileData/SaveFileData 用 Racket file I/O 替代） || core_vr_simulator | types, rcore, rtextures, rmodels, raylib-var | _Shader, _vrdeviceinfo-bytes, _vrstereoconfig-bytes, _shader-bytes, load-shader, unload-shader, get-shader-location, set-shader-value, begin-shader-mode, end-shader-mode, load-vr-stereo-config, unload-vr-stereo-config, begin-vr-stereo-mode, end-vr-stereo-mode, malloc-float-vec2, malloc-float-vec4, SHADER-UNIFORM-* |

| core_monitor_detector | types, rcore, rshapes, raylib-var | get-monitor-count, get-current-monitor, get-monitor-position, get-monitor-name, get-monitor-width, get-monitor-height, get-monitor-physical-width, get-monitor-physical-height, get-monitor-refresh-rate, set-window-monitor, get-window-position, draw-rectangle-v |

| core_window_should_close | types, rcore, rshapes, raylib-var | 无需新增绑定 (set-exit-key, KEY-NULL 均已存在) |

| core_window_letterbox | types, rcore, rshapes, rtextures, raymath, raylib-var | set-window-min-size, set-texture-filter, draw-texture-pro, vec2-clamp, TEXTURE-FILTER-BILINEAR |

| core_window_flags | types, rcore, rshapes, raylib-var | toggle-fullscreen, toggle-borderless-windowed, is-window-state?, set-window-state, clear-window-state, minimize-window, maximize-window, restore-window, draw-rectangle-lines-ex |

| core_world_screen | types, rcore, rmodels, raylib-var | get-world-to-screen（仅此一个新增） |

| core_3d_picking | types, rcore, rshapes, rmodels, raylib-var | Ray, BoundingBox, RayCollision, get-screen-to-world-ray, get-ray-collision-box, draw-ray, measure-text |


| core_automation_events | raylib-racket/automation.rkt, rcore、rshapes、raylib-var | automation-event struct, play-automation-event (FFI), export/load-automation-events, recorder, record-frame!, 23 type constants, 完全纯 Racket 录制，无 C 持指针 |

| | core_render_texture | types, rcore, rshapes, rtextures, raylib-var | 无需新增绑定（全部函数已绑定；rt->texture 辅助函数已在分屏示例定义） |
| | core_undo_redo | types, rcore, rshapes, raylib-var | 无需新增 FFI 绑定；纯 Racket 实现环状缓冲区 Undo/Redo 系统（color=? 辅助函数） |
| | | core_viewport_scaling | types, rcore, rshapes, rtextures, raylib-var | is-window-resized? (新增绑定), 六个视口缩放算法(纯 Racket 实现), screen2render-texture-position |


| | | core_viewport_scaling | types, rcore, rshapes, rtextures, raylib-var | is-window-resized? (新增绑定), 六个视口缩放算法(纯 Racket 实现), screen2render-texture-position |
| | | core_input_actions | rcore, rshapes, raylib-var | 纯 Racket 实现 Action 映射系统 (is-action-pressed?/released?/down?), 无需新增 FFI 绑定 |
| | | core_directory_files | rcore, rshapes, raylib-var | get-working-directory, get-prev-directory-path, directory-exists?, load-directory-files-ex (4 个新增绑定), 用原生 raylib 绘制替代 raygui |
| | | | shapes_rectangle_advanced | rcore, rshapes, rtextures, raylib-var | draw-rectangle-gradient-ex, get-shapes-texture, get-shapes-texture-rectangle, rl-set-texture, rl-begin, rl-end, rl-vertex-2f, rl-tex-coord-2f, rl-color-4ub, RL-QUADS, RL-TRIANGLES, draw-rectangle-rounded-gradient-h（纯 Racket 实现）|
| | | core_highdpi_testbed | rcore, rshapes, raylib-var | get-render-width, get-render-height, get-window-scale-dpi (3 个新增绑定) |
| | | core_screen_recording | rcore, rshapes, raylib-var | _image-bytes, load-image-from-screen, unload-image, get-application-directory, export-image (5 个新增绑定), 用 ExportImage PNG 替代 C 版的 msf_gif GIF |
| | | core_clipboard_text | rcore, rshapes, raylib-var | set-clipboard-text, get-clipboard-text (2 个新增绑定), 用原生 raylib 绘制替代 raygui |
| | | | core_keyboard_testbed | rcore, rshapes, raylib-var | 无需新增绑定。get-key-text 纯 Racket 实现, TraceLog 用 printf 替代 |
| | | | core_compute_hash | rcore, raylib-var | compute-crc32, compute-md5, compute-sha1, compute-sha256, encode-data-base64 (5 个新增绑定), 用原生 raylib 绘制替代 raygui |
| | | | core_window_web | rcore, raylib-var | 无需新增绑定。纯翻译，展示 Web/Desktop 兼容结构 |
| | | | | core_text_file_loading | rcore, raylib-var | _font-bytes, load-file-text(自动释放), get-font-default, measure-text-ex (4 个新增绑定), LoadTextLines 用 string-split 替代, TextFormat 用 format 替代 |
| | textures_image_rotate | rcore, rtextures, raylib-var | load-image (新增), image-rotate (新增), 复用 load-texture-from-image / draw-texture / unload-texture |
| | textures_screen_buffer | rcore, rtextures, raylib-var | gen-image-color (新增), update-texture (新增), draw-texture-ex (新增), 直接 ptr-set! 写 Image.data 指针替代 90k ImageDrawPixel 调用 |




## shapes 模块

| 示例 | 涉及模块 | 新增函数/类型 |
|------|---------|-------------|
| shapes_basic_shapes | rcore, rshapes, raylib-var | draw-circle-gradient, draw-circle-lines, draw-ellipse, draw-ellipse-lines, draw-rectangle-gradient-h, draw-triangle-lines, draw-poly, draw-poly-lines, draw-poly-lines-ex (9 个新绑定) |
| shapes_bouncing_ball | rcore, rshapes, raylib-var | 无需新增绑定（全部函数/常量已存在） |
| shapes_bullet_hell | rcore, rshapes, rtextures, raylib-var | draw-circle-lines-v (1 个新绑定), rt->texture 辅助函数, 纯 Racket Bullet 结构体, 使用 racket/math (cos/sin/pi) |
| shapes_colors_palette | rcore, rshapes, raylib-var | 无需新增绑定（全部函数/颜色常量已存在） |
| shapes_logo_raylib | rcore, rshapes, raylib-var | 无需新增绑定 |
| shapes_logo_raylib_anim | rcore, rshapes, raylib-var | text-subtext (1 个新增绑定) |
| shapes_rectangle_scaling | rcore, rshapes, raylib-var | 无需新增绑定 |
| shapes_lines_bezier | rcore, rshapes, raylib-var | draw-line-bezier, check-collision-point-circle (2 个新增绑定) |
| shapes_collision_area | rcore, rshapes, raylib-var | check-collision-recs, get-collision-rec (2 个新增绑定) |
| shapes_following_eyes | rcore, rshapes, raylib-var | 无需新增绑定（check-collision-point-circle 已绑定，cos/sin/atan 来自 racket/math） |
| shapes_easings_ball | rcore, rshapes, raylib-var | 无需新增 FFI 绑定；纯 Racket 实现 ease-cubic-out, ease-elastic-in, ease-elastic-out（对应 reasings.h） |
| shapes_easings_box | rcore, rshapes, raylib-var | 无需新增 FFI 绑定；纯 Racket 实现 ease-elastic-out, ease-bounce-out, ease-quad-out, ease-circ-out, ease-sine-out |
| shapes_easings_rectangles | rcore, rshapes, raylib-var | 无需新增 FFI 绑定；纯 Racket 实现 ease-circ-out, ease-linear-in |
| | shapes_rectangle_advanced | rcore, rshapes, rtextures, raylib-var | draw-rectangle-gradient-ex, get-shapes-texture, get-shapes-texture-rectangle, rl-set-texture, rl-begin, rl-end, rl-vertex-2f, rl-tex-coord-2f, rl-color-4ub, RL-QUADS, RL-TRIANGLES, draw-rectangle-rounded-gradient-h（纯 Racket 实现，对应 C 的 static 自定义函数）|
| | shapes_splines_drawing | rcore, rshapes, raylib-var | draw-spline-linear, draw-spline-basis, draw-spline-catmull-rom, draw-spline-bezier-cubic, draw-spline-segment-linear, draw-spline-segment-basis, draw-spline-segment-catmull-rom, draw-spline-segment-bezier-cubic, vec2-vector->float-buf（8 个 FFI 绑定 + 1 个辅助函数）；键盘控制替代 raygui |
| | shapes_double_pendulum | rcore, rshapes, rtextures, raylib-var | 无需新增 FFI 绑定；纯 Racket 实现双摆物理模拟（RK 积分）+ RenderTexture 轨迹拖尾 |
| | shapes_starfield_effect | rcore, rshapes, raymath, raylib-var | 无需新增 FFI 绑定 |
| | shapes_simple_particles | rcore, rshapes, raylib-var | 无需新增 FFI 绑定；纯 Racket 实现环形缓冲粒子系统（3 种粒子类型：WATER/SMOKE/FIRE）|
| | shapes_mouse_trail | rcore, rshapes, raylib-var | 无需新增 FFI 绑定 |
| | shapes_clock_of_clocks | rcore, rshapes, raymath, raylib-var | 无需新增 FFI 绑定；color-lerp 纯 Racket 实现。SKIP: runtime cpointer error |
| | shapes_kaleidoscope | rcore, rshapes, raymath, raylib-var | vec2-multiply, vec2-rotate（2 个纯 Racket 辅助函数）；键盘控制替代 raygui |
| | shapes_pie_chart | rcore, rshapes, rtext, raylib-var | 无需新增 FFI 绑定；键盘控制替代 raygui |
| | shapes_vector_angle | rcore, rshapes, raymath, raylib-var | 无需新增 FFI 绑定；vec2-angle、vec2-line-angle 纯 Racket 实现 |
| | shapes_triangle_strip | rcore, rshapes, raylib-var | color-from-hsv（1 个 FFI 绑定）；键盘控制替代 raygui |
| | shapes_dashed_line | rcore, rshapes, raylib-var | draw-line-dashed（1 个 FFI 绑定）|
| | shapes_digital_clock | rcore, rshapes, raylib-var | draw-triangle-strip（1 个 FFI 绑定）；纯 Racket 实现 7 段数码管 + 模拟表盘双模式时钟，SPACE 切换 |


