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

;; Color 按值比较 — 供用户直接使用，无需自行处理 ptr-ref
(define (color=? a b)
  (and (= (ptr-ref a _ubyte 0) (ptr-ref b _ubyte 0))
       (= (ptr-ref a _ubyte 1) (ptr-ref b _ubyte 1))
       (= (ptr-ref a _ubyte 2) (ptr-ref b _ubyte 2))
       (= (ptr-ref a _ubyte 3) (ptr-ref b _ubyte 3))))

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

(def-ffi set-random-seed "SetRandomSeed" (_fun _uint -> _void))

;; ============================================================
;; 窗口管理 (core_basic_window.c)
;; ============================================================

(def-ffi init-window "InitWindow" (_fun _int _int _string -> _void))
(def-ffi close-window "CloseWindow" (_fun -> _void))
(def-ffi window-should-close? "WindowShouldClose" (_fun -> _stdbool))
(def-ffi set-target-fps "SetTargetFPS" (_fun _int -> _void))

;; ============================================================
;; 窗口状态 / 标志管理 (core_window_flags.c)
;; ============================================================

(def-ffi set-window-min-size "SetWindowMinSize" (_fun _int _int -> _void))
(def-ffi is-window-resized? "IsWindowResized" (_fun -> _stdbool))

;; ============================================================
;; ============================================================
;; 自定义日志回调 (core_custom_logging.c)
;; SetTraceLogCallback(TraceLogCallback callback)
;; TraceLogCallback = void (*)(int logLevel, const char *text, va_list args)
;; ============================================================

(define set-trace-log-callback
  (get-ffi-obj "SetTraceLogCallback" T:lib
    (_fun _pointer -> _void)))

;; C 标准库 vsnprintf — 展开 va_list 到字符串缓冲区
;; int vsnprintf(char *str, size_t size, const char *format, va_list ap);
(define vsnprintf
  (get-ffi-obj "vsnprintf" #f
    (_fun _pointer _int _string _pointer -> _int)))

;; ============================================================
;; 文件系统 (core_directory_files.c, core_drop_files.c)
;; ============================================================

(def-ffi get-working-directory   "GetWorkingDirectory"   (_fun -> _string))
(def-ffi get-prev-directory-path "GetPrevDirectoryPath"  (_fun _string -> _string))
(def-ffi directory-exists?       "DirectoryExists"       (_fun _string -> _stdbool))

;; 显示器/窗口信息 (core_monitor_detector.c)
;; ============================================================

(def-ffi get-monitor-count              "GetMonitorCount"              (_fun -> _int))
(def-ffi get-current-monitor            "GetCurrentMonitor"            (_fun -> _int))
(def-ffi get-monitor-width              "GetMonitorWidth"              (_fun _int -> _int))
(def-ffi get-monitor-height             "GetMonitorHeight"             (_fun _int -> _int))
(def-ffi get-monitor-physical-width     "GetMonitorPhysicalWidth"      (_fun _int -> _int))
(def-ffi get-monitor-physical-height    "GetMonitorPhysicalHeight"     (_fun _int -> _int))
(def-ffi get-monitor-refresh-rate       "GetMonitorRefreshRate"        (_fun _int -> _int))
(def-ffi get-monitor-name               "GetMonitorName"               (_fun _int -> _string))
(def-ffi set-window-monitor             "SetWindowMonitor"             (_fun _int -> _void))

(define get-monitor-position
  (let ([f (get-ffi-obj "GetMonitorPosition" T:lib
             (_fun _int -> (v : _vec2-bytes)))])
    (λ (monitor) (vec2-bytes->vec2 (f monitor)))))

(define get-window-position
  (let ([f (get-ffi-obj "GetWindowPosition" T:lib
             (_fun -> (v : _vec2-bytes)))])
    (λ () (vec2-bytes->vec2 (f)))))


(def-ffi toggle-fullscreen          "ToggleFullscreen"          (_fun -> _void))
(def-ffi toggle-borderless-windowed "ToggleBorderlessWindowed"  (_fun -> _void))
(def-ffi is-window-state?           "IsWindowState"             (_fun _uint -> _stdbool))
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

