#lang racket/base

;; raylib [shaders] example - palette switch (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_palette_switch.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! _int malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(define MAX-PALETTES 3)
(define COLORS-PER-PALETTE 8)
(define VALUES-PER-COLOR 3)

(define palette-data
  (vector
   ;; 3-BIT RGB
   (list 0 0 0   255 0 0   0 255 0   0 0 255
         0 255 255   255 0 255   255 255 0   255 255 255)
   ;; AMMO-8 (GameBoy-like)
   (list 4 12 6   17 35 24   30 58 41   48 93 66
         77 128 97   137 162 87   190 220 127   238 255 204)
   ;; RKBV (2-strip film)
   (list 21 25 26   138 76 88   217 98 117   230 184 193
         69 107 115   75 151 166   165 189 194   255 245 247)))

(define palette-text (vector "3-BIT RGB" "AMMO-8 (GameBoy-like)" "RKBV (2-strip film)"))

(init-window 800 450 "raylib [shaders] example - palette switch")

(define shader (load-shader #f (res (format "shaders/glsl~a/palette_switch.fs" GLSL-VERSION))))
(define palette-loc (get-shader-location shader "palette"))

(define current-palette 0)
(define line-height (/ 450 COLORS-PER-PALETTE))

;; 预分配调色板缓冲区
(define palette-buf (malloc _int (* COLORS-PER-PALETTE VALUES-PER-COLOR) 'atomic))

;; 初始化调色板
(define (load-palette! idx)
  (let ([pal (vector-ref palette-data idx)])
    (for ([i (in-range (* COLORS-PER-PALETTE VALUES-PER-COLOR))])
      (ptr-set! palette-buf _int i (list-ref pal i)))
    (set-shader-value-v shader palette-loc palette-buf SHADER-UNIFORM-IVEC3 COLORS-PER-PALETTE)))

(load-palette! 0)
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    ;; Update
    (when (is-key-pressed KEY-RIGHT)
      (set! current-palette (modulo (+ current-palette 1) MAX-PALETTES))
      (load-palette! current-palette))
    (when (is-key-pressed KEY-LEFT)
      (set! current-palette (modulo (+ current-palette MAX-PALETTES -1) MAX-PALETTES))
      (load-palette! current-palette))

    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-shader-mode shader)
    (for ([i (in-range COLORS-PER-PALETTE)])
      (draw-rectangle 0 (round (* line-height i)) 800 (round line-height) (color i i i 255)))
    (end-shader-mode)
    (draw-text "< >" 10 10 30 DARKBLUE)
    (draw-text "CURRENT PALETTE:" 60 15 20 RAYWHITE)
    (draw-text (vector-ref palette-text current-palette) 300 15 20 RED)
    (draw-fps 700 15)
    (end-drawing)
    (loop)))

(unload-shader shader)
(close-window)
