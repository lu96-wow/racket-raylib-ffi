#lang racket/base

;; 逐个排查 transform 值
(require "../../raylib/raylib.rkt" racket/runtime-path)

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(define (set-model-transform model-list mat-list)
  (append mat-list (list-tail model-list 16)))

(init-window 800 450 "transform test")

(define raw (load-model (res "models/vox/chr_knight.vox")))
(define camera (camera3d 10.0 10.0 10.0  0.0 0.0 0.0  0.0 1.0 0.0 45.0 CAMERA-PERSPECTIVE))
(define pos (vector3 0.0 0.0 0.0))
(define mode 0)

;; 构建不同 transform 的模型
(define (mk-model x y z)
;; C Matrix 字段顺序: m0,m4,m8,m12, m1,m5,m9,m13, m2,m6,m10,m14, m3,m7,m11,m15
  (set-model-transform raw
    (list 1.0 0.0 0.0 x  0.0 1.0 0.0 y  0.0 0.0 1.0 z  0.0 0.0 0.0 1.0)))

(define m-id     (mk-model  0.0  0.0  0.0))  ;; 对照：应可见
(define m-x     (mk-model -2.25 0.0  0.0))  ;; 只改 x
(define m-z     (mk-model  0.0  0.0 -5.25)) ;; 只改 z
(define m-xz    (mk-model -2.25 0.0 -5.25)) ;; 改 x+z（原居中）

(let loop ()
  (unless (window-should-close?)
    (when (is-key-pressed KEY-ONE)   (set! mode 0))
    (when (is-key-pressed KEY-TWO)   (set! mode 1))
    (when (is-key-pressed KEY-THREE) (set! mode 2))
    (when (is-key-pressed KEY-FOUR)  (set! mode 3))
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (case mode
      [(0) (draw-model m-id pos 1.0 WHITE)]
      [(1) (draw-model m-x  pos 1.0 WHITE)]
      [(2) (draw-model m-z  pos 1.0 WHITE)]
      [(3) (draw-model m-xz pos 1.0 WHITE)])
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text (case mode
                 [(0) "1: ident (可见)"]
                 [(1) "2: m12=-2.25"]
                 [(2) "3: m14=-5.25"]
                 [(3) "4: m12+m14"])
               10 10 20 BLACK)
    (end-drawing)
    (loop)))

(unload-model raw)
(close-window)
