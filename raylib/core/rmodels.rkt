#lang racket/base

;; core/rmodels.rkt — 3D模型/网格/碰撞函数绑定 (rmodels.h)

(require ffi/unsafe
         "ffi-helpers.rkt")

(define (matrix-identity)
  (list 1.0 0.0 0.0 0.0  0.0 1.0 0.0 0.0  0.0 0.0 1.0 0.0  0.0 0.0 0.0 1.0))
(define draw-cube
  (let ([f (get-ffi-obj "DrawCube" lib (_fun (pos : _vec3-bytes) _float _float _float (col : _color-bytes) -> _void))])
    (λ (p w h l c) (f (vec3->bytes p) w h l (color->bytes c)))))
(define draw-cube-wires
  (let ([f (get-ffi-obj "DrawCubeWires" lib (_fun (pos : _vec3-bytes) _float _float _float (col : _color-bytes) -> _void))])
    (λ (p w h l c) (f (vec3->bytes p) w h l (color->bytes c)))))
(define draw-cube-v
  (let ([f (get-ffi-obj "DrawCubeV" lib (_fun (pos : _vec3-bytes) (size : _vec3-bytes) (col : _color-bytes) -> _void))])
    (λ (p s c) (f (vec3->bytes p) (vec3->bytes s) (color->bytes c)))))
(define draw-cube-wires-v
  (let ([f (get-ffi-obj "DrawCubeWiresV" lib (_fun (pos : _vec3-bytes) (size : _vec3-bytes) (col : _color-bytes) -> _void))])
    (λ (p s c) (f (vec3->bytes p) (vec3->bytes s) (color->bytes c)))))
(define draw-plane
  (let ([f (get-ffi-obj "DrawPlane" lib (_fun (pos : _vec3-bytes) (size : _vec2-bytes) (col : _color-bytes) -> _void))])
    (λ (p s c) (f (vec3->bytes p) (vec2->bytes s) (color->bytes c)))))
(define draw-sphere
  (let ([f (get-ffi-obj "DrawSphere" lib (_fun (pos : _vec3-bytes) _float (col : _color-bytes) -> _void))])
    (λ (p r c) (f (vec3->bytes p) r (color->bytes c)))))
(define draw-sphere-ex
  (let ([f (get-ffi-obj "DrawSphereEx" lib (_fun (c : _vec3-bytes) _float _int _int (col : _color-bytes) -> _void))])
    (lambda (c r ri sl co) (f (vec3->bytes c) r ri sl (color->bytes co)))))
(define draw-sphere-wires
  (let ([f (get-ffi-obj "DrawSphereWires" lib (_fun (c : _vec3-bytes) _float _int _int (col : _color-bytes) -> _void))])
    (lambda (c r ri sl co) (f (vec3->bytes c) r ri sl (color->bytes co)))))
(define draw-cylinder
  (let ([f (get-ffi-obj "DrawCylinder" lib (_fun (pos : _vec3-bytes) _float _float _float _int (col : _color-bytes) -> _void))])
    (lambda (p rt rb h sl c) (f (vec3->bytes p) rt rb h sl (color->bytes c)))))
(define draw-cylinder-ex
  (let ([f (get-ffi-obj "DrawCylinderEx" lib (_fun (s : _vec3-bytes) (e : _vec3-bytes) _float _float _int (col : _color-bytes) -> _void))])
    (lambda (sp ep rs re sl c) (f (vec3->bytes sp) (vec3->bytes ep) rs re sl (color->bytes c)))))
(define draw-cylinder-wires
  (let ([f (get-ffi-obj "DrawCylinderWires" lib (_fun (pos : _vec3-bytes) _float _float _float _int (col : _color-bytes) -> _void))])
    (lambda (p rt rb h sl c) (f (vec3->bytes p) rt rb h sl (color->bytes c)))))
(define draw-cylinder-wires-ex
  (let ([f (get-ffi-obj "DrawCylinderWiresEx" lib (_fun (s : _vec3-bytes) (e : _vec3-bytes) _float _float _int (col : _color-bytes) -> _void))])
    (lambda (sp ep rs re sl c) (f (vec3->bytes sp) (vec3->bytes ep) rs re sl (color->bytes c)))))
(define draw-capsule
  (let ([f (get-ffi-obj "DrawCapsule" lib (_fun (s : _vec3-bytes) (e : _vec3-bytes) _float _int _int (col : _color-bytes) -> _void))])
    (lambda (sp ep r sl ri c) (f (vec3->bytes sp) (vec3->bytes ep) r sl ri (color->bytes c)))))
