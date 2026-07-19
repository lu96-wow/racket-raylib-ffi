#lang racket/base

;; raylib [shaders] example - vertex displacement (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_vertex_displacement.c
;;
;; 功能: 使用 vertex shader 对平面做 Perlin noise 顶点位移
;; 注意: 不使用 rlights.h (尽管 C 代码 include 了但未实际使用)

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! _float malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "raylib [shaders] example - vertex displacement")

;; camera
(define camera (camera3d 20.0 5.0 -20.0  0.0 0.0 0.0  0.0 1.0 0.0  60.0 CAMERA-PERSPECTIVE))

;; load shader
(define shader (load-shader (res (format "shaders/glsl~a/vertex_displacement.vs" GLSL-VERSION))
                            (res (format "shaders/glsl~a/vertex_displacement.fs" GLSL-VERSION))))

;; load perlin noise texture and bind to sampler
(define perlin-image (gen-image-perlin-noise 512 512 0 0 1.0))
(define perlin-map (load-texture-from-image perlin-image))
(unload-image perlin-image)

(define perlin-loc (get-shader-location shader "perlinNoiseMap"))
(rl-enable-shader (car shader))
(rl-active-texture-slot 1)
(rl-enable-texture (car perlin-map))
(rl-set-uniform-sampler perlin-loc 1)

;; create plane mesh and model
(define plane-mesh (gen-mesh-plane 50.0 50.0 50 50))
(define plane-model (load-model-from-mesh plane-mesh))

;; apply shader to model
(define mats-ptr (list-ref plane-model 19))
(set-material-shader mats-ptr shader)

(define time 0.0)
(define time-buf (malloc _float 1 'atomic))
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-FREE)

    (set! time (+ time (get-frame-time)))
    (ptr-set! time-buf _float 0 time)
    (set-shader-value shader (get-shader-location shader "time") time-buf SHADER-UNIFORM-FLOAT)

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (begin-shader-mode shader)
    (draw-model plane-model (vector3 0.0 0.0 0.0) 1.0 WHITE)
    (end-shader-mode)
    (end-mode-3d)
    (draw-text "Vertex displacement" 10 10 20 DARKGRAY)
    (draw-fps 10 40)
    (end-drawing)
    (loop)))

(unload-shader shader)
(unload-model plane-model)
(unload-texture perlin-map)
(close-window)
