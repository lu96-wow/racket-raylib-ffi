#lang racket/base

;; raylib models 模块 — 3D 形状/模型加载与绘制
;;
;; 对应 C: rmodels.c / raylib.h "Module: models"
;; 包括: DrawCube, DrawGrid, DrawPlane, DrawSphere,
;;       LoadModel, DrawModel 等

(require ffi/unsafe
         (prefix-in T: "types.rkt")
         (prefix-in C: "rcore.rkt"))

;; ============================================================
;; 3D 方块绘制 (core_3d_camera_mode.c)
;; DrawCube(Vector3 position, float width, float height, float length, Color color)
;; ============================================================

(define draw-cube
  (let ([f (get-ffi-obj "DrawCube" T:lib
             (_fun (pos : C:_vec3-bytes) _float _float _float (col : C:_color-bytes) -> _void))])
    (λ (position width height length color)
      (f (C:vec3->bytes position) width height length (C:color->bytes color)))))

;; ============================================================
;; 3D 方块线框绘制 (core_3d_camera_mode.c)
;; DrawCubeWires(Vector3 position, float width, float height, float length, Color color)
;; ============================================================

(define draw-cube-wires
  (let ([f (get-ffi-obj "DrawCubeWires" T:lib
             (_fun (pos : C:_vec3-bytes) _float _float _float (col : C:_color-bytes) -> _void))])
    (λ (position width height length color)
      (f (C:vec3->bytes position) width height length (C:color->bytes color)))))

;; ============================================================
;; 平面绘制 (core_3d_camera_first_person.c)
;; DrawPlane(Vector3 centerPos, Vector2 size, Color color)
;; ============================================================

(define draw-plane
  (let ([f (get-ffi-obj "DrawPlane" T:lib
             (_fun (pos : C:_vec3-bytes) (size : C:_vec2-bytes) (col : C:_color-bytes) -> _void))])
    (λ (center-pos size color)
      (f (C:vec3->bytes center-pos) (C:vec2->bytes size) (C:color->bytes color)))))

;; ============================================================
;; DrawCubeV(Vector3 position, Vector3 size, Color color)
;; 3D 方块绘制 (Vector 版, core_3d_camera_fps.c)
;; ============================================================

(define draw-cube-v
  (let ([f (get-ffi-obj "DrawCubeV" T:lib
             (_fun (pos : C:_vec3-bytes) (size : C:_vec3-bytes) (col : C:_color-bytes) -> _void))])
    (λ (position size color)
      (f (C:vec3->bytes position) (C:vec3->bytes size) (C:color->bytes color)))))

;; ============================================================
;; DrawCubeWiresV(Vector3 position, Vector3 size, Color color)
;; 3D 方块线框绘制 (Vector 版, core_3d_camera_fps.c)
;; ============================================================

(define draw-cube-wires-v
  (let ([f (get-ffi-obj "DrawCubeWiresV" T:lib
             (_fun (pos : C:_vec3-bytes) (size : C:_vec3-bytes) (col : C:_color-bytes) -> _void))])
    (λ (position size color)
      (f (C:vec3->bytes position) (C:vec3->bytes size) (C:color->bytes color)))))

;; ============================================================
;; DrawSphere(Vector3 centerPos, float radius, Color color)
;; 3D 球体绘制 (core_3d_camera_fps.c)
;; ============================================================

(define draw-sphere
  (let ([f (get-ffi-obj "DrawSphere" T:lib
             (_fun (pos : C:_vec3-bytes) _float (col : C:_color-bytes) -> _void))])
    (λ (center-pos radius color)
      (f (C:vec3->bytes center-pos) radius (C:color->bytes color)))))

;; ============================================================
;; DrawRay(Ray ray, Color color) — 绘制射线 (core_3d_picking.c)
;; ============================================================

(define draw-ray
  (let ([f (get-ffi-obj "DrawRay" T:lib
             (_fun (r : C:_ray-bytes) (col : C:_color-bytes) -> _void))])
    (λ (ray color)
      (f (C:ray->bytes ray) (C:color->bytes color)))))

;; ============================================================
;; GetRayCollisionBox(Ray ray, BoundingBox box) — 射线-盒碰撞 (core_3d_picking.c)
;; ============================================================

(define get-ray-collision-box
  (let ([f (get-ffi-obj "GetRayCollisionBox" T:lib
             (_fun (r : C:_ray-bytes) (bb : C:_bounding-box-bytes) -> (rc : C:_ray-collision-bytes)))])
    (λ (ray bounding-box)
      (f (C:ray->bytes ray) (C:bounding-box->bytes bounding-box)))))

;; ============================================================
;; 导出
;; ============================================================


;; ============================================================
;; Model 传值类型
;; Model struct (26 字段):
;;   Matrix transform      → 16 floats
;;   int meshCount, materialCount
;;   Mesh *meshes, Material *materials, int *meshMaterial
;;   int boneCount
;;   BoneInfo *bones, Transform *bindPose
;;   Transform *currentPose
;;   Matrix *boneMatrices
;; ============================================================

