#lang racket/base

;; raylib [core] example - 3d camera mode
;;
;; 对应 C: examples/core/core_3d_camera_mode.c
;; 演示: 设置 3D 相机, 在 3D 空间绘制方块和网格

(require (except-in ffi/unsafe _bool)
         "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
             "raylib [core] example - 3d camera mode")

;; 定义 3D 相机
;; 用 malloc 创建裸指针 + ptr-set! 写字段
;; (因为 define-cstruct 生成的 set-Xxx! 有契约检查, 不接受裸 cpointer)
(define camera
  (let ([cam (malloc _Camera3D 'atomic)])
    ;; camera.position = (Vector3){ 0.0f, 10.0f, 10.0f }
    (ptr-set! cam _float 0 0.0)    ;; pos-x
    (ptr-set! cam _float 1 10.0)   ;; pos-y
    (ptr-set! cam _float 2 10.0)   ;; pos-z
    ;; camera.target = (Vector3){ 0.0f, 0.0f, 0.0f }
    (ptr-set! cam _float 3 0.0)    ;; tar-x
    (ptr-set! cam _float 4 0.0)    ;; tar-y
    (ptr-set! cam _float 5 0.0)    ;; tar-z
    ;; camera.up = (Vector3){ 0.0f, 1.0f, 0.0f }
    (ptr-set! cam _float 6 0.0)    ;; up-x
    (ptr-set! cam _float 7 1.0)    ;; up-y
    (ptr-set! cam _float 8 0.0)    ;; up-z
    ;; camera.fovy = 45.0f
    (ptr-set! cam _float 9 45.0)   ;; fovy
    ;; camera.projection = CAMERA_PERSPECTIVE
    (ptr-set! cam _int 10 CAMERA-PERSPECTIVE) ;; projection (10th int at byte 40)
    cam))

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
