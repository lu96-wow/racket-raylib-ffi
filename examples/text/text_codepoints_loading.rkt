#lang racket/base

;; raylib [text] example - codepoints loading (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_codepoints_loading.c

(require "../../raylib/raylib.rkt"
         (only-in ffi/unsafe malloc free))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - codepoints loading")

;; Text to be displayed, must be UTF-8
(define text "いろはにほへと　ちりぬるを\nわかよたれそ　つねならむ\nうゐのおくやま　けふこえて\nあさきゆめみし　ゑひもせす")

;; Convert each utf-8 character into its corresponding codepoint
(define-values (codepoints codepoint-count) (load-codepoints text))

;; Removed duplicate codepoints to generate smaller font atlas
;; (Using Racket to remove duplicates)
(define (remove-duplicates lst)
  (let loop ([lst lst] [seen (make-hash)] [acc '()])
    (if (null? lst)
        (reverse acc)
        (let ([x (car lst)])
          (if (hash-has-key? seen x)
              (loop (cdr lst) seen acc)
              (begin (hash-set! seen x #t) (loop (cdr lst) seen (cons x acc))))))))

;; Convert codepoints pointer to a Racket list
(define (codepoints->list ptr count)
  (for/list ([i (in-range count)])
    (ptr-ref ptr _int i)))

;; Convert Racket list back to a C int array pointer
(define (list->codepoints-ptr lst)
  (let* ([len (length lst)]
         [ptr (malloc _int len 'atomic)])
    (for ([i (in-range len)]
          [x (in-list lst)])
      (ptr-set! ptr _int i x))
    ptr))

(define codepoints-list (codepoints->list codepoints codepoint-count))
(define codepoints-no-dups (remove-duplicates codepoints-list))
(define codepoints-no-dups-count (length codepoints-no-dups))
(define codepoints-no-dups-ptr (list->codepoints-ptr codepoints-no-dups))

(unload-codepoints codepoints)

;; Load font containing all the provided codepoint glyphs
(define font (load-font-ex "../../../examples/text/resources/DotGothic16-Regular.ttf" 36 codepoints-no-dups-ptr codepoints-no-dups-count))

;; Extract texture from font (Font fields: baseSize glyphCount glyphPadding texId texW texH texMip texFmt ...)
(define font-texture (list (list-ref font 3) (list-ref font 4) (list-ref font 5) (list-ref font 6) (list-ref font 7)))

;; Set bilinear scale filter for better font scaling
(set-texture-filter font-texture TEXTURE-FILTER-BILINEAR)

(set-text-line-spacing 20)

;; Free codepoints (NOTE: skipped, memory allocated via Racket FFI malloc
;; should not be manually freed with C free)
#;(free codepoints-no-dups-ptr)

(define ptr (string-length text))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ([show-font-atlas? #f])
  (unless (window-should-close?)
    (define show? (if (is-key-pressed KEY-SPACE) (not show-font-atlas?) show-font-atlas?))

    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    (draw-rectangle 0 0 (get-screen-width) 70 BLACK)
    (draw-text (format "Total codepoints contained in provided text: ~a" codepoint-count) 10 10 20 GREEN)
    (draw-text (format "Total codepoints required for font atlas (duplicates excluded): ~a" codepoints-no-dups-count) 10 40 20 GREEN)

    (if show?
        (begin
          ;; Draw generated font texture atlas containing provided codepoints
          ;; The font texture is embedded within the font list
          ;; font texture id = (list-ref font 3), width = (list-ref font 4), height = (list-ref font 5)
          (draw-texture font-texture 150 100 BLACK)
          (draw-rectangle-lines 150 100 (font-tex-width font) (font-tex-height font) BLACK))
        (begin
          ;; Draw provided text with loaded font
          (draw-text-ex font text (vector2 160.0 110.0) 48.0 5.0 BLACK)))

    (draw-text "Press SPACE to toggle font atlas view!" 10 (- (get-screen-height) 30) 20 GRAY)

    (end-drawing)

    (loop show?)))

;; ============================================================
;; 清理
;; ============================================================

(unload-font font)
(close-window)
