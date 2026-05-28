#lang racket/base

;; raylib core 模块 — 窗口/输入/绘制上下文/计时/系统
;;
;; 对应 C: rcore.c / raylib.h "Module: core"
;;
;; 设计约定:
;;   结构体在 Racket 侧通过 boxed 指针持有,
;;   对 C 侧传值的小结构体, 由 _xxx-pass 类型自动解包.

(require ffi/unsafe
         (for-syntax racket/base)
         (prefix-in T: "types.rkt"))

;; ============================================================
;; 宏: def-ffi     — 直接传指针 / 基础类型（无包装）
;;   完整跨写 _fun 表达式
;; ============================================================

(define-syntax-rule (def-ffi name c-name fun-spec)
  (define name
    (get-ffi-obj c-name T:lib fun-spec)))

;; ============================================================
;; 宏: def-ffi/unwrap — 结构体传值（自动解引用指针→值）
;;
;;   用法: (def-ffi/unwrap fn "CName" (_fun (c : _color-bytes) -> _void) color->bytes)
;;   展开: λ: 接受指针 → unwrap → 传值
;; ============================================================

(define-syntax-rule (def-ffi/unwrap name c-name fun-spec unwrap-fn)
  (define name
    (let ([f (get-ffi-obj c-name T:lib fun-spec)])
      (λ (x) (f (unwrap-fn x))))))

;; ============================================================
;; 传值类型: Color 传值
;; ============================================================

(define _color-bytes
  (_list-struct _ubyte _ubyte _ubyte _ubyte))

(define (color->bytes c)
  (list (ptr-ref c _ubyte 0)
        (ptr-ref c _ubyte 1)
        (ptr-ref c _ubyte 2)
        (ptr-ref c _ubyte 3)))

;; (预定义颜色已移入 raylib-var/core.rkt)

;; ============================================================
;; 传值类型: Vector2 传值 / 返回值
;; ============================================================

(define _vec2-bytes
  (_list-struct _float _float))

(define (vec2->bytes v)
  (list (ptr-ref v _float 0)   ;; offset 0 = first float (x)
        (ptr-ref v _float 1))) ;; offset 1 = second float (y, at byte 4)

