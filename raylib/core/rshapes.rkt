#lang racket/base

;; core/rshapes.rkt — 2D 形状绘制函数绑定 (rshapes.h)

(require ffi/unsafe
         racket/math
         "ffi-helpers.rkt"
         "rlgl.rkt")

;; ═══════════════════════════════════════════════════════════
;; 圆形
;; ═══════════════════════════════════════════════════════════

(define draw-circle
  (let ([f (get-ffi-obj "DrawCircle" lib
                        (_fun _int _int _float (col : _color-bytes) -> _void))])
    (λ (cx cy r c) (f cx cy r (color->bytes c)))))

(define draw-circle-v
  (let ([f (get-ffi-obj "DrawCircleV" lib
                        (_fun (c : _vec2-bytes) _float (col : _color-bytes) -> _void))])
    (λ (center radius color) (f (vec2->bytes center) radius (color->bytes color)))))

(define draw-circle-lines
  (let ([f (get-ffi-obj "DrawCircleLines" lib
                        (_fun _int _int _float (col : _color-bytes) -> _void))])
    (λ (cx cy r c) (f cx cy r (color->bytes c)))))

(define draw-circle-lines-v
  (let ([f (get-ffi-obj "DrawCircleLinesV" lib
                        (_fun (c : _vec2-bytes) _float (col : _color-bytes) -> _void))])
    (λ (center radius color) (f (vec2->bytes center) radius (color->bytes color)))))

(define draw-circle-gradient
  (let ([f (get-ffi-obj "DrawCircleGradient" lib
                        (_fun (c : _vec2-bytes) _float
                              (c1 : _color-bytes) (c2 : _color-bytes) -> _void))])
    (λ (center radius inner outer)
      (f (vec2->bytes center) radius (color->bytes inner) (color->bytes outer)))))

(define draw-circle-sector
  (let ([f (get-ffi-obj "DrawCircleSector" lib
                        (_fun (c : _vec2-bytes) _float _float _float _int
                              (col : _color-bytes) -> _void))])
    (λ (center radius sa ea seg color)
      (f (vec2->bytes center) radius sa ea seg (color->bytes color)))))

(define draw-circle-sector-lines
  (let ([f (get-ffi-obj "DrawCircleSectorLines" lib
                        (_fun (c : _vec2-bytes) _float _float _float _int
                              (col : _color-bytes) -> _void))])
    (λ (center radius sa ea seg color)
      (f (vec2->bytes center) radius sa ea seg (color->bytes color)))))

;; ═══════════════════════════════════════════════════════════
;; 椭圆 / 环形
;; ═══════════════════════════════════════════════════════════

(define draw-ellipse
  (let ([f (get-ffi-obj "DrawEllipse" lib
                        (_fun _int _int _float _float (col : _color-bytes) -> _void))])
    (λ (cx cy rh rv c) (f cx cy rh rv (color->bytes c)))))

(define draw-ellipse-lines
  (let ([f (get-ffi-obj "DrawEllipseLines" lib
                        (_fun _int _int _float _float (col : _color-bytes) -> _void))])
    (λ (cx cy rh rv c) (f cx cy rh rv (color->bytes c)))))

(define draw-ring
  (let ([f (get-ffi-obj "DrawRing" lib
                        (_fun (c : _vec2-bytes) _float _float _float _float _int
                              (col : _color-bytes) -> _void))])
    (λ (center ir or sa ea seg color)
      (f (vec2->bytes center) ir or sa ea seg (color->bytes color)))))

(define draw-ring-lines
  (let ([f (get-ffi-obj "DrawRingLines" lib
                        (_fun (c : _vec2-bytes) _float _float _float _float _int
                              (col : _color-bytes) -> _void))])
    (λ (center ir or sa ea seg color)
      (f (vec2->bytes center) ir or sa ea seg (color->bytes color)))))

;; ═══════════════════════════════════════════════════════════
;; 矩形
;; ═══════════════════════════════════════════════════════════

(define draw-rectangle
  (let ([f (get-ffi-obj "DrawRectangle" lib
                        (_fun _int _int _int _int (col : _color-bytes) -> _void))])
    (λ (x y w h c) (f x y w h (color->bytes c)))))

