#lang racket/base

;; core/rcore.rkt — 核心模块函数绑定 (rcore.h)
;; 分类: 窗口/输入/相机/计时/屏幕/文件/着色器/颜色/加密/VR

(require ffi/unsafe
         "ffi-helpers.rkt"
         "types/image.rkt"
         "types/ray.rkt"
         "types/shader.rkt")

;; ═══════════════════════════════════════════════════════════
;; 1. 窗口管理
;; ═══════════════════════════════════════════════════════════

(def-ffi init-window        "InitWindow"        (_fun _int _int _string -> _void))
(def-ffi close-window       "CloseWindow"       (_fun -> _void))
(def-ffi window-should-close? "WindowShouldClose" (_fun -> _stdbool))
(def-ffi is-window-ready?   "IsWindowReady"     (_fun -> _stdbool))
(def-ffi is-window-fullscreen?  "IsWindowFullscreen"  (_fun -> _stdbool))
(def-ffi is-window-hidden?      "IsWindowHidden"      (_fun -> _stdbool))
(def-ffi is-window-minimized?   "IsWindowMinimized"   (_fun -> _stdbool))
(def-ffi is-window-maximized?   "IsWindowMaximized"   (_fun -> _stdbool))
(def-ffi is-window-focused?     "IsWindowFocused"     (_fun -> _stdbool))
(def-ffi is-window-resized?     "IsWindowResized"     (_fun -> _stdbool))
(def-ffi is-window-state?       "IsWindowState"       (_fun _uint -> _stdbool))
(def-ffi set-window-title    "SetWindowTitle"    (_fun _string -> _void))
(def-ffi set-window-position "SetWindowPosition" (_fun _int _int -> _void))
(def-ffi set-window-size     "SetWindowSize"     (_fun _int _int -> _void))
(def-ffi set-window-min-size "SetWindowMinSize"  (_fun _int _int -> _void))
(def-ffi set-window-max-size "SetWindowMaxSize"  (_fun _int _int -> _void))
(def-ffi set-window-opacity  "SetWindowOpacity"  (_fun _float -> _void))
(def-ffi set-window-focused  "SetWindowFocused"  (_fun -> _void))
(def-ffi get-window-handle   "GetWindowHandle"   (_fun -> _pointer))
(def-ffi set-window-state    "SetWindowState"    (_fun _uint -> _void))
(def-ffi clear-window-state  "ClearWindowState"  (_fun _uint -> _void))
(def-ffi toggle-fullscreen   "ToggleFullscreen"  (_fun -> _void))
(def-ffi toggle-borderless-windowed "ToggleBorderlessWindowed" (_fun -> _void))
(def-ffi minimize-window "MinimizeWindow" (_fun -> _void))
(def-ffi maximize-window "MaximizeWindow" (_fun -> _void))
(def-ffi restore-window  "RestoreWindow"  (_fun -> _void))

(define get-window-position
  (let ([f (get-ffi-obj "GetWindowPosition" lib (_fun -> (v : _vec2-bytes)))])
    (λ () (bytes->vec2 (f)))))

(define set-window-icon
  (let ([f (get-ffi-obj "SetWindowIcon" lib (_fun (img : _image-bytes) -> _void))])
    (lambda (image) (f image))))

(def-ffi set-window-icons "SetWindowIcons" (_fun _pointer _int -> _void))

;; ═══════════════════════════════════════════════════════════
;; 2. 显示器
;; ═══════════════════════════════════════════════════════════

(def-ffi get-monitor-count    "GetMonitorCount"    (_fun -> _int))
(def-ffi get-current-monitor  "GetCurrentMonitor"  (_fun -> _int))
(def-ffi get-monitor-width    "GetMonitorWidth"    (_fun _int -> _int))
(def-ffi get-monitor-height   "GetMonitorHeight"   (_fun _int -> _int))
(def-ffi get-monitor-physical-width  "GetMonitorPhysicalWidth"  (_fun _int -> _int))
(def-ffi get-monitor-physical-height "GetMonitorPhysicalHeight" (_fun _int -> _int))
(def-ffi get-monitor-refresh-rate "GetMonitorRefreshRate" (_fun _int -> _int))
(def-ffi get-monitor-name     "GetMonitorName"     (_fun _int -> _string))
(def-ffi set-window-monitor   "SetWindowMonitor"   (_fun _int -> _void))

(define get-monitor-position
  (let ([f (get-ffi-obj "GetMonitorPosition" lib (_fun _int -> (v : _vec2-bytes)))])
    (λ (monitor) (bytes->vec2 (f monitor)))))

;; ═══════════════════════════════════════════════════════════
;; 3. 绘制上下文
;; ═══════════════════════════════════════════════════════════

(def-ffi begin-drawing  "BeginDrawing"  (_fun -> _void))
(def-ffi end-drawing    "EndDrawing"    (_fun -> _void))
(def-ffi begin-blend-mode "BeginBlendMode" (_fun _int -> _void))
(def-ffi end-blend-mode   "EndBlendMode"   (_fun -> _void))
(def-ffi begin-scissor-mode "BeginScissorMode" (_fun _int _int _int _int -> _void))
(def-ffi end-scissor-mode   "EndScissorMode"   (_fun -> _void))
(def-ffi set-config-flags   "SetConfigFlags"   (_fun _uint -> _void))