;; 将 C 侧返回的 (list x y) 转换回 Vector2 指针
(define (vec2-bytes->vec2 lst)
  (let ([v (malloc T:_Vector2 'atomic)])
    (ptr-set! v _float 0 (car lst))
    (ptr-set! v _float 1 (cadr lst))
    v))

;; ============================================================
;; 窗口管理 (core_basic_window.c)
;; ============================================================

(def-ffi init-window "InitWindow" (_fun _int _int _string -> _void))
(def-ffi close-window "CloseWindow" (_fun -> _void))
(def-ffi window-should-close? "WindowShouldClose" (_fun -> _bool))
(def-ffi set-target-fps "SetTargetFPS" (_fun _int -> _void))

;; ============================================================
;; 绘制上下文 (core_basic_window.c)
;;
;; def-ffi       — 直接传，无包装
;; def-ffi/unwrap — 自动解引用 Color 指针传值
;; ============================================================

(def-ffi begin-drawing "BeginDrawing" (_fun -> _void))
(def-ffi end-drawing "EndDrawing" (_fun -> _void))

(def-ffi/unwrap clear-background "ClearBackground"
  (_fun (c : _color-bytes) -> _void)
  color->bytes)

(define draw-text
  (let ([f (get-ffi-obj "DrawText" T:lib
             (_fun _string _int _int _int (c : _color-bytes) -> _void))])
    (λ (text x y fontSize c)
      (f text x y fontSize (color->bytes c)))))

;; ============================================================
;; 计时 / 帧率 (core_delta_time.c)
;; ============================================================

(def-ffi get-frame-time "GetFrameTime" (_fun -> _float))
(def-ffi get-fps "GetFPS" (_fun -> _int))
(def-ffi get-mouse-wheel-move "GetMouseWheelMove" (_fun -> _float))
(def-ffi draw-fps "DrawFPS" (_fun _int _int -> _void))

;; ============================================================
;; 输入 — 键盘 (core_delta_time.c, core_input_keys.c, core_input_mouse.c)
;; ============================================================

(def-ffi is-key-pressed        "IsKeyPressed"        (_fun _int -> _bool))
(def-ffi is-key-down           "IsKeyDown"           (_fun _int -> _bool))
(def-ffi is-key-pressed-repeat "IsKeyPressedRepeat"  (_fun _int -> _bool))
(def-ffi is-key-released       "IsKeyReleased"       (_fun _int -> _bool))
(def-ffi is-key-up             "IsKeyUp"             (_fun _int -> _bool))

(def-ffi get-key-pressed       "GetKeyPressed"       (_fun -> _int))
(def-ffi get-char-pressed      "GetCharPressed"      (_fun -> _int))
(def-ffi get-key-name          "GetKeyName"          (_fun _int -> _string))
(def-ffi set-exit-key          "SetExitKey"          (_fun _int -> _void))

;; ============================================================
;; 输入 — 鼠标 (core_input_mouse.c, core_input_mouse_wheel.c)
;; ============================================================

(def-ffi is-mouse-button-pressed  "IsMouseButtonPressed"  (_fun _int -> _bool))
(def-ffi is-mouse-button-down     "IsMouseButtonDown"     (_fun _int -> _bool))
(def-ffi is-mouse-button-released "IsMouseButtonReleased" (_fun _int -> _bool))
(def-ffi is-mouse-button-up       "IsMouseButtonUp"       (_fun _int -> _bool))

(def-ffi get-mouse-x  "GetMouseX"  (_fun -> _int))
(def-ffi get-mouse-y  "GetMouseY"  (_fun -> _int))

(define get-mouse-position
  (let ([f (get-ffi-obj "GetMousePosition" T:lib
             (_fun -> (v : _vec2-bytes)))])
    (λ () (vec2-bytes->vec2 (f)))))

(define get-mouse-delta
  (let ([f (get-ffi-obj "GetMouseDelta" T:lib
             (_fun -> (v : _vec2-bytes)))])
    (λ () (vec2-bytes->vec2 (f)))))

(def-ffi set-mouse-position "SetMousePosition" (_fun _int _int -> _void))
(def-ffi set-mouse-offset   "SetMouseOffset"   (_fun _int _int -> _void))
(def-ffi set-mouse-scale    "SetMouseScale"    (_fun _float _float -> _void))

(define get-mouse-wheel-move-v
  (let ([f (get-ffi-obj "GetMouseWheelMoveV" T:lib
             (_fun -> (v : _vec2-bytes)))])
    (λ () (vec2-bytes->vec2 (f)))))

(def-ffi set-mouse-cursor "SetMouseCursor" (_fun _int -> _void))

;; ============================================================
;; 输入 — cursor 可见性 (core_input_mouse.c)
;; ============================================================

(def-ffi is-cursor-hidden?  "IsCursorHidden"  (_fun -> _bool))
(def-ffi show-cursor        "ShowCursor"      (_fun -> _void))
(def-ffi hide-cursor        "HideCursor"      (_fun -> _void))
(def-ffi enable-cursor      "EnableCursor"    (_fun -> _void))
(def-ffi disable-cursor     "DisableCursor"   (_fun -> _void))
(def-ffi is-cursor-on-screen? "IsCursorOnScreen" (_fun -> _bool))

;; ============================================================
;; 输入 — 事件轮询
;; ============================================================

(def-ffi poll-input-events "PollInputEvents" (_fun -> _void))

;; ============================================================
;; 导出 — 只导出当前示例需要的
;; ============================================================

(provide
 ;; 宏（供其他模块用）
 def-ffi def-ffi/unwrap

 ;; 传值辅助（供其他模块用）
 _color-bytes color->bytes
 _vec2-bytes vec2->bytes vec2-bytes->vec2

 ;; 窗口
 init-window close-window window-should-close? set-target-fps

 ;; 绘制
 begin-drawing end-drawing
 clear-background draw-text

 ;; 计时
 get-frame-time get-fps get-mouse-wheel-move draw-fps

 ;; 输入 — 键盘
 is-key-pressed is-key-down is-key-pressed-repeat
 is-key-released is-key-up
 get-key-pressed get-char-pressed get-key-name set-exit-key

 ;; 输入 — 鼠标
 is-mouse-button-pressed is-mouse-button-down
 is-mouse-button-released is-mouse-button-up
 get-mouse-x get-mouse-y get-mouse-position get-mouse-delta
 set-mouse-position set-mouse-offset set-mouse-scale
 get-mouse-wheel-move-v set-mouse-cursor

 ;; 输入 — cursor 可见性
 is-cursor-hidden? show-cursor hide-cursor
 enable-cursor disable-cursor is-cursor-on-screen?

 ;; 输入 — 事件轮询
 poll-input-events)