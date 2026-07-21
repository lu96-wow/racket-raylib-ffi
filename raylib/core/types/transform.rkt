#lang racket/base

;; types/transform.rkt — Transform (40 bytes)

(require ffi/unsafe)

(define-cstruct _Transform
  ([trans-x _float] [trans-y _float] [trans-z _float]
   [rot-x _float] [rot-y _float] [rot-z _float] [rot-w _float]
   [scale-x _float] [scale-y _float] [scale-z _float]))

(provide _Transform)
