#lang racket/base

;; raylib [textures] example - textured curve (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_textured_curve.c
;;
;; 演示: 用 rlgl 底层绘制 API 绘制纹理贝塞尔曲线
;;   贝塞尔控制点可拖拽
;;
;; 控制:
;;   SPACE    — 显示/隐藏参考曲线
;;   +/-      — 调整曲线宽度
;;   ←/→      — 调整分段数
;;   拖拽控制点 — 编辑曲线形状

(require "../../raylib/raylib.rkt")

(define resource-dir
  (path->string (build-path (current-directory) "../../../examples/textures/resources/")))

;; ============================================================
;; 全局状态
;; ============================================================

(define tex-road #f)
(define show-curve #f)
(define curve-width 50.0)
(define curve-segments 24)

(define curve-start-pos     (vector2 80 100))
(define curve-start-tangent (vector2 100 300))
;; ============================================================
;; 纹理贝塞尔曲线绘制（对应 C 的 DrawTexturedCurve）
;; ============================================================

(define (draw-textured-curve!)
  (let ([step (/ 1.0 curve-segments)]
        [tex-h (list-ref tex-road 2)]
        [tex-id (list-ref tex-road 0)])

    (define sx (vector2-x curve-start-pos))
    (define sy (vector2-y curve-start-pos))
    (define stx (vector2-x curve-start-tangent))
    (define sty (vector2-y curve-start-tangent))
    (define ex (vector2-x curve-end-pos))
    (define ey (vector2-y curve-end-pos))
    (define etx (vector2-x curve-end-tangent))
    (define ety (vector2-y curve-end-tangent))

    (define prev (vector2 sx sy))
    (define prev-tangent (vector2 0 0))
    (define prev-v 0.0)
    (define tangent-set #f)

    (for ([i (in-range 1 (add1 curve-segments))])
      (define t (* step i))
      (define a (expt (- 1.0 t) 3))
      (define b (* 3.0 (expt (- 1.0 t) 2) t))
      (define c (* 3.0 (- 1.0 t) (expt t 2)))
      (define d (expt t 3))

      (define cur-x (+ (* a sx) (* b stx) (* c etx) (* d ex)))
      (define cur-y (+ (* a sy) (* b sty) (* c ety) (* d ey)))
      (define current (vector2 cur-x cur-y))

      (define delta-x (- cur-x (vector2-x prev)))
      (define delta-y (- cur-y (vector2-y prev)))
      (define normal (vec2-normalize (vector2 (- delta-y) delta-x)))

      (define seg-len (sqrt (+ (* delta-x delta-x) (* delta-y delta-y))))
      (define v (+ prev-v (/ seg-len (* tex-h 2.0))))

      (unless tangent-set
        (set-vector2-x! prev-tangent (vector2-x normal))
        (set-vector2-y! prev-tangent (vector2-y normal))
        (set! tangent-set #t))

      (define prev-pos (vec2-add prev (vec2-scale prev-tangent curve-width)))
      (define prev-neg (vec2-add prev (vec2-scale prev-tangent (- curve-width))))
      (define cur-pos  (vec2-add current (vec2-scale normal curve-width)))
      (define cur-neg  (vec2-add current (vec2-scale normal (- curve-width))))

      (rl-set-texture tex-id)
      (rl-begin RL-QUADS)
      (rl-color-4ub 255 255 255 255)
      (rl-normal-3f 0.0 0.0 1.0)

      (rl-tex-coord-2f 0.0 prev-v)
      (rl-vertex-2f (vector2-x prev-neg) (vector2-y prev-neg))
      (rl-tex-coord-2f 1.0 prev-v)
      (rl-vertex-2f (vector2-x prev-pos) (vector2-y prev-pos))
      (rl-tex-coord-2f 1.0 v)
      (rl-vertex-2f (vector2-x cur-pos) (vector2-y cur-pos))
      (rl-tex-coord-2f 0.0 v)
      (rl-vertex-2f (vector2-x cur-neg) (vector2-y cur-neg))

      (rl-end)
      (rl-set-texture 0)

      (set-vector2-x! prev (vector2-x current))
      (set-vector2-y! prev (vector2-y current))
      (set-vector2-x! prev-tangent (vector2-x normal))
      (set-vector2-y! prev-tangent (vector2-y normal))
      (set! prev-v v))))

;; ============================================================
;; 辅助: 更新控制点（拖拽）
;; ============================================================

(define (update-selected-point!)
  (let ([sel (unbox selected-point)])
    (when sel
      (let ([delta (get-mouse-delta)])
        (set-vector2-x! sel
          (+ (vector2-x sel) (vector2-x delta)))
        (set-vector2-y! sel
          (+ (vector2-y sel) (vector2-y delta)))))))

(define curve-end-pos       (vector2 700 350))
(define curve-end-tangent   (vector2 600 100))
(define-var selected-point #f)
(set-config-flags (bitwise-ior FLAG-VSYNC-HINT FLAG-MSAA-4X-HINT))

(init-window 800 450
  "raylib [textures] example - textured curve")

(set! tex-road (load-texture (string-append resource-dir "road.png")))
(set-texture-filter tex-road TEXTURE-FILTER-BILINEAR)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (when (is-key-pressed KEY-SPACE)
      (set! show-curve (not show-curve)))

    (when (is-key-pressed KEY-EQUAL) (set! curve-width (+ curve-width 2)))
    (when (is-key-pressed KEY-MINUS) (set! curve-width (- curve-width 2)))
    (when (< curve-width 2) (set! curve-width 2))

    (when (is-key-pressed KEY-LEFT)  (set! curve-segments (- curve-segments 2)))
    (when (is-key-pressed KEY-RIGHT) (set! curve-segments (+ curve-segments 2)))
    (when (< curve-segments 2) (set! curve-segments 2))

    (unless (is-mouse-button-down MOUSE-BUTTON-LEFT)
      (set-box! selected-point #f))
    (update-selected-point!)

    (let ([mouse (get-mouse-position)])
      (cond
        [(check-collision-point-circle mouse curve-start-pos 6.0)
         (set-box! selected-point curve-start-pos)]
        [(check-collision-point-circle mouse curve-start-tangent 6.0)
         (set-box! selected-point curve-start-tangent)]
        [(check-collision-point-circle mouse curve-end-pos 6.0)
         (set-box! selected-point curve-end-pos)]
        [(check-collision-point-circle mouse curve-end-tangent 6.0)
         (set-box! selected-point curve-end-tangent)]))

    (begin-drawing)
    (clear-background RAYWHITE)
    (draw-textured-curve!)

    (when show-curve
      (draw-spline-segment-bezier-cubic
        curve-start-pos curve-end-pos
        curve-start-tangent curve-end-tangent
        2.0 BLUE))

    (draw-line-v curve-start-pos curve-start-tangent SKYBLUE)
    (draw-line-v curve-start-tangent curve-end-tangent (fade LIGHTGRAY 0.4))
    (draw-line-v curve-end-pos curve-end-tangent PURPLE)

    (let ([mouse (get-mouse-position)])
      (when (check-collision-point-circle mouse curve-start-pos 6.0)
        (draw-circle-v curve-start-pos 7.0 YELLOW))
      (draw-circle-v curve-start-pos 5.0 RED)

      (when (check-collision-point-circle mouse curve-start-tangent 6.0)
        (draw-circle-v curve-start-tangent 7.0 YELLOW))
      (draw-circle-v curve-start-tangent 5.0 MAROON)

      (when (check-collision-point-circle mouse curve-end-pos 6.0)
        (draw-circle-v curve-end-pos 7.0 YELLOW))
      (draw-circle-v curve-end-pos 5.0 GREEN)

      (when (check-collision-point-circle mouse curve-end-tangent 6.0)
        (draw-circle-v curve-end-tangent 7.0 YELLOW))
      (draw-circle-v curve-end-tangent 5.0 DARKGREEN))

    (draw-text
      "Drag points to move curve, press SPACE to show/hide base curve"
      10 10 10 DARKGRAY)
    (draw-text
      (format "Curve width: ~a (Use + and - to adjust)"
              (real->decimal-string curve-width 0))
      10 30 10 DARKGRAY)
    (draw-text
      (format "Curve segments: ~a (Use LEFT and RIGHT to adjust)"
              curve-segments)
      10 50 10 DARKGRAY)

    (end-drawing)
    (loop)))

(unload-texture tex-road)
(close-window)

