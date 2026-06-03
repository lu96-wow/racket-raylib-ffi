#lang racket/base

;; rcore.rkt 绘制/计时测试
;; 需 OpenGL 上下文

(require "../helper.rkt"
         (prefix-in lib: "../../raylib/raylib.rkt"))

(printf "~n========================================~n")
(printf "  绘制/计时测试~n")
(printf "========================================~n")

;; ============================================================
;; 基本绘制循环
;; ============================================================

(test-section "基本绘制循环")

(printf "  注意: 会短暂打开窗口, 绘制几帧后关闭~n")

(define (test-draw-loop)
  (lib:init-window 400 300 "test-draw")
  (lib:set-target-fps 60)

  ;; 绘制 10 帧, 验证计时函数
  (let loop ([frame 0])
    (when (and (< frame 10) (not (lib:window-should-close?)))
      (lib:begin-drawing)
      (lib:clear-background lib:RAYWHITE)

      ;; 在窗口中绘制一些文字
      (lib:draw-text "Drawing test..." 50 100 20 lib:RED)
      (lib:draw-text "Frame" 50 130 20 lib:BLUE)
      (lib:draw-text (number->string frame) 140 130 20 lib:BLUE)

      (lib:end-drawing)

      ;; 验证计时函数
      (define dt (lib:get-frame-time))
      (define fps (lib:get-fps))
      (define t (lib:get-time))

      (when (= frame 0)
        (printf "    frame 0: dt=~a, fps=~a, time=~a~n" dt fps t)
        (test-pass! "get-frame-time / get-fps / get-time 返回值"))

      (loop (add1 frame))))

  (lib:close-window)
  (test-pass! "10帧绘制循环 (无异常)"))

(test-draw-loop)

;; ============================================================
;; DrawFPS
;; ============================================================

(test-section "DrawFPS")

(define (test-draw-fps)
  (lib:init-window 400 200 "test-fps")
  (lib:set-target-fps 30)

  (let loop ([frame 0])
    (when (and (< frame 5) (not (lib:window-should-close?)))
      (lib:begin-drawing)
      (lib:clear-background lib:BLACK)
      (lib:draw-fps 10 10)
      (lib:end-drawing)
      (loop (add1 frame))))

  (lib:close-window)
  (test-pass! "draw-fps (无异常)"))

(test-draw-fps)

;; ============================================================
;; Scissor Mode
;; ============================================================

(test-section "Scissor Mode")

(define (test-scissor)
  (lib:init-window 400 200 "test-scissor")
  (lib:set-target-fps 30)

  (let loop ([frame 0])
    (when (and (< frame 5) (not (lib:window-should-close?)))
      (lib:begin-drawing)
      (lib:clear-background lib:RAYWHITE)
      (lib:begin-scissor-mode 50 50 100 100)
      (lib:draw-rectangle 0 0 400 200 lib:RED)
      (lib:end-scissor-mode)
      (lib:end-drawing)
      (loop (add1 frame))))

  (lib:close-window)
  (test-pass! "begin-scissor-mode / end-scissor-mode (无异常)"))

(test-scissor)

;; ============================================================
;; SwapScreenBuffer / WaitTime
;; ============================================================

(test-section "SwapScreenBuffer / WaitTime / PollInputEvents")

(define (test-swap-wait)
  (lib:init-window 400 200 "test-swap")
  (lib:set-target-fps 60)

  ;; 手动帧控制
  (lib:begin-drawing)
  (lib:clear-background lib:RAYWHITE)
  (lib:draw-text "Manual swap" 50 100 20 lib:RED)
  (lib:end-drawing)

  (lib:swap-screen-buffer)
  (lib:poll-input-events)
  (lib:wait-time 0.1)
  (test-pass! "swap-screen-buffer / poll-input-events / wait-time (无异常)")

  (lib:close-window))

(test-swap-wait)

(printf "~n绘制/计时测试完成!~n")
