#lang racket/base
(require ffi/unsafe)

(define-cstruct _VrDeviceInfo
  ([hResolution _int] [vResolution _int] [hScreenSize _float] [vScreenSize _float]
   [eyeToScreenDistance _float] [lensSeparationDistance _float] [interpupillaryDistance _float]
   [lensDist0 _float] [lensDist1 _float] [lensDist2 _float] [lensDist3 _float]
   [chromaAb0 _float] [chromaAb1 _float] [chromaAb2 _float] [chromaAb3 _float]))
(define _vrdeviceinfo-bytes
  (_list-struct _int _int _float _float _float _float _float _float _float _float _float _float _float _float _float))

(define (vr-device-info-h-resolution lst)        (list-ref lst 0))
(define (vr-device-info-v-resolution lst)        (list-ref lst 1))
(define (vr-device-info-h-screen-size lst)       (list-ref lst 2))
(define (vr-device-info-eye-to-screen lst)       (list-ref lst 4))
(define (vr-device-info-ipd lst)                 (list-ref lst 6))

(provide _VrDeviceInfo _vrdeviceinfo-bytes
         vr-device-info-h-resolution vr-device-info-v-resolution
         vr-device-info-h-screen-size vr-device-info-eye-to-screen vr-device-info-ipd)
