#lang racket/base

;; raylib [textures] example - screen buffer (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_screen_buffer.c
;;
;; 演示: 使用 Racket 字节缓冲区模拟火焰效果，直接写入 Image.data 指针
;; 替代 C 的 RL_CALLOC/ImageDrawPixel，避免每帧 90k 次 FFI 调用
;;
;; 差异: C 用 ImageDrawPixel 逐像素绘制，本版直接 ptr-set! 写 RGBA8 像素数据

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define MAX-COLORS    256)
(define SCALE-FACTOR   2)
(define screen-width  800)
(define screen-height 450)

(define image-width   (quotient screen-width SCALE-FACTOR))   ; 400
(define image-height  (quotient screen-height SCALE-FACTOR))  ; 225
(define flame-width   image-width)                             ; 400

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - screen buffer")

;; ---- 生成火焰调色板 ----
;; 预提取 RGBA 字节到 vector，避免热循环中的 ptr-ref 调用
(define palette
  (for/vector ([i (in-range MAX-COLORS)])
    (let* ([t (exact->inexact (/ i (sub1 MAX-COLORS)))]
           [hue (+ 250.0 (* 150.0 t t))]
           [col (color-from-hsv hue t t)])
      (vector (ptr-ref col _ubyte 0)
              (ptr-ref col _ubyte 1)
              (ptr-ref col _ubyte 2)
              (ptr-ref col _ubyte 3)))))

;; ---- 创建屏幕缓冲区 ----
;; indexBuffer: 火焰"温度"索引 (0-255)，每个像素 1 字节
(define indexBuffer (make-bytes (* image-width image-height) 0))
;; flameRootBuffer: 底部火焰源
(define flameRootBuffer (make-bytes flame-width 0))

;; ---- 创建 Image 和 Texture ----
(define screen-image
  (gen-image-color image-width image-height BLACK))
(define screen-texture
  (load-texture-from-image screen-image))
(define image-data-ptr
  (list-ref screen-image 0))  ;; Image.data 指针，直接写 RGBA

(set-target-fps 60)

;; ============================================================
;; 辅助: 清空图像数据为黑色
;; ============================================================

(define (clear-image-data!)
  ;; 跳过第 0 行（保持原有逻辑），从 y=1 开始
  (let ([stride (* image-width 4)])
    (do ([y 1 (add1 y)]) [(>= y image-height)]
      (let ([row-start (* y stride)])
        (do ([x 0 (+ x 4)]) [(>= x stride)]
          ;; 写 4 字节 RGBA = 0,0,0,255（黑色）
          (ptr-set! image-data-ptr _ubyte (+ row-start x) 0)
          (ptr-set! image-data-ptr _ubyte (+ row-start x 1) 0)
          (ptr-set! image-data-ptr _ubyte (+ row-start x 2) 0)
          (ptr-set! image-data-ptr _ubyte (+ row-start x 3) 255))))))

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)

    ;; ---- 更新 ----
    ;; 1. 生长火焰根部 (flameRootBuffer)
    (do ([x 2 (add1 x)]) [(>= x flame-width)]
      (let ([flame (+ (bytes-ref flameRootBuffer x)
                      (get-random-value 0 2))])
        (bytes-set! flameRootBuffer x (if (> flame 255) 255 flame))))

    ;; 2. 传递火焰根部到底行
    (let ([bottom-row (* (sub1 image-height) image-width)])
      (do ([x 0 (add1 x)]) [(>= x flame-width)]
        (bytes-set! indexBuffer (+ bottom-row x)
                    (bytes-ref flameRootBuffer x))))

    ;; 3. 清除顶行（火焰不能更高了）
    (do ([x 0 (add1 x)]) [(>= x image-width)]
      (unless (zero? (bytes-ref indexBuffer x))
        (bytes-set! indexBuffer x 0)))

    ;; 4. 向上传播火焰
    (do ([y 1 (add1 y)]) [(>= y image-height)]
      (do ([x 0 (add1 x)]) [(>= x image-width)]
        (let* ([i (+ x (* y image-width))]
               [colorIndex (bytes-ref indexBuffer i)])
          (unless (zero? colorIndex)
            (bytes-set! indexBuffer i 0)
            (let* ([moveX (- (get-random-value 0 2) 1)]
                   [newX (+ x moveX)])
              (when (and (> newX 0) (< newX image-width))
                (let* ([iAbove (- (+ i moveX) image-width)]
                       [decay (get-random-value 0 3)]
                       [new-color (- colorIndex (if (< decay colorIndex)
                                                    decay colorIndex))])
                  (bytes-set! indexBuffer iAbove new-color))))))))

    ;; 5. 将调色板颜色写入 Image.data 指针（替代 ImageDrawPixel）
    ;;    RGBA8 格式: 每像素 4 字节, offset = (y * imageWidth + x) * 4
    (do ([y 1 (add1 y)]) [(>= y image-height)]
      (do ([x 0 (add1 x)]) [(>= x image-width)]
        (let* ([i (+ x (* y image-width))]
               [colorIndex (bytes-ref indexBuffer i)]
               [rgba (vector-ref palette colorIndex)]
               [pixel-offset (* i 4)])
          ;; 直接写 4 字节 RGBA
          (ptr-set! image-data-ptr _ubyte pixel-offset        (vector-ref rgba 0))
          (ptr-set! image-data-ptr _ubyte (+ pixel-offset 1)  (vector-ref rgba 1))
          (ptr-set! image-data-ptr _ubyte (+ pixel-offset 2)  (vector-ref rgba 2))
          (ptr-set! image-data-ptr _ubyte (+ pixel-offset 3)  (vector-ref rgba 3)))))

    ;; 6. 更新 GPU 纹理
    (update-texture screen-texture image-data-ptr)

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)
    (draw-texture-ex screen-texture
                     (vector2 0 0)
                     0.0    ;; rotation
                     2.0    ;; scale
                     WHITE)
    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture screen-texture)
(unload-image screen-image)
(close-window)
