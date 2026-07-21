#lang racket/base

;; types/file-path-list.rkt — FilePathList (16 bytes)

(require ffi/unsafe)

(define-cstruct _FilePathList
  ([count _uint] [paths _pointer]))


;; pass-by-value
(define _filepathlist-bytes (_list-struct _uint _pointer))

(provide _FilePathList _filepathlist-bytes)
