#lang racket/base

;; raylib [textures] example - sprite animation (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_sprite_animation.c
;;
;; 演示: 使用精灵表 (spritesheet) 实现帧动画
;;   纹理水平包含 6 帧，右/左箭头键控制播放速度

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 资源路径
;; ============================================================

(define resource-dir
  (path->string (build-path (current-directory) "../../../examples/textures/resources/")))

;; ============================================================
;; 常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define max-frame-speed 15)
(define min-frame-speed 1)

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - sprite animation")

(define scarfy (load-texture (string-append resource-dir "scarfy.png")))

;; 精灵表有 6 帧水平排列
(define frame-width (/ (list-ref scarfy 1) 6.0))
(define frame-height (list-ref scarfy 2))

(define position (vector2 350.0 280.0))
(define frame-rec (rectangle 0.0 0.0 frame-width frame-height))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ([current-frame 0]
           [frames-counter 0]
           [frames-speed 8])
  (unless (window-should-close?)
    ;; 更新
    (let* ([frames-counter (+ frames-counter 1)]
           ;; 检查是否应该前进到下一帧
           [advance? (>= frames-counter (quotient 60 frames-speed))]
           ;; 帧推进
           [current-frame (if advance?
                             (let ([next (+ current-frame 1)])
                               (if (> next 5) 0 next))
                             current-frame)]
           [frames-counter (if advance? 0 frames-counter)]
           ;; 更新源矩形 x 偏移
           [_ (set-rectangle-x! frame-rec (* current-frame frame-width))]
           ;; 控制帧速度（右箭头加速，左箭头减速）
           [frames-speed
            (cond [(is-key-pressed KEY-RIGHT) (min (+ frames-speed 1) max-frame-speed)]
                  [(is-key-pressed KEY-LEFT)  (max (- frames-speed 1) min-frame-speed)]
                  [else frames-speed])])

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)

      ;; 绘制整个精灵表（左上角小尺寸）
      (draw-texture scarfy 15 40 WHITE)
      (draw-rectangle-lines 15 40 (list-ref scarfy 1) (list-ref scarfy 2) LIME)
      (draw-rectangle-lines (+ 15 (inexact->exact (truncate (rectangle-x frame-rec))))
                           (+ 40 (inexact->exact (truncate (rectangle-y frame-rec))))
                           (inexact->exact (truncate frame-width))
                           (inexact->exact (truncate frame-height)) RED)

      ;; 帧速度显示
      (draw-text "FRAME SPEED: " 165 210 10 DARKGRAY)
      (draw-text (format "~a FPS" frames-speed) 575 210 10 DARKGRAY)
      (draw-text "PRESS RIGHT/LEFT KEYS to CHANGE SPEED!" 290 240 10 DARKGRAY)

      ;; 速度指示条
      (for ([i (in-range max-frame-speed)])
        (let ([x (+ 250 (* 21 i))])
          (when (< i frames-speed)
            (draw-rectangle x 205 20 20 RED))
          (draw-rectangle-lines x 205 20 20 MAROON)))

      ;; 绘制当前动画帧（放大的精灵）
      (draw-texture-rec scarfy frame-rec position WHITE)

      (draw-text "(c) Scarfy sprite by Eiden Marsal"
                 (- screen-width 200) (- screen-height 20) 10 GRAY)

      (end-drawing)
      (loop current-frame frames-counter frames-speed))))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture scarfy)
(close-window)