(define draw-rectangle-v
  (let ([f (get-ffi-obj "DrawRectangleV" lib
                        (_fun (p : _vec2-bytes) (s : _vec2-bytes)
                              (col : _color-bytes) -> _void))])
    (λ (pos size c) (f (vec2->bytes pos) (vec2->bytes size) (color->bytes c)))))

(define draw-rectangle-rec
  (let ([f (get-ffi-obj "DrawRectangleRec" lib
                        (_fun (r : _rectangle-bytes) (col : _color-bytes) -> _void))])
    (λ (rec c) (f (rectangle->bytes rec) (color->bytes c)))))

(define draw-rectangle-pro
  (let ([f (get-ffi-obj "DrawRectanglePro" lib
                        (_fun (r : _rectangle-bytes) (o : _vec2-bytes) _float
                              (col : _color-bytes) -> _void))])
    (λ (rec origin rot c)
      (f (rectangle->bytes rec) (vec2->bytes origin) rot (color->bytes c)))))

(define draw-rectangle-rounded
  (let ([f (get-ffi-obj "DrawRectangleRounded" lib
                        (_fun (r : _rectangle-bytes) _float _int
                              (col : _color-bytes) -> _void))])
    (λ (rec rn seg c) (f (rectangle->bytes rec) rn seg (color->bytes c)))))

(define draw-rectangle-rounded-lines-ex
  (let ([f (get-ffi-obj "DrawRectangleRoundedLinesEx" lib
                        (_fun (r : _rectangle-bytes) _float _int _float
                              (col : _color-bytes) -> _void))])
    (λ (rec rn seg lt c) (f (rectangle->bytes rec) rn seg lt (color->bytes c)))))

(define draw-rectangle-lines
  (let ([f (get-ffi-obj "DrawRectangleLines" lib
                        (_fun _int _int _int _int (col : _color-bytes) -> _void))])
    (λ (x y w h c) (f x y w h (color->bytes c)))))

(define draw-rectangle-lines-ex
  (let ([f (get-ffi-obj "DrawRectangleLinesEx" lib
                        (_fun (r : _rectangle-bytes) _float (col : _color-bytes) -> _void))])
    (λ (rec lt c) (f (rectangle->bytes rec) lt (color->bytes c)))))

(define draw-rectangle-gradient-h
  (let ([f (get-ffi-obj "DrawRectangleGradientH" lib
                        (_fun _int _int _int _int
                              (c1 : _color-bytes) (c2 : _color-bytes) -> _void))])
    (λ (x y w h left right)
      (f x y w h (color->bytes left) (color->bytes right)))))

(define draw-rectangle-gradient-ex
  (let ([f (get-ffi-obj "DrawRectangleGradientEx" lib
                        (_fun (r : _rectangle-bytes)
                              (tl : _color-bytes) (bl : _color-bytes)
                              (br : _color-bytes) (tr : _color-bytes) -> _void))])
    (λ (rec tl bl br tr)
      (f (rectangle->bytes rec) (color->bytes tl) (color->bytes bl)
         (color->bytes br) (color->bytes tr)))))

;; ═══════════════════════════════════════════════════════════
;; 线条
;; ═══════════════════════════════════════════════════════════

(define draw-line-ex
  (let ([f (get-ffi-obj "DrawLineEx" lib
                        (_fun (s : _vec2-bytes) (e : _vec2-bytes) _float
                              (col : _color-bytes) -> _void))])
    (λ (start end thick c)
      (f (vec2->bytes start) (vec2->bytes end) thick (color->bytes c)))))

(define draw-line-v
  (let ([f (get-ffi-obj "DrawLineV" lib
                        (_fun (s : _vec2-bytes) (e : _vec2-bytes)
                              (col : _color-bytes) -> _void))])
    (λ (start end c)
      (f (vec2->bytes start) (vec2->bytes end) (color->bytes c)))))

(define draw-line-bezier
  (let ([f (get-ffi-obj "DrawLineBezier" lib
                        (_fun (s : _vec2-bytes) (e : _vec2-bytes) _float
                              (col : _color-bytes) -> _void))])
    (λ (start end thick c)
      (f (vec2->bytes start) (vec2->bytes end) thick (color->bytes c)))))

