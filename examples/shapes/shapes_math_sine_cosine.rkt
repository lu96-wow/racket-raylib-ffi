#lang racket/base
;; raylib [shapes] example - math sine cosine (Racket FFI 翻译)
;; 滑块控制替代 raygui (参照 ring_drawing.rkt)
(require "../../raylib/raylib.rkt"
         racket/match
         racket/math)

(define WAVE-POINTS 36)
(define screen-w 800) (define screen-h 450)

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window screen-w screen-h "raylib [shapes] example - math sine cosine")

;; ============================================================
;; 滑块 + 复选框
;; ============================================================
(define (make-slider x y w h vmin vmax init label)
  (box (list x y w h vmin vmax init #f label)))
(define SLIDER-HANDLE-W 12)

(define (update-slider sl-box)
  (match-define (list x y w h vmin vmax cur drag? label) (unbox sl-box))
  (define mx (get-mouse-x)) (define my (get-mouse-y))
  (define mdown (is-mouse-button-down MOUSE-BUTTON-LEFT))
  (define mreleased (is-mouse-button-released MOUSE-BUTTON-LEFT))
  (define in-rect (and (>= mx (- x 2)) (<= mx (+ x w 2))
                       (>= my (- y 2)) (<= my (+ y h 2))))
  (define new-drag?
    (cond [mreleased #f] [(and mdown in-rect (not drag?)) #t]
          [drag? (if mdown #t #f)] [else #f]))
  (define new-val
    (if new-drag?
        (let* ([t (max 0.0 (min 1.0 (/ (- mx x) w)))]
               [v (+ vmin (* t (- vmax vmin)))]) v)
        cur))
  (set-box! sl-box (list x y w h vmin vmax new-val new-drag? label)))

(define (draw-slider sl-box)
  (match-define (list x y w h vmin vmax cur drag? label) (unbox sl-box))
  (define range (- vmax vmin))
  (define t (if (zero? range) 0.0 (/ (- cur vmin) range)))
  (define handle-x (+ x (exact-round (* w t))))
  (define track-y (+ y (quotient h 2) -2))
  (draw-rectangle x track-y w 4 (fade GRAY 0.3))
  (draw-rectangle (- handle-x (quotient SLIDER-HANDLE-W 2)) y
                  SLIDER-HANDLE-W h (if drag? MAROON (fade DARKGRAY 0.7)))
  (draw-text (real->decimal-string cur 0) (+ x w 8) (- (+ y (quotient h 2)) 5) 10 DARKGRAY))

(define (slider-val sl-box)
  (cadddr (cdddr (unbox sl-box))))

(define (slider-set! sl-box val)
  (match-define (list x y w h vmin vmax _ drag? label) (unbox sl-box))
  (set-box! sl-box (list x y w h vmin vmax val drag? label)))

(define BOX-SIZE 16)
(define (draw-checkbox x y label-text checked?)
  (define mx (get-mouse-x)) (define my (get-mouse-y))
  (define mclicked (is-mouse-button-pressed MOUSE-BUTTON-LEFT))
  (define new-val
    (if (and mclicked (>= mx x) (<= mx (+ x BOX-SIZE 100))
             (>= my y) (<= my (+ y BOX-SIZE)))
        (not checked?) checked?))
  (draw-rectangle-lines x y BOX-SIZE BOX-SIZE DARKGRAY)
  (when new-val
    (draw-rectangle (+ x 3) (+ y 3) (- BOX-SIZE 6) (- BOX-SIZE 6) MAROON))
  (draw-text label-text (+ x 22) (- (+ y (quotient BOX-SIZE 2)) 5) 10 DARKGRAY)
  new-val)

(set-target-fps 60)

;; ============================================================
;; 几何数据
;; ============================================================
(define DEG2RAD (/ pi 180.0))
(define center (vector2 (- (/ screen-w 2) 30.0) (/ screen-h 2)))
(define start-rect (rectangle 20.0 (- screen-h 120.0) 200.0 100.0))
(define radius 130.0)

;; 预计算正弦/余弦波形点
(define sine-points (make-vector WAVE-POINTS))
(define cos-points  (make-vector WAVE-POINTS))
(for ([i (in-range WAVE-POINTS)])
  (define t (/ i (sub1 WAVE-POINTS)))
  (define a (* t 360.0 DEG2RAD))
  (vector-set! sine-points i
    (vector2 (+ (ptr-ref start-rect _float 0) (* t (ptr-ref start-rect _float 2)))
             (+ (ptr-ref start-rect _float 1) (/ (ptr-ref start-rect _float 3) 2.0)
                (* (- (sin a)) (/ (ptr-ref start-rect _float 3) 2.0)))))
  (vector-set! cos-points i
    (vector2 (+ (ptr-ref start-rect _float 0) (* t (ptr-ref start-rect _float 2)))
             (+ (ptr-ref start-rect _float 1) (/ (ptr-ref start-rect _float 3) 2.0)
                (* (- (cos a)) (/ (ptr-ref start-rect _float 3) 2.0))))))

(define angle 0.0)
(define pause #f)

(define sl-angle (make-slider 640 42 120 16 0.0 360.0 0.0 "Angle"))

;; ============================================================
;; 主循环
;; ============================================================
(let loop ()
  (unless (window-should-close?)
    (when (not pause)
      (set! angle (if (>= angle 360.0) 0.0 (+ angle 1.0))))

    (define arad (* angle DEG2RAD))
    (define cos-v (cos arad)) (define sin-v (sin arad))
    (define pt (vector2 (+ (ptr-ref center _float 0) (* cos-v radius))
                        (- (ptr-ref center _float 1) (* sin-v radius))))
    (define limit-min (vector2 (- (ptr-ref center _float 0) radius)
                               (- (ptr-ref center _float 1) radius)))
    (define limit-max (vector2 (+ (ptr-ref center _float 0) radius)
                               (+ (ptr-ref center _float 1) radius)))
    (define complementary (- 90.0 angle))
    (define supplementary (- 180.0 angle))
    (define explementary  (- 360.0 angle))
    (define tangent (tan arad))
    (define tangent-clamped (max -10.0 (min 10.0 tangent)))
    (define cotangent
      (if (> (abs tangent) 0.001)
          (max (- radius) (min radius (/ 1.0 tangent))) 0.0))
    (define tangent-pt
      (vector2 (+ (ptr-ref center _float 0) radius)
               (- (ptr-ref center _float 1) (* tangent-clamped radius))))
    (define cotangent-pt
      (vector2 (+ (ptr-ref center _float 0) (* cotangent radius))
               (- (ptr-ref center _float 1) radius)))

    (begin-drawing)
    (clear-background RAYWHITE)

    ;; Cotangent 线 (橙色)
    (draw-line-ex (vector2 (ptr-ref center _float 0) (ptr-ref limit-min _float 1))
                  (vector2 (ptr-ref cotangent-pt _float 0) (ptr-ref limit-min _float 1)) 2.0 ORANGE)
    (draw-line-dashed center cotangent-pt 10 4 ORANGE)

    ;; 右侧面板
    (draw-line 580 0 580 (get-screen-height) (color 218 218 218 255))
    (draw-rectangle 580 0 (- (get-screen-width) 580) (get-screen-height)
                    (color 232 232 232 255))

    ;; 圆和坐标轴
    (draw-circle-lines-v center radius GRAY)
    (draw-line-ex (vector2 (ptr-ref center _float 0) (ptr-ref limit-min _float 1))
                  (vector2 (ptr-ref center _float 0) (ptr-ref limit-max _float 1)) 1.0 GRAY)
    (draw-line-ex (vector2 (ptr-ref limit-min _float 0) (ptr-ref center _float 1))
                  (vector2 (ptr-ref limit-max _float 0) (ptr-ref center _float 1)) 1.0 GRAY)

    ;; 波形图坐标轴
    (define sx (ptr-ref start-rect _float 0)) (define sy (ptr-ref start-rect _float 1))
    (define sw (ptr-ref start-rect _float 2)) (define sh (ptr-ref start-rect _float 3))
    (define shy (+ sy (/ sh 2.0)))
    (draw-line-ex (vector2 sx sy) (vector2 sx (+ sy sh)) 2.0 GRAY)
    (draw-line-ex (vector2 (+ sx sw) sy) (vector2 (+ sx sw) (+ sy sh)) 2.0 GRAY)
    (draw-line-ex (vector2 sx shy) (vector2 (+ sx sw) shy) 2.0 GRAY)
    (draw-text "1"   (exact-round (- sx 8))  (exact-round sy)        6 GRAY)
    (draw-text "0"   (exact-round (- sx 8))  (exact-round (- shy 6)) 6 GRAY)
    (draw-text "-1"  (exact-round (- sx 12)) (exact-round (- (+ sy sh) 8)) 6 GRAY)
    (draw-text "0"   (exact-round (- sx 2))  (exact-round (+ sy sh 4)) 6 GRAY)
    (draw-text "360" (exact-round (- (+ sx sw) 8)) (exact-round (+ sy sh 4)) 6 GRAY)

    ;; 正弦 (红色)
    (draw-line-ex (vector2 (ptr-ref center _float 0) (ptr-ref center _float 1))
                  (vector2 (ptr-ref center _float 0) (ptr-ref pt _float 1)) 2.0 RED)
    (draw-line-dashed (vector2 (ptr-ref pt _float 0) (ptr-ref center _float 1))
                      (vector2 (ptr-ref pt _float 0) (ptr-ref pt _float 1)) 10 4 RED)
    (draw-text (format "Sine ~a" (real->decimal-string sin-v 2)) 640 190 6 RED)
    (draw-circle-v (vector2 (+ sx (* (/ angle 360.0) sw))
                            (+ sy (* (+ (- sin-v) 1.0) (/ sh 2.0)))) 4.0 RED)
    (draw-spline-linear sine-points WAVE-POINTS 1.0 RED)

    ;; 余弦 (蓝色)
    (draw-line-ex (vector2 (ptr-ref center _float 0) (ptr-ref center _float 1))
                  (vector2 (ptr-ref pt _float 0) (ptr-ref center _float 1)) 2.0 BLUE)
    (draw-line-dashed (vector2 (ptr-ref center _float 0) (ptr-ref pt _float 1))
                      (vector2 (ptr-ref pt _float 0) (ptr-ref pt _float 1)) 10 4 BLUE)
    (draw-text (format "Cosine ~a" (real->decimal-string cos-v 2)) 640 210 6 BLUE)
    (draw-circle-v (vector2 (+ sx (* (/ angle 360.0) sw))
                            (+ sy (* (+ (- cos-v) 1.0) (/ sh 2.0)))) 4.0 BLUE)
    (draw-spline-linear cos-points WAVE-POINTS 1.0 BLUE)

    ;; 正切 (紫色) / 余切 (橙色)
    (draw-line-ex (vector2 (ptr-ref limit-max _float 0) (ptr-ref center _float 1))
                  (vector2 (ptr-ref limit-max _float 0) (ptr-ref tangent-pt _float 1)) 2.0 PURPLE)
    (draw-line-dashed center tangent-pt 10 4 PURPLE)
    (draw-text (format "Tangent ~a" (real->decimal-string tangent-clamped 2)) 640 230 6 PURPLE)
    (draw-text (format "Cotangent ~a" (real->decimal-string cotangent 2)) 640 250 6 ORANGE)

    ;; 余角/补角/周角 弧
    (draw-circle-sector-lines center (* radius 0.6) (- angle) -90.0 36 BEIGE)
    (draw-text (format "Complementary ~a°" (exact-round complementary)) 640 150 6 BEIGE)
    (draw-circle-sector-lines center (* radius 0.5) (- angle) -180.0 36 DARKBLUE)
    (draw-text (format "Supplementary ~a°" (exact-round supplementary)) 640 130 6 DARKBLUE)
    (draw-circle-sector-lines center (* radius 0.4) (- angle) -360.0 36 PINK)
    (draw-text (format "Explementary ~a°" (exact-round explementary)) 640 170 6 PINK)

    ;; 当前角度弧 + 半径线
    (draw-circle-sector-lines center (* radius 0.7) (- angle) 0.0 36 LIME)
    (draw-line-ex (vector2 (ptr-ref center _float 0) (ptr-ref center _float 1)) pt 2.0 BLACK)
    (draw-circle-v pt 4.0 BLACK)


    ;; ---- UI 控件 ----
    (draw-text "Angle" 640 30 10 DARKGRAY)
    (when (not pause) (slider-set! sl-angle angle))
    (update-slider sl-angle)
    (set! angle (slider-val sl-angle))
    (draw-slider sl-angle)

    (set! pause (draw-checkbox 640 72 "Pause" pause))

    (draw-text "Angle Values" 630 115 10 DARKGRAY)
    (draw-rectangle-lines 620 110 140 170 GRAY)

    (draw-fps 10 10)
    (end-drawing)
    (loop)))

(close-window)