#lang racket/base
(require ffi/unsafe)

(define-cstruct _Image ([data _pointer] [width _int] [height _int] [mipmaps _int] [format _int]))
(define (image data width height mipmaps format)
  (let ([img (malloc _Image 'atomic)])
    (ptr-set! img _pointer 0 data) (ptr-set! img _int 1 width) (ptr-set! img _int 2 height)
    (ptr-set! img _int 3 mipmaps) (ptr-set! img _int 4 format) img))
(define _image-bytes (_list-struct _pointer _int _int _int _int))

(define (image-get-data lst)     (list-ref lst 0))
(define (image-get-width lst)    (list-ref lst 1))
(define (image-get-height lst)   (list-ref lst 2))
(define (image-get-mipmaps lst)  (list-ref lst 3))
(define (image-get-format lst)   (list-ref lst 4))

(provide _Image _image-bytes image
         image-get-data image-get-width image-get-height image-get-mipmaps image-get-format)
