#lang racket/base

;; 测试: list struct 的列表能否被复用
(require "../../raylib/raylib.rkt"
         racket/runtime-path
         (only-in ffi/unsafe malloc))

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "list test")

(define m (load-model (res "models/vox/chr_knight.vox")))
(printf "m length = ~a, list? = ~a\n" (length m) (list? m))

;; 测试1: list-tail
(define tail (list-tail m 16))
(printf "tail length = ~a, list? = ~a\n" (length tail) (list? tail))

;; 测试2: append
(define mat (list 1.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0 1.0))
(define m2 (append mat tail))
(printf "m2 length = ~a, list? = ~a\n" (length m2) (list? m2))
(printf "m2[19] = ~a, m[19] = ~a, equal? = ~a\n" (list-ref m2 19) (list-ref m 19) (equal? (list-ref m2 19) (list-ref m 19)))

;; 测试3: 直接用 index 拼接
(define m3
  (list* 1.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0 1.0
         (list-ref m 16) (list-ref m 17) (list-ref m 18) (list-ref m 19)
         (list-ref m 20) (list-ref m 21) (list-ref m 22)
         (list-ref m 23) (list-ref m 24) (list-ref m 25)
         (list-ref m 26) '()))
(printf "m3 length = ~a, list? = ~a\n" (length m3) (list? m3))

;; 测试4: 给 m 赋红色 shader，作为基准
(define shader (load-shader
                (res "shaders/glsl330/voxel_lighting.vs")
                (res "shaders/glsl330/voxel_lighting.fs")))
(set-shader-value shader (get-shader-location shader "ambient")
                  (malloc-float-vec4 2.0 0.0 0.0 1.0) SHADER-UNIFORM-VEC4)
(for ([j (in-range (list-ref m 17))])
  (set-material-shader (ptr-add (list-ref m 19) (* j 40)) shader))

;; m2 和 m3 共享材质指针，已赋着色器

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
      [(0) (draw-model m  pos 1.0 WHITE)]   ;; 原始
      [(1) (draw-model m2 pos 1.0 WHITE)]   ;; append
      [(2) (draw-model m3 pos 1.0 WHITE)])  ;; list*
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text (case mode [(0) "1:原始"][(1) "2:append"][(2) "3:list*"]) 10 10 20 BLACK)
    (end-drawing)
    (loop)))

(unload-model m)
(close-window)
