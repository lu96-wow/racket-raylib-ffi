#lang racket/base

;; raylib [textures] example - image text (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_image_text.c
;;
;; 演示: 使用 TTF 字体在图像上绘制文字，以及显示字体图集纹理
;;   按空格键切换显示字体图集
;;   需要资源: parrots.png, KAISG.ttf

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
;; Image 指针辅助函数
;; ============================================================


(define (image-ptr->list p)
  (list (ptr-ref p _pointer 0)
        (ptr-ref p _int 2)
        (ptr-ref p _int 3)
        (ptr-ref p _int 4)
        (ptr-ref p _int 5)))

(define (font-list->ptr f)
  (let ([p (malloc _Font 'atomic)])
    (ptr-set! p _int 0 (list-ref f 0))
    (ptr-set! p _int 1 (list-ref f 1))
    (ptr-set! p _int 2 (list-ref f 2))
    (ptr-set! p _uint 3 (list-ref f 3))
    (ptr-set! p _int 4 (list-ref f 4))
    (ptr-set! p _int 5 (list-ref f 5))
    (ptr-set! p _int 6 (list-ref f 6))
    (ptr-set! p _int 7 (list-ref f 7))
    (ptr-set! p _pointer 4 (list-ref f 8))
    (ptr-set! p _pointer 5 (list-ref f 9))
    p))

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - image text")

;; NOTE: 纹理必须在窗口初始化后加载（需要 OpenGL 上下文）

;; 加载图像到 CPU 内存
(define parrots (load-image (string-append resource-dir "parrots.png")))

;; 加载 TTF 字体（自定义生成参数）
(define font (load-font-ex (string-append resource-dir "KAISG.ttf") 64 #f 0))

;; 用自定义字体在图像上绘制文字
;; NOTE: image-draw-text-ex 的 Font 参数按值传递（_font-bytes），直接传 font list
(let ([p (image-list->ptr parrots)])
  (image-draw-text-ex p font "[Parrots font drawing]"
                      (vector2 20.0 20.0)
                      (exact->inexact (list-ref font 0))  ;; font.baseSize
                      0.0 RED)
  (set! parrots (image-ptr->list p)))

;; 将图像转为纹理，释放 CPU 内存
(define texture (load-texture-from-image parrots))
(unload-image parrots)

;; 绘制位置（居中偏上）
(define position
  (vector2 (- (/ screen-width 2.0) (/ (list-ref texture 1) 2.0))
           (- (/ screen-height 2.0) (/ (list-ref texture 2) 2.0) 20.0)))

(define show-font? #f)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (set! show-font? (is-key-down KEY-SPACE))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (if (not show-font?)
        (begin
          ;; 绘制已含有文字的纹理
          (draw-texture-v texture position WHITE)

          ;; 直接使用精灵字体绘制文字（覆盖在纹理之上）
          (draw-text-ex font "[Parrots font drawing]"
                        (vector2 (+ (vector2-x position) 20.0)
                                 (+ (vector2-y position) 20.0 280.0))
                        (exact->inexact (list-ref font 0))  ;; font.baseSize
                        0.0 WHITE))
        ;; 显示字体图集纹理
        (let* ([font-tex-w (list-ref font 4)]     ;; font.tex-width
               [font-tex-h (list-ref font 5)]     ;; font.tex-height
               [font-tex (list (list-ref font 3)  ;; tex-id
                              (list-ref font 4)   ;; tex-width
                              (list-ref font 5)   ;; tex-height
                              (list-ref font 6)   ;; tex-mipmaps
                              (list-ref font 7))]) ;; tex-format
          (draw-texture font-tex
                        (- (quotient screen-width 2) (quotient font-tex-w 2))
                        50 BLACK)))

    (draw-text "PRESS SPACE to SHOW FONT ATLAS USED"
               290 420 10 DARKGRAY)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture texture)
(unload-font font)
(close-window)
