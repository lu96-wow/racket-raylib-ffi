#lang racket/base

;; raylib [textures] example - srcrec dstrec (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_srcrec_dstrec.c
;;
;; 演示: DrawTexturePro 使用源矩形(source rect)、目标矩形(dest rect)、
;;   旋转中心和旋转角度进行高级纹理绘制
;;   纹理: scarfy.png (6 帧精灵表，取第一帧)

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 资源路径
;; ============================================================

(define resource-dir
  (path->string (build-path (current-directory) "../../../examples/textures/resources/")))

;; ============================================================
;; 常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - srcrec dstrec")

;; NOTE: 纹理必须在窗口初始化后加载（需要 OpenGL 上下文）
(define scarfy (load-texture (string-append resource-dir "scarfy.png")))

;; scarfy.png 是 6 帧精灵表（6×1），取一帧的宽高
(define frame-width (quotient (list-ref scarfy 1) 6))   ;; texture.width / 6
(define frame-height (list-ref scarfy 2))                 ;; texture.height

;; 源矩形：从纹理中取哪一部分来绘制
(define source-rec (rectangle 0.0 0.0
                              (exact->inexact frame-width)
                              (exact->inexact frame-height)))

;; 目标矩形：在屏幕的什么位置、以什么尺寸绘制
(define dest-rec (rectangle (/ screen-width 2.0)
                            (/ screen-height 2.0)
                            (* frame-width 2.0)
                            (* frame-height 2.0)))

;; 旋转/缩放中心点（相对于目标矩形）
(define origin (vector2 (exact->inexact frame-width)
                        (exact->inexact frame-height)))

(define rotation 0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (set! rotation (add1 rotation))

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; NOTE: DrawTexturePro 可以轻松旋转和缩放纹理的一部分
    ;;   source-rec: 定义纹理中用于绘制的部分
    ;;   dest-rec:   定义纹理部分在屏幕上的目标矩形（缩放以适配）
    ;;   origin:     旋转/缩放的参考点（相对于目标矩形）
    ;;   rotation:   旋转角度（以 origin 为旋转中心）
    (draw-texture-pro scarfy
                      source-rec
                      dest-rec
                      origin
                      (exact->inexact rotation)
                      WHITE)

    ;; 绘制目标矩形中心的十字参考线
    (draw-line (inexact->exact (rectangle-x dest-rec)) 0
               (inexact->exact (rectangle-x dest-rec)) screen-height GRAY)
    (draw-line 0 (inexact->exact (rectangle-y dest-rec))
               screen-width (inexact->exact (rectangle-y dest-rec)) GRAY)

    (draw-text "(c) Scarfy sprite by Eiden Marsal"
               (- screen-width 200) (- screen-height 20) 10 GRAY)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture scarfy)
(close-window)
