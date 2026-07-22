#lang racket/base

;; raylib [shaders] example - hybrid rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_hybrid_rendering.c
;;
;; 功能: 在同一场景中混合 raymarching + 光栅化渲染，共用 depth texture

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         racket/math
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref _int _float malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

;; helper: extract texture from render texture
(define (rt->texture rt)
  (list (render-texture-tex-id rt) (render-texture-tex-width rt) (render-texture-tex-height rt) (render-texture-tex-mipmaps rt) (render-texture-tex-format rt)))

;; helper: create a RenderTexture with writable depth texture
(define (load-render-texture-depth-tex width height)
  (define fbo-id (rl-load-framebuffer))
  (when (<= fbo-id 0) (error "Failed to create framebuffer"))
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
    (rl-unload-texture (render-texture-tex-id rt))
    (rl-unload-texture (list-ref rt 6))
    (rl-unload-framebuffer (list-ref rt 0))))

;; pure Racket: Vector3 math helpers
(define (v3-sub ax ay az bx by bz)
  (values (- ax bx) (- ay by) (- az bz)))
(define (v3-scale x y z s)
  (values (* x s) (* y s) (* z s)))
(define (v3-normalize x y z)
  (define len (sqrt (+ (* x x) (* y y) (* z z))))
  (values (/ x len) (/ y len) (/ z len)))

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height "raylib [shaders] example - hybrid rendering")

;; raymarch shader (depth + color via raymarching)
(define shdr-raymarch (load-shader #f (res (format "shaders/glsl~a/hybrid_raymarch.fs" GLSL-VERSION))))
(define cam-pos-loc (get-shader-location shdr-raymarch "camPos"))
(define cam-dir-loc (get-shader-location shdr-raymarch "camDir"))
(define screen-center-loc (get-shader-location shdr-raymarch "screenCenter"))

;; rasterization shader with depth writing
(define shdr-raster (load-shader #f (res (format "shaders/glsl~a/hybrid_raster.fs" GLSL-VERSION))))

;; screen center
(define screen-center (malloc _float 2 'atomic))
(ptr-set! screen-center _float 0 (/ screen-width 2.0))
(ptr-set! screen-center _float 1 (/ screen-height 2.0))
(set-shader-value shdr-raymarch screen-center-loc screen-center SHADER-UNIFORM-VEC2)

;; custom render texture with depth
(define target (load-render-texture-depth-tex screen-width screen-height))

(define camera (camera3d 0.5 1.0 1.5  0.0 0.5 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))
(define cam-dist (/ 1.0 (tan (* 45.0 0.5 (/ pi 180.0)))))

(define cam-pos-buf (malloc _float 3 'atomic))
(define cam-dir-buf (malloc _float 3 'atomic))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera CAMERA-ORBITAL)

    ;; update raymarch camera position
    (ptr-set! cam-pos-buf _float 0 (camera3d-pos-x camera))
    (ptr-set! cam-pos-buf _float 1 (camera3d-pos-y camera))
    (ptr-set! cam-pos-buf _float 2 (camera3d-pos-z camera))
    (set-shader-value shdr-raymarch cam-pos-loc cam-pos-buf SHADER-UNIFORM-VEC3)

    ;; update raymarch camera direction (normalized direction × camDist)
    (let-values ([(dx dy dz) (v3-sub (camera3d-tar-x camera) (camera3d-tar-y camera) (camera3d-tar-z camera)
                                      (camera3d-pos-x camera) (camera3d-pos-y camera) (camera3d-pos-z camera))])
      (let-values ([(nx ny nz) (v3-normalize dx dy dz)])
        (let-values ([(sx sy sz) (v3-scale nx ny nz cam-dist)])
          (ptr-set! cam-dir-buf _float 0 sx)
          (ptr-set! cam-dir-buf _float 1 sy)
          (ptr-set! cam-dir-buf _float 2 sz)))
      (set-shader-value shdr-raymarch cam-dir-loc cam-dir-buf SHADER-UNIFORM-VEC3))

    ;; draw into custom render texture
    (begin-texture-mode target)
    (clear-background WHITE)

    ;; raymarch scene
    (rl-enable-depth-test)
    (begin-shader-mode shdr-raymarch)
    (draw-rectangle-rec (rectangle 0.0 0.0 (exact->inexact screen-width) (exact->inexact screen-height)) WHITE)
    (end-shader-mode)

    ;; rasterize scene
    (begin-mode-3d camera)
    (begin-shader-mode shdr-raster)
    (draw-cube-wires-v (vector3 0.0 0.5 1.0) (vector3 1.0 1.0 1.0) RED)
    (draw-cube-v (vector3 0.0 0.5 1.0) (vector3 1.0 1.0 1.0) PURPLE)
    (draw-cube-wires-v (vector3 0.0 0.5 -1.0) (vector3 1.0 1.0 1.0) DARKGREEN)
    (draw-cube-v (vector3 0.0 0.5 -1.0) (vector3 1.0 1.0 1.0) YELLOW)
    (draw-grid 10 1.0)
    (end-shader-mode)
    (end-mode-3d)
    (end-texture-mode)

    ;; draw to screen
    (begin-drawing)
    (clear-background RAYWHITE)
    (draw-texture-rec (rt->texture target)
                      (rectangle 0.0 0.0 (exact->inexact screen-width) (exact->inexact (- screen-height)))
                      (vector2 0.0 0.0) WHITE)
    (draw-fps 10 10)
    (end-drawing)
    (loop)))

(unload-render-texture-depth-tex target)
(unload-shader shdr-raymarch)
(unload-shader shdr-raster)
(close-window)
