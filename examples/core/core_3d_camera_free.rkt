#lang racket/base

;; raylib [core] example - 3d camera free (WASD 手动控制测试版)
;;
;; 对应 C: examples/core/core_3d_camera_free.c 这个为了测试racket Camera做了修改
;; 修改为用 WASD 手动控制相机位置, 验证 Camera3D 字段绑定正确性
;;   W/S: 沿 target 方向前进/后退
;;   A/D: 横向平移 (strafe)
;;   Q/E: 上下移动

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
             "raylib [core] example - 3d camera free (WASD test)")

;; 定义 3D 相机 (使用 raylib-var 提供的 camera3d 构造器)
(define camera
  (camera3d 10.0 10.0 10.0   ;; position  (10, 10, 10)
            0.0 0.0 0.0       ;; target   (0, 0, 0)
            0.0 1.0 0.0       ;; up       (0, 1, 0)
            45.0              ;; fovy
            CAMERA-PERSPECTIVE))

;; 方块位置
(define cube-position (vector3 0.0 0.0 0.0))

;; 移动速度
(define move-speed 0.3)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- 手动 WASD 控制 ----
    (when (is-key-down KEY-W)
      ;; 沿视线方向前进
      (let* ([dx (- (camera3d-tar-x camera) (camera3d-pos-x camera))]
             [dy (- (camera3d-tar-y camera) (camera3d-pos-y camera))]
             [dz (- (camera3d-tar-z camera) (camera3d-pos-z camera))]
             [len (sqrt (+ (* dx dx) (* dy dy) (* dz dz)))])
        (set-camera3d-pos-x! camera (+ (camera3d-pos-x camera) (* (/ dx len) move-speed)))
        (set-camera3d-pos-y! camera (+ (camera3d-pos-y camera) (* (/ dy len) move-speed)))
        (set-camera3d-pos-z! camera (+ (camera3d-pos-z camera) (* (/ dz len) move-speed)))))

    (when (is-key-down KEY-S)
      ;; 沿视线方向后退
      (let* ([dx (- (camera3d-tar-x camera) (camera3d-pos-x camera))]
             [dy (- (camera3d-tar-y camera) (camera3d-pos-y camera))]
             [dz (- (camera3d-tar-z camera) (camera3d-pos-z camera))]
             [len (sqrt (+ (* dx dx) (* dy dy) (* dz dz)))])
        (set-camera3d-pos-x! camera (- (camera3d-pos-x camera) (* (/ dx len) move-speed)))
        (set-camera3d-pos-y! camera (- (camera3d-pos-y camera) (* (/ dy len) move-speed)))
        (set-camera3d-pos-z! camera (- (camera3d-pos-z camera) (* (/ dz len) move-speed)))))

    (when (is-key-down KEY-A)
      ;; 向左平移 (strafe)
      (let* ([fx (- (camera3d-tar-x camera) (camera3d-pos-x camera))]
             [fy (- (camera3d-tar-y camera) (camera3d-pos-y camera))]
             [fz (- (camera3d-tar-z camera) (camera3d-pos-z camera))]
             [sx (- (* (camera3d-up-y camera) fz) (* (camera3d-up-z camera) fy))]
             [sy (- (* (camera3d-up-z camera) fx) (* (camera3d-up-x camera) fz))]
             [sz (- (* (camera3d-up-x camera) fy) (* (camera3d-up-y camera) fx))]
             [len (sqrt (+ (* sx sx) (* sy sy) (* sz sz)))])
        (set-camera3d-pos-x! camera (- (camera3d-pos-x camera) (* (/ sx len) move-speed)))
        (set-camera3d-pos-y! camera (- (camera3d-pos-y camera) (* (/ sy len) move-speed)))
        (set-camera3d-pos-z! camera (- (camera3d-pos-z camera) (* (/ sz len) move-speed)))))

    (when (is-key-down KEY-D)
      ;; 向右平移
      (let* ([fx (- (camera3d-tar-x camera) (camera3d-pos-x camera))]
             [fy (- (camera3d-tar-y camera) (camera3d-pos-y camera))]
             [fz (- (camera3d-tar-z camera) (camera3d-pos-z camera))]
             [sx (- (* (camera3d-up-y camera) fz) (* (camera3d-up-z camera) fy))]
             [sy (- (* (camera3d-up-z camera) fx) (* (camera3d-up-x camera) fz))]
             [sz (- (* (camera3d-up-x camera) fy) (* (camera3d-up-y camera) fx))]
             [len (sqrt (+ (* sx sx) (* sy sy) (* sz sz)))])
        (set-camera3d-pos-x! camera (+ (camera3d-pos-x camera) (* (/ sx len) move-speed)))
        (set-camera3d-pos-y! camera (+ (camera3d-pos-y camera) (* (/ sy len) move-speed)))
        (set-camera3d-pos-z! camera (+ (camera3d-pos-z camera) (* (/ sz len) move-speed)))))

    (when (is-key-down KEY-Q)
      ;; 向下移动
      (set-camera3d-pos-y! camera (- (camera3d-pos-y camera) move-speed)))

    (when (is-key-down KEY-E)
      ;; 向上移动
      (set-camera3d-pos-y! camera (+ (camera3d-pos-y camera) move-speed)))

    ;; ---- 绘制 ----
    (begin-drawing)

    (clear-background RAYWHITE)

    (begin-mode-3d camera)

    (draw-cube cube-position 2.0 2.0 2.0 RED)
    (draw-cube-wires cube-position 2.0 2.0 2.0 MAROON)

    (draw-grid 10 1.0)

    (end-mode-3d)

    (draw-text (format "Camera pos: ~a, ~a, ~a"
                       (camera3d-pos-x camera)
                       (camera3d-pos-y camera)
                       (camera3d-pos-z camera))
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
