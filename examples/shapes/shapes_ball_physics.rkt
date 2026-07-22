#lang racket/base
;; raylib [shapes] example - ball physics (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_ball_physics.c
;; 小球物理模拟: 抓取/投掷, 重力, 摩擦, 弹性碰撞

(require "../../raylib/raylib.rkt" racket/math
         (only-in ffi/unsafe malloc))

;; ============================================================
;; 数据结构
;; ============================================================

(define MAX-BALLS 5000)

(struct ball (position speed prev-position radius friction elasticity color grabbed)
  #:mutable #:transparent)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - ball physics")

;; 球数组
(define balls (make-vector MAX-BALLS #f))

;; 初始化第一个球
(vector-set! balls 0
  (ball (vector2 (/ screen-width 2.0) (/ screen-height 2.0))
        (vector2 200.0 200.0)
        (vector2 0.0 0.0)
        40.0 0.99 0.9 BLUE #f))

(define-var ball-count 1)
(define-var grabbed-ball #f)
(define press-offset (vector2 0.0 0.0))
(define-var gravity 100.0)
(define window-pos (get-window-position))

(define (vx v) (ptr-ref v _float 0))
(define (vy v) (ptr-ref v _float 1))

(define (make-color r g b a)
  (let ([c (malloc _ubyte 4)])
    (ptr-set! c _ubyte 0 r)
    (ptr-set! c _ubyte 1 g)
    (ptr-set! c _ubyte 2 b)
    (ptr-set! c _ubyte 3 a)
    c))

(set-target-fps 60)


;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()
  (unless (window-should-close?)
    (define delta (get-frame-time))
    (define mouse-pos (get-mouse-position))

    ;; 左键按下: 检测是否抓到球
    (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
      (let loop ([i (sub1 (unbox ball-count))])
        (when (>= i 0)
          (let* ([b (vector-ref balls i)]
                 [bpos (ball-position b)]
                 [offx (- (vx mouse-pos) (vx bpos))]
                 [offy (- (vy mouse-pos) (vy bpos))])
            (ptr-set! press-offset _float 0 offx)
            (ptr-set! press-offset _float 1 offy)
            (if (<= (sqrt (+ (* offx offx) (* offy offy))) (ball-radius b))
                (begin (set-ball-grabbed! b #t) (set-box! grabbed-ball b))
                (loop (sub1 i)))))))

    ;; 左键松开: 释放球
    (when (is-mouse-button-released MOUSE-BUTTON-LEFT)
      (let ([gb (unbox grabbed-ball)])
        (when gb (set-ball-grabbed! gb #f) (set-box! grabbed-ball #f))))

    ;; 右键: 创建新球 (Ctrl+右键可连续创建)
    (when (or (is-mouse-button-pressed MOUSE-BUTTON-RIGHT)
              (and (is-key-down KEY-LEFT-CONTROL)
                   (is-mouse-button-down MOUSE-BUTTON-RIGHT)))
      (when (< (unbox ball-count) MAX-BALLS)
        (vector-set! balls (unbox ball-count)
          (ball mouse-pos
                (vector2 (get-random-float -300 300)
                         (get-random-float -300 300))
                (vector2 0.0 0.0)
                (+ 20.0 (get-random-float 0 30))
                0.99 0.9
                (make-color (get-random-value 0 255)
                            (get-random-value 0 255)
                            (get-random-value 0 255) 255)
                #f))
        (set-box! ball-count (add1 (unbox ball-count)))))

    ;; 窗口抖动检测
    (let* ([new-wp (get-window-position)]
           [wp-delta (vec2-subtract window-pos new-wp)])
      (when (> (vec2-length wp-delta) 5.0)
        (let ([shake (vec2-scale wp-delta 10.0)])
          (for ([i (in-range (unbox ball-count))])
            (let ([b (vector-ref balls i)])
              (unless (ball-grabbed b)
                (set-ball-speed! b (vec2-add (ball-speed b) shake)))))))
      (set! window-pos new-wp))

    ;; 中键: 震荡所有球
    (when (is-mouse-button-pressed MOUSE-BUTTON-MIDDLE)
      (for ([i (in-range (unbox ball-count))])
        (let ([b (vector-ref balls i)])
          (unless (ball-grabbed b)
            (set-ball-speed! b
              (vector2 (get-random-float -2000 2000)
                       (get-random-float -2000 2000)))))))

    ;; 滚轮调整重力
    (+= gravity (* (get-mouse-wheel-move) 5.0))

    ;; 更新每个球
    (for ([i (in-range (unbox ball-count))])
      (let ([b (vector-ref balls i)])
        (if (ball-grabbed b)
            (let* ([new-x (- (vx mouse-pos) (vx press-offset))]
                   [new-y (- (vy mouse-pos) (vy press-offset))]
                   [bpos (ball-position b)])
              (set-ball-speed! b (vector2 (/ (- new-x (vx bpos)) delta)
                                          (/ (- new-y (vy bpos)) delta)))
              (set-ball-prev-position! b bpos)
              (ptr-set! bpos _float 0 new-x)
              (ptr-set! bpos _float 1 new-y))
            (let* ([bpos (ball-position b)]
                   [spd  (ball-speed b)]
                   [sx (vx spd)] [sy (vy spd)]
                   [r (ball-radius b)]
                   [el (ball-elasticity b)]
                   [fr (ball-friction b)])
              (ptr-set! bpos _float 0 (+ (vx bpos) (* sx delta)))
              (ptr-set! bpos _float 1 (+ (vy bpos) (* sy delta)))
              (cond [(>= (+ (vx bpos) r) screen-width)
                     (ptr-set! bpos _float 0 (- screen-width r))
                     (set! sx (- (* sx el)))]
                    [(<= (- (vx bpos) r) 0)
                     (ptr-set! bpos _float 0 r)
                     (set! sx (- (* sx el)))])
              (cond [(>= (+ (vy bpos) r) screen-height)
                     (ptr-set! bpos _float 1 (- screen-height r))
                     (set! sy (- (* sy el)))]
                    [(<= (- (vy bpos) r) 0)
                     (ptr-set! bpos _float 1 r)
                     (set! sy (- (* sy el)))])
              (ptr-set! spd _float 0 (* sx fr))
              (ptr-set! spd _float 1 (+ (* sy fr) (unbox gravity)))))))

    ;; --- 绘制 ---
    (begin-drawing)
    (clear-background RAYWHITE)
    (for ([i (in-range (unbox ball-count))])
      (let* ([b (vector-ref balls i)]
             [bpos (ball-position b)]
             [r (ball-radius b)]
             [c (ball-color b)])
        (draw-circle-v bpos r c)
        (draw-circle-lines-v bpos r BLACK)))
    (draw-text "grab a ball by pressing with the mouse and throw it by releasing"
               10 10 10 DARKGRAY)
    (draw-text "right click to create new balls (keep left control pressed to create a lot)"
               10 30 10 DARKGRAY)
    (draw-text "use mouse wheel to change gravity" 10 50 10 DARKGRAY)
    (draw-text "middle click to shake" 10 70 10 DARKGRAY)
    (draw-text (format "BALL COUNT: ~a" (unbox ball-count))
               10 (- (get-screen-height) 70) 20 BLACK)
    (draw-text (format "GRAVITY: ~a" (real->decimal-string (unbox gravity) 2))
               10 (- (get-screen-height) 40) 20 BLACK)
    (end-drawing)
    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
