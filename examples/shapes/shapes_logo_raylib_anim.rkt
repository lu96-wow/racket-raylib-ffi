#lang racket/base

;; raylib [shapes] example - logo raylib anim (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_logo_raylib_anim.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - logo raylib anim")

(define logo-pos-x (- (quotient screen-width 2) 128))
(define logo-pos-y (- (quotient screen-height 2) 128))

(define frames-counter 0)
(define letters-count 0)

(define top-side-rec-width 16)
(define left-side-rec-height 16)
(define bottom-side-rec-width 16)
(define right-side-rec-height 16)

(define state 0)
(define alpha 1.0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新 — 状态机
    (cond
      [(= state 0)
       (set! frames-counter (+ frames-counter 1))
       (when (= frames-counter 120)
         (set! state 1)
         (set! frames-counter 0))]
      [(= state 1)
       (set! top-side-rec-width (+ top-side-rec-width 4))
       (set! left-side-rec-height (+ left-side-rec-height 4))
       (when (= top-side-rec-width 256) (set! state 2))]
      [(= state 2)
       (set! bottom-side-rec-width (+ bottom-side-rec-width 4))
       (set! right-side-rec-height (+ right-side-rec-height 4))
       (when (= bottom-side-rec-width 256) (set! state 3))]
      [(= state 3)
       (set! frames-counter (+ frames-counter 1))
       (when (= (quotient frames-counter 12) 1)
         (set! letters-count (+ letters-count 1))
         (set! frames-counter 0))
       (when (>= letters-count 10)
         (set! alpha (- alpha 0.02))
         (when (<= alpha 0.0)
           (set! alpha 0.0)
           (set! state 4)))]
      [(= state 4)
       (when (is-key-pressed KEY-R)
         (set! frames-counter 0)
         (set! letters-count 0)
         (set! top-side-rec-width 16)
         (set! left-side-rec-height 16)
         (set! bottom-side-rec-width 16)
         (set! right-side-rec-height 16)
         (set! alpha 1.0)
         (set! state 0))])

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (cond
      [(= state 0)
       (when (= (modulo (quotient frames-counter 15) 2) 1)
         (draw-rectangle logo-pos-x logo-pos-y 16 16 BLACK))]
      [(= state 1)
       (draw-rectangle logo-pos-x logo-pos-y top-side-rec-width 16 BLACK)
       (draw-rectangle logo-pos-x logo-pos-y 16 left-side-rec-height BLACK)]
      [(= state 2)
       (draw-rectangle logo-pos-x logo-pos-y top-side-rec-width 16 BLACK)
       (draw-rectangle logo-pos-x logo-pos-y 16 left-side-rec-height BLACK)
       (draw-rectangle (+ logo-pos-x 240) logo-pos-y 16 right-side-rec-height BLACK)
       (draw-rectangle logo-pos-x (+ logo-pos-y 240) bottom-side-rec-width 16 BLACK)]
      [(= state 3)
       (draw-rectangle logo-pos-x logo-pos-y top-side-rec-width 16 (fade BLACK alpha))
       (draw-rectangle logo-pos-x (+ logo-pos-y 16) 16 (- left-side-rec-height 32) (fade BLACK alpha))
       (draw-rectangle (+ logo-pos-x 240) (+ logo-pos-y 16) 16 (- right-side-rec-height 32) (fade BLACK alpha))
       (draw-rectangle logo-pos-x (+ logo-pos-y 240) bottom-side-rec-width 16 (fade BLACK alpha))
       (draw-rectangle (- (quotient (get-screen-width) 2) 112)
                       (- (quotient (get-screen-height) 2) 112)
                       224 224 (fade RAYWHITE alpha))
       (draw-text (text-subtext "raylib" 0 letters-count)
                  (- (quotient (get-screen-width) 2) 44)
                  (+ (quotient (get-screen-height) 2) 48)
                  50 (fade BLACK alpha))]
      [(= state 4)
       (draw-text "[R] REPLAY" 340 200 20 GRAY)])

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
