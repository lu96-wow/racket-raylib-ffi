#lang racket/base

;; raylib [text] example - strings management (Racket FFI 翻译 简化版)
;;
;; 对应 C: examples/text/text_strings_management.c
;;
;; 注意: C 原版使用复杂的 struct 和物理模拟，此处展示核心文本操作 API。
;; 原版中的 TextSplit, TextFormat, TextToUpper/Lower/Pascal/Snake/Camel 等
;; 函数均可在本示例中观察到。

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define font-size 30)

(init-window screen-width screen-height
  "raylib [text] example - strings management")

;; 当前显示的文本
(define current-text (box "raylib => fun videogames programming!"))
(define display-message (box "raylib => fun videogames programming!"))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新 - 按数字键切换文本转换
    (when (is-key-pressed KEY-ONE)
      (set-box! current-text "raylib => fun videogames programming!")
      (set-box! display-message "Original text"))
    (when (is-key-pressed KEY-TWO)
      (set-box! current-text (text-to-upper (unbox current-text)))
      (set-box! display-message "TextToUpper"))
    (when (is-key-pressed KEY-THREE)
      (set-box! current-text (text-to-lower (unbox current-text)))
      (set-box! display-message "TextToLower"))
    (when (is-key-pressed KEY-FOUR)
      (let ([src "raylib_fun_videogames_programming"])
        (set-box! current-text (text-to-pascal src))
        (set-box! display-message "TextToPascal")))
    (when (is-key-pressed KEY-FIVE)
      (let ([src "RaylibFunVideogamesProgramming"])
        (set-box! current-text (text-to-snake src))
        (set-box! display-message "TextToSnake")))
    (when (is-key-pressed KEY-SIX)
      (let ([src "raylib_fun_videogames_programming"])
        (set-box! current-text (text-to-camel src))
        (set-box! display-message "TextToCamel")))

    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    (draw-text "Text String Management Functions Demo" 20 20 20 DARKGRAY)
    (draw-text "Press keys 1-6 to see different text transformations:" 20 50 15 DARKGRAY)
    (draw-text "  1 = Original" 30 75 15 DARKGRAY)
    (draw-text "  2 = TextToUpper" 30 95 15 DARKGRAY)
    (draw-text "  3 = TextToLower" 30 115 15 DARKGRAY)
    (draw-text "  4 = TextToPascal" 30 135 15 DARKGRAY)
    (draw-text "  5 = TextToSnake" 30 155 15 DARKGRAY)
    (draw-text "  6 = TextToCamel" 30 175 15 DARKGRAY)

    ;; 文本长度信息
    (draw-text (format "Text: \"~a\"" (unbox current-text)) 20 220 20 MAROON)
    (draw-text (format "Text length: ~a characters (bytes)" (text-length (unbox current-text))) 20 260 20 DARKGREEN)
    (draw-text (format "Codepoint count: ~a" (get-codepoint-count (unbox current-text))) 20 290 20 DARKGREEN)
    (draw-text (format "Transformation: ~a" (unbox display-message)) 20 330 20 BLUE)

    ;; 显示转换后的文本
    (let ([text-width (measure-text (unbox current-text) 40)])
      (draw-text (unbox current-text)
                 (quotient (- screen-width text-width) 2)
                 380 40 RED))

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
