#lang racket/base

;; raylib core 模块 — 窗口/输入/绘制上下文/计时/系统
;;
;; 对应 C: rcore.c / raylib.h "Module: core"
;;
;; 设计约定:
;;   结构体在 Racket 侧通过 boxed 指针持有,
;;   对 C 侧传值的小结构体, 由 _xxx-pass 类型自动解包.

(require (except-in ffi/unsafe _bool)
         (for-syntax racket/base)
         (prefix-in T: "types.rkt")
         (only-in "types.rkt" _bool))

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
;; Camera2D 传值辅助
;; ============================================================

(define _camera2d-bytes
  (_list-struct _float _float _float _float _float _float))

(define (camera2d->bytes cam)
  (list (ptr-ref cam _float 0)   ;; off-x
        (ptr-ref cam _float 1)   ;; off-y
        (ptr-ref cam _float 2)   ;; tar-x
        (ptr-ref cam _float 3)   ;; tar-y
        (ptr-ref cam _float 4)   ;; rotation
        (ptr-ref cam _float 5))) ;; zoom

;; ============================================================
;; 2D 相机 (core_2d_camera.c)
;; ============================================================

(def-ffi/unwrap begin-mode-2d "BeginMode2D"
  (_fun (c : _camera2d-bytes) -> _void)
  camera2d->bytes)

(def-ffi end-mode-2d "EndMode2D" (_fun -> _void))

;; ============================================================
;; 屏幕坐标 ↔ 世界坐标转换
;; GetScreenToWorld2D(Vector2 position, Camera2D camera) -> Vector2
;; GetWorldToScreen2D(Vector2 position, Camera2D camera) -> Vector2
;; ============================================================

(define get-screen-to-world-2d
  (let ([f (get-ffi-obj "GetScreenToWorld2D" T:lib
             (_fun (pos : _vec2-bytes) (cam : _camera2d-bytes) -> (v : _vec2-bytes)))])
    (λ (position camera)
      (vec2-bytes->vec2 (f (vec2->bytes position) (camera2d->bytes camera))))))

(define get-world-to-screen-2d
  (let ([f (get-ffi-obj "GetWorldToScreen2D" T:lib
             (_fun (pos : _vec2-bytes) (cam : _camera2d-bytes) -> (v : _vec2-bytes)))])
    (λ (position camera)
      (vec2-bytes->vec2 (f (vec2->bytes position) (camera2d->bytes camera))))))

;; ============================================================
;; 3D 传值辅助: Vector3
;; ============================================================

(define _vec3-bytes
  (_list-struct _float _float _float))

(define (vec3->bytes v)
  (list (ptr-ref v _float 0)
        (ptr-ref v _float 1)
        (ptr-ref v _float 2)))

