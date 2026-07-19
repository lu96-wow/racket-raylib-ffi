#lang racket/base

;; raylib [shaders] example - rounded rectangle (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_rounded_rectangle.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         racket/math
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! _float malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "raylib [shaders] example - rounded rectangle")

;; 加载着色器 (同时需要顶点和片段着色器)
(define shader (load-shader (res (format "shaders/glsl~a/base.vs" GLSL-VERSION))
                            (res (format "shaders/glsl~a/rounded_rectangle.fs" GLSL-VERSION))))

;; 获取所有 uniform 位置
(define rectangle-loc (get-shader-location shader "rectangle"))
(define radius-loc (get-shader-location shader "radius"))
(define color-loc (get-shader-location shader "color"))
(define shadow-radius-loc (get-shader-location shader "shadowRadius"))
(define shadow-offset-loc (get-shader-location shader "shadowOffset"))
(define shadow-scale-loc (get-shader-location shader "shadowScale"))
(define shadow-color-loc (get-shader-location shader "shadowColor"))
(define border-thickness-loc (get-shader-location shader "borderThickness"))
(define border-color-loc (get-shader-location shader "borderColor"))

;; 初始化静态 uniform (不逐帧变化的)
(define radius-val (malloc _float 4 'atomic))
(ptr-set! radius-val _float 0 5.0)  (ptr-set! radius-val _float 1 10.0)
(ptr-set! radius-val _float 2 15.0) (ptr-set! radius-val _float 3 20.0)
(set-shader-value shader radius-loc radius-val SHADER-UNIFORM-VEC4)

(define shadow-radius-val (malloc _float 1 'atomic))
(ptr-set! shadow-radius-val _float 0 20.0)
(set-shader-value shader shadow-radius-loc shadow-radius-val SHADER-UNIFORM-FLOAT)

(define shadow-offset-val (malloc _float 2 'atomic))
(ptr-set! shadow-offset-val _float 0 0.0) (ptr-set! shadow-offset-val _float 1 -5.0)
(set-shader-value shader shadow-offset-loc shadow-offset-val SHADER-UNIFORM-VEC2)

(define shadow-scale-val (malloc _float 1 'atomic))
(ptr-set! shadow-scale-val _float 0 0.95)
(set-shader-value shader shadow-scale-loc shadow-scale-val SHADER-UNIFORM-FLOAT)

(define border-thickness-val (malloc _float 1 'atomic))
(ptr-set! border-thickness-val _float 0 5.0)
(set-shader-value shader border-thickness-loc border-thickness-val SHADER-UNIFORM-FLOAT)

;; 预分配每帧用的缓冲区
(define rect-buf (malloc _float 4 'atomic))
(define color-buf (malloc _float 4 'atomic))
(define zero-color (malloc _float 4 'atomic))
(ptr-set! zero-color _float 0 0.0) (ptr-set! zero-color _float 1 0.0)
(ptr-set! zero-color _float 2 0.0) (ptr-set! zero-color _float 3 0.0)

(define rectangle-color BLUE)
(define shadow-color DARKBLUE)
(define border-color SKYBLUE)

(set-target-fps 60)

;; 辅助: 设置矩形位置 (带 Y 轴翻转)
(define (set-rectangle-uniform! x y w h)
  (ptr-set! rect-buf _float 0 x)
  (ptr-set! rect-buf _float 1 (- 450 y h))
  (ptr-set! rect-buf _float 2 w)
  (ptr-set! rect-buf _float 3 h)
  (set-shader-value shader rectangle-loc rect-buf SHADER-UNIFORM-VEC4))

;; 辅助: 设置颜色
(define (set-color-uniform! loc c)
  (ptr-set! color-buf _float 0 (exact->inexact (/ (color-r c) 255.0)))
  (ptr-set! color-buf _float 1 (exact->inexact (/ (color-g c) 255.0)))
  (ptr-set! color-buf _float 2 (exact->inexact (/ (color-b c) 255.0)))
  (ptr-set! color-buf _float 3 (exact->inexact (/ (color-a c) 255.0)))
  (set-shader-value shader loc color-buf SHADER-UNIFORM-VEC4))

(let loop ()
  (unless (window-should-close?)
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; --- 仅矩形颜色 ---
    (let ([rec-x 50.0] [rec-y 70.0] [rec-w 110.0] [rec-h 60.0])
      (draw-rectangle-lines (- (exact-truncate rec-x) 20) (- (exact-truncate rec-y) 20)
                            (+ (exact-truncate rec-w) 40) (+ (exact-truncate rec-h) 40) DARKGRAY)
      (draw-text "Rounded rectangle" (- (exact-truncate rec-x) 20) (- (exact-truncate rec-y) 35) 10 DARKGRAY)
      (set-rectangle-uniform! rec-x rec-y rec-w rec-h)
      (set-color-uniform! color-loc rectangle-color)
      (set-shader-value shader shadow-color-loc zero-color SHADER-UNIFORM-VEC4)
      (set-shader-value shader border-color-loc zero-color SHADER-UNIFORM-VEC4)
      (begin-shader-mode shader)
      (draw-rectangle 0 0 800 450 WHITE)
      (end-shader-mode))

    ;; --- 仅阴影 ---
    (let ([rec-x 50.0] [rec-y 200.0] [rec-w 110.0] [rec-h 60.0])
      (draw-rectangle-lines (- (exact-truncate rec-x) 20) (- (exact-truncate rec-y) 20)
                            (+ (exact-truncate rec-w) 40) (+ (exact-truncate rec-h) 40) DARKGRAY)
      (draw-text "Rounded rectangle shadow" (- (exact-truncate rec-x) 20) (- (exact-truncate rec-y) 35) 10 DARKGRAY)
      (set-rectangle-uniform! rec-x rec-y rec-w rec-h)
      (set-shader-value shader color-loc zero-color SHADER-UNIFORM-VEC4)
      (set-color-uniform! shadow-color-loc shadow-color)
      (set-shader-value shader border-color-loc zero-color SHADER-UNIFORM-VEC4)
      (begin-shader-mode shader)
      (draw-rectangle 0 0 800 450 WHITE)
      (end-shader-mode))

    ;; --- 仅边框 ---
    (let ([rec-x 50.0] [rec-y 330.0] [rec-w 110.0] [rec-h 60.0])
      (draw-rectangle-lines (- (exact-truncate rec-x) 20) (- (exact-truncate rec-y) 20)
                            (+ (exact-truncate rec-w) 40) (+ (exact-truncate rec-h) 40) DARKGRAY)
      (draw-text "Rounded rectangle border" (- (exact-truncate rec-x) 20) (- (exact-truncate rec-y) 35) 10 DARKGRAY)
      (set-rectangle-uniform! rec-x rec-y rec-w rec-h)
      (set-shader-value shader color-loc zero-color SHADER-UNIFORM-VEC4)
      (set-shader-value shader shadow-color-loc zero-color SHADER-UNIFORM-VEC4)
      (set-color-uniform! border-color-loc border-color)
      (begin-shader-mode shader)
      (draw-rectangle 0 0 800 450 WHITE)
      (end-shader-mode))

    ;; --- 全部三种颜色 ---
    (let ([rec-x 240.0] [rec-y 80.0] [rec-w 500.0] [rec-h 300.0])
      (draw-rectangle-lines (- (exact-truncate rec-x) 30) (- (exact-truncate rec-y) 30)
                            (+ (exact-truncate rec-w) 60) (+ (exact-truncate rec-h) 60) DARKGRAY)
      (draw-text "Rectangle with all three combined" (- (exact-truncate rec-x) 30) (- (exact-truncate rec-y) 45) 10 DARKGRAY)
      (set-rectangle-uniform! rec-x rec-y rec-w rec-h)
      (set-color-uniform! color-loc rectangle-color)
      (set-color-uniform! shadow-color-loc shadow-color)
      (set-color-uniform! border-color-loc border-color)
      (begin-shader-mode shader)
      (draw-rectangle 0 0 800 450 WHITE)
      (end-shader-mode))

    (draw-text "(c) Rounded rectangle SDF by Iñigo Quilez. MIT License."
               (- 800 300) (- 450 20) 10 BLACK)

    (end-drawing)
    (loop)))

(unload-shader shader)
(close-window)
