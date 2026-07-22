#lang racket/base

;; raylib [text] example - writing anim (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_writing_anim.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - writing anim")

(define message "This sample illustrates a text writing\nanimation effect! Check it out! ;)")

(define-var frames-counter 0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (if (is-key-down KEY-SPACE)
        (+= frames-counter 8)
        (+= frames-counter 1))

    (when (is-key-pressed KEY-ENTER)
      (set-box! frames-counter 0))

    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    (draw-text (text-subtext message 0 (quotient (unbox frames-counter) 10)) 210 160 20 MAROON)
    (draw-text "PRESS [ENTER] to RESTART!" 240 260 20 LIGHTGRAY)
    (draw-text "HOLD [SPACE] to SPEED UP!" 239 300 20 LIGHTGRAY)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