(define _model-bytes
  (_list-struct
    _float _float _float _float
    _float _float _float _float
    _float _float _float _float
    _float _float _float _float
    _int _int
    _pointer _pointer _pointer
    _int _pointer _pointer
    _pointer _pointer))

;; ============================================================
;; LoadModel(const char *fileName) -> Model
;; ============================================================

(define load-model
  (let ([f (get-ffi-obj "LoadModel" T:lib
             (_fun _string -> (m : _model-bytes)))])
    (lambda (filename) (f filename))))

;; ============================================================
;; UnloadModel(Model model) -> void
;; ============================================================

(define unload-model
  (let ([f (get-ffi-obj "UnloadModel" T:lib
             (_fun (m : _model-bytes) -> _void))])
    (lambda (model) (f model))))

;; ============================================================
;; DrawModelEx(Model model, Vector3 position, Vector3 rotationAxis,
;;             float rotationAngle, Vector3 scale, Color tint)
;; ============================================================

(define draw-model-ex
  (let ([f (get-ffi-obj "DrawModelEx" T:lib
             (_fun (m : _model-bytes)
                   (pos : C:_vec3-bytes)
                   (axis : C:_vec3-bytes) _float
                   (scale : C:_vec3-bytes)
                   (col : C:_color-bytes) -> _void))])
    (lambda (model position rotation-axis rotation-angle scale tint)
      (f model
         (C:vec3->bytes position)
         (C:vec3->bytes rotation-axis) rotation-angle
         (C:vec3->bytes scale)
         (C:color->bytes tint)))))


;; ============================================================
;; ModelAnimation 传值类型
;; ModelAnimation struct (35 字段):
;;   char name[32]    → 32 _ubyte
;;   int boneCount    → _int  (index 32)
;;   int keyframeCount → _int (index 33)
;;   Transform **keyframePoses → _pointer (index 34)
;; ============================================================

(define _model-animation-bytes
  (_list-struct
    _ubyte _ubyte _ubyte _ubyte
    _ubyte _ubyte _ubyte _ubyte
    _ubyte _ubyte _ubyte _ubyte
    _ubyte _ubyte _ubyte _ubyte
    _ubyte _ubyte _ubyte _ubyte
    _ubyte _ubyte _ubyte _ubyte
    _ubyte _ubyte _ubyte _ubyte
    _ubyte _ubyte _ubyte _ubyte
    _int _int _pointer))

;; ============================================================
;; LoadModelAnimations(const char *fileName, int *animCount)
;; -> ModelAnimation* (pointer to array)
;; ============================================================

(define load-model-animations
  (let ([f (get-ffi-obj "LoadModelAnimations" T:lib
             (_fun _string _pointer -> _pointer))])
    (lambda (filename)
      (let ([count-ptr (malloc _int 'atomic)])
        (ptr-set! count-ptr _int 0 0)
        (let ([anims-ptr (f filename count-ptr)])
          (values anims-ptr (ptr-ref count-ptr _int 0)))))))

;; ============================================================
;; UpdateModelAnimation(Model model, ModelAnimation anim, float frame)
;; ============================================================

(define update-model-animation
  (let ([f (get-ffi-obj "UpdateModelAnimation" T:lib
             (_fun (m : _model-bytes) (a : _model-animation-bytes) _float -> _void))])
    (lambda (model anim frame)
      (f model anim frame))))

;; ============================================================
;; UnloadModelAnimations(ModelAnimation *animations, int animCount)
;; ============================================================

(define unload-model-animations
  (let ([f (get-ffi-obj "UnloadModelAnimations" T:lib
             (_fun _pointer _int -> _void))])
    (lambda (anims-ptr count)
      (f anims-ptr count))))

;; ============================================================
;; 辅助: 从 ModelAnimation 指针中读取名称 (C char[32])
;; ============================================================

(define (model-animation-name anim-ptr)
  (let loop ([i 0] [chars '()])
    (if (>= i 32)
        (list->string (reverse chars))
        (let ([b (ptr-ref anim-ptr _ubyte i)])
          (if (zero? b)
              (list->string (reverse chars))
              (loop (add1 i) (cons (integer->char b) chars)))))))

(define (model-animation-keyframe-count anim-ptr)
  ;; name(32) + boneCount(4) = offset 36
  (ptr-ref anim-ptr _int 9))  ;; byte offset 32 (name) + 4 (boneCount) = element index 8? No...
(provide
 draw-cube
 draw-cube-wires
 draw-plane
 draw-cube-v
 draw-cube-wires-v
 draw-sphere
 draw-ray
 get-ray-collision-box
 _model-bytes
 load-model unload-model
 draw-model-ex
 _model-animation-bytes
 load-model-animations update-model-animation unload-model-animations
 model-animation-name model-animation-keyframe-count)

