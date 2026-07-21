#lang racket/base

;; types/font.rkt — Font (48 bytes)

(require ffi/unsafe)

(define-cstruct _Font
  ([baseSize _int] [glyphCount _int] [glyphPadding _int]
   [tex-id _uint] [tex-width _int] [tex-height _int] [tex-mipmaps _int] [tex-format _int]
   [recs _pointer] [glyphs _pointer]))


;; pass-by-value
(define _font-bytes
  (_list-struct _int _int _int _uint _int _int _int _int _pointer _pointer))

(provide _Font _font-bytes)
