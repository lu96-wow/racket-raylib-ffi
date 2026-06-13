#lang racket/base

;; raylib models 模块 — 3D 形状/模型加载与绘制
;;
;; 对应 C: rmodels.c / raylib.h "Module: models"
;; 包括: DrawCube, DrawGrid, DrawPlane, DrawSphere,
;;       LoadModel, DrawModel 等

(require ffi/unsafe
         (prefix-in T: "types.rkt")
         (prefix-in C: "rcore.rkt")
         (prefix-in TX: "rtextures.rkt"))

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

;; Mesh (raylib.h:346) — ~112 字节，用于 GenMesh* / LoadModelFromMesh 的传值 ABI
(define _mesh-bytes
  (_list-struct
    _int _int           ; vertexCount, triangleCount
    _pointer _pointer _pointer       ; vertices, texcoords, texcoords2
    _pointer _pointer _pointer _pointer  ; normals, tangents, colors, indices
    _int                ; boneCount
    _pointer _pointer   ; boneIndices, boneWeights
    _pointer _pointer   ; animVertices, animNormals
    _uint               ; vaoId
    _pointer))          ; vboId

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
;; ============================================================
;; 3D 基本形状绘制
;; ============================================================

(define draw-point-3d
  (let ([f (get-ffi-obj "DrawPoint3D" T:lib
             (_fun (pos : C:_vec3-bytes) (col : C:_color-bytes) -> _void))])
    (lambda (position color)
      (f (C:vec3->bytes position) (C:color->bytes color)))))

(define draw-circle-3d
  (let ([f (get-ffi-obj "DrawCircle3D" T:lib
             (_fun (c : C:_vec3-bytes) _float (rot : C:_vec3-bytes) _float (col : C:_color-bytes) -> _void))])
    (lambda (center radius rotation-axis rotation-angle color)
      (f (C:vec3->bytes center) radius (C:vec3->bytes rotation-axis) rotation-angle (C:color->bytes color)))))

(define draw-triangle-3d
  (let ([f (get-ffi-obj "DrawTriangle3D" T:lib
             (_fun (v1 : C:_vec3-bytes) (v2 : C:_vec3-bytes) (v3 : C:_vec3-bytes) (col : C:_color-bytes) -> _void))])
    (lambda (v1 v2 v3 color)
      (f (C:vec3->bytes v1) (C:vec3->bytes v2) (C:vec3->bytes v3) (C:color->bytes color)))))

(define draw-triangle-strip-3d
  (let ([f (get-ffi-obj "DrawTriangleStrip3D" T:lib
             (_fun _pointer _int (col : C:_color-bytes) -> _void))])
    (lambda (points-ptr point-count color)
      (f points-ptr point-count (C:color->bytes color)))))

;; ============================================================
;; 球体/圆柱/胶囊 绘制
;; ============================================================

(define draw-sphere-ex
  (let ([f (get-ffi-obj "DrawSphereEx" T:lib
             (_fun (c : C:_vec3-bytes) _float _int _int (col : C:_color-bytes) -> _void))])
    (lambda (center radius rings slices color)
      (f (C:vec3->bytes center) radius rings slices (C:color->bytes color)))))

(define draw-sphere-wires
  (let ([f (get-ffi-obj "DrawSphereWires" T:lib
             (_fun (c : C:_vec3-bytes) _float _int _int (col : C:_color-bytes) -> _void))])
    (lambda (center radius rings slices color)
      (f (C:vec3->bytes center) radius rings slices (C:color->bytes color)))))

(define draw-cylinder
  (let ([f (get-ffi-obj "DrawCylinder" T:lib
             (_fun (pos : C:_vec3-bytes) _float _float _float _int (col : C:_color-bytes) -> _void))])
    (lambda (position radius-top radius-bottom height slices color)
      (f (C:vec3->bytes position) radius-top radius-bottom height slices (C:color->bytes color)))))

(define draw-cylinder-ex
  (let ([f (get-ffi-obj "DrawCylinderEx" T:lib
             (_fun (s : C:_vec3-bytes) (e : C:_vec3-bytes) _float _float _int (col : C:_color-bytes) -> _void))])
    (lambda (start-pos end-pos radius-start radius-end slices color)
      (f (C:vec3->bytes start-pos) (C:vec3->bytes end-pos) radius-start radius-end slices (C:color->bytes color)))))

