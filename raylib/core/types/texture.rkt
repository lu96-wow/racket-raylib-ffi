#lang racket/base

;; types/texture.rkt — Texture (20 bytes, pass-by-value)

(require ffi/unsafe)

(define-cstruct _Texture
  ([id _uint] [width _int] [height _int] [mipmaps _int] [format _int]))

(define (texture id width height mipmaps format)
  (list id width height mipmaps format))

(define _texture-bytes
  (_list-struct _uint _int _int _int _int))

(define (texture-id lst)       (list-ref lst 0))
(define (texture-width lst)    (list-ref lst 1))
(define (texture-height lst)   (list-ref lst 2))
(define (texture-mipmaps lst)  (list-ref lst 3))
(define (texture-format lst)   (list-ref lst 4))

(provide _Texture _texture-bytes texture
         texture-id texture-width texture-height texture-mipmaps texture-format)
