#lang racket/base
(require ffi/unsafe)
(define-cstruct _RenderTexture ([id _uint] [tex-id _uint] [tex-width _int] [tex-height _int] [tex-mipmaps _int] [tex-format _int] [dep-id _uint] [dep-width _int] [dep-height _int] [dep-mipmaps _int] [dep-format _int]))
(define (render-texture id tex-id tex-w tex-h tex-m tex-f dep-id dep-w dep-h dep-m dep-f)
  (let ([rt (malloc _RenderTexture 'atomic)]) (ptr-set! rt _uint 0 id) (ptr-set! rt _uint 1 tex-id) (ptr-set! rt _int 2 tex-w) (ptr-set! rt _int 3 tex-h) (ptr-set! rt _int 4 tex-m) (ptr-set! rt _int 5 tex-f) (ptr-set! rt _uint 6 dep-id) (ptr-set! rt _int 7 dep-w) (ptr-set! rt _int 8 dep-h) (ptr-set! rt _int 9 dep-m) (ptr-set! rt _int 10 dep-f) rt))

;; pass-by-value
(define _render-texture-bytes
  (_list-struct _uint
                _uint _int _int _int _int
                _uint _int _int _int _int))

(provide _RenderTexture _render-texture-bytes render-texture)
