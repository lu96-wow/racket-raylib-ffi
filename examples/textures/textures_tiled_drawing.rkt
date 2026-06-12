#lang racket/base

;; raylib [textures] example - tiled drawing (Racket FFI 翻译)
;; 对应 C: examples/textures/textures_tiled_drawing.c
;; 演示: 纹理平铺绘制 (自定义 DrawTextureTiled)

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define-runtime-path resource-dir-path
  "../../../examples/textures/resources/")
(define resource-dir (path->string resource-dir-path))

(define screen-width 800)
(define screen-height 450)
(define OPT-WIDTH 220)
(define MARGIN-SIZE 8)
(define COLOR-SIZE 16)
(define FLAG-WINDOW-RESIZABLE 4)
(define TEXTURE-FILTER-BILINEAR 1)

;; ============================================================
;; DrawTextureTiled
;; ============================================================
(define (draw-texture-tiled texture source dest origin rotation scale tint)
  (define tex-id (list-ref texture 0))
  (define src-x (rectangle-x source)) (define src-y (rectangle-y source))
  (define src-w (rectangle-w source)) (define src-h (rectangle-h source))
  (define dst-x (rectangle-x dest)) (define dst-y (rectangle-y dest))
  (define dst-w (rectangle-w dest)) (define dst-h (rectangle-h dest))
  (when (and (> tex-id 0) (> scale 0.0) (> src-w 0) (> src-h 0))
    (define tile-w (* src-w scale))
    (define tile-h (* src-h scale))
    (cond
      [(and (< dst-w tile-w) (< dst-h tile-h))
       (draw-texture-pro texture
                         (rectangle src-x src-y (* (/ dst-w tile-w) src-w) (* (/ dst-h tile-h) src-h))
                         dest origin rotation tint)]
      [(<= dst-w tile-w)
       (let vloop ([dy 0.0])
         (when (< (+ dy tile-h) dst-h)
           (draw-texture-pro texture
                             (rectangle src-x src-y (* (/ dst-w tile-w) src-w) src-h)
                             (rectangle dst-x (+ dst-y dy) dst-w tile-h) origin rotation tint)
           (vloop (+ dy tile-h))))
       (let ([dy (* (floor (/ dst-h tile-h)) tile-h)])
         (when (< dy dst-h)
           (draw-texture-pro texture
                             (rectangle src-x src-y (* (/ dst-w tile-w) src-w)
                                        (* (/ (- dst-h dy) tile-h) src-h))
                             (rectangle dst-x (+ dst-y dy) dst-w (- dst-h dy)) origin rotation tint)))]
      [(<= dst-h tile-h)
       (let hloop ([dx 0.0])
         (when (< (+ dx tile-w) dst-w)
           (draw-texture-pro texture
                             (rectangle src-x src-y src-w (* (/ dst-h tile-h) src-h))
                             (rectangle (+ dst-x dx) dst-y tile-w dst-h) origin rotation tint)
           (hloop (+ dx tile-w))))
       (let ([dx (* (floor (/ dst-w tile-w)) tile-w)])
         (when (< dx dst-w)
           (draw-texture-pro texture
                             (rectangle src-x src-y (* (/ (- dst-w dx) tile-w) src-w)
                                        (* (/ dst-h tile-h) src-h))
                             (rectangle (+ dst-x dx) dst-y (- dst-w dx) dst-h) origin rotation tint)))]
      [else
       (let hloop ([dx 0.0])
         (when (< (+ dx tile-w) dst-w)
           (let vloop ([dy 0.0])
             (when (< (+ dy tile-h) dst-h)
               (draw-texture-pro texture source
                                 (rectangle (+ dst-x dx) (+ dst-y dy) tile-w tile-h)
                                 origin rotation tint)
               (vloop (+ dy tile-h))))
           (let ([dy (* (floor (/ dst-h tile-h)) tile-h)])
             (when (< dy dst-h)
               (draw-texture-pro texture
                                 (rectangle src-x src-y src-w (* (/ (- dst-h dy) tile-h) src-h))
                                 (rectangle (+ dst-x dx) (+ dst-y dy) tile-w (- dst-h dy))
                                 origin rotation tint)))
           (hloop (+ dx tile-w))))
       (let ([dx (* (floor (/ dst-w tile-w)) tile-w)])
         (when (< dx dst-w)
           (let vloop ([dy 0.0])
             (when (< (+ dy tile-h) dst-h)
               (draw-texture-pro texture
                                 (rectangle src-x src-y (* (/ (- dst-w dx) tile-w) src-w) src-h)
                                 (rectangle (+ dst-x dx) (+ dst-y dy) (- dst-w dx) tile-h)
                                 origin rotation tint)
               (vloop (+ dy tile-h))))
           (let ([dy (* (floor (/ dst-h tile-h)) tile-h)])
             (when (< dy dst-h)
               (draw-texture-pro texture
                                 (rectangle src-x src-y (* (/ (- dst-w dx) tile-w) src-w)
                                            (* (/ (- dst-h dy) tile-h) src-h))
                                 (rectangle (+ dst-x dx) (+ dst-y dy) (- dst-w dx) (- dst-h dy))
                                 origin rotation tint)))))])))

;; ============================================================
;; 初始化
;; ============================================================

(set-config-flags FLAG-WINDOW-RESIZABLE)
(init-window screen-width screen-height
             "raylib [textures] example - tiled drawing")

(define tex-pattern (load-texture (string-append resource-dir "patterns.png")))
(set-texture-filter tex-pattern TEXTURE-FILTER-BILINEAR)

(define rec-patterns
  (vector (rectangle 3.0 3.0 66.0 66.0)
          (rectangle 75.0 3.0 100.0 100.0)
          (rectangle 3.0 75.0 66.0 66.0)
          (rectangle 7.0 156.0 50.0 50.0)
          (rectangle 85.0 106.0 90.0 45.0)
          (rectangle 75.0 154.0 100.0 60.0)))

