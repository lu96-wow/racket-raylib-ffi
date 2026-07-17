#lang racket/base

;; raylib [shaders] example - model shader (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_model_shader.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe get-ffi-obj _fun _pointer _string))

(define lib (ffi-lib "/home/debian/raylib/build/raylib/libraylib.so"))
(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(define (load-fs-only-shader fs-filename)
  (let ([f (get-ffi-obj "LoadShader" lib (_fun _pointer _string -> _shader-bytes))])
    (f #f fs-filename)))

(init-window 800 450 "raylib [shaders] example - model shader")

(define camera (camera3d 4.0 4.0 4.0  0.0 1.0 -1.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

(define model (load-model (res "models/watermill.obj")))
(define texture (load-texture (res "models/watermill_diffuse.png")))
(define shader (load-fs-only-shader (res (format "shaders/glsl~a/grayscale.fs" GLSL-VERSION))))

(let ([mats-ptr (list-ref model 19)])
  (set-material-shader mats-ptr shader)
  (set-material-texture mats-ptr MATERIAL-MAP-DIFFUSE texture))

(define position (vector3 0.0 0.0 0.0))
(disable-cursor)
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-FREE)
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (draw-model model position 0.2 WHITE)
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text "(c) Watermill 3D model by Alberto Cano" (- 800 210) (- 450 20) 10 GRAY)
    (draw-fps 10 10)
    (end-drawing)
    (loop)))

(unload-shader shader)
(unload-texture texture)
(unload-model model)
(close-window)
