#lang racket/base

;; raw-types.rkt — 原始指针安全访问器
;;
;; 背景: define-cstruct 生成的访问器 (_Material-maps 等) 有契约检查，
;;       拒绝 raylib C API 返回的裸 cpointer。
;;       本模块用 ptr-ref + 固定整数偏移替代，偏移量由 types.rkt 中
;;       define-cstruct 字段顺序 + C 对齐规则确定。
;;
;; 所有偏移基于: Linux x86-64, sizeof(int)=4, sizeof(float)=4, sizeof(ptr)=8

(require ffi/unsafe
         "types.rkt")

(provide
 ;; sizeof 常量 (来自 ctype-sizeof, 与 types.rkt 同步)
 sizeof-transform     ;; 40
 sizeof-boneinfo      ;; 36

 ;; Transform 字段访问器
 transform-trans-x transform-trans-y transform-trans-z
 transform-rot-x   transform-rot-y   transform-rot-z   transform-rot-w
 transform-scale-x transform-scale-y transform-scale-z

 ;; BoneInfo 字段访问器
 bone-info-parent

 ;; ModelAnimation 字段索引
 anim-name-length            ;; 32
 anim-keyframe-count-index   ;; 33
 anim-keyframe-poses-index)  ;; 34

;; ============================================================
;; sizeof 常量 (ctype-sizeof 保证与 types.rkt 同步)
;; ============================================================

(define sizeof-transform   (ctype-sizeof _Transform))    ;; 40
(define sizeof-boneinfo    (ctype-sizeof _BoneInfo))     ;; 36

;; ============================================================
;; Transform (raylib.h:395)
;; _float 偏移: trans(0,1,2) rot(3,4,5,6) scale(7,8,9)
;; ============================================================
(define (transform-trans-x p)  (ptr-ref p _float 0))
(define (transform-trans-y p)  (ptr-ref p _float 1))
(define (transform-trans-z p)  (ptr-ref p _float 2))
(define (transform-rot-x p)    (ptr-ref p _float 3))
(define (transform-rot-y p)    (ptr-ref p _float 4))
(define (transform-rot-z p)    (ptr-ref p _float 5))
(define (transform-rot-w p)    (ptr-ref p _float 6))
(define (transform-scale-x p)  (ptr-ref p _float 7))
(define (transform-scale-y p)  (ptr-ref p _float 8))
(define (transform-scale-z p)  (ptr-ref p _float 9))

;; ============================================================
;; BoneInfo (raylib.h:405)
;; name[32] _ubyte + parent _int → 36B
;; parent 在字节偏移 32 (_int 索引 8)
;; ============================================================

(define (bone-info-parent p)
  (ptr-ref p _int 8))

;; ============================================================
;; ModelAnimation 字段索引 (对应 _model-animation-bytes list)
;; _list-struct 展平: 32 _ubyte + _int + _int + _pointer
;; list-ref 索引: name[0..31], boneCount[32], keyframeCount[33], keyframePoses[34]
;; ============================================================

(define anim-name-length 32)
(define anim-keyframe-count-index 33)
(define anim-keyframe-poses-index 34)
