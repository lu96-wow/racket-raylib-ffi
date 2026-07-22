#lang racket/base

;; raylib [models] example - billboard rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_billboard_rendering.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

;; 资源目录 — 使用 define-runtime-path 基于源文件位置解析
;; 从 examples/models/ 往上 3 级到 raylib/，再进入 examples/models/resources/
(define-runtime-path resource-dir "../../../examples/models/resources/")

(init-window screen-width screen-height
  "raylib [models] example - billboard rendering")

;; 定义 3D 相机
(define camera (camera3d 5.0 4.0 5.0
                         0.0 2.0 0.0
                         0.0 1.0 0.0
                         45.0 CAMERA-PERSPECTIVE))

;; 加载 billboard 纹理
(define bill (load-texture (path->string (build-path resource-dir "billboard.png"))))
(define bill-w (list-ref bill 1))   ;; Texture2D list: (id width height mipmaps format)
(define bill-h (texture-height bill))

(define bill-position-static (vector3 0.0 2.0 0.0))
(define bill-position-rotating (vector3 1.0 2.0 1.0))

;; 整张纹理的源矩形
(define source (rectangle 0.0 0.0 bill-w bill-h))

;; Y 轴锁定
(define bill-up (vector3 0.0 1.0 0.0))

;; 保持宽高比，高度为 1.0
(define size (vector2 (/ bill-w bill-h) 1.0))

;; 绕图片中心旋转
(define origin (vector2 (* 0.5 (/ bill-w bill-h)) 0.5))

(define rotation 0.0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    (update-camera camera CAMERA-ORBITAL)

    (set! rotation (+ rotation 0.4))

    ;; 计算距离以确定绘制顺序（远的先画）
    (let* ([cam-pos (vector3 (camera3d-pos-x camera)
                             (camera3d-pos-y camera)
                             (camera3d-pos-z camera))]
           [distance-static (vector3-distance cam-pos bill-position-static)]
           [distance-rotating (vector3-distance cam-pos bill-position-rotating)])

      ;; ---- Draw ----
      (begin-drawing)
      (clear-background RAYWHITE)

      (begin-mode-3d camera)

      (draw-grid 10 1.0)

      ;; 远的先画，保证正确的深度顺序
      (if (> distance-static distance-rotating)
          (begin
            (draw-billboard camera bill bill-position-static 2.0 WHITE)
            (draw-billboard-pro camera bill source
                               bill-position-rotating bill-up
                               size origin rotation WHITE))
          (begin
            (draw-billboard-pro camera bill source
                               bill-position-rotating bill-up
                               size origin rotation WHITE)
            (draw-billboard camera bill bill-position-static 2.0 WHITE)))

      (end-mode-3d)

      (draw-fps 10 10)

      (end-drawing)
      (loop))))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture bill)
(close-window)