(define draw-capsule-wires
  (let ([f (get-ffi-obj "DrawCapsuleWires" lib (_fun (s : _vec3-bytes) (e : _vec3-bytes) _float _int _int (col : _color-bytes) -> _void))])
    (lambda (sp ep r sl ri c) (f (vec3->bytes sp) (vec3->bytes ep) r sl ri (color->bytes c)))))
(define draw-point-3d
  (let ([f (get-ffi-obj "DrawPoint3D" lib (_fun (pos : _vec3-bytes) (col : _color-bytes) -> _void))])
    (lambda (p c) (f (vec3->bytes p) (color->bytes c)))))
(define draw-circle-3d
  (let ([f (get-ffi-obj "DrawCircle3D" lib (_fun (c : _vec3-bytes) _float (rot : _vec3-bytes) _float (col : _color-bytes) -> _void))])
    (lambda (c r ra aa co) (f (vec3->bytes c) r (vec3->bytes ra) aa (color->bytes co)))))
(define draw-triangle-3d
  (let ([f (get-ffi-obj "DrawTriangle3D" lib (_fun (v1 : _vec3-bytes) (v2 : _vec3-bytes) (v3 : _vec3-bytes) (col : _color-bytes) -> _void))])
    (lambda (a b c co) (f (vec3->bytes a) (vec3->bytes b) (vec3->bytes c) (color->bytes co)))))
(define draw-triangle-strip-3d
  (let ([f (get-ffi-obj "DrawTriangleStrip3D" lib (_fun _pointer _int (col : _color-bytes) -> _void))])
    (lambda (pp pc c) (f pp pc (color->bytes c)))))
(define draw-ray
  (let ([f (get-ffi-obj "DrawRay" lib (_fun (r : _ray-bytes) (col : _color-bytes) -> _void))])
    (λ (r c) (f (ray->bytes r) (color->bytes c)))))
(define load-model
  (let ([f (get-ffi-obj "LoadModel" lib (_fun _string -> (m : _model-bytes)))])
    (lambda (fn) (f fn))))
(define load-model-from-mesh
  (let ([f (get-ffi-obj "LoadModelFromMesh" lib (_fun (m : _mesh-bytes) -> (ret : _model-bytes)))])
    (lambda (m) (f m))))
(define unload-model
  (let ([f (get-ffi-obj "UnloadModel" lib (_fun (m : _model-bytes) -> _void))])
    (lambda (m) (f m))))
(define is-model-valid
  (let ([f (get-ffi-obj "IsModelValid" lib (_fun (m : _model-bytes) -> _stdbool))])
    (lambda (m) (f m))))
(define get-model-bounding-box
  (let ([f (get-ffi-obj "GetModelBoundingBox" lib (_fun (m : _model-bytes) -> (bb : _bounding-box-bytes)))])
    (lambda (m) (f m))))
(define (set-model-mesh-material mp mi mti)
  ((get-ffi-obj "SetModelMeshMaterial" lib (_fun _pointer _int _int -> _void)) mp mi mti))
(define draw-model
  (let ([f (get-ffi-obj "DrawModel" lib (_fun (m : _model-bytes) (pos : _vec3-bytes) _float (c : _color-bytes) -> _void))])
    (lambda (m p s c) (f m (vec3->bytes p) s (color->bytes c)))))
(define draw-model-ex
  (let ([f (get-ffi-obj "DrawModelEx" lib (_fun (m : _model-bytes) (pos : _vec3-bytes) (axis : _vec3-bytes) _float (scale : _vec3-bytes) (col : _color-bytes) -> _void))])
    (lambda (m p a ra s c) (f m (vec3->bytes p) (vec3->bytes a) ra (vec3->bytes s) (color->bytes c)))))
(define draw-model-wires
  (let ([f (get-ffi-obj "DrawModelWires" lib (_fun (m : _model-bytes) (pos : _vec3-bytes) _float (c : _color-bytes) -> _void))])
    (lambda (m p s c) (f m (vec3->bytes p) s (color->bytes c)))))
(define draw-model-wires-ex
  (let ([f (get-ffi-obj "DrawModelWiresEx" lib (_fun (m : _model-bytes) (pos : _vec3-bytes) _float _float (c : _color-bytes) -> _void))])
    (lambda (m p s ww c) (f m (vec3->bytes p) s ww (color->bytes c)))))
(define draw-bounding-box
  (let ([f (get-ffi-obj "DrawBoundingBox" lib (_fun (bb : _bounding-box-bytes) (c : _color-bytes) -> _void))])
    (lambda (b c) (f (bounding-box->bytes b) (color->bytes c)))))
