#lang racket/base

;; core/rcamera.rkt — 相机控制辅助函数 (rcamera.h)

(require ffi/unsafe
         "ffi-helpers.rkt")

(def-ffi camera-yaw   "CameraYaw"   (_fun _pointer _float _stdbool -> _void))
(def-ffi camera-pitch "CameraPitch" (_fun _pointer _float _stdbool _stdbool _stdbool -> _void))
(def-ffi camera-roll  "CameraRoll"  (_fun _pointer _float -> _void))
(def-ffi camera-move-forward  "CameraMoveForward"  (_fun _pointer _float _stdbool -> _void))
(def-ffi camera-move-right    "CameraMoveRight"    (_fun _pointer _float _stdbool -> _void))
(def-ffi camera-move-up       "CameraMoveUp"       (_fun _pointer _float -> _void))
(def-ffi camera-move-to-target "CameraMoveToTarget" (_fun _pointer _float -> _void))
(def-ffi get-camera-forward "GetCameraForward" (_fun _pointer -> _pointer))
(def-ffi get-camera-right   "GetCameraRight"   (_fun _pointer -> _pointer))
(def-ffi get-camera-up      "GetCameraUp"      (_fun _pointer -> _pointer))

(provide
 camera-yaw camera-pitch camera-roll
 camera-move-forward camera-move-right camera-move-up camera-move-to-target
 get-camera-forward get-camera-right get-camera-up)
