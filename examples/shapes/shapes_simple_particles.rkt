#lang racket/base

;; raylib [shapes] example - simple particles (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_simple_particles.c
;; 粒子系统: WATER(下落) SMOKE(上升膨胀褪色) FIRE(上升振荡缩小)
;; 键盘: ↑↓ 改变发射率  ←→ 切换粒子类型
;; 鼠标: 按住拖动发射器


(require "../../raylib/raylib.rkt" racket/math)


;; ============================================================
;; 初始化
;; ============================================================

(define SCREEN-W 800)
(define SCREEN-H 450)
(define MAX-P   3000)
(define DEG2RAD (/ pi 180.0))

(define WATER 0)
(define SMOKE 1)
(define FIRE  2)
(define TYPE-NAMES (vector "WATER" "SMOKE" "FIRE"))

(init-window SCREEN-W SCREEN-H
  "raylib [shapes] example - simple particles")
(set-target-fps 60)


;; ------------------------------------------------------------
;; 发射器参数
;; ------------------------------------------------------------

(define-var emission-rate -2)
(define-var current-type WATER)
(define emitter (vector2 (/ SCREEN-W 2.0) (/ SCREEN-H 2.0)))


;; ------------------------------------------------------------
;; 粒子数据 — 扁平向量, 全部初始化避免 null-pointer
;; ------------------------------------------------------------

(define p-x    (make-vector MAX-P 0.0))
(define p-y    (make-vector MAX-P 0.0))
(define v-x    (make-vector MAX-P 0.0))
(define v-y    (make-vector MAX-P 0.0))
(define p-r    (make-vector MAX-P 0.0))
(define p-life (make-vector MAX-P 0.0))
(define p-alive (make-vector MAX-P #f))
(define p-type (make-vector MAX-P WATER))

(define p-cr (make-vector MAX-P 0))
(define p-cg (make-vector MAX-P 0))
(define p-cb (make-vector MAX-P 0))
(define p-ca (make-vector MAX-P 255))

(define-var head 0)
(define-var tail 0)


;; ------------------------------------------------------------
;; 可复用的临时指针 (绘图用)
;; ------------------------------------------------------------

(define tmp-pos   (vector2 0.0 0.0))
(define tmp-color (color 0 0 0 0))


;; ============================================================
;; 环形缓冲操作
;; ============================================================

(define (circular-buffer-add!)
  (define h (unbox head))
  (define nh (modulo (add1 h) MAX-P))
  (if (= nh (unbox tail)) #f (begin (set-box! head nh) h)))


;; ------------------------------------------------------------
;; 发射一个粒子
;; ------------------------------------------------------------

(define (emit-particle! x y type)
  (define i (circular-buffer-add!))
  (when i
    (vector-set! p-x i x)
    (vector-set! p-y i y)
    (vector-set! p-alive i #t)
    (vector-set! p-life i 0.0)
    (vector-set! p-type i type)
    (define speed (/ (random 10) 5.0))
    (define dir   (* (random 360) DEG2RAD))
    (case type
      [(0) ;; WATER
       (vector-set! p-r i 5.0)
       (vector-set! p-cr i (ptr-ref BLUE _ubyte 0))
       (vector-set! p-cg i (ptr-ref BLUE _ubyte 1))
       (vector-set! p-cb i (ptr-ref BLUE _ubyte 2))
       (vector-set! p-ca i (ptr-ref BLUE _ubyte 3))
       (vector-set! v-x i (* speed (cos dir)))
       (vector-set! v-y i (* speed (sin dir)))]
      [(1) ;; SMOKE
       (vector-set! p-r i 7.0)
       (vector-set! p-cr i (ptr-ref GRAY _ubyte 0))
       (vector-set! p-cg i (ptr-ref GRAY _ubyte 1))
       (vector-set! p-cb i (ptr-ref GRAY _ubyte 2))
       (vector-set! p-ca i (ptr-ref GRAY _ubyte 3))
       (vector-set! v-x i (* speed (cos dir)))
       (vector-set! v-y i (* speed (sin dir)))]
      [(2) ;; FIRE
       (vector-set! p-r i 10.0)
       (vector-set! p-cr i (ptr-ref YELLOW _ubyte 0))
       (vector-set! p-cg i (ptr-ref YELLOW _ubyte 1))
       (vector-set! p-cb i (ptr-ref YELLOW _ubyte 2))
       (vector-set! p-ca i (ptr-ref YELLOW _ubyte 3))
       (vector-set! v-x i (* speed 0.1 (cos dir)))
       (vector-set! v-y i (* speed 0.1 (sin dir)))])))


;; ============================================================
;; 更新 / 绘制
;; ============================================================

(define (update-particles!)
  (let loop ([i (unbox tail)])
    (unless (= i (unbox head))
      (when (vector-ref p-alive i)
        (define r  (vector-ref p-r i))
        (define l  (vector-ref p-life i))
        (vector-set! p-life i (+ l (/ 1.0 60.0)))
        ;; 出界检测
        (when (or (< (vector-ref p-x i) (- r))
                  (> (vector-ref p-x i) (+ SCREEN-W r))
                  (< (vector-ref p-y i) (- r))
                  (> (vector-ref p-y i) (+ SCREEN-H r)))
          (vector-set! p-alive i #f))
        (when (vector-ref p-alive i)
          (case (vector-ref p-type i)
            [(0) ;; WATER
             (vector-set! p-x i (+ (vector-ref p-x i) (vector-ref v-x i)))
             (vector-set! v-y i (+ (vector-ref v-y i) 0.2))
             (vector-set! p-y i (+ (vector-ref p-y i) (vector-ref v-y i)))]
            [(1) ;; SMOKE
             (vector-set! p-x i (+ (vector-ref p-x i) (vector-ref v-x i)))
             (vector-set! v-y i (- (vector-ref v-y i) 0.05))
             (vector-set! p-y i (+ (vector-ref p-y i) (vector-ref v-y i)))
             (vector-set! p-r i (+ r 0.5))
             (vector-set! p-ca i (max 0 (- (vector-ref p-ca i) 4)))
             (when (< (vector-ref p-ca i) 4) (vector-set! p-alive i #f))]
            [(2) ;; FIRE
             (vector-set! p-x i (+ (vector-ref p-x i) (vector-ref v-x i)
                                   (cos (* l 215.0))))
             (vector-set! v-y i (- (vector-ref v-y i) 0.05))
             (vector-set! p-y i (+ (vector-ref p-y i) (vector-ref v-y i)))
             (vector-set! p-r i (- r 0.15))
             (vector-set! p-cg i (max 0 (- (vector-ref p-cg i) 3)))
             (when (<= (vector-ref p-r i) 0.02) (vector-set! p-alive i #f))])))
      (loop (modulo (add1 i) MAX-P)))))


(define (clean-dead-particles!)
  (let loop ()
    (when (and (not (= (unbox tail) (unbox head)))
               (not (vector-ref p-alive (unbox tail))))
      (set-box! tail (modulo (add1 (unbox tail)) MAX-P))
      (loop))))


(define (draw-particles!)
  (let loop ([i (unbox tail)])
    (unless (= i (unbox head))
      (when (vector-ref p-alive i)
        (ptr-set! tmp-pos _float 0 (vector-ref p-x i))
        (ptr-set! tmp-pos _float 1 (vector-ref p-y i))
        (ptr-set! tmp-color _ubyte 0 (vector-ref p-cr i))
        (ptr-set! tmp-color _ubyte 1 (vector-ref p-cg i))
        (ptr-set! tmp-color _ubyte 2 (vector-ref p-cb i))
        (ptr-set! tmp-color _ubyte 3 (vector-ref p-ca i))
        (draw-circle-v tmp-pos (vector-ref p-r i) tmp-color))
      (loop (modulo (add1 i) MAX-P)))))


;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()

  (unless (window-should-close?)

    ;; ---- 更新 ----
    (define er  (unbox emission-rate))
    (define ctp (unbox current-type))
    (define ex  (vector2-x emitter))
    (define ey  (vector2-y emitter))

    (if (< er 0)
        (when (zero? (random (- er)))
          (emit-particle! ex ey ctp))
        (for ([k (in-range (add1 er))])
          (emit-particle! ex ey ctp)))

    (update-particles!)
    (clean-dead-particles!)

    ;; ---- 输入 ----
    (when (is-key-pressed KEY-UP)    (set-box! emission-rate (add1 er)))
    (when (is-key-pressed KEY-DOWN)  (set-box! emission-rate (sub1 er)))
    (when (is-key-pressed KEY-RIGHT) (set-box! current-type
                                         (if (= ctp FIRE) WATER (add1 ctp))))
    (when (is-key-pressed KEY-LEFT)  (set-box! current-type
                                         (if (= ctp WATER) FIRE (sub1 ctp))))
    (when (is-mouse-button-down MOUSE-BUTTON-LEFT)
      (set-vector2-x! emitter (exact->inexact (get-mouse-x)))
      (set-vector2-y! emitter (exact->inexact (get-mouse-y))))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-particles!)

    (draw-rectangle 5 5 315 75 (fade SKYBLUE 0.5))
    (draw-rectangle-lines 5 5 315 75 BLUE)

    (draw-text "CONTROLS:" 15 15 10 BLACK)
    (draw-text "UP/DOWN: Change Particle Emission Rate" 15 35 10 BLACK)
    (draw-text "LEFT/RIGHT: Change Particle Type (Water, Smoke, Fire)" 15 55 10 BLACK)

    (define rate-str
      (if (< er 0)
          (format "Particles every ~a frames" (- er))
          (format "~a Particles per frame" (add1 er))))
    (draw-text (format "~a | Type: ~a" rate-str (vector-ref TYPE-NAMES ctp))
               15 95 10 DARKGRAY)

    (draw-fps (- SCREEN-W 80) 10)
    (end-drawing)

    (main-loop)))


;; ============================================================
;; 清理
;; ============================================================

(close-window)
