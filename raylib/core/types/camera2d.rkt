#lang racket/base

;; types/camera2d.rkt — Camera2D (24 bytes, pass-by-value)

(require ffi/unsafe
         "vector2.rkt")

;; ═══════════════════════════════════════════════════════════
;; C struct
;; ═══════════════════════════════════════════════════════════

(define-cstruct _Camera2D
  ([off-x _float] [off-y _float]
   [tar-x _float] [tar-y _float]
   [rotation _float] [zoom _float]))

;; ═══════════════════════════════════════════════════════════
;; 构造器
;; ═══════════════════════════════════════════════════════════

(define (camera2d offset-x offset-y target-x target-y rotation zoom)
  (let ([cam (malloc _Camera2D 'atomic)])
    (ptr-set! cam _float 0 (exact->inexact offset-x))
    (ptr-set! cam _float 1 (exact->inexact offset-y))
    (ptr-set! cam _float 2 (exact->inexact target-x))
    (ptr-set! cam _float 3 (exact->inexact target-y))
    (ptr-set! cam _float 4 (exact->inexact rotation))
    (ptr-set! cam _float 5 (exact->inexact zoom))
    cam))

;; ═══════════════════════════════════════════════════════════
;; 逐字段访问器
;; ═══════════════════════════════════════════════════════════

(define (camera2d-offset-x c)  (ptr-ref c _float 0))
(define (camera2d-offset-y c)  (ptr-ref c _float 1))
(define (camera2d-target-x c)  (ptr-ref c _float 2))
(define (camera2d-target-y c)  (ptr-ref c _float 3))
(define (camera2d-rotation c)  (ptr-ref c _float 4))
(define (camera2d-zoom c)      (ptr-ref c _float 5))

;; ═══════════════════════════════════════════════════════════
;; 逐字段修改器
;; ═══════════════════════════════════════════════════════════

(define (set-camera2d-offset-x! c v) (ptr-set! c _float 0 (exact->inexact v)))
(define (set-camera2d-offset-y! c v) (ptr-set! c _float 1 (exact->inexact v)))
(define (set-camera2d-target-x! c v) (ptr-set! c _float 2 (exact->inexact v)))
(define (set-camera2d-target-y! c v) (ptr-set! c _float 3 (exact->inexact v)))
(define (set-camera2d-rotation! c v) (ptr-set! c _float 4 (exact->inexact v)))
(define (set-camera2d-zoom! c v)     (ptr-set! c _float 5 (exact->inexact v)))

;; ═══════════════════════════════════════════════════════════
;; 分组访问器 — offset/target 整体取/设
;; ═══════════════════════════════════════════════════════════

(define (camera2d-offset c)
  (vector2 (camera2d-offset-x c) (camera2d-offset-y c)))

(define (camera2d-target c)
  (vector2 (camera2d-target-x c) (camera2d-target-y c)))

(define (set-camera2d-offset! c v)
  (set-camera2d-offset-x! c (vector2-x v))
  (set-camera2d-offset-y! c (vector2-y v)))

(define (set-camera2d-target! c v)
  (set-camera2d-target-x! c (vector2-x v))
  (set-camera2d-target-y! c (vector2-y v)))

;; ═══════════════════════════════════════════════════════════
;; pass-by-value 转换
;; ═══════════════════════════════════════════════════════════

(define _camera2d-bytes
  (_list-struct _float _float _float _float _float _float))

(define (camera2d->bytes cam)
  (list (ptr-ref cam _float 0) (ptr-ref cam _float 1)
        (ptr-ref cam _float 2) (ptr-ref cam _float 3)
        (ptr-ref cam _float 4) (ptr-ref cam _float 5)))

(define (bytes->camera2d lst)
  (let ([cam (malloc _Camera2D 'atomic)])
    (ptr-set! cam _float 0 (list-ref lst 0))
    (ptr-set! cam _float 1 (list-ref lst 1))
    (ptr-set! cam _float 2 (list-ref lst 2))
    (ptr-set! cam _float 3 (list-ref lst 3))
    (ptr-set! cam _float 4 (list-ref lst 4))
    (ptr-set! cam _float 5 (list-ref lst 5))
    cam))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide _Camera2D _camera2d-bytes
         camera2d
         camera2d-offset-x camera2d-offset-y
         camera2d-target-x camera2d-target-y
         camera2d-rotation camera2d-zoom
         set-camera2d-offset-x! set-camera2d-offset-y!
         set-camera2d-target-x! set-camera2d-target-y!
         set-camera2d-rotation! set-camera2d-zoom!
         camera2d-offset camera2d-target
         set-camera2d-offset! set-camera2d-target!
         camera2d->bytes bytes->camera2d)
