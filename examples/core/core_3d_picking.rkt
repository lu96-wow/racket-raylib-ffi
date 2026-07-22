#lang racket/base

;; raylib [core] example - 3d picking (Racket FFI 翻译)

(require "../../raylib/raylib.rkt"
         ffi/unsafe)

(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 450)

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - 3d picking")

(define camera
  (camera3d 10.0 10.0 10.0 0.0 0.0 0.0 0.0 1.0 0.0 45.0 CAMERA-PERSPECTIVE))
(define cube-pos (vector3 0.0 1.0 0.0))
(define cube-size (vector3 2.0 2.0 2.0))
(define-var ray #f)
(define-var collision #f)
(define-var cam-mode CAMERA-FIRST-PERSON)
(set-target-fps 60)

(define (make-bb cx cy cz sx sy sz)
  (let ([bb (malloc _BoundingBox 'atomic)])
    (ptr-set! bb _float 0 (- cx (/ sx 2)))
    (ptr-set! bb _float 1 (- cy (/ sy 2)))
    (ptr-set! bb _float 2 (- cz (/ sz 2)))
    (ptr-set! bb _float 3 (+ cx (/ sx 2)))
    (ptr-set! bb _float 4 (+ cy (/ sy 2)))
    (ptr-set! bb _float 5 (+ cz (/ sz 2)))
    bb))

(let loop ()
  (unless (window-should-close?)
    (when (is-cursor-hidden?)
      (update-camera camera (unbox cam-mode)))
    (when (is-mouse-button-pressed MOUSE-BUTTON-RIGHT)
      (if (is-cursor-hidden?) (enable-cursor) (disable-cursor)))
    (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
      (if (and (unbox collision) (car (unbox collision)))
        (set-box! collision #f)
        (let* ([mp (get-mouse-position)]
               [nr (get-screen-to-world-ray mp camera)]
               [bb (make-bb (vector3-x cube-pos) (vector3-y cube-pos)
                            (vector3-z cube-pos)
                            (vector3-x cube-size) (vector3-y cube-size)
                            (vector3-z cube-size))]
               [nc (get-ray-collision-box nr bb)])
          (set-box! ray nr)
          (set-box! collision nc))))

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (if (and (unbox collision) (car (unbox collision)))
      (begin
        (draw-cube cube-pos 2.0 2.0 2.0 RED)
        (draw-cube-wires cube-pos 2.0 2.0 2.0 MAROON)
        (draw-cube-wires cube-pos 2.2 2.2 2.2 GREEN))
      (begin
        (draw-cube cube-pos 2.0 2.0 2.0 GRAY)
        (draw-cube-wires cube-pos 2.0 2.0 2.0 DARKGRAY)))
    (when (unbox ray) (draw-ray (unbox ray) MAROON))
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text "Try clicking on the box with your mouse!" 240 10 20 DARKGRAY)
    (when (and (unbox collision) (car (unbox collision)))
      (draw-text "BOX SELECTED"
        (quotient (- SCREEN-WIDTH (measure-text "BOX SELECTED" 30)) 2)
        (inexact->exact (floor (* SCREEN-HEIGHT 0.1))) 30 GREEN))
    (draw-text "Right click mouse to toggle camera controls" 10 430 10 GRAY)
    (draw-fps 10 10)
    (end-drawing)
    (loop)))

(close-window)
