#lang racket/base

;; raylib [models] example - animation gpu skinning (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_animation_gpu_skinning.c
;;
;; WARNING: GPU skinning must be enabled in raylib with a compilation flag,
;; if not enabled, CPU skinning will be used instead

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(define GLSL-VERSION 330)

;; 资源目录
(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window screen-width screen-height
  "raylib [models] example - animation gpu skinning")

;; 定义 3D 相机
(define camera (camera3d 5.0 5.0 5.0
                         0.0 1.0 0.0
                         0.0 1.0 0.0
                         45.0 CAMERA-PERSPECTIVE))

;; 加载模型
(define model-path (res "models/gltf/greenman.glb"))
(define model (load-model model-path))
(define position (vector3 0.0 0.0 0.0))

;; 加载 skinning 着色器
(define skinning-shader
  (load-shader
   (res (format "shaders/glsl~a/skinning.vs" GLSL-VERSION))
   (res (format "shaders/glsl~a/skinning.fs" GLSL-VERSION))))

;; 设置 model.materials[1].shader = skinningShader (使用绑定函数)
(let ([materials-ptr (model-materials model)])
  (set-material-shader (ptr-add materials-ptr 40) skinning-shader))

;; 加载动画
(let-values ([(anims-ptr anim-count) (load-model-animations model-path)])
  ;; 辅助函数: 从动画列表中提取名称
  (define (anim-name-from-list anim-lst)
    (list->string
     (for/list ([i (in-range 32)]
                #:break (zero? (list-ref anim-lst i)))
       (integer->char (list-ref anim-lst i)))))

  ;; 动画播放变量
  (define anim-index 0)
  (define anim-current-frame 0)

  (set-target-fps 60)

  ;; ============================================================
  ;; 主循环
  ;; ============================================================

  (let loop ()
    (unless (window-should-close?)
      ;; ---- Update ----
      (update-camera camera CAMERA-ORBITAL)

      ;; 左右键切换动画
      (cond [(is-key-pressed KEY-RIGHT)
             (set! anim-index (modulo (add1 anim-index) anim-count))]
            [(is-key-pressed KEY-LEFT)
             (set! anim-index (modulo (+ anim-index (sub1 anim-count)) anim-count))])

      ;; 获取当前动画数据
      (let* ([anim (ptr-ref anims-ptr _model-animation-bytes anim-index)]
             [kf-count (model-animation-frame-count anim)]
             [anim-name (anim-name-from-list anim)])

        ;; 更新动画帧
        (set! anim-current-frame (modulo (add1 anim-current-frame) kf-count))
        (update-model-animation model anim (exact->inexact anim-current-frame))

        ;; ---- Draw ----
        (begin-drawing)
        (clear-background RAYWHITE)

        (begin-mode-3d camera)

        (draw-model model position 1.0 WHITE)
        (draw-grid 10 1.0)

        (end-mode-3d)

        (draw-text (format "Current animation: ~a" anim-name) 10 40 20 MAROON)
        (draw-text "Use the LEFT/RIGHT keys to switch animation" 10 10 20 GRAY)

        (end-drawing)
        (loop))))

  ;; ============================================================
  ;; 清理
  ;; ============================================================

  (unload-model-animations anims-ptr anim-count)
  (unload-model model)
  (unload-shader skinning-shader))

(close-window)
