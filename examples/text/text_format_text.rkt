#lang racket/base

;; raylib [text] example - format text (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_format_text.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - format text")

(define score 100020)
(define hiscore 200450)
(define lives 5)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    (draw-text (format "Score: ~a" score) 200 80 20 RED)
    (draw-text (format "HiScore: ~a" hiscore) 200 120 20 GREEN)
    (draw-text (format "Lives: ~a" lives) 200 160 40 BLUE)
    (draw-text (format "Elapsed Time: ~ams" (* (get-frame-time) 1000.0)) 200 220 20 BLACK)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
