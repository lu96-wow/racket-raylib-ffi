#lang racket/base

;; raylib [textures] example - logo raylib (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_logo_raylib.c
;;
;; 演示: 最简单的纹理加载与绘制
;;   直接使用 LoadTexture 将图片加载为 GPU 纹理并绘制

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 资源路径
;; ============================================================

(define resource-dir
  (path->string (build-path (current-directory) "../examples/textures/resources/")))

;; ============================================================
;; 常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - logo raylib")

;; NOTE: 纹理必须在窗口初始化后加载（需要 OpenGL 上下文）
(define texture (load-texture (string-append resource-dir "raylib_logo.png")))

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

    (draw-text "this IS a texture!"
               360 370 10 GRAY)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture texture)
(close-window)
