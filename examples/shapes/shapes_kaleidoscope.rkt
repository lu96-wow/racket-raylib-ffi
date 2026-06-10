#lang racket/base

;; raylib [shapes] example - kaleidoscope (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_kaleidoscope.c
;; 万花筒绘图: 鼠标拖动画线, 自动旋转对称 + 镜像反射
;; 键盘: [Q/W] 增减对称数  [C] 清除  [←→] 撤销/重做
;; 鼠标: 点击 Reset 按钮或拖动画线


(require "../../raylib/raylib.rkt" racket/math)


;; ============================================================
;; 初始化
;; ============================================================

(define SCREEN-W 800)
(define SCREEN-H 450)
(define MAX-LINES 8192)
(define DEG2RAD (/ pi 180.0))

(init-window SCREEN-W SCREEN-H
  "raylib [shapes] example - kaleidoscope")
(set-target-fps 60)


;; ------------------------------------------------------------
;; 参数
;; ------------------------------------------------------------

(define symmetry  (box 6))
(define thickness 3.0)

;; Camera2D: 原点居中
(define camera
  (camera2d 0.0 0.0                        ; target
            (/ SCREEN-W 2.0) (/ SCREEN-H 2.0)  ; offset
            0.0 1.0))                      ; rotation, zoom

(define offset   (vector2 (/ SCREEN-W 2.0) (/ SCREEN-H 2.0)))
(define scale-v  (vector2 1.0 -1.0))       ; x 翻转做镜像


;; ------------------------------------------------------------
;; 线段存储: 4 个扁平向量, 完全避免 null-pointer
;; ------------------------------------------------------------

(define start-x (make-vector MAX-LINES 0.0))
(define start-y (make-vector MAX-LINES 0.0))
(define end-x   (make-vector MAX-LINES 0.0))
(define end-y   (make-vector MAX-LINES 0.0))

(define total-counter   (box 0))
(define current-counter (box 0))


;; ------------------------------------------------------------
;; 复用的临时 Vector2 指针 (绘图时更新字段, 不重新 malloc)
;; ------------------------------------------------------------

(define tmp-start (vector2 0.0 0.0))
(define tmp-end   (vector2 0.0 0.0))

;; 鼠标上一帧位置 (用可复用的指针)
(define prev-mouse (vector2 0.0 0.0))


;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()

  (unless (window-should-close?)

    ;; ---- 更新 ----

    (define sym   (unbox symmetry))
    (define angle (/ 360.0 sym))
    (define total (unbox total-counter))
    (define cur   (unbox current-counter))

    ;; 当前鼠标位置
    (define mx (exact->inexact (get-mouse-x)))
    (define my (exact->inexact (get-mouse-y)))
    (define pmx (vector2-x prev-mouse))
    (define pmy (vector2-y prev-mouse))

    ;; 鼠标世界坐标 (相对画面中心)
    (define line-start (vec2-subtract (vector2 mx my) offset))
    (define line-end   (vec2-subtract prev-mouse offset))

    ;; ---- 键盘控制 ----
    (when (is-key-pressed KEY-C)
      (set-box! current-counter 0)
      (set-box! total-counter 0))

    (when (is-key-pressed KEY-LEFT)
      (set-box! current-counter (max 0 (sub1 cur))))

    (when (is-key-pressed KEY-RIGHT)
      (define next (min MAX-LINES (add1 cur)))
      (set-box! current-counter next)
      (when (> next total)
        (set-box! total-counter next)))

    (when (is-key-pressed KEY-Q)
      (set-box! symmetry (max 2 (sub1 sym))))

    (when (is-key-pressed KEY-W)
      (set-box! symmetry (min 12 (add1 sym))))

    ;; ---- Reset 按钮 ----
    (define reset-rec (rectangle (- SCREEN-W 55.0) 5.0 50 25))
    (when (and (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
               (check-collision-point-rec (vector2 mx my) reset-rec))
      (set-box! current-counter 0)
      (set-box! total-counter 0))

    ;; ---- 鼠标绘制 (排除 Reset 按钮区域) ----
    (when (and (is-mouse-button-down MOUSE-BUTTON-LEFT)
               (not (check-collision-point-rec (vector2 mx my) reset-rec))
               (< (unbox total-counter) (sub1 MAX-LINES)))
      (let draw-loop ([s 0] [ls line-start] [le line-end])
        (when (< s sym)
          ;; 旋转当前线段
          (define nls (vec2-rotate ls (* angle DEG2RAD)))
          (define nle (vec2-rotate le (* angle DEG2RAD)))

          ;; 存储原始段 (每次迭代读取最新的 total-counter)
          (define idx (unbox total-counter))
          (vector-set! start-x idx (vector2-x nls))
          (vector-set! start-y idx (vector2-y nls))
          (vector-set! end-x   idx (vector2-x nle))
          (vector-set! end-y   idx (vector2-y nle))

          ;; 存储镜像反射段
          (define rls (vec2-multiply nls scale-v))
          (define rle (vec2-multiply nle scale-v))
          (vector-set! start-x (add1 idx) (vector2-x rls))
          (vector-set! start-y (add1 idx) (vector2-y rls))
          (vector-set! end-x   (add1 idx) (vector2-x rle))
          (vector-set! end-y   (add1 idx) (vector2-y rle))

          (set-box! total-counter (+ idx 2))
          (set-box! current-counter (unbox total-counter))
          (draw-loop (add1 s) nls nle))))

    ;; 更新 prev-mouse
    (set-vector2-x! prev-mouse mx)
    (set-vector2-y! prev-mouse my)

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-2d camera)

    ;; 绘制已有线段 (每帧画 sym 遍以形成万花筒效果)
    (for ([s (in-range sym)])
      (for ([i (in-range cur)])
        (ptr-set! tmp-start _float 0 (vector-ref start-x i))
        (ptr-set! tmp-start _float 1 (vector-ref start-y i))
        (ptr-set! tmp-end   _float 0 (vector-ref end-x i))
        (ptr-set! tmp-end   _float 1 (vector-ref end-y i))
        (draw-line-ex tmp-start tmp-end thickness BLACK)))

    (end-mode-2d)

    ;; ---- UI ----
    (draw-text (format "LINES: ~a/~a" cur MAX-LINES)
               10 (- SCREEN-H 30) 20 MAROON)
    (draw-text (format "Symmetry [Q/W]: ~a" sym)
               10 (- SCREEN-H 55) 15 DARKGRAY)
    (draw-text "[C] Clear  [<- ->] Undo/Redo"
               10 (- SCREEN-H 75) 15 DARKGRAY)
    (draw-text "Reset"
               (- SCREEN-W 55) 10 15 DARKGRAY)
    (draw-rectangle-lines-ex reset-rec 1.0 GRAY)

    (draw-fps 10 10)
    (end-drawing)

    (main-loop)))


;; ============================================================
;; 清理
;; ============================================================

(close-window)