(define draw-billboard
  (let ([f (get-ffi-obj "DrawBillboard" lib (_fun (c : _camera3d-bytes) (t : _texture-bytes) (pos : _vec3-bytes) _float (col : _color-bytes) -> _void))])
    (lambda (cam t p s c) (f (camera3d->bytes cam) t (vec3->bytes p) s (color->bytes c)))))
(define draw-billboard-rec
  (let ([f (get-ffi-obj "DrawBillboardRec" lib (_fun (c : _camera3d-bytes) (t : _texture-bytes) (src : _rect-bytes) (pos : _vec3-bytes) (size : _vec2-bytes) (col : _color-bytes) -> _void))])
    (lambda (cam t src p s c) (f (camera3d->bytes cam) t (rect->bytes src) (vec3->bytes p) (vec2->bytes s) (color->bytes c)))))
(define draw-billboard-pro
  (let ([f (get-ffi-obj "DrawBillboardPro" lib (_fun (c : _camera3d-bytes) (t : _texture-bytes) (src : _rect-bytes) (pos : _vec3-bytes) (up : _vec3-bytes) (size : _vec2-bytes) (orig : _vec2-bytes) _float (col : _color-bytes) -> _void))])
    (lambda (cam t src p up s o rot c) (f (camera3d->bytes cam) t (rect->bytes src) (vec3->bytes p) (vec3->bytes up) (vec2->bytes s) (vec2->bytes o) rot (color->bytes c)))))
