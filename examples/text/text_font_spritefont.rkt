#lang racket/base

;; raylib [text] example - font spritefont (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_font_spritefont.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - font spritefont")

(define msg1 "THIS IS A custom SPRITE FONT...")
(define msg2 "...and this is ANOTHER CUSTOM font...")
(define msg3 "...and a THIRD one! GREAT! :D")

;; NOTE: Textures/Fonts MUST be loaded after Window initialization (OpenGL context is required)
(define font1 (load-font "resources/custom_mecha.png"))          ; Font loading
(define font2 (load-font "resources/custom_alagard.png"))        ; Font loading
(define font3 (load-font "resources/custom_jupiter_crash.png"))  ; Font loading

(define font-base1 (exact->inexact (car font1)))
(define font-base2 (exact->inexact (car font2)))
(define font-base3 (exact->inexact (car font3)))

(define font-position1
  (vector2 (- (/ screen-width 2.0)
              (/ (vector2-x (measure-text-ex font1 msg1 font-base1 -3.0)) 2.0))
           (- (/ screen-height 2.0) (/ font-base1 2.0) 80.0)))

(define font-position2
  (vector2 (- (/ screen-width 2.0)
              (/ (vector2-x (measure-text-ex font2 msg2 font-base2 -2.0)) 2.0))
           (- (/ screen-height 2.0) (/ font-base2 2.0) 10.0)))

(define font-position3
  (vector2 (- (/ screen-width 2.0)
              (/ (vector2-x (measure-text-ex font3 msg3 font-base3 2.0)) 2.0))
           (- (/ screen-height 2.0) (/ font-base3 2.0) -50.0)))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    (draw-text-ex font1 msg1 font-position1 font-base1 -3.0 WHITE)
    (draw-text-ex font2 msg2 font-position2 font-base2 -2.0 WHITE)
    (draw-text-ex font3 msg3 font-position3 font-base3 2.0 WHITE)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-font font1)
(unload-font font2)
(unload-font font3)
(close-window)
