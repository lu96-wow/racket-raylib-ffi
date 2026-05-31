#lang racket/base

;; raylib [shapes] example - following eyes (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_following_eyes.c

(require "../../raylib/raylib.rkt"
         racket/math)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - following eyes")

(define sclera-left-pos  (vector2 (- (/ (get-screen-width) 2.0) 100.0)
                                   (/ (get-screen-height) 2.0)))
(define sclera-right-pos (vector2 (+ (/ (get-screen-width) 2.0) 100.0)
                                   (/ (get-screen-height) 2.0)))
(define sclera-radius 80.0)

(define iris-left-pos  (vector2 (- (/ (get-screen-width) 2.0) 100.0)
                                 (/ (get-screen-height) 2.0)))
(define iris-right-pos (vector2 (+ (/ (get-screen-width) 2.0) 100.0)
                                 (/ (get-screen-height) 2.0)))
(define iris-radius 24.0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新 — 虹膜跟随鼠标
    (define mouse (get-mouse-position))

    ;; Left eye
    (set-vector2-x! iris-left-pos (vector2-x mouse))
    (set-vector2-y! iris-left-pos (vector2-y mouse))

    (unless (check-collision-point-circle iris-left-pos sclera-left-pos
                                          (- sclera-radius iris-radius))
      (define dx (- (vector2-x iris-left-pos) (vector2-x sclera-left-pos)))
      (define dy (- (vector2-y iris-left-pos) (vector2-y sclera-left-pos)))
      (define angle (atan dy dx))
      (define dxx (* (- sclera-radius iris-radius) (cos angle)))
      (define dyy (* (- sclera-radius iris-radius) (sin angle)))
      (set-vector2-x! iris-left-pos (+ (vector2-x sclera-left-pos) dxx))
      (set-vector2-y! iris-left-pos (+ (vector2-y sclera-left-pos) dyy)))

    ;; Right eye
    (set-vector2-x! iris-right-pos (vector2-x mouse))
    (set-vector2-y! iris-right-pos (vector2-y mouse))

    (unless (check-collision-point-circle iris-right-pos sclera-right-pos
                                          (- sclera-radius iris-radius))
      (define dx (- (vector2-x iris-right-pos) (vector2-x sclera-right-pos)))
      (define dy (- (vector2-y iris-right-pos) (vector2-y sclera-right-pos)))
      (define angle (atan dy dx))
      (define dxx (* (- sclera-radius iris-radius) (cos angle)))
      (define dyy (* (- sclera-radius iris-radius) (sin angle)))
      (set-vector2-x! iris-right-pos (+ (vector2-x sclera-right-pos) dxx))
      (set-vector2-y! iris-right-pos (+ (vector2-y sclera-right-pos) dyy)))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; Left eye
    (draw-circle-v sclera-left-pos sclera-radius LIGHTGRAY)
    (draw-circle-v iris-left-pos iris-radius BROWN)
    (draw-circle-v iris-left-pos 10.0 BLACK)

    ;; Right eye
    (draw-circle-v sclera-right-pos sclera-radius LIGHTGRAY)
    (draw-circle-v iris-right-pos iris-radius DARKGREEN)
    (draw-circle-v iris-right-pos 10.0 BLACK)

    (draw-fps 10 10)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
