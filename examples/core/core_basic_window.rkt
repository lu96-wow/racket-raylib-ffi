#lang racket/base

;; raylib [core] example - basic window (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_basic_window.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(init-window 800 450 "raylib [core] example - basic window")

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)
    (draw-text "Congrats! You created your first window!" 190 200 20 LIGHTGRAY)
    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
