#lang racket/base

;; types/sound.rkt — Sound (40 bytes, AudioStream inline)

(require ffi/unsafe)

(define-cstruct _Sound
  ([stream-buffer _pointer] [stream-processor _pointer]
   [stream-sampleRate _uint] [stream-sampleSize _uint] [stream-channels _uint]
   [_stream-pad _uint]
   [frameCount _uint]))


;; pass-by-value
(define _sound-bytes
  (_list-struct _pointer _pointer _uint _uint _uint _uint _uint _uint))

(provide _Sound _sound-bytes)
