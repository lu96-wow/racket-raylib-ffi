#lang racket/base

;; types/file-path-list.rkt — FilePathList (16 bytes)

(require ffi/unsafe)

;; ═══════════════════════════════════════════════════════════
;; C struct
;; ═══════════════════════════════════════════════════════════

(define-cstruct _FilePathList
  ([count _uint] [paths _pointer]))

;; ═══════════════════════════════════════════════════════════
;; pass-by-value 转换
;; ═══════════════════════════════════════════════════════════

(define _file-path-list-bytes
  (_list-struct _uint _pointer))

;; ═══════════════════════════════════════════════════════════
;; 列表访问器 (用于 FFI 返回值)
;; ═══════════════════════════════════════════════════════════

(define (file-path-list-count lst) (list-ref lst 0))
(define (file-path-list-paths lst) (list-ref lst 1))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide _FilePathList _file-path-list-bytes
         file-path-list-count file-path-list-paths)
