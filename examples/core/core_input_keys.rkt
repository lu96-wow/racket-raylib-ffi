#lang racket/base

;; raylib [core] example - input keys (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_input_keys.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [core] example - input keys")

(define ball-position (vector2 (/ screen-width 2.0) (/ screen-height 2.0)))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新 — 用方向键移动球
    (when (is-key-down KEY-RIGHT)
      (set-vector2-x! ball-position (+ (vector2-x ball-position) 2.0)))
    (when (is-key-down KEY-LEFT)
      (set-vector2-x! ball-position (- (vector2-x ball-position) 2.0)))
    (when (is-key-down KEY-UP)
      (set-vector2-y! ball-position (- (vector2-y ball-position) 2.0)))
    (when (is-key-down KEY-DOWN)
      (set-vector2-y! ball-position (+ (vector2-y ball-position) 2.0)))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-text "move the ball with arrow keys" 10 10 20 DARKGRAY)

    (draw-circle-v ball-position 50.0 MAROON)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
