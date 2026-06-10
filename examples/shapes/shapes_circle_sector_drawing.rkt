#lang racket/base

;; raylib [shapes] example - circle sector drawing (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_circle_sector_drawing.c
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

  ;; 拖拽中更新值 (保留浮点精度)
  (define new-val
    (if new-drag?
        (let* ([t (max 0.0 (min 1.0 (/ (- mx x) w)))]
               [v (+ vmin (* t (- vmax vmin)))])
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
  ;; 值 — 两位小数显示
  (draw-text (real->decimal-string cur 2) (+ x w 8) (- (+ y (quotient h 2)) 5) 10 DARKGRAY))

;; 滑块当前值
(define (slider-val sl-box)
  (cadddr (cdddr (unbox sl-box))))  ;; list-ref at index 6

;; ============================================================
;; 初始化
;; ============================================================

(define screen-w 800)
(define screen-h 450)

(init-window screen-w screen-h
             "raylib [shapes] example - circle sector drawing")

(define center (vector2 (/ (- (get-screen-width) 300) 2.0)
                        (/ (get-screen-height) 2.0)))

;; 滑块: x=520, w=150, h=16, 范围对应 C 版 raygui GuiSliderBar
(define sl-start-angle  (make-slider 520  42 150 16    0.0 720.0   0.0 "StartAngle"))
(define sl-end-angle    (make-slider 520  74 150 16    0.0 720.0 180.0 "EndAngle"))
(define sl-outer-radius (make-slider 520 140 150 16    0.0 200.0 180.0 "Radius"))
(define sl-segments     (make-slider 520 172 150 16    0.0 100.0  10.0 "Segments"))

;; 当前值（每帧由滑块更新）
(define start-angle    0.0)
(define end-angle      180.0)
(define outer-radius   180.0)
(define segments       10.0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- 更新（鼠标交互）----
    (update-slider sl-start-angle)
    (update-slider sl-end-angle)
    (update-slider sl-outer-radius)
    (update-slider sl-segments)

    ;; 读取滑块值
    (set! start-angle   (slider-val sl-start-angle))
    (set! end-angle     (slider-val sl-end-angle))
    (set! outer-radius  (slider-val sl-outer-radius))
    (set! segments      (slider-val sl-segments))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 分隔线 + 控制面板背景
    (draw-line 500 0 500 (get-screen-height) (fade LIGHTGRAY 0.6))
    (draw-rectangle 500 0 (- (get-screen-width) 500) (get-screen-height)
                    (fade LIGHTGRAY 0.3))

    ;; 扇形
    (draw-circle-sector center outer-radius start-angle end-angle
                        (exact-round segments) (fade MAROON 0.3))
    (draw-circle-sector-lines center outer-radius start-angle end-angle
                              (exact-round segments) (fade MAROON 0.6))

    ;; 绘制滑块
    (draw-slider sl-start-angle)
    (draw-slider sl-end-angle)
    (draw-slider sl-outer-radius)
    (draw-slider sl-segments)

    ;; 标签
    (draw-text "StartAngle" 520 30 10 DARKGRAY)
    (draw-text "EndAngle"   520 62 10 DARKGRAY)
    (draw-text "Radius"     520 128 10 DARKGRAY)
    (draw-text "Segments"   520 160 10 DARKGRAY)

    ;; MODE 显示
    (define min-seg (exact-ceiling (/ (- end-angle start-angle) 90.0)))
    (define mode-text (if (>= segments min-seg) "MANUAL" "AUTO"))
    (define mode-color (if (>= segments min-seg) MAROON DARKGRAY))
    (draw-text (format "MODE: ~a" mode-text) 520 200 10 mode-color)

    (draw-text "Drag sliders to adjust values"
               520 415 8 (fade DARKGRAY 0.6))

    (draw-fps 10 10)
    (end-drawing)

    (loop)))

;; 清理
(close-window)
