#lang racket/base

;; raylib shapes 模块 — 基本 2D 形状绘制
;;
;; 对应 C: rshapes.c / raylib.h "Module: shapes"

(require ffi/unsafe
         racket/math
         (prefix-in T: "types.rkt")
         (prefix-in C: "rcore.rkt")
         (prefix-in TX: "rtextures.rkt"))

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
;; 圆角矩形边框绘制 (shapes_rounded_rectangle_drawing.c)
;; DrawRectangleRoundedLinesEx(Rectangle rec, float roundness,
;;                              int segments, float lineThick, Color color)
;; ============================================================

(define draw-rectangle-rounded-lines-ex
  (let ([f (get-ffi-obj "DrawRectangleRoundedLinesEx" T:lib
             (_fun (r : C:_rect-bytes) _float _int _float (col : C:_color-bytes) -> _void))])
    (λ (rec roundness segments line-thick color)
      (f (C:rect->bytes rec) roundness segments line-thick (C:color->bytes color)))))

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
;; 矩形碰撞检测 (shapes_collision_area.c)
;; CheckCollisionRecs(Rectangle rec1, Rectangle rec2) -> bool
;; ============================================================

(define check-collision-recs
  (let ([f (get-ffi-obj "CheckCollisionRecs" T:lib
             (_fun (r1 : C:_rect-bytes) (r2 : C:_rect-bytes) -> _stdbool))])
    (λ (rec1 rec2)
      (f (C:rect->bytes rec1) (C:rect->bytes rec2)))))

;; ============================================================
;; 获取碰撞矩形 (shapes_collision_area.c)
;; GetCollisionRec(Rectangle rec1, Rectangle rec2) -> Rectangle
;; ============================================================

(define get-collision-rec
  (let ([f (get-ffi-obj "GetCollisionRec" T:lib
             (_fun (r1 : C:_rect-bytes) (r2 : C:_rect-bytes) -> (r : C:_rect-bytes)))])
    (λ (rec1 rec2)
      (C:rect-bytes->rect (f (C:rect->bytes rec1) (C:rect->bytes rec2))))))

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
;; 环形边框绘制 (shapes_ring_drawing.c)
;; DrawRingLines(Vector2 center, float innerRadius, float outerRadius,
;;               float startAngle, float endAngle, int segments, Color color)
;; ============================================================

(define draw-ring-lines
  (let ([f (get-ffi-obj "DrawRingLines" T:lib
             (_fun (c : C:_vec2-bytes) _float _float _float _float _int
                   (col : C:_color-bytes) -> _void))])
    (λ (center inner-radius outer-radius start-angle end-angle segments color)
      (f (C:vec2->bytes center) inner-radius outer-radius start-angle end-angle
         segments (C:color->bytes color)))))

;; ============================================================
;; 扇形填充绘制 (shapes_circle_sector_drawing.c)
;; DrawCircleSector(Vector2 center, float radius,
;;                  float startAngle, float endAngle, int segments, Color color)
;; ============================================================

(define draw-circle-sector
  (let ([f (get-ffi-obj "DrawCircleSector" T:lib
             (_fun (c : C:_vec2-bytes) _float _float _float _int
                   (col : C:_color-bytes) -> _void))])
    (λ (center radius start-angle end-angle segments color)
      (f (C:vec2->bytes center) radius start-angle end-angle
         segments (C:color->bytes color)))))

;; ============================================================
;; 扇形边框绘制 (shapes_ring_drawing.c, shapes_circle_sector_drawing.c)
;; DrawCircleSectorLines(Vector2 center, float radius,
;;                       float startAngle, float endAngle, int segments, Color color)
;; ============================================================

