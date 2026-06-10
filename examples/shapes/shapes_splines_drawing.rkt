#lang racket/base
;; raylib [shapes] example - splines drawing (Racket FFI 翻译)
;; 对应 C: examples/shapes/shapes_splines_drawing.c
;; 交互式样条线绘制，滑块控制替代 raygui (参照 ring_drawing.rkt)
(require "../../raylib/raylib.rkt"
         racket/match
         racket/math
         (only-in ffi/unsafe malloc))

(define MAX-SPLINE-POINTS 32)
(define SPLINE-LINEAR 0) (define SPLINE-BASIS 1)
(define SPLINE-CATMULLROM 2) (define SPLINE-BEZIER 3)

;; ============================================================
;; 滑块控件 (浮点版本)
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

;; ============================================================
;; 复选框控件
;; ============================================================
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

;; ============================================================
;; 样条类型选择器 (点击切换，高亮当前选中项)
;; ============================================================
(define TYPE-LABELS #("LINEAR" "B-SPLINE" "CATMULL-ROM" "BEZIER"))

(define (draw-type-selector x y active-type)
  (draw-text "Spline type:" x y 10 DARKGRAY)
  (define mx (get-mouse-x)) (define my (get-mouse-y))
  (define mclicked (is-mouse-button-pressed MOUSE-BUTTON-LEFT))
  (define new-active active-type)
  (for ([i (in-range 4)])
    (define ty (+ y 22 (* i 20)))
    (define txt (vector-ref TYPE-LABELS i))
    (define color (if (= i active-type) MAROON DARKGRAY))
    (when (and mclicked (>= mx x) (<= mx (+ x 130))
               (>= my ty) (<= my (+ ty 16)))
      (set! new-active i))
    (draw-text txt x ty 10 color))
  new-active)

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window 800 450 "raylib [shapes] example - splines drawing")

;; 样条点
(define points
  (vector (vector2 50.0 400.0) (vector2 160.0 220.0)
          (vector2 340.0 380.0) (vector2 520.0 60.0)
          (vector2 710.0 260.0)))
(define point-count 5)

