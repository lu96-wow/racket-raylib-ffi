#lang racket/base

;; raylib [shapes] example - rectangle scaling (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_rectangle_scaling.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define MOUSE-SCALE-MARK-SIZE 12)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - rectangle scaling")

(define rec (rectangle 100 100 200 80))

(define mouse-scale-ready? #f)
(define mouse-scale-mode?  #f)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (define mouse-pos (get-mouse-position))
    (define rx (rectangle-x rec))
    (define ry (rectangle-y rec))
    (define rw (rectangle-w rec))
    (define rh (rectangle-h rec))

    ;; 检测鼠标是否在右下角缩放标记区域内
    (if (check-collision-point-rec mouse-pos
          (rectangle (+ rx rw (- MOUSE-SCALE-MARK-SIZE))
                     (+ ry rh (- MOUSE-SCALE-MARK-SIZE))
                     MOUSE-SCALE-MARK-SIZE
                     MOUSE-SCALE-MARK-SIZE))
        (begin
          (set! mouse-scale-ready? #t)
          (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
            (set! mouse-scale-mode? #t)))
        (set! mouse-scale-ready? #f))

    (when mouse-scale-mode?
      (set! mouse-scale-ready? #t)
      (set-rectangle-w! rec (- (vector2-x mouse-pos) rx))
      (set-rectangle-h! rec (- (vector2-y mouse-pos) ry))

      ;; 最小尺寸
      (when (< (rectangle-w rec) MOUSE-SCALE-MARK-SIZE)
        (set-rectangle-w! rec MOUSE-SCALE-MARK-SIZE))
      (when (< (rectangle-h rec) MOUSE-SCALE-MARK-SIZE)
        (set-rectangle-h! rec MOUSE-SCALE-MARK-SIZE))

      ;; 最大尺寸
      (when (> (rectangle-w rec) (- (get-screen-width) rx))
        (set-rectangle-w! rec (- (get-screen-width) rx)))
      (when (> (rectangle-h rec) (- (get-screen-height) ry))
        (set-rectangle-h! rec (- (get-screen-height) ry)))

      (when (is-mouse-button-released MOUSE-BUTTON-LEFT)
        (set! mouse-scale-mode? #f)))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-text "Scale rectangle dragging from bottom-right corner!"
               10 10 20 GRAY)
    (draw-rectangle-rec rec (fade GREEN 0.5))

    (when mouse-scale-ready?
      (define rrx (rectangle-x rec))
      (define rry (rectangle-y rec))
      (define rrw (rectangle-w rec))
      (define rrh (rectangle-h rec))
      (draw-rectangle-lines-ex rec 1 RED)
      (draw-triangle
        (vector2 (+ rrx rrw (- MOUSE-SCALE-MARK-SIZE)) (+ rry rrh))
        (vector2 (+ rrx rrw) (+ rry rrh))
        (vector2 (+ rrx rrw) (+ rry rrh (- MOUSE-SCALE-MARK-SIZE)))
        RED))

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
