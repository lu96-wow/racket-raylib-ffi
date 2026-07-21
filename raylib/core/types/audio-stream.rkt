#lang racket/base

;; types/audio-stream.rkt — AudioStream (32 bytes)

(require ffi/unsafe)

(define-cstruct _AudioStream
  ([buffer _pointer] [processor _pointer]
   [sampleRate _uint] [sampleSize _uint] [channels _uint]))


;; pass-by-value
(define _audio-stream-bytes
  (_list-struct _pointer _pointer _uint _uint _uint))

(provide _AudioStream _audio-stream-bytes)
