#lang racket/base
;; raylib [shapes] example - double pendulum (Racket FFI 翻译)
;; 双摆物理模拟 + 轨迹拖尾
(require "../../raylib/raylib.rkt" racket/math)

(define SIMULATION-STEPS 30)
(define G 9.81)
(define DEG2RAD (/ pi 180.0))
(define RAD2DEG (/ 180.0 pi))

(set-config-flags FLAG-WINDOW-HIGHDPI)
(init-window 800 450 "raylib [shapes] example - double pendulum")
(set-target-fps 60)

(define screen-w 800) (define screen-h 450)

;; 物理参数
(define l1 15.0) (define m1 0.2) (define theta1 (box (* DEG2RAD 170))) (define w1 (box 0.0))
(define l2 15.0) (define m2 0.1) (define theta2 (box 0.0)) (define w2 (box 0.0))
(define length-scaler 0.1)
(define total-m (+ m1 m2))

(define L1 (* l1 length-scaler)) (define L2 (* l2 length-scaler))

(define line-thick 20) (define trail-thick 2.0) (define fade-alpha 0.01)

;; RenderTexture + texture filter
(define target (load-render-texture screen-w screen-h))
(set-texture-filter (list (cadr target) (caddr target) (cadddr target)  ;; texture.id/w/h
                          (list-ref target 4) (list-ref target 5))       ;; mipmaps/format
                    TEXTURE-FILTER-BILINEAR)

;; rt->texture: 从 RenderTexture 的 11 元素 list 提取内嵌 Texture
(define (rt->texture rt)
  (list (list-ref rt 1)   ;; tex-id
        (list-ref rt 2)   ;; tex-width
        (list-ref rt 3)   ;; tex-height
        (list-ref rt 4)   ;; tex-mipmaps
        (list-ref rt 5))) ;; tex-format

(define (pend-endpoint l theta)
  (vector2 (* 10 l (sin theta)) (* 10 l (cos theta))))

(define (double-pend-endpoint l1 th1 l2 th2)
  (define e1 (pend-endpoint l1 th1))
  (vector2 (+ (ptr-ref e1 _float 0) (* 10 l2 (sin th2)))
           (+ (ptr-ref e1 _float 1) (* 10 l2 (cos th2)))))

(define prev-pos
  (let ([p (double-pend-endpoint l1 (unbox theta1) l2 (unbox theta2))])
    (ptr-set! p _float 0 (+ (ptr-ref p _float 0) (/ screen-w 2)))
    (ptr-set! p _float 1 (+ (ptr-ref p _float 1) (- (/ screen-h 2) 100)))
    p))

(let main-loop ()
  (unless (window-should-close?)
    (define dt (get-frame-time))
    (define step (/ dt SIMULATION-STEPS)) (define step2 (* step step))

    ;; 物理更新
    (for ([i (in-range SIMULATION-STEPS)])
      (define t1 (unbox theta1)) (define t2 (unbox theta2))
      (define ww1 (unbox w1)) (define ww2 (unbox w2))
      (define delta (- t1 t2))
      (define sinD (sin delta)) (define cosD (cos delta)) (define cos2D (cos (* 2 delta)))

      (define a1 (/ (- (* -1 G (+ (* 2 m1) m2) (sin t1))
                       (* m2 G (sin (- t1 (* 2 t2))))
                       (* 2 sinD m2 (+ (* ww2 L2) (* ww1 L1 cosD))))
                    (* L1 (- (+ (* 2 m1) m2) (* m2 cos2D)))))
      (define a2 (/ (* 2 sinD (+ (* ww1 L1 total-m)
                                (* G total-m (cos t1))
                                (* ww2 L2 m2 cosD)))
                    (* L2 (- (+ (* 2 m1) m2) (* m2 cos2D)))))

      (set-box! theta1 (+ t1 (* ww1 step) (* 0.5 a1 step2)))
      (set-box! theta2 (+ t2 (* ww2 step) (* 0.5 a2 step2)))
      (set-box! w1 (+ ww1 (* a1 step)))
      (set-box! w2 (+ ww2 (* a2 step))))

    ;; 当前位置
    (define cur-pos (double-pend-endpoint l1 (unbox theta1) l2 (unbox theta2)))
    (ptr-set! cur-pos _float 0 (+ (ptr-ref cur-pos _float 0) (/ screen-w 2)))
    (ptr-set! cur-pos _float 1 (+ (ptr-ref cur-pos _float 1) (- (/ screen-h 2) 100)))

    ;; 绘制轨迹到 render texture
    (begin-texture-mode target)
    (draw-rectangle 0 0 screen-w screen-h (fade BLACK fade-alpha))
    (draw-circle-v prev-pos trail-thick RED)
    (draw-line-ex prev-pos cur-pos (* trail-thick 2.0) RED)
    (end-texture-mode)

    ;; 更新 prev
    (ptr-set! prev-pos _float 0 (ptr-ref cur-pos _float 0))
    (ptr-set! prev-pos _float 1 (ptr-ref cur-pos _float 1))

    ;; 主绘制
    (begin-drawing)
    (clear-background BLACK)
    (draw-texture-rec (rt->texture target)
                      (rectangle 0 0 screen-w (* -1 screen-h))
                      (vector2 0 0) WHITE)

    ;; 摆臂 1
    (draw-rectangle-pro
      (rectangle (/ screen-w 2) (- (/ screen-h 2) 100) (* 10 l1) line-thick)
      (vector2 0 (* line-thick 0.5))
      (- 90 (* RAD2DEG (unbox theta1))) RAYWHITE)

    ;; 摆臂 2
    (define e1 (pend-endpoint l1 (unbox theta1)))
    (draw-rectangle-pro
      (rectangle (+ (/ screen-w 2) (ptr-ref e1 _float 0))
                 (+ (- (/ screen-h 2) 100) (ptr-ref e1 _float 1))
                 (* 10 l2) line-thick)
      (vector2 0 (* line-thick 0.5))
      (- 90 (* RAD2DEG (unbox theta2))) RAYWHITE)

    (end-drawing)
    (main-loop)))

(unload-render-texture target)
(close-window)
