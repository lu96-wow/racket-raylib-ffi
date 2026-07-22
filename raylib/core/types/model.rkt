#lang racket/base

;; types/model.rkt — Model (104 bytes)

(require ffi/unsafe)

;; ═══════════════════════════════════════════════════════════
;; C struct
;; ═══════════════════════════════════════════════════════════

(define-cstruct _Model
  ([tr-m0 _float] [tr-m1 _float] [tr-m2 _float] [tr-m3 _float]
   [tr-m4 _float] [tr-m5 _float] [tr-m6 _float] [tr-m7 _float]
   [tr-m8 _float] [tr-m9 _float] [tr-m10 _float] [tr-m11 _float]
   [tr-m12 _float] [tr-m13 _float] [tr-m14 _float] [tr-m15 _float]
   [meshCount _int] [materialCount _int]
   [meshes _pointer] [materials _pointer] [meshMaterial _pointer]
   [skeleton-boneCount _int]
   [skeleton-bones _pointer] [skeleton-bindPose _pointer]
   [currentPose _pointer] [boneMatrices _pointer]))

;; ═══════════════════════════════════════════════════════════
;; pass-by-value 转换
;; ═══════════════════════════════════════════════════════════

(define _model-bytes
  (_list-struct
   _float _float _float _float
   _float _float _float _float
   _float _float _float _float
   _float _float _float _float
   _int _int
   _pointer _pointer _pointer
   _int _int
   _pointer _pointer
   _pointer _pointer))

;; ═══════════════════════════════════════════════════════════
;; 列表访问器 (用于 FFI 返回值)
;; ═══════════════════════════════════════════════════════════

(define (model-transform lst)      (for/list ([i (in-range 16)]) (list-ref lst i)))
(define (model-mesh-count lst)     (list-ref lst 16))
(define (model-material-count lst) (list-ref lst 17))
(define (model-meshes lst)         (list-ref lst 18))
(define (model-materials lst)      (list-ref lst 19))
(define (model-mesh-material lst)  (list-ref lst 20))
(define (model-bone-count lst)     (list-ref lst 21))
(define (model-bones lst)          (list-ref lst 23))
(define (model-bind-pose lst)      (list-ref lst 24))
(define (model-current-pose lst)   (list-ref lst 25))
(define (model-bone-matrices lst)  (list-ref lst 26))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide _Model _model-bytes
         model-transform model-mesh-count model-material-count
         model-meshes model-materials model-mesh-material
         model-bone-count model-bones model-bind-pose
         model-current-pose model-bone-matrices)
