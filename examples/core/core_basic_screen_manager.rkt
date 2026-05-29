#lang racket/base

;; raylib [core] example - basic screen manager (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_basic_screen_manager.c
;;
;; 演示基于状态机的简单屏幕管理器

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)

;; 屏幕状态枚举 (用整数模拟 C enum)
(define LOGO      0)
(define TITLE     1)
(define GAMEPLAY  2)
(define ENDING    3)

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - basic screen manager")

(define current-screen LOGO)
(define frames-counter 0)

(set-target-fps 60)

;; ============================================================
;; 辅助: 检测 Enter 或触摸手势
;; ============================================================

(define (enter-or-tap?)
  (or (is-key-pressed KEY-ENTER)
      (is-gesture-detected? GESTURE-TAP)))

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; === 更新阶段 ===
    (cond
      [(= current-screen LOGO)
       (set! frames-counter (add1 frames-counter))
       (when (> frames-counter 120)
         (set! current-screen TITLE))]

      [(= current-screen TITLE)
       (when (enter-or-tap?)
         (set! current-screen GAMEPLAY))]

      [(= current-screen GAMEPLAY)
       (when (enter-or-tap?)
         (set! current-screen ENDING))]

      [(= current-screen ENDING)
       (when (enter-or-tap?)
         (set! current-screen TITLE))])

    ;; === 绘制阶段 ===
    (begin-drawing)
    (clear-background RAYWHITE)

    (cond
      [(= current-screen LOGO)
       (draw-text "LOGO SCREEN" 20 20 40 LIGHTGRAY)
       (draw-text "WAIT for 2 SECONDS..." 290 220 20 GRAY)]

      [(= current-screen TITLE)
       (draw-rectangle 0 0 SCREEN-WIDTH SCREEN-HEIGHT GREEN)
       (draw-text "TITLE SCREEN" 20 20 40 DARKGREEN)
       (draw-text "PRESS ENTER or TAP to JUMP to GAMEPLAY SCREEN"
                  120 220 20 DARKGREEN)]

      [(= current-screen GAMEPLAY)
       (draw-rectangle 0 0 SCREEN-WIDTH SCREEN-HEIGHT PURPLE)
       (draw-text "GAMEPLAY SCREEN" 20 20 40 MAROON)
       (draw-text "PRESS ENTER or TAP to JUMP to ENDING SCREEN"
                  130 220 20 MAROON)]

      [(= current-screen ENDING)
       (draw-rectangle 0 0 SCREEN-WIDTH SCREEN-HEIGHT BLUE)
       (draw-text "ENDING SCREEN" 20 20 40 DARKBLUE)
       (draw-text "PRESS ENTER or TAP to RETURN to TITLE SCREEN"
                  120 220 20 DARKBLUE)])

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
