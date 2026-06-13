#lang racket/base

;; raylib [models] example - directional billboard (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_directional_billboard.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(define-runtime-path resource-dir "../../../examples/models/resources/")

(init-window screen-width screen-height
  "raylib [models] example - directional billboard")

;; 定义 3D 相机
(define camera (camera3d 2.0 1.0 2.0
                         0.0 0.5 0.0
                         0.0 1.0 0.0
                         45.0 CAMERA-PERSPECTIVE))

;; 加载纹理（spritesheet: 8 方向 × 4 帧动画, 每个格子 24×24）
(define skillbot (load-texture (path->string (build-path resource-dir "skillbot.png"))))

(define anim-timer 0.0)
(define anim 0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    (update-camera camera CAMERA-ORBITAL)

    ;; 动画计时器（每 0.5 秒切换一帧）
    (set! anim-timer (+ anim-timer (get-frame-time)))
    (when (> anim-timer 0.5)
      (set! anim-timer 0.0)
      (set! anim (add1 anim)))
    (when (>= anim 4) (set! anim 0))

    ;; 根据相机位置计算方向帧索引 (Vector2Angle 手工实现)
    (let* ([cam-x (camera3d-pos-x camera)]
           [cam-z (camera3d-pos-z camera)]
           [angle (atan (- cam-z 0.0) (- cam-x 2.0))]
           [dir (floor (+ (* (/ angle (* 2 (asin 1.0))) 4.0) 0.25))]
           [dir (if (< dir 0.0)
                    (- 8.0 (abs (inexact->exact dir)))
                    dir)])

      ;; ---- Draw ----
      (begin-drawing)
      (clear-background RAYWHITE)

      (begin-mode-3d camera)

      (draw-grid 10 1.0)

      ;; 方向 billboard: spritesheet 中 (anim*24, dir*24) 位置取 24×24 子图
      (draw-billboard-pro camera skillbot
                          (rectangle (exact->inexact (* anim 24))
                                     (* (exact->inexact dir) 24.0)
                                     24.0 24.0)
                          (vector3 0.0 0.0 0.0)    ;; position
                          (vector3 0.0 1.0 0.0)    ;; up
                          (vector2 1.0 1.0)        ;; size
                          (vector2 0.5 0.0)        ;; origin
                          0.0 WHITE)

      (end-mode-3d)

      (draw-text (format "animation: ~a" anim) 10 10 20 DARKGRAY)
      (draw-text (format "direction frame: ~a" dir) 10 40 20 DARKGRAY)

      (end-drawing)
      (loop))))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture skillbot)
(close-window)