(define clear-background
  (let ([f (get-ffi-obj "ClearBackground" lib
                        (_fun (c : _color-bytes) -> _void))])
    (λ (c) (f (color->bytes c)))))

(define draw-text
  (let ([f (get-ffi-obj "DrawText" lib
                        (_fun _string _int _int _int (c : _color-bytes) -> _void))])
    (λ (text x y fs c) (f text x y fs (color->bytes c)))))

(define draw-line
  (let ([f (get-ffi-obj "DrawLine" lib
                        (_fun _int _int _int _int (c : _color-bytes) -> _void))])
    (λ (sx sy ex ey c) (f sx sy ex ey (color->bytes c)))))

;; ═══════════════════════════════════════════════════════════
;; 4. 相机
;; ═══════════════════════════════════════════════════════════

(define begin-mode-2d
  (let ([f (get-ffi-obj "BeginMode2D" lib
                        (_fun (c : _camera2d-bytes) -> _void))])
    (λ (c) (f (camera2d->bytes c)))))

(def-ffi end-mode-2d "EndMode2D" (_fun -> _void))

(define begin-mode-3d
  (let ([f (get-ffi-obj "BeginMode3D" lib
                        (_fun (c : _camera3d-bytes) -> _void))])
    (λ (c) (f (camera3d->bytes c)))))

(def-ffi end-mode-3d "EndMode3D" (_fun -> _void))
(def-ffi update-camera "UpdateCamera" (_fun _pointer _int -> _void))

(define update-camera-pro
  (let ([f (get-ffi-obj "UpdateCameraPro" lib
                        (_fun _pointer (mov : _vec3-bytes) (rot : _vec3-bytes)
                              _float -> _void))])
    (lambda (camera movement rotation zoom)
      (f camera (vec3->bytes movement) (vec3->bytes rotation) zoom))))

(define get-camera-matrix
  (let ([f (get-ffi-obj "GetCameraMatrix" lib
                        (_fun (c : _camera3d-bytes) -> (m : _matrix-bytes)))])
    (λ (camera) (f (camera3d->bytes camera)))))

(define get-camera-matrix-2d
  (let ([f (get-ffi-obj "GetCameraMatrix2D" lib
                        (_fun (cam : _camera2d-bytes) -> (m : _matrix-bytes)))])
    (lambda (camera) (f (camera2d->bytes camera)))))

;; ═══════════════════════════════════════════════════════════
;; 5. 屏幕/坐标转换
;; ═══════════════════════════════════════════════════════════

(def-ffi get-screen-width   "GetScreenWidth"   (_fun -> _int))
(def-ffi get-screen-height  "GetScreenHeight"  (_fun -> _int))
(def-ffi get-render-width   "GetRenderWidth"   (_fun -> _int))
(def-ffi get-render-height  "GetRenderHeight"  (_fun -> _int))
(def-ffi draw-grid          "DrawGrid"         (_fun _int _float -> _void))

(define get-window-scale-dpi
  (let ([f (get-ffi-obj "GetWindowScaleDPI" lib
                        (_fun -> (v : _vec2-bytes)))])
    (λ () (bytes->vec2 (f)))))

(define get-screen-to-world-2d
  (let ([f (get-ffi-obj "GetScreenToWorld2D" lib
                        (_fun (pos : _vec2-bytes) (cam : _camera2d-bytes)
                              -> (v : _vec2-bytes)))])
    (λ (p c) (bytes->vec2 (f (vec2->bytes p) (camera2d->bytes c))))))

(define get-world-to-screen-2d
  (let ([f (get-ffi-obj "GetWorldToScreen2D" lib
                        (_fun (pos : _vec2-bytes) (cam : _camera2d-bytes)
                              -> (v : _vec2-bytes)))])
    (λ (p c) (bytes->vec2 (f (vec2->bytes p) (camera2d->bytes c))))))

