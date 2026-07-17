#lang racket/base

;; 逐步构建：从 test2 开始，一次加一个功能
(require "../../raylib/raylib.rkt"
         racket/runtime-path
         (only-in ffi/unsafe malloc))

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))
(define GLSL-VERSION 330)

;; C Matrix 字段顺序: m0,m4,m8,m12, m1,m5,m9,m13, m2,m6,m10,m14, m3,m7,m11,m15
(define (matrix-translate x y z)
  (list 1.0 0.0 0.0 x  0.0 1.0 0.0 y  0.0 0.0 1.0 z  0.0 0.0 0.0 1.0))

(define (set-model-transform model-list mat-list)
  (append mat-list (list-tail model-list 16)))

(init-window 800 450 "step: 1=noCenter 2=+center 3=+camMove 4=+viewPos 5=+light")

;; 着色器 (和 test2 完全一样)
(define shader (load-shader
                (res (format "shaders/glsl~a/voxel_lighting.vs" GLSL-VERSION))
                (res (format "shaders/glsl~a/voxel_lighting.fs" GLSL-VERSION))))
(printf "shader.id=~a\n" (car shader))
(define ambient-loc (get-shader-location shader "ambient"))
(set-shader-value shader ambient-loc
                  (malloc-float-vec4 2.0 0.0 0.0 1.0) SHADER-UNIFORM-VEC4)
(printf "ambient loc=~a\n" ambient-loc)

;; viewPos
(define viewPos-loc (get-shader-location shader "viewPos"))
(printf "viewPos loc=~a\n" viewPos-loc)
(ptr-set! (caddr shader) _int (* 11 4) viewPos-loc)

;; 灯光 uniform locations
(for ([i 4])
  (printf "light[~a] locs: en=~a ty=~a po=~a ta=~a co=~a\n" i
    (get-shader-location shader (format "lights[~a].enabled" i))
    (get-shader-location shader (format "lights[~a].type" i))
    (get-shader-location shader (format "lights[~a].position" i))
    (get-shader-location shader (format "lights[~a].target" i))
    (get-shader-location shader (format "lights[~a].color" i))))

;; 模型
(define model-raw (load-model (res "models/vox/chr_knight.vox")))
(printf "model meshCount=~a\n" (list-ref model-raw 16))

;; 居中版本
(define bb (get-model-bounding-box model-raw))
(define cx (+ (list-ref bb 0) (/ (- (list-ref bb 3) (list-ref bb 0)) 2.0)))
(define cz (+ (list-ref bb 2) (/ (- (list-ref bb 5) (list-ref bb 2)) 2.0)))
(define model-centered
  (set-model-transform model-raw (matrix-translate (- cx) 0.0 (- cz))))
(printf "center: cx=~a cz=~a\n" cx cz)

;; 给两个模型都赋自定义着色器
(for ([m (list model-raw model-centered)])
  (for ([j (in-range (list-ref m 17))])
    (set-material-shader (ptr-add (list-ref m 19) (* j 40)) shader)))

(define camera (camera3d 10.0 10.0 10.0  0.0 0.0 0.0  0.0 1.0 0.0 45.0 CAMERA-PERSPECTIVE))
(define pos (vector3 0.0 0.0 0.0))
(set-target-fps 60)
(define mode 0)

;; 复用 buffer
(define vpbuf (malloc _float 3 'atomic))
(define libuf (malloc _int 1 'atomic))
(define lfbuf (malloc _float 3 'atomic))
(define lcbuf (malloc _float 4 'atomic))

(let loop ()
  (unless (window-should-close?)
    (when (is-key-pressed KEY-ONE)   (set! mode 0))
    (when (is-key-pressed KEY-TWO)   (set! mode 1))
    (when (is-key-pressed KEY-THREE) (set! mode 2))
    (when (is-key-pressed KEY-FOUR)  (set! mode 3))
    (when (is-key-pressed KEY-FIVE)  (set! mode 4))

    ;; 模式 2+：简单的固定旋转（不引入鼠标交互复杂度）
    ;; 模式 3+：viewPos
    ;; 模式 4+：灯光

    (when (>= mode 3)
      (ptr-set! vpbuf _float 0 (ptr-ref camera _float 0))
      (ptr-set! vpbuf _float 1 (ptr-ref camera _float 1))
      (ptr-set! vpbuf _float 2 (ptr-ref camera _float 2))
      (set-shader-value shader (ptr-ref (caddr shader) _int (* 11 4))
                        vpbuf SHADER-UNIFORM-VEC3))

    (when (>= mode 4)
      ;; 一盏灯
      (ptr-set! libuf _int 0 1)
      (set-shader-value shader (get-shader-location shader "lights[0].enabled")  libuf SHADER-UNIFORM-INT)
      (ptr-set! libuf _int 0 1)
      (set-shader-value shader (get-shader-location shader "lights[0].type")     libuf SHADER-UNIFORM-INT)
      (ptr-set! lfbuf _float 0 -20.0) (ptr-set! lfbuf _float 1 20.0) (ptr-set! lfbuf _float 2 -20.0)
      (set-shader-value shader (get-shader-location shader "lights[0].position") lfbuf SHADER-UNIFORM-VEC3)
      (ptr-set! lfbuf _float 0 0.0)   (ptr-set! lfbuf _float 1 0.0)  (ptr-set! lfbuf _float 2 0.0)
      (set-shader-value shader (get-shader-location shader "lights[0].target")   lfbuf SHADER-UNIFORM-VEC3)
      (ptr-set! lcbuf _float 0 0.5)   (ptr-set! lcbuf _float 1 0.5)
      (ptr-set! lcbuf _float 2 0.5)   (ptr-set! lcbuf _float 3 1.0)
      (set-shader-value shader (get-shader-location shader "lights[0].color")    lcbuf SHADER-UNIFORM-VEC4))

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    ;; 模式 0: 原始模型（对照，应可见，红色）
    ;; 模式 1-4: 居中模型
    (if (= mode 0)
        (draw-model model-raw pos 1.0 WHITE)
        (draw-model model-centered pos 1.0 WHITE))
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text (case mode
                 [(0) "0:raw(对照)"]
                 [(1) "1:+center"]
                 [(2) "2:+center(同1)"]
                 [(3) "3:+viewPos"]
                 [(4) "4:+light"])
               10 10 20 BLACK)
    (end-drawing)
    (loop)))

(unload-model model-raw)
(close-window)
