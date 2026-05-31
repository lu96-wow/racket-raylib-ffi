#lang racket/base

;; raylib [shapes] example - easings box (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_easings_box.c
;; reasings.h 用纯 Racket 实现

(require "../../raylib/raylib.rkt"
         racket/math)

;; ============================================================
;; Easing 函数 — 纯 Racket 实现
;; ============================================================

(define (ease-elastic-out t b c d)
  (cond
    [(= t 0.0) b]
    [else
     (let* ([t2 (/ t d)]
            [t2 (if (= t2 1.0) 1.0 t2)])
       (if (= t2 1.0) (+ b c)
           (let* ([p (* d 0.3)]
                  [a c] [s (/ p 4.0)])
             (+ (* a (expt 2.0 (* -10.0 t2))
                   (sin (/ (* (- (* t2 d) s) 2.0 pi) p))) c b))))]))

(define (ease-bounce-out t b c d)
  (let* ([t2 (/ t d)])
    (cond
      [(< t2 (/ 1.0 2.75)) (+ (* c 7.5625 t2 t2) b)]
      [(< t2 (/ 2.0 2.75))
       (let ([postfix (- t2 (/ 1.5 2.75))])
         (+ (* c (+ (* 7.5625 postfix t2) 0.75)) b))]
      [(< t2 (/ 2.5 2.75))
       (let ([postfix (- t2 (/ 2.25 2.75))])
         (+ (* c (+ (* 7.5625 postfix t2) 0.9375)) b))]
      [else
       (let ([postfix (- t2 (/ 2.625 2.75))])
         (+ (* c (+ (* 7.5625 postfix t2) 0.984375)) b))])))

(define (ease-quad-out t b c d)
  (let ([t2 (/ t d)])
    (+ (- (* c t2 (- t2 2.0))) b)))

(define (ease-circ-out t b c d)
  (let ([t2 (- (/ t d) 1.0)])
    (+ (* c (sqrt (- 1.0 (* t2 t2)))) b)))

(define (ease-sine-out t b c d)
  (+ (* c (sin (* (/ t d) (/ pi 2.0)))) b))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - easings box")

(define rec (rectangle (/ (get-screen-width) 2.0) -100 100 100))
(define rotation 0.0)
(define alpha 1.0)
(define state 0)
(define frames-counter 0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (cond
      [(= state 0)
       (set! frames-counter (+ frames-counter 1))
       (set-rectangle-y! rec (ease-elastic-out frames-counter -100
                               (+ (/ (get-screen-height) 2.0) 100) 120))
       (when (>= frames-counter 120)
         (set! frames-counter 0) (set! state 1))]
      [(= state 1)
       (set! frames-counter (+ frames-counter 1))
       (set-rectangle-h! rec (ease-bounce-out frames-counter 100 -90 120))
       (set-rectangle-w! rec (ease-bounce-out frames-counter 100
                               (get-screen-width) 120))
       (when (>= frames-counter 120)
         (set! frames-counter 0) (set! state 2))]
      [(= state 2)
       (set! frames-counter (+ frames-counter 1))
       (set! rotation (ease-quad-out frames-counter 0.0 270.0 240))
       (when (>= frames-counter 240)
         (set! frames-counter 0) (set! state 3))]
      [(= state 3)
       (set! frames-counter (+ frames-counter 1))
       (set-rectangle-h! rec (ease-circ-out frames-counter 10
                               (get-screen-width) 120))
       (when (>= frames-counter 120)
         (set! frames-counter 0) (set! state 4))]
      [(= state 4)
       (set! frames-counter (+ frames-counter 1))
       (set! alpha (ease-sine-out frames-counter 1.0 -1.0 160))
       (when (>= frames-counter 160)
         (set! frames-counter 0) (set! state 5))])

    (when (is-key-pressed KEY-SPACE)
      (set! rec (rectangle (/ (get-screen-width) 2.0) -100 100 100))
      (set! rotation 0.0)
      (set! alpha 1.0)
      (set! state 0)
      (set! frames-counter 0))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-rectangle-pro rec (vector2 (/ (rectangle-w rec) 2)
                                      (/ (rectangle-h rec) 2))
                        rotation (fade BLACK alpha))

    (draw-text "PRESS [SPACE] TO RESET BOX ANIMATION!"
               10 (- (get-screen-height) 25) 20 LIGHTGRAY)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
