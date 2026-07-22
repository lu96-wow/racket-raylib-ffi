#lang racket/base

;; raylib VR 立体渲染 — 键盘控制视角
;;
;; 结合:
;;   - 失真着色器 + VR 立体渲染
;;   - WASD/QE/方向键手动控制相机
;;
;; 启动: cd racket-bind && racket test/vr-keyboard-camera.rkt

(require "../../raylib/raylib.rkt")

(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 450)
(define MOVE-SPEED 8.0)
(define LOOK-SPEED 1.5)

(define (camera-forward pos target)
  (vec3-normalize (vector3 (- (vector3-x target) (vector3-x pos))
                           (- (vector3-y target) (vector3-y pos))
                           (- (vector3-z target) (vector3-z pos)))))
(define (camera-right forward)
  (vec3-normalize (vec3-cross-product forward (vector3 0.0 1.0 0.0))))

(define (make-cam-ptr)
  (camera3d 5.0 2.0 5.0 0.0 2.0 0.0 0.0 1.0 0.0 60.0 CAMERA-PERSPECTIVE))
(define (cam-move! cam dx dy dz)
  (set-camera3d-pos-x! cam (+ (camera3d-pos-x cam) dx))
  (set-camera3d-pos-y! cam (+ (camera3d-pos-y cam) dy))
  (set-camera3d-pos-z! cam (+ (camera3d-pos-z cam) dz))
  (set-camera3d-tar-x! cam (+ (camera3d-tar-x cam) dx))
  (set-camera3d-tar-y! cam (+ (camera3d-tar-y cam) dy))
  (set-camera3d-tar-z! cam (+ (camera3d-tar-z cam) dz)))

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT "raylib [test] - VR keyboard camera")

;; VR 设备参数
(define vr-device
  (list 2160 1200 0.133793 0.0669 0.041 0.07 0.07
        1.0 0.22 0.24 0.0
        0.996 -0.004 1.014 0.0))
(define vr-config (load-vr-stereo-config vr-device))

;; 失真着色器
(define distortion-shader
  (load-shader "" "../examples/core/resources/shaders/glsl330/distortion.fs"))

(let ([loc-left-lens-center (get-shader-location distortion-shader "leftLensCenter")]
      [loc-right-lens-center (get-shader-location distortion-shader "rightLensCenter")]
      [loc-left-screen-center (get-shader-location distortion-shader "leftScreenCenter")]
      [loc-right-screen-center (get-shader-location distortion-shader "rightScreenCenter")]
      [loc-scale (get-shader-location distortion-shader "scale")]
      [loc-scale-in (get-shader-location distortion-shader "scaleIn")]
      [loc-warp (get-shader-location distortion-shader "deviceWarpParam")]
      [loc-chroma (get-shader-location distortion-shader "chromaAbParam")])
  (set-shader-value distortion-shader loc-left-lens-center
                    (malloc-float-vec2 (list-ref vr-config 64) (list-ref vr-config 65)) SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-right-lens-center
                    (malloc-float-vec2 (list-ref vr-config 66) (list-ref vr-config 67)) SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-left-screen-center
                    (malloc-float-vec2 (list-ref vr-config 68) (list-ref vr-config 69)) SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-right-screen-center
                    (malloc-float-vec2 (list-ref vr-config 70) (list-ref vr-config 71)) SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-scale
                    (malloc-float-vec2 (list-ref vr-config 72) (list-ref vr-config 73)) SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-scale-in
                    (malloc-float-vec2 (list-ref vr-config 74) (list-ref vr-config 75)) SHADER-UNIFORM-VEC2)
  (set-shader-value distortion-shader loc-warp
                    (malloc-float-vec4 (list-ref vr-device 7) (list-ref vr-device 8) (list-ref vr-device 9) (list-ref vr-device 10))
                    SHADER-UNIFORM-VEC4)
  (set-shader-value distortion-shader loc-chroma
                    (malloc-float-vec4 (list-ref vr-device 11) (list-ref vr-device 12) (list-ref vr-device 13) (list-ref vr-device 14))
                    SHADER-UNIFORM-VEC4))

;; 渲染目标
(define render-target (load-render-texture (list-ref vr-device 0) (list-ref vr-device 1)))
(define source-rect
  (rectangle 0.0 0.0
             (exact->inexact (list-ref render-target 2))
             (- (exact->inexact (list-ref render-target 3)))))
