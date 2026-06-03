#lang racket

;; 把 test/ 下所有 (assert-= expr #t) → (assert-true expr)
;; 和 (assert-= expr #f) → (assert-false expr)

(define files
  (list "core/test-input.rkt" "core/test-window.rkt"
        "core/test-misc.rkt" "core/test-types.rkt"
        "shapes/test-top-down-lights-apis.rkt"))

(for ([f files])
  (printf "fixing ~a~n" f)
  (define path (string-append "../test/" f))
  (define content (file->string path))
  (define fixed
    (regexp-replace* #px"\\(assert-=\\s*\\(([^)]+)\\)\\s*#t\\)"
                     content " (assert-true (\\1))"))
  (define fixed2
    (regexp-replace* #px"\\(assert-=\\s*\\(([^)]+)\\)\\s*#f\\)"
                     fixed " (assert-false (\\1))"))
  (with-output-to-file path #:exists 'replace
    (λ () (display fixed2))))