(define draw-circle-sector-lines
  (let ([f (get-ffi-obj "DrawCircleSectorLines" T:lib
             (_fun (c : C:_vec2-bytes) _float _float _float _int
                   (col : C:_color-bytes) -> _void))])
    (λ (center radius start-angle end-angle segments color)
      (f (C:vec2->bytes center) radius start-angle end-angle
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
;; 三角形扇形绘制 (shapes_top_down_lights.c)
;; DrawTriangleFan(const Vector2 *points, int pointCount, Color color)
;; ============================================================

(define draw-triangle-fan
  (let ([f (get-ffi-obj "DrawTriangleFan" T:lib
             (_fun _pointer _int (col : C:_color-bytes) -> _void))])
    (λ (points-vec point-count color)
      ;; points-vec: vector of Vector2 pointers
      ;; Allocate a flat float buffer: 2*point-count floats
      (let ([buf (malloc _float (* 2 point-count) 'atomic)])
        (for ([i (in-range point-count)])
          (let ([v (vector-ref points-vec i)])
            (ptr-set! buf _float (* 2 i)     (ptr-ref v _float 0))
            (ptr-set! buf _float (+ (* 2 i) 1) (ptr-ref v _float 1))))
        (f buf point-count (C:color->bytes color))))))

;; ============================================================
;; 渐变矩形填充 (shapes_rectangle_advanced.c)
;; DrawRectangleGradientEx(Rectangle rec, Color topLeft, Color bottomLeft,
;;                         Color bottomRight, Color topRight)
;; ============================================================

(define draw-rectangle-gradient-ex
  (let ([f (get-ffi-obj "DrawRectangleGradientEx" T:lib
             (_fun (r : C:_rect-bytes)
                   (col1 : C:_color-bytes) (col2 : C:_color-bytes)
                   (col3 : C:_color-bytes) (col4 : C:_color-bytes) -> _void))])
    (λ (rec top-left bottom-left bottom-right top-right)
      (f (C:rect->bytes rec)
         (C:color->bytes top-left) (C:color->bytes bottom-left)
         (C:color->bytes bottom-right) (C:color->bytes top-right)))))

;; ============================================================
;; Shapes 纹理获取 (shapes_rectangle_advanced.c)
;; GetShapesTexture(void) -> Texture2D
;; GetShapesTextureRectangle(void) -> Rectangle
;; ============================================================

(define get-shapes-texture
  (let ([f (get-ffi-obj "GetShapesTexture" T:lib
             (_fun -> (t : TX:_texture-bytes)))])
    (λ () (f))))

(define get-shapes-texture-rectangle
  (let ([f (get-ffi-obj "GetShapesTextureRectangle" T:lib
             (_fun -> (r : C:_rect-bytes)))])
    (λ () (C:rect-bytes->rect (f)))))

;; ============================================================
;; rlgl 低层绘制函数 (shapes_rectangle_advanced.c)
;; ============================================================

(define rl-set-texture
  (get-ffi-obj "rlSetTexture" T:lib (_fun _uint -> _void)))

(define rl-begin
  (get-ffi-obj "rlBegin" T:lib (_fun _int -> _void)))

(define rl-end
  (get-ffi-obj "rlEnd" T:lib (_fun -> _void)))

(define rl-vertex-2f
  (get-ffi-obj "rlVertex2f" T:lib (_fun _float _float -> _void)))

(define rl-tex-coord-2f
  (get-ffi-obj "rlTexCoord2f" T:lib (_fun _float _float -> _void)))

(define rl-color-4ub
  (get-ffi-obj "rlColor4ub" T:lib (_fun _ubyte _ubyte _ubyte _ubyte -> _void)))

;; ============================================================
;; rlgl 绘制模式常量
;; ============================================================

(define RL-QUADS     #x0007)
(define RL-TRIANGLES #x0004)

;; ============================================================
;; 渐变圆角矩形绘制 (shapes_rectangle_advanced.c — 自定义函数)
;;
;; DrawRectangleRoundedGradientH:
;;   绘制水平渐变圆角矩形，左右两侧可分别设置圆角半径
;;
;; 对应 C: static void DrawRectangleRoundedGradientH()
;; ============================================================

(define deg2rad (/ pi 180.0))

(define (draw-rectangle-rounded-gradient-h
         rec roundness-left roundness-right segments left-color right-color)
  (define rec-x   (ptr-ref rec _float 0))
  (define rec-y   (ptr-ref rec _float 1))
  (define rec-w   (ptr-ref rec _float 2))
  (define rec-h   (ptr-ref rec _float 3))

  (if (or (and (<= roundness-left 0.0) (<= roundness-right 0.0))
          (< rec-w 1) (< rec-h 1))
      (draw-rectangle-gradient-ex rec left-color left-color right-color right-color)
      (let ([roundness-left  (min roundness-left 1.0)]
            [roundness-right (min roundness-right 1.0)]
            [rec-size (min rec-w rec-h)]
            [radius-left  0.0]
            [radius-right 0.0])
        (set! radius-left  (/ (* rec-size roundness-left)  2.0))
        (set! radius-right (/ (* rec-size roundness-right) 2.0))
        (when (< radius-left  0.0) (set! radius-left  0.0))
        (when (< radius-right 0.0) (set! radius-right 0.0))
        (when (and (<= radius-right 0.0) (<= radius-left 0.0))
          (error "draw-rectangle-rounded-gradient-h: both radii zero"))
        (define step-length (/ 90.0 segments))

        ;; 12 个点坐标: 每个点为 (list x y)
        (define points
          (vector
           (list (+ rec-x radius-left) rec-y)
           (list (- (+ rec-x rec-w) radius-right) rec-y)
           (list (+ rec-x rec-w) (+ rec-y radius-right))
           (list (+ rec-x rec-w) (- (+ rec-y rec-h) radius-right))
           (list (- (+ rec-x rec-w) radius-right) (+ rec-y rec-h))
           (list (+ rec-x radius-left) (+ rec-y rec-h))
           (list rec-x (- (+ rec-y rec-h) radius-left))
           (list rec-x (+ rec-y radius-left))
           (list (+ rec-x radius-left) (+ rec-y radius-left))
           (list (- (+ rec-x rec-w) radius-right) (+ rec-y radius-right))
           (list (- (+ rec-x rec-w) radius-right) (- (+ rec-y rec-h) radius-right))
           (list (+ rec-x radius-left) (- (+ rec-y rec-h) radius-left))))
        ;; 4 个圆心
        (define centers (vector (vector-ref points 8) (vector-ref points 9)
                                (vector-ref points 10) (vector-ref points 11)))
        (define angles (vector 180.0 270.0 0.0 90.0))

        ;; 获取 shapes 纹理
        (define tex-shapes (get-shapes-texture))
        (define tex-id (car tex-shapes))
        (define tex-w  (cadr tex-shapes))
        (define tex-h  (caddr tex-shapes))
        (define shape-rect (get-shapes-texture-rectangle))
        (define sr-x (ptr-ref shape-rect _float 0))
        (define sr-y (ptr-ref shape-rect _float 1))
        (define sr-w (ptr-ref shape-rect _float 2))
        (define sr-h (ptr-ref shape-rect _float 3))

        (define (rl-color c)
          (rl-color-4ub (ptr-ref c _ubyte 0)
                        (ptr-ref c _ubyte 1)
                        (ptr-ref c _ubyte 2)
                        (ptr-ref c _ubyte 3)))
        (define (pt-x p) (car p))
        (define (pt-y p) (cadr p))

        ;; ---- 开始 QUADS 绘制 ----
        (rl-set-texture tex-id)
        (rl-begin RL-QUADS)

        ;; 4 个圆角
        (for ([k (in-range 4)])
          (define color (case k [(0) left-color] [(1) right-color]
                               [(2) right-color] [(3) left-color]))
          (define radius (case k [(0) radius-left] [(1) radius-right]
                                [(2) radius-right] [(3) radius-left]))
          (define base-angle (vector-ref angles k))
          (define cx (pt-x (vector-ref centers k)))
          (define cy (pt-y (vector-ref centers k)))
          (for ([i (in-range (quotient segments 2))])
            (rl-color color)
            (rl-tex-coord-2f (/ sr-x tex-w) (/ sr-y tex-h))
            (rl-vertex-2f cx cy)
            (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ sr-y tex-h))
            (rl-vertex-2f
             (+ cx (* (cos (* deg2rad (+ base-angle (* step-length 2 i 2)))) radius))
             (+ cy (* (sin (* deg2rad (+ base-angle (* step-length 2 i 2)))) radius)))
            (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ (+ sr-y sr-h) tex-h))
            (rl-vertex-2f
             (+ cx (* (cos (* deg2rad (+ base-angle (* step-length 2 i 1)))) radius))
             (+ cy (* (sin (* deg2rad (+ base-angle (* step-length 2 i 1)))) radius)))
            (rl-tex-coord-2f (/ sr-x tex-w) (/ (+ sr-y sr-h) tex-h))
            (rl-vertex-2f
             (+ cx (* (cos (* deg2rad (+ base-angle (* step-length 2 i 0)))) radius))
             (+ cy (* (sin (* deg2rad (+ base-angle (* step-length 2 i 0)))) radius))))
          (when (odd? segments)
            (rl-color color)
            (rl-tex-coord-2f (/ sr-x tex-w) (/ sr-y tex-h))
            (rl-vertex-2f cx cy)
            (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ (+ sr-y sr-h) tex-h))
            (rl-vertex-2f
             (+ cx (* (cos (* deg2rad (+ base-angle (* (quotient segments 2) 2) step-length))) radius))
             (+ cy (* (sin (* deg2rad (+ base-angle (* (quotient segments 2) 2) step-length))) radius)))
            (rl-tex-coord-2f (/ sr-x tex-w) (/ (+ sr-y sr-h) tex-h))
            (rl-vertex-2f
             (+ cx (* (cos (* deg2rad (+ base-angle (* (quotient segments 2) 2)))) radius))
             (+ cy (* (sin (* deg2rad (+ base-angle (* (quotient segments 2) 2)))) radius)))
            (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ sr-y tex-h))
            (rl-vertex-2f cx cy)))
        ;; [2] 上方矩形
        (rl-color left-color)
        (rl-tex-coord-2f (/ sr-x tex-w) (/ sr-y tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 0)) (pt-y (vector-ref points 0)))
        (rl-tex-coord-2f (/ sr-x tex-w) (/ (+ sr-y sr-h) tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 8)) (pt-y (vector-ref points 8)))
        (rl-color right-color)
        (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ (+ sr-y sr-h) tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 9)) (pt-y (vector-ref points 9)))
        (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ sr-y tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 1)) (pt-y (vector-ref points 1)))
        ;; [4] 右方矩形
        (rl-color right-color)
        (rl-tex-coord-2f (/ sr-x tex-w) (/ sr-y tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 2)) (pt-y (vector-ref points 2)))
        (rl-tex-coord-2f (/ sr-x tex-w) (/ (+ sr-y sr-h) tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 9)) (pt-y (vector-ref points 9)))
        (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ (+ sr-y sr-h) tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 10)) (pt-y (vector-ref points 10)))
        (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ sr-y tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 3)) (pt-y (vector-ref points 3)))
        ;; [6] 下方矩形
        (rl-color left-color)
        (rl-tex-coord-2f (/ sr-x tex-w) (/ sr-y tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 11)) (pt-y (vector-ref points 11)))
        (rl-tex-coord-2f (/ sr-x tex-w) (/ (+ sr-y sr-h) tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 5)) (pt-y (vector-ref points 5)))
        (rl-color right-color)
        (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ (+ sr-y sr-h) tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 4)) (pt-y (vector-ref points 4)))
        (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ sr-y tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 10)) (pt-y (vector-ref points 10)))
        ;; [8] 左方矩形
        (rl-color left-color)
        (rl-tex-coord-2f (/ sr-x tex-w) (/ sr-y tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 7)) (pt-y (vector-ref points 7)))
        (rl-tex-coord-2f (/ sr-x tex-w) (/ (+ sr-y sr-h) tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 6)) (pt-y (vector-ref points 6)))
        (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ (+ sr-y sr-h) tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 11)) (pt-y (vector-ref points 11)))
        (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ sr-y tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 8)) (pt-y (vector-ref points 8)))
        ;; [9] 中间矩形
        (rl-color left-color)
        (rl-tex-coord-2f (/ sr-x tex-w) (/ sr-y tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 8)) (pt-y (vector-ref points 8)))
        (rl-tex-coord-2f (/ sr-x tex-w) (/ (+ sr-y sr-h) tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 11)) (pt-y (vector-ref points 11)))
        (rl-color right-color)
        (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ (+ sr-y sr-h) tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 10)) (pt-y (vector-ref points 10)))
        (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ sr-y tex-h))
        (rl-vertex-2f (pt-x (vector-ref points 9)) (pt-y (vector-ref points 9)))
        (rl-end)
        (rl-set-texture 0))))

