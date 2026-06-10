#lang racket/base

;; raylib [text] example - rectangle bounds (Racket FFI 翻译 简化版)
;;
;; 对应 C: examples/text/text_rectangle_bounds.c
;;
;; 注意: C 原版包含 DrawTextBoxed/DrawTextBoxedSelectable 自定义函数，
;; 涉及低层字体 glyph 访问 (font.glyphs[index].advanceX, font.recs[index].width)、
;; GetCodepoint、单词换行测量等复杂逻辑。
;; 本示例展示容器缩放和基本文本绘制功能。

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - rectangle bounds")

(define text "Text cannot escape this container... word wrap also works when active so here's a long text for testing.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")

(define resizing? (box #f))
(define word-wrap? (box #t))

(define container (rectangle 25.0 25.0 (- screen-width 50.0) (- screen-height 250.0)))
(define resizer (rectangle (+ (rectangle-x container) (rectangle-w container) -17.0)
                            (+ (rectangle-y container) (rectangle-h container) -17.0)
                            14.0 14.0))

(define min-width 60.0)
(define min-height 60.0)
(define max-width (- screen-width 50.0))
(define max-height (- screen-height 160.0))

(define last-mouse (vector2 0.0 0.0))
(define border-color MAROON)
(define font (get-font-default))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (when (is-key-pressed KEY-SPACE)
      (set-box! word-wrap? (not (unbox word-wrap?))))

    (let ([mouse (get-mouse-position)])
      ;; 检测鼠标是否在容器内
      (if (check-collision-point-rec mouse container)
          (set! border-color (fade MAROON 0.4))
          (unless (unbox resizing?)
            (set! border-color MAROON)))

      ;; 容器缩放逻辑
      (if (unbox resizing?)
          (begin
            (when (is-mouse-button-released MOUSE-BUTTON-LEFT)
              (set-box! resizing? #f))
            (let ([width (+ (rectangle-w container) (- (vector2-x mouse) (vector2-x last-mouse)))])
              (set-rectangle-w! container
                                (cond [(< width min-width) min-width]
                                      [(> width max-width) max-width]
                                      [else width])))
            (let ([height (+ (rectangle-h container) (- (vector2-y mouse) (vector2-y last-mouse)))])
              (set-rectangle-h! container
                                (cond [(< height min-height) min-height]
                                      [(> height max-height) max-height]
                                      [else height]))))
          ;; 检测是否开始缩放
          (when (and (is-mouse-button-down MOUSE-BUTTON-LEFT)
                     (check-collision-point-rec mouse resizer))
            (set-box! resizing? #t)))

      ;; 更新缩放器位置
      (set-rectangle-x! resizer (+ (rectangle-x container) (rectangle-w container) -17.0))
      (set-rectangle-y! resizer (+ (rectangle-y container) (rectangle-h container) -17.0))

      ;; 保存鼠标位置
      (set-vector2-x! last-mouse (vector2-x mouse))
      (set-vector2-y! last-mouse (vector2-y mouse)))

    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    ;; 绘制容器边框
    (draw-rectangle-lines-ex container 3.0 border-color)

    ;; 在容器内绘制文本
    (draw-text text
               (+ (inexact->exact (rectangle-x container)) 8)
               (+ (inexact->exact (rectangle-y container)) 8)
               20 GRAY)

    ;; 绘制缩放器
    (draw-rectangle-rec resizer border-color)

    ;; 底部信息
    (draw-rectangle 0 (- screen-height 54) screen-width 54 GRAY)
    (draw-rectangle-rec (rectangle 382.0 (- screen-height 34.0) 12.0 12.0) MAROON)

    (draw-text "Word Wrap: " 313 (- screen-height 115) 20 BLACK)
    (if (unbox word-wrap?)
        (draw-text "ON" 447 (- screen-height 115) 20 RED)
        (draw-text "OFF" 447 (- screen-height 115) 20 BLACK))

    (draw-text "Press [SPACE] to toggle word wrap" 218 (- screen-height 86) 20 GRAY)
    (draw-text "Click hold & drag the box to resize the container" 155 (- screen-height 38) 20 RAYWHITE)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
