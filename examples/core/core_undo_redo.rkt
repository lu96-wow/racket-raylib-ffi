#lang racket/base

;; raylib [core] example - undo redo (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_undo_redo.c
;;
;; 演示: 使用环状缓冲区 (ring buffer) 实现 Undo/Redo 系统
;;
;;   - 方向键移动玩家
;;   - SPACE 随机改变玩家颜色
;;   - CTRL+Z 撤销 (Undo)
;;   - CTRL+Y 重做 (Redo)
;;
;; 复杂度: [★★★☆] 3/4
;;
;; 所有 FFI 绑定已在先前示例中完成，无需新增。

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define MAX-UNDO-STATES  26)
(define GRID-CELL-SIZE   24)
(define MAX-GRID-CELLS-X 30)
(define MAX-GRID-CELLS-Y 13)
(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
             "raylib [core] example - undo redo")

;; ---- 玩家状态 ----
(define player-cell-x 10)
(define player-cell-y 10)
(define player-color RED)

;; ---- Undo 环状缓冲区 ----
;; 每个条目: (list cell-x cell-y color)
(define states
  (let ([v (make-vector MAX-UNDO-STATES)])
    (for ([i (in-range MAX-UNDO-STATES)])
      (vector-set! v i (list 10 10 RED)))
    v))

(define current-undo-idx 0)
(define first-undo-idx 0)
(define last-undo-idx 0)
(define undo-frame-counter 0)

;; ---- 布局位置 ----
(define grid-x 40)
(define grid-y 60)
(define undo-info-x 110)
(define undo-info-y 400)

(set-target-fps 60)

;; ============================================================
;; 辅助: 比较两个状态是否相等
;; ============================================================

(define (state=? s1 s2)
  (and (= (car s1) (car s2))
       (= (cadr s1) (cadr s2))
       (color=? (caddr s1) (caddr s2))))

;; ============================================================
;; 辅助: 绘制 Undo 环状缓冲区可视化
;; ============================================================

(define (draw-undo-buffer pos-x pos-y first-idx last-idx cur-idx slot-size)
  ;; 绘制索引标记
  (draw-rectangle (+ pos-x 8 (* slot-size cur-idx)) (- pos-y 10) 8 8 RED)
  (draw-rectangle-lines (+ pos-x 2 (* slot-size first-idx)) (+ pos-y 27) 8 8 BLACK)
  (draw-rectangle (+ pos-x 14 (* slot-size last-idx)) (+ pos-y 27) 8 8 BLACK)

  ;; 背景灰色格子
  (for ([i (in-range MAX-UNDO-STATES)])
    (draw-rectangle (+ pos-x (* slot-size i)) pos-y slot-size slot-size LIGHTGRAY)
    (draw-rectangle-lines (+ pos-x (* slot-size i)) pos-y slot-size slot-size GRAY))

  ;; 已占用格子: firstUndoIndex -> lastUndoIndex (浅蓝)
  (cond
    [(<= first-idx last-idx)
     (for ([i (in-range first-idx (add1 last-idx))])
       (draw-rectangle (+ pos-x (* slot-size i)) pos-y slot-size slot-size SKYBLUE)
       (draw-rectangle-lines (+ pos-x (* slot-size i)) pos-y slot-size slot-size BLUE))]
    [else
     (for ([i (in-range first-idx MAX-UNDO-STATES)])
       (draw-rectangle (+ pos-x (* slot-size i)) pos-y slot-size slot-size SKYBLUE)
       (draw-rectangle-lines (+ pos-x (* slot-size i)) pos-y slot-size slot-size BLUE))
     (for ([i (in-range 0 (add1 last-idx))])
       (draw-rectangle (+ pos-x (* slot-size i)) pos-y slot-size slot-size SKYBLUE)
       (draw-rectangle-lines (+ pos-x (* slot-size i)) pos-y slot-size slot-size BLUE))])

  ;; 已占用格子: firstUndoIndex -> currentUndoIndex (绿色)
  (cond
    [(< first-idx cur-idx)
     (for ([i (in-range first-idx cur-idx)])
       (draw-rectangle (+ pos-x (* slot-size i)) pos-y slot-size slot-size GREEN)
       (draw-rectangle-lines (+ pos-x (* slot-size i)) pos-y slot-size slot-size LIME))]
    [(< cur-idx first-idx)
     (for ([i (in-range first-idx MAX-UNDO-STATES)])
       (draw-rectangle (+ pos-x (* slot-size i)) pos-y slot-size slot-size GREEN)
       (draw-rectangle-lines (+ pos-x (* slot-size i)) pos-y slot-size slot-size LIME))
     (for ([i (in-range 0 cur-idx)])
       (draw-rectangle (+ pos-x (* slot-size i)) pos-y slot-size slot-size GREEN)
       (draw-rectangle-lines (+ pos-x (* slot-size i)) pos-y slot-size slot-size LIME))])

  ;; 当前选中的 UNDO 槽位 (金色)
  (draw-rectangle (+ pos-x (* slot-size cur-idx)) pos-y slot-size slot-size GOLD)
  (draw-rectangle-lines (+ pos-x (* slot-size cur-idx)) pos-y slot-size slot-size ORANGE))

