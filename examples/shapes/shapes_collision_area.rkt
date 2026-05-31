#lang racket/base

;; raylib [shapes] example - collision area (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_collision_area.c

(require "../../raylib/raylib.rkt"
         racket/math)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - collision area")

(define box-a (rectangle 10 (- (/ (get-screen-height) 2.0) 50) 200 100))
(define box-a-speed-x 4)

(define box-b (rectangle (- (/ (get-screen-width) 2.0) 30)
                         (- (/ (get-screen-height) 2.0) 30) 60 60))

(define box-collision (rectangle 0 0 0 0))

(define screen-upper-limit 40)
(define pause? #f)
(define collision? #f)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (unless pause?
      (set-rectangle-x! box-a (+ (rectangle-x box-a) box-a-speed-x)))

    ;; 弹跳
    (when (or (>= (+ (rectangle-x box-a) (rectangle-w box-a)) (get-screen-width))
              (<= (rectangle-x box-a) 0))
      (set! box-a-speed-x (* box-a-speed-x -1)))

    ;; 更新 box-b 跟随鼠标
    (set-rectangle-x! box-b (- (get-mouse-x) (/ (rectangle-w box-b) 2)))
    (set-rectangle-y! box-b (- (get-mouse-y) (/ (rectangle-h box-b) 2)))

    ;; 边界限制
    (when (>= (+ (rectangle-x box-b) (rectangle-w box-b)) (get-screen-width))
      (set-rectangle-x! box-b (- (get-screen-width) (rectangle-w box-b))))
    (when (<= (rectangle-x box-b) 0)
      (set-rectangle-x! box-b 0))
    (when (>= (+ (rectangle-y box-b) (rectangle-h box-b)) (get-screen-height))
      (set-rectangle-y! box-b (- (get-screen-height) (rectangle-h box-b))))
    (when (<= (rectangle-y box-b) screen-upper-limit)
      (set-rectangle-y! box-b screen-upper-limit))

    ;; 碰撞检测
    (set! collision? (check-collision-recs box-a box-b))
    (when collision?
      (set! box-collision (get-collision-rec box-a box-b)))

    ;; 暂停
    (when (is-key-pressed KEY-SPACE)
      (set! pause? (not pause?)))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-rectangle 0 0 screen-width screen-upper-limit
                    (if collision? RED BLACK))

    (draw-rectangle-rec box-a GOLD)
    (draw-rectangle-rec box-b BLUE)

    (when collision?
      (draw-rectangle-rec box-collision LIME)
      (draw-text "COLLISION!"
        (- (/ (get-screen-width) 2)
           (/ (measure-text "COLLISION!" 20) 2))
        (- (/ screen-upper-limit 2) 10) 20 BLACK)
      (draw-text
        (format "Collision Area: ~a"
                (* (exact-floor (rectangle-w box-collision))
                   (exact-floor (rectangle-h box-collision))))
        (- (/ (get-screen-width) 2) 100) (+ screen-upper-limit 10) 20 BLACK))

    (draw-text "Press SPACE to PAUSE/RESUME" 20 (- screen-height 35) 20 LIGHTGRAY)
    (draw-fps 10 10)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
