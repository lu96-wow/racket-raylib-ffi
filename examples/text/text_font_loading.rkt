#lang racket/base

;; raylib [text] example - font loading (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_font_loading.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - font loading")

;; Define characters to draw
(define msg "!#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI\nJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmn\nopqrstuvwxyz{|}~¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓ\nÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷\nøùúûüýþÿ")

;; BMFont (AngelCode) : Font data and image atlas have been generated using external program
(define font-bm (load-font "../../../examples/text/resources/pixantiqua.fnt")) ; Requires pixantiqua.png

;; TTF font : Font data and atlas are generated directly from TTF
(define font-ttf (load-font-ex "../../../examples/text/resources/pixantiqua.ttf" 32 #f 250))

(set-text-line-spacing 16)

(set-target-fps 60)

(let loop ([use-ttf? #f])
  (unless (window-should-close?)
    (define next-ttf? (is-key-down KEY-SPACE))

    (begin-drawing)
    (clear-background RAYWHITE)
    (draw-text "Hold SPACE to use TTF generated font" 20 20 20 LIGHTGRAY)

    (if (not next-ttf?)
        (begin
          (draw-text-ex font-bm msg (vector2 20.0 100.0) (exact->inexact (car font-bm)) 2.0 MAROON)
          (draw-text "Using BMFont (Angelcode) imported" 20 (- (get-screen-height) 30) 20 GRAY))
        (begin
          (draw-text-ex font-ttf msg (vector2 20.0 100.0) (exact->inexact (car font-ttf)) 2.0 LIME)
          (draw-text "Using TTF font generated" 20 (- (get-screen-height) 30) 20 GRAY)))

    (end-drawing)
    (loop next-ttf?)))

;; ============================================================
;; 清理
;; ============================================================

(unload-font font-bm)
(unload-font font-ttf)
(close-window)
