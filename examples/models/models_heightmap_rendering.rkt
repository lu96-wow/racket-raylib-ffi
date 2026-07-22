#lang racket/base

;; raylib [models] example - heightmap rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_heightmap_rendering.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(define-runtime-path resource-dir "../../../examples/models/resources/")

(init-window screen-width screen-height
  "raylib [models] example - heightmap rendering")

;; 定义 3D 相机
(define camera (camera3d 18.0 21.0 18.0
                         0.0  0.0  0.0
                         0.0  1.0  0.0
                         45.0 CAMERA-PERSPECTIVE))

;; 加载高度图图像 → 纹理（VRAM）
(define img (load-image (path->string (build-path resource-dir "heightmap.png"))))
(define texture (load-texture-from-image img))

;; 从图像生成高度图网格 → 模型
(define mesh (gen-mesh-heightmap img (vector3 16 8 16)))
(define model (load-model-from-mesh mesh))

;; 给模型设置纹理
(set-material-texture (model-materials model) MATERIAL-MAP-DIFFUSE texture)
(define map-position (vector3 -8.0 0.0 -8.0))

(unload-image img)

;; 纹理尺寸 (Texture2D list: id width height mipmaps format)
(define tex-w (list-ref texture 1))
(define tex-h (list-ref texture 2))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    (update-camera camera CAMERA-ORBITAL)

    ;; ---- Draw ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)
    (draw-model model map-position 1.0 RED)
    (draw-grid 20 1.0)
    (end-mode-3d)

    ;; 右下角高度图纹理预览
    (draw-texture texture (- screen-width tex-w 20) 20 WHITE)
    (draw-rectangle-lines (- screen-width tex-w 20) 20 tex-w tex-h GREEN)

    (draw-fps 10 10)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture texture)
(unload-model model)
(close-window)
