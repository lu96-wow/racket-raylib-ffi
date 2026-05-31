#lang racket/base

;; raylib [shapes] example - circle sector drawing (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_circle_sector_drawing.c
;; 键盘控制替代 raygui 滑块

(require "../../raylib/raylib.rkt"
         racket/math)

;; ============================================================
;; 键盘控制
;; ============================================================
;; startAngle:    q↑ / w↓   步进 5     范围 0-720
;; endAngle:      a↑ / s↓   步进 5     范围 0-720
;; outerRadius:   z↑ / x↓   步进 5     范围 0-200
;; segments:      e↑ / r↓   步进 1     范围 0-100
;; ============================================================

(define (fmt v) (real->decimal-string v 2))

;; ============================================================
;; 初始化
;; ============================================================
(define screen-w 800)
(define screen-h 450)

(init-window screen-w screen-h
             "raylib [shapes] example - circle sector drawing")

(define center (vector2 (/ (- (get-screen-width) 300) 2.0)
                        (/ (get-screen-height) 2.0)))

(define outer-radius (box 180.0))
(define start-angle  (box 0.0))
(define end-angle    (box 180.0))
(define segments     (box 10.0))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================
(let main-loop ()
  (unless (window-should-close?)
    ;; ---- 键盘控制 ----
    (cond [(is-key-pressed KEY-Q)
           (set-box! start-angle (min 720.0 (+ (unbox start-angle) 5.0)))]
          [(is-key-pressed KEY-W)
           (set-box! start-angle (max 0.0   (- (unbox start-angle) 5.0)))])
    (cond [(is-key-pressed KEY-A)
           (set-box! end-angle (min 720.0 (+ (unbox end-angle) 5.0)))]
          [(is-key-pressed KEY-S)
           (set-box! end-angle (max 0.0   (- (unbox end-angle) 5.0)))])
    (cond [(is-key-pressed KEY-Z)
           (set-box! outer-radius (min 200.0 (+ (unbox outer-radius) 5.0)))]
          [(is-key-pressed KEY-X)
           (set-box! outer-radius (max 0.0   (- (unbox outer-radius) 5.0)))])
    (cond [(is-key-pressed KEY-E)
           (set-box! segments (min 100.0 (+ (unbox segments) 1.0)))]
          [(is-key-pressed KEY-R)
           (set-box! segments (max 0.0   (- (unbox segments) 1.0)))])

    ;; ---- 绘制 ----
    (define sa (unbox start-angle))
    (define ea (unbox end-angle))
    (define r  (unbox outer-radius))
    (define sg (unbox segments))

    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 分隔线 + 控制面板
    (draw-line 500 0 500 (get-screen-height) (fade LIGHTGRAY 0.6))
    (draw-rectangle 500 0 (- (get-screen-width) 500) (get-screen-height)
                    (fade LIGHTGRAY 0.3))

    ;; 扇形
    (draw-circle-sector center r sa ea (exact-round sg) (fade MAROON 0.3))
    (draw-circle-sector-lines center r sa ea (exact-round sg) (fade MAROON 0.6))

    ;; 参数显示
    (draw-text (format "StartAngle [Q/W]: ~a" (fmt sa)) 600 40 10 DARKGRAY)
    (draw-text (format "EndAngle   [A/S]: ~a" (fmt ea)) 600 70 10 DARKGRAY)
    (draw-text (format "Radius     [Z/X]: ~a" (fmt r))  600 140 10 DARKGRAY)
    (draw-text (format "Segments   [E/R]: ~a" (fmt sg)) 600 170 10 DARKGRAY)

    ;; MODE 显示
    (define min-seg (exact-ceiling (/ (- ea sa) 90.0)))
    (define mode-text
      (if (>= sg min-seg) "MANUAL" "AUTO"))
    (define mode-color
      (if (>= sg min-seg) MAROON DARKGRAY))
    (draw-text (format "MODE: ~a" mode-text) 600 200 10 mode-color)

    (draw-fps 10 10)
    (end-drawing)

    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================
(close-window)
