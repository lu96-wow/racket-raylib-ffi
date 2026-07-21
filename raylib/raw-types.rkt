#lang racket/base
;; 转发到新的 raw-types (向后兼容)

(require "core/types/transform.rkt"
         "core/types/bone-info.rkt"
         ffi/unsafe)

(define sizeof-transform   (ctype-sizeof _Transform))
(define sizeof-boneinfo    (ctype-sizeof _BoneInfo))

(define (transform-trans-x p) (ptr-ref p _float 0))
(define (transform-trans-y p) (ptr-ref p _float 1))
(define (transform-trans-z p) (ptr-ref p _float 2))
(define (transform-rot-x p)   (ptr-ref p _float 3))
(define (transform-rot-y p)   (ptr-ref p _float 4))
(define (transform-rot-z p)   (ptr-ref p _float 5))
(define (transform-rot-w p)   (ptr-ref p _float 6))
(define (transform-scale-x p) (ptr-ref p _float 7))
(define (transform-scale-y p) (ptr-ref p _float 8))
(define (transform-scale-z p) (ptr-ref p _float 9))
(define (bone-info-parent p)  (ptr-ref p _int 8))
(define anim-name-length 32)
(define anim-keyframe-count-index 33)
(define anim-keyframe-poses-index 34)

(provide sizeof-transform sizeof-boneinfo
         transform-trans-x transform-trans-y transform-trans-z
         transform-rot-x transform-rot-y transform-rot-z transform-rot-w
         transform-scale-x transform-scale-y transform-scale-z
         bone-info-parent
         anim-name-length anim-keyframe-count-index anim-keyframe-poses-index)
