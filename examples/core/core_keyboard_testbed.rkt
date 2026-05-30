#lang racket/base

;; raylib [core] example - keyboard testbed
;; 
;; 对应 C: examples/core/core_keyboard_testbed.c
;;
;; 展示键盘布局的交互式测试台：
;;   - 按下键盘键时，对应按键高亮显示（MAROON 边框）
;;   - 鼠标悬停在按键上时，按键以红色高亮
;;   - stdout 输出被按下的键码和字符码
;;
;; NOTE: raylib 定义的键值对应 ENG-US 键盘布局
;;       其他布局的映射由用户自己处理

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define KEY-REC-SPACING 4)   ;; 按键之间的像素间距

;; ============================================================
;; 按键文本映射 — 对应 C 的 GetKeyText()
;; ============================================================

(define (get-key-text key)
  (cond
    ;; 标点符号
    [(= key KEY-APOSTROPHE)    "'"]
    [(= key KEY-COMMA)         ","]
    [(= key KEY-MINUS)         "-"]
    [(= key KEY-PERIOD)        "."]
    [(= key KEY-SLASH)         "/"]
    ;; 数字键
    [(= key KEY-ZERO)  "0"] [(= key KEY-ONE)   "1"]
    [(= key KEY-TWO)   "2"] [(= key KEY-THREE) "3"]
    [(= key KEY-FOUR)  "4"] [(= key KEY-FIVE)  "5"]
    [(= key KEY-SIX)   "6"] [(= key KEY-SEVEN) "7"]
    [(= key KEY-EIGHT) "8"] [(= key KEY-NINE)  "9"]
    [(= key KEY-SEMICOLON) ";"] [(= key KEY-EQUAL) "="]
    ;; 字母键 (A-Z)
    [(= key KEY-A) "A"] [(= key KEY-B) "B"] [(= key KEY-C) "C"]
    [(= key KEY-D) "D"] [(= key KEY-E) "E"] [(= key KEY-F) "F"]
    [(= key KEY-G) "G"] [(= key KEY-H) "H"] [(= key KEY-I) "I"]
    [(= key KEY-J) "J"] [(= key KEY-K) "K"] [(= key KEY-L) "L"]
    [(= key KEY-M) "M"] [(= key KEY-N) "N"] [(= key KEY-O) "O"]
    [(= key KEY-P) "P"] [(= key KEY-Q) "Q"] [(= key KEY-R) "R"]
    [(= key KEY-S) "S"] [(= key KEY-T) "T"] [(= key KEY-U) "U"]
    [(= key KEY-V) "V"] [(= key KEY-W) "W"] [(= key KEY-X) "X"]
    [(= key KEY-Y) "Y"] [(= key KEY-Z) "Z"]
    [(= key KEY-LEFT-BRACKET)  "["]
    [(= key KEY-BACKSLASH)     "\\"]
    [(= key KEY-RIGHT-BRACKET) "]"]
    [(= key KEY-GRAVE)         "`"]
    ;; 功能键
    [(= key KEY-SPACE)     "SPACE"]  [(= key KEY-ESCAPE) "ESC"]
    [(= key KEY-ENTER)     "ENTER"]  [(= key KEY-TAB)    "TAB"]
    [(= key KEY-BACKSPACE) "BACK"]   [(= key KEY-INSERT) "INS"]
    [(= key KEY-DELETE)    "DEL"]
    [(= key KEY-RIGHT) "RIGHT"] [(= key KEY-LEFT)  "LEFT"]
    [(= key KEY-DOWN)  "DOWN"]  [(= key KEY-UP)    "UP"]
    [(= key KEY-PAGE-UP)   "PGUP"]   [(= key KEY-PAGE-DOWN) "PGDOWN"]
    [(= key KEY-HOME)      "HOME"]   [(= key KEY-END)        "END"]
    [(= key KEY-CAPS-LOCK)   "CAPS"] [(= key KEY-SCROLL-LOCK) "LOCK"]
    [(= key KEY-NUM-LOCK)    "NUMLOCK"]
    [(= key KEY-PRINT-SCREEN) "PRINTSCR"] [(= key KEY-PAUSE) "PAUSE"]
    ;; F1~F12
    [(= key KEY-F1)  "F1"]  [(= key KEY-F2)  "F2"]
    [(= key KEY-F3)  "F3"]  [(= key KEY-F4)  "F4"]
    [(= key KEY-F5)  "F5"]  [(= key KEY-F6)  "F6"]
    [(= key KEY-F7)  "F7"]  [(= key KEY-F8)  "F8"]
    [(= key KEY-F9)  "F9"]  [(= key KEY-F10) "F10"]
    [(= key KEY-F11) "F11"] [(= key KEY-F12) "F12"]
    ;; 修饰键
    [(= key KEY-LEFT-SHIFT)      "LSHIFT"]
    [(= key KEY-LEFT-CONTROL)    "LCTRL"]
    [(= key KEY-LEFT-ALT)        "LALT"]
    [(= key KEY-LEFT-SUPER)      "WIN"]
    [(= key KEY-RIGHT-SHIFT)     "RSHIFT"]
    [(= key KEY-RIGHT-CONTROL)   "RCTRL"]
    [(= key KEY-RIGHT-ALT)       "ALTGR"]
    [(= key KEY-RIGHT-SUPER)     "RSUPER"]
    [(= key KEY-KB-MENU)         "KBMENU"]
    ;; 数字键盘
    [(= key 320) "KP0"]   [(= key 321) "KP1"]
    [(= key 322) "KP2"]   [(= key 323) "KP3"]
    [(= key 324) "KP4"]   [(= key 325) "KP5"]
    [(= key 326) "KP6"]   [(= key 327) "KP7"]
    [(= key 328) "KP8"]   [(= key 329) "KP9"]
    [(= key 330) "KPDEC"] [(= key 331) "KPDIV"]
    [(= key 332) "KPMUL"] [(= key 333) "KPSUB"]
    [(= key 334) "KPADD"] [(= key 335) "KPENTER"]
    [(= key 336) "KPEQU"]
    [else ""]))

