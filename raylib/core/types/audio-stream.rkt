#lang racket/base
(require ffi/unsafe)

(define-cstruct _AudioStream ([buffer _pointer] [processor _pointer] [sampleRate _uint] [sampleSize _uint] [channels _uint]))
(define _audio-stream-bytes (_list-struct _pointer _pointer _uint _uint _uint))

(define (audio-stream-buffer lst)      (list-ref lst 0))
(define (audio-stream-processor lst)   (list-ref lst 1))
(define (audio-stream-sample-rate lst) (list-ref lst 2))
(define (audio-stream-sample-size lst) (list-ref lst 3))
(define (audio-stream-channels lst)    (list-ref lst 4))

(provide _AudioStream _audio-stream-bytes
         audio-stream-buffer audio-stream-processor
         audio-stream-sample-rate audio-stream-sample-size audio-stream-channels)
