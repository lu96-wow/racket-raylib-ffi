#lang racket/base

;; raylib [shaders] example - basic PBR (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_basic_pbr.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref ptr-add _float _int _uint _pointer malloc))

(define GLSL-VERSION 330)
(define MAX-LIGHTS 4)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

;; ============================================================
;; 灯光 — Light 用 vector 存储，enabled 独立管理
;; ============================================================

(define (create-light type pos-x pos-y pos-z tar-x tar-y tar-z
                      color intensity shader)
  (when (>= light-count MAX-LIGHTS)
    (error "create-light: max lights reached"))
  (define i light-count)
  (set! light-count (+ light-count 1))
  (define prefix (string-append "lights[" (number->string i) "]."))
  (vector
   type pos-x pos-y pos-z tar-x tar-y tar-z
   (/ (color-r color) 255.0) (/ (color-g color) 255.0)
   (/ (color-b color) 255.0) (/ (color-a color) 255.0)
   intensity
   (get-shader-location shader (string-append prefix "type"))
   (get-shader-location shader (string-append prefix "enabled"))
   (get-shader-location shader (string-append prefix "position"))
   (get-shader-location shader (string-append prefix "target"))
   (get-shader-location shader (string-append prefix "color"))
   (get-shader-location shader (string-append prefix "intensity"))))

