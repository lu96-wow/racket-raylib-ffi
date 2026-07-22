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
(let ([locs-ptr (shader-list-locs cel-shader)])
  (ptr-set! locs-ptr _int SHADER-LOC-VECTOR-VIEW (get-shader-location cel-shader "viewPos")))

;; save default shader, apply cel shader
(define mats-ptr (model-materials model))
(define default-shader (ptr-ref mats-ptr _shader-bytes 0))
(set-material-shader mats-ptr cel-shader)

;; numBands: toon quantization steps (2=hard binary, 20=near-smooth)
(define-var num-bands 10.0)
(define num-bands-loc (get-shader-location cel-shader "numBands"))
(define num-bands-buf (malloc _float 1 'atomic))
(ptr-set! num-bands-buf _float 0 (unbox num-bands))
(set-shader-value cel-shader num-bands-loc num-bands-buf SHADER-UNIFORM-FLOAT)

;; outline shader (inverted-hull)
(define outline-shader (load-shader (res (format "shaders/glsl~a/outline_hull.vs" GLSL-VERSION))
                                    (res (format "shaders/glsl~a/outline_hull.fs" GLSL-VERSION))))
(define outline-thickness-loc (get-shader-location outline-shader "outlineThickness"))

;; single directional light
(reset-lights!)
(define lights
  (list
   (create-light LIGHT-DIRECTIONAL 50.0 50.0 50.0 0.0 0.0 0.0 WHITE cel-shader)))

(define-var cel-enabled #t)
(define-var outline-enabled #t)

(define thickness-buf (malloc _float 1 'atomic))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-ORBITAL)

    ;; update viewPos uniform
    (set-shader-value-vec3 cel-shader
      (ptr-ref (shader-list-locs cel-shader) _int SHADER-LOC-VECTOR-VIEW)
      (camera3d-position camera))

    ;; [Z] toggle cel shading
    (when (is-key-pressed KEY-Z)
      (set-box! cel-enabled (not (unbox cel-enabled)))
      (set-material-shader mats-ptr (if (unbox cel-enabled) cel-shader default-shader)))

    ;; [C] toggle outline
    (when (is-key-pressed KEY-C)
      (set-box! outline-enabled (not (unbox outline-enabled))))

    ;; [Q/E] adjust band count
    (when (or (is-key-pressed KEY-E) (is-key-pressed-repeat KEY-E))
      (+= num-bands 1.0) (set-box! num-bands (min 20.0 (unbox num-bands))))
    (when (or (is-key-pressed KEY-Q) (is-key-pressed-repeat KEY-Q))
      (-= num-bands 1.0) (set-box! num-bands (max 2.0 (unbox num-bands))))
    (ptr-set! num-bands-buf _float 0 (unbox num-bands))
    (set-shader-value cel-shader num-bands-loc num-bands-buf SHADER-UNIFORM-FLOAT)

    ;; spin light
    (let* ([t (get-time)]
           [l (list-ref lights 0)])
      (set-light-position! l (* (sin (* -0.3 t)) 5.0) 5.0 (* (cos (* -0.3 t)) 5.0)))

    (for ([light lights]) (update-light-values cel-shader light))

    ;; draw
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)

    (when (unbox outline-enabled)
      (ptr-set! thickness-buf _float 0 0.005)
      (set-shader-value outline-shader outline-thickness-loc thickness-buf SHADER-UNIFORM-FLOAT)
      (rl-set-cull-face RL-CULL-FACE-FRONT)
      (set-material-shader mats-ptr outline-shader)
      (draw-model model (vector3 0.0 0.0 0.0) 0.75 WHITE)
      (set-material-shader mats-ptr (if (unbox cel-enabled) cel-shader default-shader))
      (rl-set-cull-face RL-CULL-FACE-BACK))

    (draw-model model (vector3 0.0 0.0 0.0) 0.75 WHITE)
    (let ([l (list-ref lights 0)])
      (draw-sphere-ex (vector3 (light-position-x l) (light-position-y l) (light-position-z l))
                       0.2 50 50 YELLOW))
    (draw-grid 10 10.0)

    (end-mode-3d)

    (draw-fps 10 10)
    (draw-text (format "Cel: ~a  [Z]" (if (unbox cel-enabled) "ON" "OFF")) 10 65 20
               (if (unbox cel-enabled) DARKGREEN DARKGRAY))
    (draw-text (format "Outline: ~a  [C]" (if (unbox outline-enabled) "ON" "OFF")) 10 90 20
               (if (unbox outline-enabled) DARKGREEN DARKGRAY))
    (draw-text (format "Bands: ~a  [Q/E]" (inexact->exact (round (unbox num-bands)))) 10 115 20 DARKGRAY)

    (end-drawing)
    (loop)))

(unload-model model)
(unload-shader cel-shader)
(unload-shader outline-shader)
(close-window)
