#lang racket/base

;; raylib [models] example - loading iqm (Racket FFI 翻译，简化版)
;;
;; 对应 C: examples/models/models_loading_iqm.c
;;
;; 简化: 只加载静态模型显示，跳过动画部分（LoadModelAnimations等）

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 资源路径
;; ============================================================

(define resource-dir
  (path->string (build-path (current-directory) "../examples/models/resources/")))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [models] example - loading iqm (simplified)")

(define camera (make-Camera3D 10.0 10.0 10.0
                              0.0 4.0 0.0
                              0.0 1.0 0.0
                              45.0 CAMERA-PERSPECTIVE))

(define guy-model
  (load-model (string-append resource-dir "models/iqm/guy.iqm")))

(define guy-texture
  (load-texture (string-append resource-dir "models/iqm/guytex.png")))

;; Set material texture: model.materials is at index 19 in model list
(set-material-texture (list-ref guy-model 19) MATERIAL-MAP-DIFFUSE guy-texture)

(define position (make-Vector3 0.0 0.0 0.0))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-ORBITAL)

    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)
    (draw-model-ex guy-model
                   position
                   (make-Vector3 1.0 0.0 0.0)  ;; rotation axis
                   -90.0                        ;; rotation angle
                   (make-Vector3 1.0 1.0 1.0)  ;; scale
                   WHITE)
    (draw-grid 10 1.0)
    (end-mode-3d)

    (draw-text "(c) Guy IQM 3D model by @culacant"
               (- screen-width 200) (- screen-height 20) 10 GRAY)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture guy-texture)
(unload-model guy-model)
(close-window)
