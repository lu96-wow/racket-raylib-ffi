#lang racket/base

;; types/file-path-list.rkt — FilePathList (16 bytes)

(require ffi/unsafe)

(define-cstruct _FilePathList
  ([count _uint] [paths _pointer]))

(define _filepathlist-bytes
  (_list-struct _uint _pointer))

(define (file-path-list-count lst) (list-ref lst 0))
(define (file-path-list-paths lst) (list-ref lst 1))

(provide _FilePathList _filepathlist-bytes
         file-path-list-count file-path-list-paths)
