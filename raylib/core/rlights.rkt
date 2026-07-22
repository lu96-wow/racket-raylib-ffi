#lang racket/base

;; core/rlights.rkt — 光照系统 (rlights.h) 纯Racket封装

(require ffi/unsafe
         "rcore.rkt"
         "types/color.rkt")

(provide create-light update-light-values reset-lights!
         MAX-LIGHTS LIGHT-DIRECTIONAL LIGHT-POINT
         ;; 光源的命名访问器
         light-enabled? light-type
         light-position-x light-position-y light-position-z
         light-target-x light-target-y light-target-z
         light-color
         set-light-enabled! set-light-position! set-light-target!
         set-light-color!)

(define MAX-LIGHTS 4)
(define LIGHT-DIRECTIONAL 0)
(define LIGHT-POINT 1)
(define lights-count 0)
(define (reset-lights!) (set! lights-count 0))

;; ============================================================
;; 光源字段索引 (内部)
;; ============================================================
;; [0]enabled [1]type [2]px [3]py [4]pz [5]tx [6]ty [7]tz
;; [8]cr  [9]cg  [10]cb [11]ca
;; [12]loc-enabled [13]loc-type [14]loc-position [15]loc-target [16]loc-color

;; ============================================================
;; 命名访问器
;; ============================================================

(define (light-enabled? l)       (= (vector-ref l 0) 1))
(define (light-type l)           (vector-ref l 1))
(define (light-position-x l)     (vector-ref l 2))
(define (light-position-y l)     (vector-ref l 3))
(define (light-position-z l)     (vector-ref l 4))
(define (light-target-x l)       (vector-ref l 5))
(define (light-target-y l)       (vector-ref l 6))
(define (light-target-z l)       (vector-ref l 7))
(define (light-color l)          (color (vector-ref l 8) (vector-ref l 9)
                                        (vector-ref l 10) (vector-ref l 11)))

(define (set-light-enabled! l v)       (vector-set! l 0 (if v 1 0)))
(define (set-light-position! l x y z)  (vector-set! l 2 (exact->inexact x))
                                       (vector-set! l 3 (exact->inexact y))
                                       (vector-set! l 4 (exact->inexact z)))
(define (set-light-target! l x y z)    (vector-set! l 5 (exact->inexact x))
                                       (vector-set! l 6 (exact->inexact y))
                                       (vector-set! l 7 (exact->inexact z)))
(define (set-light-color! l c)         (vector-set! l 8  (color-r c))
                                       (vector-set! l 9  (color-g c))
                                       (vector-set! l 10 (color-b c))
                                       (vector-set! l 11 (color-a c)))

;; ============================================================
;; create-light (两种调用方式)
;; ============================================================

(define create-light
  (case-lambda
    ;; 新式: (create-light type px py pz tx ty tz color shader)
    [(type px py pz tx ty tz color shader)
     (create-light* type px py pz tx ty tz
                    (color-r color) (color-g color) (color-b color) (color-a color)
                    shader)]
    ;; 旧式: (create-light type px py pz tx ty tz cr cg cb ca shader)
    [(type px py pz tx ty tz cr cg cb ca shader)
     (create-light* type px py pz tx ty tz cr cg cb ca shader)]))

(define (create-light* type px py pz tx ty tz cr cg cb ca shader)
  (when (>= lights-count MAX-LIGHTS) (error "create-light: max lights reached"))
  (define idx lights-count)
  (set! lights-count (+ lights-count 1))
  (define prefix (format "lights[~a]." idx))
  (define light (make-vector 17))
  (vector-set! light 0 1) (vector-set! light 1 type)
  (vector-set! light 2 (exact->inexact px)) (vector-set! light 3 (exact->inexact py)) (vector-set! light 4 (exact->inexact pz))
  (vector-set! light 5 (exact->inexact tx)) (vector-set! light 6 (exact->inexact ty)) (vector-set! light 7 (exact->inexact tz))
  (vector-set! light 8 cr) (vector-set! light 9 cg) (vector-set! light 10 cb) (vector-set! light 11 ca)
  (vector-set! light 12 (get-shader-location shader (string-append prefix "enabled")))
  (vector-set! light 13 (get-shader-location shader (string-append prefix "type")))
  (vector-set! light 14 (get-shader-location shader (string-append prefix "position")))
  (vector-set! light 15 (get-shader-location shader (string-append prefix "target")))
  (vector-set! light 16 (get-shader-location shader (string-append prefix "color")))
  (update-light-values shader light)
  light)

(define (update-light-values shader light)
  (define enabled (vector-ref light 0)) (define type (vector-ref light 1))
  (define px (vector-ref light 2)) (define py (vector-ref light 3)) (define pz (vector-ref light 4))
  (define tx (vector-ref light 5)) (define ty (vector-ref light 6)) (define tz (vector-ref light 7))
  (define cr (vector-ref light 8)) (define cg (vector-ref light 9)) (define cb (vector-ref light 10)) (define ca (vector-ref light 11))
  (define el (vector-ref light 12)) (define tl (vector-ref light 13))
  (define pl (vector-ref light 14)) (define tgl (vector-ref light 15)) (define cl (vector-ref light 16))
  (define ib (malloc _int 1 'atomic)) (define v3 (malloc _float 3 'atomic)) (define v4 (malloc _float 4 'atomic))
  (ptr-set! ib _int 0 enabled) (set-shader-value shader el ib 4)
  (ptr-set! ib _int 0 type) (set-shader-value shader tl ib 4)
  (ptr-set! v3 _float 0 px) (ptr-set! v3 _float 1 py) (ptr-set! v3 _float 2 pz) (set-shader-value shader pl v3 2)
  (ptr-set! v3 _float 0 tx) (ptr-set! v3 _float 1 ty) (ptr-set! v3 _float 2 tz) (set-shader-value shader tgl v3 2)
  (ptr-set! v4 _float 0 (exact->inexact (/ cr 255.0))) (ptr-set! v4 _float 1 (exact->inexact (/ cg 255.0)))
  (ptr-set! v4 _float 2 (exact->inexact (/ cb 255.0))) (ptr-set! v4 _float 3 (exact->inexact (/ ca 255.0)))
  (set-shader-value shader cl v4 3))
