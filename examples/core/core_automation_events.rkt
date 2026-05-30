#lang racket/base

;; raylib [core] example - automation events
;; 对应 C: examples/core/core_automation_events.c
;;
;; 录制/回放输入事件的自动化系统演示
;;   按 S 开始/停止录制
;;   按 A 回放录制的输入事件
;;   按 R 重置游戏状态
;;
;; 设计: 录制用纯 Racket (recorder + 事件列表)
;;       回放用唯一 FFI: PlayAutomationEvent

(require racket/string
         "../../raylib/raylib.rkt"
         "../../raylib-racket/automation.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define GRAVITY 400)
(define PLAYER-JUMP-SPD 350.0)
(define PLAYER-HOR-SPD 200.0)
(define MAX-ENVIRONMENT-ELEMENTS 5)
(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 450)

;; ============================================================
;; 自定义结构体
;; ============================================================

(struct player (position speed can-jump) #:mutable)
(struct env-element (rect blocking color) #:mutable)

;; ============================================================
;; 辅助: 用已有 FFI 检测输入变化（供 recorder 使用）
;; ============================================================

(define (key-down? key) (is-key-down key))
(define (mouse-btn? btn) (is-mouse-button-down btn))

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
             "raylib [core] example - automation events")

;; Player
(define p (player (vector2 400 280) 0.0 #f))

;; Environment elements (platforms)
(define env-elements
  (list (env-element (rectangle 0 0 1000 400) 0 LIGHTGRAY)
        (env-element (rectangle 0 400 1000 200) 1 GRAY)
        (env-element (rectangle 300 200 400 10) 1 GRAY)
        (env-element (rectangle 250 300 100 10) 1 GRAY)
        (env-element (rectangle 650 300 100 10) 1 GRAY)))

;; Camera
(define camera
  (camera2d 400 280
            (/ SCREEN-WIDTH 2.0) (/ SCREEN-HEIGHT 2.0)
            0.0 1.0))

;; Automation events — 纯 Racket 录制
(define recorder (make-recorder))
(define recorded-events '())       ;; 录制完成后从 recorder 取出存这里
(define event-recording #f)
(define event-playing #f)
(define play-frame-counter 0)
(define current-play-frame 0)
(define frame-counter 0)

(set-target-fps 60)

;; ============================================================
;; 辅助: 重置场景
;; ============================================================

(define (reset-scene)
  (set-vector2-x! (player-position p) 400)
  (set-vector2-y! (player-position p) 280)
  (set-player-speed! p 0.0)
  (set-player-can-jump! p #f)
  (set-camera2d-target-x! camera 400)
  (set-camera2d-target-y! camera 280)
  (set-camera2d-offset-x! camera (/ SCREEN-WIDTH 2.0))
  (set-camera2d-offset-y! camera (/ SCREEN-HEIGHT 2.0))
  (set-camera2d-rotation! camera 0.0)
  (set-camera2d-zoom! camera 1.0))

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (define delta-time 0.015)

    ;; ── 鼠标/滚轮状态（供 recorder 使用）──
    (define mouse-pos (get-mouse-position))
    (define mx (inexact->exact (truncate (vector2-x mouse-pos))))
    (define my (inexact->exact (truncate (vector2-y mouse-pos))))
    (define wheel-delta (inexact->exact (truncate (get-mouse-wheel-move))))

    ;; ── 录制: 每帧记录输入变化 ──
    (when event-recording
      (record-frame! recorder frame-counter
                     key-down? mouse-btn?
                     mx my wheel-delta wheel-delta))

    ;; ── Dropped files ──
    (when (is-file-dropped)
      (define files (load-dropped-files))
      (when (and (pair? files)
                 (or (string-suffix? (car files) ".txt")
                     (string-suffix? (car files) ".rae")))
        (set! recorded-events (load-automation-events (car files)))
        (set! event-recording #f)
        (set! event-playing #t)
        (set! play-frame-counter 0)
        (set! current-play-frame 0)
        (reset-scene)))

    ;; ── Update player ──
    (when (is-key-down KEY-LEFT)
      (set-vector2-x! (player-position p)
        (- (vector2-x (player-position p)) (* PLAYER-HOR-SPD delta-time))))
    (when (is-key-down KEY-RIGHT)
      (set-vector2-x! (player-position p)
        (+ (vector2-x (player-position p)) (* PLAYER-HOR-SPD delta-time))))
    (when (and (is-key-down KEY-SPACE) (player-can-jump p))
      (set-player-speed! p (- PLAYER-JUMP-SPD))
      (set-player-can-jump! p #f))

    ;; Obstacle collision
    (define (check-obstacles)
      (let loop-elems ([elems env-elements])
        (cond
          [(null? elems) (values #f #f)]
          [else
           (define elem (car elems))
           (define r (env-element-rect elem))
           (define px (vector2-x (player-position p)))
           (define py (vector2-y (player-position p)))
           (define spd (player-speed p))
           (if (and (= (env-element-blocking elem) 1)
                    (<= (rectangle-x r) px)
                    (>= (+ (rectangle-x r) (rectangle-w r)) px)
                    (>= (rectangle-y r) py)
                    (<= (rectangle-y r) (+ py (* spd delta-time))))
               (values #t (rectangle-y r))
               (loop-elems (cdr elems)))])))
    (define-values (hit? obstacle-y) (check-obstacles))
    (if hit?
        (begin
          (set-player-speed! p 0.0)
          (set-vector2-y! (player-position p) obstacle-y)
          (set-player-can-jump! p #t))
        (begin
          (set-vector2-y! (player-position p)
            (+ (vector2-y (player-position p)) (* (player-speed p) delta-time)))
          (set-player-speed! p (+ (player-speed p) (* GRAVITY delta-time)))
          (set-player-can-jump! p #f)))

    ;; Reset on KEY-R
    (when (is-key-pressed KEY-R) (reset-scene))

    ;; ── 回放 ──
    (when event-playing
      (let loop-play ()
        (when (< current-play-frame (length recorded-events))
          (define evt (list-ref recorded-events current-play-frame))
          (when (= play-frame-counter (automation-event-frame evt))
            (play-automation-event evt)
            (set! current-play-frame (add1 current-play-frame))
            (when (= current-play-frame (length recorded-events))
              (set! event-playing #f)
              (set! current-play-frame 0)
              (set! play-frame-counter 0))
            (loop-play)))))
    (when event-playing
      (set! play-frame-counter (add1 play-frame-counter)))

    ;; ── Camera update ──
    (set-camera2d-target-x! camera (vector2-x (player-position p)))
    (set-camera2d-target-y! camera (vector2-y (player-position p)))
    (set-camera2d-offset-x! camera (/ SCREEN-WIDTH 2.0))
    (set-camera2d-offset-y! camera (/ SCREEN-HEIGHT 2.0))

    (define minX 1000.0) (define minY 1000.0)
    (define maxX -1000.0) (define maxY -1000.0)
    (for-each (lambda (elem)
                (define r (env-element-rect elem))
                (set! minX (min (rectangle-x r) minX))
                (set! maxX (max (+ (rectangle-x r) (rectangle-w r)) maxX))
                (set! minY (min (rectangle-y r) minY))
                (set! maxY (max (+ (rectangle-y r) (rectangle-h r)) maxY)))
              env-elements)

    (define zoom-delta (* (get-mouse-wheel-move) 0.05))
    (set-camera2d-zoom! camera (max 0.25 (min 3.0 (+ (camera2d-zoom camera) zoom-delta))))

    (define max-screen (get-world-to-screen-2d (vector2 maxX maxY) camera))
    (define min-screen (get-world-to-screen-2d (vector2 minX minY) camera))
    (when (< (vector2-x max-screen) SCREEN-WIDTH)
      (set-camera2d-offset-x! camera
        (- SCREEN-WIDTH (- (vector2-x max-screen) (/ SCREEN-WIDTH 2.0)))))
    (when (< (vector2-y max-screen) SCREEN-HEIGHT)
      (set-camera2d-offset-y! camera
        (- SCREEN-HEIGHT (- (vector2-y max-screen) (/ SCREEN-HEIGHT 2.0)))))
    (when (> (vector2-x min-screen) 0)
      (set-camera2d-offset-x! camera (- (/ SCREEN-WIDTH 2.0) (vector2-x min-screen))))
    (when (> (vector2-y min-screen) 0)
      (set-camera2d-offset-y! camera (- (/ SCREEN-HEIGHT 2.0) (vector2-y min-screen))))

    ;; ── 按键管理 ──
    (when (is-key-pressed KEY-S)
      (unless event-playing
        (if event-recording
            (begin
              (set! event-recording #f)
              (set! recorded-events (reverse (recorder-events recorder)))
              (clear-recorder! recorder)
              (export-automation-events recorded-events "automation.rae"))
            (begin
              (set! frame-counter 0)
              (clear-recorder! recorder)
              (set! event-recording #t)))))

    (when (is-key-pressed KEY-A)
      (when (and (not event-recording) (pair? recorded-events))
        (set! event-playing #t)
        (set! play-frame-counter 0)
        (set! current-play-frame 0)
        (reset-scene)))

    ;; Frame counter
    (set! frame-counter (add1 frame-counter))

    ;; ── Draw ──
    (begin-drawing)
    (clear-background LIGHTGRAY)

    (begin-mode-2d camera)
    (for-each (lambda (elem)
                (draw-rectangle-rec (env-element-rect elem) (env-element-color elem)))
              env-elements)
    (define px (vector2-x (player-position p)))
    (define py (vector2-y (player-position p)))
    (draw-rectangle-rec (rectangle (- px 20) (- py 40) 40 40) RED)
    (end-mode-2d)

    ;; UI 面板
    (draw-rectangle 10 10 290 145 (fade SKYBLUE 0.5))
    (draw-rectangle-lines 10 10 290 145 (fade BLUE 0.8))
    (draw-text "Controls:" 20 20 10 BLACK)
    (draw-text "- RIGHT | LEFT: Player movement" 30 40 10 DARKGRAY)
    (draw-text "- SPACE: Player jump" 30 60 10 DARKGRAY)
    (draw-text "- R: Reset game state" 30 80 10 DARKGRAY)
    (draw-text "- S: START/STOP RECORDING INPUT EVENTS" 30 110 10 BLACK)
    (draw-text "- A: REPLAY LAST RECORDED INPUT EVENTS" 30 130 10 BLACK)

    ;; 录制/回放指示器
    (cond
      [event-recording
       (draw-rectangle 10 160 290 30 (fade RED 0.3))
       (draw-rectangle-lines 10 160 290 30 (fade MAROON 0.8))
       (draw-circle 30 175 10.0 MAROON)
       (when (= (modulo (quotient frame-counter 15) 2) 1)
         (draw-text (format "RECORDING EVENTS... [~a]" (length (recorder-events recorder)))
                    50 170 10 MAROON))]
      [event-playing
       (draw-rectangle 10 160 290 30 (fade LIME 0.3))
       (draw-rectangle-lines 10 160 290 30 (fade DARKGREEN 0.8))
       (draw-triangle (vector2 20 165) (vector2 20 185) (vector2 40 175) DARKGREEN)
       (when (= (modulo (quotient frame-counter 15) 2) 1)
         (draw-text (format "PLAYING RECORDED EVENTS... [~a]" current-play-frame)
                    50 170 10 DARKGREEN))])

    (end-drawing)
    (loop)))

;; ── 清理 ──
(close-window)