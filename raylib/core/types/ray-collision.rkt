#lang racket/base
(require ffi/unsafe)
(define-cstruct _RayCollision
  ([hit _stdbool] [distance _float]
   [point-x _float] [point-y _float] [point-z _float]
   [norm-x _float]  [norm-y _float]  [norm-z _float]))

;; pass-by-value
(define _ray-collision-bytes
  (_list-struct _stdbool _float _float _float _float _float _float _float))

(provide _RayCollision _ray-collision-bytes)
