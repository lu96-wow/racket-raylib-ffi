#lang racket/base
;; raylib [shapes] example - rlgl color wheel (Racket FFI 翻译)
;; 滑块控制替代 raygui (参照 ring_drawing.rkt)
;; 注意: 颜色轮使用 rlgl 底层的 rlBegin/rlEnd 绘制
(require "../../raylib/raylib.rkt"
         racket/match
         racket/math
         (only-in ffi/unsafe malloc))

(define screen-w 800) (define screen-h 450)
(define RL-TRIANGLES 4) (define RL-LINES 1)

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window screen-w screen-h "raylib [shapes] example - rlgl color wheel")

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
               [v (+ vmin (* t (- vmax vmin)))]) v) cur))
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
  (draw-text (real->decimal-string cur (if (< (- vmax vmin) 2) 2 0))
              (+ x w 8) (- (+ y (quotient h 2)) 5) 10 DARKGRAY))

(define (slider-val sl-box) (cadddr (cdddr (unbox sl-box))))

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
;; 辅助函数
;; ============================================================
(define (vec2-dist a b)
  (let ([dx (- (ptr-ref a _float 0) (ptr-ref b _float 0))]
        [dy (- (ptr-ref a _float 1) (ptr-ref b _float 1))])
    (sqrt (+ (* dx dx) (* dy dy)))))

