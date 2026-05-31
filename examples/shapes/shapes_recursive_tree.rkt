#lang racket/base

;; raylib [shapes] example - recursive tree (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_recursive_tree.c
;; 用键盘控制替代 raygui 滑块

(require "../../raylib/raylib.rkt"
         racket/math)

;; ============================================================
;; 常量 & 工具
;; ============================================================
(define DEG2RAD (/ pi 180.0))
(define MAX-BRANCHES 1030)

(struct branch (start end angle len) #:transparent #:mutable)

(define (fmt v d) (real->decimal-string v d))
(define (on/off v) (if v "[x]" "[ ]"))

;; ============================================================
;; 初始化
;; ============================================================
(define screen-w 800)
(define screen-h 450)

(init-window screen-w screen-h
             "raylib [shapes] example - recursive tree")

;; 可变状态用 box
(define start       (vector2 (- (/ screen-w 2.0) 125.0) screen-h))
(define angle       (box 40.0))
(define thick       (box 1.0))
(define depth       (box 10.0))
(define decay       (box 0.66))
(define len         (box 120.0))
(define bezier?     (box #f))

(define branches (make-vector MAX-BRANCHES #f))

(set-target-fps 60)


;; ============================================================
;; 分支生成 — 用 named-let 传递 count 参数，避免 set! 副作用
;; ============================================================
(define (generate-branches theta max-count decay-val len-val)
  (let ([initial-end
         (vector2 (vector2-x start)
                  (- (vector2-y start) len-val))])
    (vector-set! branches 0 (branch start initial-end 0.0 len-val))

    (let iter ([i 0] [count 1])
      (if (>= i count)
          count
          (let* ([b  (vector-ref branches i)]
                 [bl (and b (branch-len b))])
            (if (and bl (>= bl 2.0))
                (let ([next-len (* bl decay-val)])
                  (if (and (< count max-count) (>= next-len 2.0))
                      (let* ([br-start (branch-end b)]
                             [a1 (+ (branch-angle b) theta)]
                             [a2 (- (branch-angle b) theta)])
                        ;; 左分支
                        (vector-set! branches count
                                     (branch br-start
                                             (vector2 (+ (vector2-x br-start)
                                                         (* next-len (sin a1)))
                                                      (- (vector2-y br-start)
                                                         (* next-len (cos a1))))
                                             a1 next-len))
                        ;; 右分支
                        (vector-set! branches (+ count 1)
                                     (branch br-start
                                             (vector2 (+ (vector2-x br-start)
                                                         (* next-len (sin a2)))
                                                      (- (vector2-y br-start)
                                                         (* next-len (cos a2))))
                                             a2 next-len))
                        (iter (+ i 1) (+ count 2)))
                      (iter (+ i 1) count)))
                (iter (+ i 1) count)))))))


;; ============================================================
;; 主循环
;; ============================================================
(let main-loop ()
  (unless (window-should-close?)
    ;; ---- 键盘控制 ----
    (cond [(is-key-pressed KEY-Q) (set-box! angle (min 180.0 (+ (unbox angle) 2.0)))]
          [(is-key-pressed KEY-W) (set-box! angle (max 0.0   (- (unbox angle) 2.0)))])
    (cond [(is-key-pressed KEY-A) (set-box! len   (min 240.0 (+ (unbox len) 5.0)))]
          [(is-key-pressed KEY-S) (set-box! len   (max 12.0  (- (unbox len) 5.0)))])
    (cond [(is-key-pressed KEY-Z) (set-box! decay (min 0.78 (+ (unbox decay) 0.02)))]
          [(is-key-pressed KEY-X) (set-box! decay (max 0.1  (- (unbox decay) 0.02)))])
    (cond [(is-key-pressed KEY-E) (set-box! depth (min 10.0 (+ (unbox depth) 1.0)))]
          [(is-key-pressed KEY-R) (set-box! depth (max 1.0  (- (unbox depth) 1.0)))])
    (cond [(is-key-pressed KEY-D) (set-box! thick (min 8.0 (+ (unbox thick) 1.0)))]
          [(is-key-pressed KEY-F) (set-box! thick (max 1.0 (- (unbox thick) 1.0)))])
    (when (is-key-pressed KEY-T) (set-box! bezier? (not (unbox bezier?))))

    ;; ---- 更新 ----
    (define count
      (generate-branches (* (unbox angle) DEG2RAD)
                         (expt 2 (exact-floor (unbox depth)))
                         (unbox decay)
                         (unbox len)))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 画树
    (for ([i (in-range count)])
      (let ([b (vector-ref branches i)])
        (when (and b (>= (branch-len b) 2))
          (if (unbox bezier?)
              (draw-line-bezier (branch-start b) (branch-end b) (unbox thick) RED)
              (draw-line-ex    (branch-start b) (branch-end b) (unbox thick) RED)))))

    ;; 控制面板背景
    (draw-line 580 0 580 (get-screen-height) (make-color 218 218 218))
    (draw-rectangle 580 0 (get-screen-width) (get-screen-height)
                    (make-color 232 232 232))

    ;; 参数显示
    (draw-text (format "Angle  [Q/W]: ~a" (fmt (unbox angle) 1))  640 40  10 DARKGRAY)
    (draw-text (format "Length [A/S]: ~a" (fmt (unbox len)   1))  640 70  10 DARKGRAY)
    (draw-text (format "Decay  [Z/X]: ~a" (fmt (unbox decay) 2))  640 100 10 DARKGRAY)
    (draw-text (format "Depth  [E/R]: ~a" (fmt (unbox depth) 1))  640 130 10 DARKGRAY)
    (draw-text (format "Thick  [D/F]: ~a" (fmt (unbox thick) 1))  640 160 10 DARKGRAY)
    (draw-text (format "~a Bezier [T]" (on/off (unbox bezier?)))  640 190 10 DARKGRAY)

    (draw-fps 10 10)
    (end-drawing)

    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================
(close-window)
