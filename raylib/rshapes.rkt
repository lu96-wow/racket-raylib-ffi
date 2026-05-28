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
;; 圆圈绘制 (core_input_gamepad.c)
;; DrawCircle(int centerX, int centerY, float radius, Color color)
;; ============================================================

(define draw-circle
  (let ([f (get-ffi-obj "DrawCircle" T:lib
             (_fun _int _int _float (col : C:_color-bytes) -> _void))])
    (λ (centerX centerY radius color)
      (f centerX centerY radius (C:color->bytes color)))))

;; ============================================================
;; 圆角矩形绘制 (core_input_gamepad.c)
;; DrawRectangleRounded(Rectangle rec, float roundness, int segments, Color color)
;; ============================================================

(define draw-rectangle-rounded
  (let ([f (get-ffi-obj "DrawRectangleRounded" T:lib
             (_fun (r : C:_rect-bytes) _float _int (col : C:_color-bytes) -> _void))])
    (λ (rec roundness segments color)
      (f (C:rect->bytes rec) roundness segments (C:color->bytes color)))))

;; ============================================================
;; 三角形绘制 (core_input_gamepad.c)
;; DrawTriangle(Vector2 v1, Vector2 v2, Vector2 v3, Color color)
;; ============================================================

(define draw-triangle
  (let ([f (get-ffi-obj "DrawTriangle" T:lib
             (_fun (v1 : C:_vec2-bytes) (v2 : C:_vec2-bytes) (v3 : C:_vec2-bytes)
                   (col : C:_color-bytes) -> _void))])
    (λ (v1 v2 v3 color)
      (f (C:vec2->bytes v1)
         (C:vec2->bytes v2)
         (C:vec2->bytes v3)
         (C:color->bytes color)))))

;; ============================================================
;; 碰撞检测 (core_input_gamepad.c)
;; CheckCollisionPointRec(Vector2 point, Rectangle rec) -> bool
;; ============================================================

(define check-collision-point-rec
  (let ([f (get-ffi-obj "CheckCollisionPointRec" T:lib
             (_fun (p : C:_vec2-bytes) (r : C:_rect-bytes) -> _bool))])
    (λ (point rec)
      (f (C:vec2->bytes point) (C:rect->bytes rec)))))

;; ============================================================
;; 矩形绘制 Rec 版本 (core_input_gestures.c)
;; DrawRectangleRec(Rectangle rec, Color color)
;; ============================================================

(define draw-rectangle-rec
  (let ([f (get-ffi-obj "DrawRectangleRec" T:lib
             (_fun (r : C:_rect-bytes) (col : C:_color-bytes) -> _void))])
    (λ (rec color)
      (f (C:rect->bytes rec) (C:color->bytes color)))))

;; ============================================================
;; 矩形边框绘制 (core_input_gestures.c)
;; DrawRectangleLines(int posX, int posY, int width, int height, Color color)
;; ============================================================

(define draw-rectangle-lines
  (let ([f (get-ffi-obj "DrawRectangleLines" T:lib
             (_fun _int _int _int _int (col : C:_color-bytes) -> _void))])
    (λ (posX posY width height color)
      (f posX posY width height (C:color->bytes color)))))

;; ============================================================
;; 线段绘制 (core_input_gestures_testbed.c)
;; DrawLineEx(Vector2 startPos, Vector2 endPos, float thick, Color color)
;; ============================================================

(define draw-line-ex
  (let ([f (get-ffi-obj "DrawLineEx" T:lib
             (_fun (s : C:_vec2-bytes) (e : C:_vec2-bytes) _float (col : C:_color-bytes) -> _void))])
    (λ (start-pos end-pos thick color)
      (f (C:vec2->bytes start-pos) (C:vec2->bytes end-pos) thick (C:color->bytes color)))))

;; ============================================================
;; 环形绘制 (core_input_gestures_testbed.c)
;; DrawRing(Vector2 center, float innerRadius, float outerRadius,
;;          float startAngle, float endAngle, int segments, Color color)
;; ============================================================

(define draw-ring
  (let ([f (get-ffi-obj "DrawRing" T:lib
             (_fun (c : C:_vec2-bytes) _float _float _float _float _int
                   (col : C:_color-bytes) -> _void))])
    (λ (center inner-radius outer-radius start-angle end-angle segments color)
      (f (C:vec2->bytes center) inner-radius outer-radius start-angle end-angle
         segments (C:color->bytes color)))))

;; ============================================================
;; 导出
;; ============================================================

(provide
 draw-circle-v
 draw-rectangle
 draw-circle
 draw-rectangle-rounded
 draw-triangle
 check-collision-point-rec
 draw-rectangle-rec
 draw-rectangle-lines
 draw-line-ex
 draw-ring)

