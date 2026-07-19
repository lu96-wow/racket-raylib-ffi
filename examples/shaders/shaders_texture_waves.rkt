#lang racket/base

;; raylib [shaders] example - texture waves (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_texture_waves.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! _float malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "raylib [shaders] example - texture waves")

(define tex (load-texture (res "space.png")))
(define shader (load-shader #f (res (format "shaders/glsl~a/wave.fs" GLSL-VERSION))))

(define seconds-loc (get-shader-location shader "seconds"))
(define freq-x-loc  (get-shader-location shader "freqX"))
(define freq-y-loc  (get-shader-location shader "freqY"))
(define amp-x-loc   (get-shader-location shader "ampX"))
(define amp-y-loc   (get-shader-location shader "ampY"))
(define speed-x-loc (get-shader-location shader "speedX"))
(define speed-y-loc (get-shader-location shader "speedY"))
(define size-loc    (get-shader-location shader "size"))

(define freq-x  (malloc _float 1 'atomic)) (ptr-set! freq-x  _float 0 25.0)
(define freq-y  (malloc _float 1 'atomic)) (ptr-set! freq-y  _float 0 25.0)
(define amp-x   (malloc _float 1 'atomic)) (ptr-set! amp-x   _float 0 5.0)
(define amp-y   (malloc _float 1 'atomic)) (ptr-set! amp-y   _float 0 5.0)
(define speed-x (malloc _float 1 'atomic)) (ptr-set! speed-x _float 0 8.0)
(define speed-y (malloc _float 1 'atomic)) (ptr-set! speed-y _float 0 8.0)
(define seconds (malloc _float 1 'atomic)) (ptr-set! seconds _float 0 0.0)

(define screen-size (malloc _float 2 'atomic))
(ptr-set! screen-size _float 0 800.0) (ptr-set! screen-size _float 1 450.0)
(set-shader-value shader size-loc screen-size SHADER-UNIFORM-VEC2)
(set-shader-value shader freq-x-loc freq-x SHADER-UNIFORM-FLOAT)
(set-shader-value shader freq-y-loc freq-y SHADER-UNIFORM-FLOAT)
(set-shader-value shader amp-x-loc amp-x SHADER-UNIFORM-FLOAT)
(set-shader-value shader amp-y-loc amp-y SHADER-UNIFORM-FLOAT)
(set-shader-value shader speed-x-loc speed-x SHADER-UNIFORM-FLOAT)
(set-shader-value shader speed-y-loc speed-y SHADER-UNIFORM-FLOAT)

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (ptr-set! seconds _float 0 (+ (ptr-ref seconds _float 0) (get-frame-time)))
    (set-shader-value shader seconds-loc seconds SHADER-UNIFORM-FLOAT)

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-shader-mode shader)
    (draw-texture tex 0 0 WHITE)
    (draw-texture tex (list-ref tex 1) 0 WHITE)
    (end-shader-mode)
    (end-drawing)
    (loop)))

(unload-texture tex) (unload-shader shader) (close-window)
