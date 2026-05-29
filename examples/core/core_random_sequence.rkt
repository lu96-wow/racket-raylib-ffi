#lang racket/base

;; raylib [core] example - random sequence (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_random_sequence.c
;;
;; 演示: 随机序列生成 + 随机颜色矩形 + 重排

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 辅助: 生成随机颜色
;; ============================================================

(define (generate-random-color)
  (make-color (get-random-value 0 255)
              (get-random-value 0 255)
              (get-random-value 0 255)
              255))

;; ============================================================
;; 辅助: 生成随机颜色矩形序列
;; 返回: vector of (vector color rect)
;;       用 vector-set! 可更新
;; ============================================================

(define (generate-random-color-rect-sequence rect-count rect-width screen-width screen-height)
  (define seq (load-random-sequence rect-count 0 (- rect-count 1)))
  (define rect-seq-width (* rect-count rect-width))
  (define start-x (* (- screen-width rect-seq-width) 0.5))

  (for/vector ([i (in-range rect-count)])
    (define rect-height (inexact->exact
                         (round (remap (list-ref seq i) 0 (- rect-count 1)
                                       0 screen-height))))
    (define color (generate-random-color))
    (define rect (rectangle (+ start-x (* i rect-width))
                            (- screen-height rect-height)
                            rect-width
                            rect-height))
    (vector color rect)))

;; ============================================================
;; 辅助: 重排序列 (只交换颜色和 height/y)
;; ============================================================

(define (shuffle-color-rect-sequence rectangles)
  (define count (vector-length rectangles))
  (define seq (load-random-sequence count 0 (- count 1)))

  (for ([i (in-range count)])
    (define j (list-ref seq i))
    (when (not (= i j))
      (define a (vector-ref rectangles i))   ;; (vector color rect)
      (define b (vector-ref rectangles j))   ;; (vector color rect)
      ;; 暂存 a 的颜色 / rect 的 height,y
      (define tmp-color (vector-ref a 0))
      (define a-rect (vector-ref a 1))
      (define tmp-height (rectangle-h a-rect))
      (define tmp-y (rectangle-y a-rect))
      ;; a ← b 的颜色和 height/y
      (define b-color (vector-ref b 0))
      (define b-rect (vector-ref b 1))
      (vector-set! a 0 b-color)
      (set-rectangle-h! a-rect (rectangle-h b-rect))
      (set-rectangle-y! a-rect (rectangle-y b-rect))
      ;; b ← a 的原始颜色和 height/y
      (vector-set! b 0 tmp-color)
      (set-rectangle-h! b-rect tmp-height)
      (set-rectangle-y! b-rect tmp-y)))

  rectangles)

;; ============================================================
;; 常量
;; ============================================================

(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - random sequence")

(define rect-count 20)
(define rect-size (/ SCREEN-WIDTH rect-count))
(define rectangles
  (generate-random-color-rect-sequence rect-count rect-size
    SCREEN-WIDTH (* 0.75 SCREEN-HEIGHT)))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (when (is-key-pressed KEY-SPACE)
      (shuffle-color-rect-sequence rectangles))

    (when (is-key-pressed KEY-UP)
      (set! rect-count (+ rect-count 1))
      (set! rect-size (/ SCREEN-WIDTH rect-count))
      (set! rectangles
        (generate-random-color-rect-sequence rect-count rect-size
          SCREEN-WIDTH (* 0.75 SCREEN-HEIGHT))))

    (when (is-key-pressed KEY-DOWN)
      (when (>= rect-count 4)
        (set! rect-count (- rect-count 1))
        (set! rect-size (/ SCREEN-WIDTH rect-count))
        (set! rectangles
          (generate-random-color-rect-sequence rect-count rect-size
            SCREEN-WIDTH (* 0.75 SCREEN-HEIGHT)))))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (for ([i (in-range (vector-length rectangles))])
      (define item (vector-ref rectangles i))
      (define color (vector-ref item 0))
      (define rect (vector-ref item 1))
      (draw-rectangle-rec rect color))

    (draw-text "Press SPACE to shuffle the current sequence"
               10 (- SCREEN-HEIGHT 96) 20 BLACK)
    (draw-text "Press UP to add a rectangle and generate a new sequence"
               10 (- SCREEN-HEIGHT 64) 20 BLACK)
    (draw-text "Press DOWN to remove a rectangle and generate a new sequence"
               10 (- SCREEN-HEIGHT 32) 20 BLACK)
    (draw-text (format "Count: ~a rectangles" rect-count)
               10 10 20 MAROON)
    (draw-fps (- SCREEN-WIDTH 80) 10)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
