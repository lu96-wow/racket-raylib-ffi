#lang racket/base

;; raylib [shaders] example - custom uniform (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_custom_uniform.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! _float malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "raylib [shaders] example - custom uniform")

(define camera (camera3d 8.0 8.0 8.0  0.0 1.5 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

(define model (load-model (res "models/barracks.obj")))
(define texture (load-texture (res "models/barracks_diffuse.png")))
(let ([mats-ptr (list-ref model 19)])
  (set-material-texture mats-ptr MATERIAL-MAP-DIFFUSE texture))
(define position (vector3 0.0 0.0 0.0))

(define shader (load-shader #f (res (format "shaders/glsl~a/swirl.fs" GLSL-VERSION))))
(define swirl-center-loc (get-shader-location shader "center"))
(define swirl-center (malloc _float 2 'atomic))

(define target (load-render-texture 800 450))
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-ORBITAL)

    (let ([mp (get-mouse-position)])
      (ptr-set! swirl-center _float 0 (ptr-ref mp _float 0))
      (ptr-set! swirl-center _float 1 (- 450.0 (ptr-ref mp _float 1))))
    (set-shader-value shader swirl-center-loc swirl-center SHADER-UNIFORM-VEC2)

    ;; 渲染到纹理
    (begin-texture-mode target)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (draw-model model position 0.5 WHITE)
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text "TEXT DRAWN IN RENDER TEXTURE" 200 10 30 RED)
    (end-texture-mode)

    ;; 画到屏幕
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-shader-mode shader)
    (define target-tex (list (list-ref target 1) (list-ref target 2)
                              (list-ref target 3) (list-ref target 4)
                              (list-ref target 5)))
    (draw-texture-rec target-tex
                      (rectangle 0.0 0.0 (list-ref target 2) (- (list-ref target 3)))
                      (vector2 0.0 0.0) WHITE)
    (end-shader-mode)
    (draw-text "(c) Barracks 3D model by Alberto Cano" (- 800 220) (- 450 20) 10 GRAY)
    (draw-fps 10 10)
    (end-drawing)
    (loop)))

(unload-shader shader)
(unload-texture texture)
(unload-model model)
(unload-render-texture target)
(close-window)
