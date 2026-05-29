#lang racket/base

;; raylib [core] example - custom frame control (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_custom_frame_control.c
;;
;; 演示自定义帧控制：手动管理 PollInputEvents / SwapScreenBuffer / 帧定时
;; 注意：此示例需要 raylib 以 SUPPORT_CUSTOM_FRAME_CONTROL 编译，
;;       否则 EndDrawing 内部已包含 SwapScreenBuffer 和 PollInputEvents

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - custom frame control")

;; 自定义计时变量
(define previous-time (get-time))       ;; 上一帧时间
(define current-time 0.0)               ;; 当前时间
(define update-draw-time 0.0)           ;; 更新+绘制耗时
(define wait-time-val 0.0)              ;; 等待时间
(define delta-time 0.0)                 ;; 帧时间

(define time-counter 0.0)               ;; 累计时间 (秒)
(define position 0.0)                   ;; 圆圈位置
(define pause? #f)                      ;; 暂停标志

(define target-fps 60)                  ;; 目标帧率

;; 注意: 使用 SUPPORT_CUSTOM_FRAME_CONTROL 时 SetTargetFPS 无效
;; 所以这里不调用 set-target-fps

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; === 轮询输入 (自定义帧控制) ===
    (poll-input-events)

    ;; 更新
    (when (is-key-pressed KEY-SPACE)
      (set! pause? (not pause?)))

    (cond
      [(is-key-pressed KEY-UP)    (set! target-fps (+ target-fps 20))]
      [(is-key-pressed KEY-DOWN)  (set! target-fps (- target-fps 20))])

    (when (< target-fps 0) (set! target-fps 0))

    (unless pause?
      (set! position (+ position (* 200.0 delta-time)))  ;; 200 像素/秒
      (when (>= position SCREEN-WIDTH) (set! position 0.0))
      (set! time-counter (+ time-counter delta-time)))

    ;; === 绘制 ===
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 画垂直分隔线
    (for ([i (in-range (inexact->exact (ceiling (/ SCREEN-WIDTH 200.0))))])
      (draw-rectangle (* i 200) 0 1 SCREEN-HEIGHT SKYBLUE))

    ;; 画移动的红色圆圈
    (define pos-int (inexact->exact (round position)))
    (draw-circle pos-int (- (quotient SCREEN-HEIGHT 2) 25) 50.0 RED)

    ;; 显示时间/位置信息
    (define ms-val (inexact->exact (round (* time-counter 1000.0))))
    (draw-text (format "~a ms" ms-val)
               (- pos-int 40) (- (quotient SCREEN-HEIGHT 2) 100) 20 MAROON)
    (draw-text (format "PosX: ~a" pos-int)
               (- pos-int 50) (+ (quotient SCREEN-HEIGHT 2) 40) 20 BLACK)

    ;; 提示文字
    (draw-text "Circle is moving at a constant 200 pixels/sec,\nindependently of the frame rate."
               10 10 20 DARKGRAY)
    (draw-text "PRESS SPACE to PAUSE MOVEMENT"
               10 (- SCREEN-HEIGHT 60) 20 GRAY)
    (draw-text "PRESS UP | DOWN to CHANGE TARGET FPS"
               10 (- SCREEN-HEIGHT 30) 20 GRAY)
    (draw-text (format "TARGET FPS: ~a" target-fps)
               (- SCREEN-WIDTH 220) 10 20 LIME)
    (unless (= delta-time 0.0)
      (define current-fps (inexact->exact (round (/ 1.0 delta-time))))
      (draw-text (format "CURRENT FPS: ~a" current-fps)
                 (- SCREEN-WIDTH 220) 40 20 GREEN))

    (end-drawing)

    ;; === 自定义帧控制 (SUPPORT_CUSTOM_FRAME_CONTROL) ===
    (swap-screen-buffer)

    (set! current-time (get-time))
    (set! update-draw-time (- current-time previous-time))

    (when (> target-fps 0)
      (define wait-time-ms (- (/ 1.0 target-fps) update-draw-time))
      (when (> wait-time-ms 0.0)
        (wait-time wait-time-ms)
        (set! current-time (get-time))
        (set! delta-time (- current-time previous-time))))

    (unless (> target-fps 0)
      (set! delta-time update-draw-time))

    (set! previous-time current-time)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
