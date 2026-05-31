#lang racket/base

;; raylib [shapes] example - easings ball (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_easings_ball.c
;; 注意: reasings.h 不在 raylib 库中，用纯 Racket 实现 easing 函数

(require "../../raylib/raylib.rkt"
         racket/math)

;; ============================================================
;; Easing 函数 — 纯 Racket 实现（对应 reasings.h）
;;   参数: t=当前时间, b=起始值, c=变化量, d=总时长
;; ============================================================

(define (ease-cubic-out t b c d)
  (let ([t2 (- (/ t d) 1.0)])
    (+ (* c (+ (* t2 t2 t2) 1.0)) b)))

(define (ease-elastic-in t b c d)
  (cond
    [(= t 0.0) b]
    [else
     (let* ([t2 (/ t d)]
            [t2 (if (= t2 1.0) 1.0 t2)])
       (if (= t2 1.0)
           (+ b c)
           (let* ([p (* d 0.3)]
                  [a c]
                  [s (/ p 4.0)]
                  [t3 (- t2 1.0)]
                  [postfix (* a (expt 2.0 (* 10.0 t3)))])
             (+ (- (* postfix (sin (/ (* (- (* t3 d) s) 2.0 pi) p)))) b))))]))

(define (ease-elastic-out t b c d)
  (cond
    [(= t 0.0) b]
    [else
     (let* ([t2 (/ t d)]
            [t2 (if (= t2 1.0) 1.0 t2)])
       (if (= t2 1.0)
           (+ b c)
           (let* ([p (* d 0.3)]
                  [a c]
                  [s (/ p 4.0)])
             (+ (* a (expt 2.0 (* -10.0 t2))
                   (sin (/ (* (- (* t2 d) s) 2.0 pi) p)))
                c b))))]))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - easings ball")

(define ball-position-x -100)
(define ball-radius 20)
(define ball-alpha 0.0)

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
       (set! ball-position-x
         (exact-floor (ease-elastic-out frames-counter -100
                                         (+ (/ screen-width 2.0) 100) 120)))
       (when (>= frames-counter 120)
         (set! frames-counter 0)
         (set! state 1))]
      [(= state 1)
       (set! frames-counter (+ frames-counter 1))
       (set! ball-radius
         (exact-floor (ease-elastic-in frames-counter 20 500 200)))
       (when (>= frames-counter 200)
         (set! frames-counter 0)
         (set! state 2))]
      [(= state 2)
       (set! frames-counter (+ frames-counter 1))
       (set! ball-alpha (ease-cubic-out frames-counter 0.0 1.0 200))
       (when (>= frames-counter 200)
         (set! frames-counter 0)
         (set! state 3))]
      [(= state 3)
       (when (is-key-pressed KEY-ENTER)
         (set! ball-position-x -100)
         (set! ball-radius 20)
         (set! ball-alpha 0.0)
         (set! state 0))])

    (when (is-key-pressed KEY-R)
      (set! frames-counter 0))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (when (>= state 2)
      (draw-rectangle 0 0 screen-width screen-height GREEN))

    (draw-circle ball-position-x 200 (exact->inexact ball-radius)
                 (fade RED (- 1.0 ball-alpha)))

    (when (= state 3)
      (draw-text "PRESS [ENTER] TO PLAY AGAIN!" 240 200 20 BLACK))

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
