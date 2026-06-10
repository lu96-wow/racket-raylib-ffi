#lang racket/base

(require ffi/unsafe (prefix-in T: "types.rkt"))

(define lib T:lib)

(define camera-yaw
  (get-ffi-obj "CameraYaw" lib (_fun _pointer _float _stdbool -> _void)))

(define camera-pitch
  (get-ffi-obj "CameraPitch" lib (_fun _pointer _float _stdbool _stdbool _stdbool -> _void)))

(define camera-roll
  (get-ffi-obj "CameraRoll" lib (_fun _pointer _float -> _void)))

(define camera-move-forward
  (get-ffi-obj "CameraMoveForward" lib (_fun _pointer _float _stdbool -> _void)))

(define camera-move-right
  (get-ffi-obj "CameraMoveRight" lib (_fun _pointer _float _stdbool -> _void)))

(define camera-move-up
  (get-ffi-obj "CameraMoveUp" lib (_fun _pointer _float -> _void)))

(define camera-move-to-target
  (get-ffi-obj "CameraMoveToTarget" lib (_fun _pointer _float -> _void)))

(define get-camera-forward
  (get-ffi-obj "GetCameraForward" lib (_fun _pointer -> _pointer)))

(define get-camera-right
  (get-ffi-obj "GetCameraRight" lib (_fun _pointer -> _pointer)))

(define get-camera-up
  (get-ffi-obj "GetCameraUp" lib (_fun _pointer -> _pointer)))

(provide
 camera-yaw camera-pitch camera-roll
 camera-move-forward camera-move-right camera-move-up camera-move-to-target
 get-camera-forward get-camera-right get-camera-up)
