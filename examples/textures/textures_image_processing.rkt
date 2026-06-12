#lang racket/base

;; raylib [textures] example - image processing (Racket FFI 翻译)
;; 对应 C: examples/textures/textures_image_processing.c
;; 演示: 9 种图像处理效果 (灰度/染色/反转/对比/亮度/模糊/翻转...)

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (prefix-in T: "../../raylib/types.rkt"))

(define-runtime-path resource-dir-path "../../../examples/textures/resources/")
(define resource-dir (path->string resource-dir-path))

;; Image list ↔ C Image* 指针转换
(define (image-list->ptr img)
  (let ([ptr (malloc T:_Image 'atomic)])
    (ptr-set! ptr _pointer 0 (list-ref img 0))
    (ptr-set! ptr _int 2 (list-ref img 1))
    (ptr-set! ptr _int 3 (list-ref img 2))
    (ptr-set! ptr _int 4 (list-ref img 3))
    (ptr-set! ptr _int 5 (list-ref img 4))
    ptr))

(define (image-ptr->list ptr)
  (list (ptr-ref ptr _pointer 0)
        (ptr-ref ptr _int 2)
        (ptr-ref ptr _int 3)
        (ptr-ref ptr _int 4)
        (ptr-ref ptr _int 5)))

(define screen-width 800)
(define screen-height 450)
(define num-processes 9)
(define PFORMAT-R8G8B8A8 7)

;; 处理效果名称
(define process-text
  '("NO PROCESSING" "COLOR GRAYSCALE" "COLOR TINT" "COLOR INVERT"
    "COLOR CONTRAST" "COLOR BRIGHTNESS" "GAUSSIAN BLUR"
    "FLIP VERTICAL" "FLIP HORIZONTAL"))

;; 按钮矩形
(define toggle-recs (make-vector num-processes))
(for ([i (in-range num-processes)])

(init-window screen-width screen-height
             "raylib [textures] example - image processing")

(define im-origin (load-image (string-append resource-dir "parrots.png")))
(image-format (image-list->ptr im-origin) PFORMAT-R8G8B8A8)
;; re-read after format
(set! im-origin (list (ptr-ref (image-list->ptr im-origin) _pointer 0)
                      (list-ref im-origin 1) (list-ref im-origin 2)
                      (list-ref im-origin 3) PFORMAT-R8G8B8A8))
(define texture (load-texture-from-image im-origin))
(define im-copy (image-copy im-origin))

(set-target-fps 60)

(let loop ([current-process 0] [texture-reload #f] [mouse-hover-rec -1])
  (unless (window-should-close?)
    ;; 更新
    (let* ([mouse (get-mouse-position)]

           ;; 鼠标悬停检测
           [mouse-hover-rec
            (let loop ([i 0])
              (if (>= i num-processes) -1
                  (if (check-collision-point-rec mouse (vector-ref toggle-recs i))
                      i
                      (loop (add1 i)))))]

           ;; 点击/键盘切换效果
           [values
            (cond
              [(and (>= mouse-hover-rec 0)
                    (is-mouse-button-released MOUSE-BUTTON-LEFT))
               (values mouse-hover-rec #t mouse-hover-rec)]
              [(is-key-pressed KEY-DOWN)
               (values (modulo (add1 current-process) num-processes) #t mouse-hover-rec)]
              [(is-key-pressed KEY-UP)
               (values (modulo (sub1 current-process) num-processes) #t mouse-hover-rec)]
              [else (values current-process texture-reload mouse-hover-rec)])]
           [current-process (car (list values))]
           [texture-reload (cadr (list values))]
           [mouse-hover-rec (caddr (list values))]

           ;; 应用图像处理
           [_ (when texture-reload
                (unload-image im-copy)
                (set! im-copy (image-copy im-origin))
                (let ([ptr (image-list->ptr im-copy)])
                  (case current-process
                    [(1) (image-color-grayscale ptr)]
                    [(2) (image-color-tint ptr GREEN)]
                    [(3) (image-color-invert ptr)]
                    [(4) (image-color-contrast ptr -40)]
                    [(5) (image-color-brightness ptr -80)]
                    [(6) (image-blur-gaussian ptr 10)]
                    [(7) (image-flip-vertical ptr)]
                    [(8) (image-flip-horizontal ptr)])
                  (let ([pixels (load-image-colors (image-ptr->list ptr))])
                    (update-texture texture pixels)
                    (unload-image-colors pixels)))
                (set! texture-reload #f))])

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)
      (draw-text "IMAGE PROCESSING:" 40 30 10 DARKGRAY)

      (for ([i (in-range num-processes)])
        (let* ([rec (vector-ref toggle-recs i)]
               [active? (or (= i current-process) (= i mouse-hover-rec))]
               [x (inexact->exact (round (rectangle-x rec)))]
               [y (inexact->exact (round (rectangle-y rec)))]
               [w (inexact->exact (round (rectangle-w rec)))]
               [h (inexact->exact (round (rectangle-h rec)))]
               [txt (list-ref process-text i)])
          (draw-rectangle-rec rec (if active? SKYBLUE LIGHTGRAY))
          (draw-rectangle-lines x y w h (if active? BLUE GRAY))
          ;; 近似居中 (skip measure-text, not critical)
          (draw-text txt (+ x 5) (+ y 11) 10 (if active? DARKBLUE DARKGRAY))))

      ;; 绘制处理后的纹理
      (let ([tw (list-ref texture 1)]
            [th (list-ref texture 2)])
        (draw-texture texture (- screen-width tw 60)
                      (- (quotient screen-height 2) (quotient th 2)) WHITE)
        (draw-rectangle-lines (- screen-width tw 60)
                              (- (quotient screen-height 2) (quotient th 2))
                              tw th BLACK))

      (end-drawing)
      (loop current-process texture-reload mouse-hover-rec))))

(unload-texture texture)
(unload-image im-origin)
(unload-image im-copy)
(close-window)

  (vector-set! toggle-recs i (rectangle 40.0 (+ 50.0 (* 32 i)) 150.0 30.0)))
