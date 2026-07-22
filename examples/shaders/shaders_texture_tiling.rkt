#lang racket/base

;; raylib [shaders] example - texture tiling (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_texture_tiling.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! _float malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "raylib [shaders] example - texture tiling")

(define camera (camera3d 4.0 4.0 4.0  0.0 0.5 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

;; 创建立方体模型
(define cube-mesh (gen-mesh-cube 1.0 1.0 1.0))
(define model (load-model-from-mesh cube-mesh))

;; 加载纹理并设置为模型材质
(define texture (load-texture (res "cubicmap_atlas.png")))
(let ([mats-ptr (model-materials model)])
  (set-material-texture mats-ptr MATERIAL-MAP-DIFFUSE texture))

;; 加载 tiling 着色器
(define shader (load-shader #f (res (format "shaders/glsl~a/tiling.fs" GLSL-VERSION))))
(set-texture-wrap texture TEXTURE-WRAP-REPEAT)

;; 设置 tiling uniform
(define tiling-val (malloc _float 2 'atomic))
(ptr-set! tiling-val _float 0 3.0) (ptr-set! tiling-val _float 1 3.0)
(set-shader-value shader (get-shader-location shader "tiling") tiling-val SHADER-UNIFORM-VEC2)

;; 给模型设置着色器
(let ([mats-ptr (model-materials model)])
  (set-material-shader mats-ptr shader))

(disable-cursor)
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-FREE)

    (when (is-key-pressed 90)  ;; KEY_Z
      (set-camera3d-tar-x! camera 0.0)
      (set-camera3d-tar-y! camera 0.5)
      (set-camera3d-tar-z! camera 0.0))

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (begin-shader-mode shader)
    (draw-model model (vector3 0.0 0.0 0.0) 2.0 WHITE)
    (end-shader-mode)
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text "Use mouse to rotate the camera" 10 10 20 DARKGRAY)
    (end-drawing)
    (loop)))

(unload-model model)
(unload-shader shader)
(unload-texture texture)
(close-window)
