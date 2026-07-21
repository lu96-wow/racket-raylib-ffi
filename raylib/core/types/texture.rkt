#lang racket/base
(require ffi/unsafe)
(define-cstruct _Texture ([id _uint] [width _int] [height _int] [mipmaps _int] [format _int]))

;; pass-by-value
(define _texture-bytes (_list-struct _uint _int _int _int _int))

(provide _Texture _texture-bytes)
