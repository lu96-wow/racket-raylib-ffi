#lang racket/base

;; raylib [models] example - rotating cube (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_rotating_cube.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(define-runtime-path resource-dir "../../../examples/models/resources/")

(init-window screen-width screen-height
  "raylib [models] example - rotating cube")

;; 定义 3D 相机
(define camera (camera3d 0.0 3.0 3.0
                         0.0 0.0 0.0
                         0.0 1.0 0.0
                         45.0 CAMERA-PERSPECTIVE))

;; 生成方块网格 → 模型
(define model (load-model-from-mesh (gen-mesh-cube 1.0 1.0 1.0)))

;; 加载纹理（裁剪 atlas 的右下角 1/4）
(define img (load-image (path->string (build-path resource-dir "cubicmap_atlas.png"))))
(define img-w (list-ref img 1))  ;; Image list: (data width height mipmaps format)
(define img-h (list-ref img 2))
(define crop (image-from-image img (rectangle 0.0 (/ img-h 2.0) (/ img-w 2.0) (/ img-h 2.0))))
(define texture (load-texture-from-image crop))
(unload-image img)
(unload-image crop)

;; 设置材质纹理
(set-material-texture (model-materials model) MATERIAL-MAP-DIFFUSE texture)

(define rotation 0.0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    (set! rotation (+ rotation 1.0))

    ;; ---- Draw ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)

    (draw-model-ex model
                   (vector3 0.0 0.0 0.0)          ;; position
                   (vector3 0.5 1.0 0.0)          ;; rotation axis
                   rotation                       ;; angle
                   (vector3 1.0 1.0 1.0)          ;; scale
                   WHITE)
    (draw-grid 10 1.0)

    (end-mode-3d)

    (draw-fps 10 10)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture texture)
(unload-model model)
(close-window)
