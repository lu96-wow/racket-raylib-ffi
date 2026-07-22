#lang racket/base

;; raylib [shaders] example - postprocessing (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_postprocessing.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! _float malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

;; 辅助: Fade(color, alpha) - 调整颜色透明度
(define (fade c alpha)
  (color (color-r c) (color-g c) (color-b c) (inexact->exact (truncate (* (color-a c) alpha)))))

;; 后处理着色器名称
(define postpro-names
  #("GRAYSCALE" "POSTERIZATION" "DREAM_VISION" "PIXELIZER"
    "CROSS_HATCHING" "CROSS_STITCHING" "PREDATOR_VIEW" "SCANLINES"
    "FISHEYE" "SOBEL" "BLOOM" "BLUR"))

(define MAX-POSTPRO-SHADERS (vector-length postpro-names))

(define FX-GRAYSCALE 0)
(define FX-POSTERIZATION 1)
(define FX-DREAM-VISION 2)
(define FX-PIXELIZER 3)
(define FX-CROSS-HATCHING 4)
(define FX-CROSS-STITCHING 5)
(define FX-PREDATOR-VIEW 6)
(define FX-SCANLINES 7)
(define FX-FISHEYE 8)
(define FX-SOBEL 9)
(define FX-BLOOM 10)
(define FX-BLUR 11)

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window 800 450 "raylib [shaders] example - postprocessing")

(define camera (camera3d 2.0 3.0 2.0  0.0 1.0 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

;; 加载模型和纹理
(define model (load-model (res "models/church.obj")))
(define texture (load-texture (res "models/church_diffuse.png")))
(let ([mats-ptr (list-ref model 19)])
  (set-material-texture mats-ptr MATERIAL-MAP-DIFFUSE texture))

;; 加载12个后处理着色器
(define (load-fs-shader fs-name)
  (load-shader #f (res (format "shaders/glsl~a/~a.fs" GLSL-VERSION fs-name))))

(define shaders
  (vector
   (load-fs-shader "grayscale")
   (load-fs-shader "posterization")
   (load-fs-shader "dream_vision")
   (load-fs-shader "pixelizer")
   (load-fs-shader "cross_hatching")
   (load-fs-shader "cross_stitching")
   (load-fs-shader "predator")
   (load-fs-shader "scanlines")
   (load-fs-shader "fisheye")
   (load-fs-shader "sobel")
   (load-fs-shader "bloom")
   (load-fs-shader "blur")))

(define current-shader 0)

;; 创建 RenderTexture
(define target (load-render-texture 800 450))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    ;; Update
    (update-camera camera CAMERA-ORBITAL)

    (when (is-key-pressed KEY-RIGHT)
      (set! current-shader (modulo (+ current-shader 1) MAX-POSTPRO-SHADERS)))
    (when (is-key-pressed KEY-LEFT)
      (set! current-shader (modulo (+ current-shader MAX-POSTPRO-SHADERS -1) MAX-POSTPRO-SHADERS)))

    ;; Draw to texture
    (begin-texture-mode target)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (draw-model model (vector3 0.0 0.0 0.0) 0.1 WHITE)
    (draw-grid 10 1.0)
    (end-mode-3d)
    (end-texture-mode)

    ;; Draw to screen with postprocessing
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-shader-mode (vector-ref shaders current-shader))
    (draw-texture-rec (list (render-texture-tex-id target) (render-texture-tex-width target) (render-texture-tex-height target) (render-texture-tex-mipmaps target) (render-texture-tex-format target))
                      (rectangle 0.0 0.0 800.0 -450.0)
                      (vector2 0.0 0.0) WHITE)
    (end-shader-mode)

    (draw-rectangle 0 9 580 30 (fade LIGHTGRAY 0.7))
    (draw-text "(c) Church 3D model by Alberto Cano" (- 800 200) (- 450 20) 10 GRAY)
    (draw-text "CURRENT POSTPRO SHADER:" 10 15 20 BLACK)
    (draw-text (vector-ref postpro-names current-shader) 330 15 20 RED)
    (draw-text "< >" 540 10 30 DARKBLUE)
    (draw-fps 700 15)
    (end-drawing)
    (loop)))

;; 清理
(for ([i (in-range MAX-POSTPRO-SHADERS)])
  (unload-shader (vector-ref shaders i)))
(unload-texture texture)
(unload-model model)
(unload-render-texture target)
(close-window)
