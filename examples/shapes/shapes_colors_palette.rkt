#lang racket/base

;; raylib [shapes] example - colors palette (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_colors_palette.c

(require "../../raylib/raylib.rkt"
         racket/math)

;; ============================================================
;; 常量
;; ============================================================

(define MAX-COLORS-COUNT 21)

(define colors
  (vector DARKGRAY MAROON ORANGE DARKGREEN DARKBLUE DARKPURPLE DARKBROWN
          GRAY RED GOLD LIME BLUE VIOLET BROWN LIGHTGRAY PINK YELLOW
          GREEN SKYBLUE PURPLE BEIGE))

(define color-names
  (vector "DARKGRAY" "MAROON" "ORANGE" "DARKGREEN" "DARKBLUE"
          "DARKPURPLE" "DARKBROWN" "GRAY" "RED" "GOLD"
          "LIME" "BLUE" "VIOLET" "BROWN" "LIGHTGRAY"
          "PINK" "YELLOW" "GREEN" "SKYBLUE" "PURPLE" "BEIGE"))

(define color-recs (make-vector MAX-COLORS-COUNT #f))
(define color-state (make-vector MAX-COLORS-COUNT #f))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - colors palette")

;; 填充矩形数据
(for ([i (in-range MAX-COLORS-COUNT)])
  (vector-set! color-recs i
    (rectangle (+ 20.0 (* 100.0 (modulo i 7)) (* 10.0 (modulo i 7)))
               (+ 80.0 (* 100.0 (quotient i 7)) (* 10.0 (/ i 7.0)))
               100.0 100.0)))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (define mouse-pos (get-mouse-position))
    (for ([i (in-range MAX-COLORS-COUNT)])
      (vector-set! color-state i
        (check-collision-point-rec mouse-pos (vector-ref color-recs i))))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-text "raylib colors palette" 28 42 20 BLACK)
    (draw-text "press SPACE to see all colors"
               (- (get-screen-width) 180) (- (get-screen-height) 40) 10 GRAY)

    (for ([i (in-range MAX-COLORS-COUNT)])
      (define rec (vector-ref color-recs i))
      (define hover? (vector-ref color-state i))

      (draw-rectangle-rec rec (fade (vector-ref colors i) (if hover? 0.6 1.0)))

      (when (or (is-key-down KEY-SPACE) hover?)
        (define rx (rectangle-x rec))
        (define ry (rectangle-y rec))
        (define rw (rectangle-w rec))
        (define rh (rectangle-h rec))

        (draw-rectangle (exact-floor rx) (exact-floor (- (+ ry rh) 26))
                        (exact-floor rw) 20 BLACK)
        (draw-rectangle-lines-ex rec 6.0 (fade BLACK 0.3))
        (draw-text (vector-ref color-names i)
          (exact-floor (- (+ rx rw) (measure-text (vector-ref color-names i) 10) 12))
          (exact-floor (- (+ ry rh) 20)) 10 (vector-ref colors i))))

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
