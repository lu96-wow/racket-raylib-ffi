#lang racket/base
(require ffi/unsafe)

(define-cstruct _Wave ([frameCount _uint] [sampleRate _uint] [sampleSize _uint] [channels _uint] [data _pointer]))
(define _wave-bytes (_list-struct _uint _uint _uint _uint _pointer))

(define (wave-frame-count lst)  (list-ref lst 0))
(define (wave-sample-rate lst)  (list-ref lst 1))
(define (wave-sample-size lst)  (list-ref lst 2))
(define (wave-channels lst)     (list-ref lst 3))
(define (wave-data lst)         (list-ref lst 4))

(provide _Wave _wave-bytes
         wave-frame-count wave-sample-rate wave-sample-size wave-channels wave-data)
