#lang racket/base

;; raylib [shaders] example - raymarching rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_raymarching_rendering.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! _float malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(set-config-flags FLAG-WINDOW-RESIZABLE)
(init-window 800 450 "raylib [shaders] example - raymarching rendering")

(define camera (camera3d 2.5 2.5 3.0  0.0 0.0 0.7  0.0 1.0 0.0  65.0 CAMERA-PERSPECTIVE))

(define shader (load-shader #f (res (format "shaders/glsl~a/raymarching.fs" GLSL-VERSION))))

(define view-eye-loc (get-shader-location shader "viewEye"))
(define view-center-loc (get-shader-location shader "viewCenter"))
(define run-time-loc (get-shader-location shader "runTime"))
(define resolution-loc (get-shader-location shader "resolution"))

;; 预分配缓冲区
(define resolution (malloc _float 2 'atomic))
(ptr-set! resolution _float 0 800.0) (ptr-set! resolution _float 1 450.0)
(set-shader-value shader resolution-loc resolution SHADER-UNIFORM-VEC2)

(define camera-pos (malloc _float 3 'atomic))
(define camera-target (malloc _float 3 'atomic))
(define run-time-val (malloc _float 1 'atomic))
(ptr-set! run-time-val _float 0 0.0)

(disable-cursor)
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-FIRST-PERSON)

    ;; 更新摄像机位置/目标
    (ptr-set! camera-pos _float 0 (camera3d-pos-x camera))
    (ptr-set! camera-pos _float 1 (camera3d-pos-y camera))
    (ptr-set! camera-pos _float 2 (camera3d-pos-z camera))
    (ptr-set! camera-target _float 0 (camera3d-tar-x camera))
    (ptr-set! camera-target _float 1 (camera3d-tar-y camera))
    (ptr-set! camera-target _float 2 (camera3d-tar-z camera))

    ;; 更新运行时间
    (ptr-set! run-time-val _float 0 (+ (ptr-ref run-time-val _float 0) (get-frame-time)))

    (set-shader-value shader view-eye-loc camera-pos SHADER-UNIFORM-VEC3)
    (set-shader-value shader view-center-loc camera-target SHADER-UNIFORM-VEC3)
    (set-shader-value shader run-time-loc run-time-val SHADER-UNIFORM-FLOAT)

    ;; 窗口大小改变时更新 resolution
    (when (is-window-resized?)
      (ptr-set! resolution _float 0 (exact->inexact (get-screen-width)))
      (ptr-set! resolution _float 1 (exact->inexact (get-screen-height)))
      (set-shader-value shader resolution-loc resolution SHADER-UNIFORM-VEC2))

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-shader-mode shader)
    (draw-rectangle 0 0 (get-screen-width) (get-screen-height) WHITE)
    (end-shader-mode)
    (draw-text "(c) Raymarching shader by Iñigo Quilez. MIT License."
               (- (get-screen-width) 280) (- (get-screen-height) 20) 10 BLACK)
    (end-drawing)
    (loop)))

(unload-shader shader)
(close-window)
