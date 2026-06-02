#lang racket/base
;; raylib [shapes] example - mouse trail (Racket FFI 翻译)
(require "../../raylib/raylib.rkt")

(define MAX-TRAIL 30)
(init-window 800 450 "raylib [shapes] example - mouse trail")
(set-target-fps 60)

(define trail (make-vector MAX-TRAIL (vector2 0.0 0.0)))

(let main-loop ()
  (unless (window-should-close?)
    (define mp (get-mouse-position))
    ;; 移位
    (for ([i (in-range (sub1 MAX-TRAIL) 0 -1)])
      (vector-set! trail i (vector-ref trail (sub1 i))))
    (vector-set! trail 0 mp)

    (begin-drawing)
    (clear-background BLACK)

    (for ([i (in-range MAX-TRAIL)])
      (define pos (vector-ref trail i))
      (when (and pos (not (and (= (ptr-ref pos _float 0) 0.0)
                               (= (ptr-ref pos _float 1) 0.0))))
        (define ratio (/ (exact->inexact (- MAX-TRAIL i)) MAX-TRAIL))
        (define col (fade SKYBLUE (+ (* ratio 0.5) 0.5)))
        (draw-circle-v pos (* 15.0 ratio) col)))

    (draw-text "Move the mouse to see the trail effect!" 10 (- (get-screen-height) 30) 20 LIGHTGRAY)
    (end-drawing)
    (main-loop)))

(close-window)
