#lang racket/base

;; rlights.h — Racket 移植
;; 不需要 FFI，纯 Racket 封装已有的 raylib API

(require ffi/unsafe
         (only-in ffi/unsafe ptr-set! _float _int malloc)
         "raylib.rkt")

(define MAX-LIGHTS 4)
(define LIGHT-DIRECTIONAL 0)
(define LIGHT-POINT 1)

(define lights-count 0)

(define (reset-lights!) (set! lights-count 0))

(define (create-light type px py pz tx ty tz cr cg cb ca shader)
  (when (>= lights-count MAX-LIGHTS)
    (error "create-light: max lights reached"))
  (define idx lights-count)
  (set! lights-count (+ lights-count 1))
  (define prefix (format "lights[~a]." idx))

  (define light (make-vector 17))
  (vector-set! light 0 1)          ; enabled
  (vector-set! light 1 type)
  (vector-set! light 2 (exact->inexact px))
  (vector-set! light 3 (exact->inexact py))
  (vector-set! light 4 (exact->inexact pz))
  (vector-set! light 5 (exact->inexact tx))
  (vector-set! light 6 (exact->inexact ty))
  (vector-set! light 7 (exact->inexact tz))
  (vector-set! light 8 cr)
  (vector-set! light 9 cg)
  (vector-set! light 10 cb)
  (vector-set! light 11 ca)
  (vector-set! light 12 (get-shader-location shader (string-append prefix "enabled")))
  (vector-set! light 13 (get-shader-location shader (string-append prefix "type")))
  (vector-set! light 14 (get-shader-location shader (string-append prefix "position")))
  (vector-set! light 15 (get-shader-location shader (string-append prefix "target")))
  (vector-set! light 16 (get-shader-location shader (string-append prefix "color")))
  ;; C CreateLight calls UpdateLightValues internally to upload values
  (update-light-values shader light)
  light)

(define (update-light-values shader light)
  (define enabled    (vector-ref light 0))
  (define type       (vector-ref light 1))
  (define px (vector-ref light 2))  (define py (vector-ref light 3))  (define pz (vector-ref light 4))
  (define tx (vector-ref light 5))  (define ty (vector-ref light 6))  (define tz (vector-ref light 7))
  (define cr (vector-ref light 8))  (define cg (vector-ref light 9))
  (define cb (vector-ref light 10)) (define ca (vector-ref light 11))
  (define enabled-loc (vector-ref light 12))
  (define type-loc    (vector-ref light 13))
  (define pos-loc     (vector-ref light 14))
  (define target-loc  (vector-ref light 15))
  (define color-loc   (vector-ref light 16))

  (define i-buf  (malloc _int 1 'atomic))
  (define v3-buf (malloc _float 3 'atomic))
  (define v4-buf (malloc _float 4 'atomic))

  (ptr-set! i-buf _int 0 enabled)
  (set-shader-value shader enabled-loc i-buf SHADER-UNIFORM-INT)
  (ptr-set! i-buf _int 0 type)
  (set-shader-value shader type-loc i-buf SHADER-UNIFORM-INT)

  (ptr-set! v3-buf _float 0 px) (ptr-set! v3-buf _float 1 py) (ptr-set! v3-buf _float 2 pz)
  (set-shader-value shader pos-loc v3-buf SHADER-UNIFORM-VEC3)
  (ptr-set! v3-buf _float 0 tx) (ptr-set! v3-buf _float 1 ty) (ptr-set! v3-buf _float 2 tz)
  (set-shader-value shader target-loc v3-buf SHADER-UNIFORM-VEC3)

  (ptr-set! v4-buf _float 0 (exact->inexact (/ cr 255.0)))
  (ptr-set! v4-buf _float 1 (exact->inexact (/ cg 255.0)))
  (ptr-set! v4-buf _float 2 (exact->inexact (/ cb 255.0)))
  (ptr-set! v4-buf _float 3 (exact->inexact (/ ca 255.0)))
  (set-shader-value shader color-loc v4-buf SHADER-UNIFORM-VEC4))

(provide
 create-light update-light-values
 reset-lights!
 MAX-LIGHTS LIGHT-DIRECTIONAL LIGHT-POINT)
