#lang racket/base

;; raymath 模块纯 Racket 测试
;; 无需 OpenGL 上下文，可独立运行

(require "../helper.rkt"
         (prefix-in lib: "../../raylib/raylib.rkt"))

(printf "~n========================================~n")
(printf "  raymath 测试~n")
(printf "========================================~n")

;; ============================================================
;; 基础数学工具
;; ============================================================

(test-section "clamp / lerp / remap")

(define (test-clamp)
  (assert-= (lib:clamp 5 0 10) 5)
  (assert-= (lib:clamp -1 0 10) 0)
  (assert-= (lib:clamp 15 0 10) 10)
  (test-pass! "clamp"))

(define (test-lerp)
  (assert-= (lib:lerp 0 10 0.0) 0)
  (assert-= (lib:lerp 0 10 0.5) 5)
  (assert-= (lib:lerp 0 10 1.0) 10)
  (test-pass! "lerp"))

(define (test-remap)
  (assert-= (lib:remap 0.5 0 1 0 100) 50)
  (assert-= (lib:remap 0 0 1 -100 100) -100)
  (test-pass! "remap"))

(test-clamp)
(test-lerp)
(test-remap)

;; ============================================================
;; Vector2 运算
;; ============================================================

(test-section "Vector2 运算")

(define (test-vec2-basic)
  (define a (lib:make-Vector2 3.0 4.0))
  (define b (lib:make-Vector2 1.0 2.0))

  ;; length
  (assert-= (lib:vec2-length a) 5.0)
  (test-pass! "vec2-length")

  ;; add
  (define sum (lib:vec2-add a b))
  (assert-vec2= sum 4.0 6.0)
  (test-pass! "vec2-add")

  ;; subtract
  (define diff (lib:vec2-subtract a b))
  (assert-vec2= diff 2.0 2.0)
  (test-pass! "vec2-subtract")

  ;; scale
  (define scaled (lib:vec2-scale a 2.0))
  (assert-vec2= scaled 6.0 8.0)
  (test-pass! "vec2-scale")

  ;; normalize
  (define norm (lib:vec2-normalize a))
  (assert-= (lib:vec2-length norm) 1.0)
  (test-pass! "vec2-normalize")

  ;; dot (via multiply + sum)
  (define mul (lib:vec2-multiply a b))
  (assert-vec2= mul 3.0 8.0)
  (test-pass! "vec2-multiply")

  ;; clamp
  (define mn (lib:make-Vector2 0.0 0.0))
  (define mx (lib:make-Vector2 2.0 2.0))
  (define clamped (lib:vec2-clamp a mn mx))
  (assert-vec2= clamped 2.0 2.0)
  (test-pass! "vec2-clamp"))

(test-vec2-basic)

;; ============================================================
;; Vector3 运算
;; ============================================================

(test-section "Vector3 运算")

(define (test-vec3-basic)
  (define a (lib:make-Vector3 1.0 0.0 0.0))
  (define b (lib:make-Vector3 0.0 1.0 0.0))

  ;; cross product
  (define cross (lib:vec3-cross-product a b))
  (assert-vec3= cross 0.0 0.0 1.0)
  (test-pass! "vec3-cross-product")

  ;; dot product (perpendicular = 0)
  (assert-= (lib:vec3-dot-product a b) 0.0)
  (test-pass! "vec3-dot-product")

  ;; angle (perpendicular: 90° = pi/2)
  (assert-= (lib:vec3-angle a b) (/ 3.141592653589793 2))
  (test-pass! "vec3-angle")

  ;; add
  (define sum (lib:vec3-add a b))
  (assert-vec3= sum 1.0 1.0 0.0)
  (test-pass! "vec3-add")

  ;; scale
  (define scaled (lib:vec3-scale a 5.0))
  (assert-vec3= scaled 5.0 0.0 0.0)
  (test-pass! "vec3-scale")

  ;; length
  (assert-= (lib:vec3-length a) 1.0)
  (test-pass! "vec3-length")

  ;; negate
  (define neg (lib:vec3-negate a))
  (assert-vec3= neg -1.0 0.0 0.0)
  (test-pass! "vec3-negate")

  ;; normalize (already unit)
  (define n (lib:vec3-normalize a))
  (assert-vec3= n 1.0 0.0 0.0)
  (test-pass! "vec3-normalize")

  ;; lerp
  (define lerped (lib:vec3-lerp a b 0.5))
  (assert-vec3= lerped 0.5 0.5 0.0)
  (test-pass! "vec3-lerp")

  ;; rotate-by-axis-angle: rotate (1,0,0) around z-axis by 90° → (0,1,0)
  (define z-axis (lib:make-Vector3 0.0 0.0 1.0))
  (define rotated (lib:vec3-rotate-by-axis-angle a z-axis (/ 3.141592653589793 2)))
  (assert-vec3= rotated 0.0 1.0 0.0)
  (test-pass! "vec3-rotate-by-axis-angle"))

(test-vec3-basic)

;; ============================================================
;; Matrix FFI
;; ============================================================

(test-section "Matrix FFI")

(define (test-matrix)
  ;; MatrixPerspective should return a valid 4x4 matrix
  (define proj (lib:matrix-perspective 45.0 1.0 0.1 100.0))
  (unless (list? proj)
    (error 'test-matrix "matrix-perspective did not return a list: ~a" proj))
  (unless (= (length proj) 16)
    (error 'test-matrix "matrix-perspective returned ~a elements, expected 16" (length proj)))
  (test-pass! "matrix-perspective (valid 16-float list)")

  ;; MatrixMultiply with identity matrices
  (define ident
    (list 1.0 0.0 0.0 0.0
          0.0 1.0 0.0 0.0
          0.0 0.0 1.0 0.0
          0.0 0.0 0.0 1.0))
  (define result (lib:matrix-multiply ident ident))
  (unless (and (= (length result) 16) (list? result))
    (error 'test-matrix "matrix-multiply result invalid"))
  (test-pass! "matrix-multiply"))

(test-matrix)

;; ============================================================
;; Vector3Distance FFI
;; ============================================================

(test-section "Vector3Distance FFI")

(define (test-vec3-distance)
  (define a (lib:make-Vector3 0.0 0.0 0.0))
  (define b (lib:make-Vector3 3.0 4.0 0.0))
  (assert-= (lib:vector3-distance a b) 5.0)
  (test-pass! "vector3-distance"))

(test-vec3-distance)

(printf "~nraymath 测试完成!~n")