(define draw-line-dashed
  (let ([f (get-ffi-obj "DrawLineDashed" lib
                        (_fun (s : _vec2-bytes) (e : _vec2-bytes)
                              _int _int (col : _color-bytes) -> _void))])
    (λ (start end dash space c)
      (f (vec2->bytes start) (vec2->bytes end) dash space (color->bytes c)))))

(define draw-line-3d
  (let ([f (get-ffi-obj "DrawLine3D" lib
                        (_fun (s : _vec3-bytes) (e : _vec3-bytes)
                              (c : _color-bytes) -> _void))])
    (λ (start end color)
      (f (vec3->bytes start) (vec3->bytes end) (color->bytes color)))))

;; ═══════════════════════════════════════════════════════════
;; 三角形
;; ═══════════════════════════════════════════════════════════

(define draw-triangle
  (let ([f (get-ffi-obj "DrawTriangle" lib
                        (_fun (v1 : _vec2-bytes) (v2 : _vec2-bytes) (v3 : _vec2-bytes)
                              (col : _color-bytes) -> _void))])
    (λ (v1 v2 v3 c)
      (f (vec2->bytes v1) (vec2->bytes v2) (vec2->bytes v3) (color->bytes c)))))

(define draw-triangle-lines
  (let ([f (get-ffi-obj "DrawTriangleLines" lib
                        (_fun (v1 : _vec2-bytes) (v2 : _vec2-bytes) (v3 : _vec2-bytes)
                              (col : _color-bytes) -> _void))])
    (λ (v1 v2 v3 c)
      (f (vec2->bytes v1) (vec2->bytes v2) (vec2->bytes v3) (color->bytes c)))))

