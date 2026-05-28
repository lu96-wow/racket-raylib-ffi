#lang racket

;; raylib [core] example - basic window
;; Translated from C to Racket
;; 尽量保持与 C 原版结构一致

(require "../../raylib/main.rkt")

;; === 初始化 ===
(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [core] example - basic window")

(set-target-fps 60)

;; === 主循环 ===
(let loop ()
  (unless (window-should-close?)
    (begin-drawing)
    (clear-background RAYWHITE)
    (draw-text "Congrats! You created your first window!"
               190 200 20 LIGHTGRAY)
    (end-drawing)
    (loop)))

;; === 销毁 ===
(close-window)
