#lang racket/base

;; raylib [shapes] example - ring drawing (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_ring_drawing.c
;; raygui 替代: 用 raylib 原生绘制 + 鼠标交互实现滑块/复选框

(require racket/math
         racket/match
         "../../raylib/raylib.rkt")

;; ============================================================
;; 联动滑块控件 (raylib 原生绘制 + 鼠标交互)
;; ============================================================

;; 滑块状态: (box (list x y w h vmin vmax cur-val dragging? label))
(define (make-slider x y w h vmin vmax init label)
  (box (list x y w h vmin vmax init #f label)))

;; 滑块 handle 宽度
(define SLIDER-HANDLE-W 12)

;; 更新: 处理鼠标输入，修改滑块值
(define (update-slider sl-box)
  (match-define (list x y w h vmin vmax cur drag? label) (unbox sl-box))
  (define mx (get-mouse-x))
  (define my (get-mouse-y))
  (define mdown (is-mouse-button-down MOUSE-BUTTON-LEFT))
  (define mreleased (is-mouse-button-released MOUSE-BUTTON-LEFT))
  (define in-rect (and (>= mx (- x 2)) (<= mx (+ x w 2))
                       (>= my (- y 2)) (<= my (+ y h 2))))

  (define new-drag?
    (cond
      [mreleased #f]
      [(and mdown in-rect (not drag?)) #t]
      [drag? (if mdown #t #f)]
      [else #f]))

  ;; 拖拽中更新值
  (define new-val
    (if new-drag?
        (let* ([t (max 0.0 (min 1.0 (/ (- mx x) w)))]
               [v (exact-round (+ vmin (* t (- vmax vmin))))])
          v)
        cur))

  (set-box! sl-box (list x y w h vmin vmax new-val new-drag? label)))

;; 绘制: 渲染滑块外观
(define (draw-slider sl-box)
  (match-define (list x y w h vmin vmax cur drag? label) (unbox sl-box))
  (define range (- vmax vmin))
  (define t (if (zero? range) 0.0 (/ (- cur vmin) range)))
  (define handle-x (+ x (exact-round (* w t))))
  (define track-y (+ y (quotient h 2) -2))
  ;; 轨道
  (draw-rectangle x track-y w 4 (fade GRAY 0.3))
  ;; handle
  (draw-rectangle (- handle-x (quotient SLIDER-HANDLE-W 2)) y
                  SLIDER-HANDLE-W h (if drag? MAROON (fade DARKGRAY 0.7)))
  ;; 值
  (draw-text (number->string cur) (+ x w 8) (- (+ y (quotient h 2)) 5) 10 DARKGRAY))

;; 滑块当前值
(define (slider-val sl-box)
  (cadddr (cdddr (unbox sl-box))))  ;; list-ref at index 6

;; ============================================================
;; 复选框控件
;; ============================================================
(define (draw-checkbox x y label-text checked?)
  (define box-size 16)
  (define mx (get-mouse-x))
  (define my (get-mouse-y))
  (define mclicked (is-mouse-button-pressed MOUSE-BUTTON-LEFT))

  (define new-val
    (if (and mclicked (>= mx x) (<= mx (+ x box-size 100))
             (>= my y) (<= my (+ y box-size)))
        (not checked?)
        checked?))

  (draw-rectangle-lines x y box-size box-size DARKGRAY)
  (when new-val
    (draw-rectangle (+ x 3) (+ y 3) (- box-size 6) (- box-size 6) MAROON))
  (draw-text label-text (+ x 22) (- (+ y (quotient box-size 2)) 5) 10 DARKGRAY)
  new-val)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - ring drawing")

(define center (vector2 (/ (- (get-screen-width) 300) 2.0)
                        (/ (get-screen-height) 2.0)))

;; 参数
(define start-angle    0)
(define end-angle      360)
(define inner-radius   80)
(define outer-radius   190)
(define segments       0)
(define draw-ring?     #t)
(define draw-ring-lines? #f)
(define draw-circle-lines? #f)

;; 滑块: 520 + 150 + 12 = 682 区域
(define sl-start-angle  (make-slider 520  42 150 16 -450 450 0   "StartAngle"))
(define sl-end-angle    (make-slider 520  74 150 16 -450 450 360 "EndAngle"))
(define sl-inner-radius (make-slider 520 140 150 16 0    300 80  "InnerRadius"))
(define sl-outer-radius (make-slider 520 172 150 16 0    400 190 "OuterRadius"))
(define sl-segments     (make-slider 520 238 150 16 0    200 0   "Segments"))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- 更新（鼠标交互）----
    (update-slider sl-start-angle)
    (update-slider sl-end-angle)
    (update-slider sl-inner-radius)
    (update-slider sl-outer-radius)
    (update-slider sl-segments)

    ;; 读取滑块值
    (set! start-angle   (slider-val sl-start-angle))
    (set! end-angle     (slider-val sl-end-angle))
    (set! inner-radius  (slider-val sl-inner-radius))
    (set! outer-radius  (slider-val sl-outer-radius))
    (set! segments      (slider-val sl-segments))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 分隔线 + 控制面板背景
    (draw-line 500 0 500 (get-screen-height) (fade LIGHTGRAY 0.6))
    (draw-rectangle 500 0 (- (get-screen-width) 500) (get-screen-height)
                    (fade LIGHTGRAY 0.3))

    ;; 绘制环/扇形
    (when draw-ring?
      (draw-ring center (exact->inexact inner-radius) (exact->inexact outer-radius)
                 (exact->inexact start-angle) (exact->inexact end-angle)
                 (exact-round segments) (fade MAROON 0.3)))
    (when draw-ring-lines?
      (draw-ring-lines center (exact->inexact inner-radius) (exact->inexact outer-radius)
                       (exact->inexact start-angle) (exact->inexact end-angle)
                       (exact-round segments) (fade BLACK 0.4)))
    (when draw-circle-lines?
      (draw-circle-sector-lines center (exact->inexact outer-radius)
                                (exact->inexact start-angle) (exact->inexact end-angle)
                                (exact-round segments) (fade BLACK 0.4)))

    ;; 绘制滑块
    (draw-slider sl-start-angle)
    (draw-slider sl-end-angle)
    (draw-slider sl-inner-radius)
    (draw-slider sl-outer-radius)
    (draw-slider sl-segments)

    ;; 标签
    (draw-text "StartAngle"   520 30 10 DARKGRAY)
    (draw-text "EndAngle"     520 62 10 DARKGRAY)
    (draw-text "InnerRadius"  520 128 10 DARKGRAY)
    (draw-text "OuterRadius"  520 160 10 DARKGRAY)
    (draw-text "Segments"     520 226 10 DARKGRAY)

    ;; 复选框
    (set! draw-ring?
      (draw-checkbox 520 316 "DrawRing" draw-ring?))
    (set! draw-ring-lines?
      (draw-checkbox 520 346 "DrawRingLines" draw-ring-lines?))
    (set! draw-circle-lines?
      (draw-checkbox 520 376 "DrawCircleLines" draw-circle-lines?))

    ;; MODE
    (define seg-f (exact->inexact segments))
    (define sa-f (exact->inexact start-angle))
    (define ea-f (exact->inexact end-angle))
    (define min-seg (ceiling (/ (- ea-f sa-f) 90)))
    (draw-text (string-append "MODE: " (if (>= seg-f min-seg) "MANUAL" "AUTO"))
               520 270 10 (if (>= seg-f min-seg) MAROON DARKGRAY))

    (draw-text "Drag sliders to adjust values"
               520 415 8 (fade DARKGRAY 0.6))

    (draw-fps 10 10)
    (end-drawing)

    (loop)))

;; 清理
(close-window)
