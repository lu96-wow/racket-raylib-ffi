#lang racket/base

;; raylib [models] example - orthographic projection (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_orthographic_projection.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define FOVY-PERSPECTIVE 45.0)
(define WIDTH-ORTHOGRAPHIC 10.0)

(init-window screen-width screen-height
  "raylib [models] example - orthographic projection")

;; 定义 3D 相机 (默认透视投影)
(define camera (camera3d 0.0 10.0 10.0
                         0.0  0.0  0.0
                         0.0  1.0  0.0
                         FOVY-PERSPECTIVE CAMERA-PERSPECTIVE))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    ;; 空格键切换投影模式
    (when (is-key-pressed KEY-SPACE)
      (if (= (camera3d-projection camera) CAMERA-PERSPECTIVE)
          (begin
            (set-camera3d-fovy! camera WIDTH-ORTHOGRAPHIC)
            (set-camera3d-projection! camera CAMERA-ORTHOGRAPHIC))
          (begin
            (set-camera3d-fovy! camera FOVY-PERSPECTIVE)
            (set-camera3d-projection! camera CAMERA-PERSPECTIVE))))

    ;; ---- Draw ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)

    ;; 方块: 填充 + 线框
    (draw-cube (vector3 -4.0 0.0 2.0) 2.0 5.0 2.0 RED)
    (draw-cube-wires (vector3 -4.0 0.0 2.0) 2.0 5.0 2.0 GOLD)
    (draw-cube-wires (vector3 -4.0 0.0 -2.0) 3.0 6.0 2.0 MAROON)

    ;; 球体: 填充 + 线框
    (draw-sphere (vector3 -1.0 0.0 -2.0) 1.0 GREEN)
    (draw-sphere-wires (vector3 1.0 0.0 2.0) 2.0 16 16 LIME)

    ;; 圆柱: 填充 + 线框
    (draw-cylinder (vector3 4.0 0.0 -2.0) 1.0 2.0 3.0 4 SKYBLUE)
    (draw-cylinder-wires (vector3 4.0 0.0 -2.0) 1.0 2.0 3.0 4 DARKBLUE)
    (draw-cylinder-wires (vector3 4.5 -1.0 2.0) 1.0 1.0 2.0 6 BROWN)

    ;; 圆锥 (用 draw-cylinder 实现: radius-top=0)
    (draw-cylinder (vector3 1.0 0.0 -4.0) 0.0 1.5 3.0 8 GOLD)
    (draw-cylinder-wires (vector3 1.0 0.0 -4.0) 0.0 1.5 3.0 8 PINK)

    ;; 网格
    (draw-grid 10 1.0)

    (end-mode-3d)

    ;; UI 提示
    (draw-text "Press Spacebar to switch camera type" 10 (- (get-screen-height) 30) 20 DARKGRAY)

    (cond [(= (camera3d-projection camera) CAMERA-ORTHOGRAPHIC)
           (draw-text "ORTHOGRAPHIC" 10 40 20 BLACK)]
          [(= (camera3d-projection camera) CAMERA-PERSPECTIVE)
           (draw-text "PERSPECTIVE" 10 40 20 BLACK)])

    (draw-fps 10 10)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
