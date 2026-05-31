#lang racket/base

;; raylib [shapes] example - bullet hell (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_bullet_hell.c

(require "../../raylib/raylib.rkt"
         racket/list
         racket/match
         racket/math)

;; ============================================================
;; 常量
;; ============================================================

(define MAX-BULLETS 500000)
(define DEG2RAD (/ pi 180.0))

;; ============================================================
;; Bullet 结构体 — 纯 Racket 实现
;; ============================================================

(struct bullet (pos-x pos-y accel-x accel-y disabled color) #:mutable)

;; ============================================================
;; 辅助: 从 RenderTexture 中提取内嵌 Texture
;;   RenderTexture = (id tex-id tex-w tex-h tex-mip tex-fmt
;;                        dep-id dep-w dep-h dep-mip dep-fmt)
;;   Texture = (tex-id tex-w tex-h tex-mip tex-fmt)
;; ============================================================

(define (rt->texture rt)
  (list (list-ref rt 1) (list-ref rt 2)
        (list-ref rt 3) (list-ref rt 4) (list-ref rt 5)))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - bullet hell")

;; Bullets array (Racket 可变 vector)
(define bullets (make-vector MAX-BULLETS #f))
(define bullet-count 0)
(define bullet-disabled-count 0)
(define bullet-radius 10)
;; 预渲染子弹纹理
(define bullet-texture (load-render-texture 24 24))
(begin-texture-mode bullet-texture)
(draw-circle 12 12 (exact->inexact bullet-radius) WHITE)
(draw-circle-lines 12 12 (exact->inexact bullet-radius) BLACK)
(end-texture-mode)

(define draw-in-performance-mode? #t)

(set-target-fps 60)

(define bullet-speed 3.0)
(define bullet-rows 6)
(define bullet-colors (vector RED BLUE))

;; Spawner variables
(define base-direction 0.0)
(define angle-increment 5)
(define spawn-cooldown 2.0)
(define spawn-cooldown-timer spawn-cooldown)

;; Magic circle
(define magic-circle-rotation 0.0)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)

    ;; ========================================================
    ;; 更新
    ;; ========================================================

    ;; Reset the bullet index
    (when (>= bullet-count MAX-BULLETS)
      (set! bullet-count 0)
      (set! bullet-disabled-count 0))

    (set! spawn-cooldown-timer (- spawn-cooldown-timer 1))
    (when (< spawn-cooldown-timer 0)
      (set! spawn-cooldown-timer spawn-cooldown)

      ;; Spawn bullets
      (define degrees-per-row (/ 360.0 bullet-rows))
      (for ([row (in-range bullet-rows)])
        (when (< bullet-count MAX-BULLETS)
          (define dir (+ base-direction (* degrees-per-row row)))
          (vector-set! bullets bullet-count
            (bullet
              (/ screen-width 2.0) (/ screen-height 2.0)
              (* bullet-speed (cos (* dir DEG2RAD)))
              (* bullet-speed (sin (* dir DEG2RAD)))
              #f
              (vector-ref bullet-colors (modulo row 2))))
          (set! bullet-count (+ bullet-count 1))))
      (set! base-direction (+ base-direction angle-increment)))

    ;; Update bullets position
    (for ([i (in-range bullet-count)])
      (define b (vector-ref bullets i))
      (when b
        (unless (bullet-disabled b)
          (set-bullet-pos-x! b (+ (bullet-pos-x b) (bullet-accel-x b)))
          (set-bullet-pos-y! b (+ (bullet-pos-y b) (bullet-accel-y b)))
          (when (or (< (bullet-pos-x b) (* bullet-radius -2))
                    (> (bullet-pos-x b) (+ screen-width (* bullet-radius 2)))
                    (< (bullet-pos-y b) (* bullet-radius -2))
                    (> (bullet-pos-y b) (+ screen-height (* bullet-radius 2))))
            (set-bullet-disabled! b #t)
            (set! bullet-disabled-count (+ bullet-disabled-count 1))))))

    ;; Input logic
    (when (or (is-key-pressed KEY-RIGHT) (is-key-pressed KEY-D))
      (when (< bullet-rows 359) (set! bullet-rows (+ bullet-rows 1))))
    (when (or (is-key-pressed KEY-LEFT) (is-key-pressed KEY-A))
      (when (> bullet-rows 1) (set! bullet-rows (- bullet-rows 1))))
    (when (or (is-key-pressed KEY-UP) (is-key-pressed KEY-W))
      (set! bullet-speed (+ bullet-speed 0.25)))
    (when (or (is-key-pressed KEY-DOWN) (is-key-pressed KEY-S))
      (when (> bullet-speed 0.50) (set! bullet-speed (- bullet-speed 0.25))))
    (when (is-key-pressed KEY-Z)
      (when (> spawn-cooldown 1) (set! spawn-cooldown (- spawn-cooldown 1))))
    (when (is-key-pressed KEY-X)
      (set! spawn-cooldown (+ spawn-cooldown 1)))
    (when (is-key-pressed KEY-ENTER)
      (set! draw-in-performance-mode? (not draw-in-performance-mode?)))
    (when (is-key-down KEY-SPACE)
      (set! angle-increment (+ angle-increment 1))
      (set! angle-increment (modulo angle-increment 360)))
    (when (is-key-pressed KEY-C)
      (set! bullet-count 0)
      (set! bullet-disabled-count 0))


    ;; ========================================================
    ;; 绘制
    ;; ========================================================

    (begin-drawing)
    (clear-background RAYWHITE)

    ;; Draw magic circle
    (define mc-rot (+ magic-circle-rotation 1))
    (set! magic-circle-rotation mc-rot)
    (draw-rectangle-pro (rectangle (/ screen-width 2.0) (/ screen-height 2.0) 120 120)
                        (vector2 60.0 60.0) mc-rot PURPLE)
    (draw-rectangle-pro (rectangle (/ screen-width 2.0) (/ screen-height 2.0) 120 120)
                        (vector2 60.0 60.0) (+ mc-rot 45) PURPLE)
    (draw-circle-lines (quotient screen-width 2) (quotient screen-height 2) 70.0 BLACK)
    (draw-circle-lines (quotient screen-width 2) (quotient screen-height 2) 50.0 BLACK)
    (draw-circle-lines (quotient screen-width 2) (quotient screen-height 2) 30.0 BLACK)

    ;; Bullet texture dimensions
    (define bt-texture (rt->texture bullet-texture))
    (define btw (list-ref bt-texture 1))  ;; texture width
    (define bth (list-ref bt-texture 2))  ;; texture height

    ;; Draw bullets
    (if draw-in-performance-mode?
        (for ([i (in-range bullet-count)])
          (define b (vector-ref bullets i))
          (when (and b (not (bullet-disabled b)))
            (draw-texture bt-texture
              (exact-floor (- (bullet-pos-x b) (* btw 0.5)))
              (exact-floor (- (bullet-pos-y b) (* bth 0.5)))
              (bullet-color b))))
        (for ([i (in-range bullet-count)])
          (define b (vector-ref bullets i))
          (when (and b (not (bullet-disabled b)))
            (draw-circle-v (vector2 (bullet-pos-x b) (bullet-pos-y b))
                           (exact->inexact bullet-radius) (bullet-color b))
            (draw-circle-lines-v (vector2 (bullet-pos-x b) (bullet-pos-y b))
                                 (exact->inexact bullet-radius) BLACK))))

    ;; Draw UI
    (draw-rectangle 10 10 280 150 (make-color 0 0 0 200))
    (draw-text "Controls:" 20 20 10 LIGHTGRAY)
    (draw-text "- Right/Left or A/D: Change rows number" 40 40 10 LIGHTGRAY)
    (draw-text "- Up/Down or W/S: Change bullet speed" 40 60 10 LIGHTGRAY)
    (draw-text "- Z or X: Change spawn cooldown" 40 80 10 LIGHTGRAY)
    (draw-text "- Space (Hold): Change the angle increment" 40 100 10 LIGHTGRAY)
    (draw-text "- Enter: Switch draw method (Performance)" 40 120 10 LIGHTGRAY)
    (draw-text "- C: Clear bullets" 40 140 10 LIGHTGRAY)

    (draw-rectangle 610 10 170 30 (make-color 0 0 0 200))
    (if draw-in-performance-mode?
        (draw-text "Draw method: DrawTexture(*)" 620 20 10 GREEN)
        (draw-text "Draw method: DrawCircle(*)" 620 20 10 RED))

    ;; Status bar
    (draw-rectangle 135 410 530 30 (make-color 0 0 0 200))
    (draw-text
      (format "[ FPS: ~a, Bullets: ~a, Rows: ~a, Bullet speed: ~a, Angle increment per frame: ~a, Cooldown: ~a ]"
              (get-fps) (- bullet-count bullet-disabled-count) bullet-rows
              bullet-speed angle-increment spawn-cooldown)
      155 420 10 GREEN)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-render-texture bullet-texture)
(close-window)

