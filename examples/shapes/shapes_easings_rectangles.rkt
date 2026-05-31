#lang racket/base

;; raylib [shapes] example - easings rectangles (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_easings_rectangles.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define RECS-WIDTH  50)
(define RECS-HEIGHT 50)
(define MAX-RECS-X  16)   ;; 800/50
(define MAX-RECS-Y  9)    ;; 450/50
(define PLAY-TIME-IN-FRAMES 240)   ;; 4 seconds at 60 fps

;; ============================================================
;; Easing 函数 — 纯 Racket
;; ============================================================

(define (ease-circ-out t b c d)
  (let ([t2 (- (/ t d) 1.0)])
    (+ (* c (sqrt (- 1.0 (* t2 t2)))) b)))

(define (ease-linear-in t b c d)
  (+ (* c (/ t d)) b))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - easings rectangles")

;; 创建矩形网格 (16x9 = 144 个矩形)
(define recs (make-vector (* MAX-RECS-X MAX-RECS-Y)))
(for ([y (in-range MAX-RECS-Y)])
  (for ([x (in-range MAX-RECS-X)])
    (vector-set! recs (+ (* y MAX-RECS-X) x)
      (rectangle (+ (/ RECS-WIDTH 2.0) (* RECS-WIDTH x))
                 (+ (/ RECS-HEIGHT 2.0) (* RECS-HEIGHT y))
                 RECS-WIDTH RECS-HEIGHT))))

(define rotation 0.0)
(define frames-counter 0)
(define state 0)   ;; 0-Playing, 1-Finished

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (when (= state 0)
      (set! frames-counter (+ frames-counter 1))

      (for ([i (in-range (* MAX-RECS-X MAX-RECS-Y))])
        (define r (vector-ref recs i))
        (set-rectangle-h! r
          (max 0 (ease-circ-out frames-counter RECS-HEIGHT (- RECS-HEIGHT)
                                PLAY-TIME-IN-FRAMES)))
        (set-rectangle-w! r
          (max 0 (ease-circ-out frames-counter RECS-WIDTH (- RECS-WIDTH)
                                PLAY-TIME-IN-FRAMES)))
        (when (and (= (rectangle-h r) 0.0) (= (rectangle-w r) 0.0))
          (set! state 1)))

      (set! rotation (ease-linear-in frames-counter 0.0 360.0
                                      PLAY-TIME-IN-FRAMES)))

    (when (and (= state 1) (is-key-pressed KEY-SPACE))
      (set! frames-counter 0)
      (for ([i (in-range (* MAX-RECS-X MAX-RECS-Y))])
        (define r (vector-ref recs i))
        (set-rectangle-w! r RECS-WIDTH)
        (set-rectangle-h! r RECS-HEIGHT))
      (set! state 0))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (if (= state 0)
        (for ([i (in-range (* MAX-RECS-X MAX-RECS-Y))])
          (define r (vector-ref recs i))
          (draw-rectangle-pro r
            (vector2 (/ (rectangle-w r) 2) (/ (rectangle-h r) 2))
            rotation RED))
        (draw-text "PRESS [SPACE] TO PLAY AGAIN!" 240 200 20 GRAY))

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
