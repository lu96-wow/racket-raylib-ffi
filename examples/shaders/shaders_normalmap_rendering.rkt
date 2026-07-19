#lang racket/base

;; raylib [shaders] example - normalmap rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_normalmap_rendering.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref ptr-add _float _int _pointer _uint malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

;; ============================================================
;; 辅助
;; ============================================================

;; 获取 material 中某个 map 的 Texture2D 指针 (用于 GenTextureMipmaps)
(define (material-map-texture-ptr material-ptr map-index)
  (let ([maps-ptr (ptr-ref material-ptr _pointer 2)])  ;; offsetof(Material,maps)=16
    (ptr-add maps-ptr (* map-index 28))))              ;; sizeof(MaterialMap)=28

;; 纯 Racket: Vector3 加法
(define (v3-add a-x a-y a-z b-x b-y b-z)
  (values (+ a-x b-x) (+ a-y b-y) (+ a-z b-z)))

;; 纯 Racket: Vector3 归一化
(define (v3-normalize x y z)
  (let ([len (sqrt (+ (* x x) (* y y) (* z z)))])
    (if (= len 0.0)
        (values 0.0 0.0 0.0)
        (values (/ x len) (/ y len) (/ z len)))))

;; 纯 Racket: Vector3 缩放
(define (v3-scale x y z s)
  (values (* x s) (* y s) (* z s)))

;; ============================================================
;; 初始化
;; ============================================================

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window 800 450 "raylib [shaders] example - normalmap rendering")

(define camera (camera3d 0.0 2.0 -4.0  0.0 0.0 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

;; 加载 normalmap 着色器
(define shader (load-shader (res (format "shaders/glsl~a/normalmap.vs" GLSL-VERSION))
                            (res (format "shaders/glsl~a/normalmap.fs" GLSL-VERSION))))

;; 设置 shader.locs
(let ([locs-ptr (caddr shader)])
  (ptr-set! locs-ptr _int SHADER-LOC-MAP-NORMAL (get-shader-location shader "normalMap"))
  (ptr-set! locs-ptr _int SHADER-LOC-VECTOR-VIEW (get-shader-location shader "viewPos")))

(define light-pos-x 0.0)
(define light-pos-y 1.0)
(define light-pos-z 0.0)
(define light-pos-loc (get-shader-location shader "lightPos"))

;; 加载 plane 模型
(define plane (load-model (res "models/plane.glb")))
(define mats-ptr (list-ref plane 19))

;; 设置材质着色器和纹理
(set-material-shader mats-ptr shader)

(define tex-diffuse (load-texture (res "tiles_diffuse.png")))
(define tex-normal  (load-texture (res "tiles_normal.png")))
(set-material-texture mats-ptr MATERIAL-MAP-DIFFUSE tex-diffuse)
(set-material-texture mats-ptr MATERIAL-MAP-NORMAL  tex-normal)

;; 生成 mipmaps 和三线性过滤
(gen-texture-mipmaps (material-map-texture-ptr mats-ptr MATERIAL-MAP-DIFFUSE))
(gen-texture-mipmaps (material-map-texture-ptr mats-ptr MATERIAL-MAP-NORMAL))
(set-texture-filter tex-diffuse TEXTURE-FILTER-TRILINEAR)
(set-texture-filter tex-normal  TEXTURE-FILTER-TRILINEAR)

;; specular exponent
(define specular-exponent 8.0)
(define specular-exponent-loc (get-shader-location shader "specularExponent"))

;; normal map 开关
(define use-normal-map 1)
(define use-normal-map-loc (get-shader-location shader "useNormalMap"))

;; 预分配缓冲区
(define light-pos-buf (malloc _float 3 'atomic))
(define cam-pos-buf   (malloc _float 3 'atomic))
(define float-buf     (malloc _float 1 'atomic))
(define int-buf       (malloc _int   1 'atomic))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    ;; Update
    ;; WASD 移动灯光
    (define-values (dir-x dir-y dir-z)
      (let ([dx (if (is-key-down KEY-D) -1.0 (if (is-key-down KEY-A) 1.0 0.0))]
            [dz (if (is-key-down KEY-W) 1.0  (if (is-key-down KEY-S) -1.0 0.0))])
        (v3-normalize dx 0.0 dz)))

    (let*-values ([(sx sy sz) (v3-scale dir-x dir-y dir-z (* (get-frame-time) 3.0))]
                  [(nx ny nz) (v3-add light-pos-x light-pos-y light-pos-z sx sy sz)])
      (set! light-pos-x nx) (set! light-pos-y ny) (set! light-pos-z nz))

    ;; 上下键调整 shininess
    (when (is-key-down KEY-UP)
      (set! specular-exponent (clamp (+ specular-exponent (* 40.0 (get-frame-time))) 2.0 128.0)))
    (when (is-key-down KEY-DOWN)
      (set! specular-exponent (clamp (- specular-exponent (* 40.0 (get-frame-time))) 2.0 128.0)))

    ;; N 切换 normal map
    (when (is-key-pressed KEY-N)
      (set! use-normal-map (if (= use-normal-map 1) 0 1)))

    ;; 旋转 plane
    ;; plane.transform = MatrixRotateY(GetTime() * 0.5)
    (define rotated-plane (append (matrix-rotate-y (* (get-time) 0.5))
                                  (list-tail plane 16)))

    ;; 更新 shader uniforms
    (ptr-set! light-pos-buf _float 0 light-pos-x)
    (ptr-set! light-pos-buf _float 1 light-pos-y)
    (ptr-set! light-pos-buf _float 2 light-pos-z)
    (set-shader-value shader light-pos-loc light-pos-buf SHADER-UNIFORM-VEC3)

    (ptr-set! cam-pos-buf _float 0 (camera3d-pos-x camera))
    (ptr-set! cam-pos-buf _float 1 (camera3d-pos-y camera))
    (ptr-set! cam-pos-buf _float 2 (camera3d-pos-z camera))
    (set-shader-value shader
      (ptr-ref (caddr shader) _int SHADER-LOC-VECTOR-VIEW)
      cam-pos-buf SHADER-UNIFORM-VEC3)

    (ptr-set! float-buf _float 0 specular-exponent)
    (set-shader-value shader specular-exponent-loc float-buf SHADER-UNIFORM-FLOAT)

    (ptr-set! int-buf _int 0 use-normal-map)
    (set-shader-value shader use-normal-map-loc int-buf SHADER-UNIFORM-INT)

    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (begin-shader-mode shader)
    (draw-model rotated-plane (vector3 0.0 0.0 0.0) 2.0 WHITE)
    (end-shader-mode)
    (draw-sphere-wires (vector3 light-pos-x light-pos-y light-pos-z) 0.2 8 8 ORANGE)
    (end-mode-3d)

    (define text-color (if (= use-normal-map 1) DARKGREEN RED))
    (draw-text (format "Use key [N] to toggle normal map: ~a"
                       (if (= use-normal-map 1) "On" "Off"))
               10 10 10 text-color)
    (draw-text "Use keys [W][A][S][D] to move the light" 10 34 10 BLACK)
    (draw-text "Use keys [Up][Down] to change specular exponent" 10 58 10 BLACK)
    (draw-text (string-append "Specular Exponent: " (real->decimal-string specular-exponent 2)) 10 82 10 BLUE)
    (draw-fps (- 800 90) 10)
    (end-drawing)
    (loop)))

(unload-shader shader)
(unload-model plane)
(close-window)
