#lang racket/base

;; types/model.rkt — Model (136 bytes)

(require ffi/unsafe)

(define-cstruct _Model
  ([tr-m0 _float] [tr-m1 _float] [tr-m2 _float] [tr-m3 _float]
   [tr-m4 _float] [tr-m5 _float] [tr-m6 _float] [tr-m7 _float]
   [tr-m8 _float] [tr-m9 _float] [tr-m10 _float] [tr-m11 _float]
   [tr-m12 _float] [tr-m13 _float] [tr-m14 _float] [tr-m15 _float]
   [meshCount _int] [materialCount _int]
   [meshes _pointer] [materials _pointer] [meshMaterial _pointer]
   [skeleton-boneCount _int]
   [skeleton-bones _pointer] [skeleton-bindPose _pointer]
   [currentPose _pointer] [boneMatrices _pointer]))


;; pass-by-value
(define _model-bytes
  (_list-struct
   _float _float _float _float
   _float _float _float _float
   _float _float _float _float
   _float _float _float _float
   _int _int
   _pointer _pointer _pointer
   _int _int
   _pointer _pointer
   _pointer _pointer))

(provide _Model _model-bytes)
