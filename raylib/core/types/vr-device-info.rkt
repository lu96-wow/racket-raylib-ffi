#lang racket/base

;; types/vr-device-info.rkt — VrDeviceInfo (60 bytes)

(require ffi/unsafe)

(define-cstruct _VrDeviceInfo
  ([hResolution _int] [vResolution _int]
   [hScreenSize _float] [vScreenSize _float]
   [eyeToScreenDistance _float] [lensSeparationDistance _float]
   [interpupillaryDistance _float]
   [lensDist0 _float] [lensDist1 _float] [lensDist2 _float] [lensDist3 _float]
   [chromaAb0 _float] [chromaAb1 _float] [chromaAb2 _float] [chromaAb3 _float]))


;; pass-by-value
(define _vrdeviceinfo-bytes
  (_list-struct _int _int
                _float _float _float _float _float
                _float _float _float _float
                _float _float _float _float))

(provide _VrDeviceInfo _vrdeviceinfo-bytes)
