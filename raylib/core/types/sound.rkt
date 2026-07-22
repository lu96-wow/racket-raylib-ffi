#lang racket/base

;; types/sound.rkt — Sound (embeds AudioStream + frameCount)

(require ffi/unsafe)

(define-cstruct _Sound
  ([stream-buffer _pointer] [stream-processor _pointer]
   [stream-sampleRate _uint] [stream-sampleSize _uint] [stream-channels _uint]
   [_stream-pad _uint] [frameCount _uint]))

(define _sound-bytes
  (_list-struct _pointer _pointer _uint _uint _uint _uint _uint _uint))

(define (sound-stream-buffer lst) (list-ref lst 0))
(define (sound-frame-count lst)   (list-ref lst 6))

(provide _Sound _sound-bytes
         sound-stream-buffer sound-frame-count)
