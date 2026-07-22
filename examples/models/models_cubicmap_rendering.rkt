#lang racket/base

;; raylib [models] example - cubicmap rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_cubicmap_rendering.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

;; 资源目录
(define-runtime-path resource-dir "../../../examples/models/resources/")

(init-window screen-width screen-height
  "raylib [models] example - cubicmap rendering")

;; 定义 3D 相机
(define camera (camera3d 16.0 14.0 16.0
                         0.0  0.0  0.0
                         0.0  1.0  0.0
                         45.0 CAMERA-PERSPECTIVE))

;; 加载 cubicmap 图像 → 纹理（用于 UI 显示）
(define img (load-image (path->string (build-path resource-dir "cubicmap.png"))))
(define cubicmap (load-texture-from-image img))

;; 从图像生成 cubicmap 网格 → 模型
(define mesh (gen-mesh-cubicmap img (vector3 1.0 1.0 1.0)))
(define model (load-model-from-mesh mesh))

;; 给模型设置纹理
(define atlas (load-texture (path->string (build-path resource-dir "cubicmap_atlas.png"))))
(set-material-texture (model-materials model) MATERIAL-MAP-DIFFUSE atlas)  ;; index 19 = materials

(define map-position (vector3 -16.0 0.0 -8.0))

(unload-image img)  ;; 图像已上传 VRAM，可释放

(define pause #f)

;; 纹理尺寸 (Texture2D list: id width height mipmaps format)
(define cmap-w (image-width cubicmap))
(define cmap-h (image-height cubicmap))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    (when (is-key-pressed KEY-P) (set! pause (not pause)))
    (unless pause (update-camera camera CAMERA-ORBITAL))

    ;; ---- Draw ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)
    (draw-model model map-position 1.0 WHITE)
    (end-mode-3d)

    ;; 右下角显示 cubicmap 纹理预览
    (draw-texture-ex cubicmap
                     (vector2 (- screen-width (* cmap-w 4.0) 20) 20.0)
                     0.0 4.0 WHITE)
    (draw-rectangle-lines (- screen-width (* cmap-w 4) 20) 20
                          (* cmap-w 4) (* cmap-h 4) GREEN)

    (draw-text "cubicmap image used to" 658 90 10 GRAY)
    (draw-text "generate map 3d model" 658 104 10 GRAY)

    (draw-fps 10 10)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture cubicmap)
(unload-texture atlas)
(unload-model model)
(close-window)
