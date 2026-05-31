#lang racket/base

;; raylib [shapes] example - easings box (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_easings_box.c
;; reasings.h 用纯 Racket 实现（无需 FFI 绑定，和 shapes_easings_ball 一致）

(require "../../raylib/raylib.rkt"
         racket/math)

;; ============================================================
;; Easing 函数 — 纯 Racket 实现
;;
;; 从 Robert Penner easing equations 翻译
;; 每个 easing 函数签名: (float t, float b, float c, float d)
;;   t = 当前帧数, b = 起始值, c = 变化量, d = 总时长
;; ============================================================

;; EaseElasticOut — 弹性下落
(define (ease-elastic-out t b c d)
  (if (= t 0.0) b
      (let ([t2 (/ t d)])
        (if (= t2 1.0) (+ b c)
            (let* ([p (* d 0.3)]
                   [a c]
                   [s (/ p 4.0)])
              (+ (* a (expt 2.0 (* -10.0 t2))
                    (sin (/ (* (- (* t2 d) s) 2.0 pi) p)))
                 c b))))))

;; EaseBounceOut — 弹跳效果
;;
;; NOTE: 对应 C 版 EaseBounceOut 的翻译要特别小心。
;; C 版中 t /= d 就地修改 t，postFix = t -= offset 同时改 t，
;; 所以 7.5625*postFix*t 实际上是 postFix 的平方。
(define (ease-bounce-out t b c d)
  (let ([t2 (/ t d)])
    (cond
      [(< t2 (/ 1.0 2.75))
       (+ (* c 7.5625 t2 t2) b)]
      [(< t2 (/ 2.0 2.75))
       (let ([postfix (- t2 (/ 1.5 2.75))])
         (+ (* c (+ (* 7.5625 postfix postfix) 0.75)) b))]
      [(< t2 (/ 2.5 2.75))
       (let ([postfix (- t2 (/ 2.25 2.75))])
         (+ (* c (+ (* 7.5625 postfix postfix) 0.9375)) b))]
      [else
       (let ([postfix (- t2 (/ 2.625 2.75))])
         (+ (* c (+ (* 7.5625 postfix postfix) 0.984375)) b))])))

;; EaseQuadOut — 二次缓出
(define (ease-quad-out t b c d)
  (let ([t2 (/ t d)])
    (+ (- (* c t2 (- t2 2.0))) b)))

;; EaseCircOut — 圆形缓出
(define (ease-circ-out t b c d)
  (let ([t2 (- (/ t d) 1.0)])
    (+ (* c (sqrt (- 1.0 (* t2 t2)))) b)))

;; EaseSineOut — 正弦缓出
(define (ease-sine-out t b c d)
  (+ (* c (sin (* (/ t d) (/ pi 2.0)))) b))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - easings box")

;; Box 动画变量
(define rec       (rectangle (/ (get-screen-width) 2.0) -100 100 100))
(define rotation  0.0)
(define alpha     1.0)
(define state     0)      ;; 动画阶段 0..4
(define frames-counter 0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- 更新 ----
    (cond
      ;; 阶段 0: 盒子弹性掉落到屏幕中央
      [(= state 0)
       (set! frames-counter (+ frames-counter 1))
       (set-rectangle-y! rec
         (ease-elastic-out frames-counter -100
           (+ (/ (get-screen-height) 2.0) 100) 120))
       (when (>= frames-counter 120)
         (set! frames-counter 0) (set! state 1))]

      ;; 阶段 1: 盒子铺开成水平条
      [(= state 1)
       (set! frames-counter (+ frames-counter 1))
       (set-rectangle-h! rec
         (ease-bounce-out frames-counter 100 -90 120))
       (set-rectangle-w! rec
         (ease-bounce-out frames-counter 100 (get-screen-width) 120))
       (when (>= frames-counter 120)
         (set! frames-counter 0) (set! state 2))]

      ;; 阶段 2: 水平条旋转 270 度
      [(= state 2)
       (set! frames-counter (+ frames-counter 1))
       (set! rotation (ease-quad-out frames-counter 0.0 270.0 240))
       (when (>= frames-counter 240)
         (set! frames-counter 0) (set! state 3))]

      ;; 阶段 3: 竖向填满屏幕
      [(= state 3)
       (set! frames-counter (+ frames-counter 1))
       (set-rectangle-h! rec
         (ease-circ-out frames-counter 10 (get-screen-width) 120))
       (when (>= frames-counter 120)
         (set! frames-counter 0) (set! state 4))]

      ;; 阶段 4: 淡出
      [(= state 4)
       (set! frames-counter (+ frames-counter 1))
       (set! alpha (ease-sine-out frames-counter 1.0 -1.0 160))
       (when (>= frames-counter 160)
         (set! frames-counter 0) (set! state 5))])

    ;; SPACE 键随时重置动画
    (when (is-key-pressed KEY-SPACE)
      (set! rec (rectangle (/ (get-screen-width) 2.0) -100 100 100))
      (set! rotation 0.0)
      (set! alpha 1.0)
      (set! state 0)
      (set! frames-counter 0))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-rectangle-pro rec
      (vector2 (/ (rectangle-w rec) 2) (/ (rectangle-h rec) 2))
      rotation
      (fade BLACK alpha))

    (draw-text "PRESS [SPACE] TO RESET BOX ANIMATION!"
      10 (- (get-screen-height) 25) 20 LIGHTGRAY)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
