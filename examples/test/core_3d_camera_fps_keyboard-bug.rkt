#lang racket/base

;; raylib [core] example - 3d camera fps 键盘控制版
;;
;; 键盘控制视角 (代替鼠标):
;;   W/S/A/D - 移动
;;   LEFT/RIGHT - 水平旋转 (yaw)
;;   UP/DOWN   - 俯仰 (pitch)
;;   Space    - 跳跃
;;   Left-Ctrl - 蹲下
;;
;; 完整版: 含头部晃动、下蹲、身体倾斜

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)

(define GRAVITY       32.0)
(define MAX-SPEED     20.0)
(define CROUCH-SPEED   5.0)
(define JUMP-FORCE    12.0)
(define MAX-ACCEL    150.0)
(define FRICTION       0.86)
(define AIR-DRAG       0.98)
(define CONTROL       15.0)
(define CROUCH-HEIGHT  0.0)
(define STAND-HEIGHT   1.0)
(define BOTTOM-HEIGHT  0.5)
(define PI (* 4 (atan 1.0)))
(define LOOK-SPEED 0.03)

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - 3d camera fps (keyboard control)")

(define player-pos  (vector3 0.0 0.0 0.0))
(define player-vel  (vector3 0.0 0.0 0.0))
(define player-dir  (vector3 0.0 0.0 0.0))
(define player-grounded (box #t))
(define look-yaw    (box 0.0))
(define look-pitch  (box 0.0))

;; 动画状态
(define head-timer (box 0.0))
(define walk-lerp  (box 0.0))
(define head-lerp  (box STAND-HEIGHT))
(define lean-x     (box 0.0))
(define lean-y     (box 0.0))

(define camera
  (camera3d
    (vector3-x player-pos)
    (+ (vector3-y player-pos) BOTTOM-HEIGHT (unbox head-lerp))
    (vector3-z player-pos)
    0.0 0.0 0.0 0.0 1.0 0.0 60.0 CAMERA-PERSPECTIVE))

(set-target-fps 60)

;; ============================================================
;; 物理更新 (简化版)
;; ============================================================

(define (update-body rot side fwd-param jump-pressed? crouch-hold?)
  (let* ([delta (get-frame-time)]
         [front-x (sin rot)] [front-z (cos rot)]
         [right-x (cos (- rot))] [right-z (sin (- rot))]
         [desired-dir-x (+ (* side right-x) (* (- fwd-param) front-x))]
         [desired-dir-z (+ (* side right-z) (* (- fwd-param) front-z))]
         [decel (if (unbox player-grounded) FRICTION AIR-DRAG)]
         [hvel-x (box (* (vector3-x player-vel) decel))]
         [hvel-z (box (* (vector3-z player-vel) decel))])

    ;; 重力
    (unless (unbox player-grounded)
      (set-vector3-y! player-vel
        (- (vector3-y player-vel) (* GRAVITY delta))))

    ;; 跳跃
    (when (and (unbox player-grounded) jump-pressed?)
      (set-vector3-y! player-vel JUMP-FORCE)
      (set-box! player-grounded #f))

    ;; dir = lerp(dir, desiredDir, CONTROL*delta)
    (let ([amount (* CONTROL delta)])
      (set-vector3-x! player-dir (lerp (vector3-x player-dir) desired-dir-x amount))
      (set-vector3-z! player-dir (lerp (vector3-z player-dir) desired-dir-z amount)))

    ;; 如果速度很小就归零
    (let ([hvel-len (sqrt (+ (* (unbox hvel-x) (unbox hvel-x))
                             (* (unbox hvel-z) (unbox hvel-z))))])
      (when (< hvel-len (* MAX-SPEED 0.01))
        (set-box! hvel-x 0.0)
        (set-box! hvel-z 0.0)))

    ;; 在 dir 方向加速 (含下蹲限速)
    (let* ([dir-x (vector3-x player-dir)]
           [dir-z (vector3-z player-dir)]
           [speed (+ (* (unbox hvel-x) dir-x) (* (unbox hvel-z) dir-z))]
           [max-speed (if crouch-hold? CROUCH-SPEED MAX-SPEED)]
           [accel (clamp (- max-speed speed) 0.0 (* MAX-ACCEL delta))])
      (set-vector3-x! player-vel (+ (unbox hvel-x) (* dir-x accel)))
      (set-vector3-z! player-vel (+ (unbox hvel-z) (* dir-z accel))))

    ;; 更新位置
    (set-vector3-x! player-pos
      (+ (vector3-x player-pos) (* (vector3-x player-vel) delta)))
    (set-vector3-y! player-pos
      (+ (vector3-y player-pos) (* (vector3-y player-vel) delta)))
    (set-vector3-z! player-pos
      (+ (vector3-z player-pos) (* (vector3-z player-vel) delta)))

    ;; 地面碰撞
    (when (<= (vector3-y player-pos) 0.0)
      (set-vector3-y! player-pos 0.0)
      (set-vector3-y! player-vel 0.0)
      (set-box! player-grounded #t))))

;; ============================================================
;; 相机更新 (键盘控制视角)
;; ============================================================

(define (update-camera cam)
  (define up (vector3 0.0 1.0 0.0))
  (define target-offset (vector3 0.0 0.0 -1.0))
  (define rot (unbox look-yaw))
  (define yaw (vec3-rotate-by-axis-angle target-offset up rot))
  (define max-angle-up (- (vec3-angle up yaw) 0.001))
  (define max-angle-down (+ (* -1 (vec3-angle (vec3-negate up) yaw)) 0.001))
  (define right (vec3-normalize (vec3-cross-product yaw up)))
  (define pitch-angle (- (- (unbox look-pitch)) (unbox lean-y)))
  (define pitch-angle-clamped
    (clamp pitch-angle (- (/ PI 2) 0.0001) (- (/ PI 2) 0.0001)))
  (define pitch (vec3-rotate-by-axis-angle yaw right pitch-angle-clamped))
  (define head-sin (sin (* (unbox head-timer) PI)))
  (define head-cos (cos (* (unbox head-timer) PI)))
  (define step-rotation 0.01)
  (define head-up-offset (+ (* head-sin step-rotation) (unbox lean-x)))
  (define new-up (vec3-rotate-by-axis-angle up pitch head-up-offset))
  (define bob-side 0.1)
  (define bob-up 0.15)
  (define bobbing (vec3-scale right (* head-sin bob-side)))
  (define camera-pos
    (vector3 (camera3d-pos-x cam) (camera3d-pos-y cam) (camera3d-pos-z cam)))
  (define bobbed-pos (vec3-add camera-pos (vec3-scale bobbing (unbox walk-lerp))))
  (define target-pos (vec3-add camera-pos pitch))

  ;; Clamp 俯仰角上限
  (when (> (- (unbox look-pitch)) max-angle-up)
    (set-box! look-pitch (- max-angle-up)))
  ;; Clamp 俯仰角下限
  (when (< (- (unbox look-pitch)) max-angle-down)
    (set-box! look-pitch (- max-angle-down)))

  (set-vector3-y! bobbing (abs (* head-cos bob-up)))
  (set-camera3d-pos-x! cam (vector3-x bobbed-pos))
  (set-camera3d-pos-y! cam (vector3-y bobbed-pos))
  (set-camera3d-pos-z! cam (vector3-z bobbed-pos))
  (set-camera3d-tar-x! cam (vector3-x target-pos))
  (set-camera3d-tar-y! cam (vector3-y target-pos))
  (set-camera3d-tar-z! cam (vector3-z target-pos))
  (set-camera3d-up-x! cam (vector3-x new-up))
  (set-camera3d-up-y! cam (vector3-y new-up))
  (set-camera3d-up-z! cam (vector3-z new-up)))

;; ============================================================
;; 绘制关卡
;; ============================================================

(define (draw-level)
  (for* ([y (in-range -25 25)] [x (in-range -25 25)])
    (cond
      [(and (odd? y) (odd? x))
       (draw-plane (vector3 (* x 5.0) 0.0 (* y 5.0)) (vector2 5.0 5.0)
                   (color 150 200 200))]
      [(and (even? y) (even? x))
       (draw-plane (vector3 (* x 5.0) 0.0 (* y 5.0)) (vector2 5.0 5.0) LIGHTGRAY)]))
  (define tower-size (vector3 16.0 32.0 16.0))
  (define tower-color (color 150 200 200))
  (define (draw-tower x z)
    (define pos (vector3 x 16.0 z))
    (draw-cube-v pos tower-size tower-color)
    (draw-cube-wires-v pos tower-size DARKBLUE))
  (draw-tower 16.0 16.0) (draw-tower -16.0 16.0)
  (draw-tower -16.0 -16.0) (draw-tower 16.0 -16.0)
  (draw-sphere (vector3 300.0 300.0 0.0) 100.0 (color 255 0 0)))

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (let* ([delta (get-frame-time)]
           [sideway (- (if (is-key-down KEY-D) 1 0) (if (is-key-down KEY-A) 1 0))]
           [fwd     (- (if (is-key-down KEY-W) 1 0) (if (is-key-down KEY-S) 1 0))]
           [crouching (is-key-down KEY-LEFT-CONTROL)])

      ;; 键盘控制视角
      (when (is-key-down KEY-LEFT)  (set-box! look-yaw (+ (unbox look-yaw) (* LOOK-SPEED 60 delta))))
      (when (is-key-down KEY-RIGHT) (set-box! look-yaw (- (unbox look-yaw) (* LOOK-SPEED 60 delta))))
      (when (is-key-down KEY-UP)    (set-box! look-pitch (+ (unbox look-pitch) (* LOOK-SPEED 60 delta))))
      (when (is-key-down KEY-DOWN)  (set-box! look-pitch (- (unbox look-pitch) (* LOOK-SPEED 60 delta))))

      ;; 移动 (含下蹲)
      (update-body (unbox look-yaw) sideway fwd (is-key-pressed KEY-SPACE) crouching)

      ;; 头部动画插值 (下蹲)
      (set-box! head-lerp
        (lerp (unbox head-lerp)
              (if crouching CROUCH-HEIGHT STAND-HEIGHT)
              (* 20.0 delta)))

      ;; 更新相机位置
      (set-camera3d-pos-x! camera (vector3-x player-pos))
      (set-camera3d-pos-y! camera
        (+ (vector3-y player-pos) BOTTOM-HEIGHT (unbox head-lerp)))
      (set-camera3d-pos-z! camera (vector3-z player-pos))

      ;; 行走动画 (头部晃动 + FOV 变化)
      (if (and (unbox player-grounded) (or (not (= fwd 0)) (not (= sideway 0))))
        (begin
          (set-box! head-timer (+ (unbox head-timer) (* delta 3.0)))
          (set-box! walk-lerp (lerp (unbox walk-lerp) 1.0 (* 10.0 delta)))
          (set-camera3d-fovy! camera
            (lerp (camera3d-fovy camera) 55.0 (* 5.0 delta))))
        (begin
          (set-box! walk-lerp (lerp (unbox walk-lerp) 0.0 (* 10.0 delta)))
          (set-camera3d-fovy! camera
            (lerp (camera3d-fovy camera) 60.0 (* 5.0 delta)))))

      ;; 身体倾斜
      (set-box! lean-x (lerp (unbox lean-x) (* sideway 0.02) (* 10.0 delta)))
      (set-box! lean-y (lerp (unbox lean-y) (* fwd 0.015) (* 10.0 delta)))

      (update-camera camera)

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)
      (begin-mode-3d camera)
      (draw-level)
      (end-mode-3d)

      (draw-rectangle 5 5 280 70 (fade SKYBLUE 0.5))
      (draw-rectangle-lines 5 5 280 70 BLUE)
      (draw-text "Keyboard controls:" 15 15 10 BLACK)
      (draw-text "W/A/S/D: move   Space: jump   Ctrl: crouch" 15 30 10 BLACK)
      (draw-text "Arrow keys: look around" 15 45 10 BLACK)
      (let ([vx (vector3-x player-vel)] [vz (vector3-z player-vel)])
        (draw-text (format "Speed: ~a" (let ([v (sqrt (+ (* vx vx) (* vz vz)))])
                                         (/ (round (* 100 v)) 100.0)))
                   15 60 10 BLACK))

      (end-drawing)
      (loop))))

(close-window)
