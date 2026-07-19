#lang racket/base

;; raylib [shaders] example - depth rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_depth_rendering.c
;;
;; 功能: 渲染场景到深度纹理，再通过 shader 可视化深度图

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref _uint _int _float malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

;; helper: extract texture from render texture
(define (rt->texture rt)
  (list (list-ref rt 1) (list-ref rt 2) (list-ref rt 3) (list-ref rt 4) (list-ref rt 5)))

;; helper: extract depth texture from render texture
(define (rt->depth rt)
  (list (list-ref rt 6) (list-ref rt 7) (list-ref rt 8) (list-ref rt 9) (list-ref rt 10)))

;; helper: create a RenderTexture with writable depth texture
(define (load-render-texture-depth-tex width height)
  (define fbo-id (rl-load-framebuffer))
  (when (<= fbo-id 0)
    (error "Failed to create framebuffer"))
  (rl-enable-framebuffer fbo-id)
  (define tex-id (rl-load-texture #f width height PIXELFORMAT-UNCOMPRESSED-R8G8B8A8 1))
  (define dep-id (rl-load-texture-depth width height #f))
  (rl-framebuffer-attach fbo-id tex-id RL-ATTACHMENT-COLOR-CHANNEL0 RL-ATTACHMENT-TEXTURE2D 0)
  (rl-framebuffer-attach fbo-id dep-id RL-ATTACHMENT-DEPTH RL-ATTACHMENT-TEXTURE2D 0)
  (rl-framebuffer-complete fbo-id)
  (rl-disable-framebuffer)
  (list fbo-id tex-id width height 1 PIXELFORMAT-UNCOMPRESSED-R8G8B8A8 dep-id width height 1 19))

(define (unload-render-texture-depth-tex rt)
  (when (> (list-ref rt 0) 0)
    (rl-unload-texture (list-ref rt 1))
    (rl-unload-texture (list-ref rt 6))
    (rl-unload-framebuffer (list-ref rt 0))))

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height "raylib [shaders] example - depth rendering")

(define camera (camera3d 4.0 1.0 5.0  0.0 0.0 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))
(define target (load-render-texture-depth-tex screen-width screen-height))

(define depth-shader (load-shader #f (res (format "shaders/glsl~a/depth_render.fs" GLSL-VERSION))))
(define depth-loc (get-shader-location depth-shader "depthTexture"))
(define flip-loc (get-shader-location depth-shader "flipY"))
(define flip-buf (malloc _int 1 'atomic))
(ptr-set! flip-buf _int 0 1)
(set-shader-value depth-shader flip-loc flip-buf SHADER-UNIFORM-INT)

(define cube-model (load-model-from-mesh (gen-mesh-cube 1.0 1.0 1.0)))
(define floor-model (load-model-from-mesh (gen-mesh-plane 20.0 20.0 1 1)))

(disable-cursor)
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-FREE)

    ;; render 3D scene to render texture
    (begin-texture-mode target)
    (clear-background WHITE)
    (begin-mode-3d camera)
    (draw-model cube-model (vector3 0.0 0.0 0.0) 3.0 YELLOW)
    (draw-model floor-model (vector3 10.0 0.0 2.0) 2.0 RED)
    (end-mode-3d)
    (end-texture-mode)

    ;; draw depth visualization to screen
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-shader-mode depth-shader)
    (set-shader-value-texture depth-shader depth-loc (rt->depth target))
    (draw-texture (rt->depth target) 0 0 WHITE)
    (end-shader-mode)

    (draw-rectangle 10 10 320 93 (fade SKYBLUE 0.5))
    (draw-rectangle-lines 10 10 320 93 BLUE)
    (draw-text "Camera Controls:" 20 20 10 BLACK)
    (draw-text "- WASD to move" 40 40 10 DARKGRAY)
    (draw-text "- Mouse Wheel Pressed to Pan" 40 60 10 DARKGRAY)
    (draw-text "- Z to zoom to (0, 0, 0)" 40 80 10 DARKGRAY)

    (end-drawing)
    (loop)))

(unload-model cube-model)
(unload-model floor-model)
(unload-render-texture-depth-tex target)
(unload-shader depth-shader)
(close-window)
