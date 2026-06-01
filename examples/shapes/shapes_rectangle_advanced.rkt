#lang racket/base

;; raylib [shapes] example - rectangle advanced (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_rectangle_advanced.c
;; 绘制水平渐变圆角矩形，左右两侧可分别设置圆角半径

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-w 800)
(define screen-h 450)

(init-window screen-w screen-h
             "raylib [shapes] example - rectangle advanced")

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()
  (unless (window-should-close?)

    ;; ---- 计算矩形位置 ----
    (define width  (/ (get-screen-width) 2.0))
    (define height (/ (get-screen-height) 6.0))
    (define rec
      (rectangle (- (/ (get-screen-width) 2.0) (/ width 2.0))
                 (- (/ (get-screen-height) 2.0) (* 5 (/ height 2.0)))
                 width height))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 绘制 5 个渐变圆角矩形，左右两侧不同圆角
    (draw-rectangle-rounded-gradient-h rec 0.8 0.8 36 BLUE RED)

    (ptr-set! rec _float 1 (+ (ptr-ref rec _float 1) height 1))
    (draw-rectangle-rounded-gradient-h rec 0.5 1.0 36 RED PINK)

    (ptr-set! rec _float 1 (+ (ptr-ref rec _float 1) height 1))
    (draw-rectangle-rounded-gradient-h rec 1.0 0.5 36 RED BLUE)

    (ptr-set! rec _float 1 (+ (ptr-ref rec _float 1) height 1))
    (draw-rectangle-rounded-gradient-h rec 0.0 1.0 36 BLUE BLACK)

    (ptr-set! rec _float 1 (+ (ptr-ref rec _float 1) height 1))
    (draw-rectangle-rounded-gradient-h rec 1.0 0.0 36 BLUE PINK)

    (end-drawing)

    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================
(close-window)
