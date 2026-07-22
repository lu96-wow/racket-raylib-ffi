#lang racket/base

;; raylib [shaders] example - simple mask (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_simple_mask.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref _float _int _pointer malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

;; 辅助: 替换 model 的 transform 矩阵
(define (model-set-transform model-list mat-list)
  (append mat-list (list-tail model-list 16)))

(init-window 800 450 "raylib [shaders] example - simple mask")

(define camera (camera3d 0.0 1.0 2.0  0.0 0.0 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

;; 创建三个模型
(define torus (load-model-from-mesh (gen-mesh-torus 0.3 1.0 16 32)))
(define model1 torus)

(define cube (load-model-from-mesh (gen-mesh-cube 0.8 0.8 0.8)))
(define model2 cube)

(define sphere (load-model-from-mesh (gen-mesh-sphere 1.0 16 16)))
(define model3 sphere)

;; 加载着色器和纹理
(define shader (load-shader #f (res (format "shaders/glsl~a/mask.fs" GLSL-VERSION))))

(define tex-diffuse (load-texture (res "plasma.png")))
(define tex-mask (load-texture (res "mask.png")))

;; 设置材质纹理和着色器
(let ([mats1 (model-materials model1)]
      [mats2 (model-materials model2)])
  ;; 设置 diffuse 纹理
  (set-material-texture mats1 MATERIAL-MAP-DIFFUSE tex-diffuse)
  (set-material-texture mats2 MATERIAL-MAP-DIFFUSE tex-diffuse)
  ;; 设置 emission 纹理 (用作 mask)
  (set-material-texture mats1 MATERIAL-MAP-EMISSION tex-mask)
  (set-material-texture mats2 MATERIAL-MAP-EMISSION tex-mask)
  ;; 设置着色器
  (set-material-shader mats1 shader)
  (set-material-shader mats2 shader))

;; 设置 shader.locs[SHADER_LOC_MAP_EMISSION] = "mask" uniform location
(let ([locs-ptr (shader-list-locs shader)]  ;; shader 是 list (id pad locs)
      [mask-loc (get-shader-location shader "mask")])
  (ptr-set! locs-ptr _int SHADER-LOC-MAP-EMISSION mask-loc))

(define shader-frame-loc (get-shader-location shader "frame"))
(define frames-counter 0)

;; 旋转角向量
(define rotation (malloc _float 3 'atomic))
(ptr-set! rotation _float 0 0.0) (ptr-set! rotation _float 1 0.0) (ptr-set! rotation _float 2 0.0)

(define frame-buf (malloc _int 1 'atomic))

(disable-cursor)
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-FIRST-PERSON)

    (set! frames-counter (+ frames-counter 1))
    (ptr-set! rotation _float 0 (+ (ptr-ref rotation _float 0) 0.01))
    (ptr-set! rotation _float 1 (+ (ptr-ref rotation _float 1) 0.005))
    (ptr-set! rotation _float 2 (- (ptr-ref rotation _float 2) 0.0025))

    ;; 更新着色器 uniform
    (ptr-set! frame-buf _int 0 frames-counter)
    (set-shader-value shader shader-frame-loc frame-buf SHADER-UNIFORM-INT)

    ;; 更新 model1 的 transform
    (set! model1 (model-set-transform model1 (matrix-rotate-xyz rotation)))

    (begin-drawing)
    (clear-background DARKBLUE)
    (begin-mode-3d camera)

    (draw-model model1 (vector3 0.5 0.0 0.0) 1.0 WHITE)
    (draw-model-ex model2 (vector3 -0.5 0.0 0.0)
                   (vector3 1.0 1.0 0.0) 50.0 (vector3 1.0 1.0 1.0) WHITE)
    (draw-model model3 (vector3 0.0 0.0 -1.5) 1.0 WHITE)
    (draw-grid 10 1.0)

    (end-mode-3d)

    (draw-rectangle 16 698 (+ (measure-text (format "Frame: ~a" frames-counter) 20) 8) 42 BLUE)
    (draw-text (format "Frame: ~a" frames-counter) 20 700 20 WHITE)
    (draw-fps 10 10)

    (end-drawing)
    (loop)))

(unload-model torus) (unload-model cube) (unload-model sphere)
(unload-texture tex-diffuse) (unload-texture tex-mask)
(unload-shader shader)
(close-window)
