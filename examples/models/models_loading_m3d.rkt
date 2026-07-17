#lang racket/base

;; raylib [models] example - loading m3d (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_loading_m3d.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         "../../raylib/raw-types.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

;; 资源目录 — 使用 define-runtime-path 基于源文件位置解析
(define-runtime-path resource-dir "../../../examples/models/resources/")

(init-window screen-width screen-height
  "raylib [models] example - loading m3d")

;; 定义 3D 相机
(define camera (camera3d 1.5 1.5 1.5
                         0.0 0.4 0.0
                         0.0 1.0 0.0
                         45.0 CAMERA-PERSPECTIVE))

;; 加载模型
(define m3d-path (path->string (build-path resource-dir "models/m3d/cesium_man.m3d")))
(define model (load-model m3d-path))
(define position (vector3 0.0 0.0 0.0))

;; 提取 model 骨骼数据
;; _model-bytes (136B): index 21=boneCount, 22=padding, 23=bones (BoneInfo*)
(define bone-count (list-ref model 21))
(define bones-ptr (list-ref model 23))

;; 加载动画
(let-values ([(anims-ptr anim-count) (load-model-animations m3d-path)])
  ;; 辅助函数: 从动画列表中提取名称
  (define (anim-name-from-list anim-lst)
    (list->string
     (for/list ([i (in-range anim-name-length)]
                #:break (zero? (list-ref anim-lst i)))
       (integer->char (list-ref anim-lst i)))))

  ;; 绘制骨骼 (对应 C: DrawModelSkeleton)
  ;; 使用 raw-types.rkt 的安全访问器 + ptr-add 字节偏移
  (define (draw-skeleton anim)
    (define frame-int (inexact->exact (floor anim-current-frame)))
    (define kf-poses-ptr (list-ref anim anim-keyframe-poses-index))  ;; Transform**
    (define frame-poses (ptr-ref kf-poses-ptr _pointer frame-int))   ;; Transform*

    (for ([i (in-range (sub1 bone-count))])
      ;; &pose[i] — ptr-add 前进 i × sizeof(Transform) 字节
      (define bone-ptr (ptr-add frame-poses (* i sizeof-transform)))
      (define pos (vector3 (transform-trans-x bone-ptr)
                           (transform-trans-y bone-ptr)
                           (transform-trans-z bone-ptr)))
      (draw-cube pos 0.05 0.05 0.05 RED)

      ;; &bones[i] — ptr-add 前进 i × sizeof(BoneInfo) 字节
      (define bi-ptr (ptr-add bones-ptr (* i sizeof-boneinfo)))
      (define parent (bone-info-parent bi-ptr))
      (when (>= parent 0)
        ;; &pose[parent]
        (define parent-ptr (ptr-add frame-poses (* parent sizeof-transform)))
        (define p-pos (vector3 (transform-trans-x parent-ptr)
                               (transform-trans-y parent-ptr)
                               (transform-trans-z parent-ptr)))
        (draw-line-3d pos p-pos RED))))

  ;; 动画播放变量
  (define anim-index 0)
  (define anim-current-frame 0.0)

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
             (set! anim-index (modulo (sub1 anim-index) anim-count))])

      ;; 获取当前动画数据
      (let* ([anim (ptr-ref anims-ptr _model-animation-bytes anim-index)]
             [kf-count (list-ref anim anim-keyframe-count-index)]       ;; keyframeCount
             [anim-name (anim-name-from-list anim)])

        ;; 更新动画帧 (插值帧，使用 float)
        (set! anim-current-frame (+ anim-current-frame 1.0))
        (when (>= anim-current-frame kf-count)
          (set! anim-current-frame 0.0))
        (update-model-animation model anim anim-current-frame)

        ;; ---- Draw ----
        (begin-drawing)
        (clear-background RAYWHITE)

        (begin-mode-3d camera)

        ;; SPACE 按下 → 骨骼, 否则 → 模型
        (if (is-key-down KEY-SPACE)
            (draw-skeleton anim)
            (draw-model model position 1.0 WHITE))
        (draw-grid 10 1.0)

        (end-mode-3d)

        (draw-text (format "Current animation: ~a" anim-name) 10 10 20 LIGHTGRAY)
        (draw-text "Press SPACE to draw skeleton" 10 40 20 MAROON)
        (draw-text "(c) CesiumMan model by KhronosGroup"
                   (- (get-screen-width) 210) (- (get-screen-height) 20) 10 GRAY)

        (end-drawing)
        (loop))))

  ;; ============================================================
  ;; 清理
  ;; ============================================================

  (unload-model-animations anims-ptr anim-count)
  (unload-model model))

(close-window)
