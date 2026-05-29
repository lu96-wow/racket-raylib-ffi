#lang racket/base

;; raylib [core] example - vr simulator
;;
;; Racket 翻译自 examples/core/core_vr_simulator.c
;;
;; 设计说明:
;;   VrDeviceInfo/VrStereoConfig 作为 list 通过 _list-struct 传值
;;   TextFormat 用 format 替代（避免绑定 C 变参函数）

(require "../../raylib/raylib.rkt")

;; ============================================================
;; VrStereoConfig 辅助（list-ref 偏移量速查）
;;
;; VrStereoConfig layout:
;;   projection[0]:    16 floats  [0..15]
;;   projection[1]:    16 floats  [16..31]
;;   viewOffset[0]:    16 floats  [32..47]
;;   viewOffset[1]:    16 floats  [48..63]
;;   leftLensCenter:    2 floats  [64..65]
;;   rightLensCenter:   2 floats  [66..67]
;;   leftScreenCenter:  2 floats  [68..69]
;;   rightScreenCenter: 2 floats  [70..71]
;;   scale:             2 floats  [72..73]
;;   scaleIn:           2 floats  [74..75]
;;
;; VrDeviceInfo layout:
;;   0: hResolution (int)
;;   1: vResolution (int)
;;   2-6: hScreenSize, vScreenSize, eyeToScreenDistance, ...
;;   7-10: lensDistortionValues[4]
;;   11-14: chromaAbCorrection[4]
;; ============================================================

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
             "raylib [core] example - vr simulator")

;; VR 设备参数（Oculus Rift CV1）
(define vr-device
  (list 2160         ;; hResolution
        1200         ;; vResolution
        0.133793     ;; hScreenSize
        0.0669       ;; vScreenSize
        0.041        ;; eyeToScreenDistance
        0.07         ;; lensSeparationDistance
        0.07         ;; interpupillaryDistance
        1.0 0.22 0.24 0.0  ;; lensDistortionValues[4]
        0.996 -0.004 1.014 0.0))  ;; chromaAbCorrection[4]

;; 加载 VR 立体渲染配置
(define vr-config (load-vr-stereo-config vr-device))

;; 加载失真着色器
(define distortion-shader
  (load-shader "" "../examples/core/resources/shaders/glsl330/distortion.fs"))

;; 配置着色器 uniform 值
(let ([loc-left-lens-center (get-shader-location distortion-shader "leftLensCenter")]
      [loc-right-lens-center (get-shader-location distortion-shader "rightLensCenter")]
      [loc-left-screen-center (get-shader-location distortion-shader "leftScreenCenter")]
      [loc-right-screen-center (get-shader-location distortion-shader "rightScreenCenter")]
      [loc-scale (get-shader-location distortion-shader "scale")]
      [loc-scale-in (get-shader-location distortion-shader "scaleIn")]
      [loc-device-warp (get-shader-location distortion-shader "deviceWarpParam")]
      [loc-chroma-ab (get-shader-location distortion-shader "chromaAbParam")])
  (set-shader-value distortion-shader loc-left-lens-center
    (malloc-float-vec2 (list-ref vr-config 64) (list-ref vr-config 65))
    SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-right-lens-center
    (malloc-float-vec2 (list-ref vr-config 66) (list-ref vr-config 67))
    SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-left-screen-center
    (malloc-float-vec2 (list-ref vr-config 68) (list-ref vr-config 69))
    SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-right-screen-center
    (malloc-float-vec2 (list-ref vr-config 70) (list-ref vr-config 71))
    SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-scale
    (malloc-float-vec2 (list-ref vr-config 72) (list-ref vr-config 73))
    SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-scale-in
    (malloc-float-vec2 (list-ref vr-config 74) (list-ref vr-config 75))
    SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-device-warp
    (malloc-float-vec4 (list-ref vr-device 7) (list-ref vr-device 8)
                       (list-ref vr-device 9) (list-ref vr-device 10))
    SHADER-UNIFORM-VEC4)
  (set-shader-value distortion-shader loc-chroma-ab
    (malloc-float-vec4 (list-ref vr-device 11) (list-ref vr-device 12)
                       (list-ref vr-device 13) (list-ref vr-device 14))
    SHADER-UNIFORM-VEC4))

;; 加载立体渲染帧缓冲
(define render-target (load-render-texture (list-ref vr-device 0) (list-ref vr-device 1)))

;; 纹理源矩形（由于 OpenGL 原因，height 取负）
(define source-rect (rectangle 0.0 0.0
                                  (exact->inexact (list-ref render-target 2))
                                  (- (exact->inexact (list-ref render-target 3)))))
;; 目标矩形
(define dest-rect (rectangle 0.0 0.0
                              (exact->inexact (get-screen-width))
                              (exact->inexact (get-screen-height))))

;; 相机设置
(define camera (camera3d 5.0 2.0 5.0   ;; position
                         0.0 2.0 0.0   ;; target
                         0.0 1.0 0.0   ;; up
                         60.0           ;; fovy
                         CAMERA-PERSPECTIVE))

(disable-cursor)
(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()
  (unless (window-should-close?)
    ;; --- 更新 ---
    (update-camera camera CAMERA-FIRST-PERSON)

    ;; --- 绘制到纹理 ---
    (begin-texture-mode render-target)
    (clear-background RAYWHITE)
    (begin-vr-stereo-mode vr-config)
    (begin-mode-3d camera)

    (draw-cube (vector3 0.0 0.0 0.0) 2.0 2.0 2.0 RED)
    (draw-cube-wires (vector3 0.0 0.0 0.0) 2.0 2.0 2.0 MAROON)
    (draw-grid 40 1.0)

    (end-mode-3d)
    (end-vr-stereo-mode)
    (end-texture-mode)

    ;; --- 绘制到屏幕（带失真着色器）---
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-shader-mode distortion-shader)
    (draw-texture-pro (list (list-ref render-target 1)
                            (list-ref render-target 2)
                            (list-ref render-target 3)
                            (list-ref render-target 4)
                            (list-ref render-target 5))
                      source-rect dest-rect
                      (vector2 0.0 0.0) 0.0 WHITE)
    (end-shader-mode)
    (draw-fps 10 10)
    (end-drawing)

    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-vr-stereo-config vr-config)
(unload-render-texture render-target)
(unload-shader distortion-shader)
(close-window)
