#lang racket/base

;; raylib [textures] example - gif player (Racket FFI 翻译)
;; 对应 C: examples/textures/textures_gif_player.c
;; 演示: 加载 GIF 动画帧，逐帧更新纹理播放

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe)

(define-runtime-path resource-dir-path "../../../examples/textures/resources/")
(define resource-dir (path->string resource-dir-path))

(define screen-width 800)
(define screen-height 450)
(define MAX-FRAME-DELAY 20)
(define MIN-FRAME-DELAY 1)

(init-window screen-width screen-height "raylib [textures] example - gif player")

;; 加载 GIF 动画 (所有帧拼接在一个 Image 中)
(define-values (im-scarfy-anim anim-frames)
  (load-image-anim (string-append resource-dir "scarfy_run.gif")))

(define tex-scarfy-anim (load-texture-from-image im-scarfy-anim))
(define frame-size (* (list-ref im-scarfy-anim 1) (list-ref im-scarfy-anim 2) 4))

(set-target-fps 60)

(let loop ([current-frame 0] [frame-delay 8] [frame-counter 0])
  (unless (window-should-close?)
    (let* ([frame-counter (add1 frame-counter)]

           ;; 帧切换
           [values (if (>= frame-counter frame-delay)
                       (let* ([next-frame (modulo (add1 current-frame) anim-frames)]
                              [offset (* frame-size next-frame)]
                              [data-ptr (list-ref im-scarfy-anim 0)]
                              [_ (update-texture tex-scarfy-anim (ptr-add data-ptr offset _ubyte))])
                         (values next-frame frame-delay 0))
                       (values current-frame frame-delay frame-counter))]
           [current-frame (car (list values))]
           [frame-delay (cadr (list values))]
           [frame-counter (caddr (list values))]

           ;; 调速
           [frame-delay
            (cond [(is-key-pressed KEY-RIGHT) (min (add1 frame-delay) MAX-FRAME-DELAY)]
                  [(is-key-pressed KEY-LEFT)  (max (sub1 frame-delay) MIN-FRAME-DELAY)]
                  [else frame-delay])])

      (begin-drawing)
      (clear-background RAYWHITE)

      (draw-text (format "TOTAL GIF FRAMES:  ~a" anim-frames) 50 30 20 LIGHTGRAY)
      (draw-text (format "CURRENT FRAME: ~a" current-frame) 50 60 20 GRAY)
      (draw-text (format "CURRENT FRAME IMAGE.DATA OFFSET: ~a" (* frame-size current-frame))
                 50 90 20 GRAY)

      (draw-text "FRAMES DELAY: " 100 305 10 DARKGRAY)
      (draw-text (format "~a frames" frame-delay) 620 305 10 DARKGRAY)
      (draw-text "PRESS RIGHT/LEFT KEYS to CHANGE SPEED!" 290 350 10 DARKGRAY)

      ;; 帧延迟进度条
      (for ([i (in-range MAX-FRAME-DELAY)])
        (let ([x (+ 190 (* 21 i))])
          (when (< i frame-delay) (draw-rectangle x 300 20 20 RED))
          (draw-rectangle-lines x 300 20 20 MAROON)))

      ;; 绘制当前帧
      (let ([w (list-ref tex-scarfy-anim 1)]
            [h (list-ref tex-scarfy-anim 2)])
        (draw-texture tex-scarfy-anim
                      (- (quotient (get-screen-width) 2) (quotient w 2))
                      140 WHITE))

      (draw-text "(c) Scarfy sprite by Eiden Marsal"
                 (- screen-width 200) (- screen-height 20) 10 GRAY)

      (end-drawing)
      (loop current-frame frame-delay frame-counter))))

(unload-texture tex-scarfy-anim)
(unload-image im-scarfy-anim)
(close-window)
