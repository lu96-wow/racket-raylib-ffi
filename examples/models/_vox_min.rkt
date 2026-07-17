#lang racket/base

;; 最简 VOX: load + center + draw, 不用灯光
(require ffi/unsafe "../../raylib/raylib.rkt" racket/runtime-path)

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(define load-model* (let ([f (get-ffi-obj "LoadModel" lib (_fun _string -> (m : _Model)))]) f))
(define draw-model* (let ([f (get-ffi-obj "DrawModel" lib
                          (_fun (m : _Model) (pos : _vec3-bytes) _float (c : _color-bytes) -> _void))])
                      (lambda (m p s c) (f m (vec3->bytes p) s (color->bytes c)))))
(define get-bb (let ([f (get-ffi-obj "GetModelBoundingBox" lib (_fun (m : _Model) -> (bb : _bounding-box-bytes)))]) f))
(define unload* (get-ffi-obj "UnloadModel" lib (_fun (m : _Model) -> _void)))

(init-window 800 450 "vox minimal")

;; 着色器 (红色 ambient)
(define shader (load-shader (res "shaders/glsl330/voxel_lighting.vs")
                            (res "shaders/glsl330/voxel_lighting.fs")))
(set-shader-value shader (get-shader-location shader "ambient")
                  (malloc-float-vec4 2.0 0.0 0.0 1.0) SHADER-UNIFORM-VEC4)

;; 模型
(define m (load-model* (res "models/vox/chr_knight.vox")))
(printf "loaded, meshCount=~a\n" (ptr-ref m _int 16))

;; 居中
(define bb (get-bb m))
(printf "bb ok\n")
(define cx (+ (list-ref bb 0) (/ (- (list-ref bb 3) (list-ref bb 0)) 2.0)))
(define cz (+ (list-ref bb 2) (/ (- (list-ref bb 5) (list-ref bb 2)) 2.0)))
(printf "center: cx=~a cz=~a\n" cx cz)

;; 设 transform 为居中矩阵
(for ([i 16]) (ptr-set! m _float i (if (member i '(0 5 10 15)) 1.0 0.0)))
(ptr-set! m _float 12 (- cx))
(ptr-set! m _float 14 (- cz))
(printf "transform set: m12=~a m14=~a\n" (ptr-ref m _float 12) (ptr-ref m _float 14))

;; 给材质赋着色器
(define mats (ptr-ref m _pointer 11))
(printf "matCount=~a mats=~a\n" (ptr-ref m _int 17) mats)
(for ([j (in-range (ptr-ref m _int 17))])
  (set-material-shader (ptr-add mats (* j 40)) shader))
(printf "mat[0].shader.id=~a\n" (ptr-ref mats _uint 0))

;; 渲染
(define camera (camera3d 10.0 10.0 10.0  0.0 0.0 0.0  0.0 1.0 0.0 45.0 CAMERA-PERSPECTIVE))
(define pos (vector3 0.0 0.0 0.0))
(set-target-fps 60)
(printf "entering loop\n")

(let loop ()
  (unless (window-should-close?)
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (draw-model* m pos 1.0 WHITE)
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text "vox minimal" 10 10 20 BLACK)
    (end-drawing)
    (loop)))

(unload* m)
(close-window)
