#lang racket/base

;; raylib [textures] example - image drawing (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_image_drawing.c
;;
;; 演示: 在 CPU 图像上进行裁剪、翻转、缩放、叠加绘制、像素级绘制等操作，
;;   最后将组合后的图像转为 GPU 纹理并显示
;;   需要资源: cat.png, parrots.png, custom_jupiter_crash.png

(require ffi/unsafe
         "../../raylib/raylib.rkt")

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

;; ============================================================
;; Image/Font 指针辅助函数
;; 图像/字体在 Racket 中以 list 形式表示（FFI 按值传递解包），
;; 但原地修改函数需要指针，因此需要 list ↔ pointer 互转
;; ============================================================

;; Image: (data width height mipmaps format) ↔ T:_Image*
(define (image-list->ptr img)
  (let ([p (malloc _Image 'atomic)])
    (ptr-set! p _pointer 0 (list-ref img 0))
    (ptr-set! p _int 2 (list-ref img 1))
    (ptr-set! p _int 3 (list-ref img 2))
    (ptr-set! p _int 4 (list-ref img 3))
    (ptr-set! p _int 5 (list-ref img 4))
    p))

(define (image-ptr->list p)
  (list (ptr-ref p _pointer 0)
        (ptr-ref p _int 2)
        (ptr-ref p _int 3)
        (ptr-ref p _int 4)
        (ptr-ref p _int 5)))

;; Font: (baseSize glyphCount glyphPadding tex-id tex-w tex-h tex-mip tex-fmt recs glyphs)
;;      ↔ T:_Font*
(define (font-list->ptr f)
  (let ([p (malloc _Font 'atomic)])
    (ptr-set! p _int 0 (list-ref f 0))      ;; baseSize
    (ptr-set! p _int 1 (list-ref f 1))      ;; glyphCount
    (ptr-set! p _int 2 (list-ref f 2))      ;; glyphPadding
    (ptr-set! p _uint 3 (list-ref f 3))     ;; tex-id
    (ptr-set! p _int 4 (list-ref f 4))      ;; tex-width
    (ptr-set! p _int 5 (list-ref f 5))      ;; tex-height
    (ptr-set! p _int 6 (list-ref f 6))      ;; tex-mipmaps
    (ptr-set! p _int 7 (list-ref f 7))      ;; tex-format
    (ptr-set! p _pointer 8 (list-ref f 8))  ;; recs
    (ptr-set! p _pointer 9 (list-ref f 9))  ;; glyphs
    p))

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - image drawing")

;; NOTE: 纹理必须在窗口初始化后加载（需要 OpenGL 上下文）

;; ---- 处理 cat 图像 ----
(define cat (load-image (string-append resource-dir "cat.png")))

;; 裁剪
(let ([p (image-list->ptr cat)])
  (image-crop p (rectangle 100.0 10.0 280.0 380.0))
  (set! cat (image-ptr->list p)))

;; 水平翻转
(let ([p (image-list->ptr cat)])
  (image-flip-horizontal p)
  (set! cat (image-ptr->list p)))

;; 缩放
(let ([p (image-list->ptr cat)])
  (image-resize p 150 200)
  (set! cat (image-ptr->list p)))

;; ---- 处理 parrots 图像 ----
(define parrots (load-image (string-append resource-dir "parrots.png")))

;; 将 cat 绘制到 parrots 上（1.5 倍缩放）
(let* ([p (image-list->ptr parrots)]
       [cat-w (exact->inexact (list-ref cat 1))]
       [cat-h (exact->inexact (list-ref cat 2))])
  (image-draw p cat
              (rectangle 0.0 0.0 cat-w cat-h)
              (rectangle 30.0 40.0 (* cat-w 1.5) (* cat-h 1.5))
              WHITE)
  (set! parrots (image-ptr->list p)))

;; 再次裁剪（去掉上下各 50 像素）
(let ([p (image-list->ptr parrots)]
      [pw (exact->inexact (list-ref parrots 1))]
      [ph (exact->inexact (list-ref parrots 2))])
  (image-crop p (rectangle 0.0 50.0 pw (- ph 100.0)))
  (set! parrots (image-ptr->list p)))

;; 像素级绘制
(let ([p (image-list->ptr parrots)])
  (image-draw-pixel p 10 10 RAYWHITE)
  (image-draw-circle-lines p 10 10 5 RAYWHITE)
  (image-draw-rectangle p 5 20 10 10 RAYWHITE)
  (set! parrots (image-ptr->list p)))

;; 释放 cat（不再需要）
(unload-image cat)

;; 加载自定义字体
(define font (load-font (string-append resource-dir "custom_jupiter_crash.png")))

;; 用自定义字体在图像上绘制文字
(let ([p (image-list->ptr parrots)]
      [fp (font-list->ptr font)])
  (image-draw-text-ex p fp "PARROTS & CAT"
                      (vector2 300.0 230.0)
                      (exact->inexact (list-ref font 0))  ;; font.baseSize
                      -2.0 WHITE)
  (set! parrots (image-ptr->list p)))

;; 释放字体（文字已绘制到图像上，不再需要）
(unload-font font)

;; 将组合后的图像转为纹理
(define texture (load-texture-from-image parrots))
(unload-image parrots)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (let* ([tex-w (list-ref texture 1)]
           [tex-h (list-ref texture 2)])
      (draw-texture texture
                    (- (quotient screen-width 2) (quotient tex-w 2))
                    (- (quotient screen-height 2) (quotient tex-h 2) 40)
                    WHITE)
      (draw-rectangle-lines (- (quotient screen-width 2) (quotient tex-w 2))
                            (- (quotient screen-height 2) (quotient tex-h 2) 40)
                            tex-w tex-h DARKGRAY))

    (draw-text "We are drawing only one texture from various images composed!"
               240 350 10 DARKGRAY)
    (draw-text "Source images have been cropped, scaled, flipped and copied one over the other."
               190 370 10 DARKGRAY)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture texture)
(close-window)
