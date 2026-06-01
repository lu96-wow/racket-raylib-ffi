#lang racket/base
;; raylib [shapes] example - splines drawing (Racket FFI 翻译)
;; 对应 C: examples/shapes/shapes_splines_drawing.c
;; 交互式样条线绘制，键盘控制替代 raygui
(require "../../raylib/raylib.rkt"
         (only-in ffi/unsafe malloc)
         racket/math)

(define MAX-SPLINE-POINTS 32)
(define SPLINE-LINEAR 0) (define SPLINE-BASIS 1)
(define SPLINE-CATMULLROM 2) (define SPLINE-BEZIER 3)

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window 800 450 "raylib [shapes] example - splines drawing")

;; 样条点
(define points
  (vector (vector2 50.0 400.0) (vector2 160.0 220.0)
          (vector2 340.0 380.0) (vector2 520.0 60.0)
          (vector2 710.0 260.0)))
(define point-count (box 5))

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

(recalc-controls! (unbox point-count))

(define selected-point      (box -1))
(define focused-point       (box -1))
(define selected-control-pt (box #f))
(define focused-control-pt  (box #f))
(define spline-thickness    (box 8.0))
(define spline-type-active  (box SPLINE-LINEAR))
(define show-helpers?       (box #t))

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

(set-target-fps 60)
;; 主循环 — 更新
(let main-loop ()
  (unless (window-should-close?)
    (define pc (unbox point-count))
    (define sp (unbox selected-point))
    (define fp (unbox focused-point))
    (define scp (unbox selected-control-pt))
    (define fcp (unbox focused-control-pt))
    (define sta (unbox spline-type-active))
    (define is-bezier? (= sta SPLINE-BEZIER))

    ;; 右键添加新点
    (when (and (is-mouse-button-pressed MOUSE-BUTTON-RIGHT) (< pc MAX-SPLINE-POINTS))
      (define new-pt (malloc _Vector2 'atomic))
      (set-v2! new-pt (mouse-x) (mouse-y))
      (vector-set! points pc new-pt)
      (when (< (sub1 pc) (sub1 MAX-SPLINE-POINTS))
        (define cs (malloc _Vector2 'atomic))
        (define ce (malloc _Vector2 'atomic))
        (set-v2! cs (+ (v2-x (vector-ref points (sub1 pc))) 50.0)
                    (v2-y (vector-ref points (sub1 pc))))
        (set-v2! ce (- (v2-x (vector-ref points pc)) 50.0)
                    (v2-y (vector-ref points pc)))
        (vector-set! control (sub1 pc) (cons cs ce)))
      (set-box! point-count (add1 pc)))

    ;; 点聚焦/选择
    (when (and (= sp -1) (or (not is-bezier?) (not scp)))
      (set-box! focused-point -1)
      (for ([i (in-range pc)])
        (when (v2-near? (vector-ref points i) (mouse-x) (mouse-y) 8.0)
          (set-box! focused-point i)
          (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
            (set-box! selected-point i)))))

    ;; 拖拽点
    (let ([sp (unbox selected-point)])
      (when (>= sp 0)
        (set-v2! (vector-ref points sp) (mouse-x) (mouse-y))
        (when (is-mouse-button-released MOUSE-BUTTON-LEFT)
          (set-box! selected-point -1))))

    ;; Bezier 控制点
    (when (and is-bezier? (= (unbox focused-point) -1))
      (let ([scp (unbox selected-control-pt)])
        (unless scp
          (set-box! focused-control-pt #f)
          (for ([i (in-range (sub1 pc))])
            (let ([cp (vector-ref control i)])
              (when cp
                (when (v2-near? (car cp) (mouse-x) (mouse-y) 6.0)
                  (set-box! focused-control-pt (car cp)))
                (when (v2-near? (cdr cp) (mouse-x) (mouse-y) 6.0)
                  (set-box! focused-control-pt (cdr cp))))))
          (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
            (set-box! selected-control-pt (unbox focused-control-pt))))
        (let ([scp (unbox selected-control-pt)])
          (when scp
            (set-v2! scp (mouse-x) (mouse-y))
            (when (is-mouse-button-released MOUSE-BUTTON-LEFT)
              (set-box! selected-control-pt #f))))))

    ;; 切换样条类型 (1-4)
    (cond
      [(is-key-pressed KEY-ONE)   (set-box! spline-type-active 0)]
      [(is-key-pressed KEY-TWO)   (set-box! spline-type-active 1)]
      [(is-key-pressed KEY-THREE) (set-box! spline-type-active 2)]
      [(is-key-pressed KEY-FOUR)  (set-box! spline-type-active 3)])
    (when (or (is-key-pressed KEY-ONE) (is-key-pressed KEY-TWO)
              (is-key-pressed KEY-THREE))
      (set-box! selected-control-pt #f))

    ;; 厚度 (Q/W)
    (when (is-key-pressed KEY-Q)
      (set-box! spline-thickness (min 40.0 (+ (unbox spline-thickness) 1.0))))
    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)
    (define thick (unbox spline-thickness))
    (define sta* (unbox spline-type-active))
    (define show? (unbox show-helpers?))

    ;; 样条
    (cond
      [(= sta* SPLINE-LINEAR) (draw-spline-linear points pc thick RED)]
      [(= sta* SPLINE-BASIS) (draw-spline-basis points pc thick RED)]
      [(= sta* SPLINE-CATMULLROM) (draw-spline-catmull-rom points pc thick RED)]
      [(= sta* SPLINE-BEZIER)
       (let ([inter (build-interleaved-points pc)])
         (draw-spline-bezier-cubic inter (add1 (* 3 (sub1 pc))) thick RED))
       (for ([i (in-range (sub1 pc))])
         (let ([cp (vector-ref control i)])
           (when cp
             (let ([cs (car cp)] [ce (cdr cp)])
               (draw-circle-v cs 6 GOLD)
               (draw-circle-v ce 6 GOLD)
               (let ([fcp (unbox focused-control-pt)])
                 (when (eq? fcp cs) (draw-circle-v cs 8 GREEN))
                 (when (eq? fcp ce) (draw-circle-v ce 8 GREEN)))
               (draw-line-ex (vector-ref points i) cs 1.0 LIGHTGRAY)
               (draw-line-ex (vector-ref points (add1 i)) ce 1.0 LIGHTGRAY)
               (draw-line-v (vector-ref points i) cs GRAY)
               (draw-line-v ce (vector-ref points (add1 i)) GRAY)))))])

    ;; 辅助点
    (when show?
      (for ([i (in-range pc)])
        (let ([p (vector-ref points i)]
              [r (if (= fp i) 12.0 8.0)]
              [c (if (= fp i) BLUE DARKBLUE)])
          (draw-circle-lines-v p r c)
          (when (and (not (= sta* SPLINE-LINEAR))
                     (not (= sta* SPLINE-BEZIER))
                     (< i (sub1 pc)))
            (draw-line-v p (vector-ref points (add1 i)) GRAY))
          (draw-text (format "[~a,~a]" (fmt (v2-x p) 0) (fmt (v2-y p) 0))
                     (exact-round (v2-x p)) (+ (exact-round (v2-y p)) 10) 10 BLACK))))

    ;; UI
    (draw-text (format "~a [1-4]" (vector-ref #("LINEAR" "B-SPLINE" "CATMULL-ROM" "BEZIER") sta*)) 12 10 12 DARKGRAY)
    (draw-text (format "Thickness [Q/W]: ~a" (fmt thick 0)) 12 40 10 DARKGRAY)
    (draw-text (format "Helpers [E]: ~a" (if show? "ON" "OFF")) 12 60 10 DARKGRAY)
    (draw-text (format "Points: ~a/32" pc) 12 90 10 DARKGRAY)
    (draw-text "R-click: add  L-click: drag" 12 120 10 DARKGRAY)
    (draw-fps 10 (- (get-screen-height) 30))
    (end-drawing)
    (main-loop)))

(close-window)

    (when (is-key-pressed KEY-W)
      (set-box! spline-thickness (max 1.0 (- (unbox spline-thickness) 1.0))))
    ;; 辅助切换 (E)
    (when (is-key-pressed KEY-E)
      (set-box! show-helpers? (not (unbox show-helpers?))))

