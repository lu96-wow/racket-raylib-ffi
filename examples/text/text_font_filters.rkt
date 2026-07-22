#lang racket/base

;; raylib [text] example - font filters (Racket FFI 翻译 简化版)
;;
;; 对应 C: examples/text/text_font_filters.c
;; 注: gen-texture-mipmaps / vector2-x / vector2-y / load-dropped-files
;;      等函数在 Racket FFI 中尚未绑定，本示例为简化版。

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - font filters")

(define msg "Loaded Font")

;; TTF Font loading with custom generation parameters
(define font (load-font-ex "../../../examples/text/resources/KAISG.ttf" 96 #f 0))

;; Extract texture from font for filter operations
(define font-texture (list (list-ref font 3) (list-ref font 4) (list-ref font 5) (list-ref font 6) (list-ref font 7)))

(define-var font-size (exact->inexact (list-ref font 0)))
(define-var font-x 40.0)
(define-var font-y (- (/ screen-height 2.0) 80.0))

;; Setup texture scaling filter
(set-texture-filter font-texture TEXTURE-FILTER-POINT)
(define-var current-font-filter 0)  ; TEXTURE_FILTER_POINT

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (+= font-size (* (get-mouse-wheel-move) 4.0))

    ;; Choose font texture filter method
    (cond [(is-key-pressed KEY-ONE)
           (set-texture-filter font-texture TEXTURE-FILTER-POINT)
           (set-box! current-font-filter 0)]
          [(is-key-pressed KEY-TWO)
           (set-texture-filter font-texture TEXTURE-FILTER-BILINEAR)
           (set-box! current-font-filter 1)]
          [(is-key-pressed KEY-THREE)
           ;; NOTE: Trilinear filter won't be noticed on 2D drawing
           (set-texture-filter font-texture TEXTURE-FILTER-TRILINEAR)
           (set-box! current-font-filter 2)])

    (when (is-key-down KEY-LEFT)
      (-= font-x 10.0))
    (when (is-key-down KEY-RIGHT)
      (+= font-x 10.0))

    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    (draw-text "Use mouse wheel to change font size" 20 20 10 GRAY)
    (draw-text "Use KEY_RIGHT and KEY_LEFT to move text" 20 40 10 GRAY)
    (draw-text "Use 1, 2, 3 to change texture filter" 20 60 10 GRAY)
    (draw-text "Drop a new TTF font for dynamic loading" 20 80 10 DARKGRAY)

    (draw-text-ex font msg (vector2 (unbox font-x) (unbox font-y)) (unbox font-size) 0.0 BLACK)

    (draw-rectangle 0 (- screen-height 80) screen-width 80 LIGHTGRAY)
    (draw-text (format "Font size: ~a" (unbox font-size)) 20 (- screen-height 50) 10 DARKGRAY)
    (let ([text-size (measure-text-ex font msg (unbox font-size) 0.0)])
      (draw-text (format "Text size: [~a, ~a]" (ptr-ref text-size _float 0) (ptr-ref text-size _float 1)) 20 (- screen-height 30) 10 DARKGRAY))

    (draw-text "CURRENT TEXTURE FILTER:" 250 400 20 GRAY)

    (cond [(= (unbox current-font-filter) 0) (draw-text "POINT" 570 400 20 BLACK)]
          [(= (unbox current-font-filter) 1) (draw-text "BILINEAR" 570 400 20 BLACK)]
          [(= (unbox current-font-filter) 2) (draw-text "TRILINEAR" 570 400 20 BLACK)])

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-font font)
(close-window)
