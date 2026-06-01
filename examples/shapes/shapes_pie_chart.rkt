#lang racket/base
;; raylib [shapes] example - pie chart (Racket FFI 翻译)
;; 键盘控制替代 raygui
(require "../../raylib/raylib.rkt" racket/math)

(define screen-w 800) (define screen-h 450)
(define MAX-SLICES 10)
(define DEG2RAD (/ pi 180.0))
(define RAD2DEG (/ 180.0 pi))

(init-window screen-w screen-h "raylib [shapes] example - pie chart")
(set-target-fps 60)

(define slice-count (box 7))
(define selected (box 0))
(define show-values (box #t))
(define show-percent (box #f))
(define show-donut (box #f))
(define donut-radius (box 25.0))

(define values '#(300.0 100.0 450.0 350.0 600.0 380.0 750.0 500.0 200.0 400.0))
(define labels
  (vector "S01" "S02" "S03" "S04" "S05" "S06" "S07" "S08" "S09" "S10"))

(define panel-w 270) (define margin 5)
(define panel-x (- screen-w margin panel-w)) (define panel-y margin)
(define canvas (rectangle 0 0 panel-x screen-h))
(define center (vector2 (/ panel-x 2) (/ screen-h 2)))
(define radius 205.0)
(let main-loop ()
  (unless (window-should-close?)
    (define n (unbox slice-count))
    (define sel (unbox selected))
    (define total (for/sum ([i (in-range n)]) (vector-ref values i)))

    (when (is-key-pressed KEY-Q) (set-box! slice-count (min MAX-SLICES (max 1 (+ n 1)))))
    (when (is-key-pressed KEY-W) (set-box! slice-count (max 1 (- n 1))))
    (when (is-key-pressed KEY-LEFT-BRACKET)  (set-box! selected (max 0 (- sel 1))))
    (when (is-key-pressed KEY-RIGHT-BRACKET) (set-box! selected (min (sub1 n) (+ sel 1))))
    (when (is-key-pressed KEY-S) (set-box! show-values (not (unbox show-values))))
    (when (is-key-pressed KEY-P) (set-box! show-percent (not (unbox show-percent))))
    (when (is-key-pressed KEY-D) (set-box! show-donut (not (unbox show-donut))))
    (when (is-key-pressed KEY-UP)
      (vector-set! values sel (min 1000.0 (+ (vector-ref values sel) 10.0))))
    (when (is-key-pressed KEY-DOWN)
      (vector-set! values sel (max 0.0 (- (vector-ref values sel) 10.0))))
    (when (and (unbox show-donut) (is-key-pressed KEY-Z))
      (set-box! donut-radius (max 5.0 (- (unbox donut-radius) 5.0))))
    (when (and (unbox show-donut) (is-key-pressed KEY-X))
      (set-box! donut-radius (min (- radius 10.0) (+ (unbox donut-radius) 5.0))))

    ;; 悬停检测
    (define hovered
      (let ([mx (get-mouse-x)] [my (get-mouse-y)])
        (if (check-collision-point-rec (vector2 (exact->inexact mx) (exact->inexact my)) canvas)
            (let* ([dx (- mx (ptr-ref center _float 0))]
                   [dy (- my (ptr-ref center _float 1))]
                   [dist (sqrt (+ (* dx dx) (* dy dy)))])
              (if (<= dist radius)
                  (let ([angle (let ([a (* (atan dy dx) RAD2DEG)])
                                 (if (< a 0) (+ a 360) a))])
                    (let loop ([i 0] [cur 0.0])
                      (if (>= i n) -1
                          (let ([sweep (if (> total 0) (* (/ (vector-ref values i) total) 360.0) 0.0)])
                            (if (and (>= angle cur) (< angle (+ cur sweep))) i
                                (loop (add1 i) (+ cur sweep)))))))
                  -1))
            -1)))

    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 绘制饼图
    (let loop ([i 0] [start 0.0])
      (when (< i n)
        (define sweep (if (> total 0) (* (/ (vector-ref values i) total) 360.0) 0.0))
        (define cr (if (= i (max hovered sel)) (+ radius 20) radius))
        (define col (color-from-hsv (exact->inexact (* (/ i n) 360.0)) 0.75 0.9))
        (draw-circle-sector center cr start (+ start sweep) 120 col)

        (when (> (vector-ref values i) 0)
          (define mid (* DEG2RAD (+ start (/ sweep 2))))
          (define lr (* radius 0.7))
          (define font (get-font-default))
          (define label
            (cond
              [(and (unbox show-values) (unbox show-percent))
               (format "~a (~a%)" (real->decimal-string (vector-ref values i) 1)
                       (real->decimal-string (* (/ (vector-ref values i) total) 100) 0))]
              [(unbox show-values) (real->decimal-string (vector-ref values i) 1)]
              [(unbox show-percent)
               (format "~a%" (real->decimal-string (* (/ (vector-ref values i) total) 100) 0))]
              [else ""]))
          (unless (equal? label "")
            (define ts (measure-text-ex font label 20.0 1.0))
            (draw-text label
              (exact-round (+ (ptr-ref center _float 0) (* (cos mid) lr)
                              (- (/ (ptr-ref ts _float 0) 2))))
              (exact-round (+ (ptr-ref center _float 1) (* (sin mid) lr)
                              (- (/ (ptr-ref ts _float 1) 2))))
              20 WHITE)))

        (when (unbox show-donut)
          (draw-circle-v center (unbox donut-radius) RAYWHITE))
        (loop (add1 i) (+ start sweep))))

    ;; 控制面板
    (define px panel-x) (define py panel-y)
    (draw-rectangle-rec (rectangle px py panel-w (- screen-h (* 2 margin)))
                        (fade LIGHTGRAY 0.5))
    (draw-rectangle-lines-ex (rectangle px py panel-w (- screen-h (* 2 margin))) 1.0 GRAY)

    (draw-text (format "Slices [Q/W]: ~a" n) (+ px 15) (+ py 15) 10 DARKGRAY)
    (draw-text (format "Values [S]: ~a" (if (unbox show-values) "ON" "OFF"))
               (+ px 15) (+ py 45) 10 DARKGRAY)
    (draw-text (format "Pct [P]: ~a" (if (unbox show-percent) "ON" "OFF"))
               (+ px 15) (+ py 70) 10 DARKGRAY)
    (draw-text (format "Donut [D]: ~a" (if (unbox show-donut) "ON" "OFF"))
               (+ px 15) (+ py 95) 10 DARKGRAY)
    (when (unbox show-donut)
      (draw-text (format "R [Z/X]: ~a" (real->decimal-string (unbox donut-radius) 0))
                 (+ px 15) (+ py 115) 10 DARKGRAY))
    (draw-text (format "Slice ~a [ ]" sel) (+ px 15) (+ py 150) 10 DARKGRAY)
    (draw-text (format "Val [UP/DN]: ~a" (real->decimal-string (vector-ref values sel) 0))
               (+ px 15) (+ py 170) 10 DARKGRAY)
    (draw-rectangle (+ px 15) (+ py 195) 20 20
                    (color-from-hsv (exact->inexact (* (/ sel n) 360.0)) 0.75 0.9))
    (draw-text (vector-ref labels sel) (+ px 50) (+ py 200) 10 BLACK)

    (draw-fps 10 10)
    (end-drawing)
    (main-loop)))

(close-window)

