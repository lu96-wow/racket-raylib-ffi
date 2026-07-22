#lang racket/base

;; types/font.rkt — Font (56 bytes)

(require ffi/unsafe)

;; ═══════════════════════════════════════════════════════════
;; C struct
;; ═══════════════════════════════════════════════════════════

(define-cstruct _Font
  ([baseSize _int] [glyphCount _int] [glyphPadding _int]
   [tex-id _uint] [tex-width _int] [tex-height _int]
   [tex-mipmaps _int] [tex-format _int]
   [recs _pointer] [glyphs _pointer]))

;; ═══════════════════════════════════════════════════════════
;; pass-by-value 转换
;; ═══════════════════════════════════════════════════════════

(define _font-bytes
  (_list-struct _int _int _int _uint _int _int _int _int _pointer _pointer))

;; ═══════════════════════════════════════════════════════════
;; 列表访问器 (用于 FFI 返回值)
;; ═══════════════════════════════════════════════════════════

(define (font-base-size lst)      (list-ref lst 0))
(define (font-glyph-count lst)    (list-ref lst 1))
(define (font-glyph-padding lst)  (list-ref lst 2))
(define (font-tex-id lst)         (list-ref lst 3))
(define (font-tex-width lst)      (list-ref lst 4))
(define (font-tex-height lst)     (list-ref lst 5))
(define (font-tex-mipmaps lst)    (list-ref lst 6))
(define (font-tex-format lst)     (list-ref lst 7))
(define (font-recs lst)           (list-ref lst 8))
(define (font-glyphs lst)         (list-ref lst 9))

;; ═══════════════════════════════════════════════════════════
;; bytes → cpointer 转换
;; ═══════════════════════════════════════════════════════════

(define (bytes->font lst)
  (let ([f (malloc _Font 'atomic)])
    (ptr-set! f _int 0 (list-ref lst 0))
    (ptr-set! f _int 1 (list-ref lst 1))
    (ptr-set! f _int 2 (list-ref lst 2))
    (ptr-set! f _uint 3 (list-ref lst 3))
    (ptr-set! f _int 4 (list-ref lst 4))
    (ptr-set! f _int 5 (list-ref lst 5))
    (ptr-set! f _int 6 (list-ref lst 6))
    (ptr-set! f _int 7 (list-ref lst 7))
    (ptr-set! f _pointer 4 (list-ref lst 8))
    (ptr-set! f _pointer 5 (list-ref lst 9))
    f))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide _Font _font-bytes
         font-base-size font-glyph-count font-glyph-padding
         font-tex-id font-tex-width font-tex-height
         font-tex-mipmaps font-tex-format
         font-recs font-glyphs
         bytes->font)
