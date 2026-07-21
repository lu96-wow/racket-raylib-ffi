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
         (only-in ffi/unsafe ptr-set! ptr-ref _float _int _uint _ubyte malloc))

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
  (define tx (exact->inexact (get-random-value -50 50)))
  (define ty (exact->inexact (get-random-value -50 50)))
  (define tz (exact->inexact (get-random-value -50 50)))
  (define translation (matrix-translate tx ty tz))
  (define rx (* (exact->inexact (get-random-value 0 360)) (/ pi 180.0)))
  (define ry (* (exact->inexact (get-random-value 0 360)) (/ pi 180.0)))
  (define rz (* (exact->inexact (get-random-value 0 360)) (/ pi 180.0)))
  (define rotation (matrix-rotate-xyz (vector3 rx ry rz)))
  (define m (matrix-multiply rotation translation))
  (for ([j (in-range 16)])
    (ptr-set! transforms _float (+ (* i 16) j) (list-ref m j))))

;; load lighting shader with instancing
(define shader (load-shader (res (format "shaders/glsl~a/lighting_instancing.vs" GLSL-VERSION))
                            (res (format "shaders/glsl~a/lighting.fs" GLSL-VERSION))))
(let ([locs-ptr (caddr shader)])
  (ptr-set! locs-ptr _int SHADER-LOC-MATRIX-MVP (get-shader-location shader "mvp"))
  (ptr-set! locs-ptr _int SHADER-LOC-VECTOR-VIEW (get-shader-location shader "viewPos")))

;; ambient light
(define ambient-buf (malloc _float 4 'atomic))
(ptr-set! ambient-buf _float 0 0.2) (ptr-set! ambient-buf _float 1 0.2)
(ptr-set! ambient-buf _float 2 0.2) (ptr-set! ambient-buf _float 3 1.0)
(set-shader-value shader (get-shader-location shader "ambient") ambient-buf SHADER-UNIFORM-VEC4)

;; create light
(reset-lights!)
(create-light LIGHT-DIRECTIONAL 50.0 50.0 0.0 0.0 0.0 0.0
              (color-r WHITE) (color-g WHITE) (color-b WHITE) (color-a WHITE) shader)

;; material for instanced drawing (RED)
(define mat-ptr-inst (load-material-default))
(set-material-shader mat-ptr-inst shader)
(define red-color-ptr (malloc _ubyte 4 'atomic))
(ptr-set! red-color-ptr _ubyte 0 (color-r RED)) (ptr-set! red-color-ptr _ubyte 1 (color-g RED))
(ptr-set! red-color-ptr _ubyte 2 (color-b RED)) (ptr-set! red-color-ptr _ubyte 3 (color-a RED))
(set-material-color mat-ptr-inst MATERIAL-MAP-DIFFUSE red-color-ptr)
(define mat-inst (material-ptr->list mat-ptr-inst))

;; default material (BLUE)
(define mat-ptr-def (load-material-default))
(define blue-color-ptr (malloc _ubyte 4 'atomic))
(ptr-set! blue-color-ptr _ubyte 0 (color-r BLUE)) (ptr-set! blue-color-ptr _ubyte 1 (color-g BLUE))
(ptr-set! blue-color-ptr _ubyte 2 (color-b BLUE)) (ptr-set! blue-color-ptr _ubyte 3 (color-a BLUE))
(set-material-color mat-ptr-def MATERIAL-MAP-DIFFUSE blue-color-ptr)
(define mat-def (material-ptr->list mat-ptr-def))

(define cam-pos-buf (malloc _float 3 'atomic))
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-ORBITAL)
    (ptr-set! cam-pos-buf _float 0 (camera3d-pos-x camera))
    (ptr-set! cam-pos-buf _float 1 (camera3d-pos-y camera))
    (ptr-set! cam-pos-buf _float 2 (camera3d-pos-z camera))
    (set-shader-value shader
                      (ptr-ref (caddr shader) _int SHADER-LOC-VECTOR-VIEW)
                      cam-pos-buf SHADER-UNIFORM-VEC3)

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
