#lang racket/base

;; raylib [shaders] example - mesh instancing (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_mesh_instancing.c
;;
;; 功能: 使用 GPU 实例化渲染 10000 个随机位置/旋转的立方体

(require "../../raylib/raylib.rkt"
         "../../raylib/core/rlights.rkt"
         racket/runtime-path
         racket/math
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref _float _int _uint malloc))

(define GLSL-VERSION 330)
(define MAX-INSTANCES 10000)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "raylib [shaders] example - mesh instancing")

(define camera (camera3d -125.0 125.0 -125.0  0.0 0.0 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

;; create cube mesh
(define cube (gen-mesh-cube 1.0 1.0 1.0))

;; allocate transforms buffer (MAX-INSTANCES × 16 floats)
(define transforms (malloc _float (* MAX-INSTANCES 16) 'atomic))

;; generate random transforms
(for ([i (in-range MAX-INSTANCES)])
  (define tx (get-random-float -50 50))
  (define ty (get-random-float -50 50))
  (define tz (get-random-float -50 50))
  (define translation (matrix-translate tx ty tz))
  (define rx (* (get-random-float 0 360) (/ pi 180.0)))
  (define ry (* (get-random-float 0 360) (/ pi 180.0)))
  (define rz (* (get-random-float 0 360) (/ pi 180.0)))
  (define rotation (matrix-rotate-xyz (vector3 rx ry rz)))
  (define m (matrix-multiply rotation translation))
  (for ([j (in-range 16)])
    (ptr-set! transforms _float (+ (* i 16) j) (list-ref m j))))

;; load lighting shader with instancing
(define shader (load-shader (res (format "shaders/glsl~a/lighting_instancing.vs" GLSL-VERSION))
                            (res (format "shaders/glsl~a/lighting.fs" GLSL-VERSION))))
(let ([locs-ptr (shader-list-locs shader)])
  (ptr-set! locs-ptr _int SHADER-LOC-MATRIX-MVP (get-shader-location shader "mvp"))
  (ptr-set! locs-ptr _int SHADER-LOC-VECTOR-VIEW (get-shader-location shader "viewPos")))

;; ambient light
(set-shader-value-vec4 shader (get-shader-location shader "ambient")
                       (vector4 0.2 0.2 0.2 1.0))

;; create light
(reset-lights!)
(create-light LIGHT-DIRECTIONAL 50.0 50.0 0.0 0.0 0.0 0.0 WHITE shader)

;; material for instanced drawing (RED)
(define mat-ptr-inst (load-material-default))
(set-material-shader mat-ptr-inst shader)
(set-material-color mat-ptr-inst MATERIAL-MAP-DIFFUSE RED)
(define mat-inst (material-ptr->list mat-ptr-inst))

;; default material (BLUE)
(define mat-ptr-def (load-material-default))
(set-material-color mat-ptr-def MATERIAL-MAP-DIFFUSE BLUE)
(define mat-def (material-ptr->list mat-ptr-def))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-ORBITAL)

    ;; 用 set-shader-value-vec3 替代手动 malloc + ptr-set!
    (set-shader-value-vec3 shader
      (ptr-ref (shader-list-locs shader) _int SHADER-LOC-VECTOR-VIEW)
      (camera3d-position camera))

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)

    ;; single blue cube
    (draw-mesh cube mat-def (matrix-translate -10.0 0.0 0.0))

    ;; 10000 instanced red cubes with lighting
    (draw-mesh-instanced cube mat-inst transforms MAX-INSTANCES)

    ;; single blue cube
    (draw-mesh cube mat-def (matrix-translate 10.0 0.0 0.0))

    (end-mode-3d)
    (draw-fps 10 10)
    (end-drawing)
    (loop)))

(close-window)
