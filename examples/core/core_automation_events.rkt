#lang racket/base

;; raylib [core] example - automation events (Racket FFI 翻译)
;; 对应 C: examples/core/core_automation_events.c
;; 演示: 自动化事件录制/回放 (平台跳跃 + 摄像机)

(require "../../raylib/raylib.rkt"
         (except-in ffi/unsafe _bool))

(define GRAVITY 400)
(define PLAYER-JUMP-SPD 350.0)
(define PLAYER-HOR-SPD 200.0)
(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)

(define (make-env-element x y w h blocking color)
  (vector (rectangle x y w h) blocking color))
(define (env-rect   e) (vector-ref e 0))
(define (env-block? e) (vector-ref e 1))
(define (env-color  e) (vector-ref e 2))

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - automation events")

;; 玩家状态: (vector pos-x pos-y speed can-jump)
(define player (vector 400.0 280.0 0.0 #f))
(define (player-pos-x)     (vector-ref player 0))
(define (player-pos-y)     (vector-ref player 1))
(define (player-speed)     (vector-ref player 2))
(define (player-can-jump)  (vector-ref player 3))
(define (set-player-pos-x!  v) (vector-set! player 0 v))
(define (set-player-pos-y!  v) (vector-set! player 1 v))
(define (set-player-speed!  v) (vector-set! player 2 v))
(define (set-player-can-jump! v) (vector-set! player 3 v))

(define env-elements
  (list (make-env-element 0 0 1000 400 0 LIGHTGRAY)
        (make-env-element 0 400 1000 200 1 GRAY)
        (make-env-element 300 200 400 10 1 GRAY)
        (make-env-element 250 300 100 10 1 GRAY)
        (make-env-element 650 300 100 10 1 GRAY)))

(define camera (camera2d (/ SCREEN-WIDTH 2.0) (/ SCREEN-HEIGHT 2.0) 0 0 0 1.0))
(define aelist-ptr (make-empty-automation-event-list))
(set-automation-event-list aelist-ptr)
(define event-recording #f)
(define event-playing #f)
(define frame-counter 0)
(define play-frame-counter 0)
(define current-play-frame 0)

(set-target-fps 60)

(define (reset-state)
  (set-player-pos-x! 400.0)
  (set-player-pos-y! 280.0)
  (set-player-speed! 0.0)
  (set-player-can-jump! #f)
  (set-camera2d-target-x! camera (player-pos-x))
  (set-camera2d-target-y! camera (player-pos-y))
  (set-camera2d-offset-x! camera (/ SCREEN-WIDTH 2.0))
  (set-camera2d-offset-y! camera (/ SCREEN-HEIGHT 2.0))
  (set-camera2d-rotation! camera 0.0)
  (set-camera2d-zoom! camera 1.0))

(let loop ()
  (unless (window-should-close?)
    (define delta-time 0.015)

    ;; 拖放文件
    (when (is-file-dropped)
      (define dropped-files (load-dropped-files))
      (when (>= (length dropped-files) 1)
        (when (is-file-extension (car dropped-files) ".txt;.rae")
          (load-automation-event-file aelist-ptr (car dropped-files))
          (set! event-recording #f)
          (set! event-playing #t)
          (set! play-frame-counter 0)
          (set! current-play-frame 0)
          (reset-state))))

    ;; 玩家更新: 左右移动
    (when (is-key-down KEY-LEFT)
      (set-player-pos-x! (- (player-pos-x) (* PLAYER-HOR-SPD delta-time))))
    (when (is-key-down KEY-RIGHT)
      (set-player-pos-x! (+ (player-pos-x) (* PLAYER-HOR-SPD delta-time))))
    (when (and (is-key-down KEY-SPACE) (player-can-jump))
      (set-player-speed! (- PLAYER-JUMP-SPD))
      (set-player-can-jump! #f))

    ;; 碰撞检测
    (define hit-obstacle #f)
    (for ([elem (in-list env-elements)])
      (when (and (not (= (env-block? elem) 0))
                 (<= (rectangle-x (env-rect elem)) (player-pos-x))
                 (>= (+ (rectangle-x (env-rect elem)) (rectangle-w (env-rect elem))) (player-pos-x))
                 (>= (rectangle-y (env-rect elem)) (player-pos-y))
                 (<= (rectangle-y (env-rect elem)) (+ (player-pos-y) (* (player-speed) delta-time))))
        (set! hit-obstacle #t)
        (set-player-speed! 0.0)
        (set-player-pos-y! (rectangle-y (env-rect elem)))))

    (if hit-obstacle
      (set-player-can-jump! #t)
      (begin
        (set-player-pos-y! (+ (player-pos-y) (* (player-speed) delta-time)))
        (set-player-speed! (+ (player-speed) (* GRAVITY delta-time)))
        (set-player-can-jump! #f)))

    (when (is-key-pressed KEY-R) (reset-state))

    ;; 事件回放
    (when event-playing
      (define events-ptr (ptr-ref aelist-ptr _pointer 1))
      (define count (ptr-ref aelist-ptr _uint 1))
      (let play-loop ()
        (when (and (< current-play-frame count)
                   (= play-frame-counter
                      (ptr-ref events-ptr _uint (* current-play-frame 6))))
          (play-automation-event
            (list (ptr-ref events-ptr _uint (* current-play-frame 6))        ;; frame
                  (ptr-ref events-ptr _uint (+ (* current-play-frame 6) 1))   ;; type
                  (ptr-ref events-ptr _int  (+ (* current-play-frame 6) 2))   ;; params[0]
                  (ptr-ref events-ptr _int  (+ (* current-play-frame 6) 3))   ;; params[1]
                  (ptr-ref events-ptr _int  (+ (* current-play-frame 6) 4))   ;; params[2]
                  (ptr-ref events-ptr _int  (+ (* current-play-frame 6) 5)))) ;; params[3]
          (set! current-play-frame (+ current-play-frame 1))
          (when (= current-play-frame count)
            (set! event-playing #f)
            (set! current-play-frame 0)
            (set! play-frame-counter 0)
            (printf "FINISH PLAYING!\n"))
          (play-loop)))
      (set! play-frame-counter (+ play-frame-counter 1)))

    ;; 摄像机更新
    (set-camera2d-target-x! camera (player-pos-x))
    (set-camera2d-target-y! camera (player-pos-y))
    (set-camera2d-offset-x! camera (/ SCREEN-WIDTH 2.0))
    (set-camera2d-offset-y! camera (/ SCREEN-HEIGHT 2.0))

    (define zoom-delta (* (get-mouse-wheel-move) 0.05))
    (set-camera2d-zoom! camera
      (max 0.25 (min 3.0 (+ (camera2d-zoom camera) zoom-delta))))

    ;; 环境边界
    (define min-x 1000) (define min-y 1000)
    (define max-x -1000) (define max-y -1000)
    (for ([elem (in-list env-elements)])
      (define r (env-rect elem))
      (set! min-x (min min-x (rectangle-x r)))
      (set! max-x (max max-x (+ (rectangle-x r) (rectangle-w r))))
      (set! min-y (min min-y (rectangle-y r)))
      (set! max-y (max max-y (+ (rectangle-y r) (rectangle-h r)))))

    (define max-pt (get-world-to-screen-2d (vector2 max-x max-y) camera))
    (define min-pt (get-world-to-screen-2d (vector2 min-x min-y) camera))

    (when (< (vector2-x max-pt) SCREEN-WIDTH)
      (set-camera2d-offset-x! camera
        (- SCREEN-WIDTH (- (vector2-x max-pt) (/ SCREEN-WIDTH 2.0)))))
    (when (< (vector2-y max-pt) SCREEN-HEIGHT)
      (set-camera2d-offset-y! camera
        (- SCREEN-HEIGHT (- (vector2-y max-pt) (/ SCREEN-HEIGHT 2.0)))))
    ;; 事件管理
    (when (is-key-pressed KEY-S)
      (unless event-playing
        (if event-recording
          (begin
            (stop-automation-event-recording)
            (set! event-recording #f)
            (export-automation-event-list-from-ptr aelist-ptr "automation.rae")
            (printf "RECORDED FRAMES: ~a\n" (automation-event-list-count aelist-ptr)))
          (begin
            (set-automation-event-base-frame 180)
            (start-automation-event-recording)
            (set! event-recording #t)))))

    (when (is-key-pressed KEY-A)
      (when (and (not event-recording) (> (automation-event-list-count aelist-ptr) 0))
        (set! event-playing #t)
        (set! play-frame-counter 0)
        (set! current-play-frame 0)
        (reset-state)))

    (if (or event-recording event-playing)
      (set! frame-counter (+ frame-counter 1))
      (set! frame-counter 0))

    ;; 绘制
    (begin-drawing)
    (clear-background LIGHTGRAY)
    (begin-mode-2d camera)
    (for ([elem (in-list env-elements)])
      (draw-rectangle-rec (env-rect elem) (env-color elem)))
    (draw-rectangle-rec
      (rectangle (- (player-pos-x) 20) (- (player-pos-y) 40) 40 40) RED)
    (end-mode-2d)

    ;; 控制面板
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
         (draw-text (format "RECORDING EVENTS... [~a]" (automation-event-list-count aelist-ptr))
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

(close-window)
