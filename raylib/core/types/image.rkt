#lang racket/base
(require ffi/unsafe)

(define-cstruct _Image ([data _pointer] [width _int] [height _int] [mipmaps _int] [format _int]))
(define (image data width height mipmaps format)
  (let ([img (malloc _Image 'atomic)])
    (ptr-set! img _pointer 0 data) (ptr-set! img _int 1 width) (ptr-set! img _int 2 height)
    (ptr-set! img _int 3 mipmaps) (ptr-set! img _int 4 format) img))
(define _image-bytes (_list-struct _pointer _int _int _int _int))

(define (image-data lst)     (list-ref lst 0))
(define (image-width lst)    (list-ref lst 1))
(define (image-height lst)   (list-ref lst 2))
(define (image-mipmaps lst)  (list-ref lst 3))
(define (image-format lst)   (list-ref lst 4))

;; 将 bytes 列表转回 cpointer（供需要指针的 FFI 函数使用）
(define (image-list->ptr lst)
  (let ([p (malloc _Image 'atomic)])
    (ptr-set! p _pointer 0 (list-ref lst 0))
    (ptr-set! p _int 2 (list-ref lst 1))
    (ptr-set! p _int 3 (list-ref lst 2))
    (ptr-set! p _int 4 (list-ref lst 3))
    (ptr-set! p _int 5 (list-ref lst 4))
    p))

(provide _Image _image-bytes image
         image-data image-width image-height image-mipmaps image-format
         image-list->ptr)
