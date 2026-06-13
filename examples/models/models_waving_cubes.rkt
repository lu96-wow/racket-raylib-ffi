#lang racket/base

;; raylib [models] example - waving cubes (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_waving_cubes.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [models] example - waving cubes")

;; 定义 3D 相机
(define camera (camera3d 30.0 20.0 30.0
                         0.0  0.0  0.0
                         0.0  1.0  0.0
                         70.0 CAMERA-PERSPECTIVE))

(define num-blocks 15)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    (let* ([time (get-time)]
           [scale (* (+ 2.0 (sin time)) 0.7)]
           [camera-time (* time 0.3)])

      ;; 移动相机环绕场景
      (set-camera3d-pos-x! camera (* (cos camera-time) 40.0))
      (set-camera3d-pos-z! camera (* (sin camera-time) 40.0))

      ;; ---- Draw ----
      (begin-drawing)
      (clear-background RAYWHITE)

      (begin-mode-3d camera)

      (draw-grid 10 5.0)

      (for* ([x (in-range num-blocks)]
             [y (in-range num-blocks)]
             [z (in-range num-blocks)])
        (let* ([block-scale (exact->inexact (/ (+ x y z) 30.0))]
               [scatter (sin (+ (* block-scale 20.0) (* time 4.0)))]
               [cx (* (- x (/ num-blocks 2)) (* scale 3.0))]
               [cy (* (- y (/ num-blocks 2)) (* scale 2.0))]
               [cz (* (- z (/ num-blocks 2)) (* scale 3.0))]
               [hue (modulo (* (+ x y z) 18) 360)]
               [cube-color (color-from-hsv (exact->inexact hue) 0.75 0.9)]
               [cube-size (* (- 2.4 scale) block-scale)])
          (draw-cube (vector3 (+ cx scatter) (+ cy scatter) (+ cz scatter))
                     cube-size cube-size cube-size
                     cube-color)))

      (end-mode-3d)

      (draw-fps 10 10)

      (end-drawing)
      (loop))))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
