#lang racket/base
;; raylib [shapes] example - pie chart (Racket FFI 翻译)
;; 滑块控制替代 raygui (参照 ring_drawing.rkt)
(require "../../raylib/raylib.rkt"
         racket/match
         racket/math)

(define screen-w 800) (define screen-h 450)
(define MAX-SLICES 10)
(define DEG2RAD (/ pi 180.0))
(define RAD2DEG (/ 180.0 pi))

(init-window screen-w screen-h "raylib [shapes] example - pie chart")

;; ============================================================
;; 滑块 + 复选框控件
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
;; 数据 & 布局
;; ============================================================
(define panel-w 270) (define margin 5)
(define panel-x (- screen-w margin panel-w))
(define canvas (rectangle 0 0 panel-x screen-h))
(define center (vector2 (/ panel-x 2) (/ screen-h 2)))
(define radius 205.0)

(define values (vector 300.0 100.0 450.0 350.0 600.0 380.0 750.0
                       500.0 200.0 400.0))
(define labels #("S01" "S02" "S03" "S04" "S05" "S06" "S07" "S08" "S09" "S10"))

(define slice-count 7)
(define selected 0)
(define show-values #t)
(define show-percent #f)
(define show-donut #f)
(define donut-radius 25.0)

;; 滑块: Slices, DonutRadius, SliceValue
(define sl-slices   (make-slider (+ panel-x 80) (+ margin 10) 120 16 1.0 10.0 7.0 ""))
(define sl-donut-r  (make-slider (+ panel-x 80) (+ margin 130) 120 16 5.0 (- radius 10.0) 25.0 ""))
(define sl-slice-v  (make-slider (+ panel-x 80) (+ margin 200) 120 16 0.0 1000.0 300.0 ""))
;; ============================================================
;; 主循环
;; ============================================================
(let loop ()
  (unless (window-should-close?)
    ;; ---- 更新滑块 ----
    (update-slider sl-slices)
    (set! slice-count (exact-round (slider-val sl-slices)))
    (set! slice-count (max 1 (min MAX-SLICES slice-count)))
    (when (>= selected slice-count) (set! selected (sub1 slice-count)))

    ;; 同步当前切片值到 value 滑块
    (slider-set! sl-slice-v (vector-ref values selected))
    (update-slider sl-slice-v)
    (vector-set! values selected (slider-val sl-slice-v))

    (when show-donut
      (update-slider sl-donut-r)
      (set! donut-radius (slider-val sl-donut-r)))

    (define total (for/sum ([i (in-range slice-count)]) (vector-ref values i)))

    ;; ---- 悬停检测 ----
    (define hovered
      (let ([mx (get-mouse-x)] [my (get-mouse-y)])
        (if (check-collision-point-rec (vector2 (exact->inexact mx)
                                                (exact->inexact my)) canvas)
            (let* ([dx (- mx (ptr-ref center _float 0))]
                   [dy (- my (ptr-ref center _float 1))]
                   [dist (sqrt (+ (* dx dx) (* dy dy)))])
              (if (<= dist radius)
                  (let ([angle (let ([a (* (atan dy dx) RAD2DEG)])
                                 (if (< a 0) (+ a 360) a))])
                    (let hloop ([i 0] [cur 0.0])
                      (if (>= i slice-count) -1
                          (let ([sweep (if (> total 0)
                                          (* (/ (vector-ref values i) total) 360.0)
                                          0.0)])
                            (if (and (>= angle cur) (< angle (+ cur sweep))) i
                                (hloop (add1 i) (+ cur sweep)))))))
                  -1))
            -1)))

    ;; 点击选中切片
    (when (and (>= hovered 0) (is-mouse-button-pressed MOUSE-BUTTON-LEFT))
      (set! selected hovered))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 饼图
    (let ploop ([i 0] [start 0.0])
      (when (< i slice-count)
        (define sweep (if (> total 0) (* (/ (vector-ref values i) total) 360.0) 0.0))
        (define cr (if (= i hovered) (+ radius 20.0) radius))
        (define col (color-from-hsv (exact->inexact (* (/ i slice-count) 360.0)) 0.75 0.9))
        (draw-circle-sector center cr start (+ start sweep) 120 col)

        (when (> (vector-ref values i) 0)
          (define mid (* DEG2RAD (+ start (/ sweep 2))))
          (define lr (* radius 0.7))
          (define label
            (cond
              [(and show-values show-percent)
               (format "~a (~a%)" (real->decimal-string (vector-ref values i) 1)
                       (real->decimal-string (* (/ (vector-ref values i) total) 100) 0))]
              [show-values (real->decimal-string (vector-ref values i) 1)]
              [show-percent
               (format "~a%" (real->decimal-string
                              (* (/ (vector-ref values i) total) 100) 0))]
              [else ""]))
          (unless (equal? label "")
            (draw-text label
              (exact-round (+ (ptr-ref center _float 0) (* (cos mid) lr)))
              (exact-round (+ (ptr-ref center _float 1) (* (sin mid) lr)))
              20 WHITE)))

        (when show-donut
          (draw-circle-v center donut-radius RAYWHITE))
        (ploop (add1 i) (+ start sweep))))

    ;; ---- 控制面板 ----
    (define px panel-x) (define py margin)
    (draw-rectangle-rec (rectangle px py panel-w (- screen-h (* 2 margin)))
                        (fade LIGHTGRAY 0.5))
    (draw-rectangle-lines-ex (rectangle px py panel-w (- screen-h (* 2 margin)))
                             1.0 GRAY)

    ;; Slices 滑块
    (draw-text "Slices" (+ px 15) (+ py 10) 10 DARKGRAY)
    (draw-slider sl-slices)

    ;; 复选框
    (set! show-values
      (draw-checkbox (+ px 20) (+ py 40) "Show Values" show-values))
    (set! show-percent
      (draw-checkbox (+ px 20) (+ py 68) "Show Percentages" show-percent))
    (set! show-donut
      (draw-checkbox (+ px 20) (+ py 96) "Make Donut" show-donut))

    ;; Inner Radius 滑块 (仅 donut 开启时显示)
    (when show-donut
      (draw-text "Inner Radius" (+ px 15) (+ py 118) 10 DARKGRAY)
      (draw-slider sl-donut-r))

    ;; 分隔线
    (draw-line (+ px 10) (+ py 172) (- (+ px panel-w) 10) (+ py 172)
               (fade GRAY 0.5))

    ;; 选中切片编辑
    (draw-text (format "Slice: ~a" (vector-ref labels selected))
               (+ px 15) (+ py 180) 10 DARKGRAY)
    (draw-rectangle (+ px 15) (+ py 198) 20 20
      (color-from-hsv (exact->inexact (* (/ selected (max 1 slice-count)) 360.0))
                      0.75 0.9))
    (draw-slider sl-slice-v)

    (draw-text "Click slice to select, drag slider"
               (+ px 15) (+ py 230) 8 (fade DARKGRAY 0.6))

    (draw-fps 10 10)
    (end-drawing)
    (loop)))

(close-window)

