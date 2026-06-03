#lang racket/base

;; types.rkt 结构体定义测试
;; 验证 struct 构造/访问/修改

(require "../helper.rkt"
         (prefix-in lib: "../../raylib/raylib.rkt")
         (prefix-in types: "../../raylib/types.rkt"))

(printf "~n========================================~n")
(printf "  types.rkt 结构体测试~n")
(printf "========================================~n")

;; ============================================================
;; 辅助: make-color
;; ============================================================
(define (my-make-color r g b a)
  (let ([c (malloc types:_Color 'atomic)])
    (ptr-set! c _ubyte 0 r)
    (ptr-set! c _ubyte 1 g)
    (ptr-set! c _ubyte 2 b)
    (ptr-set! c _ubyte 3 a)
    c))

;; ============================================================
;; Color
;; ============================================================
(test-section "Color")

(define (test-color)
  (define c (my-make-color 100 150 200 255))
  (assert-= (types:Color-r c) 100)
  (assert-= (types:Color-g c) 150)
  (assert-= (types:Color-b c) 200)
  (assert-= (types:Color-a c) 255)
  (test-pass! "Color 构造/读取")
  (types:set-Color-r! c 50)
  (assert-= (types:Color-r c) 50)
  (test-pass! "Color 修改"))

(test-color)

;; ============================================================
;; Vector2
;; ============================================================
(test-section "Vector2")

(define (test-vector2)
  (define v (types:make-Vector2 3.5 -1.2))
  (assert-= (types:Vector2-x v) 3.5)
  (assert-= (types:Vector2-y v) -1.2)
  (test-pass! "Vector2 构造/读取")
  (types:set-Vector2-x! v 10.0)
  (assert-= (types:Vector2-x v) 10.0)
  (test-pass! "Vector2 修改"))

(test-vector2)

;; ============================================================
;; Vector3
;; ============================================================
(test-section "Vector3")

(define (test-vector3)
  (define v (types:make-Vector3 1.0 2.0 3.0))
  (assert-= (types:Vector3-x v) 1.0)
  (assert-= (types:Vector3-y v) 2.0)
  (assert-= (types:Vector3-z v) 3.0)
  (test-pass! "Vector3 构造/读取")
  (types:set-Vector3-z! v 99.0)
  (assert-= (types:Vector3-z v) 99.0)
  (test-pass! "Vector3 修改"))

(test-vector3)

;; ============================================================
;; Rectangle
;; ============================================================
(test-section "Rectangle")

(define (test-rectangle)
  (define r (types:make-Rectangle 10 20 100 200))
  (assert-= (types:Rectangle-x r) 10)
  (assert-= (types:Rectangle-y r) 20)
  (assert-= (types:Rectangle-width r) 100)
  (assert-= (types:Rectangle-height r) 200)
  (test-pass! "Rectangle 构造/读取")
  (types:set-Rectangle-width! r 300)
  (assert-= (types:Rectangle-width r) 300)
  (test-pass! "Rectangle 修改"))

(test-rectangle)

;; ============================================================
;; Camera2D
;; ============================================================
(test-section "Camera2D")

(define (test-camera2d)
  (define cam (types:make-Camera2D 100 200 300 400 45.0 2.0))
  (assert-= (types:Camera2D-off-x cam) 100)
  (assert-= (types:Camera2D-off-y cam) 200)
  (assert-= (types:Camera2D-tar-x cam) 300)
  (assert-= (types:Camera2D-tar-y cam) 400)
  (assert-= (types:Camera2D-rotation cam) 45.0)
  (assert-= (types:Camera2D-zoom cam) 2.0)
  (test-pass! "Camera2D 构造/读取")
  (types:set-Camera2D-zoom! cam 5.0)
  (assert-= (types:Camera2D-zoom cam) 5.0)
  (test-pass! "Camera2D 修改"))

(test-camera2d)

;; ============================================================
;; Camera3D
;; ============================================================
(test-section "Camera3D")

(define (test-camera3d)
  (define cam (types:make-Camera3D
               10 20 30    ;; pos
               40 50 60    ;; tar
               0 1 0       ;; up
               45.0        ;; fovy
               0))         ;; projection
  (assert-= (types:Camera3D-pos-x cam) 10)
  (assert-= (types:Camera3D-pos-y cam) 20)
  (assert-= (types:Camera3D-pos-z cam) 30)
  (assert-= (types:Camera3D-tar-x cam) 40)
  (assert-= (types:Camera3D-up-y cam) 1.0)
  (assert-= (types:Camera3D-fovy cam) 45.0)
  (assert-= (types:Camera3D-projection cam) 0)
  (test-pass! "Camera3D 构造/读取"))

(test-camera3d)

;; ============================================================
;; Ray / RayCollision / BoundingBox
;; ============================================================
(test-section "Ray / RayCollision / BoundingBox")

(define (test-ray)
  (define r (types:make-Ray 0 0 0  1 0 0))
  (assert-= (types:Ray-pos-x r) 0)
  (assert-= (types:Ray-dir-x r) 1)
  (test-pass! "Ray 构造/读取"))

(define (test-raycollision)
  (define rc (types:make-RayCollision #f 0.0 0 0 0 0 0 0))
   (assert-false (types:RayCollision-hit rc))
  (test-pass! "RayCollision 构造"))

(define (test-boundingbox)
  (define bb (types:make-BoundingBox -1 -1 -1 1 1 1))
  (assert-= (types:BoundingBox-min-x bb) -1)
  (assert-= (types:BoundingBox-max-x bb) 1)
  (test-pass! "BoundingBox 构造/读取"))

(test-ray)
(test-raycollision)
(test-boundingbox)

;; ============================================================
;; RenderTexture / Image / Shader / Matrix
;; ============================================================
(test-section "复杂结构体")

(define (test-rendertexture)
  (define rt (types:make-RenderTexture 1 2 100 200 0 0 3 100 200 0 0))
  (assert-= (types:RenderTexture-id rt) 1)
  (assert-= (types:RenderTexture-tex-width rt) 100)
  (assert-= (types:RenderTexture-dep-id rt) 3)
  (test-pass! "RenderTexture 构造"))

(define (test-image)
  (define img (types:make-Image #f 640 480 1 7))
  (assert-= (types:Image-width img) 640)
  (assert-= (types:Image-format img) 7)
  (test-pass! "Image 构造"))

(define (test-shader)
  (define s (types:make-Shader 0 #f))
  (assert-= (types:Shader-id s) 0)
  (test-pass! "Shader 构造"))

(define (test-matrix)
  (define m (types:make-Matrix
             1 0 0 0 0 1 0 0
             0 0 1 0 0 0 0 1))
  (assert-= (types:Matrix-m0 m) 1)
  (assert-= (types:Matrix-m5 m) 1)
  (assert-= (types:Matrix-m15 m) 1)
  (test-pass! "Matrix 构造"))

(test-rendertexture)
(test-image)
(test-shader)
(test-matrix)

(printf "~ntypes.rkt 结构体测试完成!~n")

