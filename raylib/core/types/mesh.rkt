#lang racket/base

;; types/mesh.rkt — Mesh (80 bytes)

(require ffi/unsafe)

;; ═══════════════════════════════════════════════════════════
;; C struct
;; ═══════════════════════════════════════════════════════════

(define-cstruct _Mesh
  ([vertexCount _int] [triangleCount _int]
   [vertices _pointer] [texcoords _pointer] [texcoords2 _pointer]
   [normals _pointer] [tangents _pointer] [colors _pointer] [indices _pointer]
   [boneCount _int]
   [animVertices _pointer] [animNormals _pointer]
   [boneIndices _pointer] [boneWeights _pointer]
   [vaoId _uint] [vboId _pointer]))

;; ═══════════════════════════════════════════════════════════
;; pass-by-value 转换
;; ═══════════════════════════════════════════════════════════

(define _mesh-bytes
  (_list-struct _int _int
                _pointer _pointer _pointer _pointer _pointer _pointer _pointer
                _int _int
                _pointer _pointer
                _pointer _pointer
                _uint _int _pointer))

;; ═══════════════════════════════════════════════════════════
;; 列表访问器 (用于 FFI 返回值)
;; ═══════════════════════════════════════════════════════════

(define (mesh-vertex-count lst)    (list-ref lst 0))
(define (mesh-triangle-count lst)  (list-ref lst 1))
(define (mesh-vertices lst)        (list-ref lst 2))
(define (mesh-texcoords lst)       (list-ref lst 3))
(define (mesh-texcoords2 lst)      (list-ref lst 4))
(define (mesh-normals lst)         (list-ref lst 5))
(define (mesh-tangents lst)        (list-ref lst 6))
(define (mesh-colors lst)          (list-ref lst 7))
(define (mesh-indices lst)         (list-ref lst 8))
(define (mesh-bone-count lst)      (list-ref lst 9))
(define (mesh-bone-indices lst)    (list-ref lst 11))
(define (mesh-bone-weights lst)    (list-ref lst 12))
(define (mesh-anim-vertices lst)   (list-ref lst 13))
(define (mesh-anim-normals lst)    (list-ref lst 14))
(define (mesh-vao-id lst)          (list-ref lst 15))
(define (mesh-vbo-id lst)          (list-ref lst 17))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide _Mesh _mesh-bytes
         mesh-vertex-count mesh-triangle-count
         mesh-vertices mesh-texcoords mesh-texcoords2
         mesh-normals mesh-tangents mesh-colors mesh-indices
         mesh-bone-count mesh-bone-indices mesh-bone-weights
         mesh-anim-vertices mesh-anim-normals
         mesh-vao-id mesh-vbo-id)
