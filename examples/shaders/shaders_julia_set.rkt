#lang racket/base

;; raylib [shaders] example - julia set (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_julia_set.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref _float malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 450)

(define points-of-interest
  #(#(-0.348827 0.607167) #(-0.786268 0.169728) #(-0.8 0.156)
    #(0.285 0.0) #(-0.835 -0.2321) #(-0.70176 -0.3842)))

(define ZOOM-SPEED 1.01)
(define OFFSET-SPEED-MUL 2.0)
(define STARTING-ZOOM 0.75)

(init-window SCREEN-WIDTH SCREEN-HEIGHT "raylib [shaders] example - julia set")

(define shader (load-shader #f (res (format "shaders/glsl~a/julia_set.fs" GLSL-VERSION))))
(define target (load-render-texture SCREEN-WIDTH SCREEN-HEIGHT))

;; 获取 uniform 位置
(define c-loc (get-shader-location shader "c"))
(define zoom-loc (get-shader-location shader "zoom"))
(define offset-loc (get-shader-location shader "offset"))

;; 初始化值
(define c (malloc _float 2 'atomic))
(ptr-set! c _float 0 (vector-ref (vector-ref points-of-interest 0) 0))
(ptr-set! c _float 1 (vector-ref (vector-ref points-of-interest 0) 1))

(define offset (malloc _float 2 'atomic))
(ptr-set! offset _float 0 0.0) (ptr-set! offset _float 1 0.0)

(define zoom-val (malloc _float 1 'atomic))
(ptr-set! zoom-val _float 0 STARTING-ZOOM)

;; 上传初始 uniform
(set-shader-value shader c-loc c SHADER-UNIFORM-VEC2)
(set-shader-value shader zoom-loc zoom-val SHADER-UNIFORM-FLOAT)
(set-shader-value shader offset-loc offset SHADER-UNIFORM-VEC2)

(define increment-speed 0)
(define show-controls #t)

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    ;; Update
    ;; 按 1-6 切换到兴趣点
    (for ([i (in-range 6)])
      (when (is-key-pressed (+ KEY-ONE i))
        (ptr-set! c _float 0 (vector-ref (vector-ref points-of-interest i) 0))
        (ptr-set! c _float 1 (vector-ref (vector-ref points-of-interest i) 1))
        (set-shader-value shader c-loc c SHADER-UNIFORM-VEC2)))

    ;; 按 R 重置
    (when (is-key-pressed KEY-R)
      (ptr-set! zoom-val _float 0 STARTING-ZOOM)
      (ptr-set! offset _float 0 0.0) (ptr-set! offset _float 1 0.0)
      (set-shader-value shader zoom-loc zoom-val SHADER-UNIFORM-FLOAT)
      (set-shader-value shader offset-loc offset SHADER-UNIFORM-VEC2))

    (when (is-key-pressed KEY-SPACE) (set! increment-speed 0))
    (when (is-key-pressed KEY-F1) (set! show-controls (not show-controls)))
    (when (is-key-pressed KEY-RIGHT) (set! increment-speed (+ increment-speed 1)))
    (when (is-key-pressed KEY-LEFT) (set! increment-speed (- increment-speed 1)))

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

      (set-shader-value shader zoom-loc zoom-val SHADER-UNIFORM-FLOAT)
      (set-shader-value shader offset-loc offset SHADER-UNIFORM-VEC2))

    ;; 随时间变化 c
    (let ([dc (* (get-frame-time) increment-speed 0.0005)])
      (ptr-set! c _float 0 (+ (ptr-ref c _float 0) dc))
      (ptr-set! c _float 1 (+ (ptr-ref c _float 1) dc))
      (set-shader-value shader c-loc c SHADER-UNIFORM-VEC2))

    ;; Draw
    (begin-texture-mode target)
    (clear-background BLACK)
    (draw-rectangle 0 0 SCREEN-WIDTH SCREEN-HEIGHT BLACK)
    (end-texture-mode)

    (begin-drawing)
    (clear-background BLACK)
    (begin-shader-mode shader)
    ;; 从 RenderTexture 提取纹理子列表 (id width height mipmaps format)
    (draw-texture-ex (list (render-texture-tex-id target) (render-texture-tex-width target) (render-texture-tex-height target) (render-texture-tex-mipmaps target) (render-texture-tex-format target))
                     (vector2 0.0 0.0) 0.0 1.0 WHITE)
    (end-shader-mode)

    (when show-controls
      (draw-text "Press Mouse buttons right/left to zoom in/out and move" 10 15 10 RAYWHITE)
      (draw-text "Press KEY_F1 to toggle these controls" 10 30 10 RAYWHITE)
      (draw-text "Press KEYS [1 - 6] to change point of interest" 10 45 10 RAYWHITE)
      (draw-text "Press KEY_LEFT | KEY_RIGHT to change speed" 10 60 10 RAYWHITE)
      (draw-text "Press KEY_SPACE to stop movement animation" 10 75 10 RAYWHITE)
      (draw-text "Press KEY_R to recenter the camera" 10 90 10 RAYWHITE))
    (end-drawing)
    (loop)))

(unload-shader shader)
(unload-render-texture target)
(close-window)