(define (update-light shader enabled light)
  (let ([type        (vector-ref light 0)]
        [pos-x       (vector-ref light 1)]
        [pos-y       (vector-ref light 2)]
        [pos-z       (vector-ref light 3)]
        [tar-x       (vector-ref light 4)]
        [tar-y       (vector-ref light 5)]
        [tar-z       (vector-ref light 6)]
        [cr          (vector-ref light 7)]
        [cg          (vector-ref light 8)]
        [cb          (vector-ref light 9)]
        [ca          (vector-ref light 10)]
        [intensity   (vector-ref light 11)]
        [type-loc    (vector-ref light 12)]
        [enabled-loc (vector-ref light 13)]
        [pos-loc     (vector-ref light 14)]
        [target-loc  (vector-ref light 15)]
        [color-loc   (vector-ref light 16)]
        [intensity-loc (vector-ref light 17)]
        [i-buf (malloc _int 1 'atomic)]
        [f-buf (malloc _float 1 'atomic)]
        [v3-buf (malloc _float 3 'atomic)]
        [v4-buf (malloc _float 4 'atomic)])
    (ptr-set! i-buf _int 0 enabled)
    (set-shader-value shader enabled-loc i-buf SHADER-UNIFORM-INT)
    (ptr-set! i-buf _int 0 type)
    (set-shader-value shader type-loc i-buf SHADER-UNIFORM-INT)
    (ptr-set! v3-buf _float 0 (exact->inexact pos-x)) (ptr-set! v3-buf _float 1 (exact->inexact pos-y)) (ptr-set! v3-buf _float 2 (exact->inexact pos-z))
    (set-shader-value shader pos-loc v3-buf SHADER-UNIFORM-VEC3)
    (ptr-set! v3-buf _float 0 (exact->inexact tar-x)) (ptr-set! v3-buf _float 1 (exact->inexact tar-y)) (ptr-set! v3-buf _float 2 (exact->inexact tar-z))
    (set-shader-value shader target-loc v3-buf SHADER-UNIFORM-VEC3)
    (ptr-set! v4-buf _float 0 (exact->inexact cr)) (ptr-set! v4-buf _float 1 (exact->inexact cg))
    (ptr-set! v4-buf _float 2 (exact->inexact cb)) (ptr-set! v4-buf _float 3 (exact->inexact ca))
    (set-shader-value shader color-loc v4-buf SHADER-UNIFORM-VEC4)
    (ptr-set! f-buf _float 0 (exact->inexact intensity))
    (set-shader-value shader intensity-loc f-buf SHADER-UNIFORM-FLOAT)))

(define light-count 0)

;; ============================================================
;; 辅助: 设置 material 中 MaterialMap 的 color/value
;; ============================================================

(define (set-material-map-color! material-ptr map-index r g b a)
  (let* ([maps-ptr (ptr-ref material-ptr _pointer 2)]
         [map-ptr (ptr-add maps-ptr (* map-index 28))])
    (ptr-set! map-ptr _ubyte 20 r)
    (ptr-set! map-ptr _ubyte 21 g)
    (ptr-set! map-ptr _ubyte 22 b)
    (ptr-set! map-ptr _ubyte 23 a)))

(define (set-material-map-value! material-ptr map-index val)
  (let* ([maps-ptr (ptr-ref material-ptr _pointer 2)]
         [map-ptr (ptr-add maps-ptr (* map-index 28))])
    (ptr-set! map-ptr _float 6 (exact->inexact val))))

;; ============================================================
;; 初始化
;; ============================================================

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window 800 450 "raylib [shaders] example - basic pbr")

(define camera (camera3d 2.0 2.0 6.0  0.0 0.5 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

(define shader (load-shader (res (format "shaders/glsl~a/pbr.vs" GLSL-VERSION))
                            (res (format "shaders/glsl~a/pbr.fs" GLSL-VERSION))))

(let ([locs-ptr (shader-list-locs shader)])
  (ptr-set! locs-ptr _int SHADER-LOC-MAP-ALBEDO    (get-shader-location shader "albedoMap"))
  (ptr-set! locs-ptr _int SHADER-LOC-MAP-METALNESS (get-shader-location shader "mraMap"))
  (ptr-set! locs-ptr _int SHADER-LOC-MAP-NORMAL    (get-shader-location shader "normalMap"))
  (ptr-set! locs-ptr _int SHADER-LOC-MAP-EMISSION  (get-shader-location shader "emissiveMap"))
  (ptr-set! locs-ptr _int SHADER-LOC-COLOR-DIFFUSE (get-shader-location shader "albedoColor"))
  (ptr-set! locs-ptr _int SHADER-LOC-VECTOR-VIEW   (get-shader-location shader "viewPos")))

(let ([buf (malloc _int 1 'atomic)])
  (ptr-set! buf _int 0 MAX-LIGHTS)
  (set-shader-value shader (get-shader-location shader "numOfLights") buf SHADER-UNIFORM-INT))

;; 环境光
(let ([ai (malloc _float 1 'atomic)] [ac (malloc _float 3 'atomic)])
  (ptr-set! ai _float 0 0.02)
  (ptr-set! ac _float 0 (/ 26 255.0)) (ptr-set! ac _float 1 (/ 32 255.0)) (ptr-set! ac _float 2 (/ 135 255.0))
  (set-shader-value shader (get-shader-location shader "ambientColor") ac SHADER-UNIFORM-VEC3)
  (set-shader-value shader (get-shader-location shader "ambient") ai SHADER-UNIFORM-FLOAT))

(define metallic-value-loc     (get-shader-location shader "metallicValue"))
(define roughness-value-loc    (get-shader-location shader "roughnessValue"))
(define emissive-intensity-loc (get-shader-location shader "emissivePower"))
(define emissive-color-loc     (get-shader-location shader "emissiveColor"))
(define texture-tiling-loc     (get-shader-location shader "tiling"))

;; 加载 car 模型
(define car (load-model (res "models/old_car_new.glb")))
(define car-mats (list-ref car 19))
(set-material-shader car-mats shader)
(set-material-map-color! car-mats MATERIAL-MAP-ALBEDO 255 255 255 255)
(set-material-map-value! car-mats MATERIAL-MAP-METALNESS 1.0)
(set-material-map-value! car-mats MATERIAL-MAP-ROUGHNESS 0.0)
(set-material-map-value! car-mats MATERIAL-MAP-OCCLUSION 1.0)
(set-material-map-color! car-mats MATERIAL-MAP-EMISSION 255 162 0 255)
(set-material-texture car-mats MATERIAL-MAP-ALBEDO    (load-texture (res "old_car_d.png")))
(set-material-texture car-mats MATERIAL-MAP-METALNESS (load-texture (res "old_car_mra.png")))
(set-material-texture car-mats MATERIAL-MAP-NORMAL    (load-texture (res "old_car_n.png")))
(set-material-texture car-mats MATERIAL-MAP-EMISSION  (load-texture (res "old_car_e.png")))

;; 加载 floor 模型
(define floor (load-model (res "models/plane.glb")))
(define floor-mats (list-ref floor 19))
(set-material-shader floor-mats shader)
(set-material-map-color! floor-mats MATERIAL-MAP-ALBEDO 255 255 255 255)
(set-material-map-value! floor-mats MATERIAL-MAP-METALNESS 0.8)
(set-material-map-value! floor-mats MATERIAL-MAP-ROUGHNESS 0.1)
(set-material-map-value! floor-mats MATERIAL-MAP-OCCLUSION 1.0)
(set-material-map-color! floor-mats MATERIAL-MAP-EMISSION 0 0 0 255)
(set-material-texture floor-mats MATERIAL-MAP-ALBEDO    (load-texture (res "road_a.png")))
(set-material-texture floor-mats MATERIAL-MAP-METALNESS (load-texture (res "road_mra.png")))
(set-material-texture floor-mats MATERIAL-MAP-NORMAL    (load-texture (res "road_n.png")))

;; 创建灯光 + enabled 追踪
(define lights (make-vector MAX-LIGHTS))
(define lights-enabled (make-vector MAX-LIGHTS 1))
(vector-set! lights 0 (create-light 1 -1.0 1.0 -2.0 0.0 0.0 0.0 YELLOW 4.0 shader))
(vector-set! lights 1 (create-light 1  2.0 1.0  1.0 0.0 0.0 0.0 GREEN  3.3 shader))
(vector-set! lights 2 (create-light 1 -2.0 1.0  1.0 0.0 0.0 0.0 RED    8.3 shader))
(vector-set! lights 3 (create-light 1  1.0 1.0 -2.0 0.0 0.0 0.0 BLUE   2.0 shader))

;; 启用所有纹理贴图
(let ([buf (malloc _int 1 'atomic)])
  (ptr-set! buf _int 0 1)
  (set-shader-value shader (get-shader-location shader "useTexAlbedo")   buf SHADER-UNIFORM-INT)
  (set-shader-value shader (get-shader-location shader "useTexNormal")   buf SHADER-UNIFORM-INT)
  (set-shader-value shader (get-shader-location shader "useTexMRA")      buf SHADER-UNIFORM-INT)
  (set-shader-value shader (get-shader-location shader "useTexEmissive") buf SHADER-UNIFORM-INT))

;; 预分配缓冲区
(define cam-pos-buf (malloc _float 3 'atomic))
(define f2-buf      (malloc _float 2 'atomic))
(define f4-buf      (malloc _float 4 'atomic))
(define f1-buf      (malloc _float 1 'atomic))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-ORBITAL)

    (ptr-set! cam-pos-buf _float 0 (camera3d-pos-x camera))
    (ptr-set! cam-pos-buf _float 1 (camera3d-pos-y camera))
    (ptr-set! cam-pos-buf _float 2 (camera3d-pos-z camera))
    (set-shader-value shader (ptr-ref (shader-list-locs shader) _int SHADER-LOC-VECTOR-VIEW)
                      cam-pos-buf SHADER-UNIFORM-VEC3)

    ;; 切换灯光 (KEY 1-4)
    (when (is-key-pressed KEY-THREE)
      (vector-set! lights-enabled 2 (- 1 (vector-ref lights-enabled 2))))
    (when (is-key-pressed KEY-TWO)
      (vector-set! lights-enabled 1 (- 1 (vector-ref lights-enabled 1))))
    (when (is-key-pressed KEY-FOUR)
      (vector-set! lights-enabled 3 (- 1 (vector-ref lights-enabled 3))))
    (when (is-key-pressed KEY-ONE)
      (vector-set! lights-enabled 0 (- 1 (vector-ref lights-enabled 0))))

    ;; 更新灯光
    (for ([i (in-range MAX-LIGHTS)])
      (update-light shader (vector-ref lights-enabled i) (vector-ref lights i)))

    ;; Draw
    (begin-drawing)
    (clear-background BLACK)
    (begin-mode-3d camera)

    ;; 画 floor
    (ptr-set! f2-buf _float 0 0.5) (ptr-set! f2-buf _float 1 0.5)
    (set-shader-value shader texture-tiling-loc f2-buf SHADER-UNIFORM-VEC2)
    (ptr-set! f4-buf _float 0 0.0) (ptr-set! f4-buf _float 1 0.0)
    (ptr-set! f4-buf _float 2 0.0) (ptr-set! f4-buf _float 3 1.0)
    (set-shader-value shader emissive-color-loc f4-buf SHADER-UNIFORM-VEC4)
    (ptr-set! f1-buf _float 0 0.8)
    (set-shader-value shader metallic-value-loc f1-buf SHADER-UNIFORM-FLOAT)
    (ptr-set! f1-buf _float 0 0.1)
    (set-shader-value shader roughness-value-loc f1-buf SHADER-UNIFORM-FLOAT)
    (draw-model floor (vector3 0.0 0.0 0.0) 5.0 WHITE)

    ;; 画 car
    (ptr-set! f2-buf _float 0 0.5) (ptr-set! f2-buf _float 1 0.5)
    (set-shader-value shader texture-tiling-loc f2-buf SHADER-UNIFORM-VEC2)
    (ptr-set! f4-buf _float 0 1.0) (ptr-set! f4-buf _float 1 (/ 162.0 255.0))
    (ptr-set! f4-buf _float 2 0.0) (ptr-set! f4-buf _float 3 1.0)
    (set-shader-value shader emissive-color-loc f4-buf SHADER-UNIFORM-VEC4)
    (ptr-set! f1-buf _float 0 0.01)
    (set-shader-value shader emissive-intensity-loc f1-buf SHADER-UNIFORM-FLOAT)
    (ptr-set! f1-buf _float 0 1.0)
    (set-shader-value shader metallic-value-loc f1-buf SHADER-UNIFORM-FLOAT)
    (ptr-set! f1-buf _float 0 0.0)
    (set-shader-value shader roughness-value-loc f1-buf SHADER-UNIFORM-FLOAT)
    (draw-model car (vector3 0.0 0.0 0.0) 0.25 WHITE)

    ;; 画灯光球体
    (for ([i (in-range MAX-LIGHTS)])
      (let* ([light (vector-ref lights i)]
            [enabled (vector-ref lights-enabled i)]
            [px (vector-ref light 1)]
            [py (vector-ref light 2)]
            [pz (vector-ref light 3)]
            [cr (inexact->exact (round (* (vector-ref light 7) 255)))]
            [cg (inexact->exact (round (* (vector-ref light 8) 255)))]
            [cb (inexact->exact (round (* (vector-ref light 9) 255)))]
            [ca (inexact->exact (round (* (vector-ref light 10) 255)))]
            [lc (color cr cg cb ca)])
        (if (= enabled 1)
            (draw-sphere-ex (vector3 px py pz) 0.2 8 8 lc)
            (draw-sphere-wires (vector3 px py pz) 0.2 8 8 (color-alpha lc 0.3)))))

    (end-mode-3d)
    (draw-text "Toggle lights: [1][2][3][4]" 10 40 20 LIGHTGRAY)
    (draw-text "(c) Old Rusty Car model by Renafox (https://skfb.ly/LxRy)"
               (- 800 320) (- 450 20) 10 LIGHTGRAY)
    (draw-fps 10 10)
    (end-drawing)
    (loop)))

;; 清理
(set-material-shader car-mats (list 0 0 #f))
(unload-material car-mats)
(unload-model car)
(set-material-shader floor-mats (list 0 0 #f))
(unload-material floor-mats)
(unload-model floor)
(unload-shader shader)
(close-window)
