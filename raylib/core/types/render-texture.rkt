#lang racket/base

;; types/render-texture.rkt — RenderTexture (44 bytes)

(require ffi/unsafe)

;; ═══════════════════════════════════════════════════════════
;; C struct
;; ═══════════════════════════════════════════════════════════

(define-cstruct _RenderTexture
  ([id _uint] [tex-id _uint]
   [tex-width _int] [tex-height _int] [tex-mipmaps _int] [tex-format _int]
   [dep-id _uint]
   [dep-width _int] [dep-height _int] [dep-mipmaps _int] [dep-format _int]))

;; ═══════════════════════════════════════════════════════════
;; 构造器
;; ═══════════════════════════════════════════════════════════

(define (render-texture id tex-id tex-w tex-h tex-m tex-f
                        dep-id dep-w dep-h dep-m dep-f)
  (let ([rt (malloc _RenderTexture 'atomic)])
    (ptr-set! rt _uint 0 id)
    (ptr-set! rt _uint 1 tex-id)
    (ptr-set! rt _int 2 tex-w)
    (ptr-set! rt _int 3 tex-h)
    (ptr-set! rt _int 4 tex-m)
    (ptr-set! rt _int 5 tex-f)
    (ptr-set! rt _uint 6 dep-id)
    (ptr-set! rt _int 7 dep-w)
    (ptr-set! rt _int 8 dep-h)
    (ptr-set! rt _int 9 dep-m)
    (ptr-set! rt _int 10 dep-f)
    rt))

;; ═══════════════════════════════════════════════════════════
;; pass-by-value 转换
;; ═══════════════════════════════════════════════════════════

(define _render-texture-bytes
  (_list-struct _uint _uint _int _int _int _int _uint _int _int _int _int))

;; ═══════════════════════════════════════════════════════════
;; 列表访问器 (用于 FFI 返回值)
;; ═══════════════════════════════════════════════════════════

(define (render-texture-id lst)           (list-ref lst 0))
(define (render-texture-tex-id lst)       (list-ref lst 1))
(define (render-texture-tex-width lst)    (list-ref lst 2))
(define (render-texture-tex-height lst)   (list-ref lst 3))
(define (render-texture-tex-mipmaps lst)  (list-ref lst 4))
(define (render-texture-tex-format lst)   (list-ref lst 5))
(define (render-texture-dep-id lst)       (list-ref lst 6))
(define (render-texture-dep-width lst)    (list-ref lst 7))
(define (render-texture-dep-height lst)   (list-ref lst 8))
(define (render-texture-dep-mipmaps lst)  (list-ref lst 9))
(define (render-texture-dep-format lst)   (list-ref lst 10))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide _RenderTexture _render-texture-bytes
         render-texture
         render-texture-id render-texture-tex-id
         render-texture-tex-width render-texture-tex-height
         render-texture-tex-mipmaps render-texture-tex-format
         render-texture-dep-id render-texture-dep-width render-texture-dep-height
         render-texture-dep-mipmaps render-texture-dep-format)
