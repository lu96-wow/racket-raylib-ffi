#lang racket/base

;; raylib [textures] example - image generation (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_image_generation.c
;;
;; 演示: 程序化图像生成
;;   GenImageGradientLinear / GenImageGradientRadial / GenImageGradientSquare
;;   GenImageChecked / GenImageWhiteNoise / GenImagePerlinNoise / GenImageCellular

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define num-textures 9)

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - image generation")

;; 生成各种程序化图像 (Image 存在于 CPU RAM)
(define vertical-gradient (gen-image-gradient-linear screen-width screen-height 0 RED BLUE))
(define horizontal-gradient (gen-image-gradient-linear screen-width screen-height 90 RED BLUE))
(define diagonal-gradient (gen-image-gradient-linear screen-width screen-height 45 RED BLUE))
(define radial-gradient (gen-image-gradient-radial screen-width screen-height 0.0 WHITE BLACK))
(define square-gradient (gen-image-gradient-square screen-width screen-height 0.0 WHITE BLACK))
(define checked (gen-image-checked screen-width screen-height 32 32 RED BLUE))
(define white-noise (gen-image-white-noise screen-width screen-height 0.5))
(define perlin-noise (gen-image-perlin-noise screen-width screen-height 50 50 4.0))
(define cellular (gen-image-cellular screen-width screen-height 32))

;; 转换为 GPU 纹理 (VRAM)
(define textures
  (list (load-texture-from-image vertical-gradient)
        (load-texture-from-image horizontal-gradient)
        (load-texture-from-image diagonal-gradient)
        (load-texture-from-image radial-gradient)
        (load-texture-from-image square-gradient)
        (load-texture-from-image checked)
        (load-texture-from-image white-noise)
        (load-texture-from-image perlin-noise)
        (load-texture-from-image cellular)))

;; 释放 CPU 端 Image 数据
(unload-image vertical-gradient)
(unload-image horizontal-gradient)
(unload-image diagonal-gradient)
(unload-image radial-gradient)
(unload-image square-gradient)
(unload-image checked)
(unload-image white-noise)
(unload-image perlin-noise)
(unload-image cellular)

(set-target-fps 60)

;; 纹理名称列表
(define texture-names
  '("VERTICAL GRADIENT" "HORIZONTAL GRADIENT" "DIAGONAL GRADIENT"
    "RADIAL GRADIENT"   "SQUARE GRADIENT"    "CHECKED"
    "WHITE NOISE"       "PERLIN NOISE"        "CELLULAR"))

;; ============================================================
;; 主循环
;; ============================================================

(let loop ([current-texture 0])
  (unless (window-should-close?)
    ;; 更新 — 鼠标左键或右箭头键切换纹理
    (let ([current-texture
           (if (or (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
                   (is-key-pressed KEY-RIGHT))
               (modulo (+ current-texture 1) num-textures)
               current-texture)])

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)

      ;; 绘制当前纹理
      (draw-texture (list-ref textures current-texture) 0 0 WHITE)

      ;; 绘制提示
      (draw-rectangle 30 400 325 30 (fade SKYBLUE 0.5))
      (draw-rectangle-lines 30 400 325 30 (fade WHITE 0.5))
      (draw-text "MOUSE LEFT BUTTON to CYCLE PROCEDURAL TEXTURES" 40 410 10 WHITE)

      ;; 显示当前纹理名称
      (draw-text (list-ref texture-names current-texture)
                 (- screen-width (* (string-length (list-ref texture-names current-texture)) 10) 40)
                 10 20 RAYWHITE)

      (end-drawing)
      (loop current-texture))))

;; ============================================================
;; 清理
;; ============================================================

(for-each unload-texture textures)
(close-window)
