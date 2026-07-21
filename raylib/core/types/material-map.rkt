#lang racket/base

;; types/material-map.rkt — MaterialMap (28 bytes)

(require ffi/unsafe)

(define-cstruct _MaterialMap
  ([tex-id _uint] [tex-width _int] [tex-height _int] [tex-mipmaps _int] [tex-format _int]
   [color-r _ubyte] [color-g _ubyte] [color-b _ubyte] [color-a _ubyte]
   [value _float]))

(provide _MaterialMap)
