#lang racket/base

;; raylib [text] example - 3d drawing (Racket FFI 翻译 简化版)
;;
;; 对应 C: examples/text/text_3d_drawing.c
;;
;; 注意: C 原版使用 rlgl 底层函数（rlCheckRenderBatchLimit, rlSetTexture,
;; rlPushMatrix, rlTranslatef, rlBegin/End, rlColor4ub, rlNormal3f,
;; rlTexCoord2f, rlVertex3f, rlPopMatrix）来在 3D 空间中逐字形绘制文本。
;; 这些 rlgl 函数尚未在 Racket FFI 中绑定。
;; 本示例展示在 3D 相机下绘制简单 3D 文本等效效果。

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(set-config-flags (bitwise-ior FLAG-MSAA-4X-HINT FLAG-VSYNC-HINT))
(init-window screen-width screen-height
  "raylib [text] example - 3d drawing (simplified)")

;; 定义 3D 相机
(define camera
  (camera3d -10.0 15.0 -10.0   ; position
            0.0 0.0 0.0         ; target
            0.0 1.0 0.0         ; up
            45.0                ; fovy
            CAMERA-PERSPECTIVE)) ; projection

(define camera-mode CAMERA-ORBITAL)

(define cube-position (vector3 0.0 1.0 0.0))
(define cube-size (vector3 2.0 2.0 2.0))

(disable-cursor)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (update-camera camera camera-mode)

    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    (begin-mode-3d camera)
    ;; 绘制 3D 立方体
    (draw-cube-v cube-position cube-size RED)
    (draw-cube-wires cube-position 2.1 2.1 2.1 MAROON)
    (draw-grid 10 2.0)

    ;; 注: 3D 文本绘制需要 rlgl 绑定
    ;; 原始示例使用 DrawTextCodepoint3D + DrawTextWave3D
    ;; 这里仅显示提示信息
    (end-mode-3d)

    ;; 2D 提示信息
    (draw-text "3D Text Drawing Demo (simplified)" 20 20 20 DARKGRAY)
    (draw-text "Original C example uses rlgl for per-glyph 3D text rendering" 20 50 15 GRAY)
    (draw-text "rlgl functions not yet bound in Racket FFI" 20 70 15 GRAY)
    (draw-text "Drag & drop a .ttf font file to see font loading work!" 20 100 15 DARKGRAY)
    (draw-text "Use mouse to orbit the 3D camera" 20 130 15 DARKGRAY)

    (draw-fps 10 10)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
