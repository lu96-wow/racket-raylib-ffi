#lang racket/base

;; raylib [text] example - unicode emojis (Racket FFI 翻译 简化版)
;;
;; 对应 C: examples/text/text_unicode_emojis.c
;;
;; 注意: C 原版包含大量 Unicode 表情符号的硬编码字节数据、
;; DrawTextBoxed/DrawTextBoxedSelectable 自定义函数（低层 glyph 访问）、
;; 多种字体加载（dejavu, noto_cjk, symbola）和聊天泡泡特效。
;; 本示例展示基本 Unicode 表情符号绘制功能。

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - unicode emojis (simplified)")

;; 一些 Unicode emoji 示例 (UTF-8 编码)
(define emojis
  (list "😀" "😂" "🤣" "😍" "😎" "🤩" "🥳" "😡"
        "❤️" "🔥" "👍" "🎉" "🌟" "💯" "🍕" "🎮"))

(define font (get-font-default))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    (draw-text "Unicode Emoji Display" 20 20 30 DARKGRAY)

    ;; 在网格中显示表情符号
    (for ([i (in-range (length emojis))])
      (let* ([row (quotient i 4)]
             [col (modulo i 4)]
             [x (+ 50 (* col 180))]
             [y (+ 80 (* row 80))]
             [emoji (list-ref emojis i)])
        (draw-text-ex font emoji (vector2 (exact->inexact x) (exact->inexact y)) 50.0 5.0 BLACK)))

    (draw-text "Each emoji is a Unicode character rendered via font!" 20 (- screen-height 40) 20 GRAY)
    (draw-text "NOTE: Full emoji support requires a font with emoji glyphs"
               20 (- screen-height 20) 15 DARKGRAY)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
