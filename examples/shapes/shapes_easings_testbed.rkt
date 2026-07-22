#lang racket/base

;; raylib [shapes] example - easings testbed (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_easings_testbed.c

(require "../../raylib/raylib.rkt" racket/math)

;; ============================================================
;; Easing 函数 (译自 reasings.h)
;; ============================================================

(define (no-ease t b c d) b)
(define (ease-linear-none t b c d) (+ (* c (/ t d)) b))
(define ease-linear-in ease-linear-none)
(define ease-linear-out ease-linear-none)
(define ease-linear-in-out ease-linear-none)
(define (ease-sine-in t b c d) (+ (- (* c (cos (* (/ t d) (/ pi 2.0)))) c) b))
(define (ease-sine-out t b c d) (+ (* c (sin (* (/ t d) (/ pi 2.0)))) b))
(define (ease-sine-in-out t b c d) (+ (* (- c) 0.5 (- (cos (/ (* pi t) d)) 1.0)) b))
(define (ease-circ-in t b c d) (set! t (/ t d)) (+ (* (- c) (- (sqrt (- 1.0 (* t t))) 1.0)) b))
(define (ease-circ-out t b c d) (set! t (- (/ t d) 1.0)) (+ (* c (sqrt (- 1.0 (* t t)))) b))
(define (ease-circ-in-out t b c d)
  (set! t (/ t (/ d 2.0)))
  (if (< t 1.0) (+ (* (- c) 0.5 (- (sqrt (- 1.0 (* t t))) 1.0)) b)
      (begin (set! t (- t 2.0)) (+ (* c 0.5 (+ (sqrt (- 1.0 (* t t))) 1.0)) b))))
(define (ease-cubic-in t b c d) (set! t (/ t d)) (+ (* c t t t) b))
(define (ease-cubic-out t b c d) (set! t (- (/ t d) 1.0)) (+ (* c (+ (* t t t) 1.0)) b))
(define (ease-cubic-in-out t b c d)
  (set! t (/ t (/ d 2.0)))
  (if (< t 1.0) (+ (* c 0.5 t t t) b)
      (begin (set! t (- t 2.0)) (+ (* c 0.5 (+ (* t t t) 2.0)) b))))
(define (ease-quad-in t b c d) (set! t (/ t d)) (+ (* c t t) b))
(define (ease-quad-out t b c d) (set! t (/ t d)) (+ (- (* c t (- t 2.0))) b))
(define (ease-quad-in-out t b c d)
  (set! t (/ t (/ d 2.0)))
  (if (< t 1.0) (+ (* c 0.5 t t) b)
      (begin (set! t (- t 1.0)) (+ (* (- c) 0.5 (- (* t (- t 2.0)) 1.0)) b))))
(define (ease-expo-in t b c d)
  (if (= t 0.0) b (+ (* c (expt 2.0 (* 10.0 (- (/ t d) 1.0)))) b)))
(define (ease-expo-out t b c d)
  (if (= t d) (+ b c) (+ (* c (+ (- (expt 2.0 (* -10.0 (/ t d)))) 1.0)) b)))
(define (ease-expo-in-out t b c d)
  (cond [(= t 0.0) b] [(= t d) (+ b c)]
        [else (set! t (/ t (/ d 2.0)))
         (if (< t 1.0) (+ (* c 0.5 (expt 2.0 (* 10.0 (- t 1.0)))) b)
             (+ (* c 0.5 (+ (- (expt 2.0 (* -10.0 (- t 1.0)))) 2.0)) b))]))
(define (ease-back-in t b c d)
  (define s 1.70158) (set! t (/ t d)) (+ (* c t t (- (* (+ s 1.0) t) s)) b))
(define (ease-back-out t b c d)
  (define s 1.70158) (set! t (- (/ t d) 1.0)) (+ (* c (+ (* t t (+ (* (+ s 1.0) t) s)) 1.0)) b))
(define (ease-back-in-out t b c d)
  (define s 1.70158) (set! t (/ t (/ d 2.0)))
  (if (< t 1.0) (begin (set! s (* s 1.525)) (+ (* c 0.5 t t (- (* (+ s 1.0) t) s)) b))
      (begin (set! t (- t 2.0)) (set! s (* s 1.525))
             (+ (* c 0.5 (+ (* t t (+ (* (+ s 1.0) t) s)) 2.0)) b))))
(define (ease-bounce-out t b c d)
  (set! t (/ t d))
  (cond [(< t (/ 1.0 2.75)) (+ (* c 7.5625 t t) b)]
        [(< t (/ 2.0 2.75)) (set! t (- t (/ 1.5 2.75))) (+ (* c (+ (* 7.5625 t t) 0.75)) b)]
        [(< t (/ 2.5 2.75)) (set! t (- t (/ 2.25 2.75))) (+ (* c (+ (* 7.5625 t t) 0.9375)) b)]
        [else (set! t (- t (/ 2.625 2.75))) (+ (* c (+ (* 7.5625 t t) 0.984375)) b)]))
(define (ease-bounce-in t b c d) (+ (- c (ease-bounce-out (- d t) 0.0 c d)) b))
(define (ease-bounce-in-out t b c d)
  (if (< t (* d 0.5)) (+ (* (ease-bounce-in (* t 2.0) 0.0 c d) 0.5) b)
      (+ (* (ease-bounce-out (- (* t 2.0) d) 0.0 c d) 0.5) (* c 0.5) b)))
(define (ease-elastic-in t b c d)
  (if (= t 0.0) b
      (let* ([_ (set! t (/ t d))] [p (* d 0.3)] [s (/ p 4.0)])
        (set! t (- t 1.0))
        (+ (- (* c (expt 2.0 (* 10.0 t)) (sin (* (/ (- (* t d) s) p) 2.0 pi)))) b))))
(define (ease-elastic-out t b c d)
  (if (= t 0.0) b
      (let* ([_ (set! t (/ t d))] [p (* d 0.3)] [s (/ p 4.0)])
        (+ (* c (expt 2.0 (* -10.0 t)) (sin (* (/ (- (* t d) s) p) 2.0 pi))) c b))))
(define (ease-elastic-in-out t b c d)
  (if (= t 0.0) b
      (let* ([_ (set! t (/ t (/ d 2.0)))] [p (* d 0.45)] [s (/ p 4.0)])
        (if (< t 1.0) (begin (set! t (- t 1.0))
          (+ (- (* c 0.5 (expt 2.0 (* 10.0 t)) (sin (* (/ (- (* t d) s) p) 2.0 pi)))) b))
          (begin (set! t (- t 1.0))
          (+ (* c 0.5 (expt 2.0 (* -10.0 t)) (sin (* (/ (- (* t d) s) p) 2.0 pi))) (* c 0.5) b))))))

(define easings
  (vector (list "EaseLinearNone" ease-linear-none) (list "EaseLinearIn" ease-linear-in)
          (list "EaseLinearOut" ease-linear-out) (list "EaseLinearInOut" ease-linear-in-out)
          (list "EaseSineIn" ease-sine-in) (list "EaseSineOut" ease-sine-out)
          (list "EaseSineInOut" ease-sine-in-out) (list "EaseCircIn" ease-circ-in)
          (list "EaseCircOut" ease-circ-out) (list "EaseCircInOut" ease-circ-in-out)
          (list "EaseCubicIn" ease-cubic-in) (list "EaseCubicOut" ease-cubic-out)
          (list "EaseCubicInOut" ease-cubic-in-out) (list "EaseQuadIn" ease-quad-in)
          (list "EaseQuadOut" ease-quad-out) (list "EaseQuadInOut" ease-quad-in-out)
          (list "EaseExpoIn" ease-expo-in) (list "EaseExpoOut" ease-expo-out)
          (list "EaseExpoInOut" ease-expo-in-out) (list "EaseBackIn" ease-back-in)
          (list "EaseBackOut" ease-back-out) (list "EaseBackInOut" ease-back-in-out)
          (list "EaseBounceOut" ease-bounce-out) (list "EaseBounceIn" ease-bounce-in)
          (list "EaseBounceInOut" ease-bounce-in-out) (list "EaseElasticIn" ease-elastic-in)
          (list "EaseElasticOut" ease-elastic-out) (list "EaseElasticInOut" ease-elastic-in-out)
          (list "None" no-ease)))
(define EASING-NONE 28)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define FONT-SIZE 20)
(init-window screen-width screen-height "raylib [shapes] example - easings testbed")

