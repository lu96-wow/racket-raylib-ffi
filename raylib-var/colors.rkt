#lang racket/base

;; raylib-var/colors.rkt — 预定义颜色常量
;; 依赖 types/color.rkt 的 color 构造器

(require ffi/unsafe
         "../raylib/core/types/color.rkt")

;; ============================================================
;; 预定义颜色
;; ============================================================

(define RAYWHITE   (color 245 245 245))
(define LIGHTGRAY  (color 200 200 200))
(define GRAY       (color 130 130 130))
(define DARKGRAY   (color 80 80 80))
(define YELLOW     (color 253 249 0))
(define GOLD       (color 255 203 0))
(define ORANGE     (color 255 161 0))
(define PINK       (color 255 109 194))
(define RED        (color 230 41 55))
(define MAROON     (color 190 33 55))
(define GREEN      (color 0 228 48))
(define LIME       (color 0 158 47))
(define DARKGREEN  (color 0 117 44))
(define SKYBLUE    (color 102 191 255))
(define BLUE       (color 0 121 241))
(define DARKBLUE   (color 0 82 172))
(define PURPLE     (color 200 122 255))
(define VIOLET     (color 135 60 190))
(define DARKPURPLE (color 112 31 126))
(define BEIGE      (color 211 176 131))
(define BROWN      (color 127 106 79))
(define DARKBROWN  (color 76 63 47))
(define WHITE      (color 255 255 255))
(define BLACK      (color 0 0 0))
(define BLANK      (color 0 0 0 0))
(define MAGENTA    (color 255 0 255))

(provide
 RAYWHITE LIGHTGRAY GRAY DARKGRAY YELLOW GOLD ORANGE
 PINK RED MAROON GREEN LIME DARKGREEN SKYBLUE
 BLUE DARKBLUE PURPLE VIOLET DARKPURPLE
 BEIGE BROWN DARKBROWN WHITE BLACK BLANK MAGENTA)
