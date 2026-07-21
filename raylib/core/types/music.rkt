#lang racket/base

;; types/music.rkt — Music (56 bytes, AudioStream inline)

(require ffi/unsafe)

(define-cstruct _Music
  ([stream-buffer _pointer] [stream-processor _pointer]
   [stream-sampleRate _uint] [stream-sampleSize _uint] [stream-channels _uint]
   [_stream-pad _uint]
   [frameCount _uint]
   [looping _stdbool]
   [ctxType _int] [ctxData _pointer]))


;; pass-by-value
(define _music-bytes
  (_list-struct _pointer _pointer _uint _uint _uint _uint _uint _uint
                _int _pointer))

(provide _Music _music-bytes)
