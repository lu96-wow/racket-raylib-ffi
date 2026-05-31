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
;; 矩形绘制 Vector 版 (core_monitor_detector.c)
;; DrawRectangleV(Vector2 position, Vector2 size, Color color)
;; ============================================================

(define draw-rectangle-v
  (let ([f (get-ffi-obj "DrawRectangleV" T:lib
             (_fun (p : C:_vec2-bytes) (s : C:_vec2-bytes) (col : C:_color-bytes) -> _void))])
    (λ (position size color)
      (f (C:vec2->bytes position) (C:vec2->bytes size) (C:color->bytes color)))))

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
             (_fun (p : C:_vec2-bytes) (r : C:_rect-bytes) -> _stdbool))])
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
;; 矩形边框绘制扩展版 (core_window_flags.c)
;; DrawRectangleLinesEx(Rectangle rec, float lineThick, Color color)
;; ============================================================

(define draw-rectangle-lines-ex
  (let ([f (get-ffi-obj "DrawRectangleLinesEx" T:lib
             (_fun (r : C:_rect-bytes) _float (col : C:_color-bytes) -> _void))])
    (λ (rec line-thick color)
      (f (C:rect->bytes rec) line-thick (C:color->bytes color)))))

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
;; 线段绘制 Vector 版本
;; DrawLineV(Vector2 startPos, Vector2 endPos, Color color)
;; ============================================================

(define draw-line-v
  (let ([f (get-ffi-obj "DrawLineV" T:lib
             (_fun (s : C:_vec2-bytes) (e : C:_vec2-bytes) (col : C:_color-bytes) -> _void))])
    (λ (start-pos end-pos color)
      (f (C:vec2->bytes start-pos) (C:vec2->bytes end-pos) (C:color->bytes color)))))

;; ============================================================
;; 贝塞尔曲线绘制 (shapes_lines_bezier.c)
;; DrawLineBezier(Vector2 startPos, Vector2 endPos, float thick, Color color)
;; ============================================================

(define draw-line-bezier
  (let ([f (get-ffi-obj "DrawLineBezier" T:lib
             (_fun (s : C:_vec2-bytes) (e : C:_vec2-bytes) _float (col : C:_color-bytes) -> _void))])
    (λ (start-pos end-pos thick color)
      (f (C:vec2->bytes start-pos) (C:vec2->bytes end-pos) thick (C:color->bytes color)))))

;; ============================================================
;; 点与圆碰撞检测 (shapes_lines_bezier.c)
;; CheckCollisionPointCircle(Vector2 point, Vector2 center, float radius) -> bool
;; ============================================================

(define check-collision-point-circle
  (let ([f (get-ffi-obj "CheckCollisionPointCircle" T:lib
             (_fun (p : C:_vec2-bytes) (c : C:_vec2-bytes) _float -> _stdbool))])
    (λ (point center radius)
      (f (C:vec2->bytes point) (C:vec2->bytes center) radius))))

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
;; 渐变圆绘制 (shapes_basic_shapes.c)
;; DrawCircleGradient(Vector2 center, float radius, Color inner, Color outer)
;; ============================================================

(define draw-circle-gradient
  (let ([f (get-ffi-obj "DrawCircleGradient" T:lib
             (_fun (c : C:_vec2-bytes) _float (col1 : C:_color-bytes) (col2 : C:_color-bytes) -> _void))])
    (λ (center radius inner outer)
      (f (C:vec2->bytes center) radius (C:color->bytes inner) (C:color->bytes outer)))))

;; ============================================================
;; 空心圆绘制 (shapes_basic_shapes.c)
;; DrawCircleLines(int centerX, int centerY, float radius, Color color)
;; ============================================================

(define draw-circle-lines
  (let ([f (get-ffi-obj "DrawCircleLines" T:lib
             (_fun _int _int _float (col : C:_color-bytes) -> _void))])
    (λ (centerX centerY radius color)
      (f centerX centerY radius (C:color->bytes color)))))

;; ============================================================
;; 空心圆绘制 Vector 版 (shapes_bullet_hell.c)
;; DrawCircleLinesV(Vector2 center, float radius, Color color)
;; ============================================================

(define draw-circle-lines-v
  (let ([f (get-ffi-obj "DrawCircleLinesV" T:lib
             (_fun (c : C:_vec2-bytes) _float (col : C:_color-bytes) -> _void))])
    (λ (center radius color)
      (f (C:vec2->bytes center) radius (C:color->bytes color)))))

;; ============================================================
;; 椭圆绘制 (shapes_basic_shapes.c)
;; DrawEllipse(int centerX, int centerY, float radiusH, float radiusV, Color color)
;; ============================================================

(define draw-ellipse
  (let ([f (get-ffi-obj "DrawEllipse" T:lib
             (_fun _int _int _float _float (col : C:_color-bytes) -> _void))])
    (λ (centerX centerY radiusH radiusV color)
      (f centerX centerY radiusH radiusV (C:color->bytes color)))))

