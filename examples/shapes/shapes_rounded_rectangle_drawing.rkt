#lang racket/base

;; raylib [shapes] example - rounded rectangle drawing (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_rounded_rectangle_drawing.c
;; 滑块控制替代 raygui 滑块 (参照 ring_drawing.rkt)

(require racket/math
         racket/match
         "../../raylib/raylib.rkt")

;; ============================================================
;; 联动滑块控件 (raylib 原生绘制 + 鼠标交互) — 浮点版本
;; ============================================================

;; 滑块状态: (box (list x y w h vmin vmax cur-val dragging? label))
(define (make-slider x y w h vmin vmax init label)
  (box (list x y w h vmin vmax init #f label)))

(define SLIDER-HANDLE-W 12)

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

  (define new-val
    (if new-drag?
        (let* ([t (max 0.0 (min 1.0 (/ (- mx x) w)))]
               [v (+ vmin (* t (- vmax vmin)))])
          v)
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
  (draw-text (real->decimal-string cur 2) (+ x w 8) (- (+ y (quotient h 2)) 5) 10 DARKGRAY))

(define (slider-val sl-box)
  (cadddr (cdddr (unbox sl-box))))

;; ============================================================
;; 复选框控件 (参照 ring_drawing.rkt)
;; ============================================================
(define BOX-SIZE 16)

(define (draw-checkbox x y label-text checked?)
  (define mx (get-mouse-x))
  (define my (get-mouse-y))
  (define mclicked (is-mouse-button-pressed MOUSE-BUTTON-LEFT))

  (define new-val
    (if (and mclicked (>= mx x) (<= mx (+ x BOX-SIZE 100))
             (>= my y) (<= my (+ y BOX-SIZE)))
        (not checked?)
        checked?))

  (draw-rectangle-lines x y BOX-SIZE BOX-SIZE DARKGRAY)
  (when new-val
    (draw-rectangle (+ x 3) (+ y 3) (- BOX-SIZE 6) (- BOX-SIZE 6) MAROON))
  (draw-text label-text (+ x 22) (- (+ y (quotient BOX-SIZE 2)) 5) 10 DARKGRAY)
  new-val)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-w 800)
(define screen-h 450)

(init-window screen-w screen-h
             "raylib [shapes] example - rounded rectangle drawing")

;; 滑块: x=520, w=150, h=16, 范围对应 C 版 raygui GuiSliderBar
(define sl-width      (make-slider 520  42 150 16    0.0 500.0 200.0 "Width"))
(define sl-height     (make-slider 520  74 150 16    0.0 400.0 100.0 "Height"))
(define sl-roundness  (make-slider 520 140 150 16    0.0   1.0   0.2 "Roundness"))
(define sl-thickness  (make-slider 520 172 150 16    0.0  20.0   1.0 "Thickness"))
(define sl-segments   (make-slider 520 238 150 16    0.0  60.0   0.0 "Segments"))

;; 当前值（每帧由滑块/复选框更新）
(define width      200.0)
(define height     100.0)
(define roundness    0.2)
(define thickness    1.0)
(define segments     0.0)
(define draw-rect?          #f)
(define draw-rounded-rect?  #t)
(define draw-rounded-lines? #f)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- 更新（鼠标交互）----
    (update-slider sl-width)
    (update-slider sl-height)
    (update-slider sl-roundness)
    (update-slider sl-thickness)
    (update-slider sl-segments)

    ;; 读取滑块值
    (set! width      (slider-val sl-width))
    (set! height     (slider-val sl-height))
    (set! roundness  (slider-val sl-roundness))
    (set! thickness  (slider-val sl-thickness))
    (set! segments   (slider-val sl-segments))

    ;; ---- 计算矩形位置 ----
    (define rec (rectangle (/ (- (get-screen-width) width 250) 2.0)
                           (/ (- (get-screen-height) height) 2.0)
                           width height))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 分隔线 + 控制面板背景
    (draw-line 560 0 560 (get-screen-height) (fade LIGHTGRAY 0.6))
    (draw-rectangle 560 0 (- (get-screen-width) 500) (get-screen-height)
                    (fade LIGHTGRAY 0.3))

    ;; 矩形绘制
    (when draw-rect?
      (draw-rectangle-rec rec (fade GOLD 0.6)))
    (when draw-rounded-rect?
      (draw-rectangle-rounded rec roundness (exact-round segments) (fade MAROON 0.2)))
    (when draw-rounded-lines?
      (draw-rectangle-rounded-lines-ex rec roundness (exact-round segments) thickness
                                       (fade MAROON 0.4)))

    ;; 绘制滑块
    (draw-slider sl-width)
    (draw-slider sl-height)
    (draw-slider sl-roundness)
    (draw-slider sl-thickness)
    (draw-slider sl-segments)

    ;; 标签
    (draw-text "Width"      520 30 10 DARKGRAY)
    (draw-text "Height"     520 62 10 DARKGRAY)
    (draw-text "Roundness"  520 128 10 DARKGRAY)
    (draw-text "Thickness"  520 160 10 DARKGRAY)
    (draw-text "Segments"   520 226 10 DARKGRAY)

    ;; 复选框
    (set! draw-rounded-rect?
      (draw-checkbox 520 316 "DrawRoundedRect" draw-rounded-rect?))
    (set! draw-rounded-lines?
      (draw-checkbox 520 346 "DrawRoundedLines" draw-rounded-lines?))
    (set! draw-rect?
      (draw-checkbox 520 376 "DrawRect" draw-rect?))

    ;; MODE 显示
    (define mode-text (if (>= segments 4.0) "MANUAL" "AUTO"))
    (define mode-color (if (>= segments 4.0) MAROON DARKGRAY))
    (draw-text (format "MODE: ~a" mode-text) 520 270 10 mode-color)

    (draw-text "Drag sliders to adjust values"
               520 415 8 (fade DARKGRAY 0.6))

    (draw-fps 10 10)
    (end-drawing)

    (loop)))

;; 清理
(close-window)
