#lang racket/base
(require ffi/unsafe)
(define-cstruct _Camera3D ([pos-x _float] [pos-y _float] [pos-z _float] [tar-x _float] [tar-y _float] [tar-z _float] [up-x _float] [up-y _float] [up-z _float] [fovy _float] [projection _int]))
(define (camera3d pos-x pos-y pos-z tar-x tar-y tar-z up-x up-y up-z fovy projection)
  (let ([cam (malloc _Camera3D 'atomic)])
    (ptr-set! cam _float 0 (exact->inexact pos-x)) (ptr-set! cam _float 1 (exact->inexact pos-y)) (ptr-set! cam _float 2 (exact->inexact pos-z))
    (ptr-set! cam _float 3 (exact->inexact tar-x)) (ptr-set! cam _float 4 (exact->inexact tar-y)) (ptr-set! cam _float 5 (exact->inexact tar-z))
    (ptr-set! cam _float 6 (exact->inexact up-x)) (ptr-set! cam _float 7 (exact->inexact up-y)) (ptr-set! cam _float 8 (exact->inexact up-z))
    (ptr-set! cam _float 9 (exact->inexact fovy)) (ptr-set! cam _int 10 projection) cam))
(define (camera3d-pos-x c) (ptr-ref c _float 0)) (define (camera3d-pos-y c) (ptr-ref c _float 1)) (define (camera3d-pos-z c) (ptr-ref c _float 2))
(define (camera3d-tar-x c) (ptr-ref c _float 3)) (define (camera3d-tar-y c) (ptr-ref c _float 4)) (define (camera3d-tar-z c) (ptr-ref c _float 5))
(define (camera3d-up-x c) (ptr-ref c _float 6)) (define (camera3d-up-y c) (ptr-ref c _float 7)) (define (camera3d-up-z c) (ptr-ref c _float 8))
(define (camera3d-fovy c) (ptr-ref c _float 9)) (define (camera3d-projection c) (ptr-ref c _int 10))
(define (set-camera3d-pos-x! c v) (ptr-set! c _float 0 (exact->inexact v))) (define (set-camera3d-pos-y! c v) (ptr-set! c _float 1 (exact->inexact v)))
(define (set-camera3d-pos-z! c v) (ptr-set! c _float 2 (exact->inexact v))) (define (set-camera3d-tar-x! c v) (ptr-set! c _float 3 (exact->inexact v)))
(define (set-camera3d-tar-y! c v) (ptr-set! c _float 4 (exact->inexact v))) (define (set-camera3d-tar-z! c v) (ptr-set! c _float 5 (exact->inexact v)))
(define (set-camera3d-up-x! c v) (ptr-set! c _float 6 (exact->inexact v))) (define (set-camera3d-up-y! c v) (ptr-set! c _float 7 (exact->inexact v)))
(define (set-camera3d-up-z! c v) (ptr-set! c _float 8 (exact->inexact v))) (define (set-camera3d-fovy! c v) (ptr-set! c _float 9 (exact->inexact v)))
(define (set-camera3d-projection! c v) (ptr-set! c _int 10 v))

;; pass-by-value
(define _camera3d-bytes
  (_list-struct
   _float _float _float
   _float _float _float
   _float _float _float
   _float _int))
(define (camera3d->bytes cam)
  (list (ptr-ref cam _float 0) (ptr-ref cam _float 1) (ptr-ref cam _float 2)
        (ptr-ref cam _float 3) (ptr-ref cam _float 4) (ptr-ref cam _float 5)
        (ptr-ref cam _float 6) (ptr-ref cam _float 7) (ptr-ref cam _float 8)
        (ptr-ref cam _float 9) (ptr-ref cam _int 10)))

(provide _Camera3D _camera3d-bytes camera3d camera3d-pos-x camera3d-pos-y camera3d-pos-z
         camera3d-tar-x camera3d-tar-y camera3d-tar-z camera3d-up-x camera3d-up-y camera3d-up-z
         camera3d-fovy camera3d-projection
         set-camera3d-pos-x! set-camera3d-pos-y! set-camera3d-pos-z!
         set-camera3d-tar-x! set-camera3d-tar-y! set-camera3d-tar-z!
         set-camera3d-up-x! set-camera3d-up-y! set-camera3d-up-z!
         set-camera3d-fovy! set-camera3d-projection!
         camera3d->bytes)
