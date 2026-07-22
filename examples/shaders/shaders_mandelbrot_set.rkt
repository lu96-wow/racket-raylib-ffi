#lang racket/base

;; raylib [shaders] example - mandelbrot set (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_mandelbrot_set.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref _float _int malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 450)

(define points-of-interest
  #(#(-1.76826775 -0.00422996283 28435.9238)
    #(0.322004497 -0.0357099883 56499.7266)
    #(-0.748880744 -0.0562955774 9237.59082)
    #(-1.78385007 -0.0156200649 14599.5283)
    #(-0.0985441282 -0.924688697 26259.8535)
    #(0.317785531 -0.0322612226 29297.9258)))

(define ZOOM-SPEED 1.01)
(define OFFSET-SPEED-MUL 2.0)
(define STARTING-ZOOM 0.6)

(init-window SCREEN-WIDTH SCREEN-HEIGHT "raylib [shaders] example - mandelbrot set")

(define shader (load-shader #f (res (format "shaders/glsl~a/mandelbrot_set.fs" GLSL-VERSION))))
(define target (load-render-texture SCREEN-WIDTH SCREEN-HEIGHT))

;; 获取 uniform 位置
(define zoom-loc (get-shader-location shader "zoom"))
(define offset-loc (get-shader-location shader "offset"))
(define max-iterations-loc (get-shader-location shader "maxIterations"))

;; 初始化值
(define offset (malloc _float 2 'atomic))
(ptr-set! offset _float 0 -0.5) (ptr-set! offset _float 1 0.0)

(define zoom-val (malloc _float 1 'atomic))
(ptr-set! zoom-val _float 0 STARTING-ZOOM)

(define max-iterations-multiplier 166.5)
(define max-iterations 333)
(define max-iter-buf (malloc _int 1 'atomic))
(ptr-set! max-iter-buf _int 0 max-iterations)

;; 上传初始 uniform
(set-shader-value shader zoom-loc zoom-val SHADER-UNIFORM-FLOAT)
(set-shader-value shader offset-loc offset SHADER-UNIFORM-VEC2)
(set-shader-value shader max-iterations-loc max-iter-buf SHADER-UNIFORM-INT)

(define show-controls #t)
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    ;; Update
    (define update-shader #f)

    ;; 按 1-6 切换到兴趣点
    (for ([i (in-range 6)])
      (when (is-key-pressed (+ KEY-ONE i))
        (ptr-set! offset _float 0 (vector-ref (vector-ref points-of-interest i) 0))
        (ptr-set! offset _float 1 (vector-ref (vector-ref points-of-interest i) 1))
        (ptr-set! zoom-val _float 0 (vector-ref (vector-ref points-of-interest i) 2))
        (set! update-shader #t)))

    ;; 按 R 重置
    (when (is-key-pressed KEY-R)
      (ptr-set! offset _float 0 -0.5) (ptr-set! offset _float 1 0.0)
      (ptr-set! zoom-val _float 0 STARTING-ZOOM)
      (set! update-shader #t))

    (when (is-key-pressed KEY-F1) (set! show-controls (not show-controls)))

    ;; 上下键改变迭代次数
    (when (or (is-key-pressed KEY-UP) (is-key-pressed KEY-DOWN))
      (set! max-iterations-multiplier
            (if (is-key-pressed KEY-UP)
                (* max-iterations-multiplier 1.4)
                (/ max-iterations-multiplier 1.4)))
      (set! update-shader #t))

    ;; 鼠标缩放/平移
    (when (or (is-mouse-button-down MOUSE-BUTTON-LEFT)
              (is-mouse-button-down MOUSE-BUTTON-RIGHT))
      (let ([current-zoom (ptr-ref zoom-val _float 0)])
        (ptr-set! zoom-val _float 0
                  (* current-zoom (if (is-mouse-button-down MOUSE-BUTTON-LEFT)
                                     ZOOM-SPEED (/ 1.0 ZOOM-SPEED)))))

      (let* ([mouse-pos (get-mouse-position)]
             [mx (ptr-ref mouse-pos _float 0)]
             [my (ptr-ref mouse-pos _float 1)]
             [new-zoom (ptr-ref zoom-val _float 0)]
             [vel-x (* (/ (- mx (/ SCREEN-WIDTH 2.0)) SCREEN-WIDTH) OFFSET-SPEED-MUL (/ 1.0 new-zoom))]
             [vel-y (* (/ (- my (/ SCREEN-HEIGHT 2.0)) SCREEN-HEIGHT) OFFSET-SPEED-MUL (/ 1.0 new-zoom))])
        (ptr-set! offset _float 0 (+ (ptr-ref offset _float 0) (* (get-frame-time) vel-x)))
        (ptr-set! offset _float 1 (+ (ptr-ref offset _float 1) (* (get-frame-time) vel-y))))

      (set! update-shader #t))

    (when update-shader
      (let* ([z (ptr-ref zoom-val _float 0)]
             [iter (* (sqrt (* 2.0 (sqrt (abs (- 1.0 (sqrt (* 37.5 z)))))))
                      max-iterations-multiplier)])
        (set! max-iterations (inexact->exact (round iter)))
        (ptr-set! max-iter-buf _int 0 max-iterations))
      (set-shader-value shader zoom-loc zoom-val SHADER-UNIFORM-FLOAT)
      (set-shader-value shader offset-loc offset SHADER-UNIFORM-VEC2)
      (set-shader-value shader max-iterations-loc max-iter-buf SHADER-UNIFORM-INT))

    ;; Draw
    (begin-texture-mode target)
    (clear-background BLACK)
    (draw-rectangle 0 0 SCREEN-WIDTH SCREEN-HEIGHT BLACK)
    (end-texture-mode)

    (begin-drawing)
    (clear-background BLACK)
    (begin-shader-mode shader)
    (draw-texture-ex (list (render-texture-tex-id target) (render-texture-tex-width target) (render-texture-tex-height target) (render-texture-tex-mipmaps target) (render-texture-tex-format target))
                     (vector2 0.0 0.0) 0.0 1.0 WHITE)
    (end-shader-mode)

    (when show-controls
      (draw-text "Press Mouse buttons right/left to zoom in/out and move" 10 15 10 RAYWHITE)
      (draw-text "Press F1 to toggle these controls" 10 30 10 RAYWHITE)
      (draw-text "Press [1 - 6] to change point of interest" 10 45 10 RAYWHITE)
      (draw-text "Press UP | DOWN to change number of iterations" 10 60 10 RAYWHITE)
      (draw-text "Press R to recenter the camera" 10 75 10 RAYWHITE))
    (end-drawing)
    (loop)))

(unload-shader shader)
(unload-render-texture target)
(close-window)
