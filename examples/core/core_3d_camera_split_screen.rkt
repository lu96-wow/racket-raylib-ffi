#lang racket/base

;; raylib [core] example - 3d camera split screen (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_3d_camera_split_screen.c
;;
;; 演示 3D 双人分屏:
;;   玩家 1 (红): W/S 沿 Z 轴前后移动
;;   玩家 2 (蓝): UP/DOWN 沿 X 轴前后移动
;;
;; 每个玩家使用独立的 Camera3D, 各自渲染到 RenderTexture,
;; 最后并排绘制到主屏幕。

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)

(define COUNT 5)
(define SPACING 4.0)

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - 3d camera split screen")

;; 玩家 1 的相机 (位置在 (0, 1, -3), 看向 (0, 1, 0))
(define camera-player1
  (camera3d 0.0 1.0 -3.0    ;; position
            0.0 1.0 0.0     ;; target
            0.0 1.0 0.0     ;; up
            45.0            ;; fovy
            CAMERA-PERSPECTIVE))

;; 玩家 2 的相机 (位置在 (-3, 3, 0), 看向 (0, 3, 0))
(define camera-player2
  (camera3d -3.0 3.0 0.0    ;; position
            0.0 3.0 0.0     ;; target
            0.0 1.0 0.0     ;; up
            45.0            ;; fovy
            CAMERA-PERSPECTIVE))

;; 两个渲染纹理 (各占一半屏幕宽度)
(define screen-player1 (load-render-texture (quotient SCREEN-WIDTH 2) SCREEN-HEIGHT))
(define screen-player2 (load-render-texture (quotient SCREEN-WIDTH 2) SCREEN-HEIGHT))

;; 分屏矩形 (texture 坐标, height 为负 = 上下翻转)
(define split-screen-rect
  (rectangle 0.0 0.0
    (exact->inexact (list-ref screen-player1 2))   ;; tex-width
    (exact->inexact (- (list-ref screen-player1 3))))) ;; -tex-height

(set-target-fps 60)

;; ============================================================
;; 辅助: 从 RenderTexture list 中提取 texture 子列表 (5 元素)
;;
;; RenderTexture layout: (id tex-id tex-w tex-h tex-mip tex-fmt dep-id dep-w dep-h dep-mip dep-fmt)
;; Texture:              (id    w      h     mip    fmt)
;; ============================================================

(define (rt->texture rt)
  (list (render-texture-tex-id rt) (render-texture-tex-width rt) (render-texture-tex-height rt) (render-texture-tex-mipmaps rt) (render-texture-tex-format rt)))

;; ============================================================
;; 辅助: 绘制 3D 场景 (在两个玩家的纹理中共享)
;; ============================================================

(define (draw-3d-scene)
  ;; 平面
  (draw-plane (vector3 0.0 0.0 0.0) (vector2 50.0 50.0) BEIGE)

  ;; 网格中的方块树
  (for* ([xi (in-range (- COUNT) (add1 COUNT))]
         [zi (in-range (- COUNT) (add1 COUNT))])
    (let ([x (* xi SPACING)]
          [z (* zi SPACING)])
      ;; 树冠 (绿色)
      (draw-cube (vector3 x 1.5 z) 1.0 1.0 1.0 LIME)
      ;; 树干 (棕色)
      (draw-cube (vector3 x 0.5 z) 0.25 1.0 0.25 BROWN)))

  ;; 在每个玩家位置绘制标记方块
  (draw-cube (vector3 (camera3d-pos-x camera-player1)
                      (camera3d-pos-y camera-player1)
                      (camera3d-pos-z camera-player1))
             1.0 1.0 1.0 RED)
  (draw-cube (vector3 (camera3d-pos-x camera-player2)
                      (camera3d-pos-y camera-player2)
                      (camera3d-pos-z camera-player2))
             1.0 1.0 1.0 BLUE))

;; ============================================================
;; 主循环
;; ============================================================

(let game-loop ()
  (unless (window-should-close?)
    ;; --- 更新 ---

    ;; 基于帧时间的移动量 (10 单位/秒)
    (define offset-this-frame (* 10.0 (get-frame-time)))

    ;; 玩家 1: W/S 沿 Z 轴前后移动
    (when (is-key-down KEY-W)
      (set-camera3d-pos-z! camera-player1
        (+ (camera3d-pos-z camera-player1) offset-this-frame))
      (set-camera3d-tar-z! camera-player1
        (+ (camera3d-tar-z camera-player1) offset-this-frame)))
    (when (is-key-down KEY-S)
      (set-camera3d-pos-z! camera-player1
        (- (camera3d-pos-z camera-player1) offset-this-frame))
      (set-camera3d-tar-z! camera-player1
        (- (camera3d-tar-z camera-player1) offset-this-frame)))

    ;; 玩家 2: UP/DOWN 沿 X 轴前后移动
    (when (is-key-down KEY-UP)
      (set-camera3d-pos-x! camera-player2
        (+ (camera3d-pos-x camera-player2) offset-this-frame))
      (set-camera3d-tar-x! camera-player2
        (+ (camera3d-tar-x camera-player2) offset-this-frame)))
    (when (is-key-down KEY-DOWN)
      (set-camera3d-pos-x! camera-player2
        (- (camera3d-pos-x camera-player2) offset-this-frame))
      (set-camera3d-tar-x! camera-player2
        (- (camera3d-tar-x camera-player2) offset-this-frame)))

    ;; --- 绘制到纹理 1 (玩家 1 视角) ---

    (begin-texture-mode screen-player1)
    (clear-background SKYBLUE)

    (begin-mode-3d camera-player1)
    (draw-3d-scene)
    (end-mode-3d)

    ;; HUD
    (define hud-w (get-screen-width))
    (draw-rectangle 0 0 (quotient hud-w 2) 40 (fade RAYWHITE 0.8))
    (draw-text "PLAYER1: W/S to move" 10 10 20 MAROON)

    (end-texture-mode)

    ;; --- 绘制到纹理 2 (玩家 2 视角) ---

    (begin-texture-mode screen-player2)
    (clear-background SKYBLUE)

    (begin-mode-3d camera-player2)
    (draw-3d-scene)
    (end-mode-3d)

    ;; HUD
    (draw-rectangle 0 0 (quotient hud-w 2) 40 (fade RAYWHITE 0.8))
    (draw-text "PLAYER2: UP/DOWN to move" 10 10 20 DARKBLUE)

    (end-texture-mode)

    ;; --- 合并绘制到主屏幕 ---

    (begin-drawing)
    (clear-background BLACK)

    (define tex1 (rt->texture screen-player1))
    (define tex2 (rt->texture screen-player2))

    (draw-texture-rec tex1 split-screen-rect (vector2 0.0 0.0) WHITE)
    (draw-texture-rec tex2 split-screen-rect
                      (vector2 (exact->inexact (quotient SCREEN-WIDTH 2)) 0.0) WHITE)

    ;; 中间分割线
    (draw-rectangle (- (quotient SCREEN-WIDTH 2) 2) 0 4 SCREEN-HEIGHT LIGHTGRAY)

    (end-drawing)

    (game-loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-render-texture screen-player1)
(unload-render-texture screen-player2)
(close-window)
