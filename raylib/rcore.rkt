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
;; Color 传值类型
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
;; 输入 (core_delta_time.c)
;; ============================================================

(def-ffi is-key-pressed "IsKeyPressed" (_fun _int -> _bool))

;; ============================================================
;; 导出 — 只导出当前示例需要的
;; ============================================================

(provide
 ;; 宏（供其他模块用）
 def-ffi def-ffi/unwrap
 ;; Color 传值辅助（供其他模块用）
 _color-bytes color->bytes

 ;; 窗口
 init-window close-window window-should-close? set-target-fps

 ;; 绘制
 begin-drawing end-drawing
 clear-background draw-text

 ;; 计时
 get-frame-time get-fps get-mouse-wheel-move draw-fps

 ;; 输入
 is-key-pressed)