(define get-screen-to-world-ray
  (let ([f (get-ffi-obj "GetScreenToWorldRay" lib
                        (_fun (pos : _vec2-bytes) (cam : _camera3d-bytes)
                              -> (r : _ray-bytes)))])
    (λ (position camera)
      (let ([lst (f (vec2->bytes position) (camera3d->bytes camera))])
        (let ([r (malloc _Ray 'atomic)])
          (ptr-set! r _float 0 (car lst)) (ptr-set! r _float 1 (cadr lst))
          (ptr-set! r _float 2 (caddr lst)) (ptr-set! r _float 3 (cadddr lst))
          (ptr-set! r _float 4 (car (cddddr lst)))
          (ptr-set! r _float 5 (cadr (cddddr lst)))
          r)))))

(define get-world-to-screen
  (let ([f (get-ffi-obj "GetWorldToScreen" lib
                        (_fun (pos : _vec3-bytes) (cam : _camera3d-bytes)
                              -> (v : _vec2-bytes)))])
    (λ (p c) (bytes->vec2 (f (vec3->bytes p) (camera3d->bytes c))))))

(define get-world-to-screen-ex
  (let ([f (get-ffi-obj "GetWorldToScreenEx" lib
                        (_fun (pos : _vec3-bytes) (cam : _camera3d-bytes) _int _int
                              -> (v : _vec2-bytes)))])
    (λ (p c w h) (bytes->vec2 (f (vec3->bytes p) (camera3d->bytes c) w h)))))

(define get-screen-to-world-ray-ex
  (let ([f (get-ffi-obj "GetScreenToWorldRayEx" lib
                        (_fun (pos : _vec2-bytes) (cam : _camera3d-bytes) _int _int
                              -> (r : _ray-bytes)))])
    (lambda (position camera width height)
      (let ([lst (f (vec2->bytes position) (camera3d->bytes camera) width height)])
        (let ([r (malloc _Ray 'atomic)])
          (ptr-set! r _float 0 (car lst)) (ptr-set! r _float 1 (cadr lst))
          (ptr-set! r _float 2 (caddr lst)) (ptr-set! r _float 3 (cadddr lst))
          (ptr-set! r _float 4 (car (cddddr lst)))
          (ptr-set! r _float 5 (cadr (cddddr lst)))
          r)))))

;; ═══════════════════════════════════════════════════════════
;; 6. 计时
;; ═══════════════════════════════════════════════════════════

(def-ffi set-target-fps "SetTargetFPS" (_fun _int -> _void))
(def-ffi get-frame-time "GetFrameTime" (_fun -> _float))
(def-ffi get-fps        "GetFPS"        (_fun -> _int))
(def-ffi get-time       "GetTime"       (_fun -> _double))
(def-ffi draw-fps       "DrawFPS"       (_fun _int _int -> _void))
(def-ffi swap-screen-buffer "SwapScreenBuffer" (_fun -> _void))
(def-ffi wait-time      "WaitTime"      (_fun _double -> _void))

;; ═══════════════════════════════════════════════════════════
;; 7. 键盘
;; ═══════════════════════════════════════════════════════════

(def-ffi is-key-pressed        "IsKeyPressed"        (_fun _int -> _stdbool))
(def-ffi is-key-down           "IsKeyDown"           (_fun _int -> _stdbool))
(def-ffi is-key-pressed-repeat "IsKeyPressedRepeat"  (_fun _int -> _stdbool))
(def-ffi is-key-released       "IsKeyReleased"       (_fun _int -> _stdbool))
(def-ffi is-key-up             "IsKeyUp"             (_fun _int -> _stdbool))
(def-ffi get-key-pressed       "GetKeyPressed"       (_fun -> _int))
(def-ffi get-char-pressed      "GetCharPressed"      (_fun -> _int))
(def-ffi get-key-name          "GetKeyName"          (_fun _int -> _string))
(def-ffi set-exit-key          "SetExitKey"          (_fun _int -> _void))

;; ═══════════════════════════════════════════════════════════
;; 8. 鼠标
;; ═══════════════════════════════════════════════════════════

(def-ffi is-mouse-button-pressed  "IsMouseButtonPressed"  (_fun _int -> _stdbool))
(def-ffi is-mouse-button-down     "IsMouseButtonDown"     (_fun _int -> _stdbool))
(def-ffi is-mouse-button-released "IsMouseButtonReleased" (_fun _int -> _stdbool))
(def-ffi is-mouse-button-up       "IsMouseButtonUp"       (_fun _int -> _stdbool))
(def-ffi get-mouse-x       "GetMouseX"       (_fun -> _int))
(def-ffi get-mouse-y       "GetMouseY"       (_fun -> _int))
(def-ffi get-mouse-wheel-move "GetMouseWheelMove" (_fun -> _float))
(def-ffi set-mouse-position "SetMousePosition" (_fun _int _int -> _void))
(def-ffi set-mouse-offset   "SetMouseOffset"   (_fun _int _int -> _void))
(def-ffi set-mouse-scale    "SetMouseScale"    (_fun _float _float -> _void))
(def-ffi set-mouse-cursor   "SetMouseCursor"   (_fun _int -> _void))
(def-ffi is-cursor-hidden?    "IsCursorHidden"    (_fun -> _stdbool))
(def-ffi is-cursor-on-screen? "IsCursorOnScreen" (_fun -> _stdbool))
(def-ffi show-cursor    "ShowCursor"    (_fun -> _void))
(def-ffi hide-cursor    "HideCursor"    (_fun -> _void))
(def-ffi enable-cursor  "EnableCursor"  (_fun -> _void))
(def-ffi disable-cursor "DisableCursor" (_fun -> _void))

(define get-mouse-position
  (let ([f (get-ffi-obj "GetMousePosition" lib (_fun -> (v : _vec2-bytes)))])
    (λ () (bytes->vec2 (f)))))

(define get-mouse-delta
  (let ([f (get-ffi-obj "GetMouseDelta" lib (_fun -> (v : _vec2-bytes)))])
    (λ () (bytes->vec2 (f)))))

(define get-mouse-wheel-move-v
  (let ([f (get-ffi-obj "GetMouseWheelMoveV" lib (_fun -> (v : _vec2-bytes)))])
    (λ () (bytes->vec2 (f)))))

;; ═══════════════════════════════════════════════════════════
;; 9. 手柄
;; ═══════════════════════════════════════════════════════════

(def-ffi is-gamepad-available?      "IsGamepadAvailable"      (_fun _int -> _stdbool))
(def-ffi get-gamepad-name           "GetGamepadName"          (_fun _int -> _string))
(def-ffi is-gamepad-button-pressed  "IsGamepadButtonPressed"  (_fun _int _int -> _stdbool))
(def-ffi is-gamepad-button-down     "IsGamepadButtonDown"     (_fun _int _int -> _stdbool))
(def-ffi is-gamepad-button-released "IsGamepadButtonReleased" (_fun _int _int -> _stdbool))
(def-ffi is-gamepad-button-up       "IsGamepadButtonUp"       (_fun _int _int -> _stdbool))
(def-ffi get-gamepad-button-pressed "GetGamepadButtonPressed" (_fun -> _int))
(def-ffi get-gamepad-axis-count     "GetGamepadAxisCount"     (_fun _int -> _int))
(def-ffi get-gamepad-axis-movement  "GetGamepadAxisMovement"  (_fun _int _int -> _float))
(def-ffi set-gamepad-mappings       "SetGamepadMappings"      (_fun _string -> _int))
(def-ffi set-gamepad-vibration      "SetGamepadVibration"
         (_fun _int _float _float _float -> _void))

;; ═══════════════════════════════════════════════════════════
;; 10. 触摸 / 手势 / 事件
;; ═══════════════════════════════════════════════════════════

(def-ffi get-touch-x          "GetTouchX"          (_fun -> _int))
(def-ffi get-touch-y          "GetTouchY"          (_fun -> _int))
(def-ffi get-touch-point-id   "GetTouchPointId"    (_fun _int -> _int))
(def-ffi get-touch-point-count "GetTouchPointCount" (_fun -> _int))

(define get-touch-position
  (let ([f (get-ffi-obj "GetTouchPosition" lib
                        (_fun _int -> (v : _vec2-bytes)))])
    (λ (index) (bytes->vec2 (f index)))))

(def-ffi set-gestures-enabled     "SetGesturesEnabled"     (_fun _uint -> _void))
(def-ffi is-gesture-detected?     "IsGestureDetected"      (_fun _uint -> _stdbool))
(def-ffi get-gesture-detected     "GetGestureDetected"     (_fun -> _int))
(def-ffi get-gesture-hold-duration "GetGestureHoldDuration" (_fun -> _float))
(def-ffi get-gesture-drag-angle   "GetGestureDragAngle"    (_fun -> _float))
(def-ffi get-gesture-pinch-angle  "GetGesturePinchAngle"   (_fun -> _float))

(define get-gesture-drag-vector
  (let ([f (get-ffi-obj "GetGestureDragVector" lib
                        (_fun -> (v : _vec2-bytes)))])
    (λ () (bytes->vec2 (f)))))

(define get-gesture-pinch-vector
  (let ([f (get-ffi-obj "GetGesturePinchVector" lib
                        (_fun -> (v : _vec2-bytes)))])
    (λ () (bytes->vec2 (f)))))

(def-ffi poll-input-events    "PollInputEvents"    (_fun -> _void))
(def-ffi enable-event-waiting  "EnableEventWaiting"  (_fun -> _void))
(def-ffi disable-event-waiting "DisableEventWaiting" (_fun -> _void))

;; ═══════════════════════════════════════════════════════════
;; 11. 剪贴板 / 文件系统
;; ═══════════════════════════════════════════════════════════

(def-ffi set-clipboard-text "SetClipboardText" (_fun _string -> _void))
(def-ffi get-clipboard-text "GetClipboardText" (_fun -> _string))

(define get-clipboard-image
  (let ([f (get-ffi-obj "GetClipboardImage" lib
                        (_fun -> (img : _image-bytes)))])
    (lambda () (f))))

(def-ffi file-exists?         "FileExists"         (_fun _string -> _stdbool))
(def-ffi directory-exists?    "DirectoryExists"    (_fun _string -> _stdbool))
(def-ffi is-file-extension    "IsFileExtension"    (_fun _string _string -> _stdbool))
(def-ffi is-file-name-valid   "IsFileNameValid"    (_fun _string -> _stdbool))
(def-ffi is-path-file?        "IsPathFile"         (_fun _string -> _stdbool))
(def-ffi get-file-length      "GetFileLength"      (_fun _string -> _int))
(def-ffi get-file-mod-time    "GetFileModTime"     (_fun _string -> _long))
(def-ffi get-file-extension   "GetFileExtension"   (_fun _string -> _string))
(def-ffi get-file-name        "GetFileName"        (_fun _string -> _string))
(def-ffi get-file-name-without-ext "GetFileNameWithoutExt" (_fun _string -> _string))
(def-ffi get-directory-path   "GetDirectoryPath"   (_fun _string -> _string))
(def-ffi get-working-directory "GetWorkingDirectory" (_fun -> _string))
(def-ffi get-prev-directory-path "GetPrevDirectoryPath" (_fun _string -> _string))
(def-ffi get-application-directory "GetApplicationDirectory" (_fun -> _string))
(def-ffi make-directory       "MakeDirectory"       (_fun _string -> _int))
(def-ffi change-directory     "ChangeDirectory"     (_fun _string -> _stdbool))
(def-ffi file-rename "FileRename" (_fun _string _string -> _int))
(def-ffi file-remove "FileRemove" (_fun _string -> _int))
(def-ffi file-copy   "FileCopy"   (_fun _string _string -> _int))
(def-ffi file-move   "FileMove"   (_fun _string _string -> _int))
(def-ffi file-text-replace  "FileTextReplace"  (_fun _string _string _string -> _int))
(def-ffi file-text-find-index "FileTextFindIndex" (_fun _string _string -> _int))
(def-ffi get-directory-file-count    "GetDirectoryFileCount"    (_fun _string -> _uint))
(def-ffi get-directory-file-count-ex "GetDirectoryFileCountEx"
         (_fun _string _string _stdbool -> _uint))
(def-ffi save-file-text "SaveFileText" (_fun _string _string -> _stdbool))
(def-ffi unload-file-data "UnloadFileData" (_fun _pointer -> _void))
(def-ffi is-file-dropped "IsFileDropped" (_fun -> _stdbool))

(define set-load-file-data-callback
  (get-ffi-obj "SetLoadFileDataCallback" lib (_fun _pointer -> _void)))
(define set-save-file-data-callback
  (get-ffi-obj "SetSaveFileDataCallback" lib (_fun _pointer -> _void)))
(define set-load-file-text-callback
  (get-ffi-obj "SetLoadFileTextCallback" lib (_fun _pointer -> _void)))
(define set-save-file-text-callback
  (get-ffi-obj "SetSaveFileTextCallback" lib (_fun _pointer -> _void)))

(define load-file-data
  (let ([f (get-ffi-obj "LoadFileData" lib (_fun _string _pointer -> _pointer))])
    (lambda (filename)
      (let ([size-buf (malloc _int 1 'atomic)])
        (let ([ptr (f filename size-buf)])
          (if ptr (values ptr (ptr-ref size-buf _int 0)) (values #f 0)))))))

(define save-file-data
  (let ([f (get-ffi-obj "SaveFileData" lib
                        (_fun _string _pointer _int -> _stdbool))])
    (lambda (filename data-ptr data-size) (f filename data-ptr data-size))))

(define export-data-as-code
  (let ([f (get-ffi-obj "ExportDataAsCode" lib
                        (_fun _pointer _int _string -> _stdbool))])
    (lambda (data-ptr data-size filename) (f data-ptr data-size filename))))

(define %load-file-text-raw
  (get-ffi-obj "LoadFileText" lib (_fun _string -> _pointer)))

(define (load-file-text filename)
  (let* ([tmp (malloc _pointer 1 'atomic)]
         [cstr (%load-file-text-raw filename)]
         [unload (get-ffi-obj "UnloadFileText" lib (_fun _pointer -> _void))])
    (if (not cstr) #f
        (begin (ptr-set! tmp _pointer 0 cstr)
               (let ([r (ptr-ref tmp _string)]) (unload cstr) r)))))

(define (filepathlist->string-list raw)
  (let* ([count (car raw)] [paths-ptr (cadr raw)]
         [tmp (malloc _pointer 'atomic)]
         [paths (for/list ([i (in-range count)])
                  (let ([cstr (ptr-ref paths-ptr _pointer i)])
                    (if cstr (begin (ptr-set! tmp _pointer 0 cstr) (ptr-ref tmp _string)) "")))])
    paths))

(define load-directory-files
  (let ([lf (get-ffi-obj "LoadDirectoryFiles" lib
                         (_fun _string -> (lst : _file-path-list-bytes)))]
        [uf (get-ffi-obj "UnloadDirectoryFiles" lib
                         (_fun (lst : _file-path-list-bytes) -> _void))])
    (lambda (dir-path)
      (let* ([raw (lf dir-path)] [paths (filepathlist->string-list raw)])
        (uf raw) paths))))

(define load-directory-files-ex
  (let ([lf (get-ffi-obj "LoadDirectoryFilesEx" lib
                         (_fun _string _string _stdbool -> (lst : _file-path-list-bytes)))]
        [uf (get-ffi-obj "UnloadDirectoryFiles" lib
                         (_fun (lst : _file-path-list-bytes) -> _void))])
    (lambda (base-path filter scan-subdirs?)
      (let* ([raw (lf base-path filter scan-subdirs?)]
             [paths (filepathlist->string-list raw)])
        (uf raw) paths))))

(define load-dropped-files
  (let ([lf (get-ffi-obj "LoadDroppedFiles" lib
                         (_fun -> (lst : _file-path-list-bytes)))]
        [uf (get-ffi-obj "UnloadDroppedFiles" lib
                         (_fun (lst : _file-path-list-bytes) -> _void))])
    (lambda ()
      (let* ([raw (lf)] [paths (filepathlist->string-list raw)])
        (uf raw) paths))))

;; ═══════════════════════════════════════════════════════════
;; 12. 随机
;; ═══════════════════════════════════════════════════════════

(define get-random-value (get-ffi-obj "GetRandomValue" lib (_fun _int _int -> _int)))
(define set-random-seed  (get-ffi-obj "SetRandomSeed" lib (_fun _uint -> _void)))

(define (load-random-sequence count min max)
  (let* ([lf (get-ffi-obj "LoadRandomSequence" lib (_fun _uint _int _int -> _pointer))]
         [uf (get-ffi-obj "UnloadRandomSequence" lib (_fun _pointer -> _void))]
         [ptr (lf count min max)]
         [result (for/list ([i (in-range count)]) (ptr-ref ptr _int i))])
    (uf ptr) result))

;; ═══════════════════════════════════════════════════════════
;; 13. 着色器
;; ═══════════════════════════════════════════════════════════

(define load-shader
  (let ([f (get-ffi-obj "LoadShader" lib
                        (_fun _string _string -> (s : _shader-bytes)))]
        [f-null (get-ffi-obj "LoadShader" lib
                             (_fun _pointer _string -> (s : _shader-bytes)))])
    (lambda (vs-filename fs-filename)
      (if vs-filename
          (f vs-filename fs-filename)
          (f-null #f fs-filename)))))

(define load-shader-from-memory
  (let ([f (get-ffi-obj "LoadShaderFromMemory" lib
                        (_fun _string _string -> (s : _shader-bytes)))])
    (lambda (vs-code fs-code) (f vs-code fs-code))))

(define unload-shader
  (let ([f (get-ffi-obj "UnloadShader" lib (_fun (s : _shader-bytes) -> _void))])
    (lambda (shader) (f shader))))

(define is-shader-valid
  (let ([f (get-ffi-obj "IsShaderValid" lib (_fun (s : _shader-bytes) -> _stdbool))])
    (lambda (shader) (f shader))))

(define get-shader-location
  (let ([f (get-ffi-obj "GetShaderLocation" lib
                        (_fun (s : _shader-bytes) _string -> _int))])
    (lambda (shader uniform-name) (f shader uniform-name))))

(define get-shader-location-attrib
  (let ([f (get-ffi-obj "GetShaderLocationAttrib" lib
                        (_fun (s : _shader-bytes) _string -> _int))])
    (lambda (shader attrib-name) (f shader attrib-name))))

(define set-shader-value
  (let ([f (get-ffi-obj "SetShaderValue" lib
                        (_fun (s : _shader-bytes) _int _pointer _int -> _void))])
    (lambda (shader loc-index value uniform-type)
      (f shader loc-index value uniform-type))))

(define set-shader-value-v
  (get-ffi-obj "SetShaderValueV" lib
               (_fun (s : _shader-bytes) _int _pointer _int _int -> _void)))

(define set-shader-value-matrix
  (let ([f (get-ffi-obj "SetShaderValueMatrix" lib
                        (_fun (s : _shader-bytes) _int (m : _matrix-bytes) -> _void))])
    (lambda (shader loc-index mat) (f shader loc-index mat))))

(define set-shader-value-texture
  (let ([f (get-ffi-obj "SetShaderValueTexture" lib
                        (_fun (s : _shader-bytes) _int (t : _texture-bytes) -> _void))])
    (lambda (shader loc-index texture) (f shader loc-index texture))))

(define begin-shader-mode
  (let ([f (get-ffi-obj "BeginShaderMode" lib
                        (_fun (s : _shader-bytes) -> _void))])
    (lambda (shader) (f shader))))

(define end-shader-mode
  (get-ffi-obj "EndShaderMode" lib (_fun -> _void)))

;; ═══════════════════════════════════════════════════════════
;; 14. 颜色 / 文本 / 图像 / 截图 / 日志 / 内存 / VR / 自动化 / 哈希
;; ═══════════════════════════════════════════════════════════

(define fade
  (let ([f (get-ffi-obj "Fade" lib
                        (_fun (c : _color-bytes) _float -> (v : _color-bytes)))])
    (λ (c a) (bytes->color (f (color->bytes c) a)))))

(define color-alpha
  (let ([f (get-ffi-obj "ColorAlpha" lib
                        (_fun (c : _color-bytes) _float -> (v : _color-bytes)))])
    (λ (c a) (bytes->color (f (color->bytes c) a)))))

(define color-from-hsv
  (let ([f (get-ffi-obj "ColorFromHSV" lib
                        (_fun _float _float _float -> (v : _color-bytes)))])
    (λ (h s v) (bytes->color (f h s v)))))

(define color-is-equal
  (let ([f (get-ffi-obj "ColorIsEqual" lib
                        (_fun (c1 : _color-bytes) (c2 : _color-bytes) -> _stdbool))])
    (lambda (c1 c2) (f (color->bytes c1) (color->bytes c2)))))

(def-ffi measure-text "MeasureText" (_fun _string _int -> _int))

(define get-font-default
  (let ([f (get-ffi-obj "GetFontDefault" lib (_fun -> (font : _font-bytes)))])
    (λ () (f))))

(define measure-text-ex
  (let ([f (get-ffi-obj "MeasureTextEx" lib
                        (_fun (font : _font-bytes) _string _float _float
                              -> (v : _vec2-bytes)))])
    (λ (font text fs sp) (bytes->vec2 (f font text fs sp)))))

(define load-image-from-screen
  (let ([f (get-ffi-obj "LoadImageFromScreen" lib
                        (_fun -> (img : _image-bytes)))])
    (lambda () (f))))

(define export-image
  (let ([f (get-ffi-obj "ExportImage" lib
                        (_fun (i : _image-bytes) _string -> _stdbool))])
    (lambda (img filename) (f img filename))))

(define unload-image
  (let ([f (get-ffi-obj "UnloadImage" lib (_fun (img : _image-bytes) -> _void))])
    (lambda (img) (f img))))

(def-ffi take-screenshot    "TakeScreenshot"    (_fun _string -> _void))
(def-ffi open-url           "OpenURL"           (_fun _string -> _void))
(def-ffi set-trace-log-level "SetTraceLogLevel" (_fun _int -> _void))
(define set-trace-log-callback
  (get-ffi-obj "SetTraceLogCallback" lib (_fun _pointer -> _void)))
(define vsnprintf
  (get-ffi-obj "vsnprintf" #f (_fun _pointer _int _string _pointer -> _int)))
(def-ffi mem-alloc   "MemAlloc"   (_fun _uint -> _pointer))
(def-ffi mem-realloc "MemRealloc" (_fun _pointer _uint -> _pointer))
(def-ffi mem-free    "MemFree"    (_fun _pointer -> _void))

(define load-vr-stereo-config
  (let ([f (get-ffi-obj "LoadVrStereoConfig" lib
                        (_fun (dev : _vr-device-info-bytes)
                              -> (cfg : _vr-stereo-config-bytes)))])
    (lambda (device) (f device))))
(define unload-vr-stereo-config
  (let ([f (get-ffi-obj "UnloadVrStereoConfig" lib
                        (_fun (cfg : _vr-stereo-config-bytes) -> _void))])
    (lambda (config) (f config))))
(define begin-vr-stereo-mode
  (let ([f (get-ffi-obj "BeginVrStereoMode" lib
                        (_fun (cfg : _vr-stereo-config-bytes) -> _void))])
    (lambda (config) (f config))))
(define end-vr-stereo-mode (get-ffi-obj "EndVrStereoMode" lib (_fun -> _void)))
(define play-automation-event
  (get-ffi-obj "PlayAutomationEvent" lib
               (_fun (evt : _automation-event-bytes) -> _void)))
(define load-automation-event-list
  (get-ffi-obj "LoadAutomationEventList" lib (_fun _string -> _pointer)))
(def-ffi unload-automation-event-list "UnloadAutomationEventList" (_fun _pointer -> _void))
(define export-automation-event-list
  (get-ffi-obj "ExportAutomationEventList" lib (_fun _pointer _string -> _stdbool)))
(def-ffi set-automation-event-list "SetAutomationEventList" (_fun _pointer -> _void))
(def-ffi set-automation-event-base-frame "SetAutomationEventBaseFrame" (_fun _int -> _void))
(def-ffi start-automation-event-recording "StartAutomationEventRecording" (_fun -> _void))
(def-ffi stop-automation-event-recording  "StopAutomationEventRecording" (_fun -> _void))

(def-ffi compute-crc32 "ComputeCRC32" (_fun _bytes _int -> _uint))
(define compute-md5
  (let ([f (get-ffi-obj "ComputeMD5" lib (_fun _bytes _int -> _pointer))])
    (λ (d s) (let ([p (f d s)]) (and p (list (ptr-ref p _uint 0) (ptr-ref p _uint 1)
                                              (ptr-ref p _uint 2) (ptr-ref p _uint 3)))))))
(define compute-sha1
  (let ([f (get-ffi-obj "ComputeSHA1" lib (_fun _bytes _int -> _pointer))])
    (λ (d s) (let ([p (f d s)]) (and p (list (ptr-ref p _uint 0) (ptr-ref p _uint 1)
                                              (ptr-ref p _uint 2) (ptr-ref p _uint 3)
                                              (ptr-ref p _uint 4)))))))
(define compute-sha256
  (let ([f (get-ffi-obj "ComputeSHA256" lib (_fun _bytes _int -> _pointer))])
    (λ (d s) (let ([p (f d s)]) (and p (list (ptr-ref p _uint 0) (ptr-ref p _uint 1)
                                              (ptr-ref p _uint 2) (ptr-ref p _uint 3)
                                              (ptr-ref p _uint 4) (ptr-ref p _uint 5)
                                              (ptr-ref p _uint 6) (ptr-ref p _uint 7)))))))
(define %encode-data-base64-raw
  (get-ffi-obj "EncodeDataBase64" lib (_fun _bytes _int _pointer -> _pointer)))

(define (encode-data-base64 data data-size)
  (let ([out-size-buf (malloc _int 1 'atomic)] [tmp (malloc _pointer 1 'atomic)])
    (ptr-set! out-size-buf _int 0 0)
    (let ([cstr (%encode-data-base64-raw data data-size out-size-buf)])
      (if (not cstr) ""
          (begin (ptr-set! tmp _pointer 0 cstr)
                 (let ([r (ptr-ref tmp _string)])
                   ((get-ffi-obj "MemFree" lib (_fun _pointer -> _void)) cstr) r))))))

(define compress-data
  (let ([f (get-ffi-obj "CompressData" lib (_fun _pointer _int _pointer -> _pointer))])
    (lambda (d s) (let ([out (malloc _int 1 'atomic)])
                    (let ([r (f d s out)]) (values r (ptr-ref out _int 0)))))))

(define decompress-data
  (let ([f (get-ffi-obj "DecompressData" lib (_fun _pointer _int _pointer -> _pointer))])
    (lambda (d s) (let ([out (malloc _int 1 'atomic)])
                    (let ([r (f d s out)]) (values r (ptr-ref out _int 0)))))))

(define decode-data-base64
  (let ([f (get-ffi-obj "DecodeDataBase64" lib (_fun _string _pointer -> _pointer))])
    (lambda (text) (let ([out (malloc _int 1 'atomic)])
                     (let ([r (f text out)]) (values r (ptr-ref out _int 0)))))))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide
 init-window close-window window-should-close?
 is-window-ready? is-window-fullscreen? is-window-hidden?
 is-window-minimized? is-window-maximized? is-window-focused?
 is-window-resized? is-window-state?
 set-window-title set-window-position set-window-size
 set-window-min-size set-window-max-size
 set-window-opacity set-window-focused get-window-handle
 get-window-position set-window-icon set-window-icons
 set-window-state clear-window-state
 toggle-fullscreen toggle-borderless-windowed
 minimize-window maximize-window restore-window
 get-monitor-count get-current-monitor
 get-monitor-width get-monitor-height
 get-monitor-physical-width get-monitor-physical-height
 get-monitor-refresh-rate get-monitor-name get-monitor-position
 set-window-monitor
 begin-drawing end-drawing clear-background draw-text draw-line
 begin-blend-mode end-blend-mode begin-scissor-mode end-scissor-mode
 set-config-flags
 begin-mode-2d end-mode-2d begin-mode-3d end-mode-3d
 update-camera update-camera-pro get-camera-matrix get-camera-matrix-2d
 get-screen-width get-screen-height get-render-width get-render-height
 get-window-scale-dpi draw-grid
 get-screen-to-world-2d get-world-to-screen-2d
 get-screen-to-world-ray get-screen-to-world-ray-ex
 get-world-to-screen get-world-to-screen-ex
 set-target-fps get-frame-time get-fps get-time draw-fps
 swap-screen-buffer wait-time
 is-key-pressed is-key-down is-key-pressed-repeat is-key-released is-key-up
 get-key-pressed get-char-pressed get-key-name set-exit-key
 is-mouse-button-pressed is-mouse-button-down
 is-mouse-button-released is-mouse-button-up
 get-mouse-x get-mouse-y get-mouse-position get-mouse-delta
 get-mouse-wheel-move get-mouse-wheel-move-v
 set-mouse-position set-mouse-offset set-mouse-scale set-mouse-cursor
 is-cursor-hidden? is-cursor-on-screen?
 show-cursor hide-cursor enable-cursor disable-cursor
 is-gamepad-available? get-gamepad-name
 is-gamepad-button-pressed is-gamepad-button-down
 is-gamepad-button-released is-gamepad-button-up
 get-gamepad-button-pressed
 get-gamepad-axis-count get-gamepad-axis-movement
 set-gamepad-mappings set-gamepad-vibration
 get-touch-x get-touch-y get-touch-position
 get-touch-point-id get-touch-point-count
 set-gestures-enabled is-gesture-detected? get-gesture-detected
 get-gesture-hold-duration get-gesture-drag-vector get-gesture-drag-angle
 get-gesture-pinch-vector get-gesture-pinch-angle
 poll-input-events enable-event-waiting disable-event-waiting
 set-clipboard-text get-clipboard-text get-clipboard-image
 file-exists? directory-exists?
 is-file-extension is-file-name-valid is-path-file?
 get-file-length get-file-mod-time
 get-file-extension get-file-name get-file-name-without-ext
 get-directory-path get-working-directory get-prev-directory-path
 get-application-directory
 make-directory change-directory
 file-rename file-remove file-copy file-move
 file-text-replace file-text-find-index
 get-directory-file-count get-directory-file-count-ex
 save-file-text unload-file-data is-file-dropped
 set-load-file-data-callback set-save-file-data-callback
 set-load-file-text-callback set-save-file-text-callback
 load-file-data save-file-data export-data-as-code
 load-file-text load-directory-files load-directory-files-ex load-dropped-files
 get-random-value set-random-seed load-random-sequence
 load-shader load-shader-from-memory unload-shader is-shader-valid
 get-shader-location get-shader-location-attrib
 set-shader-value set-shader-value-v
 set-shader-value-matrix set-shader-value-texture
 begin-shader-mode end-shader-mode
 fade color-alpha color-from-hsv color-is-equal
 measure-text get-font-default measure-text-ex
 load-image-from-screen unload-image export-image
 take-screenshot open-url set-trace-log-level
 set-trace-log-callback vsnprintf
 mem-alloc mem-realloc mem-free
 load-vr-stereo-config unload-vr-stereo-config
 begin-vr-stereo-mode end-vr-stereo-mode
 play-automation-event load-automation-event-list
 unload-automation-event-list export-automation-event-list
 set-automation-event-list set-automation-event-base-frame
 start-automation-event-recording stop-automation-event-recording
 compute-crc32 compute-md5 compute-sha1 compute-sha256
 encode-data-base64 decode-data-base64 compress-data decompress-data)
