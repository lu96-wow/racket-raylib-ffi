#lang racket/base

;; raylib [shapes] example - basic shapes (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_basic_shapes.c

(require "../../raylib/raylib.rkt")

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - basic shapes")

(set-target-fps 60)

(let loop ([rotation 0.0])
  (unless (window-should-close?)
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-text "some basic shapes available on raylib" 20 20 20 DARKGRAY)

    ;; Circle shapes and lines
    (draw-circle (quotient screen-width 5) 120 35.0 DARKBLUE)
    (draw-circle-gradient (vector2 (/ screen-width 5.0) 220.0) 60.0 GREEN SKYBLUE)
    (draw-circle-lines (quotient screen-width 5) 340 80.0 DARKBLUE)
    (draw-ellipse (quotient screen-width 5) 120 25.0 20.0 YELLOW)
    (draw-ellipse-lines (quotient screen-width 5) 120 30.0 25.0 YELLOW)

    ;; Rectangle shapes and lines
    (draw-rectangle (- (* (quotient screen-width 4) 2) 60) 100 120 60 RED)
    (draw-rectangle-gradient-h (- (* (quotient screen-width 4) 2) 90) 170 180 130 MAROON GOLD)
    (draw-rectangle-lines (- (* (quotient screen-width 4) 2) 40) 320 80 60 ORANGE)

    ;; Triangle shapes and lines
    (draw-triangle (vector2 (* (/ screen-width 4.0) 3.0) 80.0)
                   (vector2 (- (* (/ screen-width 4.0) 3.0) 60.0) 150.0)
                   (vector2 (+ (* (/ screen-width 4.0) 3.0) 60.0) 150.0)
                   VIOLET)
    (draw-triangle-lines (vector2 (* (/ screen-width 4.0) 3.0) 160.0)
                         (vector2 (- (* (/ screen-width 4.0) 3.0) 20.0) 230.0)
                         (vector2 (+ (* (/ screen-width 4.0) 3.0) 20.0) 230.0)
                         DARKBLUE)

    ;; Polygon shapes and lines
    (draw-poly (vector2 (* (/ screen-width 4.0) 3) 330) 6 80.0 rotation BROWN)
    (draw-poly-lines (vector2 (* (/ screen-width 4.0) 3) 330) 6 90.0 rotation BROWN)
    (draw-poly-lines-ex (vector2 (* (/ screen-width 4.0) 3) 330) 6 85.0 rotation 6.0 BEIGE)

    (draw-line 18 42 (- screen-width 18) 42 BLACK)
    (end-drawing)
    (loop (+ rotation 0.2))))

(close-window)