(set-target-fps 60)

(define ball-pos (vector2 100.0 100.0))

;; 可变状态: 用 let-passing 在线程中传递
(let loop ([t 0.0] [d 300.0] [paused #t] [bounded-t? #t]
            [easing-x EASING-NONE] [easing-y EASING-NONE])
  (unless (window-should-close?)

    ;; — 输入处理 —
    (let* ([bounded-t? (if (is-key-pressed KEY-T) (not bounded-t?) bounded-t?)]

           [easing-x (cond [(is-key-pressed KEY-RIGHT)
                            (let ([v (add1 easing-x)])
                              (if (> v EASING-NONE) 0 v))]
                           [(is-key-pressed KEY-LEFT)
                            (if (= easing-x 0) EASING-NONE (sub1 easing-x))]
                           [else easing-x])]

           [easing-y (cond [(is-key-pressed KEY-DOWN)
                            (let ([v (add1 easing-y)])
                              (if (> v EASING-NONE) 0 v))]
                           [(is-key-pressed KEY-UP)
                            (if (= easing-y 0) EASING-NONE (sub1 easing-y))]
                           [else easing-y])]

           [d (cond [(and (is-key-pressed KEY-W) (< d (- 10000.0 20.0))) (+ d 20.0)]
                    [(and (is-key-pressed KEY-Q) (> d (+ 1.0 20.0))) (- d 20.0)]
                    [(and (is-key-down KEY-S) (< d (- 10000.0 2.0))) (+ d 2.0)]
                    [(and (is-key-down KEY-A) (> d (+ 1.0 2.0))) (- d 2.0)]
                    [else d])]

           ;; 重置条件: SPACE / 方向键 / 边界到达
           [reset? (or (is-key-pressed KEY-SPACE) (is-key-pressed KEY-T)
                       (is-key-pressed KEY-RIGHT) (is-key-pressed KEY-LEFT)
                       (is-key-pressed KEY-DOWN) (is-key-pressed KEY-UP)
                       (is-key-pressed KEY-W) (is-key-pressed KEY-Q)
                       (is-key-down KEY-S) (is-key-down KEY-A)
                       (and (is-key-pressed KEY-ENTER) bounded-t? (>= t d)))]

           [paused (if (is-key-pressed KEY-ENTER) (not paused) paused)])

      ;; 重置
      (when reset?
        (set! t 0.0)
        (set-vector2-x! ball-pos 100.0)
        (set-vector2-y! ball-pos 100.0)
        (set! paused #t))

      ;; 动画更新
      (let ([t (if (and (not paused)
                        (or (and bounded-t? (< t d))
                            (not bounded-t?)))
                   (let ([efn-x (cadr (vector-ref easings easing-x))]
                         [efn-y (cadr (vector-ref easings easing-y))])
                     (set-vector2-x! ball-pos (efn-x t 100.0 530.0 d))
                     (set-vector2-y! ball-pos (efn-y t 100.0 230.0 d))
                     (+ t 1.0))
                   t)])

        ;; — 绘制 —
        (begin-drawing)
        (clear-background RAYWHITE)
        (draw-text (format "Easing x: ~a" (car (vector-ref easings easing-x)))
                   20 FONT-SIZE FONT-SIZE LIGHTGRAY)
        (draw-text (format "Easing y: ~a" (car (vector-ref easings easing-y)))
                   20 (* FONT-SIZE 2) FONT-SIZE LIGHTGRAY)
        (draw-text (format "t (~a) = ~a d = ~a"
                           (if bounded-t? "b" "u")
                           (real->decimal-string t 2)
                           (real->decimal-string d 2))
                   20 (* FONT-SIZE 3) FONT-SIZE LIGHTGRAY)
        (draw-text "Use ENTER to play or pause movement, use SPACE to restart"
                   20 (- (get-screen-height) (* FONT-SIZE 2)) FONT-SIZE LIGHTGRAY)
        (draw-text "Use Q and W or A and S keys to change duration"
                   20 (- (get-screen-height) (* FONT-SIZE 3)) FONT-SIZE LIGHTGRAY)
        (draw-text "Use LEFT or RIGHT keys to choose easing for the x axis"
                   20 (- (get-screen-height) (* FONT-SIZE 4)) FONT-SIZE LIGHTGRAY)
        (draw-text "Use UP or DOWN keys to choose easing for the y axis"
                   20 (- (get-screen-height) (* FONT-SIZE 5)) FONT-SIZE LIGHTGRAY)
        (draw-circle-v ball-pos 16.0 MAROON)
        (end-drawing)

        (loop t d paused bounded-t? easing-x easing-y)))))

(close-window)
