#lang racket/base

;; 隔离：identity vs 居中矩阵，在完全相同的条件下对比
(require "../../raylib/raylib.rkt" racket/runtime-path)

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(define (matrix-translate x y z)
  (list 1.0 0.0 0.0 x  0.0 1.0 0.0 y  0.0 0.0 1.0 z  0.0 0.0 0.0 1.0))

(define (set-model-transform model-list mat-list)
  (append mat-list (list-tail model-list 16)))

(init-window 800 450 "center test: 1=raw 2=identity 3=centered")

;; 加载一个模型，构造三个版本
(define raw (load-model (res "models/vox/chr_knight.vox")))

;; identity 重建（模拟不居中，只重建列表）
(define identity-mat (matrix-translate 0.0 0.0 0.0))
(define id-model (set-model-transform raw identity-mat))

;; 居中重建
(define bb (get-model-bounding-box raw))
(define cx (+ (list-ref bb 0) (/ (- (list-ref bb 3) (list-ref bb 0)) 2.0)))
(define cz (+ (list-ref bb 2) (/ (- (list-ref bb 5) (list-ref bb 2)) 2.0)))
(define centered-mat (matrix-translate (- cx) 0.0 (- cz)))
(define centered (set-model-transform raw centered-mat))

(printf "raw length=~a id length=~a centered length=~a\n"
        (length raw) (length id-model) (length centered))
(printf "centered m12=~a m14=~a\n"
        (list-ref centered 12) (list-ref centered 14))

(define camera (camera3d 10.0 10.0 10.0  0.0 0.0 0.0  0.0 1.0 0.0 45.0 CAMERA-PERSPECTIVE))
(define pos (vector3 0.0 0.0 0.0))
(define mode 0)

(let loop ()
  (unless (window-should-close?)
    (when (is-key-pressed KEY-ONE) (set! mode 0))
    (when (is-key-pressed KEY-TWO) (set! mode 1))
    (when (is-key-pressed KEY-THREE) (set! mode 2))
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (case mode
      [(0) (draw-model raw      pos 1.0 WHITE)]
      [(1) (draw-model id-model pos 1.0 WHITE)]
      [(2) (draw-model centered pos 1.0 WHITE)])
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text (case mode
                 [(0) "1: raw (原始list)"]
                 [(1) "2: identity (重建, m12=0)"]
                 [(2) "3: centered (重建, m12≠0)"])
               10 10 20 BLACK)
    (end-drawing)
    (loop)))

(unload-model raw)
(close-window)
