#lang racket/base

;; raylib [textures] example - bunnymark (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_bunnymark.c
;;
;; 演示: 大量精灵绘制基准测试
;;   按住鼠标左键生成兔子，P 键暂停/继续
;;   右上角显示 FPS、兔子数量和批次绘制调用数

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

;; ============================================================
;; 资源路径 (相对于源文件位置，不依赖运行目录)
;; ============================================================

(define-runtime-path resource-dir-path
  "../../../examples/textures/resources/")

(define resource-dir (path->string resource-dir-path))

;; ============================================================
;; 常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define MAX-BUNNIES 80000)
(define MAX-BATCH-ELEMENTS 8192)

;; ============================================================
;; 兔子数据: 并行向量存储（避免每个兔子单独 malloc）
;; ============================================================

(define pos-xs    (make-vector MAX-BUNNIES 0.0))
(define pos-ys    (make-vector MAX-BUNNIES 0.0))
(define speed-xs  (make-vector MAX-BUNNIES 0.0))
(define speed-ys  (make-vector MAX-BUNNIES 0.0))
(define colors    (make-vector MAX-BUNNIES))

(define bunnies-count 0)

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
             "raylib [textures] example - bunnymark")

(define tex-bunny (load-texture (string-append resource-dir "raybunny.png")))
(define tex-w (list-ref tex-bunny 1))
(define tex-h (list-ref tex-bunny 2))

;; ============================================================
;; 主循环
;; ============================================================

(let loop ([paused #f])
  (unless (window-should-close?)
    ;; 更新
    (let* ([paused (if (is-key-pressed KEY-P) (not paused) paused)])

      ;; 按住鼠标左键: 每帧生成 100 只兔子
      (when (is-mouse-button-down MOUSE-BUTTON-LEFT)
        (for ([i (in-range 100)])
          (when (< bunnies-count MAX-BUNNIES)
            (let ([mp (get-mouse-position)])
              (vector-set! pos-xs bunnies-count (vector2-x mp))
              (vector-set! pos-ys bunnies-count (vector2-y mp))
              (vector-set! speed-xs bunnies-count
                           (exact->inexact (get-random-value -250 250)))
              (vector-set! speed-ys bunnies-count
                           (exact->inexact (get-random-value -250 250)))
              (vector-set! colors bunnies-count
                           (color (get-random-value 50 240)
                                  (get-random-value 80 240)
                                  (get-random-value 100 240)
                                  255))
              (set! bunnies-count (add1 bunnies-count))))))

      ;; 更新兔子位置 + 边界反弹
      (unless paused
        (let ([dt (get-frame-time)])
          (for ([i (in-range bunnies-count)])
            (let ([px (vector-ref pos-xs i)]
                  [py (vector-ref pos-ys i)]
                  [sx (vector-ref speed-xs i)]
                  [sy (vector-ref speed-ys i)])
              ;; 移动
              (vector-set! pos-xs i (+ px (* sx dt)))
              (vector-set! pos-ys i (+ py (* sy dt)))
              ;; 水平边界反弹
              (let ([new-px (vector-ref pos-xs i)])
                (when (or (> (+ new-px (/ tex-w 2.0))
                             (get-screen-width))
                          (< (+ new-px (/ tex-w 2.0)) 0.0))
                  (vector-set! speed-xs i (* sx -1.0))))
              ;; 垂直边界反弹
              (let ([new-py (vector-ref pos-ys i)])
                (when (or (> (+ new-py (/ tex-h 2.0))
                             (get-screen-height))
                          (< (- (+ new-py (/ tex-h 2.0)) 40) 0.0))
                  (vector-set! speed-ys i (* sy -1.0))))))))

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)

      (for ([i (in-range bunnies-count)])
        (draw-texture tex-bunny
                      (inexact->exact (round (vector-ref pos-xs i)))
                      (inexact->exact (round (vector-ref pos-ys i)))
                      (vector-ref colors i)))

      (draw-rectangle 0 0 screen-width 40 BLACK)
      (draw-text (format "bunnies: ~a" bunnies-count) 120 10 20 GREEN)
      (draw-text (format "batched draw calls: ~a"
                         (+ 1 (quotient bunnies-count MAX-BATCH-ELEMENTS)))
                 320 10 20 MAROON)
      (draw-fps 10 10)

      (end-drawing)
      (loop paused))))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture tex-bunny)
(close-window)

