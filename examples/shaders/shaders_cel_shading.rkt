#lang racket/base

;; raylib [shaders] example - cel shading (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_cel_shading.c
;;
;; 功能: 卡通渲染(cel/toon shading) + 反转法线轮廓描边
;; 按 Z 切换卡通渲染, C 切换轮廓, Q/E 调整色带数

(require "../../raylib/raylib.rkt"
         "../../raylib/core/rlights.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref _float _int malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window 800 450 "raylib [shaders] example - cel shading")

;; camera
(define camera (camera3d 9.0 6.0 9.0  0.0 1.0 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

;; load model
(define model (load-model (res "models/old_car_new.glb")))

;; load cel shader
(define cel-shader (load-shader (res (format "shaders/glsl~a/cel.vs" GLSL-VERSION))
                                (res (format "shaders/glsl~a/cel.fs" GLSL-VERSION))))
(let ([locs-ptr (caddr cel-shader)])
  (ptr-set! locs-ptr _int SHADER-LOC-VECTOR-VIEW (get-shader-location cel-shader "viewPos")))

;; save default shader, apply cel shader
(define mats-ptr (list-ref model 19))
(define default-shader (ptr-ref mats-ptr _shader-bytes 0))
(set-material-shader mats-ptr cel-shader)

;; numBands: toon quantization steps (2=hard binary, 20=near-smooth)
(define num-bands 10.0)
(define num-bands-loc (get-shader-location cel-shader "numBands"))
(define num-bands-buf (malloc _float 1 'atomic))
(ptr-set! num-bands-buf _float 0 num-bands)
(set-shader-value cel-shader num-bands-loc num-bands-buf SHADER-UNIFORM-FLOAT)

;; outline shader (inverted-hull)
(define outline-shader (load-shader (res (format "shaders/glsl~a/outline_hull.vs" GLSL-VERSION))
                                    (res (format "shaders/glsl~a/outline_hull.fs" GLSL-VERSION))))
(define outline-thickness-loc (get-shader-location outline-shader "outlineThickness"))

;; single directional light
(reset-lights!)
(define lights
  (list
   (create-light LIGHT-DIRECTIONAL 50.0 50.0 50.0 0.0 0.0 0.0
                 (color-r WHITE) (color-g WHITE) (color-b WHITE) (color-a WHITE) cel-shader)))

(define cel-enabled #t)
(define outline-enabled #t)

(define cam-pos-buf (malloc _float 3 'atomic))
(define thickness-buf (malloc _float 1 'atomic))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-ORBITAL)

    ;; update viewPos uniform
    (ptr-set! cam-pos-buf _float 0 (camera3d-pos-x camera))
    (ptr-set! cam-pos-buf _float 1 (camera3d-pos-y camera))
    (ptr-set! cam-pos-buf _float 2 (camera3d-pos-z camera))
    (set-shader-value cel-shader
                      (ptr-ref (caddr cel-shader) _int SHADER-LOC-VECTOR-VIEW)
                      cam-pos-buf SHADER-UNIFORM-VEC3)

    ;; [Z] toggle cel shading
    (when (is-key-pressed KEY-Z)
      (set! cel-enabled (not cel-enabled))
      (set-material-shader mats-ptr (if cel-enabled cel-shader default-shader)))

    ;; [C] toggle outline
    (when (is-key-pressed KEY-C)
      (set! outline-enabled (not outline-enabled)))

    ;; [Q/E] adjust band count
    (when (or (is-key-pressed KEY-E) (is-key-pressed-repeat KEY-E))
      (set! num-bands (min 20.0 (max 2.0 (+ num-bands 1.0)))))
    (when (or (is-key-pressed KEY-Q) (is-key-pressed-repeat KEY-Q))
      (set! num-bands (min 20.0 (max 2.0 (- num-bands 1.0)))))
    (ptr-set! num-bands-buf _float 0 num-bands)
    (set-shader-value cel-shader num-bands-loc num-bands-buf SHADER-UNIFORM-FLOAT)

    ;; spin light
    (let ([t (get-time)]
          [l (list-ref lights 0)])
      (vector-set! l 2 (* (sin (* -0.3 t)) 5.0))
      (vector-set! l 3 5.0)
      (vector-set! l 4 (* (cos (* -0.3 t)) 5.0)))

    (for ([light lights]) (update-light-values cel-shader light))

    ;; draw
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)

    (when outline-enabled
      (ptr-set! thickness-buf _float 0 0.005)
      (set-shader-value outline-shader outline-thickness-loc thickness-buf SHADER-UNIFORM-FLOAT)
      (rl-set-cull-face RL-CULL-FACE-FRONT)
      (set-material-shader mats-ptr outline-shader)
      (draw-model model (vector3 0.0 0.0 0.0) 0.75 WHITE)
      (set-material-shader mats-ptr (if cel-enabled cel-shader default-shader))
      (rl-set-cull-face RL-CULL-FACE-BACK))

    (draw-model model (vector3 0.0 0.0 0.0) 0.75 WHITE)
    (let ([l (list-ref lights 0)])
      (draw-sphere-ex (vector3 (vector-ref l 2) (vector-ref l 3) (vector-ref l 4))
                       0.2 50 50 YELLOW))
    (draw-grid 10 10.0)

    (end-mode-3d)

    (draw-fps 10 10)
    (draw-text (format "Cel: ~a  [Z]" (if cel-enabled "ON" "OFF")) 10 65 20
               (if cel-enabled DARKGREEN DARKGRAY))
    (draw-text (format "Outline: ~a  [C]" (if outline-enabled "ON" "OFF")) 10 90 20
               (if outline-enabled DARKGREEN DARKGRAY))
    (draw-text (format "Bands: ~a  [Q/E]" (inexact->exact (round num-bands))) 10 115 20 DARKGRAY)

    (end-drawing)
    (loop)))

(unload-model model)
(unload-shader cel-shader)
(unload-shader outline-shader)
(close-window)
