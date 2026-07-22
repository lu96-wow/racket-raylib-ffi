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

(set-target-fps 60)

(let loop ([exit-requested #f] [exit-window #f])
  (unless exit-window
    (define after-esc
      (if (or (window-should-close?) (is-key-pressed KEY-ESCAPE)) #t exit-requested))
    (define next-window
      (if (and after-esc (is-key-pressed KEY-Y)) #t exit-window))
    (define next-requested
      (if (and after-esc (is-key-pressed KEY-N)) #f after-esc))

    (begin-drawing)
    (clear-background RAYWHITE)
    (if next-requested
      (begin
        (draw-rectangle 0 100 SCREEN-WIDTH 200 BLACK)
        (draw-text "Are you sure you want to exit program? [Y/N]" 40 180 30 WHITE))
      (draw-text "Try to close the window to get confirmation message!"
        120 200 20 LIGHTGRAY))
    (end-drawing)
    (loop next-requested next-window)))

(close-window)
