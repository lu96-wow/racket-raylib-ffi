#lang racket/base

;; raylib [core] example - delta time (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_delta_time.c

(require racket/math
         racket/format
         "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [core] example - delta time")

(define current-fps 60)

(define delta-circle (vector2 0 (/ screen-height 3.0)))
(define frame-circle (vector2 0 (* screen-height (/ 2.0 3.0))))

(define speed 10.0)
(define circle-radius 32.0)

(set-target-fps current-fps)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (let ([mouse-wheel (get-mouse-wheel-move)])
      (unless (zero? mouse-wheel)
        (set! current-fps (+ current-fps (exact-round mouse-wheel)))
        (when (< current-fps 0) (set! current-fps 0))
        (set-target-fps current-fps)))

    (set-vector2-x! delta-circle
      (+ (vector2-x delta-circle) (* (get-frame-time) 6.0 speed)))

    (set-vector2-x! frame-circle
      (+ (vector2-x frame-circle) (* 0.1 speed)))

    ;; 边界重置
    (when (> (vector2-x delta-circle) screen-width)
      (set-vector2-x! delta-circle 0))
    (when (> (vector2-x frame-circle) screen-width)
      (set-vector2-x! frame-circle 0))

    ;; 按 R 重置
    (when (is-key-pressed KEY-R)
      (set-vector2-x! delta-circle 0)
      (set-vector2-x! frame-circle 0))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-circle-v delta-circle circle-radius RED)
    (draw-circle-v frame-circle circle-radius BLUE)

    (draw-text
      (format "FPS: ~a (target: ~a)" (get-fps) current-fps)
      10 10 20 DARKGRAY)
    (draw-text
      (format "Frame time: ~a ms" (~r (get-frame-time) #:precision 2))
      10 30 20 DARKGRAY)
    (draw-text
      "Use the scroll wheel to change the fps limit, r to reset"
      10 50 20 DARKGRAY)
    (draw-text "FUNC: x += GetFrameTime()*speed" 10 90 20 RED)
    (draw-text "FUNC: x += speed" 10 240 20 BLUE)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
