#lang racket/base

;; raylib [models] example - geometric shapes (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_geometric_shapes.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [models] example - geometric shapes")

;; 定义 3D 相机
(define camera (camera3d 0.0 10.0 10.0
                         0.0  0.0  0.0
                         0.0  1.0  0.0
                         45.0 CAMERA-PERSPECTIVE))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)

    ;; 方块: 填充 + 线框 (red cube with gold wires)
    (draw-cube (vector3 -4.0 0.0 2.0) 2.0 5.0 2.0 RED)
    (draw-cube-wires (vector3 -4.0 0.0 2.0) 2.0 5.0 2.0 GOLD)
    ;; 另一个方块线框 (maroon)
    (draw-cube-wires (vector3 -4.0 0.0 -2.0) 3.0 6.0 2.0 MAROON)

    ;; 球体: 填充 + 线框 (green sphere, lime wires)
    (draw-sphere (vector3 -1.0 0.0 -2.0) 1.0 GREEN)
    (draw-sphere-wires (vector3 1.0 0.0 2.0) 2.0 16 16 LIME)

    ;; 圆柱: 填充 + 线框 (skyblue cylinder, darkblue wires)
    (draw-cylinder (vector3 4.0 0.0 -2.0) 1.0 2.0 3.0 4 SKYBLUE)
    (draw-cylinder-wires (vector3 4.0 0.0 -2.0) 1.0 2.0 3.0 4 DARKBLUE)
    ;; 另一个圆柱线框 (brown)
    (draw-cylinder-wires (vector3 4.5 -1.0 2.0) 1.0 1.0 2.0 6 BROWN)

    ;; 圆锥: 填充 + 线框 (gold cone, pink wires)
    (draw-cylinder (vector3 1.0 0.0 -4.0) 0.0 1.5 3.0 8 GOLD)
    (draw-cylinder-wires (vector3 1.0 0.0 -4.0) 0.0 1.5 3.0 8 PINK)

    ;; 胶囊体: 填充 + 线框 (violet capsule, purple wires)
    (draw-capsule (vector3 -3.0 1.5 -4.0) (vector3 -4.0 -1.0 -4.0) 1.2 8 8 VIOLET)
    (draw-capsule-wires (vector3 -3.0 1.5 -4.0) (vector3 -4.0 -1.0 -4.0) 1.2 8 8 PURPLE)

    ;; 网格
    (draw-grid 10 1.0)

    (end-mode-3d)

    (draw-fps 10 10)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
