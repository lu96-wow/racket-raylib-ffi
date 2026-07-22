#lang racket/base

;; raylib [core] example - render texture (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_render_texture.c
;;
;; 演示: 使用 RenderTexture 离屏渲染一个弹跳球,
;;       然后旋转绘制到主屏幕
;;
;; 复杂度: [★☆☆☆] 1/4

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)

(define RENDER-TEX-WIDTH  300)
(define RENDER-TEX-HEIGHT 300)

;; ============================================================
;; 辅助: 从 RenderTexture 列表提取 Texture 子列表 (5 元素)
;; RenderTexture 布局: (id tex-id tex-w tex-h tex-mip tex-fmt
;;                         dep-id dep-w dep-h dep-mip dep-fmt)
;; Texture 布局:       (id   w      h     mip    fmt)
;; ============================================================

(define (rt->texture rt)
  (list (render-texture-tex-id rt) (render-texture-tex-width rt) (render-texture-tex-height rt) (render-texture-tex-mipmaps rt) (render-texture-tex-format rt)))

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - render texture")

;; 加载渲染纹理 (离屏绘制目标)
(define target (load-render-texture RENDER-TEX-WIDTH RENDER-TEX-HEIGHT))

;; 球的位置和速度 (用 Vector2 指针)
(define ball-position
  (vector2 (/ RENDER-TEX-WIDTH 2.0) (/ RENDER-TEX-HEIGHT 2.0)))
(define ball-speed (vector2 5.0 4.0))
(define BALL-RADIUS 20)

(define rotation 0.0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let game-loop ()
  (unless (window-should-close?)
    ;; === 更新 ===

    ;; 球移动
    (set-vector2-x! ball-position
      (+ (vector2-x ball-position) (vector2-x ball-speed)))
    (set-vector2-y! ball-position
      (+ (vector2-y ball-position) (vector2-y ball-speed)))

    ;; 墙壁碰撞检测 (反弹)
    (when (or (>= (vector2-x ball-position) (- RENDER-TEX-WIDTH BALL-RADIUS))
              (<= (vector2-x ball-position) BALL-RADIUS))
      (set-vector2-x! ball-speed (* -1 (vector2-x ball-speed))))
    (when (or (>= (vector2-y ball-position) (- RENDER-TEX-HEIGHT BALL-RADIUS))
              (<= (vector2-y ball-position) BALL-RADIUS))
      (set-vector2-y! ball-speed (* -1 (vector2-y ball-speed))))

    ;; 旋转角度递增
    (set! rotation (+ rotation 0.5))

    ;; === 离屏绘制: 渲染到纹理 ===
    (begin-texture-mode target)
    (clear-background SKYBLUE)

    ;; 在纹理左上角画一个红色方块
    (draw-rectangle 0 0 20 20 RED)
    ;; 在纹理中间画弹跳球
    (draw-circle-v ball-position (exact->inexact BALL-RADIUS) MAROON)

    (end-texture-mode)

    ;; === 主屏绘制 ===
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 从 RenderTexture 中提取 Texture (5 元素列表)
    (define tex (rt->texture target))

    ;; 源矩形: (0, 0, tex-w, -tex-h) — height 为负 = OpenGL 上下翻转
    (define source-rec
      (rectangle 0.0 0.0
        (exact->inexact (render-texture-tex-width target))           ;; tex-width
        (exact->inexact (* -1 (render-texture-tex-height target)))))  ;; -tex-height

    ;; 目标矩形: 屏幕居中, 保持纹理原始大小
    (define dest-rec
      (rectangle
        (exact->inexact (/ SCREEN-WIDTH 2.0))
        (exact->inexact (/ SCREEN-HEIGHT 2.0))
        (exact->inexact (render-texture-tex-width target))           ;; tex-width
        (exact->inexact (render-texture-tex-height target))))         ;; tex-height

    ;; 原点: 纹理中心 (用于旋转锚点)
    (define origin
      (vector2 (/ (render-texture-tex-width target) 2.0)
               (/ (render-texture-tex-height target) 2.0)))

    ;; 带旋转绘制纹理
    (draw-texture-pro tex source-rec dest-rec origin rotation WHITE)

    (draw-text "DRAWING BOUNCING BALL INSIDE RENDER TEXTURE!"
      10 (- SCREEN-HEIGHT 40) 20 BLACK)
    (draw-fps 10 10)

    (end-drawing)

    (game-loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-render-texture target)
(close-window)
