#lang racket/base

;; raylib [textures] example - particles blending (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_particles_blending.c
;;
;; 演示: 粒子系统 + 混合模式切换
;;   SPACE 切换 BLEND_ALPHA / BLEND_ADDITIVE
;;   鼠标移动产生彩色粒子尾迹

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define-runtime-path resource-dir-path
  "../../../examples/textures/resources/")
(define resource-dir (path->string resource-dir-path))

;; ============================================================
;; 资源路径
;; ============================================================

;; ============================================================
;; 常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define max-particles 200)

;; ============================================================
;; 粒子数据: 用并行向量存储
;; ============================================================

(define pos-x (make-vector max-particles 0.0))
(define pos-y (make-vector max-particles 0.0))
(define colors (make-vector max-particles))
(define alphas (make-vector max-particles 1.0))
(define sizes (make-vector max-particles 0.0))
(define rotations (make-vector max-particles 0.0))
(define active (make-vector max-particles #f))

;; 初始化粒子随机颜色和大小
(for ([i (in-range max-particles)])
  (vector-set! colors i (color (get-random-value 0 255)
                               (get-random-value 0 255)
                               (get-random-value 0 255)
                               255))
  (vector-set! sizes i (/ (get-random-value 1 30) 20.0))
  (vector-set! rotations i (get-random-value 0 360)))

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
             "raylib [textures] example - particles blending")

(define smoke (load-texture (string-append resource-dir "spark_flame.png")))
(define tex-w (list-ref smoke 1))
(define tex-h (list-ref smoke 2))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(define (activate-next)
  ;; 找到第一个未激活的粒子，在鼠标位置激活
  (let loop ([i 0])
    (when (< i max-particles)
      (if (not (vector-ref active i))
          (let ([mp (get-mouse-position)])
            (vector-set! active i #t)
            (vector-set! alphas i 1.0)
            (vector-set! pos-x i (vector2-x mp))
            (vector-set! pos-y i (vector2-y mp)))
          (loop (+ i 1))))))

(let loop ([blending BLEND-ALPHA])
  (unless (window-should-close?)
    ;; 更新
    (let* ([blending
            (if (is-key-pressed KEY-SPACE)
                (if (= blending BLEND-ALPHA) BLEND-ADDITIVE BLEND-ALPHA)
                blending)])
      ;; 每帧激活一个粒子
      (activate-next)

      ;; 更新所有活跃粒子
      (for ([i (in-range max-particles)])
        (when (vector-ref active i)
          (vector-set! pos-y i (+ (vector-ref pos-y i) 1.5)) ;; 重力下落
          (vector-set! alphas i (- (vector-ref alphas i) 0.005)) ;; 渐隐
          (when (<= (vector-ref alphas i) 0.0)
            (vector-set! active i #f))
          (vector-set! rotations i (+ (vector-ref rotations i) 2.0)))))

    ;; 绘制
    (begin-drawing)
    (clear-background DARKGRAY)

    (begin-blend-mode blending)

    (for ([i (in-range max-particles)])
      (when (vector-ref active i)
        (let ([size (vector-ref sizes i)])
          (draw-texture-pro smoke
                            (rectangle 0.0 0.0 tex-w tex-h)
                            (rectangle (vector-ref pos-x i) (vector-ref pos-y i)
                                       (* tex-w size) (* tex-h size))
                            (vector2 (/ (* tex-w size) 2.0) (/ (* tex-h size) 2.0))
                            (vector-ref rotations i)
                            (fade (vector-ref colors i) (vector-ref alphas i))))))

    (end-blend-mode)

    (draw-text "PRESS SPACE to CHANGE BLENDING MODE" 180 20 20 BLACK)

    (if (= blending BLEND-ALPHA)
        (draw-text "ALPHA BLENDING" 290 (- screen-height 40) 20 BLACK)
        (draw-text "ADDITIVE BLENDING" 280 (- screen-height 40) 20 RAYWHITE))

    (end-drawing)
    (loop blending)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture smoke)
(close-window)
