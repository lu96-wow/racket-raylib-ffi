#lang racket/base

;; types/image.rkt — Image (20 bytes, pass-by-value)

(require ffi/unsafe)

;; ═══════════════════════════════════════════════════════════
;; C struct
;; ═══════════════════════════════════════════════════════════

(define-cstruct _Image
  ([data _pointer] [width _int] [height _int] [mipmaps _int] [format _int]))

;; ═══════════════════════════════════════════════════════════
;; 构造器
;; ═══════════════════════════════════════════════════════════

(define (image data width height mipmaps format)
  (let ([img (malloc _Image 'atomic)])
    (ptr-set! img _pointer 0 data)
    (ptr-set! img _int 1 width)
    (ptr-set! img _int 2 height)
    (ptr-set! img _int 3 mipmaps)
    (ptr-set! img _int 4 format)
    img))

;; ═══════════════════════════════════════════════════════════
;; pass-by-value 转换
;; ═══════════════════════════════════════════════════════════

(define _image-bytes
  (_list-struct _pointer _int _int _int _int))

(define (image->bytes img)
  (list (ptr-ref img _pointer 0)
        (ptr-ref img _int 2)
        (ptr-ref img _int 3)
        (ptr-ref img _int 4)
        (ptr-ref img _int 5)))

(define (bytes->image lst)
  (let ([p (malloc _Image 'atomic)])
    (ptr-set! p _pointer 0 (list-ref lst 0))
    (ptr-set! p _int 2 (list-ref lst 1))
    (ptr-set! p _int 3 (list-ref lst 2))
    (ptr-set! p _int 4 (list-ref lst 3))
    (ptr-set! p _int 5 (list-ref lst 4))
    p))

;; ═══════════════════════════════════════════════════════════
;; 列表访问器 (用于 FFI 返回的 bytes list)
;; ═══════════════════════════════════════════════════════════

(define (image-data lst)     (list-ref lst 0))
(define (image-width lst)    (list-ref lst 1))
(define (image-height lst)   (list-ref lst 2))
(define (image-mipmaps lst)  (list-ref lst 3))
(define (image-format lst)   (list-ref lst 4))

;; 将 bytes list 转为 cpointer（兼容旧名 image-list->ptr）
(define image-list->ptr bytes->image)

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide _Image _image-bytes
         image image->bytes bytes->image image-list->ptr
         image-data image-width image-height image-mipmaps image-format)
