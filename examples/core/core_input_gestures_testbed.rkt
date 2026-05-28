#lang racket/base

;; raylib [core] example - input gestures testbed (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_input_gestures_testbed.c

(require racket/format
         racket/string
         racket/math
         racket/match
         "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define GESTURE-LOG-SIZE 20)
(define MAX-TOUCH-COUNT 32)

(define screen-width 800)
(define screen-height 450)

;; ============================================================
;; 辅助: 手势 → 名称 / 颜色
;; ============================================================

(define (get-gesture-name g)
  (match g
    [0  "None"] [1  "Tap"] [2  "Double Tap"]
    [4  "Hold"] [8  "Drag"]
    [16 "Swipe Right"] [32 "Swipe Left"]
    [64 "Swipe Up"]   [128 "Swipe Down"]
    [256 "Pinch In"]  [512 "Pinch Out"]
    [_   "Unknown"]))

(define (get-gesture-color g)
  (match g
    [0    BLACK]   [1  BLUE]    [2    SKYBLUE]
    [4    BLACK]   [8  LIME]
    [16   RED]     [32 RED]     [64   RED]    [128 RED]
    [256  VIOLET]  [512 ORANGE]
    [_    BLACK]))

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [core] example - input gestures testbed")

(define message-position (vector2 160 7))
(define last-gesture-position (vector2 165 130))
(define gesture-log-position (vector2 10 10))
(define protractor-position (vector2 266.0 315.0))

(define log-button-1 (rectangle 53 7 48 26))
(define log-button-2 (rectangle 108 7 36 26))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ([last-gesture 0]
           [gesture-log (make-vector GESTURE-LOG-SIZE "")]
           [gesture-log-idx GESTURE-LOG-SIZE]
           [prev-gesture 0]
           [log-mode 1]
           [current-angle-degrees 0.0])
  (unless (window-should-close?)
    ;; === 更新 ===
    (define current-gesture (get-gesture-detected))
    (define current-drag-degrees (get-gesture-drag-angle))
    (define current-pinch-degrees (get-gesture-pinch-angle))
    (define touch-count (get-touch-point-count))

    ;; Handle last gesture
    (define new-last-gesture
      (if (and (not (= current-gesture 0))
               (not (= current-gesture 4))
               (not (= current-gesture prev-gesture)))
          current-gesture
          last-gesture))

    ;; Handle log mode buttons
    (define new-log-mode
      (if (is-mouse-button-released MOUSE-BUTTON-LEFT)
          (cond
            [(check-collision-point-rec (get-mouse-position) log-button-1)
             (match log-mode
               [3 2] [2 3] [1 0] [_ 1])]
            [(check-collision-point-rec (get-mouse-position) log-button-2)
             (match log-mode
               [3 1] [2 0] [1 3] [_ 2])]
            [else log-mode])
          log-mode))


    ;; Handle gesture log filling
    (define fill-log?
      (cond
        [(= current-gesture 0) #f]
        [(= log-mode 3) (and (not (= current-gesture 4))
                              (not (= current-gesture prev-gesture)))]
        [(= log-mode 2) (not (= current-gesture 4))]
        [(= log-mode 1) (not (= current-gesture prev-gesture))]
        [else #t]))

    (define-values (new-gesture-log new-gesture-log-idx new-prev-gesture new-gesture-color)
      (if fill-log?
          (let ([new-idx (if (<= gesture-log-idx 0) GESTURE-LOG-SIZE (sub1 gesture-log-idx))])
            (vector-set! gesture-log new-idx (get-gesture-name current-gesture))
            (values gesture-log new-idx current-gesture (get-gesture-color current-gesture)))
          (values gesture-log gesture-log-idx prev-gesture
                  (if (= current-gesture 0) BLACK (get-gesture-color current-gesture)))))

    ;; Handle protractor angle
    (define new-angle-degrees
      (cond
        [(> current-gesture 255) current-pinch-degrees]
        [(> current-gesture 15)  current-drag-degrees]
        [(> current-gesture 0)   0.0]
        [else current-angle-degrees]))

    (define current-angle-radians (* (+ new-angle-degrees 90.0) (/ pi 180.0)))
    (define final-vector
      (vector2 (+ (* 90.0 (sin current-angle-radians)) (vector2-x protractor-position))
               (+ (* 90.0 (cos current-angle-radians)) (vector2-y protractor-position))))

    ;; Touch positions
    (define touch-positions
      (for/vector ([i (min touch-count MAX-TOUCH-COUNT)])
        (get-touch-position i)))
    (define mouse-pos
      (if (= touch-count 0) (get-mouse-position) (vector2 0 0)))

    ;; === 绘制 ===
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 公共元素
    (define mx (inexact->exact (round (vector2-x message-position))))
    (define my (inexact->exact (round (vector2-y message-position))))
    (draw-text "*" (+ mx 5) (+ my 5) 10 BLACK)
    (draw-text "Example optimized for Web/HTML5\non Smartphones with Touch Screen."
               (+ mx 15) (+ my 5) 10 BLACK)
    (draw-text "*" (+ mx 5) (+ my 35) 10 BLACK)
    (draw-text "While running on Desktop Web Browsers,\ninspect and turn on Touch Emulation."
               (+ mx 15) (+ my 35) 10 BLACK)

    ;; Last gesture 区域
    (define lx (inexact->exact (round (vector2-x last-gesture-position))))
    (define ly (inexact->exact (round (vector2-y last-gesture-position))))
    (draw-text "Last gesture" (+ lx 33) (- ly 47) 20 BLACK)
    (draw-text "Swipe         Tap       Pinch  Touch" (+ lx 17) (- ly 18) 10 BLACK)

    (draw-rectangle (+ lx 20) ly 20 20 (if (= new-last-gesture GESTURE-SWIPE-UP) RED LIGHTGRAY))
    (draw-rectangle lx (+ ly 20) 20 20 (if (= new-last-gesture GESTURE-SWIPE-LEFT) RED LIGHTGRAY))
    (draw-rectangle (+ lx 40) (+ ly 20) 20 20 (if (= new-last-gesture GESTURE-SWIPE-RIGHT) RED LIGHTGRAY))
    (draw-rectangle (+ lx 20) (+ ly 40) 20 20 (if (= new-last-gesture GESTURE-SWIPE-DOWN) RED LIGHTGRAY))
    (draw-circle (+ lx 80) (+ ly 16) 10.0 (if (= new-last-gesture GESTURE-TAP) BLUE LIGHTGRAY))
    (draw-ring (vector2 (+ lx 103.0) (+ ly 16.0)) 6.0 11.0 0.0 360.0 0
               (if (= new-last-gesture GESTURE-DRAG) LIME LIGHTGRAY))
    (draw-circle (+ lx 80) (+ ly 43) 10.0 (if (= new-last-gesture GESTURE-DOUBLETAP) SKYBLUE LIGHTGRAY))
    (draw-circle (+ lx 103) (+ ly 43) 10.0 (if (= new-last-gesture GESTURE-DOUBLETAP) SKYBLUE LIGHTGRAY))
    (draw-triangle (vector2 (+ lx 122.0) (+ ly 16.0))
                   (vector2 (+ lx 137.0) (+ ly 26.0))
                   (vector2 (+ lx 137.0) (+ ly 6.0))
                   (if (= new-last-gesture GESTURE-PINCH-OUT) ORANGE LIGHTGRAY))
    (draw-triangle (vector2 (+ lx 147.0) (+ ly 6.0))
                   (vector2 (+ lx 147.0) (+ ly 26.0))
                   (vector2 (+ lx 162.0) (+ ly 16.0))
                   (if (= new-last-gesture GESTURE-PINCH-OUT) ORANGE LIGHTGRAY))
    (draw-triangle (vector2 (+ lx 125.0) (+ ly 33.0))
                   (vector2 (+ lx 125.0) (+ ly 53.0))
                   (vector2 (+ lx 140.0) (+ ly 43.0))
                   (if (= new-last-gesture GESTURE-PINCH-IN) VIOLET LIGHTGRAY))
    (draw-triangle (vector2 (+ lx 144.0) (+ ly 43.0))
                   (vector2 (+ lx 159.0) (+ ly 53.0))
                   (vector2 (+ lx 159.0) (+ ly 33.0))
                   (if (= new-last-gesture GESTURE-PINCH-IN) VIOLET LIGHTGRAY))
    (for ([i (in-range 4)])
      (draw-circle (+ lx 180) (+ ly 7 (* i 15)) 5.0
                   (if (<= touch-count i) LIGHTGRAY new-gesture-color)))

    ;; Gesture log
    (draw-text "Log" (inexact->exact (round (vector2-x gesture-log-position)))
               (inexact->exact (round (vector2-y gesture-log-position))) 20 BLACK)

    (for ([i (in-range GESTURE-LOG-SIZE)])
      (define ii (modulo (+ new-gesture-log-idx i) GESTURE-LOG-SIZE))
      (draw-text (vector-ref new-gesture-log ii)
                 (inexact->exact (round (vector2-x gesture-log-position)))
                 (+ (inexact->exact (round (vector2-y gesture-log-position))) 410 (- (* i 20)))
                 20 (if (= i 0) new-gesture-color LIGHTGRAY)))

    ;; Log mode buttons
    (define-values (log-btn1-color log-btn2-color)
      (match new-log-mode
        [3 (values MAROON MAROON)]
        [2 (values GRAY   MAROON)]
        [1 (values MAROON GRAY)]
        [_ (values GRAY   GRAY)]))
    (draw-rectangle-rec log-button-1 log-btn1-color)
    (draw-text "Hide" (+ (inexact->exact (round (rectangle-x log-button-1))) 7)
               (+ (inexact->exact (round (rectangle-y log-button-1))) 3) 10 WHITE)
    (draw-text "Repeat" (+ (inexact->exact (round (rectangle-x log-button-1))) 7)
                (+ (inexact->exact (round (rectangle-y log-button-1))) 13) 10 WHITE)
    (draw-rectangle-rec log-button-2 log-btn2-color)
    (draw-text "Hide" (+ (inexact->exact (round (rectangle-x log-button-1))) 62)
               (+ (inexact->exact (round (rectangle-y log-button-1))) 3) 10 WHITE)
    (draw-text "Hold" (+ (inexact->exact (round (rectangle-x log-button-1))) 62)
               (+ (inexact->exact (round (rectangle-y log-button-1))) 13) 10 WHITE)

    ;; Protractor
    (define px (inexact->exact (round (vector2-x protractor-position))))
    (define py (inexact->exact (round (vector2-y protractor-position))))
    (draw-text "Angle" (+ px 55) (+ py 76) 10 BLACK)

    (define angle-str (~r new-angle-degrees #:precision '(= 2)))
    (draw-text angle-str (+ px 55) (+ py 92) 20 new-gesture-color)

    (draw-circle-v protractor-position 80.0 WHITE)
    (draw-line-ex (vector2 (- (vector2-x protractor-position) 90.0) (vector2-y protractor-position))
                  (vector2 (+ (vector2-x protractor-position) 90.0) (vector2-y protractor-position))
                  3.0 LIGHTGRAY)
    (draw-line-ex (vector2 (vector2-x protractor-position) (- (vector2-y protractor-position) 90.0))
                  (vector2 (vector2-x protractor-position) (+ (vector2-y protractor-position) 90.0))
                  3.0 LIGHTGRAY)
    (draw-line-ex (vector2 (- (vector2-x protractor-position) 80.0) (- (vector2-y protractor-position) 45.0))
                  (vector2 (+ (vector2-x protractor-position) 80.0) (+ (vector2-y protractor-position) 45.0))
                  3.0 GREEN)
    (draw-line-ex (vector2 (- (vector2-x protractor-position) 80.0) (+ (vector2-y protractor-position) 45.0))
                  (vector2 (+ (vector2-x protractor-position) 80.0) (- (vector2-y protractor-position) 45.0))
                  3.0 GREEN)

    (draw-text "0"   (+ px 96) (- py 9) 20 BLACK)
    (draw-text "30"  (+ px 74) (- py 68) 20 BLACK)
    (draw-text "90"  (- px 11) (- py 110) 20 BLACK)
    (draw-text "150" (- px 100) (- py 68) 20 BLACK)
    (draw-text "180" (- px 124) (- py 9) 20 BLACK)
    (draw-text "210" (- px 100) (+ py 50) 20 BLACK)
    (draw-text "270" (- px 18) (+ py 92) 20 BLACK)
    (draw-text "330" (+ px 72) (+ py 50) 20 BLACK)

    (unless (zero? new-angle-degrees)
      (draw-line-ex protractor-position final-vector 3.0 new-gesture-color))

    ;; Touch / mouse pointer
    (unless (= current-gesture GESTURE-NONE)
      (if (> touch-count 0)
          (begin
            (for ([i (min touch-count MAX-TOUCH-COUNT)])
              (draw-circle-v (vector-ref touch-positions i) 50.0 (fade new-gesture-color 0.5))
              (draw-circle-v (vector-ref touch-positions i) 5.0 new-gesture-color))
            (when (>= touch-count 2)
              (draw-line-ex (vector-ref touch-positions 0) (vector-ref touch-positions 1)
                            (if (= current-gesture 512) 8.0 12.0) new-gesture-color)))
          (begin
            (draw-circle-v mouse-pos 35.0 (fade new-gesture-color 0.5))
            (draw-circle-v mouse-pos 5.0 new-gesture-color))))

    (end-drawing)

    (loop new-last-gesture new-gesture-log new-gesture-log-idx
          new-prev-gesture new-log-mode new-angle-degrees)))




;; ============================================================
;; 清理
;; ============================================================

(close-window)
