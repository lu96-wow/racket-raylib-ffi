#lang racket/base

;; raylib [core] example - input gestures (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_input_gestures.c

(require racket/format
         "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define MAX-GESTURE-STRINGS 20)

(define screen-width 800)
(define screen-height 450)

;; ============================================================
;; 辅助: 手势常量 → 名称字符串
;; ============================================================

(define (gesture-name g)
  (cond
    [(= g GESTURE-TAP)        "GESTURE TAP"]
    [(= g GESTURE-DOUBLETAP)  "GESTURE DOUBLETAP"]
    [(= g GESTURE-HOLD)       "GESTURE HOLD"]
    [(= g GESTURE-DRAG)       "GESTURE DRAG"]
    [(= g GESTURE-SWIPE-RIGHT)"GESTURE SWIPE RIGHT"]
    [(= g GESTURE-SWIPE-LEFT) "GESTURE SWIPE LEFT"]
    [(= g GESTURE-SWIPE-UP)   "GESTURE SWIPE UP"]
    [(= g GESTURE-SWIPE-DOWN) "GESTURE SWIPE DOWN"]
    [(= g GESTURE-PINCH-IN)   "GESTURE PINCH IN"]
    [(= g GESTURE-PINCH-OUT)  "GESTURE PINCH OUT"]
    [else                     ""]))

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [core] example - input gestures")

(define touch-area (rectangle 220 10 (- screen-width 230.0) (- screen-height 20.0)))

(define gesture-strings (make-vector MAX-GESTURE-STRINGS ""))
(define gestures-count 0)

(define current-gesture GESTURE-NONE)
(define last-gesture GESTURE-NONE)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ([current-gesture GESTURE-NONE]
           [last-gesture GESTURE-NONE]
           [gesture-strings (make-vector MAX-GESTURE-STRINGS "")]
           [gestures-count 0])
  (unless (window-should-close?)
    ;; === 更新 ===
    (define new-last-gesture current-gesture)
    (define new-current-gesture (get-gesture-detected))
    (define touch-position (get-touch-position 0))

    (define-values (new-strings new-count)
      (if (and (check-collision-point-rec touch-position touch-area)
               (not (= new-current-gesture GESTURE-NONE))
               (not (= new-current-gesture new-last-gesture)))
          ;; 有新手势
          (let ([name (gesture-name new-current-gesture)]
                [c gestures-count])
            (cond
              [(< c MAX-GESTURE-STRINGS)
               (vector-set! gesture-strings c name)
               (values gesture-strings (add1 c))]
              [else
               ;; 重置
               (values (make-vector MAX-GESTURE-STRINGS "") 0)]))
          ;; 无新手势
          (values gesture-strings gestures-count)))

    ;; === 绘制 ===
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-rectangle-rec touch-area GRAY)
    (draw-rectangle 225 15 (- screen-width 240) (- screen-height 30) RAYWHITE)

    (draw-text "GESTURES TEST AREA" (- screen-width 270) (- screen-height 40) 20
               (fade GRAY 0.5))

    (for ([i (in-range new-count)])
      (if (even? i)
          (draw-rectangle 10 (+ 30 (* 20 i)) 200 20 (fade LIGHTGRAY 0.5))
          (draw-rectangle 10 (+ 30 (* 20 i)) 200 20 (fade LIGHTGRAY 0.3)))

      (if (< i (sub1 new-count))
          (draw-text (vector-ref new-strings i) 35 (+ 36 (* 20 i)) 10 DARKGRAY)
          (draw-text (vector-ref new-strings i) 35 (+ 36 (* 20 i)) 10 MAROON)))

    (draw-rectangle-lines 10 29 200 (- screen-height 50) GRAY)
    (draw-text "DETECTED GESTURES" 50 15 10 GRAY)

    (unless (= new-current-gesture GESTURE-NONE)
      (draw-circle-v touch-position 30.0 MAROON))

    (end-drawing)

    (loop new-current-gesture new-last-gesture new-strings new-count)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
