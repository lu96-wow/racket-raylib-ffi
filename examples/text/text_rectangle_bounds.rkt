#lang racket/base

;; raylib [text] example - rectangle bounds (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_rectangle_bounds.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; DrawTextBoxed — 在矩形容器内绘制文本（支持换行/自动换行/裁剪）
;; ============================================================

(define (draw-text-boxed font text rec font-size spacing word-wrap? tint)
  (define text-len (string-length text))
  (define base-size (exact->inexact (car font)))
  (define scale-factor (/ font-size base-size))
  (define line-height (* (+ base-size (/ base-size 2)) scale-factor))

  ;; 获取字符的 glyph 宽度
  ;; get-glyph-info 返回 list: (value offsetX offsetY advanceX img-data img-w img-h img-mip img-fmt)
  (define (glyph-width codepoint)
    (let ([info (get-glyph-info font codepoint)])
      (if (and info (pair? info))
          (let ([adv (list-ref info 3)])           ;; advanceX
            (* (if (zero? adv)
                   (rectangle-w (get-glyph-atlas-rec font codepoint))
                   adv)
               scale-factor))
          0.0)))

  ;; 测量一行文本能放多少字符，返回行尾索引
  (define (measure-line start)
    (let loop ([i start] [w 0.0] [last-space -1])
      (cond [(>= i text-len) i]
            [(char=? (string-ref text i) #\newline) i]
            [(char=? (string-ref text i) #\space)
             (loop (+ i 1) (+ w (glyph-width 32) spacing) i)]
            [(char=? (string-ref text i) #\tab)
             (loop (+ i 1) (+ w (glyph-width 32) (* 4 spacing)) i)]
            [else
             (let* ([ch (char->integer (string-ref text i))]
                    [gw (glyph-width ch)]
                    [new-w (+ w gw spacing)])
               (if (> new-w (rectangle-w rec))
                   (if word-wrap? (if (> last-space start) last-space i) i)
                   (loop (+ i 1) new-w last-space)))])))

  ;; 绘制一行（从 start 到 end）
  (define (draw-line start end y-offset)
    (let loop ([i start] [x-offset 0.0])
      (when (< i end)
        (let ([ch (string-ref text i)])
          (cond [(char=? ch #\newline) (void)]
                [(char=? ch #\space)
                 (loop (+ i 1) (+ x-offset (glyph-width 32) spacing))]
                [(char=? ch #\tab)
                 (loop (+ i 1) (+ x-offset (glyph-width 32) (* 4 spacing)))]
                [else
                 (let ([cp (char->integer ch)])
                   (draw-text-codepoint font cp
                     (vector2 (+ (rectangle-x rec) x-offset)
                              (+ (rectangle-y rec) y-offset))
                     font-size tint)
                   (loop (+ i 1) (+ x-offset (glyph-width cp) spacing)))])))))

  ;; 主循环：逐行处理
  (let main-loop ([i 0] [y-offset 0.0])
    (when (< i text-len)
      (let* ([next (measure-line i)]
             [end (if (<= next i) (+ i 1) next)])
        (unless (> (+ y-offset line-height) (rectangle-h rec))
          (draw-line i end y-offset)
          (let ([new-i (if (and (< end text-len)
                                (char=? (string-ref text end) #\newline))
                           (+ end 1)
                           end)])
            (main-loop new-i (+ y-offset line-height))))))))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - rectangle bounds")

(define text "Text cannot escape this container... word wrap also works when active so here's a long text for testing.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")

(define-var resizing? #f)
(define-var word-wrap? #t)

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

    ;; 在容器内绘制文本（使用自定义 DrawTextBoxed）
    (draw-text-boxed font text
                     (rectangle (+ (rectangle-x container) 4)
                                (+ (rectangle-y container) 4)
                                (- (rectangle-w container) 4)
                                (- (rectangle-h container) 4))
                     20.0 2.0 (unbox word-wrap?) GRAY)

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
