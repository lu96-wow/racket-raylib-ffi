#lang racket/base
(require ffi/unsafe)
(define-cstruct _Vector3 ([x _float] [y _float] [z _float]))
(define (vector3 x y z)
  (let ([v (malloc _Vector3 'atomic)])
    (ptr-set! v _float 0 (exact->inexact x)) (ptr-set! v _float 1 (exact->inexact y))
    (ptr-set! v _float 2 (exact->inexact z)) v))
(define (vector3-x v) (ptr-ref v _float 0))
(define (vector3-y v) (ptr-ref v _float 1))
(define (vector3-z v) (ptr-ref v _float 2))
(define (set-vector3-x! v x) (ptr-set! v _float 0 (exact->inexact x)))
(define (set-vector3-y! v y) (ptr-set! v _float 1 (exact->inexact y)))
(define (set-vector3-z! v z) (ptr-set! v _float 2 (exact->inexact z)))

;; pass-by-value
(define _vec3-bytes (_list-struct _float _float _float))
(define (vec3->bytes v)
  (list (ptr-ref v _float 0) (ptr-ref v _float 1) (ptr-ref v _float 2)))
(define (bytes->vec3 lst)
  (let ([v (malloc _Vector3 'atomic)])
    (ptr-set! v _float 0 (car lst))
    (ptr-set! v _float 1 (cadr lst))
    (ptr-set! v _float 2 (caddr lst))
    v))
(define (malloc-float-vec3 x y z)
  (let ([p (malloc _float 3 'atomic)])
    (ptr-set! p _float 0 x)
    (ptr-set! p _float 1 y)
    (ptr-set! p _float 2 z)
    p))

(define vector3-zero (vector3 0.0 0.0 0.0))
(define vector3-one  (vector3 1.0 1.0 1.0))

(provide _Vector3 _vec3-bytes vector3 vector3-x vector3-y vector3-z
         set-vector3-x! set-vector3-y! set-vector3-z!
         vec3->bytes bytes->vec3 malloc-float-vec3 vector3-zero vector3-one)
