#lang racket/base

;; types/vr-stereo-config.rkt — VrStereoConfig (304 bytes)

(require ffi/unsafe)

(define-cstruct _VrStereoConfig
  ([proj0-m0 _float] [proj0-m1 _float] [proj0-m2 _float] [proj0-m3 _float]
   [proj0-m4 _float] [proj0-m5 _float] [proj0-m6 _float] [proj0-m7 _float]
   [proj0-m8 _float] [proj0-m9 _float] [proj0-m10 _float] [proj0-m11 _float]
   [proj0-m12 _float] [proj0-m13 _float] [proj0-m14 _float] [proj0-m15 _float]
   [proj1-m0 _float] [proj1-m1 _float] [proj1-m2 _float] [proj1-m3 _float]
   [proj1-m4 _float] [proj1-m5 _float] [proj1-m6 _float] [proj1-m7 _float]
   [proj1-m8 _float] [proj1-m9 _float] [proj1-m10 _float] [proj1-m11 _float]
   [proj1-m12 _float] [proj1-m13 _float] [proj1-m14 _float] [proj1-m15 _float]
   [view0-m0 _float] [view0-m1 _float] [view0-m2 _float] [view0-m3 _float]
   [view0-m4 _float] [view0-m5 _float] [view0-m6 _float] [view0-m7 _float]
   [view0-m8 _float] [view0-m9 _float] [view0-m10 _float] [view0-m11 _float]
   [view0-m12 _float] [view0-m13 _float] [view0-m14 _float] [view0-m15 _float]
   [view1-m0 _float] [view1-m1 _float] [view1-m2 _float] [view1-m3 _float]
   [view1-m4 _float] [view1-m5 _float] [view1-m6 _float] [view1-m7 _float]
   [view1-m8 _float] [view1-m9 _float] [view1-m10 _float] [view1-m11 _float]
   [view1-m12 _float] [view1-m13 _float] [view1-m14 _float] [view1-m15 _float]
   [leftLensCenter0 _float] [leftLensCenter1 _float]
   [rightLensCenter0 _float] [rightLensCenter1 _float]
   [leftScreenCenter0 _float] [leftScreenCenter1 _float]
   [rightScreenCenter0 _float] [rightScreenCenter1 _float]
   [scale0 _float] [scale1 _float]
   [scaleIn0 _float] [scaleIn1 _float]))


;; pass-by-value
(define _vrstereoconfig-bytes
  (_list-struct
   _float _float _float _float _float _float _float _float
   _float _float _float _float _float _float _float _float
   _float _float _float _float _float _float _float _float
   _float _float _float _float _float _float _float _float
   _float _float _float _float _float _float _float _float
   _float _float _float _float _float _float _float _float
   _float _float _float _float _float _float _float _float
   _float _float _float _float _float _float _float _float
   _float _float _float _float
   _float _float _float _float
   _float _float _float _float))

;; 命名访问器（常用字段）
(define (vr-stereo-config-left-lens-center0 cfg)  (list-ref cfg 64))
(define (vr-stereo-config-left-lens-center1 cfg)  (list-ref cfg 65))
(define (vr-stereo-config-right-lens-center0 cfg) (list-ref cfg 66))
(define (vr-stereo-config-right-lens-center1 cfg) (list-ref cfg 67))
(define (vr-stereo-config-left-screen-center0 cfg)  (list-ref cfg 68))
(define (vr-stereo-config-left-screen-center1 cfg)  (list-ref cfg 69))
(define (vr-stereo-config-right-screen-center0 cfg) (list-ref cfg 70))
(define (vr-stereo-config-right-screen-center1 cfg) (list-ref cfg 71))
(define (vr-stereo-config-scale0 cfg)    (list-ref cfg 72))
(define (vr-stereo-config-scale1 cfg)    (list-ref cfg 73))
(define (vr-stereo-config-scale-in0 cfg) (list-ref cfg 74))
(define (vr-stereo-config-scale-in1 cfg) (list-ref cfg 75))

(provide _VrStereoConfig _vrstereoconfig-bytes
         vr-stereo-config-left-lens-center0 vr-stereo-config-left-lens-center1
         vr-stereo-config-right-lens-center0 vr-stereo-config-right-lens-center1
         vr-stereo-config-left-screen-center0 vr-stereo-config-left-screen-center1
         vr-stereo-config-right-screen-center0 vr-stereo-config-right-screen-center1
         vr-stereo-config-scale0 vr-stereo-config-scale1
         vr-stereo-config-scale-in0 vr-stereo-config-scale-in1)
