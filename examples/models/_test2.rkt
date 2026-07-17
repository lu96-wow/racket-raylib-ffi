#lang racket/base

;; 测试2: 自定义着色器，从简单到复杂
(require "../../raylib/raylib.rkt"
         racket/runtime-path
         (only-in ffi/unsafe malloc))

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))
(define GLSL-VERSION 330)

(init-window 800 450 "test: 1=default 2=custom+red")

;; 着色器
(define shader (load-shader
                (res (format "shaders/glsl~a/voxel_lighting.vs" GLSL-VERSION))
                (res (format "shaders/glsl~a/voxel_lighting.fs" GLSL-VERSION))))
(printf "shader loaded: id=~a list=~a\n" (car shader) shader)

;; 设置 ambient 为红色
(define ambient-loc (get-shader-location shader "ambient"))
(printf "ambient loc = ~a\n" ambient-loc)
(set-shader-value shader ambient-loc
                  (malloc-float-vec4 2.0 0.0 0.0 1.0) SHADER-UNIFORM-VEC4)

;; 加载两个独立模型
(define m1 (load-model (res "models/vox/chr_knight.vox")))
(define m2 (load-model (res "models/vox/chr_knight.vox")))

;; m2 赋自定义着色器
(printf "m2 mat[0].shader.id before = ~a\n" (ptr-ref (list-ref m2 19) _uint 0))
(for ([j (in-range (list-ref m2 17))])
  (set-material-shader (ptr-add (list-ref m2 19) (* j 40)) shader))
(printf "m2 mat[0].shader.id after  = ~a\n" (ptr-ref (list-ref m2 19) _uint 0))

(define camera (camera3d 10.0 10.0 10.0  0.0 0.0 0.0  0.0 1.0 0.0 45.0 CAMERA-PERSPECTIVE))
(define pos (vector3 0.0 0.0 0.0))
(define mode 0)

(let loop ()
  (unless (window-should-close?)
    (when (is-key-pressed KEY-ONE)   (set! mode 0))
    (when (is-key-pressed KEY-TWO)   (set! mode 1))
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (if (= mode 0)
        (draw-model m1 pos 1.0 WHITE)
        (draw-model m2 pos 1.0 WHITE))
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text (if (= mode 0) "1:默认shader" "2:自定义shader(红色ambient)") 10 10 20 BLACK)
    (end-drawing)
    (loop)))

(unload-model m1) (unload-model m2)
(close-window)
