#lang racket/base
;; raylib [shapes] example - triangle strip (Racket FFI 翻译)
;; 键盘控制替代 raygui: Q/W 增减段数, E 切换边框
(require "../../raylib/raylib.rkt" (only-in ffi/unsafe malloc) racket/math)

(define screen-w 800) (define screen-h 450)
(init-window screen-w screen-h "raylib [shapes] example - triangle strip")
(set-target-fps 60)

(define center (vector2 (- (/ screen-w 2) 125.0) (/ screen-h 2)))
(define segments (box 6.0))
(define inside-radius  100.0)
(define (fmt v d) (real->decimal-string v d))
(define (color r g b a)
  (let ([c (malloc _Color 'atomic)])
    (ptr-set! c _ubyte 0 r) (ptr-set! c _ubyte 1 g)
    (ptr-set! c _ubyte 2 b) (ptr-set! c _ubyte 3 a)
    c))
(define outside-radius 150.0)
(define outline (box #t))
(define RAD2DEG (/ 180.0 pi))
(define points (make-vector 122))

(let main-loop ()
  (unless (window-should-close?)
    ;; 键盘控制
    (when (is-key-pressed KEY-Q) (set-box! segments (min 60.0 (+ (unbox segments) 1.0))))
    (when (is-key-pressed KEY-W) (set-box! segments (max 6.0  (- (unbox segments) 1.0))))
    (when (is-key-pressed KEY-E) (set-box! outline (not (unbox outline))))

    (define n (exact-round (unbox segments)))
    (define angle-step (/ (* 2.0 pi) n))
    (define cx (ptr-ref center _float 0))
    (define cy (ptr-ref center _float 1))

    ;; 计算点
    (for ([i (in-range n)])
      (define a1 (* i angle-step))
      (define a2 (+ a1 (/ angle-step 2.0)))
      (define p-in  (vector2 (+ cx (* (cos a1) inside-radius))
                             (+ cy (* (sin a1) inside-radius))))
      (define p-out (vector2 (+ cx (* (cos a2) outside-radius))
                             (+ cy (* (sin a2) outside-radius))))
      (vector-set! points (* 2 i) p-in)
      (vector-set! points (add1 (* 2 i)) p-out))
    ;; 闭合
    (vector-set! points (* 2 n) (vector-ref points 0))
    (vector-set! points (add1 (* 2 n)) (vector-ref points 1))

    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 绘制三角形条带
    (for ([i (in-range n)])
      (define a (vector-ref points (* 2 i)))
      (define b (vector-ref points (add1 (* 2 i))))
      (define c (vector-ref points (+ (* 2 i) 2)))
      (define d (vector-ref points (+ (* 2 i) 3)))
      (define angle1 (* i angle-step))
      (define col1 (color-from-hsv (exact->inexact (* angle1 RAD2DEG)) 1.0 1.0))
      (define col2 (color-from-hsv (exact->inexact (* (+ angle1 (/ angle-step 2)) RAD2DEG)) 1.0 1.0))
      (draw-triangle c b a col1)
      (draw-triangle d b c col2)
      (when (unbox outline)
        (draw-triangle-lines a b c BLACK)
        (draw-triangle-lines c b d BLACK)))

    ;; 控制面板
    (draw-line 580 0 580 screen-h (color 218 218 218 255))
    (draw-rectangle 580 0 (- screen-w 580) screen-h (color 232 232 232 255))
    (draw-text (format "Segments [Q/W]: ~a" (fmt (unbox segments) 0))
               600 40 10 DARKGRAY)
    (draw-text (format "Outline [E]: ~a" (if (unbox outline) "ON" "OFF"))
               600 70 10 DARKGRAY)
    (draw-fps 10 10)
    (end-drawing)
    (main-loop)))

(close-window)
