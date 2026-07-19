#lang racket/base
(require "../../raylib/raylib.rkt" ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref _uint _int _float malloc)
         racket/runtime-path)
(define-syntax-rule (log fmt . args)
  (begin (fprintf (current-error-port) fmt . args) (flush-output)))
(define GLSL-VERSION 330)
(define-runtime-path rd "../../../examples/shaders/resources/")
(define (res . p) (path->string (simplify-path (apply build-path rd p))))
(init-window 800 450 "debug5")

;; Load resources
(define texture (load-texture (res "cubicmap_atlas.png")))
(log "A: texture ok~n")

;; Test: gen-texture-mipmaps BEFORE load-material-default
(define (gen-tex-mips tex-list)
  (define ptr (malloc 20 'atomic))
  (ptr-set! ptr _uint 0 (list-ref tex-list 0))
  (ptr-set! ptr _int 1 (list-ref tex-list 1))
  (ptr-set! ptr _int 2 (list-ref tex-list 2))
  (ptr-set! ptr _int 3 (list-ref tex-list 3))
  (ptr-set! ptr _int 4 (list-ref tex-list 4))
  (gen-texture-mipmaps ptr)
  (list (ptr-ref ptr _uint 0)(ptr-ref ptr _int 1)(ptr-ref ptr _int 2)(ptr-ref ptr _int 3)(ptr-ref ptr _int 4)))

(log "B: calling gen-tex-mips...~n")
(set! texture (gen-tex-mips texture))
(log "C: gen-tex-mips done~n")

(set-texture-filter texture TEXTURE-FILTER-TRILINEAR)
(log "D: filter set~n")

(log "E: calling load-material-default...~n")
(define mat-ptr (load-material-default))
(log "F: got ptr=~s~n" mat-ptr)

(close-window)
(log "DONE~n")
