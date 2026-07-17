#lang racket/base

;; raylib [shaders] example - texture rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_texture_rendering.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-ref ptr-set! _float malloc get-ffi-obj _fun _pointer _string))

(define lib (ffi-lib "/home/debian/raylib/build/raylib/libraylib.so"))

;; ============================================================
;; 常量
;; ============================================================

(define GLSL-VERSION 330)

;; ============================================================
;; 辅助: 加载只有 fragment shader 的着色器 (vs=NULL)
;; ============================================================

(define (load-fs-only-shader fs-filename)
  (let ([f (get-ffi-obj "LoadShader" lib (_fun _pointer _string -> _shader-bytes))])
    (f #f fs-filename)))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window screen-width screen-height "raylib [shaders] example - texture rendering")

;; 创建空白纹理
(define im-blank (gen-image-color 1024 1024 BLANK))
(define texture (load-texture-from-image im-blank))
(unload-image im-blank)

;; 加载着色器 (仅 fragment shader)
(define shader (load-fs-only-shader
                (res (format "shaders/glsl~a/cubes_panning.fs" GLSL-VERSION))))

(define time-loc (get-shader-location shader "uTime"))
(define time-ptr (malloc _float 1 'atomic))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)

    ;; Update
    (ptr-set! time-ptr _float 0 (get-time))
    (set-shader-value shader time-loc time-ptr SHADER-UNIFORM-FLOAT)

    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-shader-mode shader)
    (draw-texture texture 0 0 WHITE)
    (end-shader-mode)

    (draw-text "BACKGROUND is PAINTED and ANIMATED on SHADER!" 10 10 20 MAROON)
    (end-drawing)
    (loop)))

(unload-shader shader)
(unload-texture texture)
(close-window)
