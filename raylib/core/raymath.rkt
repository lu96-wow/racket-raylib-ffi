#lang racket/base

;; core/raymath.rkt — 数学函数 (raymath.h) 纯Racket + 少量FFI

(require ffi/unsafe
         racket/math
         "ffi-helpers.rkt"
         "types/vector2.rkt"
         "types/vector3.rkt"
         "types/vector4.rkt")

(define (clamp v mn mx) (max mn (min mx v)))
(define (lerp s e a) (+ s (* a (- e s))))
(define (remap v is ie os oe) (+ os (* (- v is) (/ (- oe os) (- ie is)))))
(define (vec2-length v) (sqrt (+ (sqr (ptr-ref v _float 0)) (sqr (ptr-ref v _float 1)))))
(define (vec2-multiply v1 v2) (let ([r (malloc _Vector2 'atomic)]) (ptr-set! r _float 0 (* (ptr-ref v1 _float 0) (ptr-ref v2 _float 0))) (ptr-set! r _float 1 (* (ptr-ref v1 _float 1) (ptr-ref v2 _float 1))) r))
(define (vec2-rotate v a) (let* ([x (ptr-ref v _float 0)] [y (ptr-ref v _float 1)] [c (cos a)] [s (sin a)] [r (malloc _Vector2 'atomic)]) (ptr-set! r _float 0 (- (* x c) (* y s))) (ptr-set! r _float 1 (+ (* x s) (* y c))) r))
(define (vec2-clamp v mn mx) (let ([r (malloc _Vector2 'atomic)]) (ptr-set! r _float 0 (clamp (ptr-ref v _float 0) (ptr-ref mn _float 0) (ptr-ref mx _float 0))) (ptr-set! r _float 1 (clamp (ptr-ref v _float 1) (ptr-ref mn _float 1) (ptr-ref mx _float 1))) r))
(define (vec2-normalize v) (let* ([x (ptr-ref v _float 0)] [y (ptr-ref v _float 1)] [l (sqrt (+ (* x x) (* y y)))]) (if (= l 0.0) v (let ([r (malloc _Vector2 'atomic)]) (ptr-set! r _float 0 (/ x l)) (ptr-set! r _float 1 (/ y l)) r))))
(define (vec2-add a b) (let ([r (malloc _Vector2 'atomic)]) (ptr-set! r _float 0 (+ (ptr-ref a _float 0) (ptr-ref b _float 0))) (ptr-set! r _float 1 (+ (ptr-ref a _float 1) (ptr-ref b _float 1))) r))
(define (vec2-subtract a b) (let ([r (malloc _Vector2 'atomic)]) (ptr-set! r _float 0 (- (ptr-ref a _float 0) (ptr-ref b _float 0))) (ptr-set! r _float 1 (- (ptr-ref a _float 1) (ptr-ref b _float 1))) r))
(define (vec2-scale v s) (let ([r (malloc _Vector2 'atomic)]) (ptr-set! r _float 0 (* (ptr-ref v _float 0) s)) (ptr-set! r _float 1 (* (ptr-ref v _float 1) s)) r))
(define (vec3-add a b) (let ([r (malloc _Vector3 'atomic)]) (ptr-set! r _float 0 (+ (ptr-ref a _float 0) (ptr-ref b _float 0))) (ptr-set! r _float 1 (+ (ptr-ref a _float 1) (ptr-ref b _float 1))) (ptr-set! r _float 2 (+ (ptr-ref a _float 2) (ptr-ref b _float 2))) r))
(define (vec3-subtract a b) (let ([r (malloc _Vector3 'atomic)]) (ptr-set! r _float 0 (- (ptr-ref a _float 0) (ptr-ref b _float 0))) (ptr-set! r _float 1 (- (ptr-ref a _float 1) (ptr-ref b _float 1))) (ptr-set! r _float 2 (- (ptr-ref a _float 2) (ptr-ref b _float 2))) r))
(define (vec3-scale v s) (let ([r (malloc _Vector3 'atomic)]) (ptr-set! r _float 0 (* (ptr-ref v _float 0) s)) (ptr-set! r _float 1 (* (ptr-ref v _float 1) s)) (ptr-set! r _float 2 (* (ptr-ref v _float 2) s)) r))
(define (vec3-cross-product a b) (let* ([x1 (ptr-ref a _float 0)] [y1 (ptr-ref a _float 1)] [z1 (ptr-ref a _float 2)] [x2 (ptr-ref b _float 0)] [y2 (ptr-ref b _float 1)] [z2 (ptr-ref b _float 2)] [r (malloc _Vector3 'atomic)]) (ptr-set! r _float 0 (- (* y1 z2) (* z1 y2))) (ptr-set! r _float 1 (- (* z1 x2) (* x1 z2))) (ptr-set! r _float 2 (- (* x1 y2) (* y1 x2))) r))
(define (vec3-length v) (sqrt (+ (sqr (ptr-ref v _float 0)) (sqr (ptr-ref v _float 1)) (sqr (ptr-ref v _float 2)))))
(define (vec3-dot-product a b) (+ (* (ptr-ref a _float 0) (ptr-ref b _float 0)) (* (ptr-ref a _float 1) (ptr-ref b _float 1)) (* (ptr-ref a _float 2) (ptr-ref b _float 2))))
(define (vec3-angle a b) (let* ([x1 (ptr-ref a _float 0)] [y1 (ptr-ref a _float 1)] [z1 (ptr-ref a _float 2)] [x2 (ptr-ref b _float 0)] [y2 (ptr-ref b _float 1)] [z2 (ptr-ref b _float 2)] [d (+ (* x1 x2) (* y1 y2) (* z1 z2))] [l1 (sqrt (+ (* x1 x1) (* y1 y1) (* z1 z1)))] [l2 (sqrt (+ (* x2 x2) (* y2 y2) (* z2 z2)))]) (acos (/ d (* l1 l2)))))
(define (vec3-negate v) (let ([r (malloc _Vector3 'atomic)]) (ptr-set! r _float 0 (- (ptr-ref v _float 0))) (ptr-set! r _float 1 (- (ptr-ref v _float 1))) (ptr-set! r _float 2 (- (ptr-ref v _float 2))) r))
(define (vec3-normalize v) (let* ([x (ptr-ref v _float 0)] [y (ptr-ref v _float 1)] [z (ptr-ref v _float 2)] [l (sqrt (+ (* x x) (* y y) (* z z)))]) (if (= l 0.0) v (let ([r (malloc _Vector3 'atomic)]) (ptr-set! r _float 0 (/ x l)) (ptr-set! r _float 1 (/ y l)) (ptr-set! r _float 2 (/ z l)) r))))
(define (vec3-rotate-by-axis-angle v axis angle) (let* ([vx (ptr-ref v _float 0)] [vy (ptr-ref v _float 1)] [vz (ptr-ref v _float 2)] [ax (ptr-ref axis _float 0)] [ay (ptr-ref axis _float 1)] [az (ptr-ref axis _float 2)] [cosres (cos angle)] [sinres (sin angle)] [len (sqrt (+ (* ax ax) (* ay ay) (* az az)))]) (if (= len 0.0) v (let* ([x (/ ax len)] [y (/ ay len)] [z (/ az len)] [dot (+ (* vx x) (* vy y) (* vz z))] [cx (- (* y vz) (* z vy))] [cy (- (* z vx) (* x vz))] [cz (- (* x vy) (* y vx))] [r (malloc _Vector3 'atomic)]) (ptr-set! r _float 0 (+ (* vx cosres) (* cx sinres) (* x dot (- 1 cosres)))) (ptr-set! r _float 1 (+ (* vy cosres) (* cy sinres) (* y dot (- 1 cosres)))) (ptr-set! r _float 2 (+ (* vz cosres) (* cz sinres) (* z dot (- 1 cosres)))) r))))
(define (vec3-lerp a b t) (let ([r (malloc _Vector3 'atomic)]) (ptr-set! r _float 0 (+ (ptr-ref a _float 0) (* t (- (ptr-ref b _float 0) (ptr-ref a _float 0))))) (ptr-set! r _float 1 (+ (ptr-ref a _float 1) (* t (- (ptr-ref b _float 1) (ptr-ref a _float 1))))) (ptr-set! r _float 2 (+ (ptr-ref a _float 2) (* t (- (ptr-ref b _float 2) (ptr-ref a _float 2))))) r))
(define vector3-distance (let ([f (get-ffi-obj "Vector3Distance" lib (_fun (v1 : _vec3-bytes) (v2 : _vec3-bytes) -> _float))]) (lambda (a b) (f (vec3->bytes a) (vec3->bytes b)))))
(define matrix-perspective (let ([f (get-ffi-obj "MatrixPerspective" lib (_fun _double _double _double _double -> (m : _matrix-bytes)))]) (lambda (fy a n f) (f fy a n f))))
(define matrix-multiply (let ([f (get-ffi-obj "MatrixMultiply" lib (_fun (l : _matrix-bytes) (r : _matrix-bytes) -> (m : _matrix-bytes)))]) (lambda (l r) (f l r))))
(define matrix-invert (let ([f (get-ffi-obj "MatrixInvert" lib (_fun (m : _matrix-bytes) -> (r : _matrix-bytes)))]) (lambda (m) (f m))))
(define matrix-translate (let ([f (get-ffi-obj "MatrixTranslate" lib (_fun _float _float _float -> (m : _matrix-bytes)))]) (lambda (x y z) (f x y z))))
(define matrix-look-at (let ([f (get-ffi-obj "MatrixLookAt" lib (_fun (eye : _vec3-bytes) (target : _vec3-bytes) (up : _vec3-bytes) -> (m : _matrix-bytes)))]) (lambda (e t u) (f (vec3->bytes e) (vec3->bytes t) (vec3->bytes u)))))
(define matrix-rotate-xyz (let ([f (get-ffi-obj "MatrixRotateXYZ" lib (_fun (v : _vec3-bytes) -> (m : _matrix-bytes)))]) (lambda (a) (f (vec3->bytes a)))))
(define matrix-rotate-y (let ([f (get-ffi-obj "MatrixRotateY" lib (_fun _float -> (m : _matrix-bytes)))]) (lambda (a) (f a))))
(define matrix-rotate-x (let ([f (get-ffi-obj "MatrixRotateX" lib (_fun _float -> (m : _matrix-bytes)))]) (lambda (a) (f a))))
(define matrix-rotate-z (let ([f (get-ffi-obj "MatrixRotateZ" lib (_fun _float -> (m : _matrix-bytes)))]) (lambda (a) (f a))))
(define (quaternion-from-axis-angle ax a) (let* ([axv (ptr-ref ax _float 0)] [ay (ptr-ref ax _float 1)] [az (ptr-ref ax _float 2)] [l (sqrt (+ (* axv axv) (* ay ay) (* az az)))] [ha (/ a 2.0)] [s (sin ha)] [c (cos ha)] [nx (if (= l 0.0) axv (/ axv l))] [ny (if (= l 0.0) ay (/ ay l))] [nz (if (= l 0.0) az (/ az l))] [q (malloc _Vector4 'atomic)]) (ptr-set! q _float 0 (exact->inexact (* nx s))) (ptr-set! q _float 1 (exact->inexact (* ny s))) (ptr-set! q _float 2 (exact->inexact (* nz s))) (ptr-set! q _float 3 (exact->inexact c)) q))
(define (quaternion-multiply q1 q2) (let* ([x1 (ptr-ref q1 _float 0)] [y1 (ptr-ref q1 _float 1)] [z1 (ptr-ref q1 _float 2)] [w1 (ptr-ref q1 _float 3)] [x2 (ptr-ref q2 _float 0)] [y2 (ptr-ref q2 _float 1)] [z2 (ptr-ref q2 _float 2)] [w2 (ptr-ref q2 _float 3)] [q (malloc _Vector4 'atomic)]) (ptr-set! q _float 0 (exact->inexact (+ (* w1 x2) (* x1 w2) (* y1 z2) (- (* z1 y2))))) (ptr-set! q _float 1 (exact->inexact (+ (* w1 y2) (- (* x1 z2)) (* y1 w2) (* z1 x2)))) (ptr-set! q _float 2 (exact->inexact (+ (* w1 z2) (* x1 y2) (- (* y1 x2)) (* z1 w2)))) (ptr-set! q _float 3 (exact->inexact (- (* w1 w2) (* x1 x2) (* y1 y2) (* z1 z2)))) q))
(define (quaternion-invert q) (let* ([x (ptr-ref q _float 0)] [y (ptr-ref q _float 1)] [z (ptr-ref q _float 2)] [w (ptr-ref q _float 3)] [ls (+ (* x x) (* y y) (* z z) (* w w))] [inv (malloc _Vector4 'atomic)]) (if (= ls 0.0) (begin (ptr-set! inv _float 0 0.0) (ptr-set! inv _float 1 0.0) (ptr-set! inv _float 2 0.0) (ptr-set! inv _float 3 1.0)) (let ([f (/ 1.0 ls)]) (ptr-set! inv _float 0 (exact->inexact (* (- x) f))) (ptr-set! inv _float 1 (exact->inexact (* (- y) f))) (ptr-set! inv _float 2 (exact->inexact (* (- z) f))) (ptr-set! inv _float 3 (exact->inexact (* w f))))) inv))
(define (quaternion-to-matrix q) (let* ([x (ptr-ref q _float 0)] [y (ptr-ref q _float 1)] [z (ptr-ref q _float 2)] [w (ptr-ref q _float 3)] [x2 (* x x)] [y2 (* y y)] [z2 (* z z)] [xy (* x y)] [xz (* x z)] [yz (* y z)] [wx (* w x)] [wy (* w y)] [wz (* w z)]) (list (- 1.0 (* 2.0 (+ y2 z2))) (* 2.0 (- xy wz)) (* 2.0 (+ xz wy)) 0.0 (* 2.0 (+ xy wz)) (- 1.0 (* 2.0 (+ x2 z2))) (* 2.0 (- yz wx)) 0.0 (* 2.0 (- xz wy)) (* 2.0 (+ yz wx)) (- 1.0 (* 2.0 (+ x2 y2))) 0.0 0.0 0.0 0.0 1.0)))

(provide clamp lerp remap vec2-add vec2-subtract vec2-scale vec2-multiply vec2-length vec2-normalize vec2-rotate vec2-clamp vec3-add vec3-subtract vec3-scale vec3-cross-product vec3-length vec3-dot-product vec3-angle vec3-negate vec3-normalize vec3-rotate-by-axis-angle vec3-lerp vector3-distance matrix-perspective matrix-multiply matrix-invert matrix-translate matrix-look-at matrix-rotate-xyz matrix-rotate-y matrix-rotate-x matrix-rotate-z quaternion-from-axis-angle quaternion-multiply quaternion-invert quaternion-to-matrix)
