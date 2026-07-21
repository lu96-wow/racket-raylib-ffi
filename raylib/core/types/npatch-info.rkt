#lang racket/base

;; types/npatch-info.rkt — NPatchInfo (36 bytes)

(require ffi/unsafe)

(define-cstruct _NPatchInfo
  ([src-x _float] [src-y _float] [src-width _float] [src-height _float]
   [left _int] [top _int] [right _int] [bottom _int] [layout _int]))


;; pass-by-value
(define _npatch-info-bytes
  (_list-struct _float _float _float _float _int _int _int _int _int))

(provide _NPatchInfo _npatch-info-bytes)
