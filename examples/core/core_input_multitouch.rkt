#lang racket/base

;; raylib [core] example - input multitouch (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_input_multitouch.c

(require racket/format
         "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define MAX-TOUCH-POINTS 10)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [core] example - input multitouch")

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 获取触摸点数量
    (let ([t-count (min (get-touch-point-count) MAX-TOUCH-POINTS)])

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)

      (for ([i (in-range t-count)])
        (let ([pos (get-touch-position i)])
          ;; 排除 (0, 0) ——表示该点无触摸
          (when (and (> (vector2-x pos) 0.0) (> (vector2-y pos) 0.0))
            (draw-circle-v pos 34.0 ORANGE)
            (draw-text (~a i)
                       (- (inexact->exact (round (vector2-x pos))) 10)
                       (- (inexact->exact (round (vector2-y pos))) 70)
                       40 BLACK))))

      (draw-text
        "touch the screen at multiple locations to get multiple balls"
        10 10 20 DARKGRAY)

      (end-drawing))

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
