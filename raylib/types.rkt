#lang racket/base

;; raylib 结构体/类型定义
;;
;; 对应 raylib.h 的类型定义部分 (struct, enum, typedef)
;; 所有结构体用 define-cstruct 定义，Racket 侧一律按指针操作
;;
;; 设计约定:
;;   - 在 Racket 中通过 make-Xxx 构造 boxed 指针
;;   - 对 C 侧传值的小结构体 (Color, Vector2 等),
;;     由各模块定义对应的 _xxx-pass 类型自动解包
;;
;; 导出: _Color, _Vector2 等类型 + make-Xxx / Xxx? / 字段访问器

(require ffi/unsafe)

;; ============================================================
;; 共享库
;; ============================================================

(define lib
  (ffi-lib "/home/debian/raylib/build/raylib/libraylib.so"))

;; ============================================================
;; 基础类型
;; raylib 使用 C99 的 _Bool（1 字节），FFI 签名中统一用 _stdbool。
;; 不覆盖 _bool（4 字节），避免与 ffi/unsafe 冲突。
;; ============================================================

;; ============================================================
;; Color (raylib.h:248) — 4 字节小结构体
;; ============================================================

(define-cstruct _Color
  ([r _ubyte]
   [g _ubyte]
   [b _ubyte]
   [a _ubyte]))

;; Vector2 (raylib.h:216)
(define-cstruct _Vector2
  ([x _float]
   [y _float]))

;; Vector3 (raylib.h:222) — 12 字节: 3 × float
(define-cstruct _Vector3
  ([x _float]
   [y _float]
   [z _float]))

;; Rectangle (raylib.h:256)
(define-cstruct _Rectangle
  ([x _float]
   [y _float]
   [width _float]
   [height _float]))

;; Camera2D (raylib.h:338)
;;   Vector2 offset;    // offset.x @ _float 0, offset.y @ _float 1
;;   Vector2 target;    // target.x @ _float 2, target.y @ _float 3
;;   float rotation;    // @ _float 4
;;   float zoom;        // @ _float 5
(define-cstruct _Camera2D
  ([off-x _float]
   [off-y _float]
   [tar-x _float]
   [tar-y _float]
   [rotation _float]
   [zoom _float]))

;; Camera3D (raylib.h:327) — 44 字节
;;   内嵌 Vector3 position (3 floats), Vector3 target (3 floats), Vector3 up (3 floats),
;;   float fovy, int projection
;;   布局: pos-x,y,z @ float 0-2; tar-x,y,z @ float 3-5; up-x,y,z @ float 6-8;
;;         fovy @ float 9; projection @ int 0 (byte 40)
(define-cstruct _Camera3D
  ([pos-x _float] [pos-y _float] [pos-z _float]
   [tar-x _float] [tar-y _float] [tar-z _float]
   [up-x _float]  [up-y _float]  [up-z _float]
   [fovy _float]
   [projection _int]))

;; Ray (raylib.h:445) — 24 字节: 2 × Vector3 (position, direction)
(define-cstruct _Ray
  ([pos-x _float] [pos-y _float] [pos-z _float]
   [dir-x _float] [dir-y _float] [dir-z _float]))

;; RayCollision (raylib.h:451)
;;   bool hit;            // 1B + 3 padding
;;   float distance;      // 4B
;;   Vector3 point;       // 12B
;;   Vector3 normal;      // 12B
;;   总计: 32B
(define-cstruct _RayCollision
  ([hit _stdbool]
   [distance _float]
   [point-x _float] [point-y _float] [point-z _float]
   [norm-x _float]  [norm-y _float]  [norm-z _float]))

;; BoundingBox (raylib.h:459) — 24 字节: 2 × Vector3 (min, max)
(define-cstruct _BoundingBox
  ([min-x _float] [min-y _float] [min-z _float]
   [max-x _float] [max-y _float] [max-z _float]))

;; RenderTexture (raylib.h:288)
;;   unsigned int id;           // @ _uint 0
;;   Texture texture (inline):  // Texture → { unsigned int id; int w, h, mip, fmt; }
;;     unsigned int tex_id;     // @ _uint 1
;;     int tex_width;           // @ _int 2
;;     int tex_height;          // @ _int 3
;;     int tex_mipmaps;         // @ _int 4
;;     int tex_format;          // @ _int 5
;;   Texture depth (inline):
;;     unsigned int dep_id;     // @ _uint 6
;;     int dep_width;           // @ _int 7
;;     int dep_height;          // @ _int 8
;;     int dep_mipmaps;         // @ _int 9
;;     int dep_format;          // @ _int 10
;; 总计: 44 字节, 11 个字段
(define-cstruct _RenderTexture
  ([id _uint]
   [tex-id _uint] [tex-width _int] [tex-height _int] [tex-mipmaps _int] [tex-format _int]
   [dep-id _uint] [dep-width _int] [dep-height _int] [dep-mipmaps _int] [dep-format _int]))


