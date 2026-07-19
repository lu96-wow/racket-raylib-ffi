#lang racket/base

;; raylib [models] example - loading vox (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_loading_vox.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         (only-in ffi/unsafe malloc))

;; ============================================================
;; 常量
;; ============================================================

(define MAX-VOX-FILES 4)
(define GLSL-VERSION 330)
(define LIGHT-POINT 1)
(define MAX-LIGHTS 4)

;; MatrixTranslate — 列优先
;; C Matrix 字段顺序: m0,m4,m8,m12, m1,m5,m9,m13, m2,m6,m10,m14, m3,m7,m11,m15
;; _list-struct 按此顺序读写, 因此 list 也必须按此顺序构造!
(define (matrix-translate x y z)
  (list 1.0 0.0 0.0 x     ; m0,m4,m8,m12
        0.0 1.0 0.0 y     ; m1,m5,m9,m13
        0.0 0.0 1.0 z     ; m2,m6,m10,m14
        0.0 0.0 0.0 1.0)) ; m3,m7,m11,m15

;; 修改 model 的 transform (替换前 16 个列表元素)
(define (set-model-transform model-list mat-list)
  (append mat-list (list-tail model-list 16)))

;; ============================================================
;; 光照辅助 — 复用 buffer
;; ============================================================

(define _ibuf (malloc _int 1 'atomic))
(define _fbuf3 (malloc _float 3 'atomic))
(define _fbuf4 (malloc _float 4 'atomic))

(define (light-locs idx shader)
  (vector (get-shader-location shader (format "lights[~a].enabled" idx))
          (get-shader-location shader (format "lights[~a].type" idx))
          (get-shader-location shader (format "lights[~a].position" idx))
          (get-shader-location shader (format "lights[~a].target" idx))
          (get-shader-location shader (format "lights[~a].color" idx))))

(define (set-light! locs type px py pz tx ty tz cr cg cb ca shader)
  (ptr-set! _ibuf _int 0 1)
  (set-shader-value shader (vector-ref locs 0) _ibuf SHADER-UNIFORM-INT)
  (ptr-set! _ibuf _int 0 type)
  (set-shader-value shader (vector-ref locs 1) _ibuf SHADER-UNIFORM-INT)
  (ptr-set! _fbuf3 _float 0 px) (ptr-set! _fbuf3 _float 1 py) (ptr-set! _fbuf3 _float 2 pz)
  (set-shader-value shader (vector-ref locs 2) _fbuf3 SHADER-UNIFORM-VEC3)
  (ptr-set! _fbuf3 _float 0 tx) (ptr-set! _fbuf3 _float 1 ty) (ptr-set! _fbuf3 _float 2 tz)
  (set-shader-value shader (vector-ref locs 3) _fbuf3 SHADER-UNIFORM-VEC3)
  (ptr-set! _fbuf4 _float 0 (/ cr 255.0)) (ptr-set! _fbuf4 _float 1 (/ cg 255.0))
  (ptr-set! _fbuf4 _float 2 (/ cb 255.0)) (ptr-set! _fbuf4 _float 3 (/ ca 255.0))
  (set-shader-value shader (vector-ref locs 4) _fbuf4 SHADER-UNIFORM-VEC4))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(define vox-file-names
  (vector
   (res "models/vox/chr_knight.vox")
   (res "models/vox/chr_sword.vox")
   (res "models/vox/monu9.vox")
   (res "models/vox/fez.vox")))

(init-window screen-width screen-height
  "raylib [models] example - loading vox")

(define camera (camera3d 10.0 10.0 10.0  0.0 0.0 0.0  0.0 1.0 0.0
                         45.0 CAMERA-PERSPECTIVE))

;; 加载 VOX 文件并居中
(define models (make-vector MAX-VOX-FILES #f))
(for ([i (in-range MAX-VOX-FILES)])
  (let* ([m  (load-model (vector-ref vox-file-names i))]
         [bb (get-model-bounding-box m)]
         [cx (+ (list-ref bb 0) (/ (- (list-ref bb 3) (list-ref bb 0)) 2.0))]
         [cz (+ (list-ref bb 2) (/ (- (list-ref bb 5) (list-ref bb 2)) 2.0))]
         [mat (matrix-translate (- cx) 0.0 (- cz))])
    (vector-set! models i (set-model-transform m mat))))

(define current-model 0)
(define modelpos (vector3 0.0 0.0 0.0))

;; 加载 voxel lighting 着色器
(define shader
  (load-shader
   (res (format "shaders/glsl~a/voxel_lighting.vs" GLSL-VERSION))
   (res (format "shaders/glsl~a/voxel_lighting.fs" GLSL-VERSION))))

;; shader.locs[SHADER_LOC_VECTOR_VIEW] = GetShaderLocation(shader, "viewPos")
;; 修复: caddr (shader 是 3 元素 list: id padding locs), * 4 (字节偏移)
(ptr-set! (caddr shader) _int SHADER-LOC-VECTOR-VIEW
          (get-shader-location shader "viewPos"))

;; Ambient light
(set-shader-value shader (get-shader-location shader "ambient")
                  (malloc-float-vec4 0.1 0.1 0.1 1.0) SHADER-UNIFORM-VEC4)

;; 给所有模型材质赋着色器
(for ([i (in-range MAX-VOX-FILES)])
  (let* ([m (vector-ref models i)]
         [mat-count (list-ref m 17)]
         [mats-ptr  (list-ref m 19)])
    (for ([j (in-range mat-count)])
      (set-material-shader (ptr-add mats-ptr (* j 40)) shader))))

;; 创建灯光
(define light-locs-vec
  (vector (light-locs 0 shader) (light-locs 1 shader)
          (light-locs 2 shader) (light-locs 3 shader)))

(define (update-lights!)
  (for ([i (in-range MAX-LIGHTS)])
    (set-light! (vector-ref light-locs-vec i) LIGHT-POINT
                (case i [(0) -20.0][(1) 20.0][(2) -20.0][(3) 20.0])
                (case i [(0) 20.0][(1) -20.0][(2) 20.0][(3) -20.0])
                (case i [(0) -20.0][(1) 20.0][(2) 20.0][(3) -20.0])
                0.0 0.0 0.0  130 130 130 255  shader)))
(update-lights!)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(define camerarot-x 0.0)
(define camerarot-y 0.0)

(let loop ()
  (unless (window-should-close?)
    ;; Mouse rotation
    (if (is-mouse-button-down MOUSE-BUTTON-MIDDLE)
        (let ([md (get-mouse-delta)])
          (set! camerarot-x (* (ptr-ref md _float 0) 0.05))
          (set! camerarot-y (* (ptr-ref md _float 1) 0.05)))
        (begin (set! camerarot-x 0.0) (set! camerarot-y 0.0)))

    (update-camera-pro camera
      (vector3 (* 0.1 (- (if (or (is-key-down KEY-W) (is-key-down KEY-UP)) 1.0 0.0)
                         (if (or (is-key-down KEY-S) (is-key-down KEY-DOWN)) 1.0 0.0)))
               (* 0.1 (- (if (or (is-key-down KEY-D) (is-key-down KEY-RIGHT)) 1.0 0.0)
                         (if (or (is-key-down KEY-A) (is-key-down KEY-LEFT)) 1.0 0.0)))
               0.0)
      (vector3 camerarot-x camerarot-y 0.0)
      (* (get-mouse-wheel-move) -2.0))

    (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
      (set! current-model (modulo (add1 current-model) MAX-VOX-FILES)))

    ;; 更新 viewPos
    (ptr-set! _fbuf3 _float 0 (ptr-ref camera _float 0))
    (ptr-set! _fbuf3 _float 1 (ptr-ref camera _float 1))
    (ptr-set! _fbuf3 _float 2 (ptr-ref camera _float 2))
    (set-shader-value shader (ptr-ref (caddr shader) _int SHADER-LOC-VECTOR-VIEW)
                      _fbuf3 SHADER-UNIFORM-VEC3)

    (update-lights!)

    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (draw-model (vector-ref models current-model) modelpos 1.0 WHITE)
    (draw-grid 10 1.0)
    (end-mode-3d)

    (draw-rectangle 10 40 340 70 (fade SKYBLUE 0.5))
    (draw-rectangle-lines 10 40 340 70 (fade DARKBLUE 0.5))
    (draw-text "- MOUSE LEFT BUTTON: CYCLE VOX MODELS" 20 50 10 BLUE)
    (draw-text "- MOUSE MIDDLE BUTTON: ZOOM OR ROTATE CAMERA" 20 70 10 BLUE)
    (draw-text "- UP-DOWN-LEFT-RIGHT KEYS: MOVE CAMERA" 20 90 10 BLUE)
    (draw-text (format "VOX model file: ~a"
                 (get-file-name (vector-ref vox-file-names current-model)))
               10 10 20 GRAY)
    (end-drawing)
    (loop)))

;; 清理
(for ([i (in-range MAX-VOX-FILES)])
  (unload-model (vector-ref models i)))
(close-window)
