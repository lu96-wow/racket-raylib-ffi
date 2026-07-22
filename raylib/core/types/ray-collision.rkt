#lang racket/base

;; types/ray-collision.rkt — RayCollision (32 bytes, pass-by-value)

(require ffi/unsafe)

;; ═══════════════════════════════════════════════════════════
;; C struct
;; ═══════════════════════════════════════════════════════════

(define-cstruct _RayCollision
  ([hit _stdbool] [distance _float]
   [point-x _float] [point-y _float] [point-z _float]
   [norm-x _float]  [norm-y _float]  [norm-z _float]))

;; ═══════════════════════════════════════════════════════════
;; pass-by-value 转换
;; ═══════════════════════════════════════════════════════════

(define _ray-collision-bytes
  (_list-struct _stdbool _float _float _float _float _float _float _float))

;; ═══════════════════════════════════════════════════════════
;; 列表访问器 (用于 FFI 返回值)
;; ═══════════════════════════════════════════════════════════

(define (ray-collision-hit lst)       (list-ref lst 0))
(define (ray-collision-distance lst)  (list-ref lst 1))
(define (ray-collision-point-x lst)   (list-ref lst 2))
(define (ray-collision-point-y lst)   (list-ref lst 3))
(define (ray-collision-point-z lst)   (list-ref lst 4))
(define (ray-collision-normal-x lst)  (list-ref lst 5))
(define (ray-collision-normal-y lst)  (list-ref lst 6))
(define (ray-collision-normal-z lst)  (list-ref lst 7))

;; ═══════════════════════════════════════════════════════════
;; bytes → cpointer 转换
;; ═══════════════════════════════════════════════════════════

(define (bytes->ray-collision lst)
  (let ([r (malloc _RayCollision 'atomic)])
    (ptr-set! r _stdbool 0 (list-ref lst 0))
    (ptr-set! r _float 1 (list-ref lst 1))
    (ptr-set! r _float 2 (list-ref lst 2))
    (ptr-set! r _float 3 (list-ref lst 3))
    (ptr-set! r _float 4 (list-ref lst 4))
    (ptr-set! r _float 5 (list-ref lst 5))
    (ptr-set! r _float 6 (list-ref lst 6))
    (ptr-set! r _float 7 (list-ref lst 7))
    r))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide _RayCollision _ray-collision-bytes
         ray-collision-hit ray-collision-distance
         ray-collision-point-x ray-collision-point-y ray-collision-point-z
         ray-collision-normal-x ray-collision-normal-y ray-collision-normal-z
         bytes->ray-collision)
