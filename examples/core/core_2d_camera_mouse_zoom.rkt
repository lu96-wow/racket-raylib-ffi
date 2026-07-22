#lang racket/base

;; raylib [core] example - 2d camera mouse zoom (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_2d_camera_mouse_zoom.c
;;
;; 演示两种缩放模式:
;;   [1] 滚轮缩放 — 按住鼠标左键拖拽平移, 滚轮缩放
;;   [2] 鼠标移动缩放 — 按住鼠标左键拖拽平移, 按住鼠标右键移动缩放
;;
;; 涉及新增绑定:
;;   get-screen-width, get-screen-height, get-screen-to-world-2d
;;   draw-grid, rl-push-matrix, rl-pop-matrix, rl-translate-f, rl-rotate-f

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 辅助函数 — 替代 raymath.h
;; ============================================================

(define (vector2-scale v s)
  (vector2 (* (vector2-x v) s) (* (vector2-y v) s)))

(define (vector2-add v1 v2)
  (vector2 (+ (vector2-x v1) (vector2-x v2))
           (+ (vector2-y v1) (vector2-y v2))))

(define (clamp v lo hi)
  (max lo (min hi v)))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [core] example - 2d camera mouse zoom")

;; Camera2D: (camera2d offset-x offset-y target-x target-y rotation zoom)
(define camera (camera2d 0.0 0.0 0.0 0.0 0.0 1.0))

(define zoom-mode 0)  ;; 0-Mouse Wheel, 1-Mouse Move

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; --- 更新 ---

    ;; [1][2] 切换缩放模式
    (cond
      [(is-key-pressed KEY-ONE) (set! zoom-mode 0)]
      [(is-key-pressed KEY-TWO) (set! zoom-mode 1)])

    ;; 鼠标左键拖拽平移 (两种模式共用)
    (when (is-mouse-button-down MOUSE-BUTTON-LEFT)
      (let ([delta (get-mouse-delta)])
        (set! delta (vector2-scale delta (/ -1.0 (camera2d-zoom camera))))
        (set-camera2d-target-x! camera
          (+ (camera2d-target-x camera) (vector2-x delta)))
        (set-camera2d-target-y! camera
          (+ (camera2d-target-y camera) (vector2-y delta)))))

    ;; 缩放处理
    (if (= zoom-mode 0)
        ;; ── 模式 0: 滚轮缩放 ──
        (let ([wheel (get-mouse-wheel-move)])
          (unless (= wheel 0.0)
            ;; 获取鼠标下的世界坐标
            (let ([mouse-world-pos
                   (get-screen-to-world-2d (get-mouse-position) camera)])
              ;; 设置 offset 到鼠标位置
              (set-camera2d-offset-x! camera (exact->inexact (get-mouse-x)))
              (set-camera2d-offset-y! camera (exact->inexact (get-mouse-y)))
              ;; 设置 target 匹配, 使鼠标下的世界坐标在缩放时保持不动
              (set-camera2d-target-x! camera (vector2-x mouse-world-pos))
              (set-camera2d-target-y! camera (vector2-y mouse-world-pos))
              ;; 对数缩放: consistent zoom speed
              (set-camera2d-zoom! camera
                (clamp (exp (+ (log (camera2d-zoom camera)) (* 0.2 wheel)))
                       0.125 64.0)))))

        ;; ── 模式 1: 鼠标右键缩放 ──
        (begin
          ;; 右键按下时锁定焦点
          (when (is-mouse-button-pressed MOUSE-BUTTON-RIGHT)
            (let ([mouse-world-pos
                   (get-screen-to-world-2d (get-mouse-position) camera)])
              (set-camera2d-offset-x! camera (exact->inexact (get-mouse-x)))
              (set-camera2d-offset-y! camera (exact->inexact (get-mouse-y)))
              (set-camera2d-target-x! camera (vector2-x mouse-world-pos))
              (set-camera2d-target-y! camera (vector2-y mouse-world-pos))))
          ;; 右键按住时横向移动控制缩放
          (when (is-mouse-button-down MOUSE-BUTTON-RIGHT)
            (let ([delta-x (vector2-x (get-mouse-delta))])
              (set-camera2d-zoom! camera
                (clamp (exp (+ (log (camera2d-zoom camera)) (* 0.005 delta-x)))
                       0.125 64.0))))))

    ;; --- 绘制 ---
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 相机内绘制
    (begin-mode-2d camera)

    ;; 绘制 3D 网格 (旋转 90° 到 XY 平面)
    (rl-push-matrix)
    (rl-translate-f 0.0 (exact->inexact (* 25 50)) 0.0)
    (rl-rotate-f 90.0 1.0 0.0 0.0)
    (draw-grid 100 50.0)
    (rl-pop-matrix)

    ;; 绘制参考圆
    (draw-circle (quotient (get-screen-width) 2)
                 (quotient (get-screen-height) 2)
                 50.0 MAROON)

    (end-mode-2d)

    ;; 鼠标参考点 (屏幕坐标)
    (draw-circle-v (get-mouse-position) 4.0 DARKGRAY)
    (draw-text (format "[~a, ~a]" (get-mouse-x) (get-mouse-y))
               (- (get-mouse-x) 44) (- (get-mouse-y) 24) 20 BLACK)

    ;; 说明文字
    (draw-text "[1][2] Select mouse zoom mode (Wheel or Move)"
               20 20 20 DARKGRAY)
    (if (= zoom-mode 0)
        (draw-text "Mouse left button drag to move, mouse wheel to zoom"
                   20 50 20 DARKGRAY)
        (draw-text "Mouse left button drag to move, mouse press and move to zoom"
                   20 50 20 DARKGRAY))

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
