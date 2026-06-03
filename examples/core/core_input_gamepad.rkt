#lang racket/base

;; raylib [core] example - input gamepad (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_input_gamepad.c
;;
;; NOTE: 需要连接手柄到系统
;;       支持 Xbox 360/One、PS3 手柄

(require racket/string
         racket/format
         "../../raylib/raylib.rkt")

;; ============================================================
;; 常量 — 手柄名称匹配
;; ============================================================

(define XBOX-ALIAS-1 "xbox")
(define XBOX-ALIAS-2 "x-box")
(define PS-ALIAS-1   "playstation")
(define PS-ALIAS-2   "sony")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(set-config-flags FLAG-MSAA-4X-HINT)

(init-window screen-width screen-height
             "raylib [core] example - input gamepad")

(define tex-ps3-pad
  (load-texture "../../../../examples/core/resources/ps3.png"))
(define tex-xbox-pad
  (load-texture "../../../../examples/core/resources/xbox.png"))

(define left-stick-deadzone-x  0.1)
(define left-stick-deadzone-y  0.1)
(define right-stick-deadzone-x 0.1)
(define right-stick-deadzone-y 0.1)
(define left-trigger-deadzone  -0.9)
(define right-trigger-deadzone -0.9)

(set-target-fps 60)

(define (apply-deadzone val deadzone)
  (if (and (> val (- deadzone)) (< val deadzone)) 0.0 val))

(define (trigger-deadzone val deadzone)
  (if (< val deadzone) -1.0 val))
;; ============================================================
;; 主循环
;; ============================================================

(let loop ([gamepad 0])
  (unless (window-should-close?)
    ;; === 更新 ===
    (define new-gamepad
      (cond
        [(and (is-key-pressed KEY-LEFT)  (> gamepad 0)) (sub1 gamepad)]
        [(is-key-pressed KEY-RIGHT) (add1 gamepad)]
        [else gamepad]))

    (define mouse-position (get-mouse-position))

    (define vibrate-button
      (rectangle 10
                 (+ 70 (* 20 (get-gamepad-axis-count new-gamepad)) 20)
                 75 24))

    (when (and (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
               (check-collision-point-rec mouse-position vibrate-button))
      (set-gamepad-vibration new-gamepad 1.0 1.0 1.0))

    ;; === 绘制 ===
    (begin-drawing)
    (clear-background RAYWHITE)


    (cond
      [(is-gamepad-available? new-gamepad)
       (let* ([gp-name (get-gamepad-name new-gamepad)]
              [gp-name-lower (string-downcase gp-name)]
              [left-stick-x  (apply-deadzone
                              (get-gamepad-axis-movement new-gamepad GAMEPAD-AXIS-LEFT-X)
                              left-stick-deadzone-x)]
              [left-stick-y  (apply-deadzone
                              (get-gamepad-axis-movement new-gamepad GAMEPAD-AXIS-LEFT-Y)
                              left-stick-deadzone-y)]
              [right-stick-x (apply-deadzone
                              (get-gamepad-axis-movement new-gamepad GAMEPAD-AXIS-RIGHT-X)
                              right-stick-deadzone-x)]
              [right-stick-y (apply-deadzone
                              (get-gamepad-axis-movement new-gamepad GAMEPAD-AXIS-RIGHT-Y)
                              right-stick-deadzone-y)]
              [left-trigger  (trigger-deadzone
                              (get-gamepad-axis-movement new-gamepad GAMEPAD-AXIS-LEFT-TRIGGER)
                              left-trigger-deadzone)]
              [right-trigger (trigger-deadzone
                              (get-gamepad-axis-movement new-gamepad GAMEPAD-AXIS-RIGHT-TRIGGER)
                              right-trigger-deadzone)])

         (draw-text (~a "GP" new-gamepad ": " gp-name) 10 10 10 BLACK)

         (cond
           ;; --- Xbox 布局 ---
           [(or (string-contains? gp-name-lower XBOX-ALIAS-1)
                (string-contains? gp-name-lower XBOX-ALIAS-2))
            (draw-texture tex-xbox-pad 0 0 DARKGRAY)

            ;; home
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-MIDDLE)
              (draw-circle 394 89 19.0 RED))

            ;; basic
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-MIDDLE-RIGHT)
              (draw-circle 436 150 9.0 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-MIDDLE-LEFT)
              (draw-circle 352 150 9.0 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-FACE-LEFT)
              (draw-circle 501 151 15.0 BLUE))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-FACE-DOWN)
              (draw-circle 536 187 15.0 LIME))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-FACE-RIGHT)
              (draw-circle 572 151 15.0 MAROON))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-FACE-UP)
              (draw-circle 536 115 15.0 GOLD))

            ;; d-pad
            (draw-rectangle 317 202 19 71 BLACK)
            (draw-rectangle 293 228 69 19 BLACK)
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-FACE-UP)
              (draw-rectangle 317 202 19 26 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-FACE-DOWN)
              (draw-rectangle 317 247 19 26 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-FACE-LEFT)
              (draw-rectangle 292 228 25 19 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-FACE-RIGHT)
              (draw-rectangle 336 228 26 19 RED))

            ;; triggers
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-TRIGGER-1)
              (draw-circle 259 61 20.0 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-TRIGGER-1)
              (draw-circle 536 61 20.0 RED))

            ;; left joystick
            (let ([lc (if (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-THUMB)
                          RED BLACK)])
              (draw-circle 259 152 39.0 BLACK)
              (draw-circle 259 152 34.0 LIGHTGRAY)
              (draw-circle (+ 259 (inexact->exact (round (* left-stick-x 20))))
                           (+ 152 (inexact->exact (round (* left-stick-y 20))))
                           25.0 lc))

            ;; right joystick
            (let ([rc (if (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-THUMB)
                          RED BLACK)])
              (draw-circle 461 237 38.0 BLACK)
              (draw-circle 461 237 33.0 LIGHTGRAY)
              (draw-circle (+ 461 (inexact->exact (round (* right-stick-x 20))))
                           (+ 237 (inexact->exact (round (* right-stick-y 20))))
                           25.0 rc))

            ;; trigger bars
            (draw-rectangle 170 30 15 70 GRAY)
            (draw-rectangle 604 30 15 70 GRAY)
            (draw-rectangle 170 30 15
                            (inexact->exact (round (* (/ (+ 1 left-trigger) 2) 70))) RED)
            (draw-rectangle 604 30 15
                            (inexact->exact (round (* (/ (+ 1 right-trigger) 2) 70))) RED)]
           ;; --- PS 布局 ---
           [(or (string-contains? gp-name-lower PS-ALIAS-1)
                (string-contains? gp-name-lower PS-ALIAS-2))
            (draw-texture tex-ps3-pad 0 0 DARKGRAY)

            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-MIDDLE)
              (draw-circle 396 222 13.0 RED))

            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-MIDDLE-LEFT)
              (draw-rectangle 328 170 32 13 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-MIDDLE-RIGHT)
              (draw-triangle (vector2 436 168) (vector2 436 185) (vector2 464 177) RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-FACE-UP)
              (draw-circle 557 144 13.0 LIME))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-FACE-RIGHT)
              (draw-circle 586 173 13.0 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-FACE-DOWN)
              (draw-circle 557 203 13.0 VIOLET))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-FACE-LEFT)
              (draw-circle 527 173 13.0 PINK))

            (draw-rectangle 225 132 24 84 BLACK)
            (draw-rectangle 195 161 84 25 BLACK)
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-FACE-UP)
              (draw-rectangle 225 132 24 29 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-FACE-DOWN)
              (draw-rectangle 225 186 24 30 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-FACE-LEFT)
              (draw-rectangle 195 161 30 25 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-FACE-RIGHT)
              (draw-rectangle 249 161 30 25 RED))

            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-TRIGGER-1)
              (draw-circle 239 82 20.0 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-TRIGGER-1)
              (draw-circle 557 82 20.0 RED))



            (let ([lc (if (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-THUMB)
                          RED BLACK)])
              (draw-circle 319 255 35.0 BLACK)
              (draw-circle 319 255 31.0 LIGHTGRAY)
              (draw-circle (+ 319 (inexact->exact (round (* left-stick-x 20))))
                           (+ 255 (inexact->exact (round (* left-stick-y 20))))
                           25.0 lc))

            (let ([rc (if (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-THUMB)
                          RED BLACK)])
              (draw-circle 475 255 35.0 BLACK)
              (draw-circle 475 255 31.0 LIGHTGRAY)
              (draw-circle (+ 475 (inexact->exact (round (* right-stick-x 20))))
                           (+ 255 (inexact->exact (round (* right-stick-y 20))))
                           25.0 rc))

            (draw-rectangle 169 48 15 70 GRAY)
            (draw-rectangle 611 48 15 70 GRAY)
            (draw-rectangle 169 48 15
                            (inexact->exact (round (* (/ (+ 1 left-trigger) 2) 70))) RED)
            (draw-rectangle 611 48 15
                            (inexact->exact (round (* (/ (+ 1 right-trigger) 2) 70))) RED)]



           ;; --- 通用布局 ---
           [else
            (draw-rectangle-rounded (rectangle 175 110 460 220) 0.3 16 DARKGRAY)

            (draw-circle 365 170 12.0 RAYWHITE)
            (draw-circle 405 170 12.0 RAYWHITE)
            (draw-circle 445 170 12.0 RAYWHITE)
            (draw-circle 516 191 17.0 RAYWHITE)
            (draw-circle 551 227 17.0 RAYWHITE)
            (draw-circle 587 191 17.0 RAYWHITE)
            (draw-circle 551 155 17.0 RAYWHITE)
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-MIDDLE-LEFT)
              (draw-circle 365 170 10.0 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-MIDDLE)
              (draw-circle 405 170 10.0 GREEN))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-MIDDLE-RIGHT)
              (draw-circle 445 170 10.0 BLUE))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-FACE-LEFT)
              (draw-circle 516 191 15.0 GOLD))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-FACE-DOWN)
              (draw-circle 551 227 15.0 BLUE))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-FACE-RIGHT)
              (draw-circle 587 191 15.0 GREEN))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-FACE-UP)
              (draw-circle 551 155 15.0 RED))

            (draw-rectangle 245 145 28 88 RAYWHITE)
            (draw-rectangle 215 174 88 29 RAYWHITE)
            (draw-rectangle 247 147 24 84 BLACK)
            (draw-rectangle 217 176 84 25 BLACK)
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-FACE-UP)
              (draw-rectangle 247 147 24 29 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-FACE-DOWN)
              (draw-rectangle 247 201 24 30 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-FACE-LEFT)
              (draw-rectangle 217 176 30 25 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-FACE-RIGHT)
              (draw-rectangle 271 176 30 25 RED))

            (draw-rectangle-rounded (rectangle 215 98 100 10) 0.5 16 DARKGRAY)
            (draw-rectangle-rounded (rectangle 495 98 100 10) 0.5 16 DARKGRAY)
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-TRIGGER-1)
              (draw-rectangle-rounded (rectangle 215 98 100 10) 0.5 16 RED))
            (when (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-TRIGGER-1)
              (draw-rectangle-rounded (rectangle 495 98 100 10) 0.5 16 RED))


            (let ([lc (if (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-LEFT-THUMB)
                          RED BLACK)])
              (draw-circle 345 260 40.0 BLACK)
              (draw-circle 345 260 35.0 LIGHTGRAY)
              (draw-circle (+ 345 (inexact->exact (round (* left-stick-x 20))))
                           (+ 260 (inexact->exact (round (* left-stick-y 20))))
                           25.0 lc))

            (let ([rc (if (is-gamepad-button-down new-gamepad GAMEPAD-BUTTON-RIGHT-THUMB)
                          RED BLACK)])
              (draw-circle 465 260 40.0 BLACK)
              (draw-circle 465 260 35.0 LIGHTGRAY)
              (draw-circle (+ 465 (inexact->exact (round (* right-stick-x 20))))
                           (+ 260 (inexact->exact (round (* right-stick-y 20))))
                           25.0 rc))

            (draw-rectangle 151 110 15 70 GRAY)
            (draw-rectangle 644 110 15 70 GRAY)
            (draw-rectangle 151 110 15
                            (inexact->exact (round (* (/ (+ 1 left-trigger) 2) 70))) RED)
            (draw-rectangle 644 110 15
                            (inexact->exact (round (* (/ (+ 1 right-trigger) 2) 70))) RED)])


         ;; 检测到的轴信息
         (draw-text (~a "DETECTED AXIS [" (get-gamepad-axis-count new-gamepad) "]:")
                    10 50 10 MAROON)

         (for ([i (in-range (get-gamepad-axis-count new-gamepad))])
           (draw-text
            (~a "AXIS " i ": "
                (~r (get-gamepad-axis-movement new-gamepad i) #:precision '(= 2)))
            20 (+ 70 (* 20 i)) 10 DARKGRAY))

         ;; 振动按钮
         (draw-rectangle
          (inexact->exact (round (rectangle-x vibrate-button)))
          (inexact->exact (round (rectangle-y vibrate-button)))
          (inexact->exact (round (rectangle-w vibrate-button)))
          (inexact->exact (round (rectangle-h vibrate-button)))
          SKYBLUE)
         (draw-text "VIBRATE"
                    (+ (inexact->exact (round (rectangle-x vibrate-button))) 14)
                    (+ (inexact->exact (round (rectangle-y vibrate-button))) 1)
                    10 DARKGRAY)

         ;; 最近按下的按钮
         (let ([btn (get-gamepad-button-pressed)])
           (if (= btn GAMEPAD-BUTTON-UNKNOWN)
               (draw-text "DETECTED BUTTON: NONE" 10 430 10 GRAY)
               (draw-text (~a "DETECTED BUTTON: " btn) 10 430 10 RED))))]

      ;; 手柄未检测到
      [else
       (draw-text (~a "GP" new-gamepad ": NOT DETECTED") 10 10 10 GRAY)
       (draw-texture tex-xbox-pad 0 0 LIGHTGRAY)])

    (end-drawing)

    (loop new-gamepad)))


;; ============================================================
;; 清理
;; ============================================================

(unload-texture tex-ps3-pad)
(unload-texture tex-xbox-pad)
(close-window)
