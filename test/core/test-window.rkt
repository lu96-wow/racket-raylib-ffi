#lang racket/base

;; rcore.rkt 窗口管理测试
;; 需 OpenGL 上下文 (init-window)

(require "../helper.rkt"
         (prefix-in lib: "../../raylib/raylib.rkt"))

(printf "~n========================================~n")
(printf "  窗口管理测试~n")
(printf "========================================~n")

;; ============================================================
;; 基本窗口生命周期
;; ============================================================

(test-section "窗口生命周期")

(printf "  注意: 这些测试会短暂打开一个窗口...~n")

(define (test-init-close)
  (lib:init-window 320 200 "test-window")
  (lib:set-target-fps 60)

  ;; 验证窗口状态函数
  (printf "    window-should-close? = ~a (应为 #f)~n" (lib:window-should-close?))

  ;; 获取屏幕尺寸
  (define w (lib:get-screen-width))
  (define h (lib:get-screen-height))
  (printf "    get-screen-width = ~a (应为 320)~n" w)
  (printf "    get-screen-height = ~a (应为 200)~n" h)
  (assert-= w 320)
  (assert-= h 200)
  (test-pass! "初始化 + 屏幕尺寸")

  ;; 检查 is-window-resized?
   (assert-false (lib:is-window-resized?))
  (test-pass! "is-window-resized? (初始为 #f)")

  (lib:close-window)
  (test-pass! "close-window (无异常)"))

(test-init-close)

;; ============================================================
;; SetWindowMinSize
;; ============================================================

(test-section "SetWindowMinSize")

(define (test-min-size)
  (lib:init-window 640 480 "test-min-size")
  (lib:set-target-fps 60)

  (lib:set-window-min-size 400 300)
  (test-pass! "set-window-min-size 调用 (需手动验证)")

  (lib:close-window))

;; 需要 FLAG-WINDOW-RESIZABLE 才能看到效果
(define (test-min-size-resizable)
  (lib:set-config-flags (bitwise-ior lib:FLAG-WINDOW-RESIZABLE
                                     lib:FLAG-VSYNC-HINT))
  (lib:init-window 640 480 "test-min-size (resizable)")
  (lib:set-target-fps 60)
  (lib:set-window-min-size 400 300)
  (test-pass! "set-window-min-size + FLAG-WINDOW-RESIZABLE")
  (lib:close-window))

(test-min-size)
(test-min-size-resizable)

;; ============================================================
;; 窗口状态标志
;; ============================================================

(test-section "窗口状态标志")

(define (test-window-state)
  (lib:init-window 640 480 "test-window-state")
  (lib:set-target-fps 60)

  ;; 检查默认状态
   (assert-true (lib:is-window-state? lib:FLAG-VSYNC-HINT))
  (test-pass! "is-window-state? (VSYNC 默认启用)")

  ;; 设置/清除状态
  (lib:set-window-state lib:FLAG-WINDOW-TOPMOST)
   (assert-true (lib:is-window-state? lib:FLAG-WINDOW-TOPMOST))
  (test-pass! "set-window-state + is-window-state? (TOPMOST)")

  (lib:clear-window-state lib:FLAG-WINDOW-TOPMOST)
   (assert-false (lib:is-window-state? lib:FLAG-WINDOW-TOPMOST))
  (test-pass! "clear-window-state (TOPMOST 清除)")

  ;; toggle-fullscreen (快速测试)
  (lib:toggle-fullscreen)
  (printf "    toggle-fullscreen 切换了~n")
  (lib:toggle-fullscreen)
  (test-pass! "toggle-fullscreen (双切回窗口)")

  (lib:close-window))

(test-window-state)

;; ============================================================
;; 窗口最大化/最小化/恢复
;; ============================================================

(test-section "minimize / maximize / restore")

(define (test-min-max-restore)
  (lib:init-window 640 480 "test-min-max-restore")
  (lib:set-target-fps 60)

  (lib:minimize-window)
  (printf "    minimize-window 调用~n")
  (lib:restore-window)
  (printf "    restore-window 调用~n")
  (lib:maximize-window)
  (printf "    maximize-window 调用~n")
  (lib:restore-window)
  (printf "    restore-window 调用~n")

  (test-pass! "minimize / maximize / restore (无异常)")
  (lib:close-window))

(test-min-max-restore)

(printf "~n窗口管理测试完成!~n")
