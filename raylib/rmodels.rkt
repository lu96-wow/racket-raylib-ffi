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

(provide
 draw-cube
 draw-cube-wires
 draw-plane
 draw-cube-v
 draw-cube-wires-v
 draw-sphere
 draw-ray
 get-ray-collision-box)

