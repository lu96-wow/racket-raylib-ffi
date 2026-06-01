#lang racket/base
;; raylib [shapes] example - kaleidoscope (Racket FFI 翻译)
;; 万花筒绘图: 鼠标拖动画线, 按键控制
(require "../../raylib/raylib.rkt" (only-in ffi/unsafe malloc) racket/math)

(define MAX-LINES 8192)
(define screen-w 800) (define screen-h 450)
(define DEG2RAD (/ pi 180.0))

(init-window screen-w screen-h "raylib [shapes] example - kaleidoscope")
(set-target-fps 20)

(define symmetry (box 6))
(define thickness 3.0)
(define offset (vector2 (/ screen-w 2) (/ screen-h 2)))
(define scale-v (vector2 1.0 -1.0))

(define camera (malloc _Camera2D 'atomic))
(ptr-set! camera _float 0 (ptr-ref offset _float 0))  ;; off-x
(ptr-set! camera _float 1 (ptr-ref offset _float 1))  ;; off-y
(ptr-set! camera _float 2 0.0)  ;; tar-x
(ptr-set! camera _float 3 0.0)  ;; tar-y
(ptr-set! camera _float 4 0.0)  ;; rotation
(ptr-set! camera _float 5 1.0)  ;; zoom

;; 线段存储: 两个平行 vector: start-points, end-points
(define start-pts (make-vector MAX-LINES))
(define end-pts   (make-vector MAX-LINES))
(define total-count (box 0))
(define current-count (box 0))

(define prev-mouse (vector2 0 0))
(define cur-mouse  (vector2 0 0))

(let main-loop ()
  (unless (window-should-close?)
    (define sym (unbox symmetry))
    (define angle (/ 360.0 sym))
    (define total (unbox total-count))
    (define cur (unbox current-count))

    ;; 更新鼠标
    (ptr-set! prev-mouse _float 0 (ptr-ref cur-mouse _float 0))
    (ptr-set! prev-mouse _float 1 (ptr-ref cur-mouse _float 1))
    (ptr-set! cur-mouse _float 0 (exact->inexact (get-mouse-x)))
    (ptr-set! cur-mouse _float 1 (exact->inexact (get-mouse-y)))

    (define line-start (vec2-subtract cur-mouse offset))
    (define line-end   (vec2-subtract prev-mouse offset))

    ;; 键盘控制
    (when (is-key-pressed KEY-C)
      (set-box! current-count 0) (set-box! total-count 0))
    (when (is-key-pressed KEY-LEFT)
      (set-box! current-count (max 0 (- cur 1))))
    (when (is-key-pressed KEY-RIGHT)
      (set-box! current-count (min MAX-LINES (add1 cur)))
      (when (> (unbox current-count) total)
        (set-box! total-count (unbox current-count))))
    (when (is-key-pressed KEY-Q)
      (set-box! symmetry (max 2 (min 12 (- sym 1)))))
    (when (is-key-pressed KEY-W)
      (set-box! symmetry (max 2 (min 12 (+ sym 1)))))

    ;; 鼠标绘制
    (define reset-x (rectangle (- screen-w 55.0) 5.0 50 25))
    (when (and (is-mouse-button-down MOUSE-BUTTON-LEFT)
               (not (check-collision-point-rec cur-mouse reset-x)))
      (let loop ([s 0] [ls line-start] [le line-end])
        (when (and (< s sym) (< total (sub1 MAX-LINES)))
          (define new-ls (vec2-rotate ls (* angle DEG2RAD)))
          (define new-le (vec2-rotate le (* angle DEG2RAD)))
          (vector-set! start-pts total new-ls)
          (vector-set! end-pts   total new-le)
          (vector-set! start-pts (add1 total) (vec2-multiply new-ls scale-v))
          (vector-set! end-pts   (add1 total) (vec2-multiply new-le scale-v))
          (set-box! total-count (+ total 2))
          (set-box! current-count (unbox total-count))
          (loop (add1 s) new-ls new-le))))

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-2d camera)

    ;; 绘制所有线段
    (for ([s (in-range sym)])
      (for ([i (in-range cur)])
        (when (and (vector-ref start-pts i) (vector-ref end-pts i))
          (draw-line-ex (vector-ref start-pts i) (vector-ref end-pts i) thickness BLACK))))

    (end-mode-2d)

    ;; UI
    (draw-text (format "LINES: ~a/~a" cur MAX-LINES) 10 (- screen-h 30) 20 MAROON)
    (draw-text (format "Symmetry [Q/W]: ~a" sym) 10 (- screen-h 55) 15 DARKGRAY)
    (draw-text "[C] Clear  [<- ->] Undo/Redo" 10 (- screen-h 75) 15 DARKGRAY)
    (draw-text "Reset" (- screen-w 55) 10 15 DARKGRAY)
    (draw-rectangle-lines-ex reset-x 1.0 GRAY)
    (draw-fps 10 10)
    (end-drawing)
    (main-loop)))

(close-window)
