#lang racket/base

;; raylib [core] example - input actions (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_input_actions.c
;;
;; 演示: 将键盘/手柄输入映射为"动作" (Action)，支持按键重映射
;;   TAB - 切换按键方案 (WASD ↔ 方向键)
;;   方向键/WASD - 移动方块
;;   Space/手柄B - 复位 (FIRE)

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 动作枚举
;; ============================================================

(define NO-ACTION   0)
(define ACTION-UP   1)
(define ACTION-DOWN 2)
(define ACTION-LEFT 3)
(define ACTION-RIGHT 4)
(define ACTION-FIRE 5)
(define MAX-ACTION  6)

;; ============================================================
;; 全局状态
;; ============================================================

(define gamepad-index 0)
(define action-inputs (make-vector MAX-ACTION #f))

;; ActionInput: (key . button)
(define (make-action-input key button) (cons key button))
(define (action-key ai)   (car ai))
(define (action-button ai) (cdr ai))

;; ============================================================
;; 动作检测函数
;; ============================================================

(define (is-action-pressed? action)
  (and (< action MAX-ACTION)
       (let ([ai (vector-ref action-inputs action)])
         (or (is-key-pressed (action-key ai))
             (is-gamepad-button-pressed gamepad-index (action-button ai))))))

(define (is-action-released? action)
  (and (< action MAX-ACTION)
       (let ([ai (vector-ref action-inputs action)])
         (or (is-key-released (action-key ai))
             (is-gamepad-button-released gamepad-index (action-button ai))))))

(define (is-action-down? action)
  (and (< action MAX-ACTION)
       (let ([ai (vector-ref action-inputs action)])
         (or (is-key-down (action-key ai))
             (is-gamepad-button-down gamepad-index (action-button ai))))))

;; ============================================================
;; 按键方案
;; ============================================================

(define (set-actions-default!)
  (vector-set! action-inputs ACTION-UP    (make-action-input KEY-W  GAMEPAD-BUTTON-LEFT-FACE-UP))
  (vector-set! action-inputs ACTION-DOWN  (make-action-input KEY-S  GAMEPAD-BUTTON-LEFT-FACE-DOWN))
  (vector-set! action-inputs ACTION-LEFT  (make-action-input KEY-A  GAMEPAD-BUTTON-LEFT-FACE-LEFT))
  (vector-set! action-inputs ACTION-RIGHT (make-action-input KEY-D  GAMEPAD-BUTTON-LEFT-FACE-RIGHT))
  (vector-set! action-inputs ACTION-FIRE  (make-action-input KEY-SPACE GAMEPAD-BUTTON-RIGHT-FACE-DOWN)))

(define (set-actions-cursor!)
  (vector-set! action-inputs ACTION-UP    (make-action-input KEY-UP    GAMEPAD-BUTTON-RIGHT-FACE-UP))
  (vector-set! action-inputs ACTION-DOWN  (make-action-input KEY-DOWN  GAMEPAD-BUTTON-RIGHT-FACE-DOWN))
  (vector-set! action-inputs ACTION-LEFT  (make-action-input KEY-LEFT  GAMEPAD-BUTTON-RIGHT-FACE-LEFT))
  (vector-set! action-inputs ACTION-RIGHT (make-action-input KEY-RIGHT GAMEPAD-BUTTON-RIGHT-FACE-RIGHT))
  (vector-set! action-inputs ACTION-FIRE  (make-action-input KEY-SPACE GAMEPAD-BUTTON-LEFT-FACE-DOWN)))

;; ============================================================
;; 初始化
;; ============================================================

(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - input actions")

(set-actions-default!)
(define action-set (box 0))

(define position (vector2 400.0 200.0))
(define size     (vector2 40.0 40.0))
(define release-action (box #f))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)

    ;; === 更新 ===
    (when (is-action-down? ACTION-UP)    (set-vector2-y! position (- (vector2-y position) 2)))
    (when (is-action-down? ACTION-DOWN)  (set-vector2-y! position (+ (vector2-y position) 2)))
    (when (is-action-down? ACTION-LEFT)  (set-vector2-x! position (- (vector2-x position) 2)))
    (when (is-action-down? ACTION-RIGHT) (set-vector2-x! position (+ (vector2-x position) 2)))

    (when (is-action-pressed? ACTION-FIRE)
      (set-vector2-x! position (/ (- SCREEN-WIDTH (vector2-x size)) 2))
      (set-vector2-y! position (/ (- SCREEN-HEIGHT (vector2-y size)) 2)))

    ;; 检测释放 (仅一帧)
    (set-box! release-action (is-action-released? ACTION-FIRE))

    ;; 切换按键方案
    (when (is-key-pressed KEY-TAB)
      (set-box! action-set (if (zero? (unbox action-set)) 1 0))
      (if (zero? (unbox action-set))
        (set-actions-default!)
        (set-actions-cursor!)))

    ;; === 绘制 ===
    (begin-drawing)
    (clear-background GRAY)

    (draw-rectangle-v position size (if (unbox release-action) BLUE RED))

    (draw-text (if (zero? (unbox action-set))
                 "Current input set: WASD (default)"
                 "Current input set: Arrow keys")
               10 10 20 WHITE)
    (draw-text "Use TAB key to toggles Actions keyset" 10 50 20 GREEN)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