;; ============================================================
;; 按键绘制 — 对应 C 的 GuiKeyboardKey()
;; ============================================================

(define (gui-keyboard-key bounds key)
  (cond
    [(= key KEY-NULL)
     ;; 空键位：只画浅灰边框
     (draw-rectangle-lines-ex bounds 2.0 LIGHTGRAY)]
    [else
     ;; 根据按键状态绘制
     (if (is-key-down key)
         (begin
           (draw-rectangle-lines-ex bounds 2.0 MAROON)
           (draw-text (get-key-text key)
                      (inexact->exact (floor (+ (rectangle-x bounds) 4)))
                      (inexact->exact (floor (+ (rectangle-y bounds) 4)))
                      10 MAROON))
         (begin
           (draw-rectangle-lines-ex bounds 2.0 DARKGRAY)
           (draw-text (get-key-text key)
                      (inexact->exact (floor (+ (rectangle-x bounds) 4)))
                      (inexact->exact (floor (+ (rectangle-y bounds) 4)))
                      10 DARKGRAY)))])
  ;; 鼠标悬停高亮
  (when (check-collision-point-rec (get-mouse-position) bounds)
    (draw-rectangle-rec bounds (fade RED 0.2))
    (draw-rectangle-lines-ex bounds 3.0 RED)))

;; ============================================================
;; 主程序
;; ============================================================

