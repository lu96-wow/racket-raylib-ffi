#lang racket/base

;; raylib [core] example - input mouse wheel (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_input_mouse_wheel.c

(require racket/format
         "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [core] example - input mouse wheel")

(define box-position-y (- (/ screen-height 2) 40))
(define scroll-speed 4)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新 — 滚轮控制方块上下移动
    (set! box-position-y
      (- box-position-y
         (inexact->exact (round (* (get-mouse-wheel-move) scroll-speed)))))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-rectangle (- (/ screen-width 2) 40) box-position-y 80 80 MAROON)

    (draw-text "Use mouse wheel to move the cube up and down!"
      10 10 20 GRAY)
    (draw-text
      (~a "Box position Y: " box-position-y)
      10 40 20 LIGHTGRAY)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
