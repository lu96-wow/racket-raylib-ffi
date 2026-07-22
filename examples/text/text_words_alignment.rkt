#lang racket/base

;; raylib [text] example - words alignment (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_words_alignment.c

(require ffi/unsafe
         "../../raylib/raylib.rkt")

;; ============================================================
;; 对齐枚举
;; ============================================================

(define TEXT-ALIGN-LEFT 0)
(define TEXT-ALIGN-TOP 0)
(define TEXT-ALIGN-CENTRE 1)
(define TEXT-ALIGN-MIDDLE 1)
(define TEXT-ALIGN-RIGHT 2)
(define TEXT-ALIGN-BOTTOM 2)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - words alignment")

;; Define the rectangle we will draw the text in
(define text-container-rect
  (rectangle (- (/ screen-width 2.0) (/ screen-width 4.0))
             (- (/ screen-height 2.0) (/ screen-height 3.0))
             (/ screen-width 2.0)
             (* screen-height 2/3)))

;; Some text to display the current alignment
(define text-align-name-h (vector "Left" "Centre" "Right"))
(define text-align-name-v (vector "Top" "Middle" "Bottom"))

;; Define the text we're going to draw in the rectangle
(define-values (words word-count) (text-split "raylib is a simple and easy-to-use library to enjoy videogames programming" 32))

;; Initialize the font size
(define font-size 40)

;; And of course the font...
(define font (get-font-default))

;; Initialize the alignment variables
(define-var h-align TEXT-ALIGN-CENTRE)
(define-var v-align TEXT-ALIGN-MIDDLE)

(set-target-fps 60)

;; ============================================================
;; 辅助: 读取 words 字符串数组
;; ============================================================

(define (words-ref words-ptr idx)
  ;; words-ptr is a char** pointer; we need to read the idx-th char* 
  ;; The text-split in rtext.rkt returns (values pointer count)
  ;; We'll use the pointer to read individual strings
  (let ([str-ptr (ptr-ref words-ptr _pointer idx)])
    (if str-ptr
        (let ([tmp (malloc _pointer 'atomic)])
          (ptr-set! tmp _pointer 0 str-ptr)
          (let ([result (ptr-ref tmp _string)])
            (free tmp)
            result))
        "")))

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (when (is-key-pressed KEY-LEFT)
      (when (> (unbox h-align) 0)
        (-= h-align 1)))

    (when (is-key-pressed KEY-RIGHT)
      (+= h-align 1)
      (when (> (unbox h-align) 2)
        (set-box! h-align 2)))

    (when (is-key-pressed KEY-UP)
      (when (> (unbox v-align) 0)
        (-= v-align 1)))

    (when (is-key-pressed KEY-DOWN)
      (+= v-align 1)
      (when (> (unbox v-align) 2)
        (set-box! v-align 2)))

    ;; One word per second
    (define word-index
      (if (> word-count 0)
          (modulo (inexact->exact (floor (get-time))) word-count)
          0))

    ;; 绘制
    (begin-drawing)

    (clear-background DARKBLUE)

    (draw-text "Use Arrow Keys to change the text alignment" 20 20 20 LIGHTGRAY)
    (draw-text (format "Alignment: Horizontal = ~a, Vertical = ~a"
                            (vector-ref text-align-name-h (unbox h-align))
                            (vector-ref text-align-name-v (unbox v-align)))
               20 40 20 LIGHTGRAY)

    (draw-rectangle-rec text-container-rect BLUE)

    ;; Get the size of the text to draw
    (let* ([current-word (words-ref words word-index)]
           [text-size (measure-text-ex font current-word (exact->inexact font-size) (* font-size 0.1))]
           ;; Calculate the top-left text position based on the rectangle and alignment
           [text-pos
            (vector2
             (+ (rectangle-x text-container-rect)
                (lerp 0.0 (- (rectangle-w text-container-rect) (vector2-x text-size))
                      (* (unbox h-align) 0.5)))
             (+ (rectangle-y text-container-rect)
                (lerp 0.0 (- (rectangle-h text-container-rect) (vector2-y text-size))
                      (* (unbox v-align) 0.5))))])
      ;; Draw the text
      (draw-text-ex font current-word text-pos (exact->inexact font-size) (* font-size 0.1) RAYWHITE))

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

;; NOTE: TextSplit uses static memory, no manual unload needed

(close-window)