(define (main)
  ;; 初始化
  (init-window 800 450 "raylib [core] example - keyboard testbed")
  (set-exit-key KEY-NULL)  ;; 避免按 ESC 退出

  ;; 键盘布局数据
  ;;
  ;; line 01: ESC, F1..F12, PRINTSCREEN, PAUSE
  (define line01-widths '(45 45 45 45 45 45 45 45 45 45 45 45 45 62 45))
  (define line01-keys   (list KEY-ESCAPE KEY-F1 KEY-F2 KEY-F3 KEY-F4 KEY-F5
                              KEY-F6 KEY-F7 KEY-F8 KEY-F9 KEY-F10 KEY-F11
                              KEY-F12 KEY-PRINT-SCREEN KEY-PAUSE))

  ;; line 02: `, 1..9, 0, -, =, BACKSPACE, DEL
  (define line02-widths '(25 45 45 45 45 45 45 45 45 45 45 45 45 82 45))
  (define line02-keys   (list KEY-GRAVE KEY-ONE KEY-TWO KEY-THREE KEY-FOUR
                              KEY-FIVE KEY-SIX KEY-SEVEN KEY-EIGHT KEY-NINE
                              KEY-ZERO KEY-MINUS KEY-EQUAL KEY-BACKSPACE KEY-DELETE))

  ;; line 03: TAB, Q..P, [, ], \, INS
  (define line03-widths '(50 45 45 45 45 45 45 45 45 45 45 45 45 57 45))
  (define line03-keys   (list KEY-TAB KEY-Q KEY-W KEY-E KEY-R KEY-T KEY-Y
                              KEY-U KEY-I KEY-O KEY-P KEY-LEFT-BRACKET
                              KEY-RIGHT-BRACKET KEY-BACKSLASH KEY-INSERT))

  ;; line 04: CAPS, A..L, ;, ', ENTER, PAGE_UP
  (define line04-widths '(68 45 45 45 45 45 45 45 45 45 45 45 88 45))
  (define line04-keys   (list KEY-CAPS-LOCK KEY-A KEY-S KEY-D KEY-F KEY-G
                              KEY-H KEY-J KEY-K KEY-L KEY-SEMICOLON
                              KEY-APOSTROPHE KEY-ENTER KEY-PAGE-UP))

  ;; line 05: LSHIFT, Z..M, ,, ., /, RSHIFT, UP, PAGE_DOWN
  (define line05-widths '(80 45 45 45 45 45 45 45 45 45 45 76 45 45))
  (define line05-keys   (list KEY-LEFT-SHIFT KEY-Z KEY-X KEY-C KEY-V KEY-B
                              KEY-N KEY-M KEY-COMMA KEY-PERIOD
                              KEY-SLASH KEY-RIGHT-SHIFT KEY-UP KEY-PAGE-DOWN))

  ;; line 06: LCTRL, WIN, LALT, SPACE, ALTGR, (162), NULL, RCTRL, LEFT, DOWN, RIGHT
  (define line06-widths '(80 45 45 208 45 45 45 60 45 45 45))
  (define line06-keys   (list KEY-LEFT-CONTROL KEY-LEFT-SUPER KEY-LEFT-ALT
                              KEY-SPACE KEY-RIGHT-ALT 162 KEY-NULL
                              KEY-RIGHT-CONTROL KEY-LEFT KEY-DOWN KEY-RIGHT))

  (define keyboard-offset-x 26)
  (define keyboard-offset-y 80)

  (set-target-fps 60)

  ;; 主循环
  (let loop ()
    (unless (window-should-close?)
      ;; 更新
      (let ([key (get-key-pressed)])
        (when (> key 0)
          (printf "KEYBOARD TESTBED: KEY PRESSED:    ~a~n" key)))
      (let ([ch (get-char-pressed)])
        (when (> ch 0)
          (printf "KEYBOARD TESTBED: CHAR PRESSED:   ~a (~a)~n"
                  (integer->char ch) ch)))

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)
      (draw-text "KEYBOARD LAYOUT: ENG-US" 26 38 20 LIGHTGRAY)

      ;; 绘制第 1 行 — 15 个键
      (let loop-keys ([i 0] [rec-offset-x 0])
        (when (< i 15)
          (let ([w (list-ref line01-widths i)]
                [k (list-ref line01-keys i)])
            (gui-keyboard-key (rectangle (+ keyboard-offset-x rec-offset-x)
                                         keyboard-offset-y w 30.0) k)
            (loop-keys (+ i 1) (+ rec-offset-x w KEY-REC-SPACING)))))

      ;; 绘制第 2 行 — 15 个键
      (let loop-keys ([i 0] [rec-offset-x 0])
        (when (< i 15)
          (let ([w (list-ref line02-widths i)]
                [k (list-ref line02-keys i)])
            (gui-keyboard-key (rectangle (+ keyboard-offset-x rec-offset-x)
                                         (+ keyboard-offset-y 30 KEY-REC-SPACING)
                                         w 38.0) k)
            (loop-keys (+ i 1) (+ rec-offset-x w KEY-REC-SPACING)))))

      ;; 绘制第 3 行 — 15 个键
      (let loop-keys ([i 0] [rec-offset-x 0])
        (when (< i 15)
          (let ([w (list-ref line03-widths i)]
                [k (list-ref line03-keys i)])
            (gui-keyboard-key (rectangle (+ keyboard-offset-x rec-offset-x)
                                         (+ keyboard-offset-y 30 38
                                            (* KEY-REC-SPACING 2))
                                         w 38.0) k)
            (loop-keys (+ i 1) (+ rec-offset-x w KEY-REC-SPACING)))))

      ;; 绘制第 4 行 — 14 个键
      (let loop-keys ([i 0] [rec-offset-x 0])
        (when (< i 14)
          (let ([w (list-ref line04-widths i)]
                [k (list-ref line04-keys i)])
            (gui-keyboard-key (rectangle (+ keyboard-offset-x rec-offset-x)
                                         (+ keyboard-offset-y 30 (* 38 2)
                                            (* KEY-REC-SPACING 3))
                                         w 38.0) k)
            (loop-keys (+ i 1) (+ rec-offset-x w KEY-REC-SPACING)))))

      ;; 绘制第 5 行 — 14 个键
      (let loop-keys ([i 0] [rec-offset-x 0])
        (when (< i 14)
          (let ([w (list-ref line05-widths i)]
                [k (list-ref line05-keys i)])
            (gui-keyboard-key (rectangle (+ keyboard-offset-x rec-offset-x)
                                         (+ keyboard-offset-y 30 (* 38 3)
                                            (* KEY-REC-SPACING 4))
                                         w 38.0) k)
            (loop-keys (+ i 1) (+ rec-offset-x w KEY-REC-SPACING)))))

      ;; 绘制第 6 行 — 11 个键
      (let loop-keys ([i 0] [rec-offset-x 0])
        (when (< i 11)
          (let ([w (list-ref line06-widths i)]
                [k (list-ref line06-keys i)])
            (gui-keyboard-key (rectangle (+ keyboard-offset-x rec-offset-x)
                                         (+ keyboard-offset-y 30 (* 38 4)
                                            (* KEY-REC-SPACING 5))
                                         w 38.0) k)
            (loop-keys (+ i 1) (+ rec-offset-x w KEY-REC-SPACING)))))

      (end-drawing)
      (loop)))

  ;; 清理
  (close-window))

;; 运行
(main)
