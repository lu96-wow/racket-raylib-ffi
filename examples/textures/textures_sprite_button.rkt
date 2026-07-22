#lang racket/base

;; raylib [textures] example - sprite button (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_sprite_button.c
;;
;; 演示: 使用纹理制作可交互按钮
;;   包含声音反馈、悬停/按下状态切换

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define-runtime-path resource-dir-path
  "../../../examples/textures/resources/")
(define resource-dir (path->string resource-dir-path))

;; ============================================================
;; 资源路径
;; ============================================================

;; ============================================================
;; 常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define num-frames 3)  ;; 按钮精灵纹理的帧数

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - sprite button")

(init-audio-device)

(define fx-button (load-sound (string-append resource-dir "buttonfx.wav")))
(define button-tex (load-texture (string-append resource-dir "button.png")))

;; 计算每帧高度并定义源矩形
(define frame-height (/ (list-ref button-tex 2) num-frames 1.0))
(define source-rec (rectangle 0.0 0.0 (list-ref button-tex 1) frame-height))

;; 定义按钮在屏幕上的位置
(define btn-bounds
  (rectangle (- (/ screen-width 2.0) (/ (list-ref button-tex 1) 2.0))
             (- (/ screen-height 2.0) (/ frame-height 2.0))
             (list-ref button-tex 1)
             frame-height))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ([btn-state 0])
  (unless (window-should-close?)
    ;; 更新
    (let* ([mouse-point (get-mouse-position)]
           [mouse-x (vector2-x mouse-point)]
           [mouse-y (vector2-y mouse-point)]
           [colliding (check-collision-point-rec mouse-point btn-bounds)]
           [btn-state
            (cond
              [(and colliding (is-mouse-button-down MOUSE-BUTTON-LEFT)) 2]
              [colliding 1]
              [else 0])]
           [btn-action (and colliding (is-mouse-button-released MOUSE-BUTTON-LEFT))])

      ;; 按钮动作
      (when btn-action
        (play-sound fx-button))

      ;; 根据状态切换源矩形的 y 偏移（每帧有不同的纹理区域）
      (set-rectangle-y! source-rec (* btn-state frame-height))

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)

      ;; 绘制按钮纹理帧
      (draw-texture-rec button-tex source-rec
                        (vector2 (rectangle-x btn-bounds) (rectangle-y btn-bounds))
                        WHITE)

      (end-drawing)
      (loop btn-state))))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture button-tex)
(unload-sound fx-button)
(close-audio-device)
(close-window)
