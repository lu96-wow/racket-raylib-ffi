#lang racket/base

;; raylib [text] example - unicode ranges (Racket FFI 翻译 简化版)
;;
;; 对应 C: examples/text/text_unicode_ranges.c
;;
;; 注意: C 原版使用 AddCodepointRange 自定义函数动态修改字体 codepoint 范围、
;; 重新生成 font atlas、展示 CJK/西里尔/希腊等 Unicode 区块。
;; 本示例展示多语言文本绘制，使用默认字体（如果字体支持）。

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - unicode ranges (simplified)")

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

    (draw-text "Multi-Language Text Display" 20 20 30 MAROON)

    ;; 用各种语言展示文本
    ;; 注意: 部分语言的 glyph 可能需要特定字体才能正常显示
    (draw-text-ex font "> English: Hello World!" (vector2 50.0 70.0) 28.0 1.0 DARKGRAY)
    (draw-text-ex font "> Español: ¡Hola mundo!" (vector2 50.0 110.0) 28.0 1.0 DARKGRAY)
    (draw-text-ex font "> Français: Bonjour le monde!" (vector2 50.0 150.0) 28.0 1.0 DARKGRAY)
    (draw-text-ex font "> Deutsch: Hallo Welt!" (vector2 50.0 190.0) 28.0 1.0 DARKGRAY)
    (draw-text-ex font "> Русский: Привет мир!" (vector2 50.0 230.0) 28.0 0.0 DARKGRAY)
    (draw-text-ex font "> 中文: 你好世界!" (vector2 50.0 270.0) 28.0 1.0 DARKGRAY)
    (draw-text-ex font "> 日本語: こんにちは世界!" (vector2 50.0 310.0) 28.0 1.0 DARKGRAY)
    (draw-text-ex font "> 한국어: 안녕하세요 세계!" (vector2 50.0 350.0) 28.0 1.0 DARKGRAY)

    (draw-text "NOTE: CJK/Cyrillic glyphs require fonts with those Unicode ranges"
               (- screen-width 500) (- screen-height 20) 10 GRAY)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
