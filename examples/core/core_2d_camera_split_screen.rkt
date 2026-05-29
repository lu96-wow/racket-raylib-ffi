#lang racket/base

;; raylib [core] example - 2d camera split screen (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_2d_camera_split_screen.c
;;
;; 演示双人分屏:
;;   玩家 1 (红): W/S/A/D  移动
;;   玩家 2 (蓝): 方向键    移动
;;
;; 每个玩家使用独立的 Camera2D, 各自渲染到 RenderTexture,
;; 最后并排绘制到主屏幕。
;;
;; 新增 FFI 绑定:
;;   draw-line-v, load-render-texture, unload-render-texture,
;;   begin-texture-mode, end-texture-mode, draw-texture-rec

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define PLAYER-SIZE 40)
(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 440)

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - 2d camera split screen")

;; 两个玩家 (用 Rectangle 表示位置 + 大小)
(define player1 (rectangle 200.0 200.0 PLAYER-SIZE PLAYER-SIZE))
(define player2 (rectangle 250.0 200.0 PLAYER-SIZE PLAYER-SIZE))

;; 相机 1 (跟随玩家 1)
(define camera1
  (camera2d
    (+ (rectangle-x player1) 0.0)      ;; target-x
    (+ (rectangle-y player1) 0.0)      ;; target-y
    200.0                               ;; offset-x
    200.0                               ;; offset-y
    0.0                                 ;; rotation
    1.0))                               ;; zoom

;; 相机 2 (跟随玩家 2)
(define camera2
  (camera2d
    (+ (rectangle-x player2) 0.0)      ;; target-x
    (+ (rectangle-y player2) 0.0)      ;; target-y
    200.0                               ;; offset-x
    200.0                               ;; offset-y
    0.0                                 ;; rotation
    1.0))                               ;; zoom

;; 两个渲染纹理 (各占一半屏幕宽度)
(define screen-camera1 (load-render-texture (quotient SCREEN-WIDTH 2) SCREEN-HEIGHT))
(define screen-camera2 (load-render-texture (quotient SCREEN-WIDTH 2) SCREEN-HEIGHT))

;; 分屏矩形 (texture坐标, height为负=上下翻转)
(define split-screen-size
  (rectangle 0.0 0.0
    (exact->inexact SCREEN-WIDTH)
    (exact->inexact (- SCREEN-HEIGHT))))

(set-target-fps 60)

;; ============================================================
;; 辅助: 绘制网格 + 坐标文字
;; ============================================================

(define (draw-scene-grid)
  ;; 竖线
  (for ([i (in-range (add1 (quotient SCREEN-WIDTH PLAYER-SIZE)))])
    (define x (exact->inexact (* PLAYER-SIZE i)))
    (draw-line-v (vector2 x 0.0) (vector2 x (exact->inexact SCREEN-HEIGHT)) LIGHTGRAY))
  ;; 横线
  (for ([i (in-range (add1 (quotient SCREEN-HEIGHT PLAYER-SIZE)))])
    (define y (exact->inexact (* PLAYER-SIZE i)))
    (draw-line-v (vector2 0.0 y) (vector2 (exact->inexact SCREEN-WIDTH) y) LIGHTGRAY))
  ;; 网格坐标文字
  (for* ([i (in-range (quotient SCREEN-WIDTH PLAYER-SIZE))]
         [j (in-range (quotient SCREEN-HEIGHT PLAYER-SIZE))])
    (draw-text (format "[~a,~a]" i j)
               (+ 10 (* PLAYER-SIZE i))
               (+ 15 (* PLAYER-SIZE j))
               10 LIGHTGRAY)))

;; 从 RenderTexture list 中提取 texture 子列表 (5 元素)
;; RenderTexture layout: (id tex-id tex-w tex-h tex-mip tex-fmt dep-id dep-w dep-h dep-mip dep-fmt)
;; Texture:              (id    w      h     mip    fmt)
(define (rt->texture rt)
  (list (list-ref rt 1) (list-ref rt 2) (list-ref rt 3)
        (list-ref rt 4) (list-ref rt 5)))

;; ============================================================
;; 主循环
;; ============================================================

(let game-loop ()
  (unless (window-should-close?)
    ;; --- 更新 ---

    ;; 玩家 1: W/S/A/D
    (when (is-key-down KEY-W) (set-rectangle-y! player1 (- (rectangle-y player1) 3.0)))
    (when (is-key-down KEY-S) (set-rectangle-y! player1 (+ (rectangle-y player1) 3.0)))
    (when (is-key-down KEY-A) (set-rectangle-x! player1 (- (rectangle-x player1) 3.0)))
    (when (is-key-down KEY-D) (set-rectangle-x! player1 (+ (rectangle-x player1) 3.0)))

    ;; 玩家 2: 方向键
    (when (is-key-down KEY-UP)    (set-rectangle-y! player2 (- (rectangle-y player2) 3.0)))
    (when (is-key-down KEY-DOWN)  (set-rectangle-y! player2 (+ (rectangle-y player2) 3.0)))
    (when (is-key-down KEY-LEFT)  (set-rectangle-x! player2 (- (rectangle-x player2) 3.0)))
    (when (is-key-down KEY-RIGHT) (set-rectangle-x! player2 (+ (rectangle-x player2) 3.0)))

    ;; 更新相机 target 跟随玩家
    (set-camera2d-target-x! camera1 (rectangle-x player1))
    (set-camera2d-target-y! camera1 (rectangle-y player1))
    (set-camera2d-target-x! camera2 (rectangle-x player2))
    (set-camera2d-target-y! camera2 (rectangle-y player2))

    ;; --- 绘制到纹理 1 (玩家 1 视角) ---
    (begin-texture-mode screen-camera1)
    (clear-background RAYWHITE)

    (begin-mode-2d camera1)
    (draw-scene-grid)
    (draw-rectangle-rec player1 RED)
    (draw-rectangle-rec player2 BLUE)
    (end-mode-2d)

    ;; HUD
    (define hud-w (get-screen-width))
    (draw-rectangle 0 0 (quotient hud-w 2) 30 (fade RAYWHITE 0.6))
    (draw-text "PLAYER1: W/S/A/D to move" 10 10 10 MAROON)

    (end-texture-mode)

    ;; --- 绘制到纹理 2 (玩家 2 视角) ---
    (begin-texture-mode screen-camera2)
    (clear-background RAYWHITE)

    (begin-mode-2d camera2)
    (draw-scene-grid)
    (draw-rectangle-rec player1 RED)
    (draw-rectangle-rec player2 BLUE)
    (end-mode-2d)

    ;; HUD
    (draw-rectangle 0 0 (quotient hud-w 2) 30 (fade RAYWHITE 0.6))
    (draw-text "PLAYER2: UP/DOWN/LEFT/RIGHT to move" 10 10 10 DARKBLUE)

    (end-texture-mode)

    ;; --- 合并绘制到主屏幕 ---
    (begin-drawing)
    (clear-background BLACK)

    (define tex1 (rt->texture screen-camera1))
    (define tex2 (rt->texture screen-camera2))

    (draw-texture-rec tex1 split-screen-size (vector2 0.0 0.0) WHITE)
    (draw-texture-rec tex2 split-screen-size
                      (vector2 (exact->inexact (quotient SCREEN-WIDTH 2)) 0.0) WHITE)

    ;; 中间分割线
    (draw-rectangle (- (quotient SCREEN-WIDTH 2) 2) 0 4 SCREEN-HEIGHT LIGHTGRAY)

    (end-drawing)

    (game-loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-render-texture screen-camera1)
(unload-render-texture screen-camera2)
(close-window)

