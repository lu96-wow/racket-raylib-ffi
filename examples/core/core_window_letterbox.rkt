#lang racket/base

(require "../../raylib/raylib.rkt")

(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 450)
(define GAME-W 640)
(define GAME-H 480)

(set-config-flags (bitwise-ior FLAG-WINDOW-RESIZABLE FLAG-VSYNC-HINT))
(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - window letterbox")
(set-window-min-size 320 240)

(define target (load-render-texture GAME-W GAME-H))

;; RenderTexture: (id tex-id tex-w tex-h tex-mip tex-fmt dep-id dep-w dep-h dep-mip dep-fmt)
;; Texture:       (id    w      h     mip    fmt)
(define (rt->texture rt)
  (list (list-ref rt 1) (list-ref rt 2) (list-ref rt 3)
        (list-ref rt 4) (list-ref rt 5)))

(set-texture-filter (rt->texture target) TEXTURE-FILTER-BILINEAR)

(set-target-fps 60)

(define (random-color)
  (color (get-random-value 100 250) (get-random-value 50 150)
              (get-random-value 10 100) 255))

(define colors (make-vector 10 #f))
(for ([i (in-range 10)])
  (vector-set! colors i (random-color)))

(let loop ()
  (unless (window-should-close?)
    (let* ([scale (min (/ (exact->inexact (get-screen-width)) GAME-W)
                       (/ (exact->inexact (get-screen-height)) GAME-H))]
           [mouse (get-mouse-position)]
           [vmouse
             (vec2-clamp
               (vector2
                 (/ (- (vector2-x mouse) (* (- (exact->inexact (get-screen-width)) (* GAME-W scale)) 0.5)) scale)
                 (/ (- (vector2-y mouse) (* (- (exact->inexact (get-screen-height)) (* GAME-H scale)) 0.5)) scale))
               (vector2 0.0 0.0)
               (vector2 GAME-W GAME-H))])

      (when (is-key-pressed KEY-SPACE)
        (for ([i (in-range 10)])
          (vector-set! colors i (random-color))))

      ;; 绘制到纹理
      (begin-texture-mode target)
      (clear-background RAYWHITE)
      (for ([i (in-range 10)])
        (draw-rectangle 0 (* (quotient GAME-H 10) i) GAME-W (quotient GAME-H 10)
                        (vector-ref colors i)))
      (draw-text "If executed inside a window,\nyou can resize the window,\nand see the screen scaling!"
        10 25 20 WHITE)
      (draw-text (format "Default Mouse: [~a , ~a]"
                  (inexact->exact (floor (vector2-x mouse)))
                  (inexact->exact (floor (vector2-y mouse))))
        350 25 20 GREEN)
      (draw-text (format "Virtual Mouse: [~a , ~a]"
                  (inexact->exact (floor (vector2-x vmouse)))
                  (inexact->exact (floor (vector2-y vmouse))))
        350 55 20 YELLOW)
      (end-texture-mode)

      ;; 绘制到屏幕
      (begin-drawing)
      (clear-background BLACK)
      (draw-texture-pro
        (rt->texture target)
        (rectangle 0.0 0.0 GAME-W (- GAME-H))
        (rectangle
          (* (- (exact->inexact (get-screen-width)) (* GAME-W scale)) 0.5)
          (* (- (exact->inexact (get-screen-height)) (* GAME-H scale)) 0.5)
          (* GAME-W scale) (* GAME-H scale))
        (vector2 0.0 0.0) 0.0 WHITE)
      (end-drawing)
      (loop))))

(unload-render-texture target)
(close-window)
