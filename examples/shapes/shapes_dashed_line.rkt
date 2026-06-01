#lang racket/base
;; raylib [shapes] example - dashed line (Racket FFI 翻译)
;; UP/DOWN 虚线长度，LEFT/RIGHT 空白长度，C 切换颜色
(require "../../raylib/raylib.rkt" racket/math)

(init-window 800 450 "raylib [shapes] example - dashed line")
(set-target-fps 60)

(define start-pos (vector2 20.0 50.0))
(define end-pos (vector2 780.0 400.0))  ;; 将被鼠标覆盖

(define dash-length   (box 25.0))
(define blank-length  (box 15.0))
(define color-index   (box 0))
(define colors (vector RED ORANGE GOLD GREEN BLUE VIOLET PINK BLACK))

(let main-loop ()
  (unless (window-should-close?)
    (ptr-set! end-pos _float 0 (exact->inexact (get-mouse-x)))
    (ptr-set! end-pos _float 1 (exact->inexact (get-mouse-y)))

    (when (is-key-down KEY-UP)    (set-box! dash-length  (+ (unbox dash-length) 1.0)))
    (when (and (is-key-down KEY-DOWN) (> (unbox dash-length) 1.0))
      (set-box! dash-length (- (unbox dash-length) 1.0)))
    (when (is-key-down KEY-RIGHT) (set-box! blank-length (+ (unbox blank-length) 1.0)))
    (when (and (is-key-down KEY-LEFT) (> (unbox blank-length) 1.0))
      (set-box! blank-length (- (unbox blank-length) 1.0)))
    (when (is-key-pressed KEY-C)
      (set-box! color-index (modulo (add1 (unbox color-index)) 8)))

    (begin-drawing)
    (clear-background RAYWHITE)
    (draw-line-dashed start-pos end-pos (exact-round (unbox dash-length))
                      (exact-round (unbox blank-length))
                      (vector-ref colors (unbox color-index)))

    ;; UI
    (draw-rectangle 5 5 265 95 (fade SKYBLUE 0.5))
    (draw-rectangle-lines 5 5 265 95 BLUE)
    (draw-text "CONTROLS:" 15 15 10 BLACK)
    (draw-text "UP/DOWN: Change Dash Length" 15 35 10 BLACK)
    (draw-text "LEFT/RIGHT: Change Space Length" 15 55 10 BLACK)
    (draw-text "C: Cycle Color" 15 75 10 BLACK)
    (draw-text (format "Dash: ~a | Space: ~a" (unbox dash-length) (unbox blank-length))
               15 115 10 DARKGRAY)
    (draw-fps (- (get-screen-width) 80) 10)
    (end-drawing)
    (main-loop)))

(close-window)