(define draw-cylinder-wires
  (let ([f (get-ffi-obj "DrawCylinderWires" T:lib
             (_fun (pos : C:_vec3-bytes) _float _float _float _int (col : C:_color-bytes) -> _void))])
    (lambda (position radius-top radius-bottom height slices color)
      (f (C:vec3->bytes position) radius-top radius-bottom height slices (C:color->bytes color)))))

(define draw-cylinder-wires-ex
  (let ([f (get-ffi-obj "DrawCylinderWiresEx" T:lib
             (_fun (s : C:_vec3-bytes) (e : C:_vec3-bytes) _float _float _int (col : C:_color-bytes) -> _void))])
    (lambda (start-pos end-pos radius-start radius-end slices color)
      (f (C:vec3->bytes start-pos) (C:vec3->bytes end-pos) radius-start radius-end slices (C:color->bytes color)))))

(define draw-capsule
  (let ([f (get-ffi-obj "DrawCapsule" T:lib
             (_fun (s : C:_vec3-bytes) (e : C:_vec3-bytes) _float _int _int (col : C:_color-bytes) -> _void))])
    (lambda (start-pos end-pos radius slices rings color)
      (f (C:vec3->bytes start-pos) (C:vec3->bytes end-pos) radius slices rings (C:color->bytes color)))))

(define draw-capsule-wires
  (let ([f (get-ffi-obj "DrawCapsuleWires" T:lib
             (_fun (s : C:_vec3-bytes) (e : C:_vec3-bytes) _float _int _int (col : C:_color-bytes) -> _void))])
    (lambda (start-pos end-pos radius slices rings color)
      (f (C:vec3->bytes start-pos) (C:vec3->bytes end-pos) radius slices rings (C:color->bytes color)))))
;; ============================================================
;; 模型加载/操作
;; ============================================================

(define load-model-from-mesh
  (let ([f (get-ffi-obj "LoadModelFromMesh" T:lib
             (_fun (m : _mesh-bytes) -> (ret : _model-bytes)))])
    (lambda (mesh) (f mesh))))

(define is-model-valid
  (let ([f (get-ffi-obj "IsModelValid" T:lib
             (_fun (m : _model-bytes) -> _stdbool))])
    (lambda (model) (f model))))

(define get-model-bounding-box
  (let ([f (get-ffi-obj "GetModelBoundingBox" T:lib
             (_fun (m : _model-bytes) -> (bb : C:_bounding-box-bytes)))])
    (lambda (model) (f model))))

(define (set-model-mesh-material model-ptr mesh-index material-index)
  ((get-ffi-obj "SetModelMeshMaterial" T:lib (_fun _pointer _int _int -> _void))
   model-ptr mesh-index material-index))

;; ============================================================
;; DrawModel 变体
;; ============================================================

(define draw-model
  (let ([f (get-ffi-obj "DrawModel" T:lib
             (_fun (m : _model-bytes) (pos : C:_vec3-bytes) _float (c : C:_color-bytes) -> _void))])
    (lambda (model position scale tint)
      (f model (C:vec3->bytes position) scale (C:color->bytes tint)))))

(define draw-model-wires
  (let ([f (get-ffi-obj "DrawModelWires" T:lib
             (_fun (m : _model-bytes) (pos : C:_vec3-bytes) _float (c : C:_color-bytes) -> _void))])
    (lambda (model position scale tint)
      (f model (C:vec3->bytes position) scale (C:color->bytes tint)))))

(define draw-model-wires-ex
  (let ([f (get-ffi-obj "DrawModelWiresEx" T:lib
             (_fun (m : _model-bytes) (pos : C:_vec3-bytes) _float _float (c : C:_color-bytes) -> _void))])
    (lambda (model position scale wire-width tint)
      (f model (C:vec3->bytes position) scale wire-width (C:color->bytes tint)))))

(define draw-bounding-box
  (let ([f (get-ffi-obj "DrawBoundingBox" T:lib
             (_fun (bb : C:_bounding-box-bytes) (c : C:_color-bytes) -> _void))])
    (lambda (box color)
      (f (C:bounding-box->bytes box) (C:color->bytes color)))))

