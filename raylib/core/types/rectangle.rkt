#lang racket/base

;; types/rectangle.rkt — Rectangle (16 bytes, pass-by-value)

(require ffi/unsafe)

(define-cstruct _Rectangle
  ([x _float] [y _float] [width _float] [height _float]))

(define (rectangle x y w h)
  (let ([r (malloc _Rectangle 'atomic)])
    (ptr-set! r _float 0 (exact->inexact x))
    (ptr-set! r _float 1 (exact->inexact y))
    (ptr-set! r _float 2 (exact->inexact w))
    (ptr-set! r _float 3 (exact->inexact h))
    r))

(define (rectangle-x r) (ptr-ref r _float 0))
(define (rectangle-y r) (ptr-ref r _float 1))
(define (rectangle-w r) (ptr-ref r _float 2))
(define (rectangle-h r) (ptr-ref r _float 3))

(define (set-rectangle-x! r v) (ptr-set! r _float 0 (exact->inexact v)))
(define (set-rectangle-y! r v) (ptr-set! r _float 1 (exact->inexact v)))
(define (set-rectangle-w! r v) (ptr-set! r _float 2 (exact->inexact v)))
(define (set-rectangle-h! r v) (ptr-set! r _float 3 (exact->inexact v)))

(define _rect-bytes (_list-struct _float _float _float _float))

(define (rect->bytes r)
  (list (ptr-ref r _float 0) (ptr-ref r _float 1)
        (ptr-ref r _float 2) (ptr-ref r _float 3)))

(define (bytes->rect lst)
  (let ([r (malloc _Rectangle 'atomic)])
    (ptr-set! r _float 0 (car lst))
    (ptr-set! r _float 1 (cadr lst))
    (ptr-set! r _float 2 (caddr lst))
    (ptr-set! r _float 3 (cadddr lst))
    r))

(provide _Rectangle _rect-bytes
         rectangle rectangle-x rectangle-y rectangle-w rectangle-h
         set-rectangle-x! set-rectangle-y! set-rectangle-w! set-rectangle-h!
         rect->bytes bytes->rect)
