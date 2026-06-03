#lang racket/base

;; rcore.rkt 输入系统测试
;; 需 OpenGL 上下文 + 用户交互（或自动轮询）
;; 部分测试只验证函数调用无异常，不验证语义

(require "../helper.rkt"
         (prefix-in lib: "../../raylib/raylib.rkt"))

(printf "~n========================================~n")
(printf "  输入系统测试~n")
(printf "========================================~n")

;; ============================================================
;; 键盘输入
;; ============================================================

(test-section "键盘输入")

(define (test-keyboard-basic)
  (lib:init-window 400 200 "test-keyboard")
  (lib:set-target-fps 60)

  ;; 验证初始状态 (无按键按下)
   (assert-false (lib:is-key-down lib:KEY-SPACE))
   (assert-false (lib:is-key-pressed lib:KEY-A))
   (assert-false (lib:is-key-released lib:KEY-B))
   (assert-true (lib:is-key-up lib:KEY-C))   ;; 没按下应该就是 up
  (test-pass! "初始键盘状态 (无按键)")

  ;; get-key-name
  (define keyname (lib:get-key-name lib:KEY-A))
  (printf "    KEY-A 名称: ~a~n" keyname)
  (test-pass! "get-key-name 无异常")

  ;; set-exit-key
  (lib:set-exit-key lib:KEY-ESCAPE)
  (test-pass! "set-exit-key (默认 ESC)")

  (lib:close-window))

(test-keyboard-basic)

;; ============================================================
;; 鼠标输入
;; ============================================================

(test-section "鼠标输入")

(define (test-mouse-basic)
  (lib:init-window 400 200 "test-mouse")
  (lib:set-target-fps 60)

  ;; 验证按钮初始状态
   (assert-false (lib:is-mouse-button-down lib:MOUSE-BUTTON-LEFT))
   (assert-false (lib:is-mouse-button-pressed lib:MOUSE-BUTTON-RIGHT))
   (assert-false (lib:is-mouse-button-released lib:MOUSE-BUTTON-MIDDLE))
   (assert-true (lib:is-mouse-button-up lib:MOUSE-BUTTON-LEFT))
  (test-pass! "鼠标按钮初始状态")

  ;; 鼠标位置
  (define mx (lib:get-mouse-x))
  (define my (lib:get-mouse-y))
  (printf "    mouse position: ~a, ~a~n" mx my)
  (test-pass! "get-mouse-x / get-mouse-y")

  ;; get-mouse-position (返回 Vector2 指针)
  (define pos (lib:get-mouse-position))
  (define pos-x (lib:ptr-ref pos lib:_float 0))
  (define pos-y (lib:ptr-ref pos lib:_float 1))
  (printf "    get-mouse-position: ~a, ~a~n" pos-x pos-y)
  (test-pass! "get-mouse-position (Vector2 指针)")

  ;; get-mouse-delta
  (define delta (lib:get-mouse-delta))
  (define dx (lib:ptr-ref delta lib:_float 0))
  (define dy (lib:ptr-ref delta lib:_float 1))
  (printf "    get-mouse-delta: ~a, ~a~n" dx dy)
  (test-pass! "get-mouse-delta (Vector2 指针)")

  ;; set-mouse-position
  (lib:set-mouse-position 100 100)
  (test-pass! "set-mouse-position (无异常)")

  ;; get-mouse-wheel-move
  (define wheel (lib:get-mouse-wheel-move))
  (printf "    get-mouse-wheel-move: ~a~n" wheel)
  (test-pass! "get-mouse-wheel-move")

  ;; get-mouse-wheel-move-v
  (define wheel-v (lib:get-mouse-wheel-move-v))
  (define wx (lib:ptr-ref wheel-v lib:_float 0))
  (define wy (lib:ptr-ref wheel-v lib:_float 1))
  (printf "    get-mouse-wheel-move-v: ~a, ~a~n" wx wy)
  (test-pass! "get-mouse-wheel-move-v (Vector2 指针)")

  ;; set-mouse-cursor
  (lib:set-mouse-cursor 0)   ;; MOUSE-CURSOR-DEFAULT
  (test-pass! "set-mouse-cursor (无异常)")

  (lib:close-window))

(test-mouse-basic)

;; ============================================================
;; Cursor 可见性
;; ============================================================

(test-section "Cursor 可见性")

(define (test-cursor)
  (lib:init-window 400 200 "test-cursor")
  (lib:set-target-fps 60)

   (assert-false (lib:is-cursor-hidden?))
  (test-pass! "初始光标可见")

  (lib:hide-cursor)
   (assert-true (lib:is-cursor-hidden?))
  (test-pass! "hide-cursor + is-cursor-hidden?")

  (lib:show-cursor)
   (assert-false (lib:is-cursor-hidden?))
  (test-pass! "show-cursor 恢复")

  (lib:disable-cursor)
  (test-pass! "disable-cursor (无异常)")
  (lib:enable-cursor)
  (test-pass! "enable-cursor (无异常)")

  (printf "    is-cursor-on-screen? = ~a~n" (lib:is-cursor-on-screen?))
  (test-pass! "is-cursor-on-screen?")

  (lib:close-window))

(test-cursor)

;; ============================================================
;; 手柄输入 (可选 — 无手柄时跳过)
;; ============================================================

(test-section "手柄输入")

(define (test-gamepad)
  (lib:init-window 400 200 "test-gamepad")
  (lib:set-target-fps 60)

  (define available (lib:is-gamepad-available? 0))
  (printf "    Gamepad 0 可用: ~a~n" available)

  (when available
    (define name (lib:get-gamepad-name 0))
    (printf "    Gamepad 0 名称: ~a~n" name)
    (test-pass! "get-gamepad-name")

     (assert-false (lib:is-gamepad-button-down 0 lib:GAMEPAD-BUTTON-LEFT-FACE-UP))
    (test-pass! "is-gamepad-button-down (初始 #f)")

    (define axis (lib:get-gamepad-axis-movement 0 lib:GAMEPAD-AXIS-LEFT-X))
    (printf "    Left-X axis: ~a~n" axis)
    (test-pass! "get-gamepad-axis-movement (无异常)")

    (define axis-count (lib:get-gamepad-axis-count 0))
    (printf "    Axis count: ~a~n" axis-count)
    (test-pass! "get-gamepad-axis-count (无异常)"))

  (test-skip! "手柄按钮/振动" (if available "需手动测试" "无手柄连接"))

  (lib:close-window))

(test-gamepad)

;; ============================================================
;; 触摸输入
;; ============================================================

(test-section "触摸输入")

(define (test-touch)
  (lib:init-window 400 200 "test-touch")
  (lib:set-target-fps 60)

  (define tx (lib:get-touch-x))
  (define ty (lib:get-touch-y))
  (printf "    touch position: ~a, ~a~n" tx ty)
  (test-pass! "get-touch-x / get-touch-y")

  (define count (lib:get-touch-point-count))
  (printf "    touch point count: ~a~n" count)
  (test-pass! "get-touch-point-count")

  (define id (lib:get-touch-point-id 0))
  (printf "    touch point 0 id: ~a~n" id)
  (test-pass! "get-touch-point-id")

  (define tpos (lib:get-touch-position 0))
  (define tpos-x (lib:ptr-ref tpos lib:_float 0))
  (define tpos-y (lib:ptr-ref tpos lib:_float 1))
  (printf "    touch position 0: ~a, ~a~n" tpos-x tpos-y)
  (test-pass! "get-touch-position (Vector2 指针)")

  (lib:close-window))

(test-touch)

(printf "~n输入系统测试完成!~n")
