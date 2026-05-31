#lang racket/base

;; raylib [shapes] example - logo raylib (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_logo_raylib.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - logo raylib")

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-rectangle (- (quotient screen-width 2) 128)
                    (- (quotient screen-height 2) 128)
                    256 256 BLACK)
    (draw-rectangle (- (quotient screen-width 2) 112)
                    (- (quotient screen-height 2) 112)
                    224 224 RAYWHITE)
    (draw-text "raylib" (- (quotient screen-width 2) 44)
                (+ (quotient screen-height 2) 48) 50 BLACK)
    (draw-text "this is NOT a texture!" 350 370 10 GRAY)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
