#lang racket/base
(require ffi/unsafe)

(define-cstruct _GlyphInfo
  ([value _int] [offsetX _int] [offsetY _int] [advanceX _int]
   [image-data _pointer] [image-width _int] [image-height _int]
   [image-mipmaps _int] [image-format _int]))
(define _glyph-info-bytes
  (_list-struct _int _int _int _int _pointer _int _int _int _int))

(define (glyph-info-value lst)          (list-ref lst 0))
(define (glyph-info-offset-x lst)       (list-ref lst 1))
(define (glyph-info-offset-y lst)       (list-ref lst 2))
(define (glyph-info-advance-x lst)      (list-ref lst 3))
(define (glyph-info-image-data lst)     (list-ref lst 4))
(define (glyph-info-image-width lst)    (list-ref lst 5))
(define (glyph-info-image-height lst)   (list-ref lst 6))
(define (glyph-info-image-mipmaps lst)  (list-ref lst 7))
(define (glyph-info-image-format lst)   (list-ref lst 8))

(define (bytes->glyph-info lst)
  (let ([g (malloc _GlyphInfo 'atomic)])
    (ptr-set! g _int 0 (list-ref lst 0))
    (ptr-set! g _int 1 (list-ref lst 1))
    (ptr-set! g _int 2 (list-ref lst 2))
    (ptr-set! g _int 3 (list-ref lst 3))
    (ptr-set! g _pointer 2 (list-ref lst 4))
    (ptr-set! g _int 6 (list-ref lst 5))
    (ptr-set! g _int 7 (list-ref lst 6))
    (ptr-set! g _int 8 (list-ref lst 7))
    (ptr-set! g _int 9 (list-ref lst 8))
    g))

(provide _GlyphInfo _glyph-info-bytes
         glyph-info-value glyph-info-offset-x glyph-info-offset-y glyph-info-advance-x
         glyph-info-image-data glyph-info-image-width glyph-info-image-height
         glyph-info-image-mipmaps glyph-info-image-format
         bytes->glyph-info)
