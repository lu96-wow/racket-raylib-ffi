#lang racket/base

;; raylib [core] example - world screen (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_world_screen.c
;;
;; 演示: 将 3D 空间坐标转换为 2D 屏幕坐标,
;; 在方块上方显示浮动文字标签

(require "../../raylib/raylib.rkt")

(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 450)

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - world screen")

(define camera
  (camera3d 10.0 10.0 10.0   ;; position
            0.0 0.0 0.0      ;; target
            0.0 1.0 0.0      ;; up
            45.0             ;; fovy
            CAMERA-PERSPECTIVE))

(define cube-pos (vector3 0.0 0.0 0.0))

(disable-cursor)
(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-THIRD-PERSON)

    (let* ([label-pos (vector3 (vector3-x cube-pos)
                               (+ (vector3-y cube-pos) 2.5)
                               (vector3-z cube-pos))]
           [screen-pos (get-world-to-screen label-pos camera)]
           [label "Enemy: 100/100"]
           [label-w (measure-text label 20)])

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)

      (begin-mode-3d camera)
      (draw-cube cube-pos 2.0 2.0 2.0 RED)
      (draw-cube-wires cube-pos 2.0 2.0 2.0 MAROON)
      (draw-grid 10 1.0)
      (end-mode-3d)

      ;; 在方块屏幕位置绘制标签
      (draw-text label
        (- (inexact->exact (floor (vector2-x screen-pos))) (quotient label-w 2))
        (inexact->exact (floor (vector2-y screen-pos)))
        20 BLACK)

      ;; 屏幕信息
      (draw-text (format "Cube position in screen space coordinates: [~a, ~a]"
                  (inexact->exact (floor (vector2-x screen-pos)))
                  (inexact->exact (floor (vector2-y screen-pos))))
        10 10 20 LIME)
      (draw-text "Text 2d should be always on top of the cube" 10 40 20 GRAY)

      (end-drawing)
      (loop))))

(close-window)
