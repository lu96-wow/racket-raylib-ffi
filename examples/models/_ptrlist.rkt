#lang racket/base

;; 验证：_list-struct 中 _pointer 字段是否是 INPUT 重建问题的根因
(require ffi/unsafe "../../raylib/raylib.rkt" racket/runtime-path)

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "ptr-in-list test")

;; ═══════════════════════════════════════
;; 测试 1: _vec3-bytes (无 _pointer) 重建后 INPUT
;;   已知正常：update-camera-pro 每帧传 vec3->bytes
;; ═══════════════════════════════════════

;; ═══════════════════════════════════════
;; 测试 2: _model-bytes (有 _pointer) — 原始 vs 重建
;; ═══════════════════════════════════════

(define m (load-model (res "models/vox/chr_knight.vox")))
(printf "original list length=~a\n" (length m))

;; 取 materials 指针 (index 19)
(define mats-ptr (list-ref m 19))
(printf "materials ptr from original: ~a\n" mats-ptr)

;; 重建 list (用 append，模拟 set-model-transform)
(define mat-identity
  (list 1.0 0.0 0.0 0.0  0.0 1.0 0.0 0.0  0.0 0.0 1.0 0.0  0.0 0.0 0.0 1.0))
(define m2 (append mat-identity (list-tail m 16)))
(printf "rebuilt list length=~a\n" (length m2))

;; 检查 _pointer 字段是否 eq? (同一个 cpointer 对象)
(define mats-ptr2 (list-ref m2 19))
(printf "materials ptr from rebuilt:  ~a\n" mats-ptr2)
(printf "eq? = ~a  (should be #t)\n" (eq? mats-ptr mats-ptr2))

;; ═══════════════════════════════════════
;; 测试 3: 只替换 float 字段，保留原始 list 的 pointer 部分
;;   list-ref 逐个元素构建，只用原始 list-ref 的值
;; ═══════════════════════════════════════
(define m3
  (list (list-ref m 0) (list-ref m 1) (list-ref m 2) (list-ref m 3)
        (list-ref m 4) (list-ref m 5) (list-ref m 6) (list-ref m 7)
        (list-ref m 8) (list-ref m 9) (list-ref m 10) (list-ref m 11)
        (list-ref m 12) (list-ref m 13) (list-ref m 14) (list-ref m 15)
        (list-ref m 16) (list-ref m 17) (list-ref m 18) (list-ref m 19)
        (list-ref m 20) (list-ref m 21) 0  ; meshMaterial, boneCount, padding
        (list-ref m 23) (list-ref m 24) (list-ref m 25) (list-ref m 26)))
(printf "m3 length=~a\n" (length m3))
(printf "m3[19] eq? original[19] = ~a\n" (eq? (list-ref m3 19) mats-ptr))

;; ═══════════════════════════════════════
;; 测试 4: 像 vec3->bytes 那样，从 cpointer 读取后 list 构建（纯数值，无 _pointer）
;;   用 _vec3-bytes 类型传一个"手工"list vs "原始"list
;; ═══════════════════════════════════════
(define camera (camera3d 10.0 10.0 10.0  0.0 0.0 0.0  0.0 1.0 0.0 45.0 CAMERA-PERSPECTIVE))

;; 用 vec3->bytes 得到 list → 这应该能正常传为 INPUT
(define raw-vec3-list (vec3->bytes (vector3 1.0 2.0 3.0)))
(printf "raw vec3 list = ~a\n" raw-vec3-list)

;; 重建 vec3 list (模拟 append/reconstruct)
(define rebuilt-vec3-list
  (append (list 1.0) (list 2.0 3.0)))
(printf "rebuilt vec3 list = ~a\n" rebuilt-vec3-list)

;; ═══════════════════════════════════════
;; 测试 5: 画一个需要 _vec3-bytes INPUT 的东西
;;   用原始 list 和 重建 list 各传一次
;; ═══════════════════════════════════════

;; 渲染 — 简单测试
(define pos (vector3 0.0 0.0 0.0))
(define mode 0)
(define shader (load-shader (res "shaders/glsl330/voxel_lighting.vs")
                            (res "shaders/glsl330/voxel_lighting.fs")))
(set-shader-value shader (get-shader-location shader "ambient")
                  (malloc-float-vec4 2.0 0.0 0.0 1.0) SHADER-UNIFORM-VEC4)
;; 给 m, m2, m3 都赋着色器
(for ([lst (list m m2 m3)])
  (for ([j (in-range (list-ref lst 17))])
    (set-material-shader (ptr-add (list-ref lst 19) (* j 40)) shader)))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (when (is-key-pressed KEY-ONE)   (set! mode 0))
    (when (is-key-pressed KEY-TWO)   (set! mode 1))
    (when (is-key-pressed KEY-THREE) (set! mode 2))
    (when (is-key-pressed KEY-FOUR)  (set! mode 3))

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (case mode
      [(0) (draw-model m  pos 1.0 WHITE)]   ;; 原始 list
      [(1) (draw-model m2 pos 1.0 WHITE)]   ;; append 重建 (有 _pointer)
      [(2) (draw-model m3 pos 1.0 WHITE)]   ;; list 逐元素重建 (有 _pointer)
      [(3) ;; 用 vec3 重建的 list 画线 (需要 _vec3-bytes INPUT)
       (let ([f (get-ffi-obj "DrawLine3D" lib
                  (_fun (v1 : _vec3-bytes) (v2 : _vec3-bytes) (c : _color-bytes) -> _void))])
         (f rebuilt-vec3-list (list 0.0 10.0 0.0) (color->bytes RED)))])
    (draw-grid 10 1.0)
    (end-mode-3d)
    (draw-text (case mode
                 [(0) "1:原始model list"]
                 [(1) "2:append重建(含_pointer)"]
                 [(2) "3:list逐个重建(含_pointer)"]
                 [(3) "4:vec3重建(纯float)"])
               10 10 20 BLACK)
    (end-drawing)
    (loop)))

(unload-model m)
(close-window)
