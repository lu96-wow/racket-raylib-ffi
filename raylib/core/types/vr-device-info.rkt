#lang racket/base

;; types/vr-device-info.rkt — VrDeviceInfo (60 bytes)

(require ffi/unsafe)

;; ═══════════════════════════════════════════════════════════
;; C struct
;; ═══════════════════════════════════════════════════════════

(define-cstruct _VrDeviceInfo
  ([hResolution _int] [vResolution _int]
   [hScreenSize _float] [vScreenSize _float]
   [eyeToScreenDistance _float] [lensSeparationDistance _float]
   [interpupillaryDistance _float]
   [lensDist0 _float] [lensDist1 _float] [lensDist2 _float] [lensDist3 _float]
   [chromaAb0 _float] [chromaAb1 _float] [chromaAb2 _float] [chromaAb3 _float]))

;; ═══════════════════════════════════════════════════════════
;; pass-by-value 转换
;; ═══════════════════════════════════════════════════════════

(define _vr-device-info-bytes
  (_list-struct _int _int _float _float _float _float _float
                _float _float _float _float _float _float _float _float))

;; ═══════════════════════════════════════════════════════════
;; 列表访问器 (用于 FFI 返回值)
;; ═══════════════════════════════════════════════════════════

(define (vr-device-info-h-resolution lst)            (list-ref lst 0))
(define (vr-device-info-v-resolution lst)            (list-ref lst 1))
(define (vr-device-info-h-screen-size lst)           (list-ref lst 2))
(define (vr-device-info-v-screen-size lst)           (list-ref lst 3))
(define (vr-device-info-eye-to-screen-distance lst)  (list-ref lst 4))
(define (vr-device-info-lens-separation-distance lst) (list-ref lst 5))
(define (vr-device-info-interpupillary-distance lst)  (list-ref lst 6))
(define (vr-device-info-lens-dist0 lst)              (list-ref lst 7))
(define (vr-device-info-lens-dist1 lst)              (list-ref lst 8))
(define (vr-device-info-lens-dist2 lst)              (list-ref lst 9))
(define (vr-device-info-lens-dist3 lst)              (list-ref lst 10))
(define (vr-device-info-chroma-ab0 lst)              (list-ref lst 11))
(define (vr-device-info-chroma-ab1 lst)              (list-ref lst 12))
(define (vr-device-info-chroma-ab2 lst)              (list-ref lst 13))
(define (vr-device-info-chroma-ab3 lst)              (list-ref lst 14))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide _VrDeviceInfo _vr-device-info-bytes
         vr-device-info-h-resolution vr-device-info-v-resolution
         vr-device-info-h-screen-size vr-device-info-v-screen-size
         vr-device-info-eye-to-screen-distance
         vr-device-info-lens-separation-distance
         vr-device-info-interpupillary-distance
         vr-device-info-lens-dist0 vr-device-info-lens-dist1
         vr-device-info-lens-dist2 vr-device-info-lens-dist3
         vr-device-info-chroma-ab0 vr-device-info-chroma-ab1
         vr-device-info-chroma-ab2 vr-device-info-chroma-ab3)
