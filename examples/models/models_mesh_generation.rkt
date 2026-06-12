#lang racket/base

;; raylib [models] example - mesh generation (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_mesh_generation.c
;; 注意: 相比 C 版省略了 GenMeshCustom()（直接操作 mesh 内存），展示 8 种几何体。

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define NUM-MODELS 8)

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [models] example - mesh generation")

;; 生成棋盘格纹理 (2x2, RED/GREEN 交替)
(define checked (gen-image-checked 2 2 1 1 RED GREEN))
(define texture (load-texture-from-image checked))
(unload-image checked)

;; 生成 8 种程序化几何体模型
;; gen-mesh-* 返回 Mesh 值 (list), load-model-from-mesh 接收 Mesh 值 -> Model
(define models
  (list (load-model-from-mesh (gen-mesh-plane 2.0 2.0 4 3))
        (load-model-from-mesh (gen-mesh-cube 2.0 1.0 2.0))
        (load-model-from-mesh (gen-mesh-sphere 2.0 32 32))
        (load-model-from-mesh (gen-mesh-hemi-sphere 2.0 16 16))
        (load-model-from-mesh (gen-mesh-cylinder 1.0 2.0 16))
        (load-model-from-mesh (gen-mesh-torus 0.25 4.0 16 32))
        (load-model-from-mesh (gen-mesh-knot 1.0 2.0 16 128))
        (load-model-from-mesh (gen-mesh-poly 5 2.0))))

;; 给所有模型设置相同纹理
;; Model 是 _list-struct 返回的 list，第 19 号元素是 materials 指针
(for ([m (in-list models)])
  (set-material-texture (list-ref m 19) MATERIAL-MAP-DIFFUSE texture))

;; 相机
(define camera (camera3d 5.0 5.0 5.0
                         0.0 0.0 0.0
                         0.0 1.0 0.0
                         45.0 CAMERA-PERSPECTIVE))

(define position (vector3 0.0 0.0 0.0))
(define current-model 0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (update-camera camera CAMERA-ORBITAL)

    ;; 鼠标左键 / 方向键切换模型
    (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
      (set! current-model (modulo (add1 current-model) NUM-MODELS)))

    (cond [(is-key-pressed KEY-RIGHT)
           (set! current-model
                 (if (>= (add1 current-model) NUM-MODELS) 0 (add1 current-model)))]
          [(is-key-pressed KEY-LEFT)
           (set! current-model
                 (if (< (sub1 current-model) 0) (sub1 NUM-MODELS) (sub1 current-model)))])

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)
    (draw-model (list-ref models current-model) position 1.0 WHITE)
    (draw-grid 10 1.0)
    (end-mode-3d)

    ;; UI 面板 + 模型名称
    (draw-rectangle 30 400 310 30 (fade SKYBLUE 0.5))
    (draw-rectangle-lines 30 400 310 30 (fade DARKBLUE 0.5))
    (draw-text "MOUSE LEFT BUTTON to CYCLE PROCEDURAL MODELS" 40 410 10 BLUE)

    (case current-model
      [(0) (draw-text "PLANE" 680 10 20 DARKBLUE)]
      [(1) (draw-text "CUBE" 680 10 20 DARKBLUE)]
      [(2) (draw-text "SPHERE" 680 10 20 DARKBLUE)]
      [(3) (draw-text "HEMISPHERE" 640 10 20 DARKBLUE)]
      [(4) (draw-text "CYLINDER" 680 10 20 DARKBLUE)]
      [(5) (draw-text "TORUS" 680 10 20 DARKBLUE)]
      [(6) (draw-text "KNOT" 680 10 20 DARKBLUE)]
      [(7) (draw-text "POLY" 680 10 20 DARKBLUE)])

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture texture)
(for ([m (in-list models)]) (unload-model m))
(close-window)
