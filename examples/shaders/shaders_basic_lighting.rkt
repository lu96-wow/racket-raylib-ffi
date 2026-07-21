#lang racket/base

;; raylib [shaders] example - basic lighting (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_basic_lighting.c

(require "../../raylib/raylib.rkt"
         "../../raylib/core/rlights.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref _float _int malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window 800 450 "raylib [shaders] example - basic lighting")

(define camera (camera3d 2.0 4.0 6.0  0.0 0.5 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

(define shader (load-shader (res (format "shaders/glsl~a/lighting.vs" GLSL-VERSION))
                            (res (format "shaders/glsl~a/lighting.fs" GLSL-VERSION))))

(let ([locs-ptr (caddr shader)])
  (ptr-set! locs-ptr _int SHADER-LOC-VECTOR-VIEW (get-shader-location shader "viewPos")))

(let ([ambient (malloc _float 4 'atomic)])
  (ptr-set! ambient _float 0 0.1) (ptr-set! ambient _float 1 0.1)
  (ptr-set! ambient _float 2 0.1) (ptr-set! ambient _float 3 1.0)
  (set-shader-value shader (get-shader-location shader "ambient") ambient SHADER-UNIFORM-VEC4))

(define lights
  (list
   (create-light LIGHT-POINT -2.0 1.0 -2.0 0.0 0.0 0.0
                 (color-r YELLOW) (color-g YELLOW) (color-b YELLOW) (color-a YELLOW) shader)
   (create-light LIGHT-POINT  2.0 1.0  2.0 0.0 0.0 0.0
                 (color-r RED) (color-g RED) (color-b RED) (color-a RED) shader)
   (create-light LIGHT-POINT -2.0 1.0  2.0 0.0 0.0 0.0
                 (color-r GREEN) (color-g GREEN) (color-b GREEN) (color-a GREEN) shader)
   (create-light LIGHT-POINT  2.0 1.0 -2.0 0.0 0.0 0.0
                 (color-r BLUE) (color-g BLUE) (color-b BLUE) (color-a BLUE) shader)))

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

    (when (is-key-pressed KEY-Y)
      (vector-set! (list-ref lights 0) 0 (- 1 (vector-ref (list-ref lights 0) 0))))
    (when (is-key-pressed KEY-R)
      (vector-set! (list-ref lights 1) 0 (- 1 (vector-ref (list-ref lights 1) 0))))
    (when (is-key-pressed KEY-G)
      (vector-set! (list-ref lights 2) 0 (- 1 (vector-ref (list-ref lights 2) 0))))
    (when (is-key-pressed KEY-B)
      (vector-set! (list-ref lights 3) 0 (- 1 (vector-ref (list-ref lights 3) 0))))

    (for ([light lights]) (update-light-values shader light))

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (begin-shader-mode shader)
    (draw-plane (vector3 0.0 0.0 0.0) (vector2 10.0 10.0) WHITE)
    (draw-cube (vector3 0.0 0.0 0.0) 2.0 4.0 2.0 WHITE)
    (end-shader-mode)

    (for ([light lights])
      (let* ([enabled (vector-ref light 0)]
            [px (vector-ref light 2)] [py (vector-ref light 3)] [pz (vector-ref light 4)]
            [cr (vector-ref light 8)] [cg (vector-ref light 9)]
            [cb (vector-ref light 10)] [ca (vector-ref light 11)]
            [lc (color cr cg cb ca)])
        (if (= enabled 1)
            (draw-sphere-ex (vector3 px py pz) 0.2 8 8 lc)
            (draw-sphere-wires (vector3 px py pz) 0.2 8 8 (color-alpha lc 0.3)))))

    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-fps 10 10)
    (draw-text "Use keys [Y][R][G][B] to toggle lights" 10 40 20 DARKGRAY)
    (end-drawing)
    (loop)))

(unload-shader shader)
(close-window)
