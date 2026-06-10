#lang racket/base

;; raylib [text] example - inline styling (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_inline_styling.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 辅助: Hex 字符串 -> Color
;; ============================================================

(define (hex->color hex-str)
  (let* ([val (string->number hex-str 16)]
         [r (bitwise-and (arithmetic-shift val -24) #xFF)]
         [g (bitwise-and (arithmetic-shift val -16) #xFF)]
         [b (bitwise-and (arithmetic-shift val -8) #xFF)]
         [a (bitwise-and val #xFF)])
    (color r g b a)))

;; ============================================================
;; DrawTextStyled — 内联样式文本绘制（简化版）
;; ============================================================
;;
;; 支持: [cRRGGBBAA] 前景色, [bRRGGBBAA] 背景色, [r] 重置
;; 注: 此实现使用 Racket 字符串处理和 get-codepoint 来遍历 Unicode

(define (draw-text-styled font text position font-size spacing base-color)
  (define text-len (string-length text))
  (define scale-factor (/ font-size (exact->inexact (car font))))
  (define back-rec-padding 4)

  (let main-loop ([i 0]
                  [text-offset-x 0.0]
                  [text-offset-y 0.0]
                  [col-front base-color]
                  [col-back BLANK])
    (when (< i text-len)
      (define ch (string-ref text i))
      (cond
        [(char=? ch #\newline)
         (main-loop (+ i 1) 0.0 (+ text-offset-y font-size) col-front col-back)]
        [(char=? ch #\[)
         (cond
           [(and (> text-len (+ i 2))
                 (char=? (string-ref text (+ i 1)) #\r)
                 (char=? (string-ref text (+ i 2)) #\]))
            ;; [r] — 重置样式
            (main-loop (+ i 3) text-offset-x text-offset-y base-color BLANK)]
           [(and (> text-len (+ i 2))
                 (or (char=? (string-ref text (+ i 1)) #\c)
                     (char=? (string-ref text (+ i 1)) #\b)))
            ;; [cRRGGBBAA] 或 [bRRGGBBAA]
            (let* ([is-fg? (char=? (string-ref text (+ i 1)) #\c)]
                   [color-start (+ i 2)]
                   [color-end
                    (let find-end ([j color-start])
                      (if (or (>= j text-len) (char=? (string-ref text j) #\]))
                          j
                          (find-end (+ j 1))))])
              (if (and (< color-end text-len) (> (- color-end color-start) 0))
                  (let* ([hex-str (substring text color-start color-end)]
                         [new-col (hex->color hex-str)])
                    (main-loop (+ color-end 1) text-offset-x text-offset-y
                               (if is-fg? new-col col-front)
                               (if is-fg? col-back new-col)))
                  (main-loop (+ i 1) text-offset-x text-offset-y col-front col-back)))]
           [else
            ;; 普通 '[' 字符，绘制它
            (let ([codepoint (char->integer ch)])
              (draw-text-codepoint font codepoint
                                   (vector2 (+ (vector2-x position) text-offset-x)
                                            (+ (vector2-y position) text-offset-y))
                                   font-size col-front)
              (main-loop (+ i 1) (+ text-offset-x spacing font-size) text-offset-y col-front col-back))])]
        [else
         ;; 普通字符
         (let ([codepoint (char->integer ch)])
           ;; 背景绘制
           (when (> (ptr-ref col-back _ubyte 3) 0)
             (draw-rectangle-rec
              (rectangle (+ (vector2-x position) text-offset-x)
                         (- (+ (vector2-y position) text-offset-y) back-rec-padding)
                         (+ font-size spacing)
                         (+ font-size (* 2 back-rec-padding)))
              col-back))
           ;; 字符绘制
           (when (and (not (char=? ch #\space)) (not (char=? ch #\tab)))
             (draw-text-codepoint font codepoint
                                  (vector2 (+ (vector2-x position) text-offset-x)
                                           (+ (vector2-y position) text-offset-y))
                                  font-size col-front))
           (main-loop (+ i 1) (+ text-offset-x spacing font-size) text-offset-y col-front col-back))]))))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - inline styling")

(define col-random (color 230 41 55 255))  ; RED
(define frame-counter (box 0))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (set-box! frame-counter (+ (unbox frame-counter) 1))

    (when (= (modulo (unbox frame-counter) 20) 0)
      (ptr-set! col-random _ubyte 0 (get-random-value 0 255))
      (ptr-set! col-random _ubyte 1 (get-random-value 0 255))
      (ptr-set! col-random _ubyte 2 (get-random-value 0 255)))

    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    (draw-text-styled (get-font-default)
                      "This changes the [cFF0000FF]foreground color[r] of provided text!!!"
                      (vector2 100.0 80.0) 20.0 2.0 BLACK)

    (draw-text-styled (get-font-default)
                      "This changes the [bFF00FFFF]background color[r] of provided text!!!"
                      (vector2 100.0 120.0) 20.0 2.0 BLACK)

    (draw-text-styled (get-font-default)
                      "This changes the [c00ff00ff][bff0000ff]foreground and background colors[r]!!!"
                      (vector2 100.0 160.0) 20.0 2.0 BLACK)

    (draw-text-styled (get-font-default)
                      "This changes the [c00ff00ff]alpha[r] relative [cffffffff][b000000ff]from source[r] [cff000088]color[r]!!!"
                      (vector2 100.0 200.0) 20.0 2.0 (color 0 0 0 100))

    ;; Dynamic colored text
    (let* ([r (ptr-ref col-random _ubyte 0)]
           [g (ptr-ref col-random _ubyte 1)]
           [b (ptr-ref col-random _ubyte 2)]
           [hex (lambda (n) (~a (number->string n 16) #:min-width 2 #:pad-string "0"))]
           [txt (format "Let's be [c~a~a~a]CREATIVE[r] !!!" (hex r) (hex g) (hex b))]
           [meas (measure-text-ex (get-font-default) txt 40.0 2.0)])
      (draw-text-styled (get-font-default) txt (vector2 100.0 240.0) 40.0 2.0 BLACK)
      (draw-rectangle-lines 100 240
                            (inexact->exact (vector2-x meas))
                            (inexact->exact (vector2-y meas))
                            GREEN))

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
