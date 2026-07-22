#lang racket/base

;; types/npatch-info.rkt — NPatchInfo (36 bytes, pass-by-value)

(require ffi/unsafe)

;; ═══════════════════════════════════════════════════════════
;; C struct
;; ═══════════════════════════════════════════════════════════

(define-cstruct _NPatchInfo
  ([src-x _float] [src-y _float] [src-width _float] [src-height _float]
   [left _int] [top _int] [right _int] [bottom _int] [layout _int]))

;; ═══════════════════════════════════════════════════════════
;; pass-by-value 转换
;; ═══════════════════════════════════════════════════════════

(define _npatch-info-bytes
  (_list-struct _float _float _float _float _int _int _int _int _int))

;; ═══════════════════════════════════════════════════════════
;; 列表访问器 (用于 FFI 返回值)
;; ═══════════════════════════════════════════════════════════

(define (npatch-info-src-x lst)       (list-ref lst 0))
(define (npatch-info-src-y lst)       (list-ref lst 1))
(define (npatch-info-src-width lst)   (list-ref lst 2))
(define (npatch-info-src-height lst)  (list-ref lst 3))
(define (npatch-info-left lst)        (list-ref lst 4))
(define (npatch-info-top lst)         (list-ref lst 5))
(define (npatch-info-right lst)       (list-ref lst 6))
(define (npatch-info-bottom lst)      (list-ref lst 7))
(define (npatch-info-layout lst)      (list-ref lst 8))

;; ═══════════════════════════════════════════════════════════
;; bytes → cpointer 转换
;; ═══════════════════════════════════════════════════════════

(define (bytes->npatch-info lst)
  (let ([n (malloc _NPatchInfo 'atomic)])
    (ptr-set! n _float 0 (list-ref lst 0))
    (ptr-set! n _float 1 (list-ref lst 1))
    (ptr-set! n _float 2 (list-ref lst 2))
    (ptr-set! n _float 3 (list-ref lst 3))
    (ptr-set! n _int 4 (list-ref lst 4))
    (ptr-set! n _int 5 (list-ref lst 5))
    (ptr-set! n _int 6 (list-ref lst 6))
    (ptr-set! n _int 7 (list-ref lst 7))
    (ptr-set! n _int 8 (list-ref lst 8))
    n))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide _NPatchInfo _npatch-info-bytes
         npatch-info-src-x npatch-info-src-y
         npatch-info-src-width npatch-info-src-height
         npatch-info-left npatch-info-top npatch-info-right npatch-info-bottom
         npatch-info-layout
         bytes->npatch-info)
