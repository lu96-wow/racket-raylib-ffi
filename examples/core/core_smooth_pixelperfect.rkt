#lang racket/base

;; raylib [core] example - smooth pixelperfect (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_smooth_pixelperfect.c
;;
;; 演示: 平滑像素完美渲染 (双摄像机 + RenderTexture + 子像素精度)

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)

(define VIRTUAL-WIDTH  160)
(define VIRTUAL-HEIGHT 90)

(define VIRTUAL-RATIO (/ SCREEN-WIDTH VIRTUAL-WIDTH))

;; ============================================================
;; 辅助: 从 RenderTexture 列表提取 Texture 子列表 (5 元素)
;; RenderTexture 布局: (id tex-id tex-w tex-h tex-mip tex-fmt dep-id dep-w dep-h dep-mip dep-fmt)
;; Texture 布局:       (id   w      h     mip    fmt)
;; ============================================================

(define (rt->texture rt)
  (list (render-texture-tex-id rt) (render-texture-tex-width rt) (render-texture-tex-height rt)
        (render-texture-tex-mipmaps rt) (render-texture-tex-format rt)))

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - smooth pixelperfect")

;; 游戏世界相机 (整数坐标)
(define world-space-camera (camera2d 0 0 0 0 0 1.0))

;; 平滑子像素相机 (保留小数部分)
(define screen-space-camera (camera2d 0 0 0 0 0 1.0))

;; 加载渲染纹理 (离屏绘制)
(define target (load-render-texture VIRTUAL-WIDTH VIRTUAL-HEIGHT))

;; 三个旋转矩形
(define rec01 (rectangle 70.0 35.0 20.0 20.0))
(define rec02 (rectangle 90.0 55.0 30.0 10.0))
(define rec03 (rectangle 80.0 65.0 15.0 25.0))

;; 纹理源矩形 (height 取负 = OpenGL 上下翻转)
(define source-rec (rectangle 0 0
                    (render-texture-tex-width target)
                    (* -1 (render-texture-tex-height target))))

;; 目标矩形 (居中缩放显示)
(define dest-rec
  (rectangle (/ (- SCREEN-WIDTH (/ SCREEN-WIDTH 1.25)) 2.0)
             (/ (- SCREEN-HEIGHT (/ SCREEN-HEIGHT 1.25)) 2.0)
             (/ SCREEN-WIDTH 1.25)
             (/ SCREEN-HEIGHT 1.25)))

(define origin (vector2 0 0))

(define rotation 0.0)
(define smooth-on #t)
(define overscan #f)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; === 更新 ===
    (set! rotation (+ rotation (* 60 (get-frame-time))))  ;; 60 度/秒

    ;; 相机移动: sin/cos 驱动
    (define camera-x (- (* (sin (get-time)) 50.0) 10.0))
    (define camera-y (* (cos (get-time)) 30.0))

    ;; 设置 screenSpace 相机 target
    (set-camera2d-target-x! screen-space-camera camera-x)
    (set-camera2d-target-y! screen-space-camera camera-y)

    ;; 整数部分 → worldSpace 相机, 小数部分 * 缩放比 → screenSpace 相机
    (set-camera2d-target-x! world-space-camera (truncate (camera2d-target-x screen-space-camera)))
    (set-camera2d-target-x! screen-space-camera
      (* (- (camera2d-target-x screen-space-camera)
            (camera2d-target-x world-space-camera))
         VIRTUAL-RATIO))

    (set-camera2d-target-y! world-space-camera (truncate (camera2d-target-y screen-space-camera)))
    (set-camera2d-target-y! screen-space-camera
      (* (- (camera2d-target-y screen-space-camera)
            (camera2d-target-y world-space-camera))
         VIRTUAL-RATIO))

    ;; 按键
    (when (is-key-pressed KEY-S) (set! smooth-on (not smooth-on)))
    (when (is-key-pressed KEY-O) (set! overscan (not overscan)))

    ;; 切换 overscan
    (if overscan
      (begin
        (set-rectangle-x! dest-rec (- VIRTUAL-RATIO))
        (set-rectangle-y! dest-rec (- VIRTUAL-RATIO))
        (set-rectangle-w! dest-rec (+ SCREEN-WIDTH (* VIRTUAL-RATIO 2)))
        (set-rectangle-h! dest-rec (+ SCREEN-HEIGHT (* VIRTUAL-RATIO 2))))
      (begin
        (set-rectangle-x! dest-rec
          (/ (- SCREEN-WIDTH (/ SCREEN-WIDTH 1.25)) 2.0))
        (set-rectangle-y! dest-rec
          (/ (- SCREEN-HEIGHT (/ SCREEN-HEIGHT 1.25)) 2.0))
        (set-rectangle-w! dest-rec (/ SCREEN-WIDTH 1.25))
        (set-rectangle-h! dest-rec (/ SCREEN-HEIGHT 1.25))))

    ;; === 离屏绘制: 渲染到纹理 ===
    (begin-texture-mode target)
    (clear-background RAYWHITE)

    (begin-mode-2d world-space-camera)
    (draw-rectangle-pro rec01 origin rotation BLACK)
    (draw-rectangle-pro rec02 origin (- rotation) RED)
    (draw-rectangle-pro rec03 origin (+ rotation 45.0) BLUE)
    (end-mode-2d)

    (end-texture-mode)

    ;; === 主屏绘制 ===
    (begin-drawing)
    (clear-background LIGHTGRAY)

    (if smooth-on
      (begin
        (begin-mode-2d screen-space-camera)
        (draw-texture-pro (rt->texture target) source-rec dest-rec origin 0.0 WHITE)
        (end-mode-2d))
      (draw-texture-pro (rt->texture target) source-rec dest-rec origin 0.0 WHITE))

    ;; 显示信息
    (draw-text (format "Screen resolution: ~ax~a" SCREEN-WIDTH SCREEN-HEIGHT)
               10 10 20 DARKBLUE)
    (draw-text (format "World resolution: ~ax~a" VIRTUAL-WIDTH VIRTUAL-HEIGHT)
               10 40 20 DARKGREEN)
    (draw-text (format "Smooth: ~a" (if smooth-on "ON" "OFF"))
               10 (- SCREEN-HEIGHT 60) 20 RED)
    (draw-text (format "Overscan: ~a" (if overscan "ON" "OFF"))
               10 (- SCREEN-HEIGHT 30) 20 RED)
    (draw-fps (- (get-screen-width) 95) 10)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-render-texture target)
(close-window)
