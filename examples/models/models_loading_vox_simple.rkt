#lang racket/base

;; 最简 VOX — 只加载模型，默认着色器，默认位置
(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "VOX simple")
(define camera (camera3d 10.0 10.0 10.0  0.0 0.0 0.0  0.0 1.0 0.0 45.0 CAMERA-PERSPECTIVE))

;; 居中辅助
;; C Matrix 字段顺序: m0,m4,m8,m12, m1,m5,m9,m13, m2,m6,m10,m14, m3,m7,m11,m15
(define (matrix-translate x y z)
  (list 1.0 0.0 0.0 x  0.0 1.0 0.0 y  0.0 0.0 1.0 z  0.0 0.0 0.0 1.0))
(define (set-model-transform model-list mat-list)
  (append mat-list (list-tail model-list 16)))

(define vox-files
  (vector (res "models/vox/chr_knight.vox")
          (res "models/vox/chr_sword.vox")
          (res "models/vox/monu9.vox")
          (res "models/vox/fez.vox")))
(define models (make-vector 4))
(for ([i 4])
  (let* ([m  (load-model (vector-ref vox-files i))]
         [bb (get-model-bounding-box m)]
         [cx (+ (list-ref bb 0) (/ (- (list-ref bb 3) (list-ref bb 0)) 2.0))]
         [cz (+ (list-ref bb 2) (/ (- (list-ref bb 5) (list-ref bb 2)) 2.0))])
    (vector-set! models i (set-model-transform m (matrix-translate (- cx) 0.0 (- cz))))))

(define pos (vector3 0.0 0.0 0.0))
(define current 0)

(let loop ()
  (unless (window-should-close?)
    (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
      (set! current (modulo (add1 current) 4)))
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (draw-model (vector-ref models current) pos 1.0 WHITE)
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text (format "VOX [~a] ~a" current (get-file-name (vector-ref vox-files current)))
               10 10 20 BLACK)
    (end-drawing)
    (loop)))

(for ([i 4]) (unload-model (vector-ref models i)))
(close-window)
