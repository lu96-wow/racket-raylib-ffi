#lang racket/base

;; raylib [shaders] example - shapes textures (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_shapes_textures.c

(require "../../raylib/raylib.rkt" racket/runtime-path)

(define GLSL-VERSION 330)
(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "raylib [shaders] example - shapes textures")

(define fudesumi (load-texture (res "fudesumi.png")))
(define shader (load-shader #f (res (format "shaders/glsl~a/grayscale.fs" GLSL-VERSION))))
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 默认着色器
    (draw-text "USING DEFAULT SHADER" 20 40 10 RED)
    (draw-circle 80 120 35.0 DARKBLUE)
    (draw-circle-gradient (vector2 80.0 220.0) 60.0 GREEN SKYBLUE)
    (draw-circle-lines 80 340 80.0 DARKBLUE)

    ;; 自定义着色器 (灰度)
    (begin-shader-mode shader)
    (draw-text "USING CUSTOM SHADER" 190 40 10 RED)
    (draw-rectangle (- 250 60) 90 120 60 RED)
    (draw-rectangle-gradient-h (- 250 90) 170 180 130 MAROON GOLD)
    (draw-rectangle-lines (- 250 40) 320 80 60 ORANGE)
    (end-shader-mode)

    ;; 回到默认着色器
    (draw-text "USING DEFAULT SHADER" 370 40 10 RED)
    (draw-triangle (vector2 430 80)
                   (vector2 (- 430 60) 150)
                   (vector2 (+ 430 60) 150) VIOLET)
    (draw-triangle-lines (vector2 430 160)
                         (vector2 (- 430 20) 230)
                         (vector2 (+ 430 20) 230) DARKBLUE)
    (draw-poly (vector2 430 320) 6 80.0 0.0 BROWN)

    ;; 自定义着色器画纹理
    (begin-shader-mode shader)
    (draw-texture fudesumi 500 -30 WHITE)
    (end-shader-mode)

    (draw-text "(c) Fudesumi sprite by Eiden Marsal" 380 (- 450 20) 10 GRAY)
    (end-drawing) (loop)))

(unload-shader shader) (unload-texture fudesumi) (close-window)
