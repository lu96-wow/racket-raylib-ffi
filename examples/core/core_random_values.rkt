#lang racket/base

;; raylib [core] example - random values
;;
;; Racket 翻译自 examples/core/core_random_values.c
;;
;; Racket 版直接用 format 替代 C 的 TextFormat 变参函数

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
             "raylib [core] example - random values")

;; 如果需要自定义随机种子:
;; (set-random-seed #xaabbccff)

(define rand-value (box (get-random-value -8 5)))
(define frames-counter (box 0))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()
  (unless (window-should-close?)
    ;; --- 更新 ---
    (set-box! frames-counter (add1 (unbox frames-counter)))

    ;; 每 2 秒（120 帧）生成一个新的随机值
    (when (= (modulo (quotient (unbox frames-counter) 120) 2) 1)
      (set-box! rand-value (get-random-value -8 5))
      (set-box! frames-counter 0))

    ;; --- 绘制 ---
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-text "Every 2 seconds a new random value is generated:"
               130 100 20 MAROON)
    (draw-text (format "~a" (unbox rand-value))
               360 180 80 LIGHTGRAY)

    (end-drawing)

    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
