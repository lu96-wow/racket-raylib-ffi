#lang racket/base

;; raylib [models] example - rlgl solar system (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_rlgl_solar_system.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         racket/flonum)

(define PI 3.141592653589793)
(define DEG2RAD (fl/ PI 180.0))

;; ============================================================
;; DrawSphereBasic — 用 RLGL 即时模式手绘球体
;; (等价 C: DrawSphereBasic，球心在原点，半径=1)
;; ============================================================

(define (draw-sphere-basic color)
  (define rings 16)
  (define slices 16)
  (rl-check-render-batch-limit (* (+ rings 2) slices 6))
  (rl-begin RL-TRIANGLES)
  (rl-color-4ub (color-r color) (color-g color) (color-b color) (color-a color))
  (for ([i (in-range (+ rings 2))])
    (for ([j (in-range slices)])
      (define phi0 (fl* DEG2RAD (fl+ 270.0 (fl/ (fl* 180.0 (exact->inexact i))
                                                 (exact->inexact (+ rings 1))))))
      (define phi1 (fl* DEG2RAD (fl+ 270.0 (fl/ (fl* 180.0 (exact->inexact (+ i 1)))
                                                 (exact->inexact (+ rings 1))))))
      (define theta0 (fl* DEG2RAD (fl/ (fl* (exact->inexact j) 360.0)
                                       (exact->inexact slices))))
      (define theta1 (fl* DEG2RAD (fl/ (fl* (exact->inexact (+ j 1)) 360.0)
                                       (exact->inexact slices))))
      ;; Triangle 1
      (rl-vertex-3f (fl* (flcos phi0) (flsin theta0)) (flsin phi0) (fl* (flcos phi0) (flcos theta0)))
      (rl-vertex-3f (fl* (flcos phi1) (flsin theta1)) (flsin phi1) (fl* (flcos phi1) (flcos theta1)))
      (rl-vertex-3f (fl* (flcos phi1) (flsin theta0)) (flsin phi1) (fl* (flcos phi1) (flcos theta0)))
      ;; Triangle 2
      (rl-vertex-3f (fl* (flcos phi0) (flsin theta0)) (flsin phi0) (fl* (flcos phi0) (flcos theta0)))
      (rl-vertex-3f (fl* (flcos phi0) (flsin theta1)) (flsin phi0) (fl* (flcos phi0) (flcos theta1)))
      (rl-vertex-3f (fl* (flcos phi1) (flsin theta1)) (flsin phi1) (fl* (flcos phi1) (flcos theta1)))))
  (rl-end))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(define sun-radius 4.0)
(define earth-radius 0.6)
(define earth-orbit-radius 8.0)
(define moon-radius 0.16)
(define moon-orbit-radius 1.5)

(init-window screen-width screen-height
  "raylib [models] example - rlgl solar system")

(define camera (camera3d 16.0 16.0 16.0
                          0.0  0.0  0.0
                          0.0  1.0  0.0
                          45.0 CAMERA-PERSPECTIVE))

(define rotation-speed 0.2)
(define earth-rotation 0.0)
(define earth-orbit-rotation 0.0)
(define moon-rotation 0.0)
(define moon-orbit-rotation 0.0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (set! earth-rotation (+ earth-rotation (* 5.0 rotation-speed)))
    (set! earth-orbit-rotation (+ earth-orbit-rotation (* (/ 365.0 360.0) 5.0 rotation-speed rotation-speed)))
    (set! moon-rotation (+ moon-rotation (* 2.0 rotation-speed)))
    (set! moon-orbit-rotation (+ moon-orbit-rotation (* 8.0 rotation-speed)))

    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)

    ;; Sun
    (rl-push-matrix)
    (rl-scale-f sun-radius sun-radius sun-radius)
    (draw-sphere-basic GOLD)
    (rl-pop-matrix)

    ;; Earth + Moon system
    (rl-push-matrix)
    (rl-rotate-f earth-orbit-rotation 0.0 1.0 0.0)
    (rl-translate-f earth-orbit-radius 0.0 0.0)

    (rl-push-matrix)
    (rl-rotate-f earth-rotation 0.25 1.0 0.0)
    (rl-scale-f earth-radius earth-radius earth-radius)
    (draw-sphere-basic BLUE)
    (rl-pop-matrix)

    ;; Moon
    (rl-rotate-f moon-orbit-rotation 0.0 1.0 0.0)
    (rl-translate-f moon-orbit-radius 0.0 0.0)
    (rl-rotate-f moon-rotation 0.0 1.0 0.0)
    (rl-scale-f moon-radius moon-radius moon-radius)
    (draw-sphere-basic LIGHTGRAY)

    (rl-pop-matrix)

    ;; Orbit reference circle
    (draw-circle-3d (vector3 0.0 0.0 0.0) earth-orbit-radius
                    (vector3 1.0 0.0 0.0) 90.0 (fade RED 0.5))
    (draw-grid 20 1.0)

    (end-mode-3d)

    (draw-text "EARTH ORBITING AROUND THE SUN!" 400 10 20 MAROON)
    (draw-fps 10 10)

    (end-drawing)
    (loop)))

(close-window)
