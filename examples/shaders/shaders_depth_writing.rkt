#lang racket/base

;; raylib [shaders] example - depth writing (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_depth_writing.c
;;
;; 功能: 使用可写 depth texture 创建自定义 FBO，shader 中反转深度值

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

;; helper: create a RenderTexture with writable depth texture
(define (load-render-texture-depth-tex width height)
  (define fbo-id (rl-load-framebuffer))
  (when (<= fbo-id 0)
    (error "Failed to create framebuffer"))

  (rl-enable-framebuffer fbo-id)

  ;; color texture
  (define tex-id (rl-load-texture #f width height PIXELFORMAT-UNCOMPRESSED-R8G8B8A8 1))
  ;; depth texture
  (define dep-id (rl-load-texture-depth width height #f))

  (rl-framebuffer-attach fbo-id tex-id RL-ATTACHMENT-COLOR-CHANNEL0 RL-ATTACHMENT-TEXTURE2D 0)
  (rl-framebuffer-attach fbo-id dep-id RL-ATTACHMENT-DEPTH RL-ATTACHMENT-TEXTURE2D 0)
  (rl-framebuffer-complete fbo-id)

  (rl-disable-framebuffer)

  ;; return as render texture list: (id tex-id tex-w tex-h tex-mip tex-fmt dep-id dep-w dep-h dep-mip dep-fmt)
  (list fbo-id tex-id width height 1 PIXELFORMAT-UNCOMPRESSED-R8G8B8A8 dep-id width height 1 19))

(define (unload-render-texture-depth-tex rt)
  (when (> (list-ref rt 0) 0)
    (rl-unload-texture (list-ref rt 1))
    (rl-unload-texture (list-ref rt 6))
    (rl-unload-framebuffer (list-ref rt 0))))

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height "raylib [shaders] example - depth writing")

(define camera (camera3d 2.0 2.0 3.0  0.0 0.5 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))
(define target (load-render-texture-depth-tex screen-width screen-height))
(define shader (load-shader #f (res (format "shaders/glsl~a/depth_write.fs" GLSL-VERSION))))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-ORBITAL)

    ;; draw 3D scene with depth-writing shader into custom render texture
    (begin-texture-mode target)
    (clear-background WHITE)
    (begin-mode-3d camera)
    (begin-shader-mode shader)
    (draw-cube-wires-v (vector3 0.0 0.5 1.0) (vector3 1.0 1.0 1.0) RED)
    (draw-cube-v (vector3 0.0 0.5 1.0) (vector3 1.0 1.0 1.0) PURPLE)
    (draw-cube-wires-v (vector3 0.0 0.5 -1.0) (vector3 1.0 1.0 1.0) DARKGREEN)
    (draw-cube-v (vector3 0.0 0.5 -1.0) (vector3 1.0 1.0 1.0) YELLOW)
    (draw-grid 10 1.0)
    (end-shader-mode)
    (end-mode-3d)
    (end-texture-mode)

    ;; draw render texture to screen
    (begin-drawing)
    (clear-background RAYWHITE)
    (draw-texture-rec (rt->texture target)
                      (rectangle 0 0 (exact->inexact screen-width) (exact->inexact (- screen-height)))
                      (vector2 0.0 0.0) WHITE)
    (draw-fps 10 10)
    (end-drawing)
    (loop)))

(unload-render-texture-depth-tex target)
(unload-shader shader)
(close-window)
