#lang racket/base

;; raylib [core] example - window should close (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_window_should_close.c
;;
;; 演示: 拦截关闭窗口请求, 确认后才退出

(require "../../raylib/raylib.rkt")

(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 450)

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - window should close")

(set-exit-key KEY-NULL)      ;; 禁用 ESC 关闭

(define exit-requested (box #f))
(define exit-window (box #f))

(set-target-fps 60)

(let loop ()
  (unless (unbox exit-window)
    ;; 检测关闭请求
    (when (or (window-should-close?) (is-key-pressed KEY-ESCAPE))
      (set-box! exit-requested #t))

    (when (unbox exit-requested)
      (cond
        [(is-key-pressed KEY-Y) (set-box! exit-window #t)]
        [(is-key-pressed KEY-N) (set-box! exit-requested #f)]))

    (begin-drawing)
    (clear-background RAYWHITE)

    (if (unbox exit-requested)
      (begin
        (draw-rectangle 0 100 SCREEN-WIDTH 200 BLACK)
        (draw-text "Are you sure you want to exit program? [Y/N]" 40 180 30 WHITE))
      (draw-text "Try to close the window to get confirmation message!"
        120 200 20 LIGHTGRAY))

    (end-drawing)
    (loop)))

(close-window)