(def-ffi is-key-pressed        "IsKeyPressed"        (_fun _int -> _stdbool))
(def-ffi is-key-down           "IsKeyDown"           (_fun _int -> _stdbool))
(def-ffi is-key-pressed-repeat "IsKeyPressedRepeat"  (_fun _int -> _stdbool))
(def-ffi is-key-released       "IsKeyReleased"       (_fun _int -> _stdbool))
(def-ffi is-key-up             "IsKeyUp"             (_fun _int -> _stdbool))

(def-ffi get-key-pressed       "GetKeyPressed"       (_fun -> _int))
(def-ffi get-char-pressed      "GetCharPressed"      (_fun -> _int))
(def-ffi get-key-name          "GetKeyName"          (_fun _int -> _string))
(def-ffi set-exit-key          "SetExitKey"          (_fun _int -> _void))

;; ============================================================
;; 输入 — 鼠标 (core_input_mouse.c, core_input_mouse_wheel.c)
;; ============================================================

(def-ffi is-mouse-button-pressed  "IsMouseButtonPressed"  (_fun _int -> _stdbool))
(def-ffi is-mouse-button-down     "IsMouseButtonDown"     (_fun _int -> _stdbool))
(def-ffi is-mouse-button-released "IsMouseButtonReleased" (_fun _int -> _stdbool))
(def-ffi is-mouse-button-up       "IsMouseButtonUp"       (_fun _int -> _stdbool))

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
(def-ffi get-render-width  "GetRenderWidth"  (_fun -> _int))
(def-ffi get-render-height "GetRenderHeight" (_fun -> _int))

(define get-window-scale-dpi
  (let ([f (get-ffi-obj "GetWindowScaleDPI" T:lib
             (_fun -> (v : _vec2-bytes)))])
    (λ () (vec2-bytes->vec2 (f)))))

(define get-mouse-wheel-move-v
  (let ([f (get-ffi-obj "GetMouseWheelMoveV" T:lib
             (_fun -> (v : _vec2-bytes)))])
    (λ () (vec2-bytes->vec2 (f)))))

(def-ffi set-mouse-cursor "SetMouseCursor" (_fun _int -> _void))

;; ============================================================
;; 输入 — cursor 可见性 (core_input_mouse.c)
;; ============================================================

(def-ffi is-cursor-hidden?  "IsCursorHidden"  (_fun -> _stdbool))
(def-ffi show-cursor        "ShowCursor"      (_fun -> _void))
(def-ffi hide-cursor        "HideCursor"      (_fun -> _void))
(def-ffi enable-cursor      "EnableCursor"    (_fun -> _void))
(def-ffi disable-cursor     "DisableCursor"   (_fun -> _void))
(def-ffi is-cursor-on-screen? "IsCursorOnScreen" (_fun -> _stdbool))

;; ============================================================
;; 输入 — 事件轮询
;; ============================================================

(def-ffi poll-input-events "PollInputEvents" (_fun -> _void))

;; ============================================================
;; 配置 (core_input_gamepad.c)
;; ============================================================

(def-ffi set-config-flags "SetConfigFlags" (_fun _uint -> _void))

;; ============================================================
;; Scissor test (core_scissor_test.c)
;; ============================================================

(def-ffi begin-scissor-mode "BeginScissorMode" (_fun _int _int _int _int -> _void))
(def-ffi end-scissor-mode "EndScissorMode" (_fun -> _void))

;; ============================================================
;; 帧控制 / 时间 (core_custom_frame_control.c)
;; ============================================================

(def-ffi get-time "GetTime" (_fun -> _double))
(def-ffi swap-screen-buffer "SwapScreenBuffer" (_fun -> _void))
(def-ffi wait-time "WaitTime" (_fun _double -> _void))

;; ============================================================
;; 随机序列 (core_random_sequence.c)
;;   LoadRandomSequence(count, min, max) → int*   (必须手动 Unload)
;;   UnloadRandomSequence(sequence) → void
;; 包装: load-random-sequence 自动读取并释放, 返回 Racket 整数列表
;; ============================================================

(define _load-random-sequence-ffi
  (get-ffi-obj "LoadRandomSequence" T:lib
    (_fun _uint _int _int -> _pointer)))

(define _unload-random-sequence-ffi
  (get-ffi-obj "UnloadRandomSequence" T:lib
    (_fun _pointer -> _void)))

