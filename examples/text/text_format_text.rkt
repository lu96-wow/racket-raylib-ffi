#lang racket/base

;; raylib [text] example - format text (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_format_text.c

(require racket/format
         "../../raylib/raylib.rkt")

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

    ;; C: TextFormat("Score: %08i", score)          → 零填充8位
    (draw-text (format "Score: ~a" (~r score #:min-width 8 #:pad-string "0")) 200 80 20 RED)
    ;; C: TextFormat("HiScore: %08i", hiscore)
    (draw-text (format "HiScore: ~a" (~r hiscore #:min-width 8 #:pad-string "0")) 200 120 20 GREEN)
    ;; C: TextFormat("Lives: %02i", lives)           → 零填充2位
    (draw-text (format "Lives: ~a" (~r lives #:min-width 2 #:pad-string "0")) 200 160 40 BLUE)
    ;; C: TextFormat("Elapsed Time: %02.02f ms", ...) → 整数≥2位+精确2位小数
    (draw-text (format "Elapsed Time: ~ams"
                       (real->decimal-string (* (get-frame-time) 1000.0) 2))
               200 220 20 BLACK)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
