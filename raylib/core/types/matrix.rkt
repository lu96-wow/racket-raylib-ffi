#lang racket/base
(require ffi/unsafe)
(define-cstruct _Matrix
  ([m0 _float] [m1 _float] [m2 _float] [m3 _float]
   [m4 _float] [m5 _float] [m6 _float] [m7 _float]
   [m8 _float] [m9 _float] [m10 _float] [m11 _float]
   [m12 _float] [m13 _float] [m14 _float] [m15 _float]))
(define (matrix m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15)
  (let ([m (malloc _Matrix 'atomic)])
    (for ([(v i) (in-indexed (list m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15))])
      (ptr-set! m _float i (exact->inexact v))) m))
(define (matrix-ref m i) (ptr-ref m _float i))
(define (matrix-set! m i v) (ptr-set! m _float i (exact->inexact v)))

;; pass-by-value
(define _matrix-bytes
  (_list-struct
   _float _float _float _float
   _float _float _float _float
   _float _float _float _float
   _float _float _float _float))

(provide _Matrix _matrix-bytes matrix matrix-ref matrix-set!)
