#lang racket/base

;; raylib [shaders] example - lightmap rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_lightmap_rendering.c
;;
;; 功能: 使用第二层纹理坐标 (texcoords2) 做 lightmap 渲染
;; 实现: 手动创建 texcoords2 VBO 并绑定到 VAO，DrawMesh 直接绘制

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! _float malloc ptr-ref _uint _int))

(define GLSL-VERSION 330)
(define MAP-SIZE 16)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window 800 450 "raylib [shaders] example - lightmap rendering")

;; camera
(define camera (camera3d 4.0 6.0 8.0  0.0 0.0 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

;; create plane mesh (4 vertices for 1×1 resolution)
(define mesh (gen-mesh-plane (exact->inexact MAP-SIZE) (exact->inexact MAP-SIZE) 1 1))

;; manually set up texcoords2 VBO (GenMeshPlane doesn't generate texcoords2)
(define vertex-count (mesh-vertex-count mesh))
(define tc2 (malloc _float (* vertex-count 2) 'atomic))
;; fill texcoords2: [0,0, 1,0, 0,1, 1,1]
(ptr-set! tc2 _float 0 0.0)  (ptr-set! tc2 _float 1 0.0)
(ptr-set! tc2 _float 2 1.0)  (ptr-set! tc2 _float 3 0.0)
(ptr-set! tc2 _float 4 0.0)  (ptr-set! tc2 _float 5 1.0)
(ptr-set! tc2 _float 6 1.0)  (ptr-set! tc2 _float 7 1.0)

;; upload texcoords2 as VBO and store in mesh.vboId[SHADER_LOC_VERTEX_TEXCOORD02]
(define tc2-vbo (rl-load-vertex-buffer tc2 (* vertex-count 2 4) #f))
(define vbo-id-ptr (mesh-vbo-id mesh))
(ptr-set! vbo-id-ptr _uint SHADER-LOC-VERTEX-TEXCOORD02 tc2-vbo)

;; configure vertex attribute 5 for texcoords2
(rl-enable-vertex-array (mesh-vao-id mesh))
(rl-set-vertex-attribute 5 2 RL-FLOAT 0 0 0)
(rl-enable-vertex-attribute 5)
(rl-disable-vertex-array)

;; load shader and textures
(define shader (load-shader (res (format "shaders/glsl~a/lightmap.vs" GLSL-VERSION))
                            (res (format "shaders/glsl~a/lightmap.fs" GLSL-VERSION))))
(define texture (load-texture (res "cubicmap_atlas.png")))
(define light (load-texture (res "spark_flame.png")))

;; helper: call GenTextureMipmaps on a texture list (creates temp cpointer, reads back)
(define (gen-texture-mipmaps* tex-list)
  (define ptr (malloc 20 'atomic))
  (ptr-set! ptr _uint 0 (texture-id tex-list))
  (ptr-set! ptr _int 1 (texture-width tex-list))
  (ptr-set! ptr _int 2 (texture-height tex-list))
  (ptr-set! ptr _int 3 (texture-mipmaps tex-list))
  (ptr-set! ptr _int 4 (texture-format tex-list))
  (gen-texture-mipmaps ptr)
  (list (ptr-ref ptr _uint 0) (ptr-ref ptr _int 1) (ptr-ref ptr _int 2)
        (ptr-ref ptr _int 3) (ptr-ref ptr _int 4)))

(set! texture (gen-texture-mipmaps* texture))
(set-texture-filter texture TEXTURE-FILTER-TRILINEAR)

;; create 16×16 lightmap render texture
(define lightmap (load-render-texture MAP-SIZE MAP-SIZE))

;; draw lightmap content
(begin-texture-mode lightmap)
(clear-background BLACK)
(begin-blend-mode BLEND-ADDITIVE)
;; red spot — full coverage
(draw-texture-pro
 light
 (rectangle 0.0 0.0 (exact->inexact (texture-width light)) (exact->inexact (texture-height light)))
 (rectangle 0.0 0.0 (* 2.0 MAP-SIZE) (* 2.0 MAP-SIZE))
 (vector2 (exact->inexact MAP-SIZE) (exact->inexact MAP-SIZE)) 0.0 RED)
;; blue spot
(draw-texture-pro
 light
 (rectangle 0.0 0.0 (exact->inexact (texture-width light)) (exact->inexact (texture-height light)))
 (rectangle (* MAP-SIZE 0.8) (/ MAP-SIZE 2.0) (* 2.0 MAP-SIZE) (* 2.0 MAP-SIZE))
 (vector2 (exact->inexact MAP-SIZE) (exact->inexact MAP-SIZE)) 0.0 BLUE)
;; green spot
(draw-texture-pro
 light
 (rectangle 0.0 0.0 (exact->inexact (texture-width light)) (exact->inexact (texture-height light)))
 (rectangle (* MAP-SIZE 0.8) (* MAP-SIZE 0.8) (exact->inexact MAP-SIZE) (exact->inexact MAP-SIZE))
 (vector2 (/ MAP-SIZE 2.0) (/ MAP-SIZE 2.0)) 0.0 GREEN)
(begin-blend-mode BLEND-ALPHA)
(end-texture-mode)

;; extract lightmap texture (indices 1-5 of rendertexture) and set mipmaps
(define lm-tex (gen-texture-mipmaps* (list (render-texture-tex-id lightmap)
                                           (render-texture-tex-width lightmap)
                                           (render-texture-tex-height lightmap)
                                           (render-texture-tex-mipmaps lightmap)
                                           (render-texture-tex-format lightmap))))
(set-texture-filter lm-tex TEXTURE-FILTER-TRILINEAR)

;; set up material
(define mat-ptr (load-material-default))
(set-material-shader mat-ptr shader)
(set-material-texture mat-ptr MATERIAL-MAP-ALBEDO texture)
(set-material-texture mat-ptr MATERIAL-MAP-METALNESS lm-tex)
(define mat-list (material-ptr->list mat-ptr))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-ORBITAL)

    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 3D scene
    (begin-mode-3d camera)
    (draw-mesh mesh mat-list (matrix-identity))
    (end-mode-3d)

    ;; lightmap preview (flip Y because RenderTexture is upside-down)
    (draw-texture-pro
     lm-tex
     (rectangle 0.0 0.0 (exact->inexact (- MAP-SIZE)) (exact->inexact (- MAP-SIZE)))
     (rectangle (- (get-render-width) (* MAP-SIZE 8) 10) 10.0 (* MAP-SIZE 8.0) (* MAP-SIZE 8.0))
     (vector2 0.0 0.0) 0.0 WHITE)

    (draw-text (format "LIGHTMAP: ~ax~a pixels" MAP-SIZE MAP-SIZE)
               (- (get-render-width) 130) (+ 20 (* MAP-SIZE 8)) 10 GREEN)
    (draw-fps 10 10)

    (end-drawing)
    (loop)))

(close-window)