(define draw-billboard
  (let ([f (get-ffi-obj "DrawBillboard" T:lib
             (_fun (c : C:_camera3d-bytes) (t : TX:_texture-bytes)
                   (pos : C:_vec3-bytes) _float (col : C:_color-bytes) -> _void))])
    (lambda (camera texture position size tint)
      (f (C:camera3d->bytes camera) texture (C:vec3->bytes position) size (C:color->bytes tint)))))

(define draw-billboard-rec
  (let ([f (get-ffi-obj "DrawBillboardRec" T:lib
             (_fun (c : C:_camera3d-bytes) (t : TX:_texture-bytes)
                   (src : C:_rect-bytes) (pos : C:_vec3-bytes) (size : C:_vec2-bytes) (col : C:_color-bytes) -> _void))])
    (lambda (camera texture source position size tint)
      (f (C:camera3d->bytes camera) texture (C:rect->bytes source)
         (C:vec3->bytes position) (C:vec2->bytes size) (C:color->bytes tint)))))

(define draw-billboard-pro
  (let ([f (get-ffi-obj "DrawBillboardPro" T:lib
             (_fun (c : C:_camera3d-bytes) (t : TX:_texture-bytes)
                   (src : C:_rect-bytes) (pos : C:_vec3-bytes) (up : C:_vec3-bytes)
                   (size : C:_vec2-bytes) (orig : C:_vec2-bytes) _float (col : C:_color-bytes) -> _void))])
    (lambda (camera texture source position up size origin rotation tint)
      (f (C:camera3d->bytes camera) texture (C:rect->bytes source)
         (C:vec3->bytes position) (C:vec3->bytes up)
         (C:vec2->bytes size) (C:vec2->bytes origin) rotation (C:color->bytes tint)))))

;; ============================================================
;; 网格加载/操作
;; ============================================================

(define (upload-mesh mesh-ptr dynamic?)
  ((get-ffi-obj "UploadMesh" T:lib (_fun _pointer _stdbool -> _void)) mesh-ptr dynamic?))

(define (update-mesh-buffer mesh-ptr index data-ptr data-size offset)
  ((get-ffi-obj "UpdateMeshBuffer" T:lib (_fun _pointer _int _pointer _int _int -> _void))
   mesh-ptr index data-ptr data-size offset))

(define (unload-mesh mesh-ptr)
  ((get-ffi-obj "UnloadMesh" T:lib (_fun _pointer -> _void)) mesh-ptr))

(define (draw-mesh mesh-ptr material-ptr transform-matrix-ptr)
  ((get-ffi-obj "DrawMesh" T:lib (_fun _pointer _pointer _pointer -> _void))
   mesh-ptr material-ptr transform-matrix-ptr))

(define (draw-mesh-instanced mesh-ptr material-ptr transforms-ptr instances)
  ((get-ffi-obj "DrawMeshInstanced" T:lib (_fun _pointer _pointer _pointer _int -> _void))
   mesh-ptr material-ptr transforms-ptr instances))

(define (export-mesh mesh-ptr file-name)
  ((get-ffi-obj "ExportMesh" T:lib (_fun _pointer _string -> _stdbool))
   mesh-ptr file-name))

(define (export-mesh-as-code mesh-ptr file-name)
  ((get-ffi-obj "ExportMeshAsCode" T:lib (_fun _pointer _string -> _stdbool))
   mesh-ptr file-name))

(define (gen-mesh-tangents mesh-ptr)
  ((get-ffi-obj "GenMeshTangents" T:lib (_fun _pointer -> _void)) mesh-ptr))

(define get-mesh-bounding-box
  (let ([f (get-ffi-obj "GetMeshBoundingBox" T:lib
             (_fun (m : _mesh-bytes) -> (bb : C:_bounding-box-bytes)))])
    (lambda (mesh-lst) (f mesh-lst))))

;; ============================================================
;; GenMesh* — 生成网格
;; ============================================================

(define gen-mesh-poly
  (let ([f (get-ffi-obj "GenMeshPoly" T:lib (_fun _int _float -> (m : _mesh-bytes)))])
    (lambda (sides radius) (f sides radius))))

