#lang racket/base

;; raylib/core/lib.rkt — 共享库发现与加载

(require ffi/unsafe
         racket/string)

(define candidate-paths
  (list
   (λ () (getenv "RAYLIB_SO_PATH"))
   (λ () "/home/debian/raylib/build/raylib/libraylib.so")
   (λ ()
     (let-values ([(dir _1 _2)
                   (split-path (or (current-load-relative-directory)
                                   (current-directory)))])
       (build-path dir ".." ".." "build" "raylib" "libraylib.so")))
   (λ () "/usr/local/lib/libraylib.so")
   (λ () "/usr/lib/libraylib.so")
   (λ () "/usr/lib/x86_64-linux-gnu/libraylib.so")
   (λ () "libraylib.so")))

(define (find-raylib-lib)
  (let loop ([remaining candidate-paths] [tried '()])
    (if (null? remaining)
        (error 'find-raylib-lib
               "Cannot find libraylib.so. Tried:\n  ~a\nSet RAYLIB_SO_PATH."
               (string-join (reverse tried) "\n  "))
        (let* ([thunk (car remaining)]
               [path  (thunk)])
          (if (not path)
              (loop (cdr remaining) (cons "(null)" tried))
              (with-handlers ([exn:fail:filesystem?
                               (λ (e)
                                 (loop (cdr remaining)
                                       (cons (format "~a (FAILED)" path)
                                             tried)))])
                (ffi-lib path)))))))

(define lib (find-raylib-lib))

(provide lib find-raylib-lib candidate-paths)
