#lang racket/base

;; raylib [text] example - sprite fonts (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_sprite_fonts.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 资源路径
;; ============================================================

(define resource-dir
  (path->string (build-path (current-directory) "../../../examples/text/resources/")))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define max-fonts 8)

(init-window screen-width screen-height
  "raylib [text] example - sprite fonts")

;; NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)
(define fonts
  (vector (load-font (string-append resource-dir "sprite_fonts/alagard.png"))
          (load-font (string-append resource-dir "sprite_fonts/pixelplay.png"))
          (load-font (string-append resource-dir "sprite_fonts/mecha.png"))
          (load-font (string-append resource-dir "sprite_fonts/setback.png"))
          (load-font (string-append resource-dir "sprite_fonts/romulus.png"))
          (load-font (string-append resource-dir "sprite_fonts/pixantiqua.png"))
          (load-font (string-append resource-dir "sprite_fonts/alpha_beta.png"))
          (load-font (string-append resource-dir "sprite_fonts/jupiter_crash.png"))))

(define messages
  (vector "ALAGARD FONT designed by Hewett Tsoi"
          "PIXELPLAY FONT designed by Aleksander Shevchuk"
          "MECHA FONT designed by Captain Falcon"
          "SETBACK FONT designed by Brian Kent (AEnigma)"
          "ROMULUS FONT designed by Hewett Tsoi"
          "PIXANTIQUA FONT designed by Gerhard Grossmann"
          "ALPHA_BETA FONT designed by Brian Kent (AEnigma)"
          "JUPITER_CRASH FONT designed by Brian Kent (AEnigma)"))

(define spacings (vector 2 4 8 4 3 4 4 1))
(define colors (vector MAROON ORANGE DARKGREEN DARKBLUE DARKPURPLE LIME GOLD RED))

;; Calculate positions
(define positions
  (for/vector ([i (in-range max-fonts)])
    (let* ([font (vector-ref fonts i)]
           [base-size (exact->inexact (car font))]
           [msg (vector-ref messages i)]
           [spacing (exact->inexact (vector-ref spacings i))]
           [text-size (measure-text-ex font msg (* base-size 2.0) spacing)])
      (vector2 (- (/ screen-width 2.0) (/ (vector2-x text-size) 2.0))
               (+ 60.0 base-size (* 45.0 i))))))

;; Small Y position corrections
(vector-set! positions 3
  (let* ([p (vector-ref positions 3)])
    (vector2 (vector2-x p) (+ (vector2-y p) 8.0))))
(vector-set! positions 4
  (let* ([p (vector-ref positions 4)])
    (vector2 (vector2-x p) (+ (vector2-y p) 2.0))))
(vector-set! positions 7
  (let* ([p (vector-ref positions 7)])
    (vector2 (vector2-x p) (- (vector2-y p) 8.0))))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    (draw-text "free sprite fonts included with raylib" 220 20 20 DARKGRAY)
    (draw-line 220 50 600 50 DARKGRAY)

    (for ([i (in-range max-fonts)])
      (let* ([font (vector-ref fonts i)]
             [base-size (car font)])
        (draw-text-ex font
                      (vector-ref messages i)
                      (vector-ref positions i)
                      (* (exact->inexact base-size) 2.0)
                      (exact->inexact (vector-ref spacings i))
                      (vector-ref colors i))))

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(for ([i (in-range max-fonts)])
  (unload-font (vector-ref fonts i)))
(close-window)
