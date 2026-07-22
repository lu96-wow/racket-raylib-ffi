#lang racket/base

;; types/material.rkt — Material (32 bytes)

(require ffi/unsafe)

;; ═══════════════════════════════════════════════════════════
;; C struct
;; ═══════════════════════════════════════════════════════════

(define-cstruct _Material
  ([shader-id _uint] [shader-locs _int]
   [maps _pointer]
   [param0 _float] [param1 _float] [param2 _float] [param3 _float]))

;; ═══════════════════════════════════════════════════════════
;; pass-by-value 转换
;; ═══════════════════════════════════════════════════════════

(define _material-bytes
  (_list-struct _uint _int _pointer _pointer _float _float _float _float))

;; ═══════════════════════════════════════════════════════════
;; 列表访问器 (用于 FFI 返回值)
;; ═══════════════════════════════════════════════════════════

(define (material-shader-id lst)  (list-ref lst 0))
(define (material-maps lst)       (list-ref lst 2))
(define (material-param0 lst)     (list-ref lst 3))
(define (material-param1 lst)     (list-ref lst 4))
(define (material-param2 lst)     (list-ref lst 5))
(define (material-param3 lst)     (list-ref lst 6))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide _Material _material-bytes
         material-shader-id material-maps
         material-param0 material-param1 material-param2 material-param3)