;; ============================================================
;; 样条线绘制 (shapes_splines_drawing.c)
;; DrawSplineLinear(const Vector2 *points, int pointCount, float thick, Color color)
;; DrawSplineBasis(const Vector2 *points, int pointCount, float thick, Color color)
;; DrawSplineCatmullRom(const Vector2 *points, int pointCount, float thick, Color color)
;; DrawSplineBezierCubic(const Vector2 *points, int pointCount, float thick, Color color)
;; ============================================================
;; 辅助: 将 Vector2 指针向量展平为 float 缓冲区
(define (vec2-vector->float-buf points-vec point-count)
  (let ([buf (malloc _float (* 2 point-count) 'atomic)])
    (for ([i (in-range point-count)])
      (let ([v (vector-ref points-vec i)])
        (ptr-set! buf _float (* 2 i)     (ptr-ref v _float 0))
        (ptr-set! buf _float (+ (* 2 i) 1) (ptr-ref v _float 1))))
    buf))

(define draw-spline-linear
  (let ([f (get-ffi-obj "DrawSplineLinear" T:lib
             (_fun _pointer _int _float (col : C:_color-bytes) -> _void))])
    (λ (points-vec point-count thick color)
      (f (vec2-vector->float-buf points-vec point-count)
         point-count thick (C:color->bytes color)))))

(define draw-spline-basis
  (let ([f (get-ffi-obj "DrawSplineBasis" T:lib
             (_fun _pointer _int _float (col : C:_color-bytes) -> _void))])
    (λ (points-vec point-count thick color)
      (f (vec2-vector->float-buf points-vec point-count)
         point-count thick (C:color->bytes color)))))

(define draw-spline-catmull-rom
  (let ([f (get-ffi-obj "DrawSplineCatmullRom" T:lib
             (_fun _pointer _int _float (col : C:_color-bytes) -> _void))])
    (λ (points-vec point-count thick color)
      (f (vec2-vector->float-buf points-vec point-count)
         point-count thick (C:color->bytes color)))))

(define draw-spline-bezier-cubic
  (let ([f (get-ffi-obj "DrawSplineBezierCubic" T:lib
             (_fun _pointer _int _float (col : C:_color-bytes) -> _void))])
    (λ (points-vec point-count thick color)
      (f (vec2-vector->float-buf points-vec point-count)
         point-count thick (C:color->bytes color)))))

;; ============================================================
;; 样条线段绘制 (单个段，Vector2 传值)
;; DrawSplineSegmentLinear(Vector2 p1, Vector2 p2, float thick, Color color)
;; DrawSplineSegmentBasis(Vector2 p1, Vector2 p2, Vector2 p3, Vector2 p4, float thick, Color color)
;; DrawSplineSegmentCatmullRom(Vector2 p1, Vector2 p2, Vector2 p3, Vector2 p4, float thick, Color color)
;; DrawSplineSegmentBezierCubic(Vector2 p1, Vector2 c2, Vector2 c3, Vector2 p4, float thick, Color color)
;; ============================================================

(define draw-spline-segment-linear
  (let ([f (get-ffi-obj "DrawSplineSegmentLinear" T:lib
             (_fun (p1 : C:_vec2-bytes) (p2 : C:_vec2-bytes)
                   _float (col : C:_color-bytes) -> _void))])
    (λ (p1 p2 thick color)
      (f (C:vec2->bytes p1) (C:vec2->bytes p2)
         thick (C:color->bytes color)))))

(define draw-spline-segment-basis
  (let ([f (get-ffi-obj "DrawSplineSegmentBasis" T:lib
             (_fun (p1 : C:_vec2-bytes) (p2 : C:_vec2-bytes)
                   (p3 : C:_vec2-bytes) (p4 : C:_vec2-bytes)
                   _float (col : C:_color-bytes) -> _void))])
    (λ (p1 p2 p3 p4 thick color)
      (f (C:vec2->bytes p1) (C:vec2->bytes p2)
         (C:vec2->bytes p3) (C:vec2->bytes p4)
         thick (C:color->bytes color)))))

(define draw-spline-segment-catmull-rom
  (let ([f (get-ffi-obj "DrawSplineSegmentCatmullRom" T:lib
             (_fun (p1 : C:_vec2-bytes) (p2 : C:_vec2-bytes)
                   (p3 : C:_vec2-bytes) (p4 : C:_vec2-bytes)
                   _float (col : C:_color-bytes) -> _void))])
    (λ (p1 p2 p3 p4 thick color)
      (f (C:vec2->bytes p1) (C:vec2->bytes p2)
         (C:vec2->bytes p3) (C:vec2->bytes p4)
         thick (C:color->bytes color)))))

(define draw-spline-segment-bezier-cubic
  (let ([f (get-ffi-obj "DrawSplineSegmentBezierCubic" T:lib
             (_fun (p1 : C:_vec2-bytes) (c2 : C:_vec2-bytes)
                   (c3 : C:_vec2-bytes) (p4 : C:_vec2-bytes)
                   _float (col : C:_color-bytes) -> _void))])
    (λ (p1 c2 c3 p4 thick color)
      (f (C:vec2->bytes p1) (C:vec2->bytes c2)
         (C:vec2->bytes c3) (C:vec2->bytes p4)
         thick (C:color->bytes color)))))

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
 draw-rectangle-rounded-lines-ex
 draw-rectangle-v
 draw-rectangle-gradient-h
 draw-triangle
 draw-triangle-fan
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
 check-collision-recs
 get-collision-rec
 draw-ring
 draw-ring-lines
 draw-circle-sector
 draw-circle-sector-lines
 draw-rectangle-pro
 draw-rectangle-gradient-ex
 get-shapes-texture
 get-shapes-texture-rectangle
 rl-set-texture
 rl-begin
 rl-end
 rl-vertex-2f
 rl-tex-coord-2f
 rl-color-4ub
 RL-QUADS
 RL-TRIANGLES
 draw-rectangle-rounded-gradient-h
 vec2-vector->float-buf
 draw-spline-linear
 draw-spline-basis
 draw-spline-catmull-rom
 draw-spline-bezier-cubic
 draw-spline-segment-linear
 draw-spline-segment-basis
 draw-spline-segment-catmull-rom
 draw-spline-segment-bezier-cubic)
