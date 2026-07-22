#lang racket/base
;; raylib [shapes] example - rlgl triangle (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_rlgl_triangle.c
;; 使用 rlgl 底层 API 绘制三角形，可拖拽顶点

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window screen-width screen-height
  "raylib [shapes] example - rlgl triangle")

;; 顶点起始位置
(define starting-positions
  (vector (vector2 400.0 150.0)
          (vector2 300.0 300.0)
          (vector2 500.0 300.0)))

;; 三角形顶点位置 (可拖动修改)
(define tri-positions
  (vector (vector2 400.0 150.0)
          (vector2 300.0 300.0)
          (vector2 500.0 300.0)))

;; 是否选中顶点 (-1 = 未选中)
(define-var triangle-index -1)

;; 线条模式?
(define-var lines-mode? #f)

(define handle-radius 8.0)

;; 提取 Vector2 的 x / y 辅助
(define (vx v) (ptr-ref v _float 0))
(define (vy v) (ptr-ref v _float 1))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()
  (unless (window-should-close?)
    ;; --- 更新 ---

    ;; 空格切换线条模式
    (when (is-key-pressed KEY-SPACE)
      (set-box! lines-mode? (not (unbox lines-mode?))))

    ;; 检查选中顶点 (仅在未选中时检查)
    (when (< (unbox triangle-index) 0)
      (for ([i (in-range 3)]
            #:break (>= (unbox triangle-index) 0))
        (let ([pos (vector-ref tri-positions i)])
          (when (and (check-collision-point-circle (get-mouse-position) pos handle-radius)
                     (is-mouse-button-down MOUSE-BUTTON-LEFT))
            (set-box! triangle-index i)))))

    ;; 拖动选中顶点
    (when (>= (unbox triangle-index) 0)
      (let ([pos (vector-ref tri-positions (unbox triangle-index))]
            [delta (get-mouse-delta)])
        (ptr-set! pos _float 0 (+ (vx pos) (vx delta)))
        (ptr-set! pos _float 1 (+ (vy pos) (vy delta)))))

    ;; 松开鼠标复位选中
    (when (is-mouse-button-released MOUSE-BUTTON-LEFT)
      (set-box! triangle-index -1))

    ;; 背面剔除
    (when (is-key-pressed KEY-LEFT)  (rl-enable-backface-culling))
    (when (is-key-pressed KEY-RIGHT) (rl-disable-backface-culling))

    ;; R 键复位
    (when (is-key-pressed KEY-R)
      (for ([i (in-range 3)])
        (let ([src (vector-ref starting-positions i)]
              [dst (vector-ref tri-positions i)])
          (ptr-set! dst _float 0 (vx src))
          (ptr-set! dst _float 1 (vy src))))
      (rl-enable-backface-culling))

    ;; --- 绘制 ---
    (begin-drawing)
    (clear-background RAYWHITE)

    (if (unbox lines-mode?)
        ;; 线条模式: 用 RL-LINES 画三条边
        (begin
          (rl-begin RL-LINES)
          ;; 红色 → 绿色
          (rl-color-4ub 255 0 0 255)
          (rl-vertex-2f (vx (vector-ref tri-positions 0)) (vy (vector-ref tri-positions 0)))
          (rl-color-4ub 0 255 0 255)
          (rl-vertex-2f (vx (vector-ref tri-positions 1)) (vy (vector-ref tri-positions 1)))
          ;; 绿色 → 蓝色
          (rl-color-4ub 0 255 0 255)
          (rl-vertex-2f (vx (vector-ref tri-positions 1)) (vy (vector-ref tri-positions 1)))
          (rl-color-4ub 0 0 255 255)
          (rl-vertex-2f (vx (vector-ref tri-positions 2)) (vy (vector-ref tri-positions 2)))
          ;; 蓝色 → 红色
          (rl-color-4ub 0 0 255 255)
          (rl-vertex-2f (vx (vector-ref tri-positions 2)) (vy (vector-ref tri-positions 2)))
          (rl-color-4ub 255 0 0 255)
          (rl-vertex-2f (vx (vector-ref tri-positions 0)) (vy (vector-ref tri-positions 0)))
          (rl-end))
        ;; 填充模式: 用 RL-TRIANGLES 画单个三角形
        (begin
          (rl-begin RL-TRIANGLES)
          (rl-color-4ub 255 0 0 255)
          (rl-vertex-2f (vx (vector-ref tri-positions 0)) (vy (vector-ref tri-positions 0)))
          (rl-color-4ub 0 255 0 255)
          (rl-vertex-2f (vx (vector-ref tri-positions 1)) (vy (vector-ref tri-positions 1)))
          (rl-color-4ub 0 0 255 255)
          (rl-vertex-2f (vx (vector-ref tri-positions 2)) (vy (vector-ref tri-positions 2)))
          (rl-end)))

    ;; 绘制顶点手柄
    (for ([i (in-range 3)])
      (let ([pos (vector-ref tri-positions i)])
        ;; 鼠标悬停高亮
        (when (check-collision-point-circle (get-mouse-position) pos handle-radius)
          (draw-circle-v pos handle-radius (color-alpha DARKGRAY 0.5)))
        ;; 选中填充
        (when (= i (unbox triangle-index))
          (draw-circle-v pos handle-radius DARKGRAY))
        ;; 手柄外框
        (draw-circle-lines-v pos handle-radius BLACK)))

    ;; 操作提示
    (draw-text "SPACE: Toggle lines mode" 10 10 20 DARKGRAY)
    (draw-text "LEFT-RIGHT: Toggle backface culling" 10 40 20 DARKGRAY)
    (draw-text "MOUSE: Click and drag vertex points" 10 70 20 DARKGRAY)
    (draw-text "R: Reset triangle to start positions" 10 100 20 DARKGRAY)

    (end-drawing)

    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