(define gen-mesh-plane
  (let ([f (get-ffi-obj "GenMeshPlane" T:lib (_fun _float _float _int _int -> (m : _mesh-bytes)))])
    (lambda (width length res-x res-z) (f width length res-x res-z))))

(define gen-mesh-cube
  (let ([f (get-ffi-obj "GenMeshCube" T:lib (_fun _float _float _float -> (m : _mesh-bytes)))])
    (lambda (width height length) (f width height length))))

(define gen-mesh-sphere
  (let ([f (get-ffi-obj "GenMeshSphere" T:lib (_fun _float _int _int -> (m : _mesh-bytes)))])
    (lambda (radius rings slices) (f radius rings slices))))

(define gen-mesh-hemi-sphere
  (let ([f (get-ffi-obj "GenMeshHemiSphere" T:lib (_fun _float _int _int -> (m : _mesh-bytes)))])
    (lambda (radius rings slices) (f radius rings slices))))

(define gen-mesh-cylinder
  (let ([f (get-ffi-obj "GenMeshCylinder" T:lib (_fun _float _float _int -> (m : _mesh-bytes)))])
    (lambda (radius height slices) (f radius height slices))))

(define gen-mesh-cone
  (let ([f (get-ffi-obj "GenMeshCone" T:lib (_fun _float _float _int -> (m : _mesh-bytes)))])
    (lambda (radius height slices) (f radius height slices))))

(define gen-mesh-torus
  (let ([f (get-ffi-obj "GenMeshTorus" T:lib (_fun _float _float _int _int -> (m : _mesh-bytes)))])
    (lambda (radius size rad-seg sides) (f radius size rad-seg sides))))

(define gen-mesh-knot
  (let ([f (get-ffi-obj "GenMeshKnot" T:lib (_fun _float _float _int _int -> (m : _mesh-bytes)))])
    (lambda (radius size rad-seg sides) (f radius size rad-seg sides))))

(define gen-mesh-heightmap
  (let ([f (get-ffi-obj "GenMeshHeightmap" T:lib (_fun (img : C:_image-bytes) (size : C:_vec3-bytes) -> (m : _mesh-bytes)))])
    (lambda (image size) (f image (C:vec3->bytes size)))))

(define gen-mesh-cubicmap
  (let ([f (get-ffi-obj "GenMeshCubicmap" T:lib (_fun (img : C:_image-bytes) (size : C:_vec3-bytes) -> (m : _mesh-bytes)))])
    (lambda (image size) (f image (C:vec3->bytes size)))))

;; ============================================================
;; 材质加载
;; ============================================================

