#lang racket/base

;; raylib [core] example - 3d camera free (WASD 手动控制测试版)
;;
;; 对应 C: examples/core/core_3d_camera_free.c
;; 修改为用 WASD 手动控制相机位置, 验证 Camera3D 字段绑定正确性
;;   W/S: 沿 target 方向前进/后退
;;   A/D: 横向平移 (strafe)
;;   Q/E: 上下移动

(require (except-in ffi/unsafe _bool)
         "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
             "raylib [core] example - 3d camera free (WASD test)")

;; 定义 3D 相机
(define camera
  (let ([cam (malloc _Camera3D 'atomic)])
    ;; camera.position = (Vector3){ 10.0f, 10.0f, 10.0f }
    (ptr-set! cam _float 0 10.0)   ;; pos-x
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

;; 移动速度
(define move-speed 0.3)

(set-target-fps 60)

;; ============================================================
;; 辅助: 读取相机字段
;; ============================================================

(define (cam-pos-x)   (ptr-ref camera _float 0))
(define (cam-pos-y)   (ptr-ref camera _float 1))
(define (cam-pos-z)   (ptr-ref camera _float 2))
(define (cam-tar-x)   (ptr-ref camera _float 3))
(define (cam-tar-y)   (ptr-ref camera _float 4))
(define (cam-tar-z)   (ptr-ref camera _float 5))
(define (cam-up-x)    (ptr-ref camera _float 6))
(define (cam-up-y)    (ptr-ref camera _float 7))
(define (cam-up-z)    (ptr-ref camera _float 8))
(define (cam-fovy)    (ptr-ref camera _float 9))
(define (cam-proj)    (ptr-ref camera _int 10))

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- 手动 WASD 控制 ----
    (when (is-key-down KEY-W)
      ;; 沿视线方向前进
      (let* ([dx (- (cam-tar-x) (cam-pos-x))]
             [dy (- (cam-tar-y) (cam-pos-y))]
             [dz (- (cam-tar-z) (cam-pos-z))]
             [len (sqrt (+ (* dx dx) (* dy dy) (* dz dz)))])
        (ptr-set! camera _float 0 (+ (cam-pos-x) (* (/ dx len) move-speed)))
        (ptr-set! camera _float 1 (+ (cam-pos-y) (* (/ dy len) move-speed)))
        (ptr-set! camera _float 2 (+ (cam-pos-z) (* (/ dz len) move-speed)))))

    (when (is-key-down KEY-S)
      ;; 沿视线方向后退
      (let* ([dx (- (cam-tar-x) (cam-pos-x))]
             [dy (- (cam-tar-y) (cam-pos-y))]
             [dz (- (cam-tar-z) (cam-pos-z))]
             [len (sqrt (+ (* dx dx) (* dy dy) (* dz dz)))])
        (ptr-set! camera _float 0 (- (cam-pos-x) (* (/ dx len) move-speed)))
        (ptr-set! camera _float 1 (- (cam-pos-y) (* (/ dy len) move-speed)))
        (ptr-set! camera _float 2 (- (cam-pos-z) (* (/ dz len) move-speed)))))

    (when (is-key-down KEY-A)
      ;; 向左平移 (strafe)
      (let* ([fx (- (cam-tar-x) (cam-pos-x))]
             [fy (- (cam-tar-y) (cam-pos-y))]
             [fz (- (cam-tar-z) (cam-pos-z))]
             [sx (- (* (cam-up-y) fz) (* (cam-up-z) fy))]
             [sy (- (* (cam-up-z) fx) (* (cam-up-x) fz))]
             [sz (- (* (cam-up-x) fy) (* (cam-up-y) fx))]
             [len (sqrt (+ (* sx sx) (* sy sy) (* sz sz)))])
        (ptr-set! camera _float 0 (- (cam-pos-x) (* (/ sx len) move-speed)))
        (ptr-set! camera _float 1 (- (cam-pos-y) (* (/ sy len) move-speed)))
        (ptr-set! camera _float 2 (- (cam-pos-z) (* (/ sz len) move-speed)))))

    (when (is-key-down KEY-D)
      ;; 向右平移
      (let* ([fx (- (cam-tar-x) (cam-pos-x))]
             [fy (- (cam-tar-y) (cam-pos-y))]
             [fz (- (cam-tar-z) (cam-pos-z))]
             [sx (- (* (cam-up-y) fz) (* (cam-up-z) fy))]
             [sy (- (* (cam-up-z) fx) (* (cam-up-x) fz))]
             [sz (- (* (cam-up-x) fy) (* (cam-up-y) fx))]
             [len (sqrt (+ (* sx sx) (* sy sy) (* sz sz)))])
        (ptr-set! camera _float 0 (+ (cam-pos-x) (* (/ sx len) move-speed)))
        (ptr-set! camera _float 1 (+ (cam-pos-y) (* (/ sy len) move-speed)))
        (ptr-set! camera _float 2 (+ (cam-pos-z) (* (/ sz len) move-speed)))))

    (when (is-key-down KEY-Q)
      ;; 向下移动
      (ptr-set! camera _float 1 (- (cam-pos-y) move-speed)))

    (when (is-key-down KEY-E)
      ;; 向上移动
      (ptr-set! camera _float 1 (+ (cam-pos-y) move-speed)))

    ;; ---- 调试信息: 在左上角显示相机位置 ----
    (begin-drawing)

    (clear-background RAYWHITE)

    (begin-mode-3d camera)

    (draw-cube cube-position 2.0 2.0 2.0 RED)
    (draw-cube-wires cube-position 2.0 2.0 2.0 MAROON)

    (draw-grid 10 1.0)

    (end-mode-3d)

    (draw-text (format "Camera pos: ~a, ~a, ~a"
                       (cam-pos-x) (cam-pos-y) (cam-pos-z))
               10 10 20 BLACK)
    (draw-text "W/S: forward/back  A/D: strafe  Q/E: up/down"
               10 40 10 DARKGRAY)

    (draw-fps 10 60)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
