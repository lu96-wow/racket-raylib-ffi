#lang racket/base

;; raylib [shaders] example - Eratosthenes sieve (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_eratosthenes_sieve.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "raylib [shaders] example - eratosthenes sieve")

(define target (load-render-texture 800 450))
(define shader (load-shader #f (res (format "shaders/glsl~a/eratosthenes.fs" GLSL-VERSION))))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    ;; 渲染到 RenderTexture
    (begin-texture-mode target)
    (clear-background BLACK)
    (draw-rectangle 0 0 800 450 BLACK)
    (end-texture-mode)

    ;; 画到屏幕 (使用 Eratosthenes 着色器)
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-shader-mode shader)
    ;; RenderTexture 需要 Y 轴翻转
    (draw-texture-rec (list (render-texture-tex-id target) (render-texture-tex-width target) (render-texture-tex-height target) (render-texture-tex-mipmaps target) (render-texture-tex-format target))
                      (rectangle 0.0 0.0 800.0 -450.0)
                      (vector2 0.0 0.0) WHITE)
    (end-shader-mode)
    (end-drawing)
    (loop)))

(unload-shader shader)
(unload-render-texture target)
(close-window)
