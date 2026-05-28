#lang racket/base

;; raylib 结构体/类型定义
;;
;; 对应 raylib.h 的类型定义部分 (struct, enum, typedef)
;; 所有结构体用 define-cstruct 定义，Racket 侧一律按指针操作
;;
;; 设计约定:
;;   - 在 Racket 中通过 make-Xxx 构造 boxed 指针
;;   - 对 C 侧传值的小结构体 (Color, Vector2 等),
;;     由各模块定义对应的 _xxx-pass 类型自动解包
;;
;; 导出: _Color, _Vector2 等类型 + make-Xxx / Xxx? / 字段访问器

(require ffi/unsafe)

;; ============================================================
;; 共享库
;; ============================================================

(define lib
  (ffi-lib "/home/debian/raylib/build/raylib/libraylib.so"))

;; ============================================================
;; 基础类型 — bool 类型
;; ffi/unsafe 提供两个布尔类型：
;;   _stdbool → 1 字节，匹配 C99 的 _Bool（raylib 使用 <stdbool.h>）
;;   _bool    → 4 字节，匹配 C 的 int（不匹配 raylib！）
;; 这里让 _bool 指向 _stdbool，确保所有 FFI 绑定使用正确的 1 字节版
;; ============================================================

(define _bool _stdbool)

;; ============================================================
;; Color (raylib.h:248) — 4 字节小结构体
;; ============================================================

(define-cstruct _Color
  ([r _ubyte]
   [g _ubyte]
   [b _ubyte]
   [a _ubyte]))

;; Vector2 (raylib.h:216)
(define-cstruct _Vector2
  ([x _float]
   [y _float]))

;; Rectangle (raylib.h:256)
(define-cstruct _Rectangle
  ([x _float]
   [y _float]
   [width _float]
   [height _float]))

;; Camera2D (raylib.h:338)
;;   Vector2 offset;    // offset.x @ _float 0, offset.y @ _float 1
;;   Vector2 target;    // target.x @ _float 2, target.y @ _float 3
;;   float rotation;    // @ _float 4
;;   float zoom;        // @ _float 5
(define-cstruct _Camera2D
  ([off-x _float]
   [off-y _float]
   [tar-x _float]
   [tar-y _float]
   [rotation _float]
   [zoom _float]))

;; ============================================================
;; 导出
;; ============================================================

(provide
 lib _bool
 ;; Color
 _Color Color? make-Color
 Color-r Color-g Color-b Color-a
 set-Color-r! set-Color-g! set-Color-b! set-Color-a!
 ;; Vector2
 _Vector2 Vector2? make-Vector2
 Vector2-x Vector2-y
 set-Vector2-x! set-Vector2-y!
 ;; Rectangle
 _Rectangle Rectangle? make-Rectangle
 Rectangle-x Rectangle-y Rectangle-width Rectangle-height
 set-Rectangle-x! set-Rectangle-y! set-Rectangle-width! set-Rectangle-height!
 ;; Camera2D
 _Camera2D Camera2D? make-Camera2D
 Camera2D-off-x Camera2D-off-y
 Camera2D-tar-x Camera2D-tar-y
 Camera2D-rotation Camera2D-zoom
 set-Camera2D-off-x! set-Camera2D-off-y!
 set-Camera2D-tar-x! set-Camera2D-tar-y!
 set-Camera2D-rotation! set-Camera2D-zoom!)

