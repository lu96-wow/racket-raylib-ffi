#lang racket/base

;; raylib 3D 场景 — 键盘控制视角
;;
;; 演示:
;;   - 手动相机控制（全键盘操作，不用 update-camera）
;;   - WASD 前后左右移动，QE 上下
;;   - 方向键控制视角（yaw/pitch）
;;   - Shift 加速，Ctrl 减速
;;   - R 重置相机位置
;;
;; 启动: cd racket-bind && racket test/keyboard-camera.rkt

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define SCREEN-WIDTH 1024)
(define SCREEN-HEIGHT 600)

(define MOVE-SPEED 8.0)      ;; 米/秒
(define LOOK-SPEED 1.5)      ;; 弧度/秒

;; ============================================================
;; 3D 向量运算辅助
;; ============================================================

(define (vec3-sub v1 v2)
  (vector3 (- (vector3-x v1) (vector3-x v2))
           (- (vector3-y v1) (vector3-y v2))
           (- (vector3-z v1) (vector3-z v2))))

(define (camera-forward pos target)
  (vec3-normalize (vec3-sub target pos)))

(define (camera-right forward up)
  (vec3-normalize (vec3-cross-product forward up)))

;; ============================================================
;; Camera3D 指针辅助
;; 使用 persistent ptr，yaw/pitch 直接修改它
;; ============================================================

(define (make-cam-ptr)
  (camera3d -10.0 5.0 -10.0   ;; pos
            0.0 0.0 0.0        ;; target
            0.0 1.0 0.0        ;; up
            60.0 CAMERA-PERSPECTIVE))

;; 从 Camera3D 指针读取位置
(define (cam-get-pos cam)
  (vector3 (camera3d-pos-x cam)
           (camera3d-pos-y cam)
           (camera3d-pos-z cam)))

(define (cam-get-target cam)
  (vector3 (camera3d-tar-x cam)
           (camera3d-tar-y cam)
           (camera3d-tar-z cam)))

;; 往 Camera3D 指针写入位置
(define (cam-set-pos! cam x y z)
  (set-camera3d-pos-x! cam x)
  (set-camera3d-pos-y! cam y)
  (set-camera3d-pos-z! cam z))

(define (cam-set-target! cam x y z)
  (set-camera3d-tar-x! cam x)
  (set-camera3d-tar-y! cam y)
  (set-camera3d-tar-z! cam z))

;; 往 Camera3D 指针平移 position + target
(define (cam-move! cam dx dy dz)
  (set-camera3d-pos-x! cam (+ (camera3d-pos-x cam) dx))
  (set-camera3d-pos-y! cam (+ (camera3d-pos-y cam) dy))
  (set-camera3d-pos-z! cam (+ (camera3d-pos-z cam) dz))
  (set-camera3d-tar-x! cam (+ (camera3d-tar-x cam) dx))
  (set-camera3d-tar-y! cam (+ (camera3d-tar-y cam) dy))
  (set-camera3d-tar-z! cam (+ (camera3d-tar-z cam) dz)))

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
             "raylib [test] - keyboard camera control")

(define cam (make-cam-ptr))

;; 保存初始状态
(define init-pos-x -10.0)
(define init-pos-y 5.0)
(define init-pos-z -10.0)
(define init-tar-x 0.0)
(define init-tar-y 0.0)
(define init-tar-z 0.0)

(define speed-mult (box 1.0))