(define dest-rect
  (rectangle 0.0 0.0
             (exact->inexact (get-screen-width))
             (exact->inexact (get-screen-height))))

;; 相机
(define cam (make-cam-ptr))
(define-var speed-mult 1.0)

(disable-cursor)
(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()
  (unless (window-should-close?)
    (define dt (get-frame-time))
    (define base-speed (* MOVE-SPEED (unbox speed-mult) dt))
    (define look-angle (* LOOK-SPEED dt))

    ;; --- 键盘相机 ---
    (define pos (vector3 (camera3d-pos-x cam) (camera3d-pos-y cam) (camera3d-pos-z cam)))
    (define target (vector3 (camera3d-tar-x cam) (camera3d-tar-y cam) (camera3d-tar-z cam)))
    (define fwd (camera-forward pos target))
    (define right (camera-right fwd))

    (when (is-key-down KEY-W) (cam-move! cam (* (vector3-x fwd) base-speed) (* (vector3-y fwd) base-speed) (* (vector3-z fwd) base-speed)))
    (when (is-key-down KEY-S) (cam-move! cam (- (* (vector3-x fwd) base-speed)) (- (* (vector3-y fwd) base-speed)) (- (* (vector3-z fwd) base-speed))))
    (when (is-key-down KEY-A) (cam-move! cam (- (* (vector3-x right) base-speed)) (- (* (vector3-y right) base-speed)) (- (* (vector3-z right) base-speed))))
    (when (is-key-down KEY-D) (cam-move! cam (* (vector3-x right) base-speed) (* (vector3-y right) base-speed) (* (vector3-z right) base-speed)))
    (when (is-key-down KEY-Q) (cam-move! cam 0.0 base-speed 0.0))
    (when (is-key-down KEY-E) (cam-move! cam 0.0 (- base-speed) 0.0))
    (when (is-key-down KEY-RIGHT) (camera-yaw cam (- look-angle) #t))
    (when (is-key-down KEY-LEFT)  (camera-yaw cam look-angle #t))
    (when (is-key-down KEY-UP)    (camera-pitch cam look-angle #t #f #f))
    (when (is-key-down KEY-DOWN)  (camera-pitch cam (- look-angle) #t #f #f))
    (set-box! speed-mult (cond [(is-key-down KEY-LEFT-SHIFT) 3.0] [(is-key-down KEY-LEFT-CONTROL) 0.3] [else 1.0]))
    (when (is-key-pressed KEY-R)
      (cam-move! cam (- 5.0 (camera3d-pos-x cam)) (- 2.0 (camera3d-pos-y cam)) (- 5.0 (camera3d-pos-z cam)))
      (set-camera3d-tar-x! cam 0.0) (set-camera3d-tar-y! cam 2.0) (set-camera3d-tar-z! cam 0.0))

    ;; --- VR 渲染到纹理 ---
    (begin-texture-mode render-target)
    (clear-background (color 245 245 245))
    (begin-vr-stereo-mode vr-config)
    (begin-mode-3d cam)
    (draw-cube (vector3 0.0 0.0 0.0) 2.0 2.0 2.0 RED)
    (draw-cube-wires (vector3 0.0 0.0 0.0) 2.0 2.0 2.0 MAROON)
    (draw-grid 40 1.0)
    (end-mode-3d)
    (end-vr-stereo-mode)
    (end-texture-mode)

    ;; --- 绘制到屏幕（失真着色器）---
    (begin-drawing)
    (clear-background (color 245 245 245))
    (begin-shader-mode distortion-shader)
    (draw-texture-pro (list (list-ref render-target 1) (list-ref render-target 2)
                            (list-ref render-target 3) (list-ref render-target 4)
                            (list-ref render-target 5))
                      source-rect dest-rect (vector2 0.0 0.0) 0.0 WHITE)
    (end-shader-mode)

    (draw-fps 10 10)
    (draw-text "WASD=move QE=up/down Arrows=look Shift=speed Ctrl=slow R=reset" 10 50 20 DARKGRAY)
    (draw-text (format "Pos: ~a ~a ~a" (camera3d-pos-x cam) (camera3d-pos-y cam) (camera3d-pos-z cam)) 10 80 15 BLACK)

    (end-drawing)
    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-vr-stereo-config vr-config)
(unload-render-texture render-target)
(unload-shader distortion-shader)
(close-window)
