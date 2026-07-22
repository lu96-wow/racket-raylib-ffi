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
(define-var scissor-mode #t)  ;; 用 box 以便在闭包中修改

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新 — 按 S 切换裁剪模式
    (when (is-key-pressed KEY-S)
      (set-box! scissor-mode (not (unbox scissor-mode))))

    ;; 裁剪区域居中跟随鼠标
    (define mx (get-mouse-x))
    (define my (get-mouse-y))
    (set-rectangle-x! scissor-area (- mx (/ (rectangle-w scissor-area) 2.0)))
    (set-rectangle-y! scissor-area (- my (/ (rectangle-h scissor-area) 2.0)))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 如果启用裁剪模式，设置裁剪区域
    (when (unbox scissor-mode)
      (begin-scissor-mode (inexact->exact (floor (rectangle-x scissor-area)))
                          (inexact->exact (floor (rectangle-y scissor-area)))
                          (inexact->exact (floor (rectangle-w scissor-area)))
                          (inexact->exact (floor (rectangle-h scissor-area)))))

    ;; 画全屏红色矩形 + 提示文字
    (draw-rectangle 0 0 (get-screen-width) (get-screen-height) RED)
    (draw-text "Move the mouse around to reveal this text!" 190 200 20 LIGHTGRAY)

    ;; 结束裁剪模式
    (when (unbox scissor-mode)
      (end-scissor-mode))

    ;; 画裁剪区域边框 + 底部提示
    (draw-rectangle-lines-ex scissor-area 1.0 BLACK)
    (draw-text "Press S to toggle scissor test" 10 10 20 BLACK)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
