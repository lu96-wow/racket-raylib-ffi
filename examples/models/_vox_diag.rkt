#lang racket/base

;; 最终诊断：只测灯光是否破坏了渲染
(require "../../raylib/raylib.rkt"
         racket/runtime-path
         (only-in ffi/unsafe malloc))

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))
(define GLSL-VERSION 330)

(define (matrix-translate x y z)
  (list 1.0 0.0 0.0 x  0.0 1.0 0.0 y  0.0 0.0 1.0 z  0.0 0.0 0.0 1.0))

(define (set-model-transform model-list mat-list)
  (append mat-list (list-tail model-list 16)))

(init-window 800 450 "diag: 1=基础 2=+灯光 3=+viewPos 4=原版灯光")

;; 着色器
(define shader (load-shader
                (res (format "shaders/glsl~a/voxel_lighting.vs" GLSL-VERSION))
                (res (format "shaders/glsl~a/voxel_lighting.fs" GLSL-VERSION))))
(define ambient-loc (get-shader-location shader "ambient"))
(define viewPos-loc (get-shader-location shader "viewPos"))
(set-shader-value shader ambient-loc
                  (malloc-float-vec4 0.1 0.1 0.1 1.0) SHADER-UNIFORM-VEC4)
(ptr-set! (caddr shader) _int (* 11 4) viewPos-loc)
(printf "shader.id=~a ambient-loc=~a viewPos-loc=~a\n" (car shader) ambient-loc viewPos-loc)

;; 模型
(define model (load-model (res "models/vox/chr_knight.vox")))
(define bb (get-model-bounding-box model))
(define cx (+ (list-ref bb 0) (/ (- (list-ref bb 3) (list-ref bb 0)) 2.0)))
(define cz (+ (list-ref bb 2) (/ (- (list-ref bb 5) (list-ref bb 2)) 2.0)))
(set! model (set-model-transform model (matrix-translate (- cx) 0.0 (- cz))))
(for ([j (in-range (list-ref model 17))])
  (set-material-shader (ptr-add (list-ref model 19) (* j 40)) shader))

;; 灯光 (简化版 — 只创建一次，复用 buffer)
(define LIGHT-POINT 1)
(define light0-enabled-loc  (get-shader-location shader "lights[0].enabled"))
(define light0-type-loc     (get-shader-location shader "lights[0].type"))
(define light0-position-loc (get-shader-location shader "lights[0].position"))
(define light0-target-loc   (get-shader-location shader "lights[0].target"))
(define light0-color-loc    (get-shader-location shader "lights[0].color"))
(printf "light[0] locs: enabled=~a type=~a pos=~a tgt=~a col=~a\n"
        light0-enabled-loc light0-type-loc light0-position-loc light0-target-loc light0-color-loc)

(define light-ibuf (malloc _int 1 'atomic))
(define light-fbuf (malloc _float 3 'atomic))
(define light-cbuf (malloc _float 4 'atomic))

(define (set-light-once!)
  ;; enabled = 1, type = LIGHT_POINT
  (ptr-set! light-ibuf _int 0 1)
  (set-shader-value shader light0-enabled-loc light-ibuf SHADER-UNIFORM-INT)
  (ptr-set! light-ibuf _int 0 LIGHT-POINT)
  (set-shader-value shader light0-type-loc light-ibuf SHADER-UNIFORM-INT)
  ;; position = (-20, 20, -20)
  (ptr-set! light-fbuf _float 0 -20.0)
  (ptr-set! light-fbuf _float 1 20.0)
  (ptr-set! light-fbuf _float 2 -20.0)
  (set-shader-value shader light0-position-loc light-fbuf SHADER-UNIFORM-VEC3)
  ;; target = (0,0,0)
  (ptr-set! light-fbuf _float 0 0.0)
  (ptr-set! light-fbuf _float 1 0.0)
  (ptr-set! light-fbuf _float 2 0.0)
  (set-shader-value shader light0-target-loc light-fbuf SHADER-UNIFORM-VEC3)
  ;; color = GRAY (130,130,130,255) → (0.51,0.51,0.51,1.0)
  (ptr-set! light-cbuf _float 0 0.51)
  (ptr-set! light-cbuf _float 1 0.51)
  (ptr-set! light-cbuf _float 2 0.51)
  (ptr-set! light-cbuf _float 3 1.0)
  (set-shader-value shader light0-color-loc light-cbuf SHADER-UNIFORM-VEC4))

(set-light-once!)
(printf "set-light-once! done\n")

;; viewPos buffer (复用)
(define vpbuf (malloc _float 3 'atomic))

(define camera (camera3d 10.0 10.0 10.0  0.0 0.0 0.0  0.0 1.0 0.0 45.0 CAMERA-PERSPECTIVE))
(define pos (vector3 0.0 0.0 0.0))
(set-target-fps 60)
(define mode 0)
(define camerarot-x 0.0)
(define camerarot-y 0.0)

(let loop ()
  (unless (window-should-close?)
    (when (is-key-pressed KEY-ONE)   (set! mode 0))
    (when (is-key-pressed KEY-TWO)   (set! mode 1))
    (when (is-key-pressed KEY-THREE) (set! mode 2))
    (when (is-key-pressed KEY-FOUR)  (set! mode 3))
    (when (is-key-pressed KEY-FIVE)  (set-light-once!))  ;; 手动刷新灯光

    (if (is-mouse-button-down MOUSE-BUTTON-MIDDLE)
        (let ([md (get-mouse-delta)])
          (set! camerarot-x (* (ptr-ref md _float 0) 0.05))
          (set! camerarot-y (* (ptr-ref md _float 1) 0.05)))
        (begin (set! camerarot-x 0.0) (set! camerarot-y 0.0)))

    (update-camera-pro camera
      (vector3 0.0 0.0 0.0)
      (vector3 camerarot-x camerarot-y 0.0)
      (* (get-mouse-wheel-move) -2.0))

    ;; 模式 2+: 更新 viewPos
    (when (>= mode 2)
      (ptr-set! vpbuf _float 0 (ptr-ref camera _float 0))
      (ptr-set! vpbuf _float 1 (ptr-ref camera _float 1))
      (ptr-set! vpbuf _float 2 (ptr-ref camera _float 2))
      (set-shader-value shader (ptr-ref (caddr shader) _int (* 11 4)) vpbuf SHADER-UNIFORM-VEC3))

    ;; 模式 3+: 每帧更新灯光（模拟原始代码的 update-light-values）
    (when (>= mode 3)
      (set-light-once!))

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (draw-model model pos 1.0 WHITE)
    (draw-grid 10 1.0)
    (end-mode-3d)

    (define labels
      '("1:基础(可见)" "2:+灯光(一次性)" "3:+viewPos" "4:+灯光每帧刷新"))
    (draw-text (format "~a | 按5手动刷新灯光" (list-ref labels mode)) 10 10 20 BLACK)
    (end-drawing)
    (loop)))

(unload-model model)
(close-window)
