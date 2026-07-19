#lang racket/base

;; raylib [models] example - skybox rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_skybox_rendering.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         (only-in ffi/unsafe ptr-ref ptr-set! ptr-add _int _uint _pointer _float malloc memcpy))

;; ============================================================
;; 常量
;; ============================================================

(define GLSL-VERSION 330)
(define DEG2RAD (/ (* 4 (atan 1)) 180))

;; ============================================================
;; 辅助: HDR cubemap 生成 (GenTextureCubemap)
;; ============================================================

(define (gen-texture-cubemap shader panorama size format)
  (rl-disable-backface-culling)

  ;; Step 1: 创建 framebuffer + cubemap depth
  (define rbo (rl-load-texture-depth size size #t))
  (define cubemap-id (rl-load-texture-cubemap #f size format 1))

  (define fbo (rl-load-framebuffer))
  (rl-framebuffer-attach fbo rbo RL-ATTACHMENT-DEPTH RL-ATTACHMENT-RENDERBUFFER 0)
  (rl-framebuffer-attach fbo cubemap-id RL-ATTACHMENT-COLOR-CHANNEL0
                         RL-ATTACHMENT-CUBEMAP-POSITIVE-X 0)
  (rl-framebuffer-complete fbo)

  ;; Step 2: 渲染每个面
  (rl-enable-shader (car shader))  ;; shader 是 list (id pad locs)

  (define mat-proj (matrix-perspective (* 90.0 DEG2RAD) 1.0
                                       (rl-get-cull-distance-near)
                                       (rl-get-cull-distance-far)))
  (rl-set-uniform-matrix (ptr-ref (caddr shader) _int SHADER-LOC-MATRIX-PROJECTION)
                         (cpointer->buffer mat-proj))

  (define fbo-views
    (vector (matrix-look-at (vector3 0.0 0.0 0.0) (vector3  1.0  0.0  0.0) (vector3 0.0 -1.0  0.0))
            (matrix-look-at (vector3 0.0 0.0 0.0) (vector3 -1.0  0.0  0.0) (vector3 0.0 -1.0  0.0))
            (matrix-look-at (vector3 0.0 0.0 0.0) (vector3  0.0  1.0  0.0) (vector3 0.0  0.0  1.0))
            (matrix-look-at (vector3 0.0 0.0 0.0) (vector3  0.0 -1.0  0.0) (vector3 0.0  0.0 -1.0))
            (matrix-look-at (vector3 0.0 0.0 0.0) (vector3  0.0  0.0  1.0) (vector3 0.0 -1.0  0.0))
            (matrix-look-at (vector3 0.0 0.0 0.0) (vector3  0.0  0.0 -1.0) (vector3 0.0 -1.0  0.0))))

  (rl-viewport 0 0 size size)
  (rl-active-texture-slot 0)
  (rl-enable-texture (list-ref panorama 0))  ;; texture id is first element

  (for ([i 6])
    (rl-set-uniform-matrix (ptr-ref (caddr shader) _int SHADER-LOC-MATRIX-VIEW)
                           (cpointer->buffer (vector-ref fbo-views i)))
    (rl-framebuffer-attach fbo cubemap-id RL-ATTACHMENT-COLOR-CHANNEL0
                           (+ RL-ATTACHMENT-CUBEMAP-POSITIVE-X i) 0)
    (rl-enable-framebuffer fbo)
    (rl-clear-screen-buffers)
    (rl-load-draw-cube))

  ;; Step 3: 清理
  (rl-disable-shader)
  (rl-disable-texture)
  (rl-disable-framebuffer)
  (rl-unload-framebuffer fbo)
  (rl-viewport 0 0 (rl-get-framebuffer-width) (rl-get-framebuffer-height))
  (rl-enable-backface-culling)

  ;; 返回 TextureCubemap (id width height mipmaps format)
  (list cubemap-id size size 1 format))

;; ============================================================
;; 辅助: list → malloc'd float buffer (用于 rlSetUniformMatrix)
;; ============================================================

(define (cpointer->buffer lst)
  (define buf (malloc _float 16 'atomic))
  (for ([i (in-range 16)])
    (ptr-set! buf _float i (list-ref lst i)))
  buf)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window screen-width screen-height "raylib [models] example - skybox rendering")

(define camera (camera3d 1.0 1.0 1.0  4.0 1.0 4.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

;; 加载 skybox 模型
(define cube-mesh (gen-mesh-cube 1.0 1.0 1.0))
(define skybox (load-model-from-mesh cube-mesh))

(define use-HDR #f)

;; 加载 skybox 着色器
(define skybox-shader
  (load-shader (res (format "shaders/glsl~a/skybox.vs" GLSL-VERSION))
               (res (format "shaders/glsl~a/skybox.fs" GLSL-VERSION))))

;; 设置材质着色器
(let ([mats-ptr (list-ref skybox 19)])
  (set-material-shader mats-ptr skybox-shader)

  ;; 设置 uniform
  (let ([env-loc (get-shader-location skybox-shader "environmentMap")]
        [gamma-loc (get-shader-location skybox-shader "doGamma")]
        [vflip-loc (get-shader-location skybox-shader "vflipped")]
        [env-val (malloc _int 1 'atomic)]
        [gamma-val (malloc _int 1 'atomic)])
    (ptr-set! env-val _int 0 MATERIAL-MAP-CUBEMAP)
    (set-shader-value skybox-shader env-loc env-val SHADER-UNIFORM-INT)
    (ptr-set! gamma-val _int 0 (if use-HDR 1 0))
    (set-shader-value skybox-shader gamma-loc gamma-val SHADER-UNIFORM-INT)
    (set-shader-value skybox-shader vflip-loc gamma-val SHADER-UNIFORM-INT)))

;; 加载 cubemap 着色器 (用于 HDR 转换)
(define cubemap-shader
  (load-shader (res (format "shaders/glsl~a/cubemap.vs" GLSL-VERSION))
               (res (format "shaders/glsl~a/cubemap.fs" GLSL-VERSION))))

(let ([eq-loc (get-shader-location cubemap-shader "equirectangularMap")]
      [eq-val (malloc _int 1 'atomic)])
  (ptr-set! eq-val _int 0 0)
  (set-shader-value cubemap-shader eq-loc eq-val SHADER-UNIFORM-INT))

;; 加载 cubemap 纹理
(define skybox-file-name (make-string 256 #\nul))
(define cubemap-tex-id 0)

(if use-HDR
  (let* ([panorama (load-texture (res "dresden_square_2k.hdr"))]
         [cubemap-tex (gen-texture-cubemap cubemap-shader panorama 1024
                                              PIXELFORMAT-UNCOMPRESSED-R8G8B8A8)]
         ;; maps[MATERIAL_MAP_CUBEMAP].texture = cubemap-tex (20 bytes)
         [maps-ptr (ptr-ref (list-ref skybox 19) _pointer 2)]
         [map-ptr (ptr-add maps-ptr (* MATERIAL-MAP-CUBEMAP 28))])
    (ptr-set! map-ptr _uint 0 (list-ref cubemap-tex 0))  ;; texture.id
    (ptr-set! map-ptr _int 1 (list-ref cubemap-tex 1))   ;; texture.width
    (ptr-set! map-ptr _int 2 (list-ref cubemap-tex 2))   ;; texture.height
    (ptr-set! map-ptr _int 3 (list-ref cubemap-tex 3))   ;; texture.mipmaps
    (ptr-set! map-ptr _int 4 (list-ref cubemap-tex 4))  ;; texture.format
    (set! cubemap-tex-id (list-ref cubemap-tex 0))
    (unload-texture panorama))
  (let* ([img (load-image (res "skybox.png"))]
         [cubemap-tex (load-texture-cubemap img CUBEMAP-LAYOUT-AUTO-DETECT)]
         [maps-ptr (ptr-ref (list-ref skybox 19) _pointer 2)]
         [map-ptr (ptr-add maps-ptr (* MATERIAL-MAP-CUBEMAP 28))])
    (ptr-set! map-ptr _uint 0 (list-ref cubemap-tex 0))
    (ptr-set! map-ptr _int 1 (list-ref cubemap-tex 1))
    (ptr-set! map-ptr _int 2 (list-ref cubemap-tex 2))
    (ptr-set! map-ptr _int 3 (list-ref cubemap-tex 3))
    (ptr-set! map-ptr _int 4 (list-ref cubemap-tex 4))
    (set! cubemap-tex-id (list-ref cubemap-tex 0))
    (unload-image img)))

(disable-cursor)
(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)

    (update-camera camera CAMERA-FIRST-PERSON)

    ;; 拖放文件加载新 cubemap
    (when (is-file-dropped)
      (let ([files (load-dropped-files)])
        (when (= (length files) 1)
          (let ([fname (car files)])
            (when (is-file-extension fname ".png;.jpg;.hdr;.bmp;.tga")
              ;; 这里可以加载新纹理, 但为了简单先略过
              (void))))))

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)

    (rl-disable-backface-culling)
    (rl-disable-depth-mask)
    (draw-model skybox (vector3 0.0 0.0 0.0) 1.0 WHITE)
    (rl-enable-backface-culling)
    (rl-enable-depth-mask)

    (draw-grid 10 1.0)
    (end-mode-3d)

    (draw-fps 10 10)
    (end-drawing)
    (loop)))

;; 清理
(when (> cubemap-tex-id 0) (rl-unload-texture cubemap-tex-id))
(unload-shader skybox-shader)
(unload-model skybox)
(close-window)
