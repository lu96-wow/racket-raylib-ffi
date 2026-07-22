#lang racket/base

;; raylib [textures] example - image kernel (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_image_kernel.c
;;
;; 演示: 图像卷积核处理 (Gaussian 模糊 / Sobel 边缘检测 / Sharpen 锐化)
;;
;; 注意: 此示例需要直接操作 C 内存中的 Image 结构体指针

(require "../../raylib/raylib.rkt"
         ffi/unsafe
         (prefix-in T: "../../raylib/types.rkt"))

;; ============================================================
;; 资源路径
;; ============================================================

(define resource-dir
  (path->string (build-path (current-directory) "../../../examples/textures/resources/")))

;; ============================================================
;; 辅助: Image list ↔ C Image* 指针转换
;; ============================================================

;; 将 Image 列表 (data width height mipmaps format) 写入 malloc'd C struct

;; 从 malloc'd C Image* 读取回列表
(define (image-ptr->list ptr)
  (list (ptr-ref ptr _pointer 0)
        (ptr-ref ptr _int 2)
        (ptr-ref ptr _int 3)
        (ptr-ref ptr _int 4)
        (ptr-ref ptr _int 5)))

;; 分配 C float 数组（用于卷积核）
(define (make-float-array lst)
  (let ([ptr (malloc _float (length lst) 'atomic)])
    (for ([v (in-list lst)]
          [i (in-naturals)])
      (ptr-set! ptr _float i v))
    ptr))

;; 归一化卷积核（使所有元素之和为 1）
(define (normalize-kernel! ptr size)
  (let ([sum (for/sum ([i (in-range size)])
               (ptr-ref ptr _float i))])
    (when (> sum 0)
      (for ([i (in-range size)])
        (ptr-set! ptr _float i (/ (ptr-ref ptr _float i) sum))))))

;; ============================================================
;; 常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - image kernel")

;; 加载原始图像
(define image (load-image (string-append resource-dir "cat.png")))

;; 定义卷积核
(define gaussian-kernel (make-float-array '(1.0 2.0 1.0
                                            2.0 4.0 2.0
                                            1.0 2.0 1.0)))
(define sobel-kernel    (make-float-array '( 1.0  0.0 -1.0
                                             2.0  0.0 -2.0
                                             1.0  0.0 -1.0)))
(define sharpen-kernel  (make-float-array '( 0.0 -1.0  0.0
                                            -1.0  5.0 -1.0
                                             0.0 -1.0  0.0)))

(normalize-kernel! gaussian-kernel 9)
(normalize-kernel! sharpen-kernel 9)
(normalize-kernel! sobel-kernel 9)

;; 复制图像并应用卷积核 (在 CPU 端处理)
(define (process-image src-img kernel-ptr kernel-size)
  (let* ([copy-list (image-copy src-img)]
         [copy-ptr  (image-list->ptr copy-list)])
    (image-kernel-convolution copy-ptr kernel-ptr kernel-size)
    (let ([result (image-ptr->list copy-ptr)])
      ;; 注意: malloc 'atomic 内存由 GC 管理，不需要手动 free
      result)))

;; 应用卷积核
(define cat-sharpend (process-image image sharpen-kernel 9))
(define cat-sobel    (process-image image sobel-kernel 9))

;; Gaussian 模糊需要多次应用
(define cat-gaussian
  (let loop ([img image] [n 0])
    (if (>= n 6)
        img
        (loop (process-image img gaussian-kernel 9) (+ n 1)))))

;; 裁剪图像（会修改原 Image 的 data 指针，原地操作）
;; 返回新的 Image 列表；原列表 data 指针变为悬垂，不应再使用！
(define (crop-image! img x y w h)
  (let* ([ptr (image-list->ptr img)]
         [_   (image-crop ptr (rectangle x y w h))]
         [result (image-ptr->list ptr)])
    result))

;; 裁剪后原 Image 列表失效，只保留裁剪结果
(define cat-sharpend-crop  (crop-image! cat-sharpend 0.0 0.0 200.0 450.0))
(define cat-sobel-crop     (crop-image! cat-sobel    0.0 0.0 200.0 450.0))
(define cat-gaussian-crop  (crop-image! cat-gaussian 0.0 0.0 200.0 450.0))
(define image-cropped      (crop-image! image       0.0 0.0 200.0 450.0))

;; 转换为 GPU 纹理
(define cat-sharpend-tex (load-texture-from-image cat-sharpend-crop))
(define cat-sobel-tex    (load-texture-from-image cat-sobel-crop))
(define cat-gaussian-tex (load-texture-from-image cat-gaussian-crop))
(define texture          (load-texture-from-image image-cropped))

;; 释放 CPU 端 Image（仅裁剪后的结果有效）
(unload-image image-cropped)
(unload-image cat-gaussian-crop)
(unload-image cat-sobel-crop)
(unload-image cat-sharpend-crop)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-texture cat-sharpend-tex 0 0 WHITE)
    (draw-texture cat-sobel-tex 200 0 WHITE)
    (draw-texture cat-gaussian-tex 400 0 WHITE)
    (draw-texture texture 600 0 WHITE)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture texture)
(unload-texture cat-sharpend-tex)
(unload-texture cat-sobel-tex)
(unload-texture cat-gaussian-tex)
(close-window)