;; Shader (raylib.h:375) — 12 字节: unsigned int id + int* locs
(define-cstruct _Shader
  ([id _uint]
   [locs _pointer]))
;; ============================================================
;; 导出
;; ============================================================

(provide
 lib
 ;; Color
 _Color Color? make-Color
 Color-r Color-g Color-b Color-a
 set-Color-r! set-Color-g! set-Color-b! set-Color-a!
 ;; Vector2
 _Vector2 Vector2? make-Vector2
 Vector2-x Vector2-y
 set-Vector2-x! set-Vector2-y!
 ;; Vector3
 _Vector3 Vector3? make-Vector3
 Vector3-x Vector3-y Vector3-z
 set-Vector3-x! set-Vector3-y! set-Vector3-z!
 ;; Rectangle
 _Rectangle Rectangle? make-Rectangle
 Rectangle-x Rectangle-y Rectangle-width Rectangle-height
 set-Rectangle-x! set-Rectangle-y! set-Rectangle-width! set-Rectangle-height!
 ;; Camera2D
 _Camera2D Camera2D? make-Camera2D
 Camera2D-off-x Camera2D-off-y
 Camera2D-tar-x Camera2D-tar-y
 Camera2D-rotation Camera2D-zoom
 set-Camera2D-off-x! set-Camera2D-off-y!
 set-Camera2D-tar-x! set-Camera2D-tar-y!
 set-Camera2D-rotation! set-Camera2D-zoom!
 ;; Camera3D
 _Camera3D Camera3D? make-Camera3D
 Camera3D-pos-x Camera3D-pos-y Camera3D-pos-z
 Camera3D-tar-x Camera3D-tar-y Camera3D-tar-z
 Camera3D-up-x Camera3D-up-y Camera3D-up-z
 Camera3D-fovy Camera3D-projection
 set-Camera3D-pos-x! set-Camera3D-pos-y! set-Camera3D-pos-z!
 set-Camera3D-tar-x! set-Camera3D-tar-y! set-Camera3D-tar-z!
 set-Camera3D-up-x! set-Camera3D-up-y! set-Camera3D-up-z!
 set-Camera3D-fovy! set-Camera3D-projection!
  ;; Ray
  _Ray Ray? make-Ray
  Ray-pos-x Ray-pos-y Ray-pos-z
  Ray-dir-x Ray-dir-y Ray-dir-z
  set-Ray-pos-x! set-Ray-pos-y! set-Ray-pos-z!
  set-Ray-dir-x! set-Ray-dir-y! set-Ray-dir-z!
  ;; RayCollision
  _RayCollision RayCollision? make-RayCollision
  RayCollision-hit RayCollision-distance
  RayCollision-point-x RayCollision-point-y RayCollision-point-z
  RayCollision-norm-x RayCollision-norm-y RayCollision-norm-z
  set-RayCollision-hit! set-RayCollision-distance!
  set-RayCollision-point-x! set-RayCollision-point-y! set-RayCollision-point-z!
  set-RayCollision-norm-x! set-RayCollision-norm-y! set-RayCollision-norm-z!
  ;; BoundingBox
  _BoundingBox BoundingBox? make-BoundingBox
  BoundingBox-min-x BoundingBox-min-y BoundingBox-min-z
  BoundingBox-max-x BoundingBox-max-y BoundingBox-max-z
  set-BoundingBox-min-x! set-BoundingBox-min-y! set-BoundingBox-min-z!
  set-BoundingBox-max-x! set-BoundingBox-max-y! set-BoundingBox-max-z!
  ;; RenderTexture
  _RenderTexture RenderTexture? make-RenderTexture

 ;; RenderTexture
 _RenderTexture RenderTexture? make-RenderTexture
 RenderTexture-id RenderTexture-tex-id RenderTexture-tex-width
 RenderTexture-tex-height RenderTexture-tex-mipmaps RenderTexture-tex-format
 RenderTexture-dep-id RenderTexture-dep-width
 RenderTexture-dep-height RenderTexture-dep-mipmaps RenderTexture-dep-format
 set-RenderTexture-id! set-RenderTexture-tex-id! set-RenderTexture-tex-width!
 set-RenderTexture-tex-height! set-RenderTexture-tex-mipmaps! set-RenderTexture-tex-format!
 set-RenderTexture-dep-id! set-RenderTexture-dep-width!
 set-RenderTexture-dep-height! set-RenderTexture-dep-mipmaps! set-RenderTexture-dep-format!
 ;; Shader
 _Shader Shader? make-Shader
 Shader-id Shader-locs
 set-Shader-id! set-Shader-locs!
)