(define (color-lerp a b t)
  (define c (malloc _Color 'atomic))
  (ptr-set! c _ubyte 0 (exact-round (+ (ptr-ref a _ubyte 0) (* t (- (ptr-ref b _ubyte 0) (ptr-ref a _ubyte 0))))))
  (ptr-set! c _ubyte 1 (exact-round (+ (ptr-ref a _ubyte 1) (* t (- (ptr-ref b _ubyte 1) (ptr-ref a _ubyte 1))))))
  (ptr-set! c _ubyte 2 (exact-round (+ (ptr-ref a _ubyte 2) (* t (- (ptr-ref b _ubyte 2) (ptr-ref a _ubyte 2))))))
  (ptr-set! c _ubyte 3 255)
  c)

;; ============================================================
;; 状态
;; ============================================================
(define center (vector2 (/ screen-w 2) (/ screen-h 2)))
(define circle-pos center)
(define triangle-count 64)
(define point-scale 150.0)
(define value 1.0)
(define render-type RL-TRIANGLES)
(define setting-color #f)

;; 当前颜色
(define current-color
  (let ([c (malloc _Color 'atomic)])
    (ptr-set! c _ubyte 0 255) (ptr-set! c _ubyte 1 255)
    (ptr-set! c _ubyte 2 255) (ptr-set! c _ubyte 3 255) c))

;; 滑块
(define sl-triangles (make-slider 8 395 120 16 3.0 256.0 64.0 ""))
(define sl-value     (make-slider 42 141 64 16 0.0 1.0 1.0 ""))

;; ============================================================
;; 主循环
;; ============================================================
(let loop ()
  (unless (window-should-close?)
    ;; ---- 更新 ----
    ;; 滚轮调整三角形数量
    (define wheel (get-mouse-wheel-move))
    (set! triangle-count (+ triangle-count (exact-round wheel)))
    (set! triangle-count (exact-round (max 3.0 (min 256.0 triangle-count))))

    ;; 颜色轮点击检测
    (when (and (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
               (<= (vec2-dist (get-mouse-position) center) (+ point-scale 10.0)))
      (set! setting-color #t))
    (when (is-mouse-button-released MOUSE-BUTTON-LEFT)
      (set! setting-color #f))

    ;; 更新颜色
    (when setting-color
      (set! circle-pos (get-mouse-position))
      (define dist (/ (vec2-dist center circle-pos) point-scale))
      (define angle
        (let* ([px (- (ptr-ref circle-pos _float 0) (ptr-ref center _float 0))]
               [npy (- (ptr-ref center _float 1) (ptr-ref circle-pos _float 1))]
               [a (atan px npy)])
          (if (< a 0) (+ a (* 2.0 pi)) a)))
      (when (> dist 1.0)
        (set! circle-pos
          (vec2-add (vector2 (* (sin angle) point-scale)
                             (* (- (cos angle)) point-scale))
                    center)))
      (define dist-clamped (max 0.0 (min 1.0 dist)))
      (define angle360 (* (/ angle (* 2.0 pi)) 360.0))
      (define hsv-col (color-from-hsv angle360 dist-clamped 1.0))
      (define gray-col
        (let ([c (malloc _Color 'atomic)])
          (ptr-set! c _ubyte 0 (exact-round (* value 255.0)))
          (ptr-set! c _ubyte 1 (exact-round (* value 255.0)))
          (ptr-set! c _ubyte 2 (exact-round (* value 255.0)))
          (ptr-set! c _ubyte 3 255) c))
      (set! current-color (color-lerp gray-col hsv-col dist-clamped)))

    ;; 滑块更新
    (update-slider sl-triangles)
    (set! triangle-count (exact-round (slider-val sl-triangles)))
    (set! triangle-count (exact-round (max 3.0 (min 256.0 triangle-count))))
    (update-slider sl-value)
    (set! value (slider-val sl-value))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 颜色轮 (rlgl)
    (rl-begin render-type)
    (for ([i (in-range triangle-count)])
      (define angle-offset (/ (* 2.0 pi) triangle-count))
      (define angle (exact->inexact (* angle-offset i)))
      (define angle-next (* angle-offset (+ i 1)))
      (define scale-v (vector2 point-scale point-scale))
      (define offset  (vec2-multiply (vector2 (sin angle) (- (cos angle))) scale-v))
      (define offset2 (vec2-multiply (vector2 (sin angle-next) (- (cos angle-next))) scale-v))
      (define pos  (vec2-add center offset))
      (define pos2 (vec2-add center offset2))
      (define ang-deg (* (/ angle (* 2.0 pi)) 360.0))
      (define ang-deg2 (+ ang-deg (* (/ angle-offset (* 2.0 pi)) 360.0)))
      (define col1 (color-from-hsv ang-deg 1.0 1.0))
      (define col2 (color-from-hsv ang-deg2 1.0 1.0))
      (cond
        [(= render-type RL-TRIANGLES)
         (rl-color-4ub (ptr-ref col1 _ubyte 0) (ptr-ref col1 _ubyte 1)
                       (ptr-ref col1 _ubyte 2) (ptr-ref col1 _ubyte 3))
         (rl-vertex-2f (ptr-ref pos _float 0) (ptr-ref pos _float 1))
         (rl-color-4ub (exact-round (* value 255)) (exact-round (* value 255))
                        (exact-round (* value 255)) 255)
         (rl-vertex-2f (ptr-ref center _float 0) (ptr-ref center _float 1))
         (rl-color-4ub (ptr-ref col2 _ubyte 0) (ptr-ref col2 _ubyte 1)
                       (ptr-ref col2 _ubyte 2) (ptr-ref col2 _ubyte 3))
         (rl-vertex-2f (ptr-ref pos2 _float 0) (ptr-ref pos2 _float 1))]
        [else ;; RL_LINES
         (rl-color-4ub (ptr-ref col1 _ubyte 0) (ptr-ref col1 _ubyte 1)
                       (ptr-ref col1 _ubyte 2) (ptr-ref col1 _ubyte 3))
         (rl-vertex-2f (ptr-ref pos _float 0) (ptr-ref pos _float 1))
         (rl-color-4ub 255 255 255 255)
         (rl-vertex-2f (ptr-ref center _float 0) (ptr-ref center _float 1))
         (rl-vertex-2f (ptr-ref center _float 0) (ptr-ref center _float 1))
         (rl-color-4ub (ptr-ref col2 _ubyte 0) (ptr-ref col2 _ubyte 1)
                       (ptr-ref col2 _ubyte 2) (ptr-ref col2 _ubyte 3))
         (rl-vertex-2f (ptr-ref pos2 _float 0) (ptr-ref pos2 _float 1))
         (rl-vertex-2f (ptr-ref pos2 _float 0) (ptr-ref pos2 _float 1))
         (rl-color-4ub (ptr-ref col1 _ubyte 0) (ptr-ref col1 _ubyte 1)
                       (ptr-ref col1 _ubyte 2) (ptr-ref col1 _ubyte 3))
         (rl-vertex-2f (ptr-ref pos _float 0) (ptr-ref pos _float 1))]))
    (rl-end)

    ;; 颜色手柄
    (define handle-color
      (if (and (<= (/ (vec2-dist center circle-pos) point-scale) 0.5) (<= value 0.5))
          DARKGRAY BLACK))
    (draw-circle-lines-v circle-pos 4.0 handle-color)

    ;; 颜色预览
    (draw-rectangle-v (vector2 8.0 8.0) (vector2 64.0 64.0) current-color)
    (draw-rectangle-lines-ex (rectangle 8.0 8.0 64.0 64.0) 2.0
                             (color-lerp current-color BLACK 0.5))

    ;; Hex / RGB 文本
    (draw-text (format "#~a~a~a"
                  (string-upcase (number->string (ptr-ref current-color _ubyte 0) 16))
                  (string-upcase (number->string (ptr-ref current-color _ubyte 1) 16))
                  (string-upcase (number->string (ptr-ref current-color _ubyte 2) 16)))
               8 (+ 8 64 8) 20 DARKGRAY)
    (draw-text (format "(~a, ~a, ~a)"
                  (ptr-ref current-color _ubyte 0)
                  (ptr-ref current-color _ubyte 1)
                  (ptr-ref current-color _ubyte 2))
               8 (+ 8 64 8 24) 20 DARKGRAY)


    ;; ---- UI 控件 ----
    ;; Triangle count 滑块
    (draw-text (format "triangles: ~a" triangle-count) 8 380 20 DARKGRAY)
    (draw-slider sl-triangles)

    ;; Value 滑块
    (draw-text "value:" 42 125 10 DARKGRAY)
    (draw-slider sl-value)

    ;; Wireframe 复选框
    (set! render-type
      (if (draw-checkbox 8 165 "Wireframe" (= render-type RL-LINES))
          RL-LINES RL-TRIANGLES))

    ;; Ctrl+C 复制
    (define copying? (and (is-key-down KEY-LEFT-CONTROL) (is-key-down KEY-C)))
    (draw-text "press ctrl+c to copy!"
               8 (- screen-h 25 (if copying? 4 0)) 20
               (if copying? DARKGREEN DARKGRAY))

    (draw-fps (+ 64 16) 8)
    (end-drawing)
    (loop)))

(close-window)