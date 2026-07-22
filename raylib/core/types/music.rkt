#lang racket/base
(require ffi/unsafe)

(define-cstruct _Music
  ([stream-buffer _pointer] [stream-processor _pointer]
   [stream-sampleRate _uint] [stream-sampleSize _uint] [stream-channels _uint]
   [_stream-pad _uint] [frameCount _uint] [looping _stdbool] [ctxType _int] [ctxData _pointer]))
(define _music-bytes
  (_list-struct _pointer _pointer _uint _uint _uint _uint _uint _uint _int _pointer))

(define (music-frame-count lst) (list-ref lst 5))
(define (music-looping lst)     (list-ref lst 6))
(define (music-ctx-type lst)    (list-ref lst 7))
(define (music-ctx-data lst)    (list-ref lst 8))

(provide _Music _music-bytes music-frame-count music-looping music-ctx-type music-ctx-data)
