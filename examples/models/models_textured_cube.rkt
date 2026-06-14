#lang racket/base

;; raylib [models] example - textured cube (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_textured_cube.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

;; ============================================================
;; 自定义函数: DrawCubeTexture — 用 RLGL 即时模式绘制带纹理的方块
;; ============================================================

(define (draw-cube-texture texture position w h l color)
  (define x (vector3-x position))
  (define y (vector3-y position))
  (define z (vector3-z position))
  (define tex-id (list-ref texture 0)) ; Texture2D: (id width height mipmaps format)

  (rl-set-texture tex-id)
  (rl-begin RL-QUADS)
  (rl-color-4ub (color-r color) (color-g color) (color-b color) (color-a color))
  ;; Front Face
  (rl-normal-3f 0.0  0.0  1.0)
  (rl-tex-coord-2f 0.0 0.0) (rl-vertex-3f (- x (/ w 2.0)) (- y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f 1.0 0.0) (rl-vertex-3f (+ x (/ w 2.0)) (- y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f 1.0 1.0) (rl-vertex-3f (+ x (/ w 2.0)) (+ y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f 0.0 1.0) (rl-vertex-3f (- x (/ w 2.0)) (+ y (/ h 2.0)) (+ z (/ l 2.0)))
  ;; Back Face
  (rl-normal-3f  0.0  0.0 -1.0)
  (rl-tex-coord-2f 1.0 0.0) (rl-vertex-3f (- x (/ w 2.0)) (- y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f 1.0 1.0) (rl-vertex-3f (- x (/ w 2.0)) (+ y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f 0.0 1.0) (rl-vertex-3f (+ x (/ w 2.0)) (+ y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f 0.0 0.0) (rl-vertex-3f (+ x (/ w 2.0)) (- y (/ h 2.0)) (- z (/ l 2.0)))
  ;; Top Face
  (rl-normal-3f  0.0  1.0  0.0)
  (rl-tex-coord-2f 0.0 1.0) (rl-vertex-3f (- x (/ w 2.0)) (+ y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f 0.0 0.0) (rl-vertex-3f (- x (/ w 2.0)) (+ y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f 1.0 0.0) (rl-vertex-3f (+ x (/ w 2.0)) (+ y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f 1.0 1.0) (rl-vertex-3f (+ x (/ w 2.0)) (+ y (/ h 2.0)) (- z (/ l 2.0)))
  ;; Bottom Face
  (rl-normal-3f  0.0 -1.0  0.0)
  (rl-tex-coord-2f 1.0 1.0) (rl-vertex-3f (- x (/ w 2.0)) (- y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f 0.0 1.0) (rl-vertex-3f (+ x (/ w 2.0)) (- y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f 0.0 0.0) (rl-vertex-3f (+ x (/ w 2.0)) (- y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f 1.0 0.0) (rl-vertex-3f (- x (/ w 2.0)) (- y (/ h 2.0)) (+ z (/ l 2.0)))
  ;; Right Face
  (rl-normal-3f  1.0  0.0  0.0)
  (rl-tex-coord-2f 1.0 0.0) (rl-vertex-3f (+ x (/ w 2.0)) (- y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f 1.0 1.0) (rl-vertex-3f (+ x (/ w 2.0)) (+ y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f 0.0 1.0) (rl-vertex-3f (+ x (/ w 2.0)) (+ y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f 0.0 0.0) (rl-vertex-3f (+ x (/ w 2.0)) (- y (/ h 2.0)) (+ z (/ l 2.0)))
  ;; Left Face
  (rl-normal-3f -1.0  0.0  0.0)
  (rl-tex-coord-2f 0.0 0.0) (rl-vertex-3f (- x (/ w 2.0)) (- y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f 1.0 0.0) (rl-vertex-3f (- x (/ w 2.0)) (- y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f 1.0 1.0) (rl-vertex-3f (- x (/ w 2.0)) (+ y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f 0.0 1.0) (rl-vertex-3f (- x (/ w 2.0)) (+ y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-end)
  (rl-set-texture 0))


;; ============================================================
;; 自定义函数: DrawCubeTextureRec — 只用纹理的一部分来绘制方块
;; ============================================================

(define (draw-cube-texture-rec texture source position w h l color)
  (define x (vector3-x position))
  (define y (vector3-y position))
  (define z (vector3-z position))
  (define tex-id (list-ref texture 0))
  (define tex-w (exact->inexact (list-ref texture 1)))
  (define tex-h (exact->inexact (list-ref texture 2)))
  (define src-x (rectangle-x source))
  (define src-y (rectangle-y source))
  (define src-w (rectangle-w source))
  (define src-h (rectangle-h source))

  ;; Normalized texture coordinates
  (define u0 (/ src-x tex-w))
  (define u1 (/ (+ src-x src-w) tex-w))
  (define v0 (/ src-y tex-h))
  (define v1 (/ (+ src-y src-h) tex-h))

  (rl-set-texture tex-id)
  (rl-begin RL-QUADS)
  (rl-color-4ub (color-r color) (color-g color) (color-b color) (color-a color))
  ;; Front face
  (rl-normal-3f  0.0  0.0  1.0)
  (rl-tex-coord-2f u0 v1) (rl-vertex-3f (- x (/ w 2.0)) (- y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f u1 v1) (rl-vertex-3f (+ x (/ w 2.0)) (- y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f u1 v0) (rl-vertex-3f (+ x (/ w 2.0)) (+ y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f u0 v0) (rl-vertex-3f (- x (/ w 2.0)) (+ y (/ h 2.0)) (+ z (/ l 2.0)))
  ;; Back face
  (rl-normal-3f  0.0  0.0 -1.0)
  (rl-tex-coord-2f u1 v1) (rl-vertex-3f (- x (/ w 2.0)) (- y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f u1 v0) (rl-vertex-3f (- x (/ w 2.0)) (+ y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f u0 v0) (rl-vertex-3f (+ x (/ w 2.0)) (+ y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f u0 v1) (rl-vertex-3f (+ x (/ w 2.0)) (- y (/ h 2.0)) (- z (/ l 2.0)))
  ;; Top face
  (rl-normal-3f  0.0  1.0  0.0)
  (rl-tex-coord-2f u0 v0) (rl-vertex-3f (- x (/ w 2.0)) (+ y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f u0 v1) (rl-vertex-3f (- x (/ w 2.0)) (+ y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f u1 v1) (rl-vertex-3f (+ x (/ w 2.0)) (+ y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f u1 v0) (rl-vertex-3f (+ x (/ w 2.0)) (+ y (/ h 2.0)) (- z (/ l 2.0)))
  ;; Bottom face
  (rl-normal-3f  0.0 -1.0  0.0)
  (rl-tex-coord-2f u1 v0) (rl-vertex-3f (- x (/ w 2.0)) (- y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f u0 v0) (rl-vertex-3f (+ x (/ w 2.0)) (- y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f u0 v1) (rl-vertex-3f (+ x (/ w 2.0)) (- y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f u1 v1) (rl-vertex-3f (- x (/ w 2.0)) (- y (/ h 2.0)) (+ z (/ l 2.0)))
  ;; Right face
  (rl-normal-3f  1.0  0.0  0.0)
  (rl-tex-coord-2f u1 v1) (rl-vertex-3f (+ x (/ w 2.0)) (- y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f u1 v0) (rl-vertex-3f (+ x (/ w 2.0)) (+ y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f u0 v0) (rl-vertex-3f (+ x (/ w 2.0)) (+ y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f u0 v1) (rl-vertex-3f (+ x (/ w 2.0)) (- y (/ h 2.0)) (+ z (/ l 2.0)))
  ;; Left face
  (rl-normal-3f -1.0  0.0  0.0)
  (rl-tex-coord-2f u0 v1) (rl-vertex-3f (- x (/ w 2.0)) (- y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-tex-coord-2f u1 v1) (rl-vertex-3f (- x (/ w 2.0)) (- y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f u1 v0) (rl-vertex-3f (- x (/ w 2.0)) (+ y (/ h 2.0)) (+ z (/ l 2.0)))
  (rl-tex-coord-2f u0 v0) (rl-vertex-3f (- x (/ w 2.0)) (+ y (/ h 2.0)) (- z (/ l 2.0)))
  (rl-end)
  (rl-set-texture 0))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(define-runtime-path resource-dir "../../../examples/models/resources/")

(init-window screen-width screen-height
  "raylib [models] example - textured cube")

;; 定义 3D 相机
(define camera (camera3d 0.0 10.0 10.0
                         0.0  0.0  0.0
                         0.0  1.0  0.0
                         45.0 CAMERA-PERSPECTIVE))

;; 加载纹理（Texture2D list: (id width height mipmaps format)）
(define texture (load-texture (path->string (build-path resource-dir "cubicmap_atlas.png"))))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----

    ;; ---- Draw ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)

    ;; 左: 带纹理的方块 (2宽 × 4高 × 2深)
    (draw-cube-texture texture
                       (vector3 -2.0 2.0 0.0)
                       2.0 4.0 2.0 WHITE)

    ;; 右: 使用纹理的右下角 1/4 区域绘制的方块
    (draw-cube-texture-rec texture
                           (rectangle 0.0 (/ (list-ref texture 2) 2.0)
                                      (/ (list-ref texture 1) 2.0)
                                      (/ (list-ref texture 2) 2.0))
                           (vector3 2.0 1.0 0.0)
                           2.0 2.0 2.0 WHITE)

    (draw-grid 10 1.0)

    (end-mode-3d)

    (draw-fps 10 10)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture texture)
(close-window)
