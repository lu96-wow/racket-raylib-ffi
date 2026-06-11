#lang racket/base

;; raylib [textures] example - sprite stacking (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_sprite_stacking.c
;;
;; 演示: 利用精灵表的堆叠效果模拟 3D 体素模型
;;   加载 booth.png（竖排 122 帧精灵表）
;;   每帧偏移一定间距绘制，产生 3D 立体感
;;
;; 控制:
;;   A/D 或 ←/→ — 改变旋转速度
;;   鼠标滚轮 — 改变层间距

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 资源路径
;; ============================================================

(define resource-dir
  (path->string (build-path (current-directory) "../../../examples/textures/resources/")))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [textures] example - sprite stacking")

(define booth
  (load-texture (string-append resource-dir "booth.png")))

(define stack-scale 3.0)        ;; 整体缩放
(define stack-count 122)        ;; 层数
(define speed-change 0.25)      ;; 速度变化步长

;; 可变状态
(define current-spacing 2.0)    ;; 层间距
(define rotation-speed 30.0)    ;; 旋转速度
(define current-rotation 0.0)   ;; 当前旋转角度

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- 更新 ----
    ;; 鼠标滚轮调节层间距
    (set! current-spacing
      (clamp (+ current-spacing (* (get-mouse-wheel-move) 0.1))
             0.0 5.0))

    ;; A/D 或 ←/→ 调节旋转速度
    (when (is-key-down KEY-LEFT)  (set! rotation-speed (- rotation-speed speed-change)))
    (when (is-key-down KEY-RIGHT) (set! rotation-speed (+ rotation-speed speed-change)))
    (when (is-key-down KEY-A)     (set! rotation-speed (- rotation-speed speed-change)))
    (when (is-key-down KEY-D)     (set! rotation-speed (+ rotation-speed speed-change)))

    (set! current-rotation
      (+ current-rotation (* rotation-speed (get-frame-time))))

    ;; 计算单帧尺寸
    (let ([frame-w (exact->inexact (list-ref booth 1))]          ;; texture.width
          [frame-h (exact->inexact (/ (list-ref booth 2) stack-count))]  ;; texture.height / stackCount
          [scaled-w (* (exact->inexact (list-ref booth 1)) stack-scale)]
          [scaled-h (* (exact->inexact (/ (list-ref booth 2) stack-count)) stack-scale)])

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 从底部到顶部绘制每一层（从下到上确保正确的遮挡顺序）
    (do ([i (sub1 stack-count) (sub1 i)]) [(< i 0)]
      (let* ([src-y (exact->inexact (* i frame-h))]
             [dest-y (+ (/ screen-height 2.0)
                        (- (* i current-spacing)
                           (* (/ current-spacing stack-count) stack-count 0.5)))]
             [origin-x (/ scaled-w 2.0)]
             [origin-y (/ scaled-h 2.0)])
        ;; source rect: (0, src-y, frame-w, frame-h) 截取当前帧
        ;; dest rect: 居中, (scaled-w, scaled-h) 缩放
        (draw-texture-pro booth
          (rectangle 0.0 src-y frame-w frame-h)          ;; source
          (rectangle (/ screen-width 2.0) dest-y          ;; dest
                          scaled-w scaled-h)
          (vector2 origin-x origin-y)                           ;; origin (中心)
          current-rotation                                      ;; rotation
          WHITE)))                                              ;; tint, let*, do

    ;; 显示控制信息
    (draw-text "A/D to spin" 10 10 20 DARKGRAY)
    (draw-text "mouse wheel to change separation (aka 'angle')" 10 30 20 DARKGRAY)
    (draw-text (format "current spacing: ~a" (real->decimal-string current-spacing 1)) 10 50 20 DARKGRAY)
    (draw-text (format "current speed: ~a" (real->decimal-string rotation-speed 2)) 10 70 20 DARKGRAY)
    (draw-text "redbooth model (c) kluchek under cc 4.0" 10 420 20 DARKGRAY))

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture booth)
(close-window)
