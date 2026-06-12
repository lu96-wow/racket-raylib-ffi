#lang racket/base

;; raylib [models] example - box collisions (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_box_collisions.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [models] example - box collisions")

;; 定义 3D 相机
(define camera (camera3d 0.0 10.0 10.0
                         0.0  0.0  0.0
                         0.0  1.0  0.0
                         45.0 CAMERA-PERSPECTIVE))

;; 玩家 (可移动方块)
(define player-position (vector3 0.0 1.0 2.0))
(define player-size (vector3 1.0 2.0 1.0))
(define player-color GREEN)

;; 敌人方块 (固定)
(define enemy-box-pos (vector3 -4.0 1.0 0.0))
(define enemy-box-size (vector3 2.0 2.0 2.0))

;; 敌人球体 (固定)
(define enemy-sphere-pos (vector3 4.0 0.0 0.0))
(define enemy-sphere-size 1.5)

(define collision #f)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    ;; 移动玩家 (箭头键)
    (cond [(is-key-down KEY-RIGHT) (set-vector3-x! player-position
                                     (+ (vector3-x player-position) 0.2))]
          [(is-key-down KEY-LEFT)  (set-vector3-x! player-position
                                     (- (vector3-x player-position) 0.2))]
          [(is-key-down KEY-DOWN)  (set-vector3-z! player-position
                                     (+ (vector3-z player-position) 0.2))]
          [(is-key-down KEY-UP)    (set-vector3-z! player-position
                                     (- (vector3-z player-position) 0.2))])

    (set! collision #f)

    ;; 碰撞检测: 玩家 vs 敌人方块
    (let ([player-bb (bounding-box
                       (- (vector3-x player-position) (/ (vector3-x player-size) 2.0))
                       (- (vector3-y player-position) (/ (vector3-y player-size) 2.0))
                       (- (vector3-z player-position) (/ (vector3-z player-size) 2.0))
                       (+ (vector3-x player-position) (/ (vector3-x player-size) 2.0))
                       (+ (vector3-y player-position) (/ (vector3-y player-size) 2.0))
                       (+ (vector3-z player-position) (/ (vector3-z player-size) 2.0)))]
          [enemy-bb (bounding-box
                      (- (vector3-x enemy-box-pos) (/ (vector3-x enemy-box-size) 2.0))
                      (- (vector3-y enemy-box-pos) (/ (vector3-y enemy-box-size) 2.0))
                      (- (vector3-z enemy-box-pos) (/ (vector3-z enemy-box-size) 2.0))
                      (+ (vector3-x enemy-box-pos) (/ (vector3-x enemy-box-size) 2.0))
                      (+ (vector3-y enemy-box-pos) (/ (vector3-y enemy-box-size) 2.0))
                      (+ (vector3-z enemy-box-pos) (/ (vector3-z enemy-box-size) 2.0)))])
      (when (check-collision-boxes player-bb enemy-bb)
        (set! collision #t)))

    ;; 碰撞检测: 玩家 vs 敌人球体
    (let ([player-bb (bounding-box
                       (- (vector3-x player-position) (/ (vector3-x player-size) 2.0))
                       (- (vector3-y player-position) (/ (vector3-y player-size) 2.0))
                       (- (vector3-z player-position) (/ (vector3-z player-size) 2.0))
                       (+ (vector3-x player-position) (/ (vector3-x player-size) 2.0))
                       (+ (vector3-y player-position) (/ (vector3-y player-size) 2.0))
                       (+ (vector3-z player-position) (/ (vector3-z player-size) 2.0)))])
      (when (check-collision-box-sphere player-bb enemy-sphere-pos enemy-sphere-size)
        (set! collision #t)))

    ;; 碰撞时变红，否则绿色
    (set! player-color (if collision RED GREEN))

    ;; ---- Draw ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)

    ;; 敌人方块
    (draw-cube enemy-box-pos (vector3-x enemy-box-size)
               (vector3-y enemy-box-size) (vector3-z enemy-box-size) GRAY)
    (draw-cube-wires enemy-box-pos (vector3-x enemy-box-size)
                     (vector3-y enemy-box-size) (vector3-z enemy-box-size) DARKGRAY)

    ;; 敌人球体
    (draw-sphere enemy-sphere-pos enemy-sphere-size GRAY)
    (draw-sphere-wires enemy-sphere-pos enemy-sphere-size 16 16 DARKGRAY)

    ;; 玩家方块
    (draw-cube-v player-position player-size player-color)

    ;; 网格
    (draw-grid 10 1.0)

    (end-mode-3d)

    (draw-text "Move player with arrow keys to collide" 220 40 20 GRAY)
    (draw-fps 10 10)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
