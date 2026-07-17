#lang racket/base

;; ptr test v2 — 最简：load model as _Model, draw with _pointer
(require ffi/unsafe "../../raylib/raylib.rkt"
         racket/runtime-path)

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

;; load-model → _Model cpointer
(define load-model-ptr
  (let ([f (get-ffi-obj "LoadModel" lib (_fun _string -> (m : _Model)))])
    (lambda (filename) (f filename))))

;; draw-model → _Model 输入 (FFI 正确处理 struct-by-value)
(define draw-model-ptr
  (let ([f (get-ffi-obj "DrawModel" lib
             (_fun (m : _Model) (pos : _vec3-bytes) _float (c : _color-bytes) -> _void))])
    (lambda (model-ptr pos scale tint)
      (f model-ptr (vec3->bytes pos) scale (color->bytes tint)))))

;; unload
(define unload-model-ptr
  (get-ffi-obj "UnloadModel" lib (_fun (m : _Model) -> _void)))

(init-window 800 450 "ptr v2: 1=default 2=custom")
(define camera (camera3d 10.0 10.0 10.0  0.0 0.0 0.0  0.0 1.0 0.0 45.0 CAMERA-PERSPECTIVE))

;; 着色器
(define shader (load-shader (res "shaders/glsl330/voxel_lighting.vs")
                            (res "shaders/glsl330/voxel_lighting.fs")))
(set-shader-value shader (get-shader-location shader "ambient")
                  (malloc-float-vec4 2.0 0.0 0.0 1.0) SHADER-UNIFORM-VEC4)

;; 模型
(define m (load-model-ptr (res "models/vox/chr_knight.vox")))
(printf "meshCount=~a matCount=~a\n"
        (ptr-ref m _int 16) (ptr-ref m _int 17))

;; 给材质赋着色器
(define mats (ptr-ref m _pointer 10))  ;; offset 80 → _pointer idx 10
(for ([j (in-range (ptr-ref m _int 17))])
  (set-material-shader (ptr-add mats (* j 40)) shader))
(printf "mat[0].shader.id = ~a\n" (ptr-ref mats _uint 0))

;; 测试: 直接写 transform (居中的矩阵)
;; 用 _model-bytes 中确认的偏移: float idx 12=m12(x), 13=m13(y), 14=m14(z), 15=m15(w)
(printf "before: m12=~a m13=~a m14=~a\n"
        (ptr-ref m _float 12) (ptr-ref m _float 13) (ptr-ref m _float 14))

;; 加载第二个模型用于测试
(define m2 (load-model-ptr (res "models/vox/chr_knight.vox")))
(define mats2 (ptr-ref m2 _pointer 10))
(for ([j (in-range (ptr-ref m2 _int 17))])
  (set-material-shader (ptr-add mats2 (* j 40)) shader))

;; 测试各种 transform 修改
(printf "m2 initial: m12=~a m13=~a m14=~a m15=~a\n"
        (ptr-ref m2 _float 12) (ptr-ref m2 _float 13)
        (ptr-ref m2 _float 14) (ptr-ref m2 _float 15))

;; 全部重置为 identity (应该和模式1一样)
(ptr-set! m2 _float 0 1.0) (ptr-set! m2 _float 1 0.0) (ptr-set! m2 _float 2 0.0) (ptr-set! m2 _float 3 0.0)
(ptr-set! m2 _float 4 0.0) (ptr-set! m2 _float 5 1.0) (ptr-set! m2 _float 6 0.0) (ptr-set! m2 _float 7 0.0)
(ptr-set! m2 _float 8 0.0) (ptr-set! m2 _float 9 0.0) (ptr-set! m2 _float 10 1.0) (ptr-set! m2 _float 11 0.0)
(ptr-set! m2 _float 12 0.0) (ptr-set! m2 _float 13 0.0) (ptr-set! m2 _float 14 0.0) (ptr-set! m2 _float 15 1.0)
(printf "m2 after identity: m12=~a m14=~a\n"
        (ptr-ref m2 _float 12) (ptr-ref m2 _float 14))

(define pos (vector3 0.0 0.0 0.0))
(define mode 0)

(let loop ()
  (unless (window-should-close?)
    (when (is-key-pressed KEY-ONE) (set! mode 0))
    (when (is-key-pressed KEY-TWO) (set! mode 1))
    (when (is-key-pressed KEY-THREE) (set! mode 2))
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (case mode
      [(0) (draw-model-ptr m  pos 1.0 WHITE)]   ;; 原始
      [(1) (draw-model-ptr m2 pos 1.0 WHITE)]   ;; 居中
      [(2) (draw-model-ptr m2 pos 1.0 WHITE)])  ;; 对照
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text (case mode [(0) "1:raw"][(1) "2:centered(ptr-set!)"][(2) "3:ctrl"]) 10 10 20 BLACK)
    (end-drawing)
    (loop)))

(unload-model-ptr m)
(unload-model-ptr m2)
(close-window)
