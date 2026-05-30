#lang racket/base

;; raylib [core] example - window web
;;
;; 对应 C: examples/core/core_window_web.c
;;
;; 展示适用于 Web/Desktop 的窗口结构：
;;   - 将 Update/Draw 逻辑封装在独立函数中
;;   - Desktop 上用 while 循环调用
;;   - Web 上可用 emscripten_set_main_loop（本 Racket 版省略）

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 全局变量
;; ============================================================

(define screen-width 800)
(define screen-height 450)

;; ============================================================
;; 更新和绘制一帧
;; ============================================================

(define (update-draw-frame)
  ;; 更新（本例无变量需要更新）

  ;; 绘制
  (begin-drawing)
  (clear-background RAYWHITE)
  (draw-text "Welcome to raylib web structure!" 220 200 20 SKYBLUE)
  (end-drawing))

;; ============================================================
;; 主程序
;; ============================================================

(define (main)
  ;; 初始化
  (init-window screen-width screen-height
    "raylib [core] example - window web")
  (set-target-fps 60)

  ;; 主循环
  (let loop ()
    (unless (window-should-close?)
      (update-draw-frame)
      (loop)))

  ;; 清理
  (close-window))

;; 运行
(main)
