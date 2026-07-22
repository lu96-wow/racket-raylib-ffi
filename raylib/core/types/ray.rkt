#lang racket/base
(require ffi/unsafe)
(define-cstruct _Ray ([pos-x _float] [pos-y _float] [pos-z _float] [dir-x _float] [dir-y _float] [dir-z _float]))
(define (ray px py pz dx dy dz) (let ([r (malloc _Ray 'atomic)]) (ptr-set! r _float 0 (exact->inexact px)) (ptr-set! r _float 1 (exact->inexact py)) (ptr-set! r _float 2 (exact->inexact pz)) (ptr-set! r _float 3 (exact->inexact dx)) (ptr-set! r _float 4 (exact->inexact dy)) (ptr-set! r _float 5 (exact->inexact dz)) r))
(define (ray-pos-x r) (ptr-ref r _float 0)) (define (ray-pos-y r) (ptr-ref r _float 1)) (define (ray-pos-z r) (ptr-ref r _float 2))
(define (ray-dir-x r) (ptr-ref r _float 3)) (define (ray-dir-y r) (ptr-ref r _float 4)) (define (ray-dir-z r) (ptr-ref r _float 5))
(define (set-ray-pos-x! r v) (ptr-set! r _float 0 (exact->inexact v))) (define (set-ray-pos-y! r v) (ptr-set! r _float 1 (exact->inexact v)))
(define (set-ray-pos-z! r v) (ptr-set! r _float 2 (exact->inexact v))) (define (set-ray-dir-x! r v) (ptr-set! r _float 3 (exact->inexact v)))
(define (set-ray-dir-y! r v) (ptr-set! r _float 4 (exact->inexact v))) (define (set-ray-dir-z! r v) (ptr-set! r _float 5 (exact->inexact v)))

;; pass-by-value
(define _ray-bytes
  (_list-struct _float _float _float _float _float _float))
(define (ray->bytes r)
  (list (ptr-ref r _float 0) (ptr-ref r _float 1) (ptr-ref r _float 2)
        (ptr-ref r _float 3) (ptr-ref r _float 4) (ptr-ref r _float 5)))

(define (bytes->ray lst)
  (ray (list-ref lst 0) (list-ref lst 1) (list-ref lst 2)
       (list-ref lst 3) (list-ref lst 4) (list-ref lst 5)))

(provide _Ray _ray-bytes ray ray-pos-x ray-pos-y ray-pos-z ray-dir-x ray-dir-y ray-dir-z
         set-ray-pos-x! set-ray-pos-y! set-ray-pos-z! set-ray-dir-x! set-ray-dir-y! set-ray-dir-z!
         ray->bytes bytes->ray)
