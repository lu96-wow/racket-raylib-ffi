#lang racket/base

(require ffi/unsafe
         (prefix-in T: "types.rkt")
         (prefix-in C: "rcore.rkt"))

(define (clamp value mn mx)
  (max mn (min mx value)))

(define (lerp start end amount)
  (+ start (* amount (- end start))))

;; Remap(float value, float inputStart, float inputEnd, float outputStart, float outputEnd)
(define (remap value input-start input-end output-start output-end)
  (+ output-start
     (* (- value input-start)
        (/ (- output-end output-start)
           (- input-end input-start)))))

(define (vec2-length v)
  (let ([x (ptr-ref v _float 0)]
        [y (ptr-ref v _float 1)])
    (sqrt (+ (* x x) (* y y)))))

(define (vec2-multiply v1 v2)
  (let ([r (malloc T:_Vector2 'atomic)])
    (ptr-set! r _float 0 (* (ptr-ref v1 _float 0) (ptr-ref v2 _float 0)))
    (ptr-set! r _float 1 (* (ptr-ref v1 _float 1) (ptr-ref v2 _float 1))) r))

(define (vec2-rotate v angle)
  (let* ([x (ptr-ref v _float 0)] [y (ptr-ref v _float 1)]
         [c (cos angle)] [s (sin angle)]
         [r (malloc T:_Vector2 'atomic)])
    (ptr-set! r _float 0 (- (* x c) (* y s)))
    (ptr-set! r _float 1 (+ (* x s) (* y c))) r))

(define (vec2-clamp v mn mx)
  (let ([r (malloc T:_Vector2 'atomic)])
    (ptr-set! r _float 0 (clamp (ptr-ref v _float 0) (ptr-ref mn _float 0) (ptr-ref mx _float 0)))
    (ptr-set! r _float 1 (clamp (ptr-ref v _float 1) (ptr-ref mn _float 1) (ptr-ref mx _float 1)))
    r))

(define (vec2-normalize v)
  (let* ([x (ptr-ref v _float 0)]
         [y (ptr-ref v _float 1)]
         [len (sqrt (+ (* x x) (* y y)))])
    (if (= len 0.0) v
        (let ([r (malloc T:_Vector2 'atomic)])
          (ptr-set! r _float 0 (/ x len))
          (ptr-set! r _float 1 (/ y len)) r))))

(define (vec2-add a b)
  (let ([r (malloc T:_Vector2 'atomic)])
    (ptr-set! r _float 0 (+ (ptr-ref a _float 0) (ptr-ref b _float 0)))
    (ptr-set! r _float 1 (+ (ptr-ref a _float 1) (ptr-ref b _float 1))) r))

(define (vec2-subtract a b)
  (let ([r (malloc T:_Vector2 'atomic)])
    (ptr-set! r _float 0 (- (ptr-ref a _float 0) (ptr-ref b _float 0)))
    (ptr-set! r _float 1 (- (ptr-ref a _float 1) (ptr-ref b _float 1))) r))

(define (vec2-scale v s)
  (let ([r (malloc T:_Vector2 'atomic)])
    (ptr-set! r _float 0 (* (ptr-ref v _float 0) s))
    (ptr-set! r _float 1 (* (ptr-ref v _float 1) s)) r))

(define (vec3-add v1 v2)
  (let ([r (malloc T:_Vector3 'atomic)])
    (ptr-set! r _float 0 (+ (ptr-ref v1 _float 0) (ptr-ref v2 _float 0)))
    (ptr-set! r _float 1 (+ (ptr-ref v1 _float 1) (ptr-ref v2 _float 1)))
    (ptr-set! r _float 2 (+ (ptr-ref v1 _float 2) (ptr-ref v2 _float 2))) r))

(define (vec3-scale v s)
  (let ([r (malloc T:_Vector3 'atomic)])
    (ptr-set! r _float 0 (* (ptr-ref v _float 0) s))
    (ptr-set! r _float 1 (* (ptr-ref v _float 1) s))
    (ptr-set! r _float 2 (* (ptr-ref v _float 2) s)) r))

(define (vec3-cross-product v1 v2)
  (let* ([x1 (ptr-ref v1 _float 0)] [y1 (ptr-ref v1 _float 1)] [z1 (ptr-ref v1 _float 2)]
         [x2 (ptr-ref v2 _float 0)] [y2 (ptr-ref v2 _float 1)] [z2 (ptr-ref v2 _float 2)]
         [r (malloc T:_Vector3 'atomic)])
    (ptr-set! r _float 0 (- (* y1 z2) (* z1 y2)))
    (ptr-set! r _float 1 (- (* z1 x2) (* x1 z2)))
    (ptr-set! r _float 2 (- (* x1 y2) (* y1 x2))) r))

(define (vec3-length v)
  (let ([x (ptr-ref v _float 0)]
        [y (ptr-ref v _float 1)]
        [z (ptr-ref v _float 2)])
    (sqrt (+ (* x x) (* y y) (* z z)))))

(define (vec3-dot-product v1 v2)
  (+ (* (ptr-ref v1 _float 0) (ptr-ref v2 _float 0))
     (* (ptr-ref v1 _float 1) (ptr-ref v2 _float 1))
     (* (ptr-ref v1 _float 2) (ptr-ref v2 _float 2))))

(define (vec3-angle v1 v2)
  (let* ([x1 (ptr-ref v1 _float 0)] [y1 (ptr-ref v1 _float 1)] [z1 (ptr-ref v1 _float 2)]
         [x2 (ptr-ref v2 _float 0)] [y2 (ptr-ref v2 _float 1)] [z2 (ptr-ref v2 _float 2)]
         [dot (+ (* x1 x2) (* y1 y2) (* z1 z2))]
         [len1 (sqrt (+ (* x1 x1) (* y1 y1) (* z1 z1)))]
         [len2 (sqrt (+ (* x2 x2) (* y2 y2) (* z2 z2)))])
    (acos (/ dot (* len1 len2)))))

(define (vec3-negate v)
  (let ([r (malloc T:_Vector3 'atomic)])
    (ptr-set! r _float 0 (- (ptr-ref v _float 0)))
    (ptr-set! r _float 1 (- (ptr-ref v _float 1)))
    (ptr-set! r _float 2 (- (ptr-ref v _float 2))) r))

(define (vec3-normalize v)
  (let* ([x (ptr-ref v _float 0)]
         [y (ptr-ref v _float 1)]
         [z (ptr-ref v _float 2)]
         [len (sqrt (+ (* x x) (* y y) (* z z)))])
    (if (= len 0.0) v
        (let ([r (malloc T:_Vector3 'atomic)])
          (ptr-set! r _float 0 (/ x len))
          (ptr-set! r _float 1 (/ y len))
          (ptr-set! r _float 2 (/ z len)) r))))

(define (vec3-rotate-by-axis-angle v axis angle)
  (let* ([vx (ptr-ref v _float 0)] [vy (ptr-ref v _float 1)] [vz (ptr-ref v _float 2)]
         [ax (ptr-ref axis _float 0)] [ay (ptr-ref axis _float 1)] [az (ptr-ref axis _float 2)]
         [cosres (cos angle)] [sinres (sin angle)]
         [len (sqrt (+ (* ax ax) (* ay ay) (* az az)))])
    (if (= len 0.0) v
        (let* ([x (/ ax len)] [y (/ ay len)] [z (/ az len)]
               [dot (+ (* vx x) (* vy y) (* vz z))]
               [crossx (- (* y vz) (* z vy))]
               [crossy (- (* z vx) (* x vz))]
               [crossz (- (* x vy) (* y vx))]
               [r (malloc T:_Vector3 'atomic)])
          (ptr-set! r _float 0 (+ (* vx cosres) (* crossx sinres) (* x dot (- 1 cosres))))
          (ptr-set! r _float 1 (+ (* vy cosres) (* crossy sinres) (* y dot (- 1 cosres))))
          (ptr-set! r _float 2 (+ (* vz cosres) (* crossz sinres) (* z dot (- 1 cosres))))
          r))))

(define (vec3-lerp v1 v2 amount)
  (let ([r (malloc T:_Vector3 'atomic)])
    (ptr-set! r _float 0 (+ (ptr-ref v1 _float 0) (* amount (- (ptr-ref v2 _float 0) (ptr-ref v1 _float 0)))))
    (ptr-set! r _float 1 (+ (ptr-ref v1 _float 1) (* amount (- (ptr-ref v2 _float 1) (ptr-ref v1 _float 1)))))
    (ptr-set! r _float 2 (+ (ptr-ref v1 _float 2) (* amount (- (ptr-ref v2 _float 2) (ptr-ref v1 _float 2)))))
    r))


;; ============================================================
;; Matrix FFI (textures_framebuffer_rendering.c)
;; ============================================================

(define vector3-distance
  (let ([f (get-ffi-obj "Vector3Distance" T:lib
             (_fun (v1 : C:_vec3-bytes) (v2 : C:_vec3-bytes) -> _float))])
    (lambda (a b) (f (C:vec3->bytes a) (C:vec3->bytes b)))))

(define matrix-perspective
  (let ([f (get-ffi-obj "MatrixPerspective" T:lib
             (_fun _double _double _double _double -> (m : C:_matrix-bytes)))])
    (lambda (fov-y aspect near far) (f fov-y aspect near far))))

(define matrix-multiply
  (let ([f (get-ffi-obj "MatrixMultiply" T:lib
             (_fun (l : C:_matrix-bytes) (r : C:_matrix-bytes) -> (m : C:_matrix-bytes)))])
    (lambda (left right) (f left right))))

(define matrix-invert
  (let ([f (get-ffi-obj "MatrixInvert" T:lib
             (_fun (m : C:_matrix-bytes) -> (result : C:_matrix-bytes)))])
    (lambda (mat) (f mat))))

(define matrix-translate
  (let ([f (get-ffi-obj "MatrixTranslate" T:lib
             (_fun _float _float _float -> (m : C:_matrix-bytes)))])
    (lambda (x y z) (f x y z))))

(define matrix-look-at
  (let ([f (get-ffi-obj "MatrixLookAt" T:lib
             (_fun (eye : C:_vec3-bytes) (target : C:_vec3-bytes) (up : C:_vec3-bytes) -> (m : C:_matrix-bytes)))])
    (lambda (eye target up) (f (C:vec3->bytes eye) (C:vec3->bytes target) (C:vec3->bytes up)))))

(define matrix-rotate-xyz
  (let ([f (get-ffi-obj "MatrixRotateXYZ" T:lib
             (_fun (v : C:_vec3-bytes) -> (m : C:_matrix-bytes)))])
    (lambda (angle) (f (C:vec3->bytes angle)))))

(define matrix-rotate-y
  (let ([f (get-ffi-obj "MatrixRotateY" T:lib
             (_fun _float -> (m : C:_matrix-bytes)))])
    (lambda (angle) (f angle))))

(define matrix-rotate-x
  (let ([f (get-ffi-obj "MatrixRotateX" T:lib
             (_fun _float -> (m : C:_matrix-bytes)))])
    (lambda (angle) (f angle))))

(define matrix-rotate-z
  (let ([f (get-ffi-obj "MatrixRotateZ" T:lib
             (_fun _float -> (m : C:_matrix-bytes)))])
    (lambda (angle) (f angle))))

;; ============================================================
;; Quaternion (纯 Racket 实现, Quaternion = Vector4 = malloc'd ptr)
;; ============================================================

(define (quaternion-from-axis-angle axis-ptr angle)
  (let* ([ax (ptr-ref axis-ptr _float 0)]
         [ay (ptr-ref axis-ptr _float 1)]
         [az (ptr-ref axis-ptr _float 2)]
         [len (sqrt (+ (* ax ax) (* ay ay) (* az az)))]
         [half-angle (/ angle 2.0)]
         [s (sin half-angle)]
         [c (cos half-angle)]
         [nx (if (= len 0.0) ax (/ ax len))]
         [ny (if (= len 0.0) ay (/ ay len))]
         [nz (if (= len 0.0) az (/ az len))]
         [q (malloc T:_Vector4 'atomic)])
    (ptr-set! q _float 0 (exact->inexact (* nx s)))
    (ptr-set! q _float 1 (exact->inexact (* ny s)))
    (ptr-set! q _float 2 (exact->inexact (* nz s)))
    (ptr-set! q _float 3 (exact->inexact c))
    q))

(define (quaternion-multiply q1 q2)
  (let* ([x1 (ptr-ref q1 _float 0)] [y1 (ptr-ref q1 _float 1)]
         [z1 (ptr-ref q1 _float 2)] [w1 (ptr-ref q1 _float 3)]
         [x2 (ptr-ref q2 _float 0)] [y2 (ptr-ref q2 _float 1)]
         [z2 (ptr-ref q2 _float 2)] [w2 (ptr-ref q2 _float 3)]
         [q (malloc T:_Vector4 'atomic)])
    (ptr-set! q _float 0 (exact->inexact (+ (* w1 x2) (* x1 w2) (* y1 z2) (- (* z1 y2)))))
    (ptr-set! q _float 1 (exact->inexact (+ (* w1 y2) (- (* x1 z2)) (* y1 w2) (* z1 x2))))
    (ptr-set! q _float 2 (exact->inexact (+ (* w1 z2) (* x1 y2) (- (* y1 x2)) (* z1 w2))))
    (ptr-set! q _float 3 (exact->inexact (- (* w1 w2) (* x1 x2) (* y1 y2) (* z1 z2))))
    q))

(define (quaternion-invert q)
  (let* ([x (ptr-ref q _float 0)] [y (ptr-ref q _float 1)]
         [z (ptr-ref q _float 2)] [w (ptr-ref q _float 3)]
         [len-sq (+ (* x x) (* y y) (* z z) (* w w))]
         [inv (malloc T:_Vector4 'atomic)])
    (if (= len-sq 0.0)
      (begin
        (ptr-set! inv _float 0 0.0)
        (ptr-set! inv _float 1 0.0)
        (ptr-set! inv _float 2 0.0)
        (ptr-set! inv _float 3 1.0))
      (let ([f (/ 1.0 len-sq)])
        (ptr-set! inv _float 0 (exact->inexact (* (- x) f)))
        (ptr-set! inv _float 1 (exact->inexact (* (- y) f)))
        (ptr-set! inv _float 2 (exact->inexact (* (- z) f)))
        (ptr-set! inv _float 3 (exact->inexact (* w f)))))
    inv))

;; quaternion->matrix: 返回 C Matrix 字段顺序的 list
(define (quaternion-to-matrix q)
  (let* ([x (ptr-ref q _float 0)] [y (ptr-ref q _float 1)]
         [z (ptr-ref q _float 2)] [w (ptr-ref q _float 3)]
         [x2 (* x x)] [y2 (* y y)] [z2 (* z z)]
         [xy (* x y)] [xz (* x z)] [yz (* y z)]
         [wx (* w x)] [wy (* w y)] [wz (* w z)])
    ;; C Matrix 字段顺序: m0,m4,m8,m12, m1,m5,m9,m13, m2,m6,m10,m14, m3,m7,m11,m15
    (list (- 1.0 (* 2.0 (+ y2 z2)))   ;; m0
          (* 2.0 (- xy wz))            ;; m4
          (* 2.0 (+ xz wy))            ;; m8
          0.0                          ;; m12
          (* 2.0 (+ xy wz))            ;; m1
          (- 1.0 (* 2.0 (+ x2 z2)))   ;; m5
          (* 2.0 (- yz wx))            ;; m9
          0.0                          ;; m13
          (* 2.0 (- xz wy))            ;; m2
          (* 2.0 (+ yz wx))            ;; m6
          (- 1.0 (* 2.0 (+ x2 y2)))   ;; m10
          0.0                          ;; m14
          0.0 0.0 0.0 1.0)))            ;; m3,m7,m11,m15

(provide
 clamp lerp remap
 vec2-add vec2-subtract vec2-scale vec2-multiply
 vec2-length vec2-normalize vec2-rotate vec2-clamp
 vec3-add vec3-scale vec3-cross-product vec3-length
 vec3-dot-product vec3-angle vec3-negate vec3-normalize
 vec3-rotate-by-axis-angle vec3-lerp
 vector3-distance matrix-perspective matrix-multiply matrix-invert
 matrix-translate
 matrix-look-at matrix-rotate-xyz matrix-rotate-y matrix-rotate-x matrix-rotate-z
 quaternion-from-axis-angle quaternion-multiply quaternion-invert
 quaternion-to-matrix)
