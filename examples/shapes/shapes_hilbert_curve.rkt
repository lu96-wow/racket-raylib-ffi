#lang racket/base
;; raylib [shapes] example - hilbert curve (Racket FFI 翻译)
;; 滑块控制替代 raygui (参照 ring_drawing.rkt)
(require "../../raylib/raylib.rkt"
         racket/match
         racket/math)

(define screen-w 800) (define screen-h 450)
(init-window screen-w screen-h "raylib [shapes] example - hilbert curve")

;; ============================================================
;; 滑块 + 复选框
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
               [v (+ vmin (* t (- vmax vmin)))]) v) cur))
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
  (draw-text (real->decimal-string cur (if (< (- vmax vmin) 2) 2 0))
              (+ x w 8) (- (+ y (quotient h 2)) 5) 10 DARKGRAY))

(define (slider-val sl-box) (cadddr (cdddr (unbox sl-box))))

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

;; ============================================================
;; Hilbert 曲线计算 (纯 Racket)
;; ============================================================
(define HILBERT-BASE (vector (vector2 0 0) (vector2 0 1)
                             (vector2 1 1) (vector2 1 0)))

(define (compute-hilbert-step order index)
  (define hi (bitwise-and index 3))
  (define v (vector-ref HILBERT-BASE hi))
  (define x (ptr-ref v _float 0))
  (define y (ptr-ref v _float 1))
  (let loop ([j 1] [idx (arithmetic-shift index -2)] [vx x] [vy y])
    (if (>= j order)
        (vector2 vx vy)
        (let* ([hi2 (bitwise-and idx 3)]
               [len (arithmetic-shift 1 j)])
          (match hi2
            [0 (loop (add1 j) (arithmetic-shift idx -2) vy vx)]
            [2 (loop (add1 j) (arithmetic-shift idx -2) (+ vx len) (+ vy len))]
            [1 (loop (add1 j) (arithmetic-shift idx -2) vx (+ vy len))]
            [3 (loop (add1 j) (arithmetic-shift idx -2)
                     (- (* 2 len) 1 vy) (- len 1 vx))])))))

(define (build-hilbert-path order size)
  (define N (arithmetic-shift 1 order))
  (define len (/ size N))
  (define count (* N N))
  (define path (make-vector count))
  (for ([i (in-range count)])
    (define pt (compute-hilbert-step order i))
    (vector-set! path i
      (vector2 (+ (* (ptr-ref pt _float 0) len) (/ len 2.0))
               (+ (* (ptr-ref pt _float 1) len) (/ len 2.0)))))
  (cons count path))

;; ============================================================
;; 状态
;; ============================================================
(define order 2)
(define size (exact->inexact screen-h))
(define thick 2.0)
(define animate #t)

(define path-data (build-hilbert-path order size))
(define stroke-count (car path-data))
(define hilbert-path (cdr path-data))
(define counter 0)

(define prev-order order)
(define prev-size (exact-round size))

;; 滑块
(define sl-order (make-slider 585 102 150 16 2.0 8.0 2.0 ""))
(define sl-thick (make-slider 524 152 200 16 1.0 10.0 2.0 ""))
(define sl-size  (make-slider 524 192 200 16 10.0 (* screen-h 1.5) screen-h ""))

;; ============================================================
;; 主循环
;; ============================================================
(let loop ()
  (unless (window-should-close?)
    ;; ---- 更新滑块 ----
    (update-slider sl-order)
    (define new-order (exact-round (slider-val sl-order)))
    (set! new-order (max 2 (min 8 new-order)))
    (update-slider sl-thick)
    (set! thick (slider-val sl-thick))
    (update-slider sl-size)
    (set! size (slider-val sl-size))

    ;; 重建 Hilbert 路径 (当 order 或 size 变化时)
    (when (or (not (= new-order prev-order))
              (not (= (exact-round size) prev-size)))
      (set! order new-order)
      (set! prev-order order)
      (set! prev-size (exact-round size))
      (set! path-data (build-hilbert-path order size))
      (set! stroke-count (car path-data))
      (set! hilbert-path (cdr path-data))
      (set! counter (if animate 0 stroke-count)))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; Hilbert 曲线 (动画 + HSV 渐变色)
    (when (> stroke-count 0)
      (define limit (min counter (sub1 stroke-count)))
      (for ([i (in-range 1 (add1 limit))])
        (define a (vector-ref hilbert-path i))
        (define b (vector-ref hilbert-path (sub1 i)))
        (define hue (* (/ i stroke-count) 360.0))
        (draw-line-ex a b thick (color-from-hsv hue 1.0 1.0)))
      (when (< counter stroke-count)
        (set! counter (add1 counter))))

    ;; ---- UI 控件 ----
    ;; Animate 复选框
    (set! animate
      (draw-checkbox 450 50 "ANIMATE GENERATION ON CHANGE" animate))

    ;; Order 滑块
    (draw-text "HILBERT CURVE ORDER:" 585 90 10 DARKGRAY)
    (draw-slider sl-order)

    ;; Thickness 滑块
    (draw-text "THICKNESS:" 524 140 10 DARKGRAY)
    (draw-slider sl-thick)

    ;; Size 滑块
    (draw-text "TOTAL SIZE:" 524 180 10 DARKGRAY)
    (draw-slider sl-size)

    (draw-fps 10 10)
    (end-drawing)
    (loop)))

(close-window)