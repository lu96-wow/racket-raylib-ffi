#lang racket/base

(require ffi/unsafe
         (prefix-in T: "types.rkt"))

(define (clamp value mn mx)
  (max mn (min mx value)))

(define (lerp start end amount)
  (+ start (* amount (- end start))))

(define (vec2-length v)
  (let ([x (ptr-ref v _float 0)]
        [y (ptr-ref v _float 1)])
    (sqrt (+ (* x x) (* y y)))))

(define (vec2-normalize v)
  (let* ([x (ptr-ref v _float 0)]
         [y (ptr-ref v _float 1)]
         [len (sqrt (+ (* x x) (* y y)))])
    (if (= len 0.0) v
        (let ([r (malloc T:_Vector2 'atomic)])
          (ptr-set! r _float 0 (/ x len))
          (ptr-set! r _float 1 (/ y len)) r))))

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

(provide
 clamp lerp
 vec2-length vec2-normalize
 vec3-add vec3-scale vec3-cross-product vec3-length
 vec3-dot-product vec3-angle vec3-negate vec3-normalize
 vec3-rotate-by-axis-angle vec3-lerp)