(define (load-random-sequence count min max)
  (let* ([ptr (_load-random-sequence-ffi count min max)]
         [result (for/list ([i (in-range count)])
                   (ptr-ref ptr _int i))])
    (_unload-random-sequence-ffi ptr)
    result))

;; ============================================================
;; 输入 — 手柄 / gamepad (core_input_gamepad.c)
;; ============================================================

(def-ffi is-gamepad-available?    "IsGamepadAvailable"    (_fun _int -> _stdbool))
(def-ffi get-gamepad-name         "GetGamepadName"        (_fun _int -> _string))
(def-ffi is-gamepad-button-pressed "IsGamepadButtonPressed" (_fun _int _int -> _stdbool))
(def-ffi is-gamepad-button-down   "IsGamepadButtonDown"   (_fun _int _int -> _stdbool))
(def-ffi is-gamepad-button-released "IsGamepadButtonReleased" (_fun _int _int -> _stdbool))
(def-ffi is-gamepad-button-up     "IsGamepadButtonUp"     (_fun _int _int -> _stdbool))
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
(def-ffi is-gesture-detected?    "IsGestureDetected"     (_fun _uint -> _stdbool))
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
  (_list-struct _stdbool _float _float _float _float _float _float _float _float _float))

;; ============================================================
;; 拖放文件 (core_drop_files.c)
;;   FilePathList = { unsigned int count; char **paths; }
;;   IsFileDropped(void) -> stdbool
;;   LoadDroppedFiles(void) -> FilePathList (by value)
;;   UnloadDroppedFiles(FilePathList files) -> void (by value)
;; ============================================================

;; FilePathList 传值类型: count (uint) + paths (char**, pointer)
(define _filepathlist-bytes
  (_list-struct _uint _pointer))

(def-ffi is-file-dropped "IsFileDropped" (_fun -> _stdbool))

