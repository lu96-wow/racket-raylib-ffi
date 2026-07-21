#lang racket/base
(require ffi/unsafe)
(define-cstruct _Image ([data _pointer] [width _int] [height _int] [mipmaps _int] [format _int]))
(define (image data width height mipmaps format) (let ([img (malloc _Image 'atomic)]) (ptr-set! img _pointer 0 data) (ptr-set! img _int 1 width) (ptr-set! img _int 2 height) (ptr-set! img _int 3 mipmaps) (ptr-set! img _int 4 format) img))
(define (image-data img) (ptr-ref img _pointer 0)) (define (image-width img) (ptr-ref img _int 1))
(define (image-height img) (ptr-ref img _int 2))
(define (image-get-mipmaps img) (ptr-ref img _int 3)) (define (image-get-format img) (ptr-ref img _int 4))
(define (set-image-data! img v) (ptr-set! img _pointer 0 v)) (define (set-image-width! img v) (ptr-set! img _int 1 v))
(define (set-image-height! img v) (ptr-set! img _int 2 v))
(define (image-set-mipmaps! img v) (ptr-set! img _int 3 v)) (define (image-set-format! img v) (ptr-set! img _int 4 v))

;; pass-by-value
(define _image-bytes (_list-struct _pointer _int _int _int _int))

(provide _Image _image-bytes image image-data image-width image-height image-get-mipmaps image-get-format set-image-data! set-image-width! set-image-height! image-set-mipmaps! image-set-format!)
