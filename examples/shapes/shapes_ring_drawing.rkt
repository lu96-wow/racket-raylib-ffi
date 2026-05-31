#lang racket/base

;; raylib [shapes] example - ring drawing (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_ring_drawing.c
;; DrawRingLines / DrawCircleSectorLines 新增绑定
;; raygui 用键盘控制替代

(require "../../raylib/raylib.rkt"
         racket/math)

;; ============================================================
;; 键盘控制参数
;;   键位约定: 上排键增大, 下排键减小
;; ============================================================
;; start-angle:   q↑ / w↓   步进 5
;; end-angle:     a↑ / s↓   步进 5
;; inner-radius:  z↑ / x↓   步进 5
;; outer-radius:  e↑ / r↓   步进 5
;; segments:      d↑ / f↓   步进 1
;; 
;; 模式开关:
;;   t = 切换 Draw Ring
;;   g = 切换 Draw RingLines
;;   h = 切换 Draw CircleLines
;; ============================================================

(define (fmt1 v) (real->decimal-string v 1))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - ring drawing")

(define center (vector2 (/ (- (get-screen-width) 300) 2.0)
                        (/ (get-screen-height) 2.0)))

(define inner-radius      80.0)
(define outer-radius      190.0)
(define start-angle       0.0)
(define end-angle         360.0)
(define segments          0.0)
(define draw-ring?        #t)
(define draw-ring-lines?  #f)
(define draw-circle-lines? #f)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- 更新（键盘控制）----
    (cond
      [(is-key-pressed KEY-Q) (set! start-angle (+ start-angle 5))]
      [(is-key-pressed KEY-W) (set! start-angle (- start-angle 5))])
    (cond
      [(is-key-pressed KEY-A) (set! end-angle (+ end-angle 5))]
      [(is-key-pressed KEY-S) (set! end-angle (- end-angle 5))])
    (cond
      [(is-key-pressed KEY-Z) (set! inner-radius (+ inner-radius 5))]
      [(is-key-pressed KEY-X) (set! inner-radius (- inner-radius 5))])
    (cond
      [(is-key-pressed KEY-E) (set! outer-radius (+ outer-radius 5))]
      [(is-key-pressed KEY-R) (set! outer-radius (- outer-radius 5))])
    (cond
      [(is-key-pressed KEY-D) (set! segments (+ segments 1))]
      [(is-key-pressed KEY-F) (set! segments (- segments 1))])

    (when (is-key-pressed KEY-T) (set! draw-ring? (not draw-ring?)))
    (when (is-key-pressed KEY-G) (set! draw-ring-lines? (not draw-ring-lines?)))
    (when (is-key-pressed KEY-H) (set! draw-circle-lines? (not draw-circle-lines?)))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 分隔线 + 控制面板背景
    (draw-line 500 0 500 (get-screen-height) (fade LIGHTGRAY 0.6))
    (draw-rectangle 500 0 (- (get-screen-width) 500) (get-screen-height)
                    (fade LIGHTGRAY 0.3))

    ;; 绘制环/扇形
    (when draw-ring?
      (draw-ring center inner-radius outer-radius start-angle end-angle
                 (exact-round segments) (fade MAROON 0.3)))
    (when draw-ring-lines?
      (draw-ring-lines center inner-radius outer-radius start-angle end-angle
                       (exact-round segments) (fade BLACK 0.4)))
    (when draw-circle-lines?
      (draw-circle-sector-lines center outer-radius start-angle end-angle
                                (exact-round segments) (fade BLACK 0.4)))

    ;; 参数显示
    (draw-text (string-append "StartAngle  [Q/W]: " (fmt1 start-angle))
               600 40 10 DARKGRAY)
    (draw-text (string-append "EndAngle    [A/S]: " (fmt1 end-angle))
               600 70 10 DARKGRAY)
    (draw-text (string-append "InnerRadius [Z/X]: " (fmt1 inner-radius))
               600 140 10 DARKGRAY)
    (draw-text (string-append "OuterRadius [E/R]: " (fmt1 outer-radius))
               600 170 10 DARKGRAY)
    (draw-text (string-append "Segments    [D/F]: " (fmt1 segments))
               600 240 10 DARKGRAY)

    ;; 模式开关显示
    (define (check-text v) (if v "[x]" "[ ]"))
    (draw-text (string-append (check-text draw-ring?) " Draw Ring       [T]")
               600 320 10 DARKGRAY)
    (draw-text (string-append (check-text draw-ring-lines?) " Draw RingLines   [G]")
               600 350 10 DARKGRAY)
    (draw-text (string-append (check-text draw-circle-lines?) " Draw CircleLines [H]")
               600 380 10 DARKGRAY)

    ;; MODE 文字
    (let ([min-seg (ceiling (/ (- end-angle start-angle) 90))])
      (draw-text (string-append "MODE: " (if (>= segments min-seg) "MANUAL" "AUTO"))
                 600 270 10 (if (>= segments min-seg) MAROON DARKGRAY)))

    ;; 操作提示
    (draw-text "Q/W A/S Z/X E/R D/F = adjust values"
               600 420 8 (fade DARKGRAY 0.6))
    (draw-text "T/G/H = toggle modes"
               600 435 8 (fade DARKGRAY 0.6))

    (draw-fps 10 10)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
