#lang racket/base

;; raylib [textures] example - image loading (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_image_loading.c
;;
;; 演示: 图像（CPU RAM）与纹理（GPU VRAM）的区别
;;   1. LoadImage 将图片载入 CPU 内存（RAM）
;;   2. LoadTextureFromImage 将图像转为纹理，上传至 GPU 显存（VRAM）
;;   3. UnloadImage 释放 CPU 内存
;;   4. DrawTexture 绘制 GPU 纹理

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
  "raylib [textures] example - image loading")

;; NOTE: 纹理必须在窗口初始化后加载（需要 OpenGL 上下文）

;; 步骤 1: 加载图像到 CPU 内存（RAM）
(define image (load-image (string-append resource-dir "raylib_logo.png")))

;; 步骤 2: 将图像转为纹理，上传至 GPU 显存（VRAM）
(define texture (load-texture-from-image image))

;; 步骤 3: 图像已转为纹理并上传至 VRAM，可以释放 RAM
(unload-image image)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    ;; (无)

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 将纹理居中绘制
    (let* ([tex-w (texture-width texture)]
           [tex-h (texture-height texture)])
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
