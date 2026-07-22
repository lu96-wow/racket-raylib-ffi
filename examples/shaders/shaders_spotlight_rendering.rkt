#lang racket/base

;; raylib [shaders] example - spotlight rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_spotlight_rendering.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref _float _uint malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(define MAX-SPOTS 3)
(define MAX-STARS 400)
(define SCREEN-WIDTH 800.0)
(define SCREEN-HEIGHT 450.0)
(define (f->i v) (inexact->exact (truncate v)))

;; ============================================================
;; ★ 关键: 所有 get-random-value 必须在 init-window (GL 初始化) 之前调用
;;    GL 初始化后大量调用 get-random-value 会导致 FFI 内存错误
;; ============================================================

(struct star (px py sx sy) #:mutable)
(define (random-speed) (/ (get-random-value -1000 1000) 100.0))

(define (make-star)
  (let ([cx (/ SCREEN-WIDTH 2.0)] [cy (/ SCREEN-HEIGHT 2.0)])
    (let loop ([sx (random-speed)] [sy (random-speed)])
      (if (< (+ (abs sx) (abs sy)) 1.0)
          (loop (random-speed) (random-speed))
          (star (+ cx (* sx 8.0)) (+ cy (* sy 8.0)) sx sy)))))

;; 预计算 scatter 后的星空 (纯 Racket, 无 FFI)
(define (scatter-stars stars n-iter)
  (for/fold ([stars stars]) ([_ (in-range n-iter)])
    (for/list ([s stars])
      (let ([nx (+ (star-px s) (star-sx s))]
            [ny (+ (star-py s) (star-sy s))])
        (if (and (>= nx 0.0) (<= nx SCREEN-WIDTH) (>= ny 0.0) (<= ny SCREEN-HEIGHT))
            (star nx ny (star-sx s) (star-sy s))
            (make-star))))))

;; ★ 第一步: 预计算所有随机数据 (init-window 之前!)
(define all-stars
  (scatter-stars (for/list ([_ (in-range MAX-STARS)]) (make-star))
                 (f->i (/ SCREEN-WIDTH 2.0))))

;; Spotlight 初始数据
(define spot-init-data
  (for/vector ([i (in-range MAX-SPOTS)])
    (let loop-sx ()
      (define sx (/ (get-random-value -400 40) 25.0))
      (define sy (/ (get-random-value -400 40) 25.0))
      (if (< (+ (abs sx) (abs sy)) 2.0) (loop-sx)
          (vector (get-random-float 64 (- (f->i SCREEN-WIDTH) 64))
                  (get-random-float 64 (- (f->i SCREEN-HEIGHT) 64))
                  sx sy)))))

;; ============================================================
;; ★ 第二步: GL 初始化 (之后不再调用 get-random-value!)
;; ============================================================

(init-window (f->i SCREEN-WIDTH) (f->i SCREEN-HEIGHT) "raylib [shaders] example - spotlight rendering")
(hide-cursor)

(define tex-ray (load-texture (res "raysan.png")))

;; 转为 FFI 浮点缓冲区
(define stars-vec
  (for/vector ([s all-stars])
    (let ([px (malloc _float 1 'atomic)] [py (malloc _float 1 'atomic)]
          [sx (malloc _float 1 'atomic)] [sy (malloc _float 1 'atomic)])
      (ptr-set! px _float 0 (star-px s)) (ptr-set! py _float 0 (star-py s))
      (ptr-set! sx _float 0 (star-sx s)) (ptr-set! sy _float 0 (star-sy s))
      (vector px py sx sy))))

(define (update-all-stars!)
  (for ([i (in-range MAX-STARS)])
    (define v (vector-ref stars-vec i))
    (define px (vector-ref v 0)) (define py (vector-ref v 1))
    (define sx-v (vector-ref v 2)) (define sy-v (vector-ref v 3))
    (define nx (+ (ptr-ref px _float 0) (ptr-ref sx-v _float 0)))
    (define ny (+ (ptr-ref py _float 0) (ptr-ref sy-v _float 0)))
    (ptr-set! px _float 0 nx) (ptr-set! py _float 0 ny)
    (when (or (< nx 0.0) (> nx SCREEN-WIDTH) (< ny 0.0) (> ny SCREEN-HEIGHT))
      ;; 重置到中心, 用帧计数产生伪随机速度
      (ptr-set! px _float 0 (/ SCREEN-WIDTH 2.0))
      (ptr-set! py _float 0 (/ SCREEN-HEIGHT 2.0))
      (ptr-set! sx-v _float 0 (+ 1.5 (/ (modulo (* frame-counter (+ i 7)) 100) 10.0)))
      (ptr-set! sy-v _float 0 (+ 1.5 (/ (modulo (* frame-counter (+ i 13)) 100) 10.0))))))

;; 加载 spotlight 着色器
(define shdr-spot (load-shader #f (res (format "shaders/glsl~a/spotlight.fs" GLSL-VERSION))))

(define (make-spot i)
  (define pos (malloc _float 2 'atomic))
  (define speed-x (malloc _float 1 'atomic))
  (define speed-y (malloc _float 1 'atomic))
  (define inner-val (malloc _float 1 'atomic))
  (define radius-val (malloc _float 1 'atomic))
  (list pos speed-x speed-y inner-val radius-val
        (get-shader-location shdr-spot (format "spots[~a].pos" i))
        (get-shader-location shdr-spot (format "spots[~a].inner" i))
        (get-shader-location shdr-spot (format "spots[~a].radius" i))))

(define spots (vector (make-spot 0) (make-spot 1) (make-spot 2)))

;; 设置 screenWidth uniform
(define sw (malloc _float 1 'atomic))
(ptr-set! sw _float 0 SCREEN-WIDTH)
(set-shader-value shdr-spot (get-shader-location shdr-spot "screenWidth") sw SHADER-UNIFORM-FLOAT)

;; 初始化 spotlight (使用预计算数据)
(for ([i (in-range MAX-SPOTS)])
  (let* ([s (vector-ref spots i)]
         [d (vector-ref spot-init-data i)]
         [pos (list-ref s 0)] [speed-x (list-ref s 1)] [speed-y (list-ref s 2)]
         [inner-val (list-ref s 3)] [radius-val (list-ref s 4)]
         [pos-loc (list-ref s 5)] [inner-loc (list-ref s 6)] [radius-loc (list-ref s 7)])
    (ptr-set! pos _float 0 (vector-ref d 0))
    (ptr-set! pos _float 1 (vector-ref d 1))
    (ptr-set! speed-x _float 0 (vector-ref d 2))
    (ptr-set! speed-y _float 0 (vector-ref d 3))
    (ptr-set! inner-val _float 0 (* 28.0 (+ i 1.0)))
    (ptr-set! radius-val _float 0 (* 48.0 (+ i 1.0)))
    (set-shader-value shdr-spot pos-loc pos SHADER-UNIFORM-VEC2)
    (set-shader-value shdr-spot inner-loc inner-val SHADER-UNIFORM-FLOAT)
    (set-shader-value shdr-spot radius-loc radius-val SHADER-UNIFORM-FLOAT)))

(define frame-counter 0)
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (set! frame-counter (+ frame-counter 1))
    (update-all-stars!)

    ;; 更新 spotlight
    (for ([i (in-range MAX-SPOTS)])
      (let* ([s (vector-ref spots i)]
             [pos (list-ref s 0)] [speed-x (list-ref s 1)] [speed-y (list-ref s 2)]
             [pos-loc (list-ref s 5)])
        (if (= i 0)
            (let ([mp (get-mouse-position)])
              (ptr-set! pos _float 0 (ptr-ref mp _float 0))
              (ptr-set! pos _float 1 (- SCREEN-HEIGHT (ptr-ref mp _float 1))))
            (begin
              (ptr-set! pos _float 0 (+ (ptr-ref pos _float 0) (ptr-ref speed-x _float 0)))
              (ptr-set! pos _float 1 (+ (ptr-ref pos _float 1) (ptr-ref speed-y _float 0)))
              (when (< (ptr-ref pos _float 0) 64.0)
                (ptr-set! speed-x _float 0 (- (ptr-ref speed-x _float 0))))
              (when (> (ptr-ref pos _float 0) (- SCREEN-WIDTH 64.0))
                (ptr-set! speed-x _float 0 (- (ptr-ref speed-x _float 0))))
              (when (< (ptr-ref pos _float 1) 64.0)
                (ptr-set! speed-y _float 0 (- (ptr-ref speed-y _float 0))))
              (when (> (ptr-ref pos _float 1) (- SCREEN-HEIGHT 64.0))
                (ptr-set! speed-y _float 0 (- (ptr-ref speed-y _float 0))))))
        (set-shader-value shdr-spot pos-loc pos SHADER-UNIFORM-VEC2)))

    (begin-drawing)
    (clear-background DARKBLUE)

    (for ([i (in-range MAX-STARS)])
      (define v (vector-ref stars-vec i))
      (draw-rectangle (f->i (ptr-ref (vector-ref v 0) _float 0))
                      (f->i (ptr-ref (vector-ref v 1) _float 0)) 2 2 WHITE))

    (for ([i (in-range 16)])
      (draw-texture tex-ray
                    (f->i (+ (/ SCREEN-WIDTH 2.0)
                             (* (cos (/ (+ frame-counter (* i 8.0)) 51.45))
                                (/ SCREEN-WIDTH 2.2)) -32.0))
                    (f->i (+ (/ SCREEN-HEIGHT 2.0)
                             (* (sin (/ (+ frame-counter (* i 8.0)) 17.87))
                                (/ SCREEN-HEIGHT 4.2))))
                    WHITE))

    (begin-shader-mode shdr-spot)
    (draw-rectangle 0 0 (f->i SCREEN-WIDTH) (f->i SCREEN-HEIGHT) WHITE)
    (end-shader-mode)

    (draw-fps 10 10)
    (draw-text "Move the mouse!" 10 30 20 GREEN)
    (draw-text "Pitch Black" (f->i (* SCREEN-WIDTH 0.2)) (f->i (/ SCREEN-HEIGHT 2.0)) 20 GREEN)
    (draw-text "Dark" (f->i (* SCREEN-WIDTH 0.66)) (f->i (/ SCREEN-HEIGHT 2.0)) 20 GREEN)
    (end-drawing)
    (loop)))

(unload-texture tex-ray)
(unload-shader shdr-spot)
(close-window)
