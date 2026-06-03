#lang racket/base

;; raylib [core] example - clipboard text (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_clipboard_text.c
;;
;; 演示: 剪贴板文本操作 (使用原生 raylib 绘制替代 raygui)
;;   按钮: CUT / COPY / PASTE / CLEAR / Random
;;   快捷键: Ctrl+X / Ctrl+C / Ctrl+V
;;
;; ============================================================
;; C 版差异说明
;; ============================================================
;;
;; C 版使用 raygui (不在 libraylib.so 中):
;;   GuiButton, GuiLabel, GuiTextBox, GuiSetStyle, GuiSetState
;;
;; Racket 版用原生 raylib 绘制替代:
;;   GuiButton   → DrawRectangleRec + DrawText + 鼠标碰撞
;;   GuiLabel    → DrawText
;;   GuiTextBox  → DrawRectangleRec + DrawText 模拟
;;

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)
(define MAX-TEXT-SAMPLES 5)

(define sample-texts
  (vector "Hello from raylib!"
          "The quick brown fox jumps over the lazy dog"
          "Clipboard operations are useful!"
          "raylib is a simple and easy-to-use library"
          "Copy and paste me!"))

;; ============================================================
;; 辅助: 检测按钮点击
;; ============================================================

(define (button! x y w h label)
  (define rect (rectangle (exact->inexact x) (exact->inexact y)
                          (exact->inexact w) (exact->inexact h)))
  (draw-rectangle-rec rect (color 60 60 60))
  (draw-text label (+ x 8) (+ y 10) 14 WHITE)
  (and (check-collision-point-rec (get-mouse-position) rect)
       (is-mouse-button-pressed MOUSE-BUTTON-LEFT)))

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - clipboard text")

(define input-buffer (box "Hello from raylib!"))
(define clipboard-text (box ""))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (define input (unbox input-buffer))
    (define clip (unbox clipboard-text))

    ;; === 更新 ===

    ;; 按钮操作
    (when (button! 50 180 158 40 "CUT")
      (set-clipboard-text input)
      (set-box! clipboard-text (get-clipboard-text))
      (set-box! input-buffer ""))

    (when (button! 215 180 158 40 "COPY")
      (set-clipboard-text input)
      (set-box! clipboard-text (get-clipboard-text)))

    (when (button! 380 180 158 40 "PASTE")
      (set-box! clipboard-text (get-clipboard-text))
      (set-box! input-buffer (unbox clipboard-text)))

    (when (button! 545 180 158 40 "CLEAR")
      (set-box! input-buffer ""))

    (when (button! 710 120 40 40 "RND")
      (set-box! input-buffer
        (vector-ref sample-texts
          (get-random-value 0 (sub1 MAX-TEXT-SAMPLES)))))

    ;; 键盘快捷键
    (when (or (is-key-down KEY-LEFT-CONTROL) (is-key-down KEY-RIGHT-CONTROL))
      (cond
        [(is-key-pressed KEY-X)
         (set-clipboard-text input)
         (set-box! clipboard-text (get-clipboard-text))
         (set-box! input-buffer "")]
        [(is-key-pressed KEY-C)
         (set-clipboard-text input)
         (set-box! clipboard-text (get-clipboard-text))]
        [(is-key-pressed KEY-V)
         (set-box! clipboard-text (get-clipboard-text))
         (set-box! input-buffer (unbox clipboard-text))]))

    ;; 输入框: 检查按键 (简化版, 只支持字符输入)
    (define key (get-char-pressed))
    (when (>= key 32)  ;; 可打印字符
      (set-box! input-buffer (string-append (unbox input-buffer) (string key))))
    (when (and (is-key-pressed KEY-BACKSPACE) (> (string-length (unbox input-buffer)) 0))
      (set-box! input-buffer (substring (unbox input-buffer) 0 (sub1 (string-length (unbox input-buffer))))))

    ;; === 绘制 ===
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 标题
    (draw-text "Use the BUTTONS or KEY SHORTCUTS:" 50 20 20 (color 50 50 50))
    (draw-text "[CTRL+X] - CUT | [CTRL+C] COPY | [CTRL+V] PASTE" 50 60 20 MAROON)

    ;; 输入框
    (draw-rectangle-rec (rectangle 50 120 652 40) WHITE)
    (draw-rectangle-lines 50 120 652 40 DARKGRAY)
    (draw-text (unbox input-buffer) 55 130 20 BLACK)

    ;; 剪贴板状态
    (draw-text "Clipboard current text data:" 50 260 20 (color 50 50 50))
    (draw-rectangle-rec (rectangle 50 300 700 40) (color 240 240 240))
    (draw-rectangle-lines 50 300 700 40 DARKGRAY)
    (draw-text (if (string=? clip "") "(empty)" clip) 55 310 20 (color 100 100 100))

    (draw-text "Try copying text from other applications and pasting here!"
               50 360 20 (color 100 100 100))

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
