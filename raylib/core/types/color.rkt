#lang racket/base

;; types/color.rkt — Color (4 bytes, pass-by-value)

(require ffi/unsafe)

(define-cstruct _Color
  ([r _ubyte] [g _ubyte] [b _ubyte] [a _ubyte]))

(define (color r g [b 0] [a 255])
  (let ([c (malloc _Color 'atomic)])
    (ptr-set! c _ubyte 0 r)
    (ptr-set! c _ubyte 1 g)
    (ptr-set! c _ubyte 2 b)
    (ptr-set! c _ubyte 3 a)
    c))

(define (color-r c) (ptr-ref c _ubyte 0))
(define (color-g c) (ptr-ref c _ubyte 1))
(define (color-b c) (ptr-ref c _ubyte 2))
(define (color-a c) (ptr-ref c _ubyte 3))

(define (set-color-r! c v) (ptr-set! c _ubyte 0 v))
(define (set-color-g! c v) (ptr-set! c _ubyte 1 v))
(define (set-color-b! c v) (ptr-set! c _ubyte 2 v))
(define (set-color-a! c v) (ptr-set! c _ubyte 3 v))

(define _color-bytes (_list-struct _ubyte _ubyte _ubyte _ubyte))

(define (color->bytes c)
  (list (ptr-ref c _ubyte 0) (ptr-ref c _ubyte 1)
        (ptr-ref c _ubyte 2) (ptr-ref c _ubyte 3)))

(define (bytes->color lst)
  (let ([c (malloc _Color 'atomic)])
    (ptr-set! c _ubyte 0 (car lst))
    (ptr-set! c _ubyte 1 (cadr lst))
    (ptr-set! c _ubyte 2 (caddr lst))
    (ptr-set! c _ubyte 3 (cadddr lst))
    c))

(define (color=? a b)
  (and (= (ptr-ref a _ubyte 0) (ptr-ref b _ubyte 0))
       (= (ptr-ref a _ubyte 1) (ptr-ref b _ubyte 1))
       (= (ptr-ref a _ubyte 2) (ptr-ref b _ubyte 2))
       (= (ptr-ref a _ubyte 3) (ptr-ref b _ubyte 3))))

(provide _Color _color-bytes
         color color-r color-g color-b color-a
         set-color-r! set-color-g! set-color-b! set-color-a!
         color->bytes bytes->color color=?)
