#lang racket/base

;; raylib [textures] example - to image (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_to_image.c
;;
;; 演示: 纹理与图像之间的双向转换
;;   1. LoadImage → LoadTextureFromImage (RAM → VRAM)
;;   2. LoadImageFromTexture (VRAM → RAM)
;;   3. UnloadTexture → LoadTextureFromImage (RAM → VRAM)

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define-runtime-path resource-dir-path
  "../../../examples/textures/resources/")
(define resource-dir (path->string resource-dir-path))

;; ============================================================
;; 资源路径
;; ============================================================

;; ============================================================
;; 常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - to image")

;; NOTE: 纹理必须在窗口初始化后加载（需要 OpenGL 上下文）

;; 步骤 1: 加载图像到 CPU 内存（RAM）
(define image (load-image (string-append resource-dir "raylib_logo.png")))

;; 步骤 2: 图像 → 纹理，上传至 GPU 显存（RAM → VRAM）
(define texture (load-texture-from-image image))

;; 步骤 3: 释放 CPU 内存中的图像
(unload-image image)

;; 步骤 4: 从 GPU 纹理重新加载图像（VRAM → RAM）
(set! image (load-image-from-texture texture))

;; 步骤 5: 释放 GPU 纹理（不再需要）
(unload-texture texture)

;; 步骤 6: 从图像重新创建纹理（RAM → VRAM）
(set! texture (load-texture-from-image image))

;; 步骤 7: 释放 CPU 内存中的图像
(unload-image image)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 将纹理居中绘制
    (let* ([tex-w (list-ref texture 1)]   ;; texture.width
           [tex-h (list-ref texture 2)])  ;; texture.height
      (draw-texture texture
                    (- (quotient screen-width 2) (quotient tex-w 2))
                    (- (quotient screen-height 2) (quotient tex-h 2))
                    WHITE))

    (draw-text "this IS a texture loaded from an image!"
               300 370 10 GRAY)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture texture)
(close-window)
