#lang racket/base

;; raylib models 模块 — 3D 形状/模型加载与绘制
;;
;; 对应 C: rmodels.c / raylib.h "Module: models"
;; 包括: DrawCube, DrawGrid, DrawPlane, DrawSphere,
;;       LoadModel, DrawModel 等

(require (except-in ffi/unsafe _bool)
         (prefix-in T: "types.rkt")
         (prefix-in C: "rcore.rkt")
         (only-in "types.rkt" _bool))

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
;; 导出
;; ============================================================

(provide
 draw-cube
 draw-cube-wires)

