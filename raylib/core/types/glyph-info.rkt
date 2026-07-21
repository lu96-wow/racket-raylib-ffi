#lang racket/base

;; types/glyph-info.rkt — GlyphInfo (40 bytes)

(require ffi/unsafe)

(define-cstruct _GlyphInfo
  ([value _int] [offsetX _int] [offsetY _int] [advanceX _int]
   [image-data _pointer] [image-width _int] [image-height _int]
   [image-mipmaps _int] [image-format _int]))


;; pass-by-value
(define _glyph-info-bytes
  (_list-struct _int _int _int _int _pointer _int _int _int _int))

(provide _GlyphInfo _glyph-info-bytes)
