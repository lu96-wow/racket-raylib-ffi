#lang racket/base

;; types/texture.rkt — Texture (20 bytes, pass-by-value)
;;
;; Texture 是纯值类型（5 个 int 字段），所有 FFI 函数通过
;; _texture-bytes 传值。因此构造器返回普通 list 而非 cpointer。
;; 如需逐字段访问，使用 list-ref 访问器。

(require ffi/unsafe)

;; ═══════════════════════════════════════════════════════════
;; C struct
;; ═══════════════════════════════════════════════════════════

(define-cstruct _Texture
  ([id _uint] [width _int] [height _int] [mipmaps _int] [format _int]))

;; ═══════════════════════════════════════════════════════════
;; 构造器 (返回 list — Texture 始终按值传递)
;; ═══════════════════════════════════════════════════════════

(define (texture id width height mipmaps format)
  (list id width height mipmaps format))

;; ═══════════════════════════════════════════════════════════
;; pass-by-value 类型定义
;; ═══════════════════════════════════════════════════════════

(define _texture-bytes
  (_list-struct _uint _int _int _int _int))

;; ═══════════════════════════════════════════════════════════
;; 列表访问器 (用于 FFI 返回值)
;; ═══════════════════════════════════════════════════════════

(define (texture-id lst)       (list-ref lst 0))
(define (texture-width lst)    (list-ref lst 1))
(define (texture-height lst)   (list-ref lst 2))
(define (texture-mipmaps lst)  (list-ref lst 3))
(define (texture-format lst)   (list-ref lst 4))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide _Texture _texture-bytes
         texture
         texture-id texture-width texture-height texture-mipmaps texture-format)