(define load-materials
  (let ([f (get-ffi-obj "LoadMaterials" T:lib (_fun _string _pointer -> _pointer))])
    (lambda (file-name)
      (let ([count-buf (malloc _int 1 'atomic)])
        (let ([result (f file-name count-buf)])
          (values result (ptr-ref count-buf _int 0)))))))

(define load-material-default
  (get-ffi-obj "LoadMaterialDefault" T:lib (_fun -> _pointer)))

(define (is-material-valid material-ptr)
  ((get-ffi-obj "IsMaterialValid" T:lib (_fun _pointer -> _stdbool)) material-ptr))

(define (unload-material material-ptr)
  ((get-ffi-obj "UnloadMaterial" T:lib (_fun _pointer -> _void)) material-ptr))

(define (update-model-animation-ex model animation anim-index frame)
  ((get-ffi-obj "UpdateModelAnimationEx" T:lib (_fun _pointer _pointer _int _int -> _void))
   model animation anim-index frame))

(define (is-model-animation-valid model-ptr anim-ptr)
  ((get-ffi-obj "IsModelAnimationValid" T:lib (_fun _pointer _pointer -> _stdbool))
   model-ptr anim-ptr))
;; ============================================================
;; 碰撞检测
;; ============================================================

(define check-collision-spheres
  (let ([f (get-ffi-obj "CheckCollisionSpheres" T:lib
             (_fun (c1 : C:_vec3-bytes) _float (c2 : C:_vec3-bytes) _float -> _stdbool))])
    (lambda (center1 radius1 center2 radius2)
      (f (C:vec3->bytes center1) radius1 (C:vec3->bytes center2) radius2))))

(define check-collision-boxes
  (let ([f (get-ffi-obj "CheckCollisionBoxes" T:lib
             (_fun (b1 : C:_bounding-box-bytes) (b2 : C:_bounding-box-bytes) -> _stdbool))])
    (lambda (box1 box2)
      (f (C:bounding-box->bytes box1) (C:bounding-box->bytes box2)))))

(define check-collision-box-sphere
  (let ([f (get-ffi-obj "CheckCollisionBoxSphere" T:lib
             (_fun (box : C:_bounding-box-bytes) (c : C:_vec3-bytes) _float -> _stdbool))])
    (lambda (box center radius)
      (f (C:bounding-box->bytes box) (C:vec3->bytes center) radius))))

(define get-ray-collision-sphere
  (let ([f (get-ffi-obj "GetRayCollisionSphere" T:lib
             (_fun (r : C:_ray-bytes) (c : C:_vec3-bytes) _float -> (rc : C:_ray-collision-bytes)))])
    (lambda (ray center radius)
      (f (C:ray->bytes ray) (C:vec3->bytes center) radius))))

(define get-ray-collision-mesh
  (let ([f (get-ffi-obj "GetRayCollisionMesh" T:lib
             (_fun (r : C:_ray-bytes) _pointer (tr : C:_matrix-bytes) -> (rc : C:_ray-collision-bytes)))])
    (lambda (ray mesh-ptr transform)
      (f (C:ray->bytes ray) mesh-ptr transform))))

(define get-ray-collision-triangle
  (let ([f (get-ffi-obj "GetRayCollisionTriangle" T:lib
             (_fun (r : C:_ray-bytes) (v1 : C:_vec3-bytes) (v2 : C:_vec3-bytes) (v3 : C:_vec3-bytes) -> (rc : C:_ray-collision-bytes)))])
    (lambda (ray v1 v2 v3)
      (f (C:ray->bytes ray) (C:vec3->bytes v1) (C:vec3->bytes v2) (C:vec3->bytes v3)))))

(define get-ray-collision-quad
  (let ([f (get-ffi-obj "GetRayCollisionQuad" T:lib
             (_fun (r : C:_ray-bytes) (v1 : C:_vec3-bytes) (v2 : C:_vec3-bytes) (v3 : C:_vec3-bytes) (v4 : C:_vec3-bytes) -> (rc : C:_ray-collision-bytes)))])
    (lambda (ray v1 v2 v3 v4)
      (f (C:ray->bytes ray) (C:vec3->bytes v1) (C:vec3->bytes v2) (C:vec3->bytes v3) (C:vec3->bytes v4)))))

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
 _mesh-bytes
 load-model
 unload-model
 draw-model-ex
 _model-animation-bytes
 load-model-animations
 update-model-animation
 unload-model-animations
 model-animation-name
 model-animation-keyframe-count
 draw-point-3d
 draw-circle-3d
 draw-triangle-3d
 draw-triangle-strip-3d
 draw-sphere-ex
 draw-sphere-wires
 draw-cylinder
 draw-cylinder-ex
 draw-cylinder-wires
 draw-cylinder-wires-ex
 draw-capsule
 draw-capsule-wires
 load-model-from-mesh
 is-model-valid
 get-model-bounding-box
 set-model-mesh-material
 draw-model
 draw-model-wires
 draw-model-wires-ex
 draw-bounding-box
 draw-billboard
 draw-billboard-rec
 draw-billboard-pro
 upload-mesh
 update-mesh-buffer
 unload-mesh
 draw-mesh
 draw-mesh-instanced
 export-mesh
 export-mesh-as-code
 gen-mesh-tangents
 get-mesh-bounding-box
 gen-mesh-poly
 gen-mesh-plane
 gen-mesh-cube
 gen-mesh-sphere
 gen-mesh-hemi-sphere
 gen-mesh-cylinder
 gen-mesh-cone
 gen-mesh-torus
 gen-mesh-knot
 gen-mesh-heightmap
 gen-mesh-cubicmap
 load-materials
 load-material-default
 is-material-valid
 unload-material
 update-model-animation-ex
 is-model-animation-valid
 check-collision-spheres
 check-collision-boxes
 check-collision-box-sphere
 get-ray-collision-sphere
 get-ray-collision-mesh
 get-ray-collision-triangle
 get-ray-collision-quad
)
