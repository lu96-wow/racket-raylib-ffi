#lang racket/base

;; raylib [core] example - 3d camera mode
;;
;; 对应 C: examples/core/core_3d_camera_mode.c
;; 演示: 设置 3D 相机, 在 3D 空间绘制方块和网格

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
             "raylib [core] example - 3d camera mode")

;; 定义 3D 相机
(define camera
  (camera3d 0.0 10.0 10.0    ;; position  (0, 10, 10)
            0.0 0.0 0.0      ;; target   (0, 0, 0)
            0.0 1.0 0.0      ;; up       (0, 1, 0)
            45.0             ;; fovy
            CAMERA-PERSPECTIVE))

;; 方块位置
(define cube-position (vector3 0.0 0.0 0.0))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; Draw
    (begin-drawing)

    (clear-background RAYWHITE)

    (begin-mode-3d camera)

    (draw-cube cube-position 2.0 2.0 2.0 RED)
    (draw-cube-wires cube-position 2.0 2.0 2.0 MAROON)

    (draw-grid 10 1.0)

    (end-mode-3d)

    (draw-text "Welcome to the third dimension!" 10 40 20 DARKGRAY)

    (draw-fps 10 10)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
