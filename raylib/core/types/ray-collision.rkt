#lang racket/base
(require ffi/unsafe)

(define-cstruct _RayCollision
  ([hit _stdbool] [distance _float]
   [point-x _float] [point-y _float] [point-z _float]
   [norm-x _float]  [norm-y _float]  [norm-z _float]))
(define _ray-collision-bytes
  (_list-struct _stdbool _float _float _float _float _float _float _float))

(define (ray-collision-hit lst)       (list-ref lst 0))
(define (ray-collision-distance lst)  (list-ref lst 1))
(define (ray-collision-point-x lst)   (list-ref lst 2))
(define (ray-collision-point-y lst)   (list-ref lst 3))
(define (ray-collision-point-z lst)   (list-ref lst 4))
(define (ray-collision-normal-x lst)  (list-ref lst 5))
(define (ray-collision-normal-y lst)  (list-ref lst 6))
(define (ray-collision-normal-z lst)  (list-ref lst 7))

(provide _RayCollision _ray-collision-bytes
         ray-collision-hit ray-collision-distance
         ray-collision-point-x ray-collision-point-y ray-collision-point-z
         ray-collision-normal-x ray-collision-normal-y ray-collision-normal-z)
