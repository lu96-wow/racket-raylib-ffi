#lang racket/base

;; raylib [textures] example - image rotate (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_image_rotate.c
;;
;; 演示: 加载同一图片并旋转不同角度，鼠标左键/→ 切换显示

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 资源路径
;; ============================================================

(define resource-dir
  (path->string (build-path (current-directory) "../../../examples/textures/resources/")))

;; ============================================================
;; 常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define NUM-TEXTURES 3)

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - image rotate")

;; NOTE: 纹理必须在窗口初始化后加载（需要 OpenGL 上下文）
(define image45
  (load-image (string-append resource-dir "raylib_logo.png")))
(define image90
  (load-image (string-append resource-dir "raylib_logo.png")))
(define imageNeg90
  (load-image (string-append resource-dir "raylib_logo.png")))

;; 旋转图像（image-rotate 是函数式调用，返回新列表，需 set! 更新）
(set! image45 (image-rotate image45 45))
(set! image90 (image-rotate image90 90))
(set! imageNeg90 (image-rotate imageNeg90 -90))

;; 从旋转后的图像创建纹理
(define textures
  (vector (load-texture-from-image image45)
          (load-texture-from-image image90)
          (load-texture-from-image imageNeg90)))

(define current-texture 0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (when (or (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
              (is-key-pressed KEY-RIGHT))
      (set! current-texture (modulo (add1 current-texture) NUM-TEXTURES)))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (let* ([tex (vector-ref textures current-texture)]
           [tex-w (list-ref tex 1)]
           [tex-h (list-ref tex 2)])
      (draw-texture tex
                    (- (quotient screen-width 2) (quotient tex-w 2))
                    (- (quotient screen-height 2) (quotient tex-h 2))
                    WHITE))

    (draw-text "Press LEFT MOUSE BUTTON to rotate the image clockwise"
               250 420 10 DARKGRAY)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(for ([tex textures])
  (unload-texture tex))
(close-window)
