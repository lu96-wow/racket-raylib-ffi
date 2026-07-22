#lang racket/base

;; raylib [textures] example - magnifying glass (Racket FFI 翻译)
;; 对应 C: examples/textures/textures_magnifying_glass.c
;; 演示: 放大镜效果 (RenderTexture + Camera2D + 遮罩)

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (prefix-in T: "../../raylib/types.rkt"))

(define-runtime-path resource-dir-path "../../../examples/textures/resources/")
(define resource-dir (path->string resource-dir-path))

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
             "raylib [textures] example - magnifying glass")

;; 加载纹理
(define bunny (load-texture (string-append resource-dir "raybunny.png")))
(define parrots (load-texture (string-append resource-dir "parrots.png")))

;; 用图像绘制生成圆形遮罩
(define circle-img (gen-image-color 256 256 BLANK))
(let ([ptr (malloc T:_Image 'atomic)])
  (ptr-set! ptr _pointer 0 (list-ref circle-img 0))
  (ptr-set! ptr _int 2 (list-ref circle-img 1))
  (ptr-set! ptr _int 3 (list-ref circle-img 2))
  (ptr-set! ptr _int 4 (list-ref circle-img 3))
  (ptr-set! ptr _int 5 (list-ref circle-img 4))
  (image-draw-circle ptr 128 128 128 WHITE))
(define mask (load-texture-from-image circle-img))
(unload-image circle-img)

;; 放大镜 RenderTexture
(define magnified-world (load-render-texture 256 256))

;; 放大镜相机 (zoom=2, offset=128,128)
(define camera (camera2d 128.0 128.0 0.0 0.0 0.0 2.0))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (let* ([m-pos (get-mouse-position)]
           [mx (vector2-x m-pos)]
           [my (vector2-y m-pos)])

      ;; 更新相机目标到鼠标位置
      (set-camera2d-target-x! camera mx)
      (set-camera2d-target-y! camera my)

      (begin-drawing)
      (clear-background RAYWHITE)

      ;; 正常世界
      (draw-texture parrots 144 33 WHITE)
      (draw-text "Use the magnifying glass to find hidden bunnies!"
                 154 6 20 BLACK)

      ;; 渲染到放大镜
      (begin-texture-mode magnified-world)
      (clear-background RAYWHITE)
      (begin-mode-2d camera)
      (draw-texture parrots 144 33 WHITE)
      (draw-text "Use the magnifying glass to find hidden bunnies!"
                 154 6 20 BLACK)
      ;; 隐藏的兔子 (仅在放大镜中可见，用 BLEND_MULTIPLIED 融入背景)
      (begin-blend-mode BLEND-MULTIPLIED)
      (draw-texture bunny 250 350 WHITE)
      (draw-texture bunny 500 100 WHITE)
      (draw-texture bunny 420 300 WHITE)
      (draw-texture bunny 650 10 WHITE)
      (end-blend-mode)
      (end-mode-2d)

      ;; 圆形遮罩 (自定义混合: 只传递 alpha 通道)
      (begin-blend-mode BLEND-CUSTOM-SEPARATE)
      (rl-set-blend-factors-separate RL-ZERO RL-ONE RL-ONE RL-ZERO
                                      RL-FUNC-ADD RL-FUNC-ADD)
      (draw-texture mask 0 0 WHITE)
      (end-blend-mode)
      (end-texture-mode)

      ;; 将放大镜 RenderTexture 绘制到屏幕 (居中于鼠标)
      (let ([tex (list (list-ref magnified-world 1) (list-ref magnified-world 2)
                       (list-ref magnified-world 3) (list-ref magnified-world 4)
                       (list-ref magnified-world 5))])
        (draw-texture-rec tex
          (rectangle 0.0 0.0 256.0 -256.0)
          (vector2 (- mx 128) (- my 128)) WHITE))

      ;; 放大镜外框
      (draw-ring m-pos 126.0 130.0 0.0 360.0 64 BLACK)

      ;; 高光
      (let ([rx (/ mx screen-width)]
            [ry (/ my screen-width)])
        (draw-circle (inexact->exact (round (- mx (* 64 rx) 32)))
                     (inexact->exact (round (- my (* 64 ry) 32)))
                     4.0 (color-alpha WHITE 0.5)))

      (end-drawing)
      (loop))))

(unload-texture parrots)
(unload-texture bunny)
(unload-texture mask)
(unload-render-texture magnified-world)
(close-window)
