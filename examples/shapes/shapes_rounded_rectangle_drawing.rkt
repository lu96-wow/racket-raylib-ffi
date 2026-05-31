#lang racket/base

;; raylib [shapes] example - rounded rectangle drawing (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_rounded_rectangle_drawing.c
;; 键盘控制替代 raygui 滑块

(require "../../raylib/raylib.rkt"
         racket/math)

;; ============================================================
;; 键盘控制
;; ============================================================
;; width:          q↑ / w↓   步进 10   范围 0-500
;; height:         a↑ / s↓   步进 10   范围 0-400
;; roundness:      z↑ / x↓   步进 0.05 范围 0.0-1.0
;; lineThick:      e↑ / r↓   步进 1    范围 0-20
;; segments:       d↑ / f↓   步进 1    范围 0-60
;; drawRoundedRect:  1 = 切换
;; drawRoundedLines: 2 = 切换
;; drawRect:         3 = 切换
;; ============================================================

(define (fmt v d) (real->decimal-string v d))
(define (on/off v) (if v "[x]" "[ ]"))

;; ============================================================
;; 初始化
;; ============================================================
(define screen-w 800)
(define screen-h 450)

(init-window screen-w screen-h
             "raylib [shapes] example - rounded rectangle drawing")

(define width      (box 200.0))
(define height     (box 100.0))
(define roundness  (box 0.2))
(define segments   (box 0.0))
(define line-thick (box 1.0))
(define draw-rect?          (box #f))
(define draw-rounded-rect?  (box #t))
(define draw-rounded-lines? (box #f))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================
(let main-loop ()
  (unless (window-should-close?)
    ;; ---- 键盘控制 ----
    (cond [(is-key-pressed KEY-Q)
           (set-box! width (min 500.0 (+ (unbox width) 10.0)))]
          [(is-key-pressed KEY-W)
           (set-box! width (max 0.0   (- (unbox width) 10.0)))])
    (cond [(is-key-pressed KEY-A)
           (set-box! height (min 400.0 (+ (unbox height) 10.0)))]
          [(is-key-pressed KEY-S)
           (set-box! height (max 0.0   (- (unbox height) 10.0)))])
    (cond [(is-key-pressed KEY-Z)
           (set-box! roundness (min 1.0 (+ (unbox roundness) 0.05)))]
          [(is-key-pressed KEY-X)
           (set-box! roundness (max 0.0 (- (unbox roundness) 0.05)))])
    (cond [(is-key-pressed KEY-E)
           (set-box! line-thick (min 20.0 (+ (unbox line-thick) 1.0)))]
          [(is-key-pressed KEY-R)
           (set-box! line-thick (max 0.0  (- (unbox line-thick) 1.0)))])
    (cond [(is-key-pressed KEY-D)
           (set-box! segments (min 60.0 (+ (unbox segments) 1.0)))]
          [(is-key-pressed KEY-F)
           (set-box! segments (max 0.0  (- (unbox segments) 1.0)))])
    (when (is-key-pressed KEY-ONE)
      (set-box! draw-rounded-rect? (not (unbox draw-rounded-rect?))))
    (when (is-key-pressed KEY-TWO)
      (set-box! draw-rounded-lines? (not (unbox draw-rounded-lines?))))
    (when (is-key-pressed KEY-THREE)
      (set-box! draw-rect? (not (unbox draw-rect?))))

    ;; ---- 更新 ----
    (define w  (unbox width))
    (define h  (unbox height))
    (define rn (unbox roundness))
    (define sg (unbox segments))
    (define lt (unbox line-thick))
    (define dr (unbox draw-rect?))
    (define drr (unbox draw-rounded-rect?))
    (define drl (unbox draw-rounded-lines?))

    (define rec (rectangle (/ (- (get-screen-width) w 250) 2.0)
                           (/ (- (get-screen-height) h) 2.0)
                           w h))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 分隔线 + 控制面板
    (draw-line 560 0 560 (get-screen-height) (fade LIGHTGRAY 0.6))
    (draw-rectangle 560 0 (- (get-screen-width) 500) (get-screen-height)
                    (fade LIGHTGRAY 0.3))

    ;; 矩形绘制
    (when dr  (draw-rectangle-rec rec (fade GOLD 0.6)))
    (when drr (draw-rectangle-rounded rec rn (exact-round sg) (fade MAROON 0.2)))
    (when drl (draw-rectangle-rounded-lines-ex rec rn (exact-round sg) lt (fade MAROON 0.4)))

    ;; 参数显示
    (draw-text (format "Width      [Q/W]: ~a" (fmt w 2))  640 40  10 DARKGRAY)
    (draw-text (format "Height     [A/S]: ~a" (fmt h 2))  640 70  10 DARKGRAY)
    (draw-text (format "Roundness  [Z/X]: ~a" (fmt rn 2)) 640 140 10 DARKGRAY)
    (draw-text (format "Thickness  [E/R]: ~a" (fmt lt 2)) 640 170 10 DARKGRAY)
    (draw-text (format "Segments   [D/F]: ~a" (fmt sg 2)) 640 240 10 DARKGRAY)

    ;; MODE 显示
    (define mode-text (if (>= sg 4.0) "MANUAL" "AUTO"))
    (define mode-color (if (>= sg 4.0) MAROON DARKGRAY))
    (draw-text (format "MODE: ~a" mode-text) 640 280 10 mode-color)

    ;; 复选框
    (draw-text (format "~a DrawRoundedRect   [1]"
                       (on/off drr)) 640 320 10 DARKGRAY)
    (draw-text (format "~a DrawRoundedLines  [2]"
                       (on/off drl)) 640 350 10 DARKGRAY)
    (draw-text (format "~a DrawRect          [3]"
                       (on/off dr))  640 380 10 DARKGRAY)

    (draw-fps 10 10)
    (end-drawing)

    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================
(close-window)
