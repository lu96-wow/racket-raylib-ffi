#lang racket/base

;; raylib [shaders] example - texture outline (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_texture_outline.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! _float malloc get-ffi-obj _fun _pointer _string))

(define lib (ffi-lib "/home/debian/raylib/build/raylib/libraylib.so"))
(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(define (load-fs-only-shader fs-filename)
  (let ([f (get-ffi-obj "LoadShader" lib (_fun _pointer _string -> _shader-bytes))])
    (f #f fs-filename)))

(init-window 800 450 "raylib [shaders] example - texture outline")

(define texture (load-texture (res "fudesumi.png")))
(define shdr-outline (load-fs-only-shader (res (format "shaders/glsl~a/outline.fs" GLSL-VERSION))))

(define outline-size-ptr (malloc _float 1 'atomic))
(ptr-set! outline-size-ptr _float 0 2.0)
(define outline-color (malloc _float 4 'atomic))
(ptr-set! outline-color _float 0 1.0)
(ptr-set! outline-color _float 1 0.0)
(ptr-set! outline-color _float 2 0.0)
(ptr-set! outline-color _float 3 1.0)
(define texture-size (malloc _float 2 'atomic))
(ptr-set! texture-size _float 0 (exact->inexact (list-ref texture 1)))
(ptr-set! texture-size _float 1 (exact->inexact (list-ref texture 2)))

(define outline-size-loc (get-shader-location shdr-outline "outlineSize"))
(define outline-color-loc (get-shader-location shdr-outline "outlineColor"))
(define texture-size-loc (get-shader-location shdr-outline "textureSize"))

(set-shader-value shdr-outline outline-size-loc outline-size-ptr SHADER-UNIFORM-FLOAT)
(set-shader-value shdr-outline outline-color-loc outline-color SHADER-UNIFORM-VEC4)
(set-shader-value shdr-outline texture-size-loc texture-size SHADER-UNIFORM-VEC2)

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (let ([s (+ (ptr-ref outline-size-ptr _float 0) (get-mouse-wheel-move))])
      (ptr-set! outline-size-ptr _float 0 (max 1.0 s)))
    (set-shader-value shdr-outline outline-size-loc outline-size-ptr SHADER-UNIFORM-FLOAT)

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-shader-mode shdr-outline)
    (draw-texture texture (- (/ (get-screen-width) 2) (/ (list-ref texture 1) 2)) -30 WHITE)
    (end-shader-mode)
    (draw-text "Shader-based\ntexture\noutline" 10 10 20 GRAY)
    (draw-text "Scroll mouse wheel to\nchange outline size" 10 72 20 GRAY)
    (draw-text (format "Outline size: ~a px" (inexact->exact (round (ptr-ref outline-size-ptr _float 0)))) 10 120 20 MAROON)
    (draw-fps 710 10)
    (end-drawing)
    (loop)))

(unload-texture texture)
(unload-shader shdr-outline)
(close-window)
