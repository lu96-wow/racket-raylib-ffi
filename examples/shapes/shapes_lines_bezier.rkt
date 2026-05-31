#lang racket/base

;; raylib [shapes] example - lines bezier (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_lines_bezier.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window screen-width screen-height
  "raylib [shapes] example - lines bezier")

(define start-point (vector2 30 30))
(define end-point   (vector2 (- screen-width 30) (- screen-height 30)))
(define move-start-point? #f)
(define move-end-point?   #f)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (define mouse (get-mouse-position))

    (cond
      [(and (check-collision-point-circle mouse start-point 10.0)
            (is-mouse-button-down MOUSE-BUTTON-LEFT))
       (set! move-start-point? #t)]
      [(and (check-collision-point-circle mouse end-point 10.0)
            (is-mouse-button-down MOUSE-BUTTON-LEFT))
       (set! move-end-point? #t)])

    (when move-start-point?
      (set-vector2-x! start-point (vector2-x mouse))
      (set-vector2-y! start-point (vector2-y mouse))
      (when (is-mouse-button-released MOUSE-BUTTON-LEFT)
        (set! move-start-point? #f)))

    (when move-end-point?
      (set-vector2-x! end-point (vector2-x mouse))
      (set-vector2-y! end-point (vector2-y mouse))
      (when (is-mouse-button-released MOUSE-BUTTON-LEFT)
        (set! move-end-point? #f)))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-text "MOVE START-END POINTS WITH MOUSE" 15 20 20 GRAY)

    ;; 绘制贝塞尔曲线
    (draw-line-bezier start-point end-point 4.0 BLUE)

    ;; 绘制起点终点圆圈
    (define start-hover? (check-collision-point-circle mouse start-point 10.0))
    (define end-hover?   (check-collision-point-circle mouse end-point 10.0))

    (draw-circle-v start-point (if start-hover? 14.0 8.0)
                   (if move-start-point? RED BLUE))
    (draw-circle-v end-point (if end-hover? 14.0 8.0)
                   (if move-end-point? RED BLUE))

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
