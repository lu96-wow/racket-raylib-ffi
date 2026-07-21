#lang racket/base
(require "../../raylib/raylib.rkt")

(define screen-width 800)
(define screen-height 450)
(init-window screen-width screen-height "raylib [core] example - 3d camera free (WASD)")

(define camera
  (camera3d 10.0 10.0 10.0  0.0 0.0 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))
(define cube-position (vector3 0.0 0.0 0.0))
(define move-speed 0.3)
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    ;; WASD 移动 — 用分组访问器 + raymath
    (let* ([forward (vec3-subtract (camera3d-target camera) (camera3d-position camera))]
           [right   (vec3-cross-product forward (camera3d-up camera))]
           [up      (vec3-cross-product right forward)])
      (when (is-key-down KEY-W)
        (set-camera3d-position! camera
          (vec3-add (camera3d-position camera)
                    (vec3-scale (vec3-normalize forward) move-speed))))
      (when (is-key-down KEY-S)
        (set-camera3d-position! camera
          (vec3-add (camera3d-position camera)
                    (vec3-scale (vec3-normalize forward) (- move-speed)))))
      (when (is-key-down KEY-A)
        (set-camera3d-position! camera
          (vec3-add (camera3d-position camera)
                    (vec3-scale (vec3-normalize right) (- move-speed)))))
      (when (is-key-down KEY-D)
        (set-camera3d-position! camera
          (vec3-add (camera3d-position camera)
                    (vec3-scale (vec3-normalize right) move-speed))))
      (when (is-key-down KEY-Q)
        (set-camera3d-position! camera
          (vec3-add (camera3d-position camera)
                    (vec3-scale (vec3-normalize up) (- move-speed)))))
      (when (is-key-down KEY-E)
        (set-camera3d-position! camera
          (vec3-add (camera3d-position camera)
                    (vec3-scale (vec3-normalize up) move-speed)))))

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (draw-cube cube-position 2.0 2.0 2.0 RED)
    (draw-cube-wires cube-position 2.0 2.0 2.0 MAROON)
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text "WASD: move, Q/E: up/down" 10 10 20 DARKGRAY)
    (draw-fps 10 40)
    (end-drawing)
    (loop)))

(close-window)