;; ============================================================
;; 空心椭圆绘制 (shapes_basic_shapes.c)
;; DrawEllipseLines(int centerX, int centerY, float radiusH, float radiusV, Color color)
;; ============================================================

(define draw-ellipse-lines
  (let ([f (get-ffi-obj "DrawEllipseLines" T:lib
             (_fun _int _int _float _float (col : C:_color-bytes) -> _void))])
    (λ (centerX centerY radiusH radiusV color)
      (f centerX centerY radiusH radiusV (C:color->bytes color)))))

;; ============================================================
;; 水平渐变矩形绘制 (shapes_basic_shapes.c)
;; DrawRectangleGradientH(int posX, int posY, int width, int height, Color left, Color right)
;; ============================================================

(define draw-rectangle-gradient-h
  (let ([f (get-ffi-obj "DrawRectangleGradientH" T:lib
             (_fun _int _int _int _int (col1 : C:_color-bytes) (col2 : C:_color-bytes) -> _void))])
    (λ (posX posY width height left right)
      (f posX posY width height (C:color->bytes left) (C:color->bytes right)))))

;; ============================================================
;; 空心三角形绘制 (shapes_basic_shapes.c)
;; DrawTriangleLines(Vector2 v1, Vector2 v2, Vector2 v3, Color color)
;; ============================================================

(define draw-triangle-lines
  (let ([f (get-ffi-obj "DrawTriangleLines" T:lib
             (_fun (v1 : C:_vec2-bytes) (v2 : C:_vec2-bytes) (v3 : C:_vec2-bytes)
                   (col : C:_color-bytes) -> _void))])
    (λ (v1 v2 v3 color)
      (f (C:vec2->bytes v1)
         (C:vec2->bytes v2)
         (C:vec2->bytes v3)
         (C:color->bytes color)))))

;; ============================================================
;; 多边形绘制 (shapes_basic_shapes.c)
;; DrawPoly(Vector2 center, int sides, float radius, float rotation, Color color)
;; ============================================================

(define draw-poly
  (let ([f (get-ffi-obj "DrawPoly" T:lib
             (_fun (c : C:_vec2-bytes) _int _float _float (col : C:_color-bytes) -> _void))])
    (λ (center sides radius rotation color)
      (f (C:vec2->bytes center) sides radius rotation (C:color->bytes color)))))

;; ============================================================
;; 空心多边形绘制 (shapes_basic_shapes.c)
;; DrawPolyLines(Vector2 center, int sides, float radius, float rotation, Color color)
;; ============================================================

(define draw-poly-lines
  (let ([f (get-ffi-obj "DrawPolyLines" T:lib
             (_fun (c : C:_vec2-bytes) _int _float _float (col : C:_color-bytes) -> _void))])
    (λ (center sides radius rotation color)
      (f (C:vec2->bytes center) sides radius rotation (C:color->bytes color)))))

;; ============================================================
;; 多边形空心扩展绘制 (shapes_basic_shapes.c)
;; DrawPolyLinesEx(Vector2 center, int sides, float radius, float rotation, float lineThick, Color color)
;; ============================================================

(define draw-poly-lines-ex
  (let ([f (get-ffi-obj "DrawPolyLinesEx" T:lib
             (_fun (c : C:_vec2-bytes) _int _float _float _float (col : C:_color-bytes) -> _void))])
    (λ (center sides radius rotation line-thick color)
      (f (C:vec2->bytes center) sides radius rotation line-thick (C:color->bytes color)))))

;; ============================================================
;; 矩形高级绘制 (core_smooth_pixelperfect.c)
;; DrawRectanglePro(Rectangle rec, Vector2 origin, float rotation, Color color)
;; ============================================================

(define draw-rectangle-pro
  (let ([f (get-ffi-obj "DrawRectanglePro" T:lib
             (_fun (r : C:_rect-bytes) (o : C:_vec2-bytes) _float (col : C:_color-bytes) -> _void))])
    (λ (rec origin rotation color)
      (f (C:rect->bytes rec) (C:vec2->bytes origin) rotation (C:color->bytes color)))))

;; ============================================================
;; 导出
;; ============================================================

(provide
 draw-circle-v
 draw-rectangle
 draw-circle
 draw-circle-gradient
 draw-circle-lines
 draw-circle-lines-v
 draw-ellipse
 draw-ellipse-lines
 draw-rectangle-rounded
 draw-rectangle-v
 draw-rectangle-gradient-h
 draw-triangle
 draw-triangle-lines
 draw-poly
 draw-poly-lines
 draw-poly-lines-ex
 check-collision-point-rec
 draw-rectangle-rec
 draw-rectangle-lines
 draw-rectangle-lines-ex
 draw-line-ex
 draw-line-v
 draw-line-bezier
 check-collision-point-circle
 draw-ring
 draw-rectangle-pro)
