#lang racket/base
(require ffi/unsafe)

(define-cstruct _Shader ([id _uint] [locs _pointer]))
(define (shader id locs) (let ([s (malloc _Shader 'atomic)]) (ptr-set! s _uint 0 id) (ptr-set! s _pointer 1 locs) s))
(define (shader-id s) (ptr-ref s _uint 0)) (define (shader-locs s) (ptr-ref s _pointer 1))
(define (set-shader-id! s v) (ptr-set! s _uint 0 v)) (define (set-shader-locs! s v) (ptr-set! s _pointer 1 v))

(define _shader-bytes (_list-struct _uint _int _pointer))

(define (shader-list-id lst)   (list-ref lst 0))
(define (shader-list-locs lst) (list-ref lst 2))

(provide _Shader _shader-bytes shader shader-id shader-locs set-shader-id! set-shader-locs!
         shader-list-id shader-list-locs)
