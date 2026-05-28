#lang racket/base

;; raylib [core] example - input mouse (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_input_mouse.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [core] example - input mouse")

(define ball-position (vector2 -100.0 -100.0))
(define ball-color DARKBLUE)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新

    ;; H 键切换 cursor 可见性
    (when (is-key-pressed KEY-H)
      (if (is-cursor-hidden?)
          (show-cursor)
          (hide-cursor)))

    ;; 球跟随鼠标
    (set! ball-position (get-mouse-position))

    ;; 鼠标按钮改变颜色
    (cond
      [(is-mouse-button-pressed MOUSE-BUTTON-LEFT)   (set! ball-color MAROON)]
      [(is-mouse-button-pressed MOUSE-BUTTON-MIDDLE) (set! ball-color LIME)]
      [(is-mouse-button-pressed MOUSE-BUTTON-RIGHT)  (set! ball-color DARKBLUE)]
      [(is-mouse-button-pressed MOUSE-BUTTON-SIDE)   (set! ball-color PURPLE)]
      [(is-mouse-button-pressed MOUSE-BUTTON-EXTRA)  (set! ball-color YELLOW)]
      [(is-mouse-button-pressed MOUSE-BUTTON-FORWARD)(set! ball-color ORANGE)]
      [(is-mouse-button-pressed MOUSE-BUTTON-BACK)   (set! ball-color BEIGE)])

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-circle-v ball-position 40.0 ball-color)

    (draw-text
      "move ball with mouse and click mouse button to change color"
      10 10 20 DARKGRAY)
    (draw-text
      "Press 'H' to toggle cursor visibility"
      10 30 20 DARKGRAY)

    (when (is-cursor-hidden?)
      (draw-text "CURSOR HIDDEN" 20 60 20 RED))

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
