#lang racket/base

;; 最简测试：只用默认着色器，不做任何自定义
(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "bare minimum")

(define model (load-model (res "models/vox/chr_knight.vox")))
(printf "model loaded, meshCount=~a\n" (list-ref model 16))

(define camera (camera3d 10.0 10.0 10.0  0.0 0.0 0.0  0.0 1.0 0.0 45.0 CAMERA-PERSPECTIVE))
(define pos (vector3 0.0 0.0 0.0))

(let loop ()
  (unless (window-should-close?)
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (draw-model model pos 1.0 WHITE)
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text "bare: model + default shader" 10 10 20 BLACK)
    (end-drawing)
    (loop)))

(unload-model model)
(close-window)
