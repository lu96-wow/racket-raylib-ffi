#lang racket/base
;; raylib [shapes] example - math angle rotation (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_math_angle_rotation.c
;; 绘制固定角度射线 + 一条旋转中的彩虹射线

(require "../../raylib/raylib.rkt" racket/math)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 720)
(define screen-height 400)

(init-window screen-width screen-height
  "raylib [shapes] example - math angle rotation")

(define DEG2RAD (/ pi 180.0))

(define center (vector2 (/ screen-width 2.0) (/ screen-height 2.0)))
(define line-length 150.0)

;; 固定角度 (度)
(define angles (vector 0 30 60 90))
(define num-angles 4)

;; 固定角度对应的颜色
(define angle-colors (vector GREEN ORANGE BLUE MAGENTA))

;; 动画旋转总角度
(define total-angle (box 0.0))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()
  (unless (window-should-close?)
    ;; --- 更新 ---
    (set-box! total-angle (+ (unbox total-angle) 1.0))
    (when (>= (unbox total-angle) 360.0)
      (set-box! total-angle (- (unbox total-angle) 360.0)))

    ;; --- 绘制 ---
    (begin-drawing)
    (clear-background WHITE)

    (draw-text "Fixed angles + rotating line" 10 10 20 LIGHTGRAY)

    ;; 绘制固定角度射线 (0°, 30°, 60°, 90°)
    (for ([i (in-range num-angles)])
      (let* ([rad (* (vector-ref angles i) DEG2RAD)]
             [cx (ptr-ref center _float 0)]
             [cy (ptr-ref center _float 1)]
             [ex (+ cx (* (cos rad) line-length))]
             [ey (+ cy (* (sin rad) line-length))]
             [end (vector2 ex ey)]
             [col (vector-ref angle-colors i)])
        ;; 射线
        (draw-line-ex center end 5.0 col)
        ;; 角度标签
        (let* ([tx (+ cx (* (cos rad) (+ line-length 20)))]
               [ty (+ cy (* (sin rad) (+ line-length 20)))]
               [label (format "~a°" (vector-ref angles i))])
          (draw-text label (exact-round tx) (exact-round ty) 20 col))))

    ;; 绘制动画旋转射线
    (let* ([anim-rad (* (unbox total-angle) DEG2RAD)]
           [cx (ptr-ref center _float 0)]
           [cy (ptr-ref center _float 1)]
           [ex (+ cx (* (cos anim-rad) line-length))]
           [ey (+ cy (* (sin anim-rad) line-length))]
           [anim-end (vector2 ex ey)]
           [anim-col (color-from-hsv (unbox total-angle) 0.8 0.9)])
      (draw-line-ex center anim-end 5.0 anim-col))

    (end-drawing)

    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
