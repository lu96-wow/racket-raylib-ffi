#lang racket/base
(require ffi/unsafe)
(define-cstruct _BoundingBox ([min-x _float] [min-y _float] [min-z _float] [max-x _float] [max-y _float] [max-z _float]))
(define (bounding-box mnx mny mnz mxx mxy mxz) (let ([bb (malloc _BoundingBox 'atomic)]) (ptr-set! bb _float 0 (exact->inexact mnx)) (ptr-set! bb _float 1 (exact->inexact mny)) (ptr-set! bb _float 2 (exact->inexact mnz)) (ptr-set! bb _float 3 (exact->inexact mxx)) (ptr-set! bb _float 4 (exact->inexact mxy)) (ptr-set! bb _float 5 (exact->inexact mxz)) bb))
(define (bounding-box-min-x bb) (ptr-ref bb _float 0)) (define (bounding-box-min-y bb) (ptr-ref bb _float 1)) (define (bounding-box-min-z bb) (ptr-ref bb _float 2))
(define (bounding-box-max-x bb) (ptr-ref bb _float 3)) (define (bounding-box-max-y bb) (ptr-ref bb _float 4)) (define (bounding-box-max-z bb) (ptr-ref bb _float 5))
(define (set-bounding-box-min-x! bb v) (ptr-set! bb _float 0 (exact->inexact v))) (define (set-bounding-box-min-y! bb v) (ptr-set! bb _float 1 (exact->inexact v)))
(define (set-bounding-box-min-z! bb v) (ptr-set! bb _float 2 (exact->inexact v))) (define (set-bounding-box-max-x! bb v) (ptr-set! bb _float 3 (exact->inexact v)))
(define (set-bounding-box-max-y! bb v) (ptr-set! bb _float 4 (exact->inexact v))) (define (set-bounding-box-max-z! bb v) (ptr-set! bb _float 5 (exact->inexact v)))

;; pass-by-value
(define _bounding-box-bytes
  (_list-struct _float _float _float _float _float _float))
(define (bounding-box->bytes bb)
  (list (ptr-ref bb _float 0) (ptr-ref bb _float 1) (ptr-ref bb _float 2)
        (ptr-ref bb _float 3) (ptr-ref bb _float 4) (ptr-ref bb _float 5)))

(define (bytes->bounding-box lst)
  (bounding-box (car lst) (cadr lst) (caddr lst)
                (cadddr lst) (car (cddddr lst)) (cadr (cddddr lst))))

(provide _BoundingBox _bounding-box-bytes bounding-box
         bounding-box-min-x bounding-box-min-y bounding-box-min-z
         bounding-box-max-x bounding-box-max-y bounding-box-max-z
         set-bounding-box-min-x! set-bounding-box-min-y! set-bounding-box-min-z!
         set-bounding-box-max-x! set-bounding-box-max-y! set-bounding-box-max-z!
         bounding-box->bytes bytes->bounding-box)