;; ============================================================
;; 主循环
;; ============================================================

(let game-loop ()
  (unless (window-should-close?)
    ;; ==================== 更新 ====================

    ;; ---- 玩家移动 ----
    (cond
      [(is-key-pressed KEY-RIGHT) (set! player-cell-x (add1 player-cell-x))]
      [(is-key-pressed KEY-LEFT)  (set! player-cell-x (sub1 player-cell-x))]
      [(is-key-pressed KEY-UP)    (set! player-cell-y (sub1 player-cell-y))]
      [(is-key-pressed KEY-DOWN)  (set! player-cell-y (add1 player-cell-y))])

    ;; 边界检查
    (when (< player-cell-x 0) (set! player-cell-x 0))
    (when (>= player-cell-x MAX-GRID-CELLS-X)
      (set! player-cell-x (sub1 MAX-GRID-CELLS-X)))
    (when (< player-cell-y 0) (set! player-cell-y 0))
    (when (>= player-cell-y MAX-GRID-CELLS-Y)
      (set! player-cell-y (sub1 MAX-GRID-CELLS-Y)))

    ;; ---- SPACE: 随机改变颜色 ----
    (when (is-key-pressed KEY-SPACE)
      (set! player-color
            (color (get-random-value 20 255)
                        (get-random-value 20 220)
                        (get-random-value 20 240))))

    ;; ---- 每隔 2 帧检查状态变化并记录到缓冲区 ----
    (set! undo-frame-counter (add1 undo-frame-counter))
    (when (>= undo-frame-counter 2)
      (define cur-state (vector-ref states current-undo-idx))
      (unless (state=? cur-state (list player-cell-x player-cell-y player-color))
        (set! current-undo-idx (add1 current-undo-idx))
        (when (>= current-undo-idx MAX-UNDO-STATES) (set! current-undo-idx 0))
        (when (= current-undo-idx first-undo-idx)
          (set! first-undo-idx (add1 first-undo-idx))
          (when (>= first-undo-idx MAX-UNDO-STATES) (set! first-undo-idx 0)))
        (vector-set! states current-undo-idx
                     (list player-cell-x player-cell-y player-color))
        (set! last-undo-idx current-undo-idx))
      (set! undo-frame-counter 0))

    ;; ---- CTRL+Z: 撤销 ----
    (when (and (is-key-down KEY-LEFT-CONTROL) (is-key-pressed KEY-Z))
      (unless (= current-undo-idx first-undo-idx)
        (set! current-undo-idx (sub1 current-undo-idx))
        (when (< current-undo-idx 0)
          (set! current-undo-idx (sub1 MAX-UNDO-STATES)))
        (define restored (vector-ref states current-undo-idx))
        (unless (state=? restored (list player-cell-x player-cell-y player-color))
          (set! player-cell-x (car restored))
          (set! player-cell-y (cadr restored))
          (set! player-color (caddr restored)))))

    ;; ---- CTRL+Y: 重做 ----
    (when (and (is-key-down KEY-LEFT-CONTROL) (is-key-pressed KEY-Y))
      (unless (= current-undo-idx last-undo-idx)
        (define next-idx (add1 current-undo-idx))
        (when (>= next-idx MAX-UNDO-STATES) (set! next-idx 0))
        (unless (= next-idx first-undo-idx)
          (set! current-undo-idx next-idx)
          (define restored (vector-ref states current-undo-idx))
          (unless (state=? restored (list player-cell-x player-cell-y player-color))
            (set! player-cell-x (car restored))
            (set! player-cell-y (cadr restored))
            (set! player-color (caddr restored))))))

    ;; ==================== 绘制 ====================

    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-text "[ARROWS] MOVE PLAYER - [SPACE] CHANGE PLAYER COLOR"
               40 20 20 DARKGRAY)

    ;; ---- 绘制已访问的格子 ----
    (cond
      [(> last-undo-idx first-undo-idx)
       (for ([i (in-range first-undo-idx current-undo-idx)])
         (define state (vector-ref states i))
         (draw-rectangle-rec
          (rectangle (exact->inexact (+ grid-x (* (car state) GRID-CELL-SIZE)))
                     (exact->inexact (+ grid-y (* (cadr state) GRID-CELL-SIZE)))
                     (exact->inexact GRID-CELL-SIZE)
                     (exact->inexact GRID-CELL-SIZE))
          LIGHTGRAY))]
      [(> first-undo-idx last-undo-idx)
       (if (and (< current-undo-idx MAX-UNDO-STATES)
                (> current-undo-idx last-undo-idx))
           (for ([i (in-range first-undo-idx current-undo-idx)])
             (define state (vector-ref states i))
             (draw-rectangle-rec
              (rectangle (exact->inexact (+ grid-x (* (car state) GRID-CELL-SIZE)))
                         (exact->inexact (+ grid-y (* (cadr state) GRID-CELL-SIZE)))
                         (exact->inexact GRID-CELL-SIZE)
                         (exact->inexact GRID-CELL-SIZE))
              LIGHTGRAY))
           (begin
             (for ([i (in-range first-undo-idx MAX-UNDO-STATES)])
               (define state (vector-ref states i))
               (draw-rectangle (+ grid-x (* (car state) GRID-CELL-SIZE))
                               (+ grid-y (* (cadr state) GRID-CELL-SIZE))
                               GRID-CELL-SIZE GRID-CELL-SIZE LIGHTGRAY))
             (for ([i (in-range 0 current-undo-idx)])
               (define state (vector-ref states i))
               (draw-rectangle (+ grid-x (* (car state) GRID-CELL-SIZE))
                               (+ grid-y (* (cadr state) GRID-CELL-SIZE))
                               GRID-CELL-SIZE GRID-CELL-SIZE LIGHTGRAY))))])

    ;; ---- 绘制网格 ----
    (for ([y (in-range (add1 MAX-GRID-CELLS-Y))])
      (draw-line grid-x
                 (+ grid-y (* y GRID-CELL-SIZE))
                 (+ grid-x (* MAX-GRID-CELLS-X GRID-CELL-SIZE))
                 (+ grid-y (* y GRID-CELL-SIZE))
                 GRAY))
    (for ([x (in-range (add1 MAX-GRID-CELLS-X))])
      (draw-line (+ grid-x (* x GRID-CELL-SIZE))
                 grid-y
                 (+ grid-x (* x GRID-CELL-SIZE))
                 (+ grid-y (* MAX-GRID-CELLS-Y GRID-CELL-SIZE))
                 GRAY))

    ;; ---- 绘制玩家 ----
    (draw-rectangle (+ grid-x (* player-cell-x GRID-CELL-SIZE))
                    (+ grid-y (* player-cell-y GRID-CELL-SIZE))
                    (add1 GRID-CELL-SIZE) (add1 GRID-CELL-SIZE)
                    player-color)

    ;; ---- 绘制 Undo 缓冲区可视化 ----
    (draw-text "UNDO STATES:" (- undo-info-x 85) (+ undo-info-y 9) 10 DARKGRAY)
    (draw-undo-buffer undo-info-x undo-info-y
                      first-undo-idx last-undo-idx current-undo-idx 24)

    (end-drawing)
    (game-loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