;; Bezier 控制点: vector of (start . end) cons pairs
(define control
  (let ([v (make-vector (sub1 MAX-SPLINE-POINTS) #f)])
    (for ([i (in-range (min 4 (sub1 MAX-SPLINE-POINTS)))])
      (vector-set! v i (cons (malloc _Vector2 'atomic)
                             (malloc _Vector2 'atomic))))
    v))

(define (recalc-controls! n)
  (for ([i (in-range (sub1 n))])
    (let ([cp (vector-ref control i)])
      (when cp
        (let* ([p (vector-ref points i)]
               [pn (vector-ref points (add1 i))]
               [cs (car cp)] [ce (cdr cp)])
          (ptr-set! cs _float 0 (+ (ptr-ref p _float 0) 50.0))
          (ptr-set! cs _float 1 (ptr-ref p _float 1))
          (ptr-set! ce _float 0 (- (ptr-ref pn _float 0) 50.0))
          (ptr-set! ce _float 1 (ptr-ref pn _float 1)))))))

(recalc-controls! point-count)

(define selected-point      -1)
(define focused-point       -1)
(define selected-control-pt #f)
(define focused-control-pt  #f)
(define spline-thickness    8.0)
(define spline-type-active  SPLINE-LINEAR)
(define show-helpers?       #t)

(define (mouse-x) (get-mouse-x))
(define (mouse-y) (get-mouse-y))
(define (v2-x v) (ptr-ref v _float 0))
(define (v2-y v) (ptr-ref v _float 1))
(define (set-v2! v x y)
  (ptr-set! v _float 0 (exact->inexact x))
  (ptr-set! v _float 1 (exact->inexact y)))
(define (v2-dist v x y) (sqrt (+ (sqr (- (v2-x v) x)) (sqr (- (v2-y v) y)))))
(define (v2-near? v x y r) (<= (v2-dist v x y) r))
(define (fmt v d) (real->decimal-string v d))

(define (build-interleaved-points n)
  (define total (* 3 (sub1 n)))
  (define result (make-vector (add1 total)))
  (for ([i (in-range (sub1 n))])
    (vector-set! result (* 3 i) (vector-ref points i))
    (let ([cp (vector-ref control i)])
      (when cp
        (vector-set! result (+ (* 3 i) 1) (car cp))
        (vector-set! result (+ (* 3 i) 2) (cdr cp)))))
  (vector-set! result total (vector-ref points (sub1 n)))
  result)

;; 滑块: x=12, w=120, h=16, 范围 1-40
(define sl-thickness (make-slider 12 142 120 16 1.0 40.0 8.0 "Thickness"))

(set-target-fps 60)
;; 主循环 — 更新
(let loop ()
  (unless (window-should-close?)
    (define is-bezier? (= spline-type-active SPLINE-BEZIER))
    (define dragging? (or (>= selected-point 0) selected-control-pt))

    ;; ---- 右键添加新点 ----
    (when (and (is-mouse-button-pressed MOUSE-BUTTON-RIGHT)
               (< point-count MAX-SPLINE-POINTS))
      (define new-pt (malloc _Vector2 'atomic))
      (set-v2! new-pt (mouse-x) (mouse-y))
      (vector-set! points point-count new-pt)
      (when (< (sub1 point-count) (sub1 MAX-SPLINE-POINTS))
        (define cs (malloc _Vector2 'atomic))
        (define ce (malloc _Vector2 'atomic))
        (set-v2! cs (+ (v2-x (vector-ref points (sub1 point-count))) 50.0)
                    (v2-y (vector-ref points (sub1 point-count))))
        (set-v2! ce (- (v2-x (vector-ref points point-count)) 50.0)
                    (v2-y (vector-ref points point-count)))
        (vector-set! control (sub1 point-count) (cons cs ce)))
      (set! point-count (add1 point-count)))

    ;; ---- 点聚焦/选择 ----
    (when (and (= selected-point -1)
               (or (not is-bezier?) (not selected-control-pt)))
      (set! focused-point -1)
      (for ([i (in-range point-count)])
        (when (v2-near? (vector-ref points i) (mouse-x) (mouse-y) 8.0)
          (set! focused-point i)
          (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
            (set! selected-point i)))))

    ;; ---- 拖拽点 ----
    (when (>= selected-point 0)
      (set-v2! (vector-ref points selected-point) (mouse-x) (mouse-y))
      (when (is-mouse-button-released MOUSE-BUTTON-LEFT)
        (set! selected-point -1)))

    ;; ---- Bezier 控制点 ----
    (when (and is-bezier? (= focused-point -1))
      (unless selected-control-pt
        (set! focused-control-pt #f)
        (for ([i (in-range (sub1 point-count))])
          (let ([cp (vector-ref control i)])
            (when cp
              (when (v2-near? (car cp) (mouse-x) (mouse-y) 6.0)
                (set! focused-control-pt (car cp)))
              (when (v2-near? (cdr cp) (mouse-x) (mouse-y) 6.0)
                (set! focused-control-pt (cdr cp))))))
        (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
          (set! selected-control-pt focused-control-pt)))
      (when selected-control-pt
        (set-v2! selected-control-pt (mouse-x) (mouse-y))
        (when (is-mouse-button-released MOUSE-BUTTON-LEFT)
          (set! selected-control-pt #f))))

    ;; ---- 滑块 / 复选框 (仅当未拖拽点时) ----
    (unless dragging?
      (update-slider sl-thickness)
      (set! spline-thickness (slider-val sl-thickness)))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 样条
    (cond
      [(= spline-type-active SPLINE-LINEAR)
       (draw-spline-linear points point-count spline-thickness RED)]
      [(= spline-type-active SPLINE-BASIS)
       (draw-spline-basis points point-count spline-thickness RED)]
      [(= spline-type-active SPLINE-CATMULLROM)
       (draw-spline-catmull-rom points point-count spline-thickness RED)]
      [(= spline-type-active SPLINE-BEZIER)
       (let ([inter (build-interleaved-points point-count)])
         (draw-spline-bezier-cubic inter (add1 (* 3 (sub1 point-count)))
                                   spline-thickness RED))
       (for ([i (in-range (sub1 point-count))])
         (let ([cp (vector-ref control i)])
           (when cp
             (let ([cs (car cp)] [ce (cdr cp)])
               (draw-circle-v cs 6 GOLD)
               (draw-circle-v ce 6 GOLD)
               (when (eq? focused-control-pt cs) (draw-circle-v cs 8 GREEN))
               (when (eq? focused-control-pt ce) (draw-circle-v ce 8 GREEN))
               (draw-line-ex (vector-ref points i) cs 1.0 LIGHTGRAY)
               (draw-line-ex (vector-ref points (add1 i)) ce 1.0 LIGHTGRAY)
               (draw-line-v (vector-ref points i) cs GRAY)
               (draw-line-v ce (vector-ref points (add1 i)) GRAY)))))])

    ;; 辅助点
    (when show-helpers?
      (for ([i (in-range point-count)])
        (let ([p (vector-ref points i)]
              [r (if (= focused-point i) 12.0 8.0)]
              [c (if (= focused-point i) BLUE DARKBLUE)])
          (draw-circle-lines-v p r c)
          (when (and (not (= spline-type-active SPLINE-LINEAR))
                     (not (= spline-type-active SPLINE-BEZIER))
                     (< i (sub1 point-count)))
            (draw-line-v p (vector-ref points (add1 i)) GRAY))
          (draw-text (format "[~a,~a]" (fmt (v2-x p) 0) (fmt (v2-y p) 0))
                     (exact-round (v2-x p)) (+ (exact-round (v2-y p)) 10) 10 BLACK))))

    ;; ---- UI 控件 ----
    ;; 类型选择器
    (define old-type spline-type-active)
    (set! spline-type-active
      (draw-type-selector 12 10 spline-type-active))
    (when (not (= spline-type-active old-type))
      (when (not (= spline-type-active SPLINE-BEZIER))
        (set! selected-control-pt #f)))

    ;; 厚度滑块
    (draw-text "Spline thickness:" 12 130 10 DARKGRAY)
    (draw-slider sl-thickness)

    ;; 复选框
    (unless dragging?
      (set! show-helpers?
        (draw-checkbox 12 170 "Show point helpers" show-helpers?)))

    ;; 信息
    (draw-text (format "Points: ~a/32" point-count) 12 200 10 DARKGRAY)
    (draw-text "R-click: add  L-click: drag" 12 220 10 DARKGRAY)

    (draw-fps 10 (- (get-screen-height) 30))
    (end-drawing)
    (loop)))

(close-window)

