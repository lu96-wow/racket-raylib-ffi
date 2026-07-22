#lang racket/base

;; raylib [textures] example - background scrolling (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_background_scrolling.c
;;
;; 演示: 视差背景滚动
;;   使用多层纹理以不同速度水平滚动实现视差滚动效果

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
  "raylib [textures] example - background scrolling")

;; NOTE: 背景纹理宽度必须 >= 屏幕宽度，否则需要绘制超过两次来实现滚动
(define background (load-texture (string-append resource-dir "cyberpunk_street_background.png")))
(define midground (load-texture (string-append resource-dir "cyberpunk_street_midground.png")))
(define foreground (load-texture (string-append resource-dir "cyberpunk_street_foreground.png")))

;; 背景色: #052c46ff → r=#x05, g=#x2c, b=#x46, a=#xff
(define bg-color (color #x05 #x2c #x46 #xff))

(set-target-fps 60)

;; Texture2D 是 5 元素列表: (id width height mipmaps format)
(define (texture-width tex) (list-ref tex 1))

;; ============================================================
;; 主循环
;; ============================================================

(let loop ([scrolling-back 0.0]
           [scrolling-mid 0.0]
           [scrolling-fore 0.0])
  (unless (window-should-close?)
    ;; 更新
    (let* ([scrolling-back (- scrolling-back 0.1)]
           [scrolling-mid (- scrolling-mid 0.5)]
           [scrolling-fore (- scrolling-fore 1.0)]
           ;; 循环重置（纹理被缩放2倍，所以宽度*2即为一个完整周期）
           [back-w (* (texture-width background) 2.0)]
           [mid-w  (* (texture-width midground) 2.0)]
           [fore-w (* (texture-width foreground) 2.0)]
           [scrolling-back (if (<= scrolling-back (- back-w)) 0.0 scrolling-back)]
           [scrolling-mid  (if (<= scrolling-mid  (- mid-w))  0.0 scrolling-mid)]
           [scrolling-fore (if (<= scrolling-fore (- fore-w)) 0.0 scrolling-fore)])

      ;; 绘制
      (begin-drawing)
      (clear-background bg-color)

      ;; 绘制背景图像两次（水平平铺实现无缝循环）
      (draw-texture-ex background
                       (vector2 scrolling-back 20.0)
                       0.0 2.0 WHITE)
      (draw-texture-ex background
                       (vector2 (+ back-w scrolling-back) 20.0)
                       0.0 2.0 WHITE)

      ;; 绘制中景图像两次
      (draw-texture-ex midground
                       (vector2 scrolling-mid 20.0)
                       0.0 2.0 WHITE)
      (draw-texture-ex midground
                       (vector2 (+ mid-w scrolling-mid) 20.0)
                       0.0 2.0 WHITE)

      ;; 绘制前景图像两次
      (draw-texture-ex foreground
                       (vector2 scrolling-fore 70.0)
                       0.0 2.0 WHITE)
      (draw-texture-ex foreground
                       (vector2 (+ fore-w scrolling-fore) 70.0)
                       0.0 2.0 WHITE)

      (draw-text "BACKGROUND SCROLLING & PARALLAX"
                 10 10 20 RED)
      (draw-text "(c) Cyberpunk Street Environment by Luis Zuno (@ansimuz)"
                 (- screen-width 330) (- screen-height 20) 10 RAYWHITE)

      (end-drawing)
      (loop scrolling-back scrolling-mid scrolling-fore))))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture background)
(unload-texture midground)
(unload-texture foreground)
(close-window)