(disable-cursor)
(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()
  (unless (window-should-close?)
    (define dt (get-frame-time))
    (define base-speed (* MOVE-SPEED (unbox speed-mult) dt))
    (define look-angle (* LOOK-SPEED dt))

    ;; --- 相机更新 ---
    (define pos (cam-get-pos cam))
    (define target (cam-get-target cam))
    (define fwd (camera-forward pos target))
    (define right (camera-right fwd (vector3 0.0 1.0 0.0)))

    ;; WASD: 前后左右（沿相机方向）
    (when (is-key-down KEY-W)
      (cam-move! cam
                 (* (vector3-x fwd) base-speed)
                 (* (vector3-y fwd) base-speed)
                 (* (vector3-z fwd) base-speed)))

    (when (is-key-down KEY-S)
      (cam-move! cam
                 (- (* (vector3-x fwd) base-speed))
                 (- (* (vector3-y fwd) base-speed))
                 (- (* (vector3-z fwd) base-speed))))

    (when (is-key-down KEY-A)
      (cam-move! cam
                 (- (* (vector3-x right) base-speed))
                 (- (* (vector3-y right) base-speed))
                 (- (* (vector3-z right) base-speed))))

    (when (is-key-down KEY-D)
      (cam-move! cam
                 (* (vector3-x right) base-speed)
                 (* (vector3-y right) base-speed)
                 (* (vector3-z right) base-speed)))

    ;; Q/E: 上下（沿世界 Y 轴）
    (when (is-key-down KEY-Q)
      (cam-move! cam 0.0 base-speed 0.0))
    (when (is-key-down KEY-E)
      (cam-move! cam 0.0 (- base-speed) 0.0))

    ;; 方向键: 旋转视角（直接修改 cam 指针）
    (when (is-key-down KEY-RIGHT)
      (camera-yaw cam (- look-angle) #t))
    (when (is-key-down KEY-LEFT)
      (camera-yaw cam look-angle #t))
    (when (is-key-down KEY-UP)
      (camera-pitch cam look-angle #t #f #f))
    (when (is-key-down KEY-DOWN)
      (camera-pitch cam (- look-angle) #t #f #f))

    ;; Shift/Ctrl: 速度倍率
    (set-box! speed-mult
              (cond [(is-key-down KEY-LEFT-SHIFT) 3.0]
                    [(is-key-down KEY-LEFT-CONTROL) 0.3]
                    [else 1.0]))

    ;; R: 重置相机
    (when (is-key-pressed KEY-R)
      (cam-set-pos! cam init-pos-x init-pos-y init-pos-z)
      (cam-set-target! cam init-tar-x init-tar-y init-tar-z))

    ;; --- 绘制 3D ---
    (begin-drawing)
    (clear-background (color 245 245 245))

    (begin-mode-3d cam)

    ;; 地面网格（40x40）
    (draw-grid 20 1.0)

    ;; 彩色方块阵列
    (draw-cube (vector3 -4.0 0.5 -2.0) 1.0 1.0 1.0 RED)
    (draw-cube-wires (vector3 -4.0 0.5 -2.0) 1.0 1.0 1.0 MAROON)

    (draw-cube (vector3 0.0 1.0 0.0) 2.0 2.0 2.0 BLUE)
    (draw-cube-wires (vector3 0.0 1.0 0.0) 2.0 2.0 2.0 DARKBLUE)

    (draw-cube (vector3 3.0 0.5 3.0) 1.0 1.0 1.0 GREEN)
    (draw-cube-wires (vector3 3.0 0.5 3.0) 1.0 1.0 1.0 DARKGREEN)

    (draw-cube (vector3 -3.0 0.5 4.0) 1.0 2.0 1.0 PURPLE)
    (draw-cube-wires (vector3 -3.0 0.5 4.0) 1.0 2.0 1.0 DARKPURPLE)

    ;; 球体
    (draw-sphere (vector3 2.0 0.5 -3.0) 0.5 GOLD)
    (draw-sphere (vector3 -2.0 0.5 -4.0) 0.7 ORANGE)
    (draw-sphere (vector3 4.0 1.0 0.0) 1.0 PINK)

    ;; 地面半透明参考平面
    (draw-plane (vector3 0.0 0.0 0.0) (vector2 20.0 20.0) (fade LIGHTGRAY 0.3))

    (end-mode-3d)

    ;; --- HUD ---
    (draw-fps 10 10)
    (draw-text "WASD=move  QE=up/down  Arrows=look" 10 50 20 DARKGRAY)
    (draw-text "Shift=speed  Ctrl=slow  R=reset" 10 75 20 DARKGRAY)

    (define cur-pos (cam-get-pos cam))
    (draw-text (format "Pos: ~a ~a ~a"
                       (vector3-x cur-pos) (vector3-y cur-pos) (vector3-z cur-pos))
               10 110 15 BLACK)
    (draw-text (string-append "Speed: " (number->string (unbox speed-mult)))
               10 130 15 BLACK)

    (end-drawing)

    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
