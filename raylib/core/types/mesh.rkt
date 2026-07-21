#lang racket/base

;; types/mesh.rkt — Mesh (120 bytes)

(require ffi/unsafe)

(define-cstruct _Mesh
  ([vertexCount _int] [triangleCount _int]
   [vertices _pointer] [texcoords _pointer] [texcoords2 _pointer]
   [normals _pointer] [tangents _pointer] [colors _pointer] [indices _pointer]
   [boneCount _int]
   [boneIndices _pointer] [boneWeights _pointer]
   [animVertices _pointer] [animNormals _pointer]
   [vaoId _uint] [vboId _pointer]))


;; pass-by-value
(define _mesh-bytes
  (_list-struct
   _int _int
   _pointer _pointer _pointer
   _pointer _pointer _pointer _pointer
   _int _int
   _pointer _pointer
   _pointer _pointer
   _uint _int _pointer))

(provide _Mesh _mesh-bytes)
