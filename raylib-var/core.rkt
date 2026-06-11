#lang racket/base

;; raylib 预定义常量 — core 模块
;; 与 FFI 绑定分离，只包含固定值

(require ffi/unsafe
         (prefix-in T: "../raylib/types.rkt"))

;; ============================================================
;; 辅助: 创建 Color / Vector2 指针（malloc + 'atomic GC 管理）
;; 使用 color / vector2 / rectangle 等构造器
;; ============================================================

(define (color r g [b 0] [a 255])
  (let ([c (malloc T:_Color 'atomic)])
    (ptr-set! c _ubyte 0 r)
    (ptr-set! c _ubyte 1 g)
    (ptr-set! c _ubyte 2 b)
    (ptr-set! c _ubyte 3 a)
    c))

(define (vector2 x y)
  (let ([v (malloc T:_Vector2 'atomic)])
    (ptr-set! v _float 0 (exact->inexact x))  ;; offset 0 = first float
    (ptr-set! v _float 1 (exact->inexact y))  ;; offset 1 = second float (byte 4)
    v))

(define (vector2-x v)
  (ptr-ref v _float 0))

(define (vector2-y v)
  (ptr-ref v _float 1))

(define (set-vector2-x! v x)
  (ptr-set! v _float 0 (exact->inexact x)))

(define (set-vector2-y! v y)
  (ptr-set! v _float 1 (exact->inexact y)))

;; ============================================================
;; 辅助: 创建 Vector3 指针
;; ============================================================

(define (vector3 x y z)
  (let ([v (malloc T:_Vector3 'atomic)])
    (ptr-set! v _float 0 (exact->inexact x))
    (ptr-set! v _float 1 (exact->inexact y))
    (ptr-set! v _float 2 (exact->inexact z))
    v))

(define (vector3-x v) (ptr-ref v _float 0))
(define (vector3-y v) (ptr-ref v _float 1))
(define (vector3-z v) (ptr-ref v _float 2))

(define (set-vector3-x! v x) (ptr-set! v _float 0 (exact->inexact x)))
(define (set-vector3-y! v y) (ptr-set! v _float 1 (exact->inexact y)))
(define (set-vector3-z! v z) (ptr-set! v _float 2 (exact->inexact z)))

;; ============================================================
;; 辅助: 创建 Rectangle 指针
;; ============================================================

(define (rectangle x y w h)
  (let ([r (malloc T:_Rectangle 'atomic)])
    (ptr-set! r _float 0 (exact->inexact x))
    (ptr-set! r _float 1 (exact->inexact y))
    (ptr-set! r _float 2 (exact->inexact w))
    (ptr-set! r _float 3 (exact->inexact h))
    r))

(define (rectangle-x r)   (ptr-ref r _float 0))
(define (rectangle-y r)   (ptr-ref r _float 1))
(define (rectangle-w r)   (ptr-ref r _float 2))
(define (rectangle-h r)   (ptr-ref r _float 3))

(define (set-rectangle-x! r v) (ptr-set! r _float 0 (exact->inexact v)))
(define (set-rectangle-y! r v) (ptr-set! r _float 1 (exact->inexact v)))
(define (set-rectangle-w! r v) (ptr-set! r _float 2 (exact->inexact v)))
(define (set-rectangle-h! r v) (ptr-set! r _float 3 (exact->inexact v)))

;; ============================================================
;; 辅助: 创建 Camera2D 指针
;; ============================================================

(define (camera2d target-x target-y offset-x offset-y rotation zoom)
  (let ([cam (malloc T:_Camera2D 'atomic)])
    (ptr-set! cam _float 0 (exact->inexact offset-x))  ;; off-x
    (ptr-set! cam _float 1 (exact->inexact offset-y))  ;; off-y
    (ptr-set! cam _float 2 (exact->inexact target-x))  ;; tar-x
    (ptr-set! cam _float 3 (exact->inexact target-y))  ;; tar-y
    (ptr-set! cam _float 4 (exact->inexact rotation))   ;; rotation
    (ptr-set! cam _float 5 (exact->inexact zoom))       ;; zoom
    cam))

(define (camera2d-offset-x cam) (ptr-ref cam _float 0))
(define (camera2d-offset-y cam) (ptr-ref cam _float 1))
(define (camera2d-target-x cam) (ptr-ref cam _float 2))
(define (camera2d-target-y cam) (ptr-ref cam _float 3))
(define (camera2d-rotation cam) (ptr-ref cam _float 4))
(define (camera2d-zoom cam)     (ptr-ref cam _float 5))

(define (set-camera2d-offset-x! cam v) (ptr-set! cam _float 0 (exact->inexact v)))
(define (set-camera2d-offset-y! cam v) (ptr-set! cam _float 1 (exact->inexact v)))
(define (set-camera2d-target-x! cam v) (ptr-set! cam _float 2 (exact->inexact v)))
(define (set-camera2d-target-y! cam v) (ptr-set! cam _float 3 (exact->inexact v)))
(define (set-camera2d-rotation! cam v) (ptr-set! cam _float 4 (exact->inexact v)))
(define (set-camera2d-zoom! cam v)     (ptr-set! cam _float 5 (exact->inexact v)))

;; ============================================================
;; 辅助: 创建 Camera3D 指针
;;   layout: pos-x/y/z @ float 0-2, tar-x/y/z @ float 3-5,
;;           up-x/y/z @ float 6-8, fovy @ float 9, projection @ int 10
;; ============================================================

(define (camera3d pos-x pos-y pos-z
                  tar-x tar-y tar-z
                  up-x up-y up-z
                  fovy projection)
  (let ([cam (malloc T:_Camera3D 'atomic)])
    (ptr-set! cam _float 0 (exact->inexact pos-x))
    (ptr-set! cam _float 1 (exact->inexact pos-y))
    (ptr-set! cam _float 2 (exact->inexact pos-z))
    (ptr-set! cam _float 3 (exact->inexact tar-x))
    (ptr-set! cam _float 4 (exact->inexact tar-y))
    (ptr-set! cam _float 5 (exact->inexact tar-z))
    (ptr-set! cam _float 6 (exact->inexact up-x))
    (ptr-set! cam _float 7 (exact->inexact up-y))
    (ptr-set! cam _float 8 (exact->inexact up-z))
    (ptr-set! cam _float 9 (exact->inexact fovy))
    (ptr-set! cam _int 10 projection)
    cam))

(define (camera3d-pos-x cam) (ptr-ref cam _float 0))
(define (camera3d-pos-y cam) (ptr-ref cam _float 1))
(define (camera3d-pos-z cam) (ptr-ref cam _float 2))
(define (camera3d-tar-x cam) (ptr-ref cam _float 3))
(define (camera3d-tar-y cam) (ptr-ref cam _float 4))
(define (camera3d-tar-z cam) (ptr-ref cam _float 5))
(define (camera3d-up-x  cam) (ptr-ref cam _float 6))
(define (camera3d-up-y  cam) (ptr-ref cam _float 7))
(define (camera3d-up-z  cam) (ptr-ref cam _float 8))
(define (camera3d-fovy  cam) (ptr-ref cam _float 9))
(define (camera3d-projection  cam) (ptr-ref cam _int 10))

(define (set-camera3d-pos-x! cam v) (ptr-set! cam _float 0 (exact->inexact v)))
(define (set-camera3d-pos-y! cam v) (ptr-set! cam _float 1 (exact->inexact v)))
(define (set-camera3d-pos-z! cam v) (ptr-set! cam _float 2 (exact->inexact v)))
(define (set-camera3d-tar-x! cam v) (ptr-set! cam _float 3 (exact->inexact v)))
(define (set-camera3d-tar-y! cam v) (ptr-set! cam _float 4 (exact->inexact v)))
(define (set-camera3d-tar-z! cam v) (ptr-set! cam _float 5 (exact->inexact v)))
(define (set-camera3d-up-x!  cam v) (ptr-set! cam _float 6 (exact->inexact v)))
(define (set-camera3d-up-y!  cam v) (ptr-set! cam _float 7 (exact->inexact v)))
(define (set-camera3d-up-z!  cam v) (ptr-set! cam _float 8 (exact->inexact v)))
(define (set-camera3d-fovy!  cam v) (ptr-set! cam _float 9 (exact->inexact v)))
(define (set-camera3d-projection!  cam v) (ptr-set! cam _int 10 v))

;; ============================================================
;; 辅助: Ray 指针 (2 × Vector3 = 6 floats)
;; ============================================================

(define (ray pos-x pos-y pos-z dir-x dir-y dir-z)
  (let ([r (malloc T:_Ray 'atomic)])
    (ptr-set! r _float 0 (exact->inexact pos-x))
    (ptr-set! r _float 1 (exact->inexact pos-y))
    (ptr-set! r _float 2 (exact->inexact pos-z))
    (ptr-set! r _float 3 (exact->inexact dir-x))
    (ptr-set! r _float 4 (exact->inexact dir-y))
    (ptr-set! r _float 5 (exact->inexact dir-z))
    r))

(define (ray-pos-x r) (ptr-ref r _float 0))
(define (ray-pos-y r) (ptr-ref r _float 1))
(define (ray-pos-z r) (ptr-ref r _float 2))
(define (ray-dir-x r) (ptr-ref r _float 3))
(define (ray-dir-y r) (ptr-ref r _float 4))
(define (ray-dir-z r) (ptr-ref r _float 5))

(define (set-ray-pos-x! r v) (ptr-set! r _float 0 (exact->inexact v)))
(define (set-ray-pos-y! r v) (ptr-set! r _float 1 (exact->inexact v)))
(define (set-ray-pos-z! r v) (ptr-set! r _float 2 (exact->inexact v)))
(define (set-ray-dir-x! r v) (ptr-set! r _float 3 (exact->inexact v)))
(define (set-ray-dir-y! r v) (ptr-set! r _float 4 (exact->inexact v)))
(define (set-ray-dir-z! r v) (ptr-set! r _float 5 (exact->inexact v)))

;; ============================================================
;; 辅助: RayCollision 指针
;; hit @ bool, distance @ float, point=V3(3), normal=V3(3)
;; ============================================================

(define (ray-collision hit distance point-x point-y point-z
                       norm-x norm-y norm-z)
  (let ([rc (malloc T:_RayCollision 'atomic)])
    (ptr-set! rc _stdbool 0 hit)
    (ptr-set! rc _float 1 (exact->inexact distance))
    (ptr-set! rc _float 2 (exact->inexact point-x))
    (ptr-set! rc _float 3 (exact->inexact point-y))
    (ptr-set! rc _float 4 (exact->inexact point-z))
    (ptr-set! rc _float 5 (exact->inexact norm-x))
    (ptr-set! rc _float 6 (exact->inexact norm-y))
    (ptr-set! rc _float 7 (exact->inexact norm-z))
    rc))

(define (ray-collision-hit rc)        (ptr-ref rc _stdbool 0))
(define (ray-collision-distance rc)   (ptr-ref rc _float 1))
(define (ray-collision-point-x rc)    (ptr-ref rc _float 2))
(define (ray-collision-point-y rc)    (ptr-ref rc _float 3))
(define (ray-collision-point-z rc)    (ptr-ref rc _float 4))
(define (ray-collision-norm-x rc)     (ptr-ref rc _float 5))
(define (ray-collision-norm-y rc)     (ptr-ref rc _float 6))
(define (ray-collision-norm-z rc)     (ptr-ref rc _float 7))

(define (set-ray-collision-hit! rc v)       (ptr-set! rc _stdbool 0 v))
(define (set-ray-collision-distance! rc v)  (ptr-set! rc _float 1 (exact->inexact v)))
(define (set-ray-collision-point-x! rc v)   (ptr-set! rc _float 2 (exact->inexact v)))
(define (set-ray-collision-point-y! rc v)   (ptr-set! rc _float 3 (exact->inexact v)))
(define (set-ray-collision-point-z! rc v)   (ptr-set! rc _float 4 (exact->inexact v)))
(define (set-ray-collision-norm-x! rc v)    (ptr-set! rc _float 5 (exact->inexact v)))
(define (set-ray-collision-norm-y! rc v)    (ptr-set! rc _float 6 (exact->inexact v)))
(define (set-ray-collision-norm-z! rc v)    (ptr-set! rc _float 7 (exact->inexact v)))

;; ============================================================
;; 辅助: BoundingBox 指针 (2 × Vector3)
;; ============================================================

(define (bounding-box min-x min-y min-z max-x max-y max-z)
  (let ([bb (malloc T:_BoundingBox 'atomic)])
    (ptr-set! bb _float 0 (exact->inexact min-x))
    (ptr-set! bb _float 1 (exact->inexact min-y))
    (ptr-set! bb _float 2 (exact->inexact min-z))
    (ptr-set! bb _float 3 (exact->inexact max-x))
    (ptr-set! bb _float 4 (exact->inexact max-y))
    (ptr-set! bb _float 5 (exact->inexact max-z))
    bb))

(define (bounding-box-min-x bb) (ptr-ref bb _float 0))
(define (bounding-box-min-y bb) (ptr-ref bb _float 1))
(define (bounding-box-min-z bb) (ptr-ref bb _float 2))
(define (bounding-box-max-x bb) (ptr-ref bb _float 3))
(define (bounding-box-max-y bb) (ptr-ref bb _float 4))
(define (bounding-box-max-z bb) (ptr-ref bb _float 5))

(define (set-bounding-box-min-x! bb v) (ptr-set! bb _float 0 (exact->inexact v)))
(define (set-bounding-box-min-y! bb v) (ptr-set! bb _float 1 (exact->inexact v)))
(define (set-bounding-box-min-z! bb v) (ptr-set! bb _float 2 (exact->inexact v)))
(define (set-bounding-box-max-x! bb v) (ptr-set! bb _float 3 (exact->inexact v)))
(define (set-bounding-box-max-y! bb v) (ptr-set! bb _float 4 (exact->inexact v)))
(define (set-bounding-box-max-z! bb v) (ptr-set! bb _float 5 (exact->inexact v)))

;; ============================================================
;; 辅助: RenderTexture 指针 (11 字段)
;; ============================================================

(define (render-texture id
                        tex-id tex-width tex-height tex-mipmaps tex-format
                        dep-id dep-width dep-height dep-mipmaps dep-format)
  (let ([rt (malloc T:_RenderTexture 'atomic)])
    (ptr-set! rt _uint 0 id)
    (ptr-set! rt _uint 1 tex-id)
    (ptr-set! rt _int 2 tex-width)
    (ptr-set! rt _int 3 tex-height)
    (ptr-set! rt _int 4 tex-mipmaps)
    (ptr-set! rt _int 5 tex-format)
    (ptr-set! rt _uint 6 dep-id)
    (ptr-set! rt _int 7 dep-width)
    (ptr-set! rt _int 8 dep-height)
    (ptr-set! rt _int 9 dep-mipmaps)
    (ptr-set! rt _int 10 dep-format)
    rt))

(define (render-texture-id rt)             (ptr-ref rt _uint 0))
(define (render-texture-tex-id rt)         (ptr-ref rt _uint 1))
(define (render-texture-tex-width rt)      (ptr-ref rt _int 2))
(define (render-texture-tex-height rt)     (ptr-ref rt _int 3))
(define (render-texture-tex-mipmaps rt)    (ptr-ref rt _int 4))
(define (render-texture-tex-format rt)     (ptr-ref rt _int 5))
(define (render-texture-dep-id rt)         (ptr-ref rt _uint 6))
(define (render-texture-dep-width rt)      (ptr-ref rt _int 7))
(define (render-texture-dep-height rt)     (ptr-ref rt _int 8))
(define (render-texture-dep-mipmaps rt)    (ptr-ref rt _int 9))
(define (render-texture-dep-format rt)     (ptr-ref rt _int 10))

(define (set-render-texture-id! rt v)             (ptr-set! rt _uint 0 v))
(define (set-render-texture-tex-id! rt v)         (ptr-set! rt _uint 1 v))
(define (set-render-texture-tex-width! rt v)      (ptr-set! rt _int 2 v))
(define (set-render-texture-tex-height! rt v)     (ptr-set! rt _int 3 v))
(define (set-render-texture-tex-mipmaps! rt v)    (ptr-set! rt _int 4 v))
(define (set-render-texture-tex-format! rt v)     (ptr-set! rt _int 5 v))
(define (set-render-texture-dep-id! rt v)         (ptr-set! rt _uint 6 v))
(define (set-render-texture-dep-width! rt v)      (ptr-set! rt _int 7 v))
(define (set-render-texture-dep-height! rt v)     (ptr-set! rt _int 8 v))
(define (set-render-texture-dep-mipmaps! rt v)    (ptr-set! rt _int 9 v))
(define (set-render-texture-dep-format! rt v)     (ptr-set! rt _int 10 v))

;; ============================================================
;; 辅助: Image 指针 (pointer + 4 ints)
;; ============================================================

(define (image data width height mipmaps format)
  (let ([img (malloc T:_Image 'atomic)])
    (ptr-set! img _pointer 0 data)
    (ptr-set! img _int 1 width)
    (ptr-set! img _int 2 height)
    (ptr-set! img _int 3 mipmaps)
    (ptr-set! img _int 4 format)
    img))

(define (image-data img)    (ptr-ref img _pointer 0))
(define (image-width img)   (ptr-ref img _int 1))
(define (image-height img)  (ptr-ref img _int 2))
(define (image-mipmaps img) (ptr-ref img _int 3))
(define (image-format img)  (ptr-ref img _int 4))

(define (set-image-data! img v)    (ptr-set! img _pointer 0 v))
(define (set-image-width! img v)   (ptr-set! img _int 1 v))
(define (set-image-height! img v)  (ptr-set! img _int 2 v))
(define (set-image-mipmaps! img v) (ptr-set! img _int 3 v))
(define (set-image-format! img v)  (ptr-set! img _int 4 v))

;; ============================================================
;; 辅助: Shader 指针 (uint + pointer)
;; ============================================================

(define (shader id locs)
  (let ([s (malloc T:_Shader 'atomic)])
    (ptr-set! s _uint 0 id)
    (ptr-set! s _pointer 1 locs)
    s))

(define (shader-id s)   (ptr-ref s _uint 0))
(define (shader-locs s) (ptr-ref s _pointer 1))

(define (set-shader-id! s v)   (ptr-set! s _uint 0 v))
(define (set-shader-locs! s v) (ptr-set! s _pointer 1 v))

;; ============================================================
;; 辅助: Matrix 指针 (16 floats, 64 字节)
;; ============================================================

(define (matrix m0 m1 m2 m3 m4 m5 m6 m7
                m8 m9 m10 m11 m12 m13 m14 m15)
  (let ([m (malloc T:_Matrix 'atomic)])
    (ptr-set! m _float 0  (exact->inexact m0))
    (ptr-set! m _float 1  (exact->inexact m1))
    (ptr-set! m _float 2  (exact->inexact m2))
    (ptr-set! m _float 3  (exact->inexact m3))
    (ptr-set! m _float 4  (exact->inexact m4))
    (ptr-set! m _float 5  (exact->inexact m5))
    (ptr-set! m _float 6  (exact->inexact m6))
    (ptr-set! m _float 7  (exact->inexact m7))
    (ptr-set! m _float 8  (exact->inexact m8))
    (ptr-set! m _float 9  (exact->inexact m9))
    (ptr-set! m _float 10 (exact->inexact m10))
    (ptr-set! m _float 11 (exact->inexact m11))
    (ptr-set! m _float 12 (exact->inexact m12))
    (ptr-set! m _float 13 (exact->inexact m13))
    (ptr-set! m _float 14 (exact->inexact m14))
    (ptr-set! m _float 15 (exact->inexact m15))
    m))

(define (matrix-m0  m) (ptr-ref m _float 0))
(define (matrix-m1  m) (ptr-ref m _float 1))
(define (matrix-m2  m) (ptr-ref m _float 2))
(define (matrix-m3  m) (ptr-ref m _float 3))
(define (matrix-m4  m) (ptr-ref m _float 4))
(define (matrix-m5  m) (ptr-ref m _float 5))
(define (matrix-m6  m) (ptr-ref m _float 6))
(define (matrix-m7  m) (ptr-ref m _float 7))
(define (matrix-m8  m) (ptr-ref m _float 8))
(define (matrix-m9  m) (ptr-ref m _float 9))
(define (matrix-m10 m) (ptr-ref m _float 10))
(define (matrix-m11 m) (ptr-ref m _float 11))
(define (matrix-m12 m) (ptr-ref m _float 12))
(define (matrix-m13 m) (ptr-ref m _float 13))
(define (matrix-m14 m) (ptr-ref m _float 14))
(define (matrix-m15 m) (ptr-ref m _float 15))

(define (set-matrix-m0!  m v) (ptr-set! m _float 0  (exact->inexact v)))
(define (set-matrix-m1!  m v) (ptr-set! m _float 1  (exact->inexact v)))
(define (set-matrix-m2!  m v) (ptr-set! m _float 2  (exact->inexact v)))
(define (set-matrix-m3!  m v) (ptr-set! m _float 3  (exact->inexact v)))
(define (set-matrix-m4!  m v) (ptr-set! m _float 4  (exact->inexact v)))
(define (set-matrix-m5!  m v) (ptr-set! m _float 5  (exact->inexact v)))
(define (set-matrix-m6!  m v) (ptr-set! m _float 6  (exact->inexact v)))
(define (set-matrix-m7!  m v) (ptr-set! m _float 7  (exact->inexact v)))
(define (set-matrix-m8!  m v) (ptr-set! m _float 8  (exact->inexact v)))
(define (set-matrix-m9!  m v) (ptr-set! m _float 9  (exact->inexact v)))
(define (set-matrix-m10! m v) (ptr-set! m _float 10 (exact->inexact v)))
(define (set-matrix-m11! m v) (ptr-set! m _float 11 (exact->inexact v)))
(define (set-matrix-m12! m v) (ptr-set! m _float 12 (exact->inexact v)))
(define (set-matrix-m13! m v) (ptr-set! m _float 13 (exact->inexact v)))
(define (set-matrix-m14! m v) (ptr-set! m _float 14 (exact->inexact v)))
(define (set-matrix-m15! m v) (ptr-set! m _float 15 (exact->inexact v)))

;; ============================================================
;; 预定义颜色
;; ============================================================

(define RAYWHITE   (color 245 245 245))
(define LIGHTGRAY  (color 200 200 200))
(define GRAY       (color 130 130 130))
(define DARKGRAY   (color 80 80 80))
(define YELLOW     (color 253 249 0))
(define GOLD       (color 255 203 0))
(define ORANGE     (color 255 161 0))
(define PINK       (color 255 109 194))
(define RED        (color 230 41 55))
(define MAROON     (color 190 33 55))
(define GREEN      (color 0 228 48))
(define LIME       (color 0 158 47))
(define DARKGREEN  (color 0 117 44))
(define SKYBLUE    (color 102 191 255))
(define BLUE       (color 0 121 241))
(define DARKBLUE   (color 0 82 172))
(define PURPLE     (color 200 122 255))
(define VIOLET     (color 135 60 190))
(define DARKPURPLE (color 112 31 126))
(define BEIGE      (color 211 176 131))
(define BROWN      (color 127 106 79))
(define DARKBROWN  (color 76 63 47))
(define WHITE      (color 255 255 255))
(define BLACK      (color 0 0 0))
(define BLANK      (color 0 0 0 0))
(define MAGENTA    (color 255 0 255))

;; ============================================================
;; 键盘键值
;; ============================================================

(define KEY-NULL          0)
(define KEY-APOSTROPHE    39) (define KEY-COMMA   44)
(define KEY-MINUS         45) (define KEY-PERIOD  46)
(define KEY-SLASH         47)
(define KEY-ZERO          48) (define KEY-ONE     49)
(define KEY-TWO           50) (define KEY-THREE   51)
(define KEY-FOUR          52) (define KEY-FIVE    53)
(define KEY-SIX           54) (define KEY-SEVEN   55)
(define KEY-EIGHT         56) (define KEY-NINE    57)
(define KEY-SEMICOLON     59) (define KEY-EQUAL   61)
(define KEY-A             65) (define KEY-B       66)
(define KEY-C             67) (define KEY-D       68)
(define KEY-E             69) (define KEY-F       70)
(define KEY-G             71) (define KEY-H       72)
(define KEY-I             73) (define KEY-J       74)
(define KEY-K             75) (define KEY-L       76)
(define KEY-M             77) (define KEY-N       78)
(define KEY-O             79) (define KEY-P       80)
(define KEY-Q             81) (define KEY-R       82)
(define KEY-S             83) (define KEY-T       84)
(define KEY-U             85) (define KEY-V       86)
(define KEY-W             87) (define KEY-X       88)
(define KEY-Y             89) (define KEY-Z       90)
(define KEY-LEFT-BRACKET  91) (define KEY-BACKSLASH     92)
(define KEY-RIGHT-BRACKET 93) (define KEY-GRAVE         96)
(define KEY-SPACE         32) (define KEY-ESCAPE       256)
(define KEY-ENTER         257)(define KEY-TAB         258)
(define KEY-BACKSPACE     259)(define KEY-INSERT      260)
(define KEY-DELETE        261)(define KEY-RIGHT       262)
(define KEY-LEFT          263)(define KEY-DOWN        264)
(define KEY-UP            265)(define KEY-PAGE-UP     266)
(define KEY-PAGE-DOWN     267)(define KEY-HOME        268)
(define KEY-END           269)
(define KEY-CAPS-LOCK     280)(define KEY-SCROLL-LOCK 281)
(define KEY-NUM-LOCK      282)(define KEY-PRINT-SCREEN 283)
(define KEY-PAUSE         284)
(define KEY-F1            290)(define KEY-F2          291)
(define KEY-F3            292)(define KEY-F4          293)
(define KEY-F5            294)(define KEY-F6          295)
(define KEY-F7            296)(define KEY-F8          297)
(define KEY-F9            298)(define KEY-F10         299)
(define KEY-F11           300)(define KEY-F12         301)
(define KEY-LEFT-SHIFT    340)
(define KEY-LEFT-CONTROL  341)(define KEY-LEFT-ALT   342)
(define KEY-LEFT-SUPER    343)(define KEY-RIGHT-SHIFT 344)
(define KEY-RIGHT-CONTROL 345)(define KEY-RIGHT-ALT   346)
(define KEY-RIGHT-SUPER   347)(define KEY-KB-MENU    348)

;; ============================================================
;; 鼠标按钮
;; ============================================================

(define MOUSE-BUTTON-LEFT      0)
(define MOUSE-BUTTON-RIGHT     1)
(define MOUSE-BUTTON-MIDDLE    2)
(define MOUSE-BUTTON-SIDE      3)
(define MOUSE-BUTTON-EXTRA     4)
(define MOUSE-BUTTON-FORWARD   5)
(define MOUSE-BUTTON-BACK      6)

;; ============================================================
;; 窗口标志
;; ============================================================

(define FLAG-VSYNC-HINT              64)
(define FLAG-FULLSCREEN-MODE         2)
(define FLAG-WINDOW-RESIZABLE        4)
(define FLAG-WINDOW-UNDECORATED      8)
(define FLAG-WINDOW-HIDDEN          128)
(define FLAG-WINDOW-MINIMIZED       512)
(define FLAG-WINDOW-MAXIMIZED      1024)
(define FLAG-WINDOW-UNFOCUSED      2048)
(define FLAG-WINDOW-TOPMOST        4096)
(define FLAG-WINDOW-HIGHDPI        8192)
(define FLAG-WINDOW-ALWAYS-RUN    16384)
(define FLAG-WINDOW-TRANSPARENT    32)
(define FLAG-MSAA-4X-HINT          16)
(define FLAG-BORDERLESS-WINDOWED-MODE 32768)

;; ============================================================
;; 日志 / 手势 / 手柄 / 相机
;; ============================================================

(define LOG-INFO      1) (define LOG-WARNING   2)
(define LOG-ERROR     4) (define LOG-DEBUG     8)

(define GESTURE-NONE        0)  (define GESTURE-TAP        1)
(define GESTURE-DOUBLETAP   2)  (define GESTURE-HOLD       4)
(define GESTURE-DRAG        8)  (define GESTURE-SWIPE-RIGHT 16)
(define GESTURE-SWIPE-LEFT  32) (define GESTURE-SWIPE-UP   64)
(define GESTURE-SWIPE-DOWN  128)(define GESTURE-PINCH-IN  256)
(define GESTURE-PINCH-OUT   512)

(define GAMEPAD-BUTTON-UNKNOWN          0)
(define GAMEPAD-BUTTON-LEFT-FACE-UP     1)
(define GAMEPAD-BUTTON-LEFT-FACE-RIGHT  2)
(define GAMEPAD-BUTTON-LEFT-FACE-DOWN   3)
(define GAMEPAD-BUTTON-LEFT-FACE-LEFT   4)
(define GAMEPAD-BUTTON-RIGHT-FACE-UP    5)
(define GAMEPAD-BUTTON-RIGHT-FACE-RIGHT 6)
(define GAMEPAD-BUTTON-RIGHT-FACE-DOWN  7)
(define GAMEPAD-BUTTON-RIGHT-FACE-LEFT  8)
(define GAMEPAD-BUTTON-LEFT-TRIGGER-1   9)
(define GAMEPAD-BUTTON-LEFT-TRIGGER-2   10)
(define GAMEPAD-BUTTON-RIGHT-TRIGGER-1  11)
(define GAMEPAD-BUTTON-RIGHT-TRIGGER-2  12)
(define GAMEPAD-BUTTON-MIDDLE-LEFT      13)
(define GAMEPAD-BUTTON-MIDDLE           14)
(define GAMEPAD-BUTTON-MIDDLE-RIGHT     15)
(define GAMEPAD-BUTTON-LEFT-THUMB       16)
(define GAMEPAD-BUTTON-RIGHT-THUMB      17)

(define GAMEPAD-AXIS-LEFT-X        0)
(define GAMEPAD-AXIS-LEFT-Y        1)
(define GAMEPAD-AXIS-RIGHT-X       2)
(define GAMEPAD-AXIS-RIGHT-Y       3)
(define GAMEPAD-AXIS-LEFT-TRIGGER  4)
(define GAMEPAD-AXIS-RIGHT-TRIGGER 5)

(define CAMERA-CUSTOM          0)
(define CAMERA-FREE            1)
(define CAMERA-ORBITAL         2)
(define CAMERA-FIRST-PERSON    3)
(define CAMERA-THIRD-PERSON    4)

(define CAMERA-PERSPECTIVE     0)
(define TEXTURE-FILTER-POINT 0)
(define TEXTURE-FILTER-BILINEAR 1)
(define TEXTURE-FILTER-TRILINEAR 2)

;; Font types
(define FONT-DEFAULT 0)
(define FONT-BITMAP 1)
(define FONT-SDF 2)

;; Mouse cursor
(define MOUSE-CURSOR-DEFAULT 0)
(define MOUSE-CURSOR-ARROW 1)
(define MOUSE-CURSOR-IBEAM 2)
(define MOUSE-CURSOR-CROSSHAIR 3)
(define MOUSE-CURSOR-POINTING-HAND 4)
(define MOUSE-CURSOR-RESIZE-EW 5)
(define MOUSE-CURSOR-RESIZE-NS 6)
(define MOUSE-CURSOR-RESIZE-NWSE 7)
(define MOUSE-CURSOR-RESIZE-NESW 8)
(define MOUSE-CURSOR-RESIZE-ALL 9)
(define MOUSE-CURSOR-NOT-ALLOWED 10)

(define CAMERA-ORTHOGRAPHIC    1)

;; ============================================================
;; Shader uniform 类型
;; ============================================================

(define SHADER-UNIFORM-FLOAT   0)
(define SHADER-UNIFORM-VEC2    1)
(define SHADER-UNIFORM-VEC3    2)
(define SHADER-UNIFORM-VEC4    3)
(define SHADER-UNIFORM-INT     4)

;; ============================================================
;; Blend 模式 (rlgl)
;; ============================================================

(define BLEND-ALPHA          0)
(define BLEND-ADDITIVE       1)
(define BLEND-MULTIPLIED     2)
(define BLEND-ADD-COLORS     3)
(define BLEND-CUSTOM         6)
(define RLGL-SRC-ALPHA   #x0302)
(define RLGL-MIN         #x8007)
(define RLGL-MAX         #x8008)

;; Material map types
(define MATERIAL-MAP-DIFFUSE 0)

;; ============================================================
;; 导出
;; ============================================================

(provide
 color vector2 vector2-x vector2-y set-vector2-x! set-vector2-y!
 vector3 vector3-x vector3-y vector3-z
 set-vector3-x! set-vector3-y! set-vector3-z!
 rectangle rectangle-x rectangle-y rectangle-w rectangle-h
 set-rectangle-x! set-rectangle-y! set-rectangle-w! set-rectangle-h!
 camera2d
 camera2d-offset-x camera2d-offset-y
 camera2d-target-x camera2d-target-y
 camera2d-rotation camera2d-zoom
 set-camera2d-offset-x! set-camera2d-offset-y!
 set-camera2d-target-x! set-camera2d-target-y!
 set-camera2d-rotation! set-camera2d-zoom!
 camera3d
 camera3d-pos-x camera3d-pos-y camera3d-pos-z
 camera3d-tar-x camera3d-tar-y camera3d-tar-z
 camera3d-up-x camera3d-up-y camera3d-up-z
 camera3d-fovy camera3d-projection
 set-camera3d-pos-x! set-camera3d-pos-y! set-camera3d-pos-z!
 set-camera3d-tar-x! set-camera3d-tar-y! set-camera3d-tar-z!
 set-camera3d-up-x! set-camera3d-up-y! set-camera3d-up-z!
 set-camera3d-fovy! set-camera3d-projection!
 ray ray-pos-x ray-pos-y ray-pos-z
 ray-dir-x ray-dir-y ray-dir-z
 set-ray-pos-x! set-ray-pos-y! set-ray-pos-z!
 set-ray-dir-x! set-ray-dir-y! set-ray-dir-z!
 ray-collision ray-collision-hit ray-collision-distance
 ray-collision-point-x ray-collision-point-y ray-collision-point-z
 ray-collision-norm-x ray-collision-norm-y ray-collision-norm-z
 set-ray-collision-hit! set-ray-collision-distance!
 set-ray-collision-point-x! set-ray-collision-point-y! set-ray-collision-point-z!
 set-ray-collision-norm-x! set-ray-collision-norm-y! set-ray-collision-norm-z!
 bounding-box
 bounding-box-min-x bounding-box-min-y bounding-box-min-z
 bounding-box-max-x bounding-box-max-y bounding-box-max-z
 set-bounding-box-min-x! set-bounding-box-min-y! set-bounding-box-min-z!
 set-bounding-box-max-x! set-bounding-box-max-y! set-bounding-box-max-z!
 render-texture
 render-texture-id render-texture-tex-id
 render-texture-tex-width render-texture-tex-height
 render-texture-tex-mipmaps render-texture-tex-format
 render-texture-dep-id render-texture-dep-width
 render-texture-dep-height render-texture-dep-mipmaps render-texture-dep-format
 set-render-texture-id! set-render-texture-tex-id!
 set-render-texture-tex-width! set-render-texture-tex-height!
 set-render-texture-tex-mipmaps! set-render-texture-tex-format!
 set-render-texture-dep-id! set-render-texture-dep-width!
 set-render-texture-dep-height! set-render-texture-dep-mipmaps! set-render-texture-dep-format!
 image image-data image-width image-height image-mipmaps image-format
 set-image-data! set-image-width! set-image-height! set-image-mipmaps! set-image-format!
 shader shader-id shader-locs set-shader-id! set-shader-locs!
 matrix
 matrix-m0 matrix-m1 matrix-m2 matrix-m3
 matrix-m4 matrix-m5 matrix-m6 matrix-m7
 matrix-m8 matrix-m9 matrix-m10 matrix-m11
 matrix-m12 matrix-m13 matrix-m14 matrix-m15
 set-matrix-m0! set-matrix-m1! set-matrix-m2! set-matrix-m3!
 set-matrix-m4! set-matrix-m5! set-matrix-m6! set-matrix-m7!
 set-matrix-m8! set-matrix-m9! set-matrix-m10! set-matrix-m11!
 set-matrix-m12! set-matrix-m13! set-matrix-m14! set-matrix-m15!
 RAYWHITE LIGHTGRAY GRAY DARKGRAY YELLOW GOLD ORANGE
 PINK RED MAROON GREEN LIME DARKGREEN SKYBLUE
 BLUE DARKBLUE PURPLE VIOLET DARKPURPLE
 BEIGE BROWN DARKBROWN WHITE BLACK BLANK MAGENTA

 KEY-NULL KEY-SPACE KEY-ESCAPE KEY-ENTER KEY-TAB
 KEY-BACKSPACE KEY-INSERT KEY-DELETE
 KEY-RIGHT KEY-LEFT KEY-DOWN KEY-UP
 KEY-PAGE-UP KEY-PAGE-DOWN KEY-HOME KEY-END
 KEY-CAPS-LOCK KEY-SCROLL-LOCK KEY-NUM-LOCK
 KEY-PRINT-SCREEN KEY-PAUSE
 KEY-LEFT-SHIFT KEY-LEFT-CONTROL KEY-LEFT-ALT KEY-LEFT-SUPER
 KEY-RIGHT-SHIFT KEY-RIGHT-CONTROL KEY-RIGHT-ALT KEY-RIGHT-SUPER
 KEY-KB-MENU
 KEY-F1 KEY-F2 KEY-F3 KEY-F4 KEY-F5 KEY-F6
 KEY-F7 KEY-F8 KEY-F9 KEY-F10 KEY-F11 KEY-F12
 KEY-A KEY-B KEY-C KEY-D KEY-E KEY-F KEY-G
 KEY-H KEY-I KEY-J KEY-K KEY-L KEY-M KEY-N
 KEY-O KEY-P KEY-Q KEY-R KEY-S KEY-T KEY-U
 KEY-V KEY-W KEY-X KEY-Y KEY-Z
 KEY-ZERO KEY-ONE KEY-TWO KEY-THREE KEY-FOUR
 KEY-FIVE KEY-SIX KEY-SEVEN KEY-EIGHT KEY-NINE
 KEY-APOSTROPHE KEY-COMMA KEY-MINUS KEY-PERIOD KEY-SLASH
 KEY-SEMICOLON KEY-EQUAL KEY-GRAVE
 KEY-LEFT-BRACKET KEY-BACKSLASH KEY-RIGHT-BRACKET

 MOUSE-BUTTON-LEFT MOUSE-BUTTON-RIGHT MOUSE-BUTTON-MIDDLE
 MOUSE-BUTTON-SIDE MOUSE-BUTTON-EXTRA
 MOUSE-BUTTON-FORWARD MOUSE-BUTTON-BACK

 FLAG-VSYNC-HINT FLAG-FULLSCREEN-MODE FLAG-WINDOW-RESIZABLE
 FLAG-WINDOW-UNDECORATED FLAG-WINDOW-HIDDEN
 FLAG-WINDOW-MINIMIZED FLAG-WINDOW-MAXIMIZED
 FLAG-WINDOW-UNFOCUSED FLAG-WINDOW-TOPMOST
 FLAG-WINDOW-HIGHDPI FLAG-WINDOW-ALWAYS-RUN
 FLAG-WINDOW-TRANSPARENT FLAG-MSAA-4X-HINT
 FLAG-BORDERLESS-WINDOWED-MODE

 LOG-INFO LOG-WARNING LOG-ERROR LOG-DEBUG
 GESTURE-NONE GESTURE-TAP GESTURE-DOUBLETAP
 GESTURE-HOLD GESTURE-DRAG
 GESTURE-SWIPE-RIGHT GESTURE-SWIPE-LEFT
 GESTURE-SWIPE-UP GESTURE-SWIPE-DOWN
 GESTURE-PINCH-IN GESTURE-PINCH-OUT
 GAMEPAD-BUTTON-UNKNOWN GAMEPAD-BUTTON-LEFT-FACE-UP
 GAMEPAD-BUTTON-LEFT-FACE-RIGHT GAMEPAD-BUTTON-LEFT-FACE-DOWN
 GAMEPAD-BUTTON-LEFT-FACE-LEFT GAMEPAD-BUTTON-RIGHT-FACE-UP
 GAMEPAD-BUTTON-RIGHT-FACE-RIGHT GAMEPAD-BUTTON-RIGHT-FACE-DOWN
 GAMEPAD-BUTTON-RIGHT-FACE-LEFT
 GAMEPAD-BUTTON-LEFT-TRIGGER-1 GAMEPAD-BUTTON-LEFT-TRIGGER-2
 GAMEPAD-BUTTON-RIGHT-TRIGGER-1 GAMEPAD-BUTTON-RIGHT-TRIGGER-2
 GAMEPAD-BUTTON-MIDDLE-LEFT GAMEPAD-BUTTON-MIDDLE
 GAMEPAD-BUTTON-MIDDLE-RIGHT
 GAMEPAD-BUTTON-LEFT-THUMB GAMEPAD-BUTTON-RIGHT-THUMB
 GAMEPAD-AXIS-LEFT-X GAMEPAD-AXIS-LEFT-Y
 GAMEPAD-AXIS-RIGHT-X GAMEPAD-AXIS-RIGHT-Y
 GAMEPAD-AXIS-LEFT-TRIGGER GAMEPAD-AXIS-RIGHT-TRIGGER
 CAMERA-CUSTOM CAMERA-FREE CAMERA-ORBITAL
 CAMERA-FIRST-PERSON CAMERA-THIRD-PERSON
 CAMERA-PERSPECTIVE CAMERA-ORTHOGRAPHIC
 TEXTURE-FILTER-POINT TEXTURE-FILTER-BILINEAR TEXTURE-FILTER-TRILINEAR
 FONT-DEFAULT FONT-BITMAP FONT-SDF
 MOUSE-CURSOR-DEFAULT MOUSE-CURSOR-ARROW MOUSE-CURSOR-IBEAM
 MOUSE-CURSOR-CROSSHAIR MOUSE-CURSOR-POINTING-HAND
 MOUSE-CURSOR-RESIZE-EW MOUSE-CURSOR-RESIZE-NS
 MOUSE-CURSOR-RESIZE-NWSE MOUSE-CURSOR-RESIZE-NESW
 MOUSE-CURSOR-RESIZE-ALL MOUSE-CURSOR-NOT-ALLOWED
 SHADER-UNIFORM-FLOAT SHADER-UNIFORM-VEC2
 SHADER-UNIFORM-VEC3 SHADER-UNIFORM-VEC4
 SHADER-UNIFORM-INT
 BLEND-ALPHA BLEND-ADDITIVE BLEND-MULTIPLIED BLEND-ADD-COLORS BLEND-CUSTOM
 RLGL-SRC-ALPHA RLGL-MIN RLGL-MAX
 MATERIAL-MAP-DIFFUSE
)
