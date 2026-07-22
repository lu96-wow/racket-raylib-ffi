#lang racket/base

;; raylib [shaders] example - fog rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_fog_rendering.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         racket/list
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref _float _int _pointer malloc))

(define GLSL-VERSION 330)
(define LIGHT-POINT 1)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

;; 辅助: 替换 model transform
(define (model-set-transform model-list mat-list)
  (append mat-list (list-tail model-list 16)))

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window 800 450 "raylib [shaders] example - fog rendering")

(define camera (camera3d 2.0 2.0 6.0  0.0 0.5 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

(define modelA (load-model-from-mesh (gen-mesh-torus 0.4 1.0 16 32)))
(define modelB (load-model-from-mesh (gen-mesh-cube 1.0 1.0 1.0)))
(define modelC (load-model-from-mesh (gen-mesh-sphere 0.5 32 32)))

(define texture (load-texture (res "texel_checker.png")))
(for ([m (list modelA modelB modelC)])
  (set-material-texture (list-ref m 19) MATERIAL-MAP-DIFFUSE texture))

(define shader (load-shader (res (format "shaders/glsl~a/lighting.vs" GLSL-VERSION))
                            (res (format "shaders/glsl~a/fog.fs" GLSL-VERSION))))

(let ([locs-ptr (shader-list-locs shader)])
  (ptr-set! locs-ptr _int SHADER-LOC-MATRIX-MODEL (get-shader-location shader "matModel"))
  (ptr-set! locs-ptr _int SHADER-LOC-VECTOR-VIEW (get-shader-location shader "viewPos")))

;; 环境光
(let ([ambient (malloc _float 4 'atomic)])
  (ptr-set! ambient _float 0 0.2) (ptr-set! ambient _float 1 0.2)
  (ptr-set! ambient _float 2 0.2) (ptr-set! ambient _float 3 1.0)
  (set-shader-value shader (get-shader-location shader "ambient") ambient SHADER-UNIFORM-VEC4))

;; 雾颜色
(let ([fog-col (malloc _float 4 'atomic)])
  (ptr-set! fog-col _float 0 (/ (color-r GRAY) 255.0))
  (ptr-set! fog-col _float 1 (/ (color-g GRAY) 255.0))
  (ptr-set! fog-col _float 2 (/ (color-b GRAY) 255.0))
  (ptr-set! fog-col _float 3 (/ (color-a GRAY) 255.0))
  (set-shader-value shader (get-shader-location shader "fogColor") fog-col SHADER-UNIFORM-VEC4))

(define fog-density 0.15)
(define fog-density-loc (get-shader-location shader "fogDensity"))
(define fog-buf (malloc _float 1 'atomic))
(ptr-set! fog-buf _float 0 fog-density)
(set-shader-value shader fog-density-loc fog-buf SHADER-UNIFORM-FLOAT)

;; 给所有模型设置着色器
(for ([m (list modelA modelB modelC)])
  (set-material-shader (list-ref m 19) shader))

;; 内联 CreateLight (fog 只用了一个灯)
(define light-enabled-loc (get-shader-location shader "lights[0].enabled"))
(define light-type-loc    (get-shader-location shader "lights[0].type"))
(define light-pos-loc     (get-shader-location shader "lights[0].position"))
(define light-target-loc  (get-shader-location shader "lights[0].target"))
(define light-color-loc   (get-shader-location shader "lights[0].color"))
(define light-pos-x 0.0) (define light-pos-y 2.0) (define light-pos-z 6.0)
(define light-tar-x 0.0) (define light-tar-y 0.0) (define light-tar-z 0.0)
(define light-cr (color-r WHITE)) (define light-cg (color-g WHITE))
(define light-cb (color-b WHITE)) (define light-ca (color-a WHITE))
(define light-enabled 1)

(define (update-light!)
  (define ib (malloc _int 1 'atomic))
  (define v3 (malloc _float 3 'atomic))
  (define v4 (malloc _float 4 'atomic))
  (ptr-set! ib _int 0 light-enabled)
  (set-shader-value shader light-enabled-loc ib SHADER-UNIFORM-INT)
  (ptr-set! ib _int 0 LIGHT-POINT)
  (set-shader-value shader light-type-loc ib SHADER-UNIFORM-INT)
  (ptr-set! v3 _float 0 light-pos-x) (ptr-set! v3 _float 1 light-pos-y) (ptr-set! v3 _float 2 light-pos-z)
  (set-shader-value shader light-pos-loc v3 SHADER-UNIFORM-VEC3)
  (ptr-set! v3 _float 0 light-tar-x) (ptr-set! v3 _float 1 light-tar-y) (ptr-set! v3 _float 2 light-tar-z)
  (set-shader-value shader light-target-loc v3 SHADER-UNIFORM-VEC3)
  (ptr-set! v4 _float 0 (/ light-cr 255.0)) (ptr-set! v4 _float 1 (/ light-cg 255.0))
  (ptr-set! v4 _float 2 (/ light-cb 255.0)) (ptr-set! v4 _float 3 (/ light-ca 255.0))
  (set-shader-value shader light-color-loc v4 SHADER-UNIFORM-VEC4))

(update-light!)

(define cam-pos-buf (malloc _float 3 'atomic))
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-ORBITAL)

    (when (is-key-down KEY-UP)
      (set! fog-density (min (+ fog-density 0.001) 1.0)))
    (when (is-key-down KEY-DOWN)
      (set! fog-density (max (- fog-density 0.001) 0.0)))
    (ptr-set! fog-buf _float 0 fog-density)
    (set-shader-value shader fog-density-loc fog-buf SHADER-UNIFORM-FLOAT)

    ;; 旋转 torus
    (let ([rot (matrix-multiply (matrix-rotate-x -0.025) (matrix-rotate-z 0.012))])
      (set! modelA (model-set-transform modelA
                      (matrix-multiply (take modelA 16) rot))))

    (ptr-set! cam-pos-buf _float 0 (camera3d-pos-x camera))
    (ptr-set! cam-pos-buf _float 1 (camera3d-pos-y camera))
    (ptr-set! cam-pos-buf _float 2 (camera3d-pos-z camera))
    (set-shader-value shader
      (ptr-ref (shader-list-locs shader) _int SHADER-LOC-VECTOR-VIEW)
      cam-pos-buf SHADER-UNIFORM-VEC3)

    (begin-drawing)
    (clear-background GRAY)
    (begin-mode-3d camera)
    (draw-model modelA (vector3 0.0 0.0 0.0) 1.0 WHITE)
    (draw-model modelB (vector3 -2.6 0.0 0.0) 1.0 WHITE)
    (draw-model modelC (vector3  2.6 0.0 0.0) 1.0 WHITE)
    (for ([i (in-range -20 20 2)])
      (draw-model modelA (vector3 (exact->inexact i) 0.0 2.0) 1.0 WHITE))
    (end-mode-3d)
    (draw-text (format "Use KEY-UP/KEY-DOWN to change fog density [~a]" (real->decimal-string fog-density 2))
               10 10 20 RAYWHITE)
    (end-drawing)
    (loop)))

(unload-model modelA) (unload-model modelB) (unload-model modelC)
(unload-texture texture)
(unload-shader shader)
(close-window)
