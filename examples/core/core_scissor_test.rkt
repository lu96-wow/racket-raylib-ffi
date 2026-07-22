#lang racket/base

;; raylib [core] example - scissor test (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_scissor_test.c
;;
;; 演示 BeginScissorMode / EndScissorMode 裁剪测试

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)

(init-window SCREEN-WIDTH SCREEN-HEIGHT "raylib [core] example - scissor test")

;; 裁剪区域矩形 (Rectangle 指针)
(define scissor-area (rectangle 0 0 300 300))

(set-target-fps 60)

(let loop ([scissor-mode #t])
  (unless (window-should-close?)
    ;; 按 S 切换裁剪模式
    (define next-mode (if (is-key-pressed KEY-S) (not scissor-mode) scissor-mode))

    ;; 裁剪区域居中跟随鼠标
    (define mx (get-mouse-x))
    (define my (get-mouse-y))
    (set-rectangle-x! scissor-area (- mx (/ (rectangle-w scissor-area) 2.0)))
    (set-rectangle-y! scissor-area (- my (/ (rectangle-h scissor-area) 2.0)))

    (begin-drawing)
    (clear-background RAYWHITE)

    (when next-mode
      (begin-scissor-mode (inexact->exact (floor (rectangle-x scissor-area)))
                          (inexact->exact (floor (rectangle-y scissor-area)))
                          (inexact->exact (floor (rectangle-w scissor-area)))
                          (inexact->exact (floor (rectangle-h scissor-area)))))

    (draw-rectangle 0 0 (get-screen-width) (get-screen-height) RED)
    (draw-text "Move the mouse around to reveal this text!" 190 200 20 LIGHTGRAY)

    (when next-mode (end-scissor-mode))

    (draw-rectangle-lines-ex scissor-area 1.0 BLACK)
    (draw-text "Press S to toggle scissor test" 10 10 20 BLACK)

    (end-drawing)
    (loop next-mode)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
