#lang racket/base

;; raylib camera 模块 — 相机系统
;;
;; 对应 C: rcamera.h
;; 包括: UpdateCamera, UpdateCameraPro, CameraYaw, CameraPitch 等

(require (except-in ffi/unsafe _bool)
         (prefix-in T: "types.rkt")
         (only-in "types.rkt" _bool))

;; ============================================================
;; CameraYaw(Camera *camera, float angle, bool rotateAroundTarget)
;;   camera: 裸指针 (Camera3D)
;;   angle: 弧度
;;   rotateAroundTarget: #t / #f
;; ============================================================

(define camera-yaw
  (get-ffi-obj "CameraYaw" T:lib
    (_fun _pointer _float _bool -> _void)))

;; ============================================================
;; CameraPitch(Camera *camera, float angle, bool lockView,
;;             bool rotateAroundTarget, bool rotateUp)
;; ============================================================

(define camera-pitch
  (get-ffi-obj "CameraPitch" T:lib
    (_fun _pointer _float _bool _bool _bool -> _void)))

(provide
 camera-yaw
 camera-pitch)

