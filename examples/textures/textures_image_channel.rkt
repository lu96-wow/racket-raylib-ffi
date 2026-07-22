#lang racket/base

;; raylib [textures] example - image channel (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_image_channel.c
;;
;; 演示: 从图像中提取 R/G/B/Alpha 通道，并用 Alpha 通道遮罩各通道

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (prefix-in T: "../../raylib/types.rkt"))

;; ============================================================
;; 资源路径 (相对于源文件位置，不依赖运行目录)
;; ============================================================

(define-runtime-path resource-dir-path
  "../../../examples/textures/resources/")

(define resource-dir (path->string resource-dir-path))

;; ============================================================
;; 辅助: Image list ↔ C Image* 指针转换 (同 image_kernel 示例)
;; ============================================================


(define (image-ptr->list ptr)
  (list (ptr-ref ptr _pointer 0)
        (ptr-ref ptr _int 2)
        (ptr-ref ptr _int 3)
        (ptr-ref ptr _int 4)
        (ptr-ref ptr _int 5)))

;; ============================================================
;; 常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
             "raylib [textures] example - image channel")

;; 加载图像
(define fudesumi-image (load-image (string-append resource-dir "fudesumi.png")))

;; 提取 Alpha 通道 (channel=3)
(define image-alpha (image-from-channel fudesumi-image 3))

;; 对 Alpha 图像自身做遮罩 (需要指针操作)
(let ([ptr (image-list->ptr image-alpha)])
  (image-alpha-mask ptr image-alpha)
  (set! image-alpha (image-ptr->list ptr)))

;; 提取 R 通道 (channel=0) 并用 Alpha 遮罩
(define image-red (image-from-channel fudesumi-image 0))
(let ([ptr (image-list->ptr image-red)])
  (image-alpha-mask ptr image-alpha)
  (set! image-red (image-ptr->list ptr)))

;; 提取 G 通道 (channel=1) 并用 Alpha 遮罩
(define image-green (image-from-channel fudesumi-image 1))
(let ([ptr (image-list->ptr image-green)])
  (image-alpha-mask ptr image-alpha)
  (set! image-green (image-ptr->list ptr)))

;; 提取 B 通道 (channel=2) 并用 Alpha 遮罩
(define image-blue (image-from-channel fudesumi-image 2))
(let ([ptr (image-list->ptr image-blue)])
  (image-alpha-mask ptr image-alpha)
  (set! image-blue (image-ptr->list ptr)))

;; 生成棋盘格背景
(define background-image
  (gen-image-checked screen-width screen-height
                     (quotient screen-width 20) (quotient screen-height 20)
                     ORANGE YELLOW))

;; 转换为 GPU 纹理
(define fudesumi-texture  (load-texture-from-image fudesumi-image))
(define texture-alpha     (load-texture-from-image image-alpha))
(define texture-red       (load-texture-from-image image-red))
(define texture-green     (load-texture-from-image image-green))
(define texture-blue      (load-texture-from-image image-blue))
(define background-texture (load-texture-from-image background-image))

;; 释放 CPU 端 Image
(unload-image fudesumi-image)
(unload-image image-alpha)
(unload-image image-red)
(unload-image image-green)
(unload-image image-blue)
(unload-image background-image)

;; 定义绘制区域矩形
(define img-w (list-ref fudesumi-texture 1))
(define img-h (list-ref fudesumi-texture 2))

(define fudesumi-rec (rectangle 0.0 0.0 img-w img-h))

(define fudesumi-pos (rectangle 50.0 10.0 (* img-w 0.8) (* img-h 0.8)))
(define fw (/ (rectangle-w fudesumi-pos) 2.0))
(define fh (/ (rectangle-h fudesumi-pos) 2.0))

(define red-pos    (rectangle 410.0 10.0  fw fh))
(define green-pos  (rectangle 600.0 10.0  fw fh))
(define blue-pos   (rectangle 410.0 230.0 fw fh))
(define alpha-pos  (rectangle 600.0 230.0 fw fh))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-texture background-texture 0 0 WHITE)
    (draw-texture-pro fudesumi-texture fudesumi-rec fudesumi-pos
                      (vector2 0.0 0.0) 0.0 WHITE)

    (draw-texture-pro texture-red   fudesumi-rec red-pos   (vector2 0.0 0.0) 0.0 RED)
    (draw-texture-pro texture-green fudesumi-rec green-pos (vector2 0.0 0.0) 0.0 GREEN)
    (draw-texture-pro texture-blue  fudesumi-rec blue-pos  (vector2 0.0 0.0) 0.0 BLUE)
    (draw-texture-pro texture-alpha fudesumi-rec alpha-pos (vector2 0.0 0.0) 0.0 WHITE)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture background-texture)
(unload-texture fudesumi-texture)
(unload-texture texture-red)
(unload-texture texture-green)
(unload-texture texture-blue)
(unload-texture texture-alpha)
(close-window)