(define (vec3-bytes->vec3 lst)
  (let ([v (malloc T:_Vector3 'atomic)])
    (ptr-set! v _float 0 (car lst))
    (ptr-set! v _float 1 (cadr lst))
    (ptr-set! v _float 2 (caddr lst))
    v))

;; ============================================================
;; 3D 传值辅助: Camera3D
;;   10 floats + 1 int = 44 字节
;;   pos-x/y/z @ float 0-2, tar-x/y/z @ float 3-5,
;;   up-x/y/z @ float 6-8, fovy @ float 9, projection @ int 0
;; ============================================================

(define _camera3d-bytes
  (_list-struct _float _float _float _float _float _float
                _float _float _float _float _int))

(define (camera3d->bytes cam)
  (list (ptr-ref cam _float 0)   ;; pos-x
        (ptr-ref cam _float 1)   ;; pos-y
        (ptr-ref cam _float 2)   ;; pos-z
        (ptr-ref cam _float 3)   ;; tar-x
        (ptr-ref cam _float 4)   ;; tar-y
        (ptr-ref cam _float 5)   ;; tar-z
        (ptr-ref cam _float 6)   ;; up-x
        (ptr-ref cam _float 7)   ;; up-y
        (ptr-ref cam _float 8)   ;; up-z
        (ptr-ref cam _float 9)   ;; fovy
        (ptr-ref cam _int 10)))  ;; projection (10th int at byte 40)

;; ============================================================
;; 3D 相机 (core_3d_camera_mode.c, core_3d_camera_free.c)
;; ============================================================

(def-ffi/unwrap begin-mode-3d "BeginMode3D"
  (_fun (c : _camera3d-bytes) -> _void)
  camera3d->bytes)

(def-ffi end-mode-3d "EndMode3D" (_fun -> _void))

;; UpdateCamera(Camera *camera, int mode) → void
;; Camera3D 在 Racket 侧已是指针, 直接传 _pointer
(def-ffi update-camera "UpdateCamera" (_fun _pointer _int -> _void))

;; ============================================================
;; 3D 网格绘制 (core_2d_camera_mouse_zoom.c)
;; DrawGrid(int slices, float spacing)
;; ============================================================

(def-ffi draw-grid "DrawGrid" (_fun _int _float -> _void))

;; ============================================================
;; rlgl 矩阵操作 (core_2d_camera_mouse_zoom.c)
;; ============================================================

(def-ffi rl-push-matrix  "rlPushMatrix"  (_fun -> _void))
(def-ffi rl-pop-matrix   "rlPopMatrix"   (_fun -> _void))
(def-ffi rl-translate-f  "rlTranslatef"  (_fun _float _float _float -> _void))
(def-ffi rl-rotate-f     "rlRotatef"     (_fun _float _float _float _float -> _void))

;; ============================================================
;; 绘制 — 2D 线条 (core_2d_camera.c)
;; DrawLine(int startPosX, int startPosY, int endPosX, int endPosY, Color color)
;; ============================================================

(define draw-line
  (let ([f (get-ffi-obj "DrawLine" T:lib
             (_fun _int _int _int _int (c : _color-bytes) -> _void))])
    (λ (start-x start-y end-x end-y color)
      (f start-x start-y end-x end-y (color->bytes color)))))

;; ============================================================
;; 随机 (core_2d_camera.c)
;; GetRandomValue(int min, int max) -> int
;; ============================================================

(def-ffi get-random-value "GetRandomValue" (_fun _int _int -> _int))

;; ============================================================
;; 窗口管理 (core_basic_window.c)
;; ============================================================

(def-ffi init-window "InitWindow" (_fun _int _int _string -> _void))
(def-ffi close-window "CloseWindow" (_fun -> _void))
(def-ffi window-should-close? "WindowShouldClose" (_fun -> _bool))
(def-ffi set-target-fps "SetTargetFPS" (_fun _int -> _void))

;; ============================================================
;; 窗口状态 / 标志管理 (core_window_flags.c)
;; ============================================================

(def-ffi toggle-fullscreen          "ToggleFullscreen"          (_fun -> _void))
(def-ffi toggle-borderless-windowed "ToggleBorderlessWindowed"  (_fun -> _void))
(def-ffi is-window-state?           "IsWindowState"             (_fun _uint -> _bool))
(def-ffi set-window-state           "SetWindowState"            (_fun _uint -> _void))
(def-ffi clear-window-state         "ClearWindowState"          (_fun _uint -> _void))
(def-ffi minimize-window            "MinimizeWindow"            (_fun -> _void))
(def-ffi maximize-window            "MaximizeWindow"            (_fun -> _void))
(def-ffi restore-window             "RestoreWindow"             (_fun -> _void))

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

;; ============================================================
;; 屏幕信息 (core_2d_camera_mouse_zoom.c)
;; ============================================================

(def-ffi get-screen-width  "GetScreenWidth"  (_fun -> _int))
(def-ffi get-screen-height "GetScreenHeight" (_fun -> _int))

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
;; 配置 (core_input_gamepad.c)
;; ============================================================

(def-ffi set-config-flags "SetConfigFlags" (_fun _uint -> _void))

;; ============================================================
;; 输入 — 手柄 / gamepad (core_input_gamepad.c)
;; ============================================================

(def-ffi is-gamepad-available?    "IsGamepadAvailable"    (_fun _int -> _bool))
(def-ffi get-gamepad-name         "GetGamepadName"        (_fun _int -> _string))
(def-ffi is-gamepad-button-pressed "IsGamepadButtonPressed" (_fun _int _int -> _bool))
(def-ffi is-gamepad-button-down   "IsGamepadButtonDown"   (_fun _int _int -> _bool))
(def-ffi is-gamepad-button-released "IsGamepadButtonReleased" (_fun _int _int -> _bool))
(def-ffi is-gamepad-button-up     "IsGamepadButtonUp"     (_fun _int _int -> _bool))
(def-ffi get-gamepad-button-pressed "GetGamepadButtonPressed" (_fun -> _int))
(def-ffi get-gamepad-axis-count   "GetGamepadAxisCount"   (_fun _int -> _int))
(def-ffi get-gamepad-axis-movement "GetGamepadAxisMovement" (_fun _int _int -> _float))
(def-ffi set-gamepad-mappings     "SetGamepadMappings"    (_fun _string -> _int))
(def-ffi set-gamepad-vibration    "SetGamepadVibration"   (_fun _int _float _float _float -> _void))

;; ============================================================
;; 输入 — 触摸 (core_input_multitouch.c, core_input_gestures.c)
;; ============================================================

(def-ffi get-touch-x          "GetTouchX"          (_fun -> _int))
(def-ffi get-touch-y          "GetTouchY"          (_fun -> _int))
(def-ffi get-touch-point-id   "GetTouchPointId"    (_fun _int -> _int))
(def-ffi get-touch-point-count "GetTouchPointCount" (_fun -> _int))

(define get-touch-position
  (let ([f (get-ffi-obj "GetTouchPosition" T:lib
             (_fun _int -> (v : _vec2-bytes)))])
    (λ (index) (vec2-bytes->vec2 (f index)))))

;; ============================================================
;; 颜色工具 (core_input_gestures.c)
;; Fade(Color color, float alpha) -> Color
;; ============================================================

(define fade
  (let ([f (get-ffi-obj "Fade" T:lib
             (_fun (c : _color-bytes) _float -> (v : _color-bytes)))])
    (λ (color alpha)
      (let ([lst (f (color->bytes color) alpha)])
        (let ([c (malloc T:_Color 'atomic)])
          (ptr-set! c _ubyte 0 (car lst))
          (ptr-set! c _ubyte 1 (cadr lst))
          (ptr-set! c _ubyte 2 (caddr lst))
          (ptr-set! c _ubyte 3 (cadddr lst))
          c)))))

;; ============================================================
;; 输入 — 手势 (core_input_gestures.c)
;; ============================================================

(def-ffi set-gestures-enabled    "SetGesturesEnabled"    (_fun _uint -> _void))
(def-ffi is-gesture-detected?    "IsGestureDetected"     (_fun _uint -> _bool))
(def-ffi get-gesture-detected    "GetGestureDetected"    (_fun -> _int))
(def-ffi get-gesture-hold-duration "GetGestureHoldDuration" (_fun -> _float))
(def-ffi get-gesture-drag-angle  "GetGestureDragAngle"   (_fun -> _float))
(def-ffi get-gesture-pinch-angle "GetGesturePinchAngle"  (_fun -> _float))

(define get-gesture-drag-vector
  (let ([f (get-ffi-obj "GetGestureDragVector" T:lib
             (_fun -> (v : _vec2-bytes)))])
    (λ () (vec2-bytes->vec2 (f)))))

(define get-gesture-pinch-vector
  (let ([f (get-ffi-obj "GetGesturePinchVector" T:lib
             (_fun -> (v : _vec2-bytes)))])
    (λ () (vec2-bytes->vec2 (f)))))

;; ============================================================
;; Rectangle 传值/返回值辅助
;; ============================================================

(define _rect-bytes
  (_list-struct _float _float _float _float))

(define (rect->bytes r)
  (list (ptr-ref r _float 0)
        (ptr-ref r _float 1)
        (ptr-ref r _float 2)
        (ptr-ref r _float 3)))

(define (rect-bytes->rect lst)
  (let ([r (malloc T:_Rectangle 'atomic)])
    (ptr-set! r _float 0 (car lst))
    (ptr-set! r _float 1 (cadr lst))
    (ptr-set! r _float 2 (caddr lst))
    (ptr-set! r _float 3 (cadddr lst))
    r))

;; ============================================================
;; Ray / BoundingBox / RayCollision 传值辅助 (core_3d_picking.c)
;; ============================================================

(define _ray-bytes
  (_list-struct _float _float _float _float _float _float))

(define (ray->bytes r)
  (list (ptr-ref r _float 0) (ptr-ref r _float 1) (ptr-ref r _float 2)
        (ptr-ref r _float 3) (ptr-ref r _float 4) (ptr-ref r _float 5)))

;; ============================================================
;; GetScreenToWorldRay (core_3d_picking.c)
;; Ray GetScreenToWorldRay(Vector2 position, Camera camera)
;; ============================================================

(define get-screen-to-world-ray
  (let ([f (get-ffi-obj "GetScreenToWorldRay" T:lib
             (_fun (pos : _vec2-bytes) (cam : _camera3d-bytes) -> (r : _ray-bytes)))])
    (λ (position camera)
      (let ([lst (f (vec2->bytes position) (camera3d->bytes camera))])
        (let ([r (malloc T:_Ray 'atomic)])
          (ptr-set! r _float 0 (car lst))
          (ptr-set! r _float 1 (cadr lst))
          (ptr-set! r _float 2 (caddr lst))
          (ptr-set! r _float 3 (cadddr lst))
          (ptr-set! r _float 4 (car (cddddr lst)))
          (ptr-set! r _float 5 (cadr (cddddr lst)))
          r)))))

;; ============================================================
;; MeasureText (core_3d_picking.c)
;; int MeasureText(const char *text, int fontSize)
;; ============================================================

(def-ffi measure-text "MeasureText" (_fun _string _int -> _int))


;; ============================================================
;; GetWorldToScreen (core_world_screen.c)
;; Vector2 GetWorldToScreen(Vector3 position, Camera camera)
;; ============================================================

(define get-world-to-screen
  (let ([f (get-ffi-obj "GetWorldToScreen" T:lib
             (_fun (pos : _vec3-bytes) (cam : _camera3d-bytes) -> (v : _vec2-bytes)))])
    (λ (position camera)
      (vec2-bytes->vec2 (f (vec3->bytes position) (camera3d->bytes camera))))))

(define _bounding-box-bytes
  (_list-struct _float _float _float _float _float _float))

(define (bounding-box->bytes bb)
  (list (ptr-ref bb _float 0) (ptr-ref bb _float 1) (ptr-ref bb _float 2)
        (ptr-ref bb _float 3) (ptr-ref bb _float 4) (ptr-ref bb _float 5)))

(define _ray-collision-bytes
  (_list-struct _bool _float _float _float _float _float _float _float _float _float))

;; ============================================================
;; 导出 — 只导出当前示例需要的
;; ============================================================

(provide
 ;; 宏（供其他模块用）
 def-ffi def-ffi/unwrap

 ;; 传值辅助（供其他模块用）
 _color-bytes color->bytes
 _vec2-bytes vec2->bytes vec2-bytes->vec2
 _rect-bytes rect->bytes rect-bytes->rect
 _camera2d-bytes camera2d->bytes
 _vec3-bytes vec3->bytes vec3-bytes->vec3
 _camera3d-bytes camera3d->bytes
 _ray-bytes ray->bytes
 _bounding-box-bytes bounding-box->bytes
 _ray-collision-bytes

 ;; 窗口
 init-window close-window window-should-close? set-target-fps
 toggle-fullscreen toggle-borderless-windowed
 is-window-state? set-window-state clear-window-state
 minimize-window maximize-window restore-window

 ;; 绘制
 begin-drawing end-drawing
 clear-background draw-text draw-line

 ;; 2D 相机
 begin-mode-2d end-mode-2d

 ;; 3D 相机
 begin-mode-3d end-mode-3d update-camera

 ;; 屏幕信息 / 坐标转换
 get-screen-width get-screen-height
 get-screen-to-world-2d get-world-to-screen-2d
 get-screen-to-world-ray get-world-to-screen measure-text

 ;; 3D 网格 / rlgl 矩阵操作
 draw-grid
 rl-push-matrix rl-pop-matrix rl-translate-f rl-rotate-f

 ;; 随机
 get-random-value

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
 poll-input-events

 ;; 配置
 set-config-flags

 ;; 输入 — 手柄
 is-gamepad-available? get-gamepad-name
 is-gamepad-button-pressed is-gamepad-button-down
 is-gamepad-button-released is-gamepad-button-up
 get-gamepad-button-pressed
 get-gamepad-axis-count get-gamepad-axis-movement
 set-gamepad-mappings set-gamepad-vibration

 ;; 输入 — 触摸
 get-touch-x get-touch-y
 get-touch-point-id get-touch-point-count
 get-touch-position

 ;; 颜色工具
 fade

 ;; 输入 — 手势
 set-gestures-enabled is-gesture-detected? get-gesture-detected
 get-gesture-hold-duration get-gesture-drag-vector get-gesture-drag-angle
 get-gesture-pinch-vector get-gesture-pinch-angle)