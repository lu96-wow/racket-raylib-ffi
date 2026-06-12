#lang racket/base

;; raylib [textures] example - mouse painting (Racket FFI 翻译)
;; 对应 C: examples/textures/textures_mouse_painting.c
;; 演示: 用鼠标在画布上绘画，可保存为 PNG

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define-runtime-path resource-dir-path "../../../examples/textures/resources/")
(define resource-dir (path->string resource-dir-path))

(define screen-width 800)
(define screen-height 450)
(define max-colors-count 23)
(define MOUSE-BUTTON-RIGHT 1)

;; 颜色选项
(define colors
  (vector RAYWHITE YELLOW GOLD ORANGE PINK RED MAROON GREEN LIME DARKGREEN
          SKYBLUE BLUE DARKBLUE PURPLE VIOLET DARKPURPLE BEIGE BROWN DARKBROWN
          LIGHTGRAY GRAY DARKGRAY BLACK))

;; 颜色按钮位置
(define color-recs (make-vector max-colors-count))
(for ([i (in-range max-colors-count)])
  (vector-set! color-recs i (rectangle (+ 10.0 (* 30.0 i) (* 2 i)) 10.0 30.0 30.0)))

(init-window screen-width screen-height "raylib [textures] example - mouse painting")

;; RenderTexture 画布
(define target (load-render-texture screen-width screen-height))
(begin-texture-mode target)
(clear-background (vector-ref colors 0))
(end-texture-mode)

;; 从 RenderTexture 提取纹理 (RenderTexture 11 元素 → Texture 5 元素)
(define (rt->tex rt)
  (list (list-ref rt 1) (list-ref rt 2) (list-ref rt 3)
        (list-ref rt 4) (list-ref rt 5)))


(let loop ([color-sel 0] [color-prev 0] [bsize 20.0]
           [mouse-was-pressed #f] [show-save #f] [save-ctr 0])
  (unless (window-should-close?)
    (let* ([m (get-mouse-position)]
           [mx (vector2-x m)] [my (vector2-y m)]

           ;; 键盘切换颜色
           [color-sel (cond [(is-key-pressed KEY-RIGHT) (min (add1 color-sel) (sub1 max-colors-count))]
                            [(is-key-pressed KEY-LEFT)  (max (sub1 color-sel) 0)]
                            [else color-sel])]

           ;; 鼠标悬停颜色按钮
           [hover (let loop ([i 0])
                    (if (>= i max-colors-count) -1
                        (if (check-collision-point-rec m (vector-ref color-recs i))
                            i (loop (add1 i)))))]

           ;; 点击颜色按钮选色
           [color-sel (if (and (>= hover 0) (is-mouse-button-pressed MOUSE-BUTTON-LEFT))
                        (begin (set! color-prev hover) hover)
                        color-sel)]

           ;; 滚轮调节笔刷
           [bsize (let ([s (+ bsize (* (get-mouse-wheel-move) 5.0))])
                    (cond [(< s 2.0) 2.0] [(> s 50.0) 50.0] [else s]))]

           ;; C 清屏
           [_ (when (is-key-pressed KEY-C)
                (begin-texture-mode target)
                (clear-background (vector-ref colors 0))
                (end-texture-mode))]

           ;; 左键绘画
           [_ (when (and (is-mouse-button-down MOUSE-BUTTON-LEFT) (> my 50))
                (begin-texture-mode target)
                (draw-circle (inexact->exact (round mx)) (inexact->exact (round my))
                             bsize (vector-ref colors color-sel))
                (end-texture-mode))]

           ;; 右键橡皮擦
           [color-sel
            (if (is-mouse-button-down MOUSE-BUTTON-RIGHT)
                (begin (unless mouse-was-pressed (set! color-prev color-sel))
                       (set! mouse-was-pressed #t)
                       (when (> my 50)
                         (begin-texture-mode target)
                         (draw-circle (inexact->exact (round mx)) (inexact->exact (round my))
                                      bsize (vector-ref colors 0))
                         (end-texture-mode))
                       0)
                (if (and mouse-was-pressed (is-mouse-button-released MOUSE-BUTTON-RIGHT))
                    (begin (set! mouse-was-pressed #f) color-prev)
                    color-sel))]

           ;; 保存按钮
           [save-rec (rectangle 750.0 10.0 40.0 30.0)]
           [save-hover (check-collision-point-rec m save-rec)]

           [show-save
            (if (and (or (and save-hover (is-mouse-button-released MOUSE-BUTTON-LEFT))
                         (is-key-pressed KEY-S))
                     (not show-save))
                (begin (let* ([img (load-image-from-texture (rt->tex target))]
                              [_ (image-flip-vertical img)]
                              [_ (export-image img "my_amazing_texture_painting.png")])
                         (unload-image img))
                       (set! save-ctr 0) #t)
                (if show-save
                    (let ([c (add1 save-ctr)])
                      (set! save-ctr c)
                      (if (> c 240) (begin (set! save-ctr 0) #f) #t))
                    #f))])

      ;; === 绘制 ===
      (begin-drawing)
      (clear-background RAYWHITE)

      ;; 画布 (y-flipped)
      (let ([tex (rt->tex target)])
        (draw-texture-rec tex
          (rectangle 0.0 0.0 (list-ref tex 1) (- (list-ref tex 2)))
          (vector2 0.0 0.0) WHITE))

      ;; 笔刷预览
      (when (> my 50)
        (if (is-mouse-button-down MOUSE-BUTTON-RIGHT)
            (draw-circle-lines (inexact->exact (round mx))
                               (inexact->exact (round my)) bsize GRAY)
            (draw-circle (get-mouse-x) (get-mouse-y) bsize
                         (vector-ref colors color-sel))))

      ;; 顶部面板
      (draw-rectangle 0 0 (get-screen-width) 50 RAYWHITE)
      (draw-line 0 50 (get-screen-width) 50 LIGHTGRAY)

      ;; 颜色按钮
      (for ([i (in-range max-colors-count)])
        (draw-rectangle-rec (vector-ref color-recs i) (vector-ref colors i)))
      (draw-rectangle-lines 10 10 30 30 LIGHTGRAY)
      (when (>= hover 0)
        (draw-rectangle-rec (vector-ref color-recs hover) (fade WHITE 0.6)))
      (let ([cr (vector-ref color-recs color-sel)])
        (draw-rectangle-lines-ex
         (rectangle (- (rectangle-x cr) 2.0) (- (rectangle-y cr) 2.0)
                    (+ (rectangle-w cr) 4.0) (+ (rectangle-h cr) 4.0))
         2.0 BLACK))

      ;; 保存按钮
      (draw-rectangle-lines-ex save-rec 2.0 (if save-hover RED BLACK))
      (draw-text "SAVE!" 755 20 10 (if save-hover RED BLACK))

      ;; 保存提示
      (when show-save
        (draw-rectangle 0 0 (get-screen-width) (get-screen-height) (fade RAYWHITE 0.8))
        (draw-rectangle 0 150 (get-screen-width) 80 BLACK)
        (draw-text "IMAGE SAVED!" 150 180 20 RAYWHITE))

      (end-drawing)
      (loop color-sel color-prev bsize mouse-was-pressed show-save save-ctr))))

(unload-render-texture target)
(close-window)

(set-target-fps 120)