(define colors-list
  (list BLACK MAROON ORANGE BLUE PURPLE BEIGE LIME RED DARKGRAY SKYBLUE))
(define num-colors (length colors-list))

(define color-recs (make-vector num-colors))
(let ([x 0.0] [y 0.0])
  (for ([i (in-range num-colors)])
    (vector-set! color-recs i
                 (rectangle (+ 2.0 MARGIN-SIZE x)
                            (+ 22.0 256.0 MARGIN-SIZE y)
                            (* COLOR-SIZE 2.0) COLOR-SIZE))
    (if (= i (- (quotient num-colors 2) 1))
        (begin (set! x 0.0) (set! y (+ y COLOR-SIZE MARGIN-SIZE)))
        (set! x (+ x (* COLOR-SIZE 2) MARGIN-SIZE)))))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ([active-pattern 0] [active-col 0] [scale 1.0] [rotation 0.0])
  (unless (window-should-close?)
    (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
      (let ([mouse (get-mouse-position)])
        (let ploop ([i 0])
          (when (< i (vector-length rec-patterns))
            (let* ([rp (vector-ref rec-patterns i)]
                   [btn (rectangle (+ 2 MARGIN-SIZE (rectangle-x rp))
                                   (+ 40 MARGIN-SIZE (rectangle-y rp))
                                   (rectangle-w rp) (rectangle-h rp))])
              (if (check-collision-point-rec mouse btn)
                  (set! active-pattern i)
                  (ploop (+ i 1))))))
        (let cloop ([i 0])
          (when (< i num-colors)
            (if (check-collision-point-rec mouse (vector-ref color-recs i))
                (set! active-col i)
                (cloop (+ i 1)))))))
    (let* ([new-scale (cond [(is-key-pressed KEY-UP) (+ scale 0.25)]
                            [(is-key-pressed KEY-DOWN) (- scale 0.25)]
                            [else scale])]
           [new-scale (cond [(> new-scale 10.0) 10.0]
                            [(<= new-scale 0.0) 0.25]
                            [else new-scale])]
           [new-rot (cond [(is-key-pressed KEY-LEFT) (- rotation 25.0)]
                          [(is-key-pressed KEY-RIGHT) (+ rotation 25.0)]
                          [else rotation])]
           [new-scale (if (is-key-pressed KEY-SPACE) 1.0 new-scale)]
           [new-rot (if (is-key-pressed KEY-SPACE) 0.0 new-rot)])
      (begin-drawing)
      (clear-background RAYWHITE)
      (draw-texture-tiled tex-pattern
                          (vector-ref rec-patterns active-pattern)
                          (rectangle (+ OPT-WIDTH MARGIN-SIZE) MARGIN-SIZE
                                     (- (get-screen-width) OPT-WIDTH (* 2.0 MARGIN-SIZE))
                                     (- (get-screen-height) (* 2.0 MARGIN-SIZE)))
                          (vector2 0.0 0.0) new-rot new-scale (list-ref colors-list active-col))
      (draw-rectangle MARGIN-SIZE MARGIN-SIZE (- OPT-WIDTH MARGIN-SIZE)
                      (- (get-screen-height) (* 2 MARGIN-SIZE))
                      (color-alpha LIGHTGRAY 0.5))
      (draw-text "Select Pattern" (+ 2 MARGIN-SIZE) (+ 30 MARGIN-SIZE) 10 BLACK)
      (draw-texture tex-pattern (+ 2 MARGIN-SIZE) (+ 40 MARGIN-SIZE) BLACK)
      (let ([rp (vector-ref rec-patterns active-pattern)])
        (draw-rectangle (+ 2 MARGIN-SIZE (inexact->exact (round (rectangle-x rp))))
                        (+ 40 MARGIN-SIZE (inexact->exact (round (rectangle-y rp))))
                        (inexact->exact (round (rectangle-w rp)))
                        (inexact->exact (round (rectangle-h rp)))
                        (color-alpha DARKBLUE 0.3)))
      (draw-text "Select Color" (+ 2 MARGIN-SIZE) (+ 10 256 MARGIN-SIZE) 10 BLACK)
      (for ([i (in-range num-colors)])
        (let ([cr (vector-ref color-recs i)])
          (draw-rectangle-rec cr (list-ref colors-list i))
          (when (= active-col i)
            (draw-rectangle-lines-ex cr 3.0 (color-alpha WHITE 0.5)))))
      (draw-text "Scale (UP/DOWN to change)"
                 (+ 2 MARGIN-SIZE) (+ 80 256 MARGIN-SIZE) 10 BLACK)
      (draw-text (format "~ax" (/ (round (* new-scale 100)) 100.0))
                 (+ 2 MARGIN-SIZE) (+ 92 256 MARGIN-SIZE) 20 BLACK)
      (draw-text "Rotation (LEFT/RIGHT to change)"
                 (+ 2 MARGIN-SIZE) (+ 122 256 MARGIN-SIZE) 10 BLACK)
      (draw-text (format "~a degrees" (round new-rot))
                 (+ 2 MARGIN-SIZE) (+ 134 256 MARGIN-SIZE) 20 BLACK)
      (draw-text "Press [SPACE] to reset"
                 (+ 2 MARGIN-SIZE) (+ 164 256 MARGIN-SIZE) 10 DARKBLUE)
      (draw-text (format "~a FPS" (get-fps))
                 (+ 2 MARGIN-SIZE) (+ 2 MARGIN-SIZE) 20 BLACK)
      (end-drawing)
      (loop active-pattern active-col new-scale new-rot))))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture tex-pattern)
(close-window)
