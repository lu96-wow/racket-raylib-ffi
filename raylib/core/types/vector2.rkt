#lang racket/base
(require ffi/unsafe)
(define-cstruct _Vector2 ([x _float] [y _float]))
(define (vector2 x y) (let ([v (malloc _Vector2 'atomic)]) (ptr-set! v _float 0 (exact->inexact x)) (ptr-set! v _float 1 (exact->inexact y)) v))
(define (vector2-x v) (ptr-ref v _float 0)) (define (vector2-y v) (ptr-ref v _float 1))
(define (set-vector2-x! v x) (ptr-set! v _float 0 (exact->inexact x))) (define (set-vector2-y! v y) (ptr-set! v _float 1 (exact->inexact y)))
(define _vec2-bytes (_list-struct _float _float))
(define (vec2->bytes v) (list (ptr-ref v _float 0) (ptr-ref v _float 1)))
(define (bytes->vec2 lst) (let ([v (malloc _Vector2 'atomic)]) (ptr-set! v _float 0 (car lst)) (ptr-set! v _float 1 (cadr lst)) v))
(define (malloc-float-vec2 x y) (let ([p (malloc _float 2 'atomic)]) (ptr-set! p _float 0 x) (ptr-set! p _float 1 y) p))
(define vector2-zero (vector2 0.0 0.0))
(define vector2-one  (vector2 1.0 1.0))

(provide _Vector2 _vec2-bytes vector2 vector2-x vector2-y set-vector2-x! set-vector2-y! vec2->bytes bytes->vec2 malloc-float-vec2 vector2-zero vector2-one)
