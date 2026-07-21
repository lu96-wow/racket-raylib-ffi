#lang racket/base

;; types/model-skeleton.rkt — ModelSkeleton (24 bytes)

(require ffi/unsafe)

(define-cstruct _ModelSkeleton
  ([boneCount _int] [bones _pointer] [bindPose _pointer]))

(provide _ModelSkeleton)
