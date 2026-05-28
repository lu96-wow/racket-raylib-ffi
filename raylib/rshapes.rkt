#lang racket/base

;; raylib shapes 模块 — 基本 2D 形状绘制
;;
;; 对应 C: rshapes.c / raylib.h "Module: shapes"

(require ffi/unsafe
         (prefix-in T: "types.rkt")
         (prefix-in C: "rcore.rkt"))

;; ============================================================
;; 圆形绘制 (core_delta_time.c, core_input_keys.c, core_input_mouse.c)
;; DrawCircleV(Vector2 center, float radius, Color color)
;; ============================================================

(define draw-circle-v
  (let ([f (get-ffi-obj "DrawCircleV" T:lib
             (_fun (c : C:_vec2-bytes) _float (col : C:_color-bytes) -> _void))])
    (λ (center radius color)
      (f (C:vec2->bytes center) radius (C:color->bytes color)))))

;; ============================================================
;; 矩形绘制 (core_input_mouse_wheel.c)
;; DrawRectangle(int posX, int posY, int width, int height, Color color)
;; ============================================================

(define draw-rectangle
  (let ([f (get-ffi-obj "DrawRectangle" T:lib
             (_fun _int _int _int _int (col : C:_color-bytes) -> _void))])
    (λ (posX posY width height color)
      (f posX posY width height (C:color->bytes color)))))

;; ============================================================
;; 导出
;; ============================================================

(provide
 draw-circle-v
 draw-rectangle)

