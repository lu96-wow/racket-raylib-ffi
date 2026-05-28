#lang racket/base

;; raylib [core] example - 2d camera
;; 对应 C: examples/core/core_2d_camera.c

(require "../../raylib/raylib.rkt"
         racket/math)

(define MAX-BUILDINGS 100)
(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 450)

;; 初始化
(init-window SCREEN-WIDTH SCREEN-HEIGHT
             "raylib [core] example - 2d camera")

;; 玩家
(define player (rectangle 400 280 40 40))

;; 建筑物
(define buildings (make-vector MAX-BUILDINGS))
(define build-colors (make-vector MAX-BUILDINGS))

(let loop ([i 0] [spacing 0])
  (when (< i MAX-BUILDINGS)
    (define w (get-random-value 50 200))
    (define h (get-random-value 100 800))
    (define y (- (- SCREEN-HEIGHT 130.0) h))
    (define x (+ -6000.0 spacing))
    (vector-set! buildings i (rectangle x y w h))
    (vector-set! build-colors i
                 (make-color (get-random-value 200 240)
                             (get-random-value 200 240)
                             (get-random-value 200 250)))
    (loop (+ i 1) (+ spacing w))))

;; 相机
(define cam
  (camera2d
   (+ (rectangle-x player) 20.0)   ;; target-x
   (+ (rectangle-y player) 20.0)   ;; target-y
   (/ SCREEN-WIDTH 2.0)            ;; offset-x
   (/ SCREEN-HEIGHT 2.0)           ;; offset-y
   0.0                             ;; rotation
   1.0))                           ;; zoom

(set-target-fps 60)

;; 主循环
(let game-loop ()
  (unless (window-should-close?)

    ;; 玩家移动
    (when (is-key-down KEY-RIGHT) (set-rectangle-x! player (+ (rectangle-x player) 2)))
    (when (is-key-down KEY-LEFT)  (set-rectangle-x! player (- (rectangle-x player) 2)))

    ;; 相机跟随玩家
    (set-camera2d-target-x! cam (+ (rectangle-x player) 20.0))
    (set-camera2d-target-y! cam (+ (rectangle-y player) 20.0))

    ;; 相机旋转
    (when (is-key-down KEY-A) (set-camera2d-rotation! cam (- (camera2d-rotation cam) 1)))
    (when (is-key-down KEY-S) (set-camera2d-rotation! cam (+ (camera2d-rotation cam) 1)))

    ;; 限制旋转 ±40°
    (when (> (camera2d-rotation cam) 40)  (set-camera2d-rotation! cam 40))
    (when (< (camera2d-rotation cam) -40) (set-camera2d-rotation! cam -40))

    ;; 相机缩放
    (set-camera2d-zoom! cam
      (exp (+ (log (max (camera2d-zoom cam) 0.001))
              (* (get-mouse-wheel-move) 0.1))))
    (when (> (camera2d-zoom cam) 3.0) (set-camera2d-zoom! cam 3.0))
    (when (< (camera2d-zoom cam) 0.1) (set-camera2d-zoom! cam 0.1))

    ;; 重置
    (when (is-key-pressed KEY-R)
      (set-camera2d-zoom! cam 1.0)
      (set-camera2d-rotation! cam 0.0))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-2d cam)
    (draw-rectangle -6000 320 13000 8000 DARKGRAY)
    (for ([i (in-range MAX-BUILDINGS)])
      (draw-rectangle-rec (vector-ref buildings i)
                          (vector-ref build-colors i)))
    (draw-rectangle-rec player RED)
    (draw-line (exact-truncate (camera2d-target-x cam))
               (* -1 SCREEN-HEIGHT 10)
               (exact-truncate (camera2d-target-x cam))
               (* SCREEN-HEIGHT 10) GREEN)
    (draw-line (* -1 SCREEN-WIDTH 10)
               (exact-truncate (camera2d-target-y cam))
               (* SCREEN-WIDTH 10)
               (exact-truncate (camera2d-target-y cam)) GREEN)
    (end-mode-2d)

    ;; UI
    (draw-text "SCREEN AREA" 640 10 20 RED)
    (draw-rectangle 0 0 SCREEN-WIDTH 5 RED)
    (draw-rectangle 0 5 5 (- SCREEN-HEIGHT 10) RED)
    (draw-rectangle (- SCREEN-WIDTH 5) 5 5 (- SCREEN-HEIGHT 10) RED)
    (draw-rectangle 0 (- SCREEN-HEIGHT 5) SCREEN-WIDTH 5 RED)

    (draw-rectangle-rec (rectangle 10 10 250 113) (fade SKYBLUE 0.5))
    (draw-rectangle-lines 10 10 250 113 BLUE)
    (draw-text "Free 2D camera controls:" 20 20 10 BLACK)
    (draw-text "- Right/Left to move player" 40 40 10 DARKGRAY)
    (draw-text "- Mouse Wheel to Zoom in-out" 40 60 10 DARKGRAY)
    (draw-text "- A / S to Rotate" 40 80 10 DARKGRAY)
    (draw-text "- R to reset Zoom and Rotation" 40 100 10 DARKGRAY)

    (end-drawing)
    (game-loop)))

(close-window)
