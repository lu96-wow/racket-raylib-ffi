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
;; 基础类型 — _bool 跨平台兼容
;; ============================================================

(define _bool
  (if (eq? (system-type 'so-mode) 'big-endian)
      _int8
      _int32))

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
 set-Rectangle-x! set-Rectangle-y! set-Rectangle-width! set-Rectangle-height!)

