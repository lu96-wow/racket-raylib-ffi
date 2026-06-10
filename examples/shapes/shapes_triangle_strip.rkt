#lang racket/base
;; raylib [shapes] example - triangle strip (Racket FFI 翻译)
;; 滑块控制替代 raygui (参照 ring_drawing.rkt)
(require "../../raylib/raylib.rkt"
         racket/match
         racket/math
         (only-in ffi/unsafe malloc))

(define screen-w 800) (define screen-h 450)
(init-window screen-w screen-h "raylib [shapes] example - triangle strip")

;; ============================================================
;; 滑块 + 复选框控件
;; ============================================================
(define (make-slider x y w h vmin vmax init label)
  (box (list x y w h vmin vmax init #f label)))
(define SLIDER-HANDLE-W 12)

(define (update-slider sl-box)
  (match-define (list x y w h vmin vmax cur drag? label) (unbox sl-box))
  (define mx (get-mouse-x)) (define my (get-mouse-y))
  (define mdown (is-mouse-button-down MOUSE-BUTTON-LEFT))
  (define mreleased (is-mouse-button-released MOUSE-BUTTON-LEFT))
  (define in-rect (and (>= mx (- x 2)) (<= mx (+ x w 2))
                       (>= my (- y 2)) (<= my (+ y h 2))))
  (define new-drag?
    (cond [mreleased #f] [(and mdown in-rect (not drag?)) #t]
          [drag? (if mdown #t #f)] [else #f]))
  (define new-val
    (if new-drag?
        (let* ([t (max 0.0 (min 1.0 (/ (- mx x) w)))]
               [v (+ vmin (* t (- vmax vmin)))]) v)
        cur))
  (set-box! sl-box (list x y w h vmin vmax new-val new-drag? label)))

(define (draw-slider sl-box)
  (match-define (list x y w h vmin vmax cur drag? label) (unbox sl-box))
  (define range (- vmax vmin))
  (define t (if (zero? range) 0.0 (/ (- cur vmin) range)))
  (define handle-x (+ x (exact-round (* w t))))
  (define track-y (+ y (quotient h 2) -2))
  (draw-rectangle x track-y w 4 (fade GRAY 0.3))
  (draw-rectangle (- handle-x (quotient SLIDER-HANDLE-W 2)) y
                  SLIDER-HANDLE-W h (if drag? MAROON (fade DARKGRAY 0.7)))
  (draw-text (real->decimal-string cur 0) (+ x w 8) (- (+ y (quotient h 2)) 5) 10 DARKGRAY))

(define (slider-val sl-box)
  (cadddr (cdddr (unbox sl-box))))

(define BOX-SIZE 16)
(define (draw-checkbox x y label-text checked?)
  (define mx (get-mouse-x)) (define my (get-mouse-y))
  (define mclicked (is-mouse-button-pressed MOUSE-BUTTON-LEFT))
  (define new-val
    (if (and mclicked (>= mx x) (<= mx (+ x BOX-SIZE 100))
             (>= my y) (<= my (+ y BOX-SIZE)))
        (not checked?) checked?))
  (draw-rectangle-lines x y BOX-SIZE BOX-SIZE DARKGRAY)
  (when new-val
    (draw-rectangle (+ x 3) (+ y 3) (- BOX-SIZE 6) (- BOX-SIZE 6) MAROON))
  (draw-text label-text (+ x 22) (- (+ y (quotient BOX-SIZE 2)) 5) 10 DARKGRAY)
  new-val)

(set-target-fps 60)

(define center (vector2 (- (/ screen-w 2) 125.0) (/ screen-h 2)))
(define segments 6.0)
(define inside-radius  100.0)
(define (color r g b a)
  (let ([c (malloc _Color 'atomic)])
    (ptr-set! c _ubyte 0 r) (ptr-set! c _ubyte 1 g)
    (ptr-set! c _ubyte 2 b) (ptr-set! c _ubyte 3 a)
    c))
(define outside-radius 150.0)
(define outline #t)
(define RAD2DEG (/ 180.0 pi))
(define points (make-vector 122))

;; 滑块: Segments 6-60
(define sl-segments (make-slider 600 42 120 16 6.0 60.0 6.0 "Segments"))

(let loop ()
  (unless (window-should-close?)
    ;; 更新滑块
    (update-slider sl-segments)
    (set! segments (slider-val sl-segments))

    (define n (exact-round segments))
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
      (when outline
        (draw-triangle-lines a b c BLACK)
        (draw-triangle-lines c b d BLACK)))

    ;; 控制面板
    (draw-line 580 0 580 screen-h (color 218 218 218 255))
    (draw-rectangle 580 0 (- screen-w 580) screen-h (color 232 232 232 255))

    ;; 标签
    (draw-text "Segments" 600 30 10 DARKGRAY)
    ;; 滑块
    (draw-slider sl-segments)
    ;; 复选框
    (set! outline
      (draw-checkbox 600 70 "Outline" outline))

    (draw-fps 10 10)
    (end-drawing)
    (loop)))

(close-window)
