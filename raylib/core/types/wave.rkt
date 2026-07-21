#lang racket/base

;; types/wave.rkt — Wave (32 bytes)

(require ffi/unsafe)

(define-cstruct _Wave
  ([frameCount _uint] [sampleRate _uint] [sampleSize _uint] [channels _uint]
   [data _pointer]))


;; pass-by-value
(define _wave-bytes (_list-struct _uint _uint _uint _uint _pointer))

(provide _Wave _wave-bytes)