(define load-model-animations
  (let ([f (get-ffi-obj "LoadModelAnimations" lib (_fun _string _pointer -> _pointer))])
    (lambda (fn) (let ([cp (malloc _int 'atomic)]) (ptr-set! cp _int 0 0) (let ([ap (f fn cp)]) (values ap (ptr-ref cp _int 0)))))))
(define update-model-animation
  (let ([f (get-ffi-obj "UpdateModelAnimation" lib (_fun (m : _model-bytes) (a : _model-animation-bytes) _float -> _void))])
    (lambda (m a fr) (f m a fr))))
(define unload-model-animations
  (let ([f (get-ffi-obj "UnloadModelAnimations" lib (_fun _pointer _int -> _void))])
    (lambda (ap c) (f ap c))))
(define (update-model-animation-ex m a ai fr)
  ((get-ffi-obj "UpdateModelAnimationEx" lib (_fun _pointer _pointer _int _int -> _void)) m a ai fr))
(define (is-model-animation-valid mp ap)
  ((get-ffi-obj "IsModelAnimationValid" lib (_fun _pointer _pointer -> _stdbool)) mp ap))
(define (model-animation-name ap)
  (let loop ([i 0] [cs '()])
    (if (>= i 32) (list->string (reverse cs)) (let ([b (ptr-ref ap _ubyte i)]) (if (zero? b) (list->string (reverse cs)) (loop (add1 i) (cons (integer->char b) cs)))))))
(define (model-animation-keyframe-count ap) (ptr-ref ap _int 9))
(define (upload-mesh mp d?) ((get-ffi-obj "UploadMesh" lib (_fun _pointer _stdbool -> _void)) mp d?))
(define (update-mesh-buffer mp i dp ds o) ((get-ffi-obj "UpdateMeshBuffer" lib (_fun _pointer _int _pointer _int _int -> _void)) mp i dp ds o))
(define (unload-mesh mp) ((get-ffi-obj "UnloadMesh" lib (_fun _pointer -> _void)) mp))
(define draw-mesh
  (let ([f (get-ffi-obj "DrawMesh" lib (_fun (m : _mesh-bytes) (mat : _material-bytes) (tr : _matrix-bytes) -> _void))])
    (lambda (m ma tr) (f m ma tr))))
(define draw-mesh-instanced
  (let ([f (get-ffi-obj "DrawMeshInstanced" lib (_fun (m : _mesh-bytes) (mat : _material-bytes) _pointer _int -> _void))])
    (lambda (m ma tr i) (f m ma tr i))))
(define (export-mesh mp fn) ((get-ffi-obj "ExportMesh" lib (_fun _pointer _string -> _stdbool)) mp fn))
(define (export-mesh-as-code mp fn) ((get-ffi-obj "ExportMeshAsCode" lib (_fun _pointer _string -> _stdbool)) mp fn))
(define (gen-mesh-tangents mp) ((get-ffi-obj "GenMeshTangents" lib (_fun _pointer -> _void)) mp))
(define get-mesh-bounding-box
  (let ([f (get-ffi-obj "GetMeshBoundingBox" lib (_fun (m : _mesh-bytes) -> (bb : _bounding-box-bytes)))])
    (lambda (ml) (f ml))))
(define (mesh-ptr->list p) (list (ptr-ref p _int 0) (ptr-ref p _int 1) (ptr-ref p _pointer 1) (ptr-ref p _pointer 2) (ptr-ref p _pointer 3) (ptr-ref p _pointer 4) (ptr-ref p _pointer 5) (ptr-ref p _pointer 6) (ptr-ref p _pointer 7) (ptr-ref p _int 16) 0 (ptr-ref p _pointer 9) (ptr-ref p _pointer 10) (ptr-ref p _pointer 11) (ptr-ref p _pointer 12) (ptr-ref p _uint 26) 0 (ptr-ref p _pointer 14)))
(define (material-ptr->list p) (list (ptr-ref p _uint 0) 0 (ptr-ref p _pointer 1) (ptr-ref p _pointer 2) (ptr-ref p _float 6) (ptr-ref p _float 7) (ptr-ref p _float 8) (ptr-ref p _float 9)))
(define gen-mesh-poly (let ([f (get-ffi-obj "GenMeshPoly" lib (_fun _int _float -> (m : _mesh-bytes)))]) (lambda (s r) (f s r))))
(define gen-mesh-plane (let ([f (get-ffi-obj "GenMeshPlane" lib (_fun _float _float _int _int -> (m : _mesh-bytes)))]) (lambda (w l rx rz) (f w l rx rz))))
(define gen-mesh-cube (let ([f (get-ffi-obj "GenMeshCube" lib (_fun _float _float _float -> (m : _mesh-bytes)))]) (lambda (w h l) (f w h l))))
(define gen-mesh-sphere (let ([f (get-ffi-obj "GenMeshSphere" lib (_fun _float _int _int -> (m : _mesh-bytes)))]) (lambda (r ri sl) (f r ri sl))))
(define gen-mesh-hemi-sphere (let ([f (get-ffi-obj "GenMeshHemiSphere" lib (_fun _float _int _int -> (m : _mesh-bytes)))]) (lambda (r ri sl) (f r ri sl))))
(define gen-mesh-cylinder (let ([f (get-ffi-obj "GenMeshCylinder" lib (_fun _float _float _int -> (m : _mesh-bytes)))]) (lambda (r h sl) (f r h sl))))
(define gen-mesh-cone (let ([f (get-ffi-obj "GenMeshCone" lib (_fun _float _float _int -> (m : _mesh-bytes)))]) (lambda (r h sl) (f r h sl))))
(define gen-mesh-torus (let ([f (get-ffi-obj "GenMeshTorus" lib (_fun _float _float _int _int -> (m : _mesh-bytes)))]) (lambda (r s rs si) (f r s rs si))))
(define gen-mesh-knot (let ([f (get-ffi-obj "GenMeshKnot" lib (_fun _float _float _int _int -> (m : _mesh-bytes)))]) (lambda (r s rs si) (f r s rs si))))
(define gen-mesh-heightmap (let ([f (get-ffi-obj "GenMeshHeightmap" lib (_fun (img : _image-bytes) (size : _vec3-bytes) -> (m : _mesh-bytes)))]) (lambda (img s) (f img (vec3->bytes s)))))
(define gen-mesh-cubicmap (let ([f (get-ffi-obj "GenMeshCubicmap" lib (_fun (img : _image-bytes) (size : _vec3-bytes) -> (m : _mesh-bytes)))]) (lambda (img s) (f img (vec3->bytes s)))))
(define load-materials (let ([f (get-ffi-obj "LoadMaterials" lib (_fun _string _pointer -> _pointer))]) (lambda (fn) (let ([cb (malloc _int 1 'atomic)]) (let ([r (f fn cb)]) (values r (ptr-ref cb _int 0)))))))
(define load-material-default
  (let ([f (get-ffi-obj "LoadMaterialDefault" lib (_fun -> _material-bytes))])
    (lambda () (define lst (f)) (define p (malloc 40 'atomic)) (ptr-set! p _uint 0 (list-ref lst 0)) (ptr-set! p _int 1 (list-ref lst 1)) (ptr-set! p _pointer 1 (list-ref lst 2)) (ptr-set! p _pointer 2 (list-ref lst 3)) (ptr-set! p _float 6 (list-ref lst 4)) (ptr-set! p _float 7 (list-ref lst 5)) (ptr-set! p _float 8 (list-ref lst 6)) (ptr-set! p _float 9 (list-ref lst 7)) p)))
(define (is-material-valid mp) ((get-ffi-obj "IsMaterialValid" lib (_fun _pointer -> _stdbool)) mp))
(define (unload-material mp) ((get-ffi-obj "UnloadMaterial" lib (_fun _pointer -> _void)) mp))
(define check-collision-spheres (let ([f (get-ffi-obj "CheckCollisionSpheres" lib (_fun (c1 : _vec3-bytes) _float (c2 : _vec3-bytes) _float -> _stdbool))]) (lambda (c1 r1 c2 r2) (f (vec3->bytes c1) r1 (vec3->bytes c2) r2))))
(define check-collision-boxes (let ([f (get-ffi-obj "CheckCollisionBoxes" lib (_fun (b1 : _bounding-box-bytes) (b2 : _bounding-box-bytes) -> _stdbool))]) (lambda (b1 b2) (f (bounding-box->bytes b1) (bounding-box->bytes b2)))))
(define check-collision-box-sphere (let ([f (get-ffi-obj "CheckCollisionBoxSphere" lib (_fun (box : _bounding-box-bytes) (c : _vec3-bytes) _float -> _stdbool))]) (lambda (b c r) (f (bounding-box->bytes b) (vec3->bytes c) r))))
(define get-ray-collision-sphere (let ([f (get-ffi-obj "GetRayCollisionSphere" lib (_fun (r : _ray-bytes) (c : _vec3-bytes) _float -> (rc : _ray-collision-bytes)))]) (lambda (r c rd) (f (ray->bytes r) (vec3->bytes c) rd))))
(define get-ray-collision-box (let ([f (get-ffi-obj "GetRayCollisionBox" lib (_fun (r : _ray-bytes) (bb : _bounding-box-bytes) -> (rc : _ray-collision-bytes)))]) (λ (r bb) (f (ray->bytes r) (bounding-box->bytes bb)))))
(define get-ray-collision-mesh (let ([f (get-ffi-obj "GetRayCollisionMesh" lib (_fun (r : _ray-bytes) _pointer (tr : _matrix-bytes) -> (rc : _ray-collision-bytes)))]) (lambda (r mp tr) (f (ray->bytes r) mp tr))))
(define get-ray-collision-triangle (let ([f (get-ffi-obj "GetRayCollisionTriangle" lib (_fun (r : _ray-bytes) (v1 : _vec3-bytes) (v2 : _vec3-bytes) (v3 : _vec3-bytes) -> (rc : _ray-collision-bytes)))]) (lambda (r a b c) (f (ray->bytes r) (vec3->bytes a) (vec3->bytes b) (vec3->bytes c)))))
(define get-ray-collision-quad (let ([f (get-ffi-obj "GetRayCollisionQuad" lib (_fun (r : _ray-bytes) (v1 : _vec3-bytes) (v2 : _vec3-bytes) (v3 : _vec3-bytes) (v4 : _vec3-bytes) -> (rc : _ray-collision-bytes)))]) (lambda (r a b c d) (f (ray->bytes r) (vec3->bytes a) (vec3->bytes b) (vec3->bytes c) (vec3->bytes d)))))

(provide matrix-identity
 draw-cube draw-cube-wires draw-cube-v draw-cube-wires-v draw-plane
 draw-sphere draw-sphere-ex draw-sphere-wires draw-cylinder draw-cylinder-ex
 draw-cylinder-wires draw-cylinder-wires-ex draw-capsule draw-capsule-wires
 draw-point-3d draw-circle-3d draw-triangle-3d draw-triangle-strip-3d draw-ray
 load-model load-model-from-mesh unload-model is-model-valid
 get-model-bounding-box set-model-mesh-material
 draw-model draw-model-ex draw-model-wires draw-model-wires-ex
 draw-bounding-box draw-billboard draw-billboard-rec draw-billboard-pro
 load-model-animations update-model-animation unload-model-animations
 update-model-animation-ex is-model-animation-valid
 model-animation-name model-animation-keyframe-count
 upload-mesh update-mesh-buffer unload-mesh draw-mesh draw-mesh-instanced
 mesh-ptr->list material-ptr->list export-mesh export-mesh-as-code
 gen-mesh-tangents get-mesh-bounding-box
 gen-mesh-poly gen-mesh-plane gen-mesh-cube gen-mesh-sphere gen-mesh-hemi-sphere
 gen-mesh-cylinder gen-mesh-cone gen-mesh-torus gen-mesh-knot
 gen-mesh-heightmap gen-mesh-cubicmap
 load-materials load-material-default is-material-valid unload-material
 check-collision-spheres check-collision-boxes check-collision-box-sphere
 get-ray-collision-sphere get-ray-collision-box
 get-ray-collision-mesh get-ray-collision-triangle get-ray-collision-quad)
