#lang racket/base

;; raylib [core] example - vr simulator
;;
;; Racket 翻译自 examples/core/core_vr_simulator.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
             "raylib [core] example - vr simulator")

;; VR 设备参数（Oculus Rift CV1）— 手工构造 list 模拟 VrDeviceInfo
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
(let ([loc-left-lens-center  (get-shader-location distortion-shader "leftLensCenter")]
      [loc-right-lens-center (get-shader-location distortion-shader "rightLensCenter")]
      [loc-left-screen-center  (get-shader-location distortion-shader "leftScreenCenter")]
      [loc-right-screen-center (get-shader-location distortion-shader "rightScreenCenter")]
      [loc-scale     (get-shader-location distortion-shader "scale")]
      [loc-scale-in  (get-shader-location distortion-shader "scaleIn")]
      [loc-device-warp (get-shader-location distortion-shader "deviceWarpParam")]
      [loc-chroma-ab   (get-shader-location distortion-shader "chromaAbParam")])
  (set-shader-value distortion-shader loc-left-lens-center
    (malloc-float-vec2 (vr-stereo-config-left-lens-center0 vr-config)
                       (vr-stereo-config-left-lens-center1 vr-config))
    SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-right-lens-center
    (malloc-float-vec2 (vr-stereo-config-right-lens-center0 vr-config)
                       (vr-stereo-config-right-lens-center1 vr-config))
    SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-left-screen-center
    (malloc-float-vec2 (vr-stereo-config-left-screen-center0 vr-config)
                       (vr-stereo-config-left-screen-center1 vr-config))
    SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-right-screen-center
    (malloc-float-vec2 (vr-stereo-config-right-screen-center0 vr-config)
                       (vr-stereo-config-right-screen-center1 vr-config))
    SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-scale
    (malloc-float-vec2 (vr-stereo-config-scale0 vr-config)
                       (vr-stereo-config-scale1 vr-config))
    SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-scale-in
    (malloc-float-vec2 (vr-stereo-config-scale-in0 vr-config)
                       (vr-stereo-config-scale-in1 vr-config))
    SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-device-warp
    (malloc-float-vec4 (vr-device-info-lens-dist0 vr-device)
                       (vr-device-info-lens-dist1 vr-device)
                       (vr-device-info-lens-dist2 vr-device)
                       (vr-device-info-lens-dist3 vr-device))
    SHADER-UNIFORM-VEC4)
  (set-shader-value distortion-shader loc-chroma-ab
    (malloc-float-vec4 (vr-device-info-chroma-ab0 vr-device)
                       (vr-device-info-chroma-ab1 vr-device)
                       (vr-device-info-chroma-ab2 vr-device)
                       (vr-device-info-chroma-ab3 vr-device))
    SHADER-UNIFORM-VEC4))

;; 加载立体渲染帧缓冲
(define render-target (load-render-texture (vr-device-info-h-resolution vr-device)
                                           (vr-device-info-v-resolution vr-device)))

;; 纹理源矩形（由于 OpenGL 原因，height 取负）
(define source-rect (rectangle 0.0 0.0
                               (exact->inexact (render-texture-tex-width render-target))
                               (- (exact->inexact (render-texture-tex-height render-target)))))
;; 目标矩形
(define dest-rect (rectangle 0.0 0.0
                              (exact->inexact (get-screen-width))
                              (exact->inexact (get-screen-height))))

(define camera (camera3d  0.2 0.03 0.1
                          0.2 0.03 1.0
                          0.0 1.0  0.0
                          70.0 CAMERA-PERSPECTIVE))

(define cube-position (vector3 0.0 0.0 0.0))

(set-target-fps 90)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-FIRST-PERSON)

    ;; ---- Left Eye ----
    (begin-texture-mode render-target)
    (clear-background RAYWHITE)
    (begin-vr-stereo-mode vr-config 0)
    (begin-mode-3d camera)
    (draw-cube cube-position 2.0 2.0 2.0 RED)
    (draw-cube-wires cube-position 2.0 2.0 2.0 MAROON)
    (draw-grid 40 1.0)
    (end-mode-3d)
    (end-vr-stereo-mode)

    ;; ---- Right Eye ----
    (begin-vr-stereo-mode vr-config 1)
    (begin-mode-3d camera)
    (draw-cube cube-position 2.0 2.0 2.0 RED)
    (draw-cube-wires cube-position 2.0 2.0 2.0 MAROON)
    (draw-grid 40 1.0)
    (end-mode-3d)
    (end-vr-stereo-mode)
    (end-texture-mode)

    ;; ---- 绘制失真矫正后的立体图像 ----
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-shader-mode distortion-shader)
    (draw-texture-pro (list (render-texture-tex-id render-target)
                            (render-texture-tex-width render-target)
                            (render-texture-tex-height render-target)
                            (render-texture-tex-mipmaps render-target)
                            (render-texture-tex-format render-target))
                      source-rect dest-rect (vector2 0.0 0.0) 0.0 WHITE)
    (end-shader-mode)
    (draw-fps 10 10)
    (end-drawing)
    (loop)))

(close-window)
