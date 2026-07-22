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

(let ([locs-ptr (shader-list-locs shader)])
  (ptr-set! locs-ptr _int SHADER-LOC-VECTOR-VIEW (get-shader-location shader "viewPos")))

(set-shader-value-vec4 shader (get-shader-location shader "ambient")
                       (vector4 0.1 0.1 0.1 1.0))

(define lights
  (list
   (create-light LIGHT-POINT -2.0 1.0 -2.0 0.0 0.0 0.0 YELLOW shader)
   (create-light LIGHT-POINT  2.0 1.0  2.0 0.0 0.0 0.0 RED    shader)
   (create-light LIGHT-POINT -2.0 1.0  2.0 0.0 0.0 0.0 GREEN  shader)
   (create-light LIGHT-POINT  2.0 1.0 -2.0 0.0 0.0 0.0 BLUE   shader)))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-ORBITAL)

    (set-shader-value-vec3 shader
      (ptr-ref (shader-list-locs shader) _int SHADER-LOC-VECTOR-VIEW)
      (camera3d-position camera))

    ;; toggle lights with Y/R/G/B
    (when (is-key-pressed KEY-Y)
      (set-light-enabled! (list-ref lights 0) (not (light-enabled? (list-ref lights 0)))))
    (when (is-key-pressed KEY-R)
      (set-light-enabled! (list-ref lights 1) (not (light-enabled? (list-ref lights 1)))))
    (when (is-key-pressed KEY-G)
      (set-light-enabled! (list-ref lights 2) (not (light-enabled? (list-ref lights 2)))))
    (when (is-key-pressed KEY-B)
      (set-light-enabled! (list-ref lights 3) (not (light-enabled? (list-ref lights 3)))))

    (for ([light lights]) (update-light-values shader light))

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (begin-shader-mode shader)
    (draw-plane (vector3 0.0 0.0 0.0) (vector2 10.0 10.0) WHITE)
    (draw-cube (vector3 0.0 0.0 0.0) 2.0 4.0 2.0 WHITE)
    (end-shader-mode)

    (for ([light lights])
      (let ([lc (light-color light)]
            [pos (vector3 (light-position-x light)
                          (light-position-y light)
                          (light-position-z light))])
        (if (light-enabled? light)
            (draw-sphere-ex pos 0.2 8 8 lc)
            (draw-sphere-wires pos 0.2 8 8 (color-alpha lc 0.3)))))

    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-fps 10 10)
    (draw-text "Use keys [Y][R][G][B] to toggle lights" 10 40 20 DARKGRAY)
    (end-drawing)
    (loop)))

(unload-shader shader)
(close-window)
