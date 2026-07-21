#lang racket/base

;; types/bone-info.rkt — BoneInfo (36 bytes: name[32] + parent int)

(require ffi/unsafe)

(define-cstruct _BoneInfo
  ([name0 _ubyte] [name1 _ubyte] [name2 _ubyte] [name3 _ubyte]
   [name4 _ubyte] [name5 _ubyte] [name6 _ubyte] [name7 _ubyte]
   [name8 _ubyte] [name9 _ubyte] [name10 _ubyte] [name11 _ubyte]
   [name12 _ubyte] [name13 _ubyte] [name14 _ubyte] [name15 _ubyte]
   [name16 _ubyte] [name17 _ubyte] [name18 _ubyte] [name19 _ubyte]
   [name20 _ubyte] [name21 _ubyte] [name22 _ubyte] [name23 _ubyte]
   [name24 _ubyte] [name25 _ubyte] [name26 _ubyte] [name27 _ubyte]
   [name28 _ubyte] [name29 _ubyte] [name30 _ubyte] [name31 _ubyte]
   [parent _int]))

(provide _BoneInfo)
