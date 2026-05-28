#lang racket/base

;; raylib shapes 模块 — 基本 2D 形状绘制
;;
;; 对应 C: rshapes.c / raylib.h "Module: shapes"

(require ffi/unsafe
         (prefix-in T: "types.rkt")
         (prefix-in C: "rcore.rkt"))

;; ============================================================
;; Vector2 传值辅助
;; ============================================================

(define _vec2-bytes
  (_list-struct _float _float))

(define (vec2->bytes v)
  (list (ptr-ref v _float 0)   ;; offset 0 = first float (x)
        (ptr-ref v _float 1))) ;; offset 1 = second float (y, at byte 4)

;; ============================================================
;; 圆形绘制 (core_delta_time.c)
;; DrawCircleV(Vector2 center, float radius, Color color)
;; ============================================================

(define draw-circle-v
  (let ([f (get-ffi-obj "DrawCircleV" T:lib
             (_fun (c : _vec2-bytes) _float (col : C:_color-bytes) -> _void))])
    (λ (center radius color)
      (f (vec2->bytes center) radius (C:color->bytes color)))))

;; ============================================================
;; 导出
;; ============================================================

(provide
 draw-circle-v)

