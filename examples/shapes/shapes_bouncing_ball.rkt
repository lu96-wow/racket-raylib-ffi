#lang racket/base

;; raylib [shapes] example - bouncing ball (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_bouncing_ball.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window screen-width screen-height
  "raylib [shapes] example - bouncing ball")

(define ball-position (vector2 (/ (get-screen-width) 2.0) (/ (get-screen-height) 2.0)))
(define ball-speed   (vector2 5.0 4.0))
(define ball-radius  20)
(define gravity      0.2)

(define use-gravity?  #t)
(define pause?        #f)
(define frames-counter 0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (when (is-key-pressed KEY-G) (set! use-gravity? (not use-gravity?)))
    (when (is-key-pressed KEY-SPACE) (set! pause? (not pause?)))

    (if (not pause?)
        (begin
          ;; 移动球
          (set-vector2-x! ball-position (+ (vector2-x ball-position) (vector2-x ball-speed)))
          (set-vector2-y! ball-position (+ (vector2-y ball-position) (vector2-y ball-speed)))

          (when use-gravity?
            (set-vector2-y! ball-speed (+ (vector2-y ball-speed) gravity)))

          ;; 墙壁碰撞反弹
          (when (or (>= (vector2-x ball-position) (- (get-screen-width) ball-radius))
                    (<= (vector2-x ball-position) ball-radius))
            (set-vector2-x! ball-speed (* (vector2-x ball-speed) -1.0)))

          (when (or (>= (vector2-y ball-position) (- (get-screen-height) ball-radius))
                    (<= (vector2-y ball-position) ball-radius))
            (set-vector2-y! ball-speed (* (vector2-y ball-speed) -0.95))))
        (set! frames-counter (+ frames-counter 1)))

    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    (draw-circle-v ball-position (exact->inexact ball-radius) MAROON)
    (draw-text "PRESS SPACE to PAUSE BALL MOVEMENT"
               10 (- (get-screen-height) 25) 20 LIGHTGRAY)

    (if use-gravity?
        (draw-text "GRAVITY: ON (Press G to disable)"
                   10 (- (get-screen-height) 50) 20 DARKGREEN)
        (draw-text "GRAVITY: OFF (Press G to enable)"
                   10 (- (get-screen-height) 50) 20 RED))

    ;; 暂停时闪烁 PAUSED 文字（每 30 帧切换一次）
    (when (and pause? (= (modulo (quotient frames-counter 30) 2) 1))
      (draw-text "PAUSED" 350 200 30 GRAY))

    (draw-fps 10 10)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
