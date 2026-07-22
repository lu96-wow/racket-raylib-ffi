#lang racket/base

;; raylib [textures] example - blend modes (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_blend_modes.c
;;
;; 演示: 混合模式
;;   BLEND_ALPHA / BLEND_ADDITIVE / BLEND_MULTIPLIED / BLEND_ADD_COLORS
;;   通过 LoadImage → LoadTextureFromImage → UnloadImage 管线加载纹理

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
  "raylib [textures] example - blend modes")

;; NOTE: 纹理必须在窗口初始化后加载（需要 OpenGL 上下文）
;;
;; LoadImage → LoadTextureFromImage 管线：
;;   Image 加载到 CPU 内存 (RAM)，然后转换为 GPU 纹理 (VRAM)
;;   转换完成后可 UnloadImage 释放 RAM 中的 Image
(define bg-image (load-image (string-append resource-dir "cyberpunk_street_background.png")))
(define bg-texture (load-texture-from-image bg-image))

(define fg-image (load-image (string-append resource-dir "cyberpunk_street_foreground.png")))
(define fg-texture (load-texture-from-image fg-image))

;; 转换为 GPU 纹理后释放 CPU 端 Image
(unload-image bg-image)
(unload-image fg-image)

(define blend-count-max 4)
(define blend-mode 0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ([blend-mode 0])
  (unless (window-should-close?)
    ;; 更新 — 按 SPACE 切换混合模式
    (let ([blend-mode
           (if (is-key-pressed KEY-SPACE)
               (if (>= blend-mode (- blend-count-max 1)) 0 (+ blend-mode 1))
               blend-mode)])

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)

      ;; 绘制背景纹理
      (draw-texture bg-texture
                    (- (quotient screen-width 2) (quotient (list-ref bg-texture 1) 2))
                    (- (quotient screen-height 2) (quotient (list-ref bg-texture 2) 2))
                    WHITE)

      ;; 应用混合模式绘制前景纹理
      (begin-blend-mode blend-mode)
      (draw-texture fg-texture
                    (- (quotient screen-width 2) (quotient (list-ref fg-texture 1) 2))
                    (- (quotient screen-height 2) (quotient (list-ref fg-texture 2) 2))
                    WHITE)
      (end-blend-mode)

      ;; 绘制提示文字
      (draw-text "Press SPACE to change blend modes." 310 350 10 GRAY)

      (cond [(= blend-mode BLEND-ALPHA)      (draw-text "Current: BLEND_ALPHA"      (- (quotient screen-width 2) 60) 370 10 GRAY)]
            [(= blend-mode BLEND-ADDITIVE)   (draw-text "Current: BLEND_ADDITIVE"   (- (quotient screen-width 2) 60) 370 10 GRAY)]
            [(= blend-mode BLEND-MULTIPLIED) (draw-text "Current: BLEND_MULTIPLIED" (- (quotient screen-width 2) 60) 370 10 GRAY)]
            [(= blend-mode BLEND-ADD-COLORS) (draw-text "Current: BLEND_ADD_COLORS" (- (quotient screen-width 2) 60) 370 10 GRAY)])

      (draw-text "(c) Cyberpunk Street Environment by Luis Zuno (@ansimuz)"
                 (- screen-width 330) (- screen-height 20) 10 GRAY)

      (end-drawing)
      (loop blend-mode))))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture fg-texture)
(unload-texture bg-texture)
(close-window)