;; load-dropped-files: 内部自动调用 UnloadDroppedFiles
;; 返回干净的 Racket 字符串列表（无需手动释放 C 内存）
(define load-dropped-files
  (let ([load-ffi (get-ffi-obj "LoadDroppedFiles" T:lib
                    (_fun -> (lst : _filepathlist-bytes)))]
        [unload-ffi (get-ffi-obj "UnloadDroppedFiles" T:lib
                      (_fun (lst : _filepathlist-bytes) -> _void))]
        [tmp (malloc _pointer 'atomic)])  ;; char* -> Racket string temp buffer
    (lambda ()
      (let* ([raw (load-ffi)]
             [count (car raw)]
             [paths-ptr (cadr raw)]
             ;; iterate paths array, convert each char* -> Racket string
             [paths
              (for/list ([i (in-range count)])
                (let ([cstr (ptr-ref paths-ptr _pointer i)])
                  (if cstr
                      ;; store char* in tmp, read as _string -> Racket string
                      (begin
                        (ptr-set! tmp _pointer 0 cstr)
                        (ptr-ref tmp _string))
                      "")))])
        (unload-ffi raw)   ;; free C memory immediately
        paths))))          ;; return clean Racket string list

;; ============================================================
;; LoadDirectoryFilesEx (core_directory_files.c)
;; FilePathList LoadDirectoryFilesEx(const char *basePath, const char *filter, bool scanSubdirs)
;; 自动释放 C 内存，返回 Racket 字符串列表
;; ============================================================

(define load-directory-files-ex
  (let ([load-ffi (get-ffi-obj "LoadDirectoryFilesEx" T:lib
                    (_fun _string _string _stdbool -> (lst : _filepathlist-bytes)))]
        [unload-ffi (get-ffi-obj "UnloadDirectoryFiles" T:lib
                      (_fun (lst : _filepathlist-bytes) -> _void))]
        [tmp (malloc _pointer 'atomic)])
    (lambda (base-path filter scan-subdirs?)
      (let* ([raw (load-ffi base-path filter scan-subdirs?)]
             [count (car raw)]
             [paths-ptr (cadr raw)]
             [paths
              (for/list ([i (in-range count)])
                (let ([cstr (ptr-ref paths-ptr _pointer i)])
                  (if cstr
                      (begin
                        (ptr-set! tmp _pointer 0 cstr)
                        (ptr-ref tmp _string))
                      "")))])
        (unload-ffi raw)
        paths))))

;; ============================================================
;; Shader 模块 — 着色器加载与绘制
;;   Shader = { unsigned int id; int *locs; }
;; ============================================================

;; Shader 传值类型: id (_uint) + locs (_pointer)
(define _shader-bytes
  (_list-struct _uint _pointer))

(define load-shader
  (let ([f (get-ffi-obj "LoadShader" T:lib
             (_fun _string _string -> (s : _shader-bytes)))])
    (lambda (vs-filename fs-filename) (f vs-filename fs-filename))))

(define unload-shader
  (let ([f (get-ffi-obj "UnloadShader" T:lib
             (_fun (s : _shader-bytes) -> _void))])
    (lambda (shader) (f shader))))

(define get-shader-location
  (let ([f (get-ffi-obj "GetShaderLocation" T:lib
             (_fun (s : _shader-bytes) _string -> _int))])
    (lambda (shader uniform-name) (f shader uniform-name))))

;; SetShaderValue(Shader shader, int locIndex, const void *value, int uniformType)
;; value 是 void*，需由调用方提供正确类型的数据指针
(define set-shader-value
  (let ([f (get-ffi-obj "SetShaderValue" T:lib
             (_fun (s : _shader-bytes) _int _pointer _int -> _void))])
    (lambda (shader loc-index value uniform-type)
      (f shader loc-index value uniform-type))))

(define begin-shader-mode
  (let ([f (get-ffi-obj "BeginShaderMode" T:lib
             (_fun (s : _shader-bytes) -> _void))])
    (lambda (shader) (f shader))))

(define end-shader-mode
  (get-ffi-obj "EndShaderMode" T:lib (_fun -> _void)))

;; ============================================================
;; VR 立体渲染 — 模拟器支持
;;   VrDeviceInfo   = { int hRes, vRes; float hScreen, vScreen, ... }
;;   VrStereoConfig = { Matrix projection[2], viewOffset[2], ... }
;; ============================================================


;; 辅助: 构造 float[*] 指针（用于 SetShaderValue 的 void* 参数）
(define (malloc-float-vec2 x y)
  (let ([buf (malloc _float 2 'atomic)])
    (ptr-set! buf _float 0 x)
    (ptr-set! buf _float 1 y)
    buf))

(define (malloc-float-vec4 a b c d)
  (let ([buf (malloc _float 4 'atomic)])
    (ptr-set! buf _float 0 a)
    (ptr-set! buf _float 1 b)
    (ptr-set! buf _float 2 c)
    (ptr-set! buf _float 3 d)
    buf))
;; VrDeviceInfo 传值类型: 15 字段 = 60 字节
;;   int hResolution, vResolution
;;   float hScreenSize, vScreenSize, eyeToScreenDistance,
;;         lensSeparationDistance, interpupillaryDistance
;;   float lensDistortionValues[4], chromaAbCorrection[4]
(define _vrdeviceinfo-bytes
  (_list-struct _int _int
               _float _float _float _float _float
               _float _float _float _float
               _float _float _float _float))

;; VrStereoConfig 传值类型: 76 字段 = 304 字节
;;   2x Matrix (每 Matrix 16 floats) + 6x float[2]
(define _vrstereoconfig-bytes
  (_list-struct
   ;; projection[0]: 16 floats
   _float _float _float _float _float _float _float _float
   _float _float _float _float _float _float _float _float
   ;; projection[1]: 16 floats
   _float _float _float _float _float _float _float _float
   _float _float _float _float _float _float _float _float
   ;; viewOffset[0]: 16 floats
   _float _float _float _float _float _float _float _float
   _float _float _float _float _float _float _float _float
   ;; viewOffset[1]: 16 floats
   _float _float _float _float _float _float _float _float
   _float _float _float _float _float _float _float _float
   ;; leftLensCenter[2], rightLensCenter[2]
   _float _float _float _float
   ;; leftScreenCenter[2], rightScreenCenter[2]
   _float _float _float _float
   ;; scale[2], scaleIn[2]
   _float _float _float _float))

(define load-vr-stereo-config
  (let ([f (get-ffi-obj "LoadVrStereoConfig" T:lib
             (_fun (dev : _vrdeviceinfo-bytes) -> (cfg : _vrstereoconfig-bytes)))])
    (lambda (device) (f device))))

(define unload-vr-stereo-config
  (let ([f (get-ffi-obj "UnloadVrStereoConfig" T:lib
             (_fun (cfg : _vrstereoconfig-bytes) -> _void))])
    (lambda (config) (f config))))

(define begin-vr-stereo-mode
  (let ([f (get-ffi-obj "BeginVrStereoMode" T:lib
             (_fun (cfg : _vrstereoconfig-bytes) -> _void))])
    (lambda (config) (f config))))

(define end-vr-stereo-mode
  (get-ffi-obj "EndVrStereoMode" T:lib (_fun -> _void)))

;; ============================================================
;; AutomationEvent 传值类型 + 回放 FFI
;;   C: PlayAutomationEvent(AutomationEvent event) → void
;;   传值调用，24 字节压栈，无指针问题
;; ============================================================

(define _automation-event-bytes
  (_list-struct _uint _uint _int _int _int _int))

;; play-automation-event: 原始 FFI，接受 (list frame type p0 p1 p2 p3)
;; raylib-racket/automation.rkt 中有对应的 struct 包装版本
(define play-automation-event
  (get-ffi-obj "PlayAutomationEvent" T:lib
    (_fun (evt : _automation-event-bytes) -> _void)))
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
  _vrstereoconfig-bytes
  _automation-event-bytes
 _camera2d-bytes camera2d->bytes
 _vec3-bytes vec3->bytes vec3-bytes->vec3
 _camera3d-bytes camera3d->bytes
 _ray-bytes ray->bytes
 _bounding-box-bytes bounding-box->bytes
 _ray-collision-bytes
 _filepathlist-bytes
 _shader-bytes
 _vrdeviceinfo-bytes
 _vrstereoconfig-bytes

 ;; 窗口
 init-window close-window window-should-close? set-target-fps
 toggle-fullscreen toggle-borderless-windowed
 is-window-state? set-window-state clear-window-state
 minimize-window maximize-window restore-window set-window-min-size
 is-window-resized?
 get-monitor-count get-current-monitor get-monitor-position get-monitor-name
 get-monitor-width get-monitor-height
 get-monitor-physical-width get-monitor-physical-height
 get-monitor-refresh-rate set-window-monitor get-window-position
 set-trace-log-callback vsnprintf



 ;; 绘制
 begin-drawing end-drawing
 clear-background draw-text draw-line

 ;; 2D 相机
 begin-mode-2d end-mode-2d

 ;; 3D 相机
 begin-mode-3d end-mode-3d update-camera

 ;; 屏幕信息 / 坐标转换
 get-screen-width get-screen-height
 get-render-width get-render-height get-window-scale-dpi
 get-screen-to-world-2d get-world-to-screen-2d
 get-screen-to-world-ray get-world-to-screen measure-text

 ;; 3D 网格 / rlgl 矩阵操作
 draw-grid
 rl-push-matrix rl-pop-matrix rl-translate-f rl-rotate-f

 ;; 随机
 get-random-value set-random-seed

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

 ;; 输入 — 拖放文件
 is-file-dropped load-dropped-files

 ;; 文件系统
 get-working-directory get-prev-directory-path directory-exists?
 load-directory-files-ex

 ;; 着色器
 load-shader unload-shader
 get-shader-location set-shader-value
 begin-shader-mode end-shader-mode

 ;; VR 立体渲染
 malloc-float-vec2 malloc-float-vec4
 load-vr-stereo-config unload-vr-stereo-config
 begin-vr-stereo-mode end-vr-stereo-mode

 ;; 配置
 set-config-flags

 ;; Scissor mode
 begin-scissor-mode end-scissor-mode

 ;; 帧控制 / 时间
 get-time swap-screen-buffer wait-time

 ;; 随机序列
 load-random-sequence

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
 fade color=?

 ;; 输入 — 手势
 set-gestures-enabled is-gesture-detected? get-gesture-detected
 get-gesture-hold-duration get-gesture-drag-vector get-gesture-drag-angle
 get-gesture-pinch-vector get-gesture-pinch-angle

)