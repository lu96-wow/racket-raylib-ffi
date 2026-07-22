#lang racket/base
(require ffi/unsafe)

(define-cstruct _Sound
  ([stream-buffer _pointer] [stream-processor _pointer]
   [stream-sampleRate _uint] [stream-sampleSize _uint] [stream-channels _uint]
   [_stream-pad _uint] [frameCount _uint]))
(define _sound-bytes (_list-struct _pointer _pointer _uint _uint _uint _uint _uint _uint))

(define (sound-frame-count lst) (list-ref lst 5))
(define (sound-stream-buffer lst) (list-ref lst 0))

(provide _Sound _sound-bytes sound-frame-count sound-stream-buffer)
