#lang racket/base

;; raylib [shaders] example - ASCII rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_ascii_rendering.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! _float malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "raylib [shaders] example - ASCII rendering")

(define fudesumi (load-texture (res "fudesumi.png")))
(define raysan   (load-texture (res "raysan.png")))

(define shader (load-shader #f (res (format "shaders/glsl~a/ascii.fs" GLSL-VERSION))))
(define resolution-loc (get-shader-location shader "resolution"))
(define font-size-loc (get-shader-location shader "fontSize"))

(define font-size-val (malloc _float 1 'atomic))
(ptr-set! font-size-val _float 0 9.0)
(define resolution (malloc _float 2 'atomic))
(ptr-set! resolution _float 0 800.0) (ptr-set! resolution _float 1 450.0)
(set-shader-value shader resolution-loc resolution SHADER-UNIFORM-VEC2)

(define circle-pos-x (malloc _float 1 'atomic))
(ptr-set! circle-pos-x _float 0 40.0)
(define circle-speed 1.0)

(define target (load-render-texture 800 450))
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    ;; Update
    (let ([nx (+ (ptr-ref circle-pos-x _float 0) circle-speed)])
      (when (or (> nx 200.0) (< nx 40.0)) (set! circle-speed (* circle-speed -1)))
      (ptr-set! circle-pos-x _float 0 nx))

    (when (and (is-key-pressed KEY-LEFT)  (> (ptr-ref font-size-val _float 0) 9.0))
      (ptr-set! font-size-val _float 0 (- (ptr-ref font-size-val _float 0) 1.0)))
    (when (and (is-key-pressed KEY-RIGHT) (< (ptr-ref font-size-val _float 0) 15.0))
      (ptr-set! font-size-val _float 0 (+ (ptr-ref font-size-val _float 0) 1.0)))

    (set-shader-value shader font-size-loc font-size-val SHADER-UNIFORM-FLOAT)

    ;; 渲染场景到 RenderTexture
    (begin-texture-mode target)
    (clear-background WHITE)
    (draw-texture fudesumi 500 -30 WHITE)
    (draw-texture-v raysan (vector2 (ptr-ref circle-pos-x _float 0) 225.0) WHITE)
    (end-texture-mode)

    ;; 画到屏幕 (用 ASCII 着色器)
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-shader-mode shader)
    (let ([tex (list (render-texture-tex-id target) (render-texture-tex-width target) (render-texture-tex-height target) (render-texture-tex-mipmaps target) (render-texture-tex-format target))])
      (draw-texture-rec tex
                      (rectangle 0.0 0.0 (render-texture-tex-width target) (- (render-texture-tex-height target)))
                      (vector2 0.0 0.0) WHITE))
    (end-shader-mode)

    (draw-rectangle 0 0 800 40 BLACK)
    (draw-text (format "Ascii effect - FontSize:~a - [Left] -1 [Right] +1 " (inexact->exact (round (ptr-ref font-size-val _float 0))))
               120 10 20 LIGHTGRAY)
    (draw-fps 10 10)
    (end-drawing)
    (loop)))

(unload-render-texture target)
(unload-shader shader)
(unload-texture fudesumi) (unload-texture raysan)
(close-window)
