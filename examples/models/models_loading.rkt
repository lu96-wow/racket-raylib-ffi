#lang racket/base

;; raylib [models] example - loading (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_loading.c
;; 支持 OBJ/GLTF/GLB/VOX/IQM/M3D 格式的拖放加载

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         racket/string)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(define-runtime-path resource-dir "../../../examples/models/resources/")

(init-window screen-width screen-height
  "raylib [models] example - loading")

;; 定义 3D 相机
(define camera (camera3d 50.0 50.0 50.0
                         0.0  12.0 0.0
                         0.0  1.0  0.0
                         45.0 CAMERA-PERSPECTIVE))

;; 加载模型 & 纹理
(define castle-path (path->string (build-path resource-dir "models/obj/castle.obj")))
(define model (load-model castle-path))
(define texture (load-texture (path->string (build-path resource-dir "models/obj/castle_diffuse.png"))))
(set-material-texture (list-ref model 19) MATERIAL-MAP-DIFFUSE texture)

(define position (vector3 0.0 0.0 0.0))

;; 获取包围盒: model.meshes[0] = 从 meshes 指针读第 0 个 Mesh (按值)
(define meshes-ptr (list-ref model 18))
(define mesh0 (ptr-ref meshes-ptr _mesh-bytes 0))  ;; 读 Mesh 为 list
(define (list->bounding-box lst)
  (bounding-box (list-ref lst 0) (list-ref lst 1) (list-ref lst 2)
                (list-ref lst 3) (list-ref lst 4) (list-ref lst 5)))
(define bounds-cptr (list->bounding-box (get-mesh-bounding-box mesh0)))

(define selected #f)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    (update-camera camera CAMERA-ORBITAL)

    ;; 拖放加载新模型/纹理
    (when (is-file-dropped)
      (let ([paths (load-dropped-files)])
        (when (= (length paths) 1)
          (let ([path (car paths)])
            (cond
              ;; 检查是否为模型文件格式
              [(or (string-suffix? path ".obj")
                   (string-suffix? path ".gltf")
                   (string-suffix? path ".glb")
                   (string-suffix? path ".vox")
                   (string-suffix? path ".iqm")
                   (string-suffix? path ".m3d"))
               (unload-model model)
               (set! model (load-model path))
               (set-material-texture (list-ref model 19) MATERIAL-MAP-DIFFUSE texture)
               (set! meshes-ptr (list-ref model 18))
               (set! bounds-cptr (list->bounding-box
                                   (get-mesh-bounding-box
                                     (ptr-ref (list-ref model 18) _mesh-bytes 0))))
               ;; 调整相机位置以适配新模型
               (set-camera3d-pos-x! camera (+ (bounding-box-max-x bounds-cptr) 10.0))
               (set-camera3d-pos-y! camera (+ (bounding-box-max-y bounds-cptr) 10.0))
               (set-camera3d-pos-z! camera (+ (bounding-box-max-z bounds-cptr) 10.0))]
              ;; 检查是否为纹理文件格式
              [(string-suffix? path ".png")
               (unload-texture texture)
               (set! texture (load-texture path))
               (set-material-texture (list-ref model 19) MATERIAL-MAP-DIFFUSE texture)])))))

    ;; 鼠标点击选中模型
    (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
      (let* ([mouse-ray (get-screen-to-world-ray (get-mouse-position) camera)]
             [hit (get-ray-collision-box mouse-ray bounds-cptr)])
        ;; RayCollision: index 0 = hit (_stdbool)
        (set! selected (if (list-ref hit 0) (not selected) #f))))

    ;; ---- Draw ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)

    (draw-model model position 1.0 WHITE)
    (draw-grid 20 10.0)
    (when selected (draw-bounding-box bounds-cptr GREEN))

    (end-mode-3d)

    (draw-text "Drag & drop model to load mesh/texture." 10 (- (get-screen-height) 20) 10 DARKGRAY)
    (when selected (draw-text "MODEL SELECTED" (- (get-screen-width) 110) 10 10 GREEN))
    (draw-text "(c) Castle 3D model by Alberto Cano" (- screen-width 200) (- screen-height 20) 10 GRAY)

    (draw-fps 10 10)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture texture)
(unload-model model)
(close-window)
