#lang racket/base

;; raylib [textures] example - npatch drawing (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_npatch_drawing.c
;;
;; 演示: 9-patch / 3-patch 纹理拉伸
;;   NPatchInfo 按值传递 (list: src-x src-y src-w src-h left top right bottom layout)
;;   移动鼠标可动态调整 n-patch 目标矩形大小

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 资源路径
;; ============================================================

(define resource-dir
  (path->string (build-path (current-directory) "../../../examples/textures/resources/")))

;; ============================================================
;; NPatchInfo 按值传递 → list (src-x src-y src-w src-h left top right bottom layout)
;; ============================================================

(define (npatch src-x src-y src-w src-h left top right bottom layout)
  (list src-x src-y src-w src-h left top right bottom layout))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [textures] example - npatch drawing")

(define n-patch-texture
  (load-texture (string-append resource-dir "ninepatch_button.png")))

;; 目标矩形 (随鼠标变化)
(define dst-rec1 (rectangle 480.0 160.0 32.0 32.0))
(define dst-rec2 (rectangle 160.0 160.0 32.0 32.0))
(define dst-rec-h (rectangle 160.0 93.0  32.0 32.0))
(define dst-rec-v (rectangle 92.0  160.0 32.0 32.0))

;; 9-patch: 双向拉伸
(define nine-patch1 (npatch 0.0   0.0 64.0 64.0 12 40 12 12 NPATCH-NINE-PATCH))
(define nine-patch2 (npatch 0.0 128.0 64.0 64.0 16 16 16 16 NPATCH-NINE-PATCH))

;; 3-patch horizontal: 仅水平拉伸
(define h3-patch (npatch 0.0  64.0 64.0 64.0 8 8 8 8 NPATCH-THREE-PATCH-HORIZONTAL))

;; 3-patch vertical: 仅垂直拉伸
(define v3-patch (npatch 0.0 192.0 64.0 64.0 6 6 6 6 NPATCH-THREE-PATCH-VERTICAL))

(define origin (vector2 0.0 0.0))

(set-target-fps 60)

;; ============================================================
;; 辅助: 限制范围
;; ============================================================

(define (clamp v lo hi)
  (max lo (min v hi)))

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新 — 根据鼠标位置调整 n-patch 大小
    (let* ([mp (get-mouse-position)]
           [mx (vector2-x mp)]
           [my (vector2-y mp)])

      (set-rectangle-w! dst-rec1 (clamp (- mx (rectangle-x dst-rec1)) 1.0 300.0))
      (set-rectangle-h! dst-rec1 (clamp (- my (rectangle-y dst-rec1)) 1.0 300.0))
      (set-rectangle-w! dst-rec2 (clamp (- mx (rectangle-x dst-rec2)) 1.0 300.0))
      (set-rectangle-h! dst-rec2 (clamp (- my (rectangle-y dst-rec2)) 1.0 300.0))
      (set-rectangle-w! dst-rec-h (clamp (- mx (rectangle-x dst-rec-h)) 1.0 300.0))
      (set-rectangle-h! dst-rec-v (clamp (- my (rectangle-y dst-rec-v)) 1.0 300.0))

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)

      ;; 绘制 n-patches
      (draw-texture-n-patch n-patch-texture nine-patch2 dst-rec2 origin 0.0 WHITE)
      (draw-texture-n-patch n-patch-texture nine-patch1 dst-rec1 origin 0.0 WHITE)
      (draw-texture-n-patch n-patch-texture h3-patch    dst-rec-h origin 0.0 WHITE)
      (draw-texture-n-patch n-patch-texture v3-patch    dst-rec-v origin 0.0 WHITE)

      ;; 绘制源纹理预览
      (draw-rectangle-lines 5 88 74 266 BLUE)
      (draw-texture n-patch-texture 10 93 WHITE)
      (draw-text "TEXTURE" 15 360 10 DARKGRAY)

      (draw-text "Move the mouse to stretch or shrink the n-patches" 10 20 20 DARKGRAY)

      (end-drawing)
      (loop))))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture n-patch-texture)
(close-window)