(define draw-triangle-fan
  (let ([f (get-ffi-obj "DrawTriangleFan" lib
                        (_fun _pointer _int (col : _color-bytes) -> _void))])
    (λ (points-vec pc color)
      (let ([buf (malloc _float (* 2 pc) 'atomic)])
        (for ([i (in-range pc)])
          (let ([v (vector-ref points-vec i)])
            (ptr-set! buf _float (* 2 i)     (ptr-ref v _float 0))
            (ptr-set! buf _float (+ (* 2 i) 1) (ptr-ref v _float 1))))
        (f buf pc (color->bytes color))))))

(define draw-triangle-strip
  (let ([f (get-ffi-obj "DrawTriangleStrip" lib
                        (_fun _pointer _int (col : _color-bytes) -> _void))])
    (λ (points-vec pc color)
      (let ([buf (malloc _float (* 2 pc) 'atomic)])
        (for ([i (in-range pc)])
          (let ([v (vector-ref points-vec i)])
            (ptr-set! buf _float (* 2 i)     (ptr-ref v _float 0))
            (ptr-set! buf _float (+ (* 2 i) 1) (ptr-ref v _float 1))))
        (f buf pc (color->bytes color))))))

(define draw-triangle-gradient
  (let ([f (get-ffi-obj "DrawTriangleGradient" lib
                        (_fun (v1 : _vec2-bytes) (v2 : _vec2-bytes) (v3 : _vec2-bytes)
                              (c1 : _color-bytes) (c2 : _color-bytes)
                              (c3 : _color-bytes) -> _void))])
    (lambda (v1 v2 v3 c1 c2 c3)
      (f (vec2->bytes v1) (vec2->bytes v2) (vec2->bytes v3)
         (color->bytes c1) (color->bytes c2) (color->bytes c3)))))

;; ═══════════════════════════════════════════════════════════
;; 多边形 / 样条线 / 碰撞 / Shapes 纹理
;; ═══════════════════════════════════════════════════════════

(define draw-poly
  (let ([f (get-ffi-obj "DrawPoly" lib
                        (_fun (c : _vec2-bytes) _int _float _float
                              (col : _color-bytes) -> _void))])
    (λ (center sides r rot c)
      (f (vec2->bytes center) sides r rot (color->bytes c)))))

(define draw-poly-lines
  (let ([f (get-ffi-obj "DrawPolyLines" lib
                        (_fun (c : _vec2-bytes) _int _float _float
                              (col : _color-bytes) -> _void))])
    (λ (center sides r rot c)
      (f (vec2->bytes center) sides r rot (color->bytes c)))))

(define draw-poly-lines-ex
  (let ([f (get-ffi-obj "DrawPolyLinesEx" lib
                        (_fun (c : _vec2-bytes) _int _float _float _float
                              (col : _color-bytes) -> _void))])
    (λ (center sides r rot lt c)
      (f (vec2->bytes center) sides r rot lt (color->bytes c)))))

(define draw-spline-linear
  (let ([f (get-ffi-obj "DrawSplineLinear" lib
                        (_fun _pointer _int _float (col : _color-bytes) -> _void))])
    (λ (points-vec pc thick color)
      (f (vec2-vector->float-buf points-vec pc) pc thick (color->bytes color)))))

(define draw-spline-basis
  (let ([f (get-ffi-obj "DrawSplineBasis" lib
                        (_fun _pointer _int _float (col : _color-bytes) -> _void))])
    (λ (points-vec pc thick color)
      (f (vec2-vector->float-buf points-vec pc) pc thick (color->bytes color)))))

(define draw-spline-catmull-rom
  (let ([f (get-ffi-obj "DrawSplineCatmullRom" lib
                        (_fun _pointer _int _float (col : _color-bytes) -> _void))])
    (λ (points-vec pc thick color)
      (f (vec2-vector->float-buf points-vec pc) pc thick (color->bytes color)))))

(define draw-spline-bezier-cubic
  (let ([f (get-ffi-obj "DrawSplineBezierCubic" lib
                        (_fun _pointer _int _float (col : _color-bytes) -> _void))])
    (λ (points-vec pc thick color)
      (f (vec2-vector->float-buf points-vec pc) pc thick (color->bytes color)))))

(define draw-spline-segment-linear
  (let ([f (get-ffi-obj "DrawSplineSegmentLinear" lib
                        (_fun (p1 : _vec2-bytes) (p2 : _vec2-bytes)
                              _float (col : _color-bytes) -> _void))])
    (λ (p1 p2 thick color)
      (f (vec2->bytes p1) (vec2->bytes p2) thick (color->bytes color)))))

(define draw-spline-segment-basis
  (let ([f (get-ffi-obj "DrawSplineSegmentBasis" lib
                        (_fun (p1 : _vec2-bytes) (p2 : _vec2-bytes)
                              (p3 : _vec2-bytes) (p4 : _vec2-bytes)
                              _float (col : _color-bytes) -> _void))])
    (λ (p1 p2 p3 p4 thick color)
      (f (vec2->bytes p1) (vec2->bytes p2)
         (vec2->bytes p3) (vec2->bytes p4)
         thick (color->bytes color)))))

(define draw-spline-segment-catmull-rom
  (let ([f (get-ffi-obj "DrawSplineSegmentCatmullRom" lib
                        (_fun (p1 : _vec2-bytes) (p2 : _vec2-bytes)
                              (p3 : _vec2-bytes) (p4 : _vec2-bytes)
                              _float (col : _color-bytes) -> _void))])
    (λ (p1 p2 p3 p4 thick color)
      (f (vec2->bytes p1) (vec2->bytes p2)
         (vec2->bytes p3) (vec2->bytes p4)
         thick (color->bytes color)))))

(define draw-spline-segment-bezier-cubic
  (let ([f (get-ffi-obj "DrawSplineSegmentBezierCubic" lib
                        (_fun (p1 : _vec2-bytes) (c2 : _vec2-bytes)
                              (c3 : _vec2-bytes) (p4 : _vec2-bytes)
                              _float (col : _color-bytes) -> _void))])
    (λ (p1 c2 c3 p4 thick color)
      (f (vec2->bytes p1) (vec2->bytes c2)
         (vec2->bytes c3) (vec2->bytes p4)
         thick (color->bytes color)))))

(define check-collision-point-rec
  (let ([f (get-ffi-obj "CheckCollisionPointRec" lib
                        (_fun (p : _vec2-bytes) (r : _rectangle-bytes) -> _stdbool))])
    (λ (p r) (f (vec2->bytes p) (rectangle->bytes r)))))

(define check-collision-point-circle
  (let ([f (get-ffi-obj "CheckCollisionPointCircle" lib
                        (_fun (p : _vec2-bytes) (c : _vec2-bytes) _float -> _stdbool))])
    (λ (p c r) (f (vec2->bytes p) (vec2->bytes c) r))))

(define check-collision-recs
  (let ([f (get-ffi-obj "CheckCollisionRecs" lib
                        (_fun (r1 : _rectangle-bytes) (r2 : _rectangle-bytes) -> _stdbool))])
    (λ (r1 r2) (f (rectangle->bytes r1) (rectangle->bytes r2)))))

(define check-collision-circle-rec
  (let ([f (get-ffi-obj "CheckCollisionCircleRec" lib
                        (_fun (c : _vec2-bytes) _float (r : _rectangle-bytes) -> _stdbool))])
    (λ (c radius r) (f (vec2->bytes c) radius (rectangle->bytes r)))))

(define get-collision-rec
  (let ([f (get-ffi-obj "GetCollisionRec" lib
                        (_fun (r1 : _rectangle-bytes) (r2 : _rectangle-bytes)
                              -> (r : _rectangle-bytes)))])
    (λ (r1 r2) (bytes->rectangle (f (rectangle->bytes r1) (rectangle->bytes r2))))))

(define get-shapes-texture
  (let ([f (get-ffi-obj "GetShapesTexture" lib
                        (_fun -> (t : _texture-bytes)))])
    (λ () (f))))

(define get-shapes-texture-rectangle
  (let ([f (get-ffi-obj "GetShapesTextureRectangle" lib
                        (_fun -> (r : _rectangle-bytes)))])
    (λ () (bytes->rectangle (f)))))

;; ═══════════════════════════════════════════════════════════
;; 自定义: 渐变圆角矩形
;; ═══════════════════════════════════════════════════════════

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
      (let* ([roundness-left  (min roundness-left 1.0)]
             [roundness-right (min roundness-right 1.0)]
             [rec-size (min rec-w rec-h)]
             [radius-left  (/ (* rec-size roundness-left)  2.0)]
             [radius-right (/ (* rec-size roundness-right) 2.0)]
             [_ (when (< radius-left  0.0) (set! radius-left  0.0))]
             [_ (when (< radius-right 0.0) (set! radius-right 0.0))]
             [step-length (/ 90.0 segments)]
             [points
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
               (list (+ rec-x radius-left) (- (+ rec-y rec-h) radius-left)))]
             [centers (vector (vector-ref points 8) (vector-ref points 9)
                              (vector-ref points 10) (vector-ref points 11))]
             [angles (vector 180.0 270.0 0.0 90.0)]
             [tex-shapes (get-shapes-texture)]
             [tex-id (car tex-shapes)]
             [tex-w  (cadr tex-shapes)]
             [tex-h  (caddr tex-shapes)]
             [shape-rect (get-shapes-texture-rectangle)]
             [sr-x (ptr-ref shape-rect _float 0)]
             [sr-y (ptr-ref shape-rect _float 1)]
             [sr-w (ptr-ref shape-rect _float 2)]
             [sr-h (ptr-ref shape-rect _float 3)])

        (define (rl-color c)
          (rl-color-4ub (ptr-ref c _ubyte 0) (ptr-ref c _ubyte 1)
                        (ptr-ref c _ubyte 2) (ptr-ref c _ubyte 3)))
        (define (pt-x p) (car p))
        (define (pt-y p) (cadr p))

        (rl-set-texture tex-id)
        (rl-begin RL-QUADS)

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

        ;; 五个矩形面
        (let* ([p0  (vector-ref points 0)] [p1 (vector-ref points 1)]
               [p2  (vector-ref points 2)] [p3 (vector-ref points 3)]
               [p4  (vector-ref points 4)] [p5 (vector-ref points 5)]
               [p6  (vector-ref points 6)] [p7 (vector-ref points 7)]
               [p8  (vector-ref points 8)] [p9 (vector-ref points 9)]
               [p10 (vector-ref points 10)] [p11 (vector-ref points 11)])
          (rl-color left-color)
          (rl-tex-coord-2f (/ sr-x tex-w) (/ sr-y tex-h))
          (rl-vertex-2f (pt-x p0) (pt-y p0))
          (rl-tex-coord-2f (/ sr-x tex-w) (/ (+ sr-y sr-h) tex-h))
          (rl-vertex-2f (pt-x p8) (pt-y p8))
          (rl-color right-color)
          (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ (+ sr-y sr-h) tex-h))
          (rl-vertex-2f (pt-x p9) (pt-y p9))
          (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ sr-y tex-h))
          (rl-vertex-2f (pt-x p1) (pt-y p1))
          (rl-color right-color)
          (rl-tex-coord-2f (/ sr-x tex-w) (/ sr-y tex-h))
          (rl-vertex-2f (pt-x p2) (pt-y p2))
          (rl-tex-coord-2f (/ sr-x tex-w) (/ (+ sr-y sr-h) tex-h))
          (rl-vertex-2f (pt-x p9) (pt-y p9))
          (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ (+ sr-y sr-h) tex-h))
          (rl-vertex-2f (pt-x p10) (pt-y p10))
          (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ sr-y tex-h))
          (rl-vertex-2f (pt-x p3) (pt-y p3))
          (rl-color left-color)
          (rl-tex-coord-2f (/ sr-x tex-w) (/ sr-y tex-h))
          (rl-vertex-2f (pt-x p11) (pt-y p11))
          (rl-tex-coord-2f (/ sr-x tex-w) (/ (+ sr-y sr-h) tex-h))
          (rl-vertex-2f (pt-x p5) (pt-y p5))
          (rl-color right-color)
          (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ (+ sr-y sr-h) tex-h))
          (rl-vertex-2f (pt-x p4) (pt-y p4))
          (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ sr-y tex-h))
          (rl-vertex-2f (pt-x p10) (pt-y p10))
          (rl-color left-color)
          (rl-tex-coord-2f (/ sr-x tex-w) (/ sr-y tex-h))
          (rl-vertex-2f (pt-x p7) (pt-y p7))
          (rl-tex-coord-2f (/ sr-x tex-w) (/ (+ sr-y sr-h) tex-h))
          (rl-vertex-2f (pt-x p6) (pt-y p6))
          (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ (+ sr-y sr-h) tex-h))
          (rl-vertex-2f (pt-x p11) (pt-y p11))
          (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ sr-y tex-h))
          (rl-vertex-2f (pt-x p8) (pt-y p8))
          (rl-color left-color)
          (rl-tex-coord-2f (/ sr-x tex-w) (/ sr-y tex-h))
          (rl-vertex-2f (pt-x p8) (pt-y p8))
          (rl-tex-coord-2f (/ sr-x tex-w) (/ (+ sr-y sr-h) tex-h))
          (rl-vertex-2f (pt-x p11) (pt-y p11))
          (rl-color right-color)
          (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ (+ sr-y sr-h) tex-h))
          (rl-vertex-2f (pt-x p10) (pt-y p10))
          (rl-tex-coord-2f (/ (+ sr-x sr-w) tex-w) (/ sr-y tex-h))
          (rl-vertex-2f (pt-x p9) (pt-y p9)))
        (rl-end)
        (rl-set-texture 0))))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide
 draw-circle draw-circle-v draw-circle-lines draw-circle-lines-v
 draw-circle-gradient draw-circle-sector draw-circle-sector-lines
 draw-ellipse draw-ellipse-lines draw-ring draw-ring-lines
 draw-rectangle draw-rectangle-v draw-rectangle-rec draw-rectangle-pro
 draw-rectangle-rounded draw-rectangle-rounded-lines-ex
 draw-rectangle-lines draw-rectangle-lines-ex
 draw-rectangle-gradient-h draw-rectangle-gradient-ex
 draw-line-ex draw-line-v draw-line-bezier draw-line-dashed draw-line-3d
 draw-triangle draw-triangle-lines draw-triangle-fan draw-triangle-strip
 draw-triangle-gradient
 draw-poly draw-poly-lines draw-poly-lines-ex
 draw-spline-linear draw-spline-basis draw-spline-catmull-rom
 draw-spline-bezier-cubic
 draw-spline-segment-linear draw-spline-segment-basis
 draw-spline-segment-catmull-rom draw-spline-segment-bezier-cubic
 check-collision-point-rec check-collision-point-circle
 check-collision-recs check-collision-circle-rec get-collision-rec
 get-shapes-texture get-shapes-texture-rectangle
 draw-rectangle-rounded-gradient-h)
