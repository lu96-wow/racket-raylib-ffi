#lang racket/base

;; types/material.rkt — Material (40 bytes)

(require ffi/unsafe)

(define-cstruct _Material
  ([shader-id _uint] [shader-locs _pointer]
   [maps _pointer]
   [param0 _float] [param1 _float] [param2 _float] [param3 _float]))


;; pass-by-value
(define _material-bytes
  (_list-struct _uint _int _pointer _pointer _float _float _float _float))

(provide _Material _material-bytes)
