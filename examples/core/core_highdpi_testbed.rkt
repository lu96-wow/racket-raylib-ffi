#lang racket/base

;; raylib [core] example - highdpi testbed (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_highdpi_testbed.c
;;
;; 演示: HighDPI 显示器信息展示
;;   网格 + 坐标标注
;;   鼠标十字准星 + 位置
;;   Space - 切换 Borderless Windowed
;;   F     - 切换全屏

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)
(define GRID-SPACING 40)

;; ============================================================
;; 初始化
;; ============================================================

(set-config-flags (bitwise-ior FLAG-WINDOW-RESIZABLE FLAG-WINDOW-HIGHDPI))
(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - highdpi testbed")

(set-target-fps 60)

;; ============================================================
;; 辅助: 绘制网格
;; ============================================================

(define (draw-grid)
  (define screen-w (get-screen-width))
  (define screen-h (get-screen-height))
  ;; 水平线
  (for ([h (in-range 0 (+ (quotient screen-h GRID-SPACING) 1))])
    (define y (* h GRID-SPACING))
    (draw-text (format "~a" (* h GRID-SPACING)) 4 (- y 4) 10 GRAY)
    (draw-line 24 y screen-w y LIGHTGRAY))
  ;; 垂直线
  (for ([v (in-range 0 (+ (quotient screen-w GRID-SPACING) 1))])
    (define x (* v GRID-SPACING))
    (draw-text (format "~a" (* v GRID-SPACING)) (- x 10) 4 10 GRAY)
    (draw-line x 20 x screen-h LIGHTGRAY)))

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (define screen-w (get-screen-width))
    (define screen-h (get-screen-height))
    (define mouse-pos (get-mouse-position))
    (define current-monitor (get-current-monitor))
    (define scale-dpi (get-window-scale-dpi))
    (define window-pos (get-window-position))

    ;; === 更新 ===
    (when (is-key-pressed KEY-SPACE) (toggle-borderless-windowed))
    (when (is-key-pressed KEY-F)     (toggle-fullscreen))

    ;; === 绘制 ===
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 网格
    (draw-grid)

    ;; UI 信息
    (draw-text (format "CURRENT MONITOR: ~a/~a (~ax~a)"
                       (+ current-monitor 1) (get-monitor-count)
                       (get-monitor-width current-monitor)
                       (get-monitor-height current-monitor))
               50 50 20 DARKGRAY)
    (draw-text (format "WINDOW POSITION: ~ax~a"
                       (inexact->exact (floor (vector2-x window-pos)))
                       (inexact->exact (floor (vector2-y window-pos))))
               50 90 20 DARKGRAY)
    (draw-text (format "SCREEN SIZE: ~ax~a" screen-w screen-h)
               50 130 20 DARKGRAY)
    (draw-text (format "RENDER SIZE: ~ax~a"
                       (get-render-width) (get-render-height))
               50 170 20 DARKGRAY)
    (draw-text (format "SCALE FACTOR: ~a x ~a"
                       (real->decimal-string (vector2-x scale-dpi) 2)
                       (real->decimal-string (vector2-y scale-dpi) 2))
               50 210 20 GRAY)

    ;; 参考矩形 (左上 + 右下)
    (draw-rectangle 0 0 30 60 RED)
    (draw-rectangle (- screen-w 30) (- screen-h 60) 30 60 BLUE)

    ;; 鼠标十字准星
    (draw-circle-v mouse-pos 20.0 MAROON)
    (draw-rectangle-rec (rectangle (- (vector2-x mouse-pos) 25) (vector2-y mouse-pos) 50 2) BLACK)
    (draw-rectangle-rec (rectangle (vector2-x mouse-pos) (- (vector2-y mouse-pos) 25) 2 50) BLACK)

    ;; 鼠标坐标文字
    (define mouse-x (get-mouse-x))
    (define mouse-y (get-mouse-y))
    (define text-pos-y
      (if (> mouse-y (- screen-h 60))
        (- mouse-y 46)
        (+ mouse-y 30)))
    (draw-text (format "[~a,~a]" mouse-x mouse-y)
               (- mouse-x 44) text-pos-y 20 BLACK)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
