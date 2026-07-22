#lang racket/base
(require ffi/unsafe)

(define-cstruct _ModelAnimation
  ([name0 _ubyte] [name1 _ubyte] [name2 _ubyte] [name3 _ubyte]
   [name4 _ubyte] [name5 _ubyte] [name6 _ubyte] [name7 _ubyte]
   [name8 _ubyte] [name9 _ubyte] [name10 _ubyte] [name11 _ubyte]
   [name12 _ubyte] [name13 _ubyte] [name14 _ubyte] [name15 _ubyte]
   [name16 _ubyte] [name17 _ubyte] [name18 _ubyte] [name19 _ubyte]
   [name20 _ubyte] [name21 _ubyte] [name22 _ubyte] [name23 _ubyte]
   [name24 _ubyte] [name25 _ubyte] [name26 _ubyte] [name27 _ubyte]
   [name28 _ubyte] [name29 _ubyte] [name30 _ubyte] [name31 _ubyte]
   [boneCount _int] [keyframeCount _int] [keyframePoses _pointer]))

(define _model-animation-bytes
  (_list-struct
   _ubyte _ubyte _ubyte _ubyte _ubyte _ubyte _ubyte _ubyte
   _ubyte _ubyte _ubyte _ubyte _ubyte _ubyte _ubyte _ubyte
   _ubyte _ubyte _ubyte _ubyte _ubyte _ubyte _ubyte _ubyte
   _ubyte _ubyte _ubyte _ubyte _ubyte _ubyte _ubyte _ubyte
   _int _int _pointer))

(define (model-animation-bone-count lst)      (list-ref lst 32))
(define (model-animation-frame-count lst)     (list-ref lst 33))
(define (model-animation-frame-poses lst)     (list-ref lst 34))

(provide _ModelAnimation _model-animation-bytes
         model-animation-bone-count model-animation-frame-count model-animation-frame-poses)
