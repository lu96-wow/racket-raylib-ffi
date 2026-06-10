#lang racket/base
;; raylib [shapes] example - lines drawing (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_lines_drawing.c
;; 左键拖拽画彩色线，右键拖拽擦除，滚轮调粗细，中键清屏

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [shapes] example - lines drawing")

;; 提示文字是否显示
(define start-text? (box #t))

;; 上一帧鼠标位置 (Vector2)
(define mouse-pos-prev (get-mouse-position))

;; 画布 RenderTexture (11 元素 list)
(define canvas (load-render-texture screen-width screen-height))

;; 画线粗细
(define line-thickness (box 8.0))

;; 颜色色相 (HSV, 0-360)
(define line-hue (box 0.0))

;; 清画布
(begin-texture-mode canvas)
(clear-background RAYWHITE)
(end-texture-mode)

;; 从 RenderTexture list 提取内嵌 Texture (5 元素 list: id w h mipmaps format)
(define (rt->texture rt)
  (list (list-ref rt 1) (list-ref rt 2) (list-ref rt 3)
        (list-ref rt 4) (list-ref rt 5)))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()
  (unless (window-should-close?)
    ;; --- 更新 ---

    ;; 点击后隐藏提示文字
    (when (and (is-mouse-button-pressed MOUSE-BUTTON-LEFT) (unbox start-text?))
      (set-box! start-text? #f))

    ;; 中键清屏
    (when (is-mouse-button-pressed MOUSE-BUTTON-MIDDLE)
      (begin-texture-mode canvas)
      (clear-background RAYWHITE)
      (end-texture-mode))

    (define left-down?  (is-mouse-button-down MOUSE-BUTTON-LEFT))
    (define right-down? (is-mouse-button-down MOUSE-BUTTON-RIGHT))

    (when (or left-down? right-down?)
      (define draw-color
        (if left-down?
            (begin
              ;; 根据鼠标移动距离更新色相
              (set-box! line-hue
                (+ (unbox line-hue)
                   (/ (vec2-length (vec2-subtract (get-mouse-position) mouse-pos-prev)) 3.0)))
              ;; 将色相保持在 [0, 360)
              (let loop-hue ()
                (when (>= (unbox line-hue) 360.0)
                  (set-box! line-hue (- (unbox line-hue) 360.0))
                  (loop-hue)))
              (color-from-hsv (unbox line-hue) 1.0 1.0))
            RAYWHITE))  ;; 右键作为擦除

      ;; 画线到画布
      (begin-texture-mode canvas)
      (draw-circle-v mouse-pos-prev (/ (unbox line-thickness) 2.0) draw-color)
      (draw-circle-v (get-mouse-position) (/ (unbox line-thickness) 2.0) draw-color)
      (draw-line-ex mouse-pos-prev (get-mouse-position) (unbox line-thickness) draw-color)
      (end-texture-mode))

    ;; 滚轮调整粗细
    (set-box! line-thickness (+ (unbox line-thickness) (get-mouse-wheel-move)))
    (set-box! line-thickness (clamp (unbox line-thickness) 1.0 500.0))

    ;; 更新上一帧鼠标位置
    (let ([cur-pos (get-mouse-position)])
      (ptr-set! mouse-pos-prev _float 0 (ptr-ref cur-pos _float 0))
      (ptr-set! mouse-pos-prev _float 1 (ptr-ref cur-pos _float 1)))

    ;; --- 绘制 ---
    (begin-drawing)

    ;; 把画布贴到屏幕上 (纵轴翻转以补偿 OpenGL 坐标系)
    (draw-texture-rec (rt->texture canvas)
                      (rectangle 0.0 0.0
                        (exact->inexact (list-ref canvas 2))
                        (exact->inexact (- (list-ref canvas 3))))
                      (vector2 0.0 0.0) WHITE)

    ;; 预览圆 (没按左键时显示)
    (unless left-down?
      (draw-circle-lines-v (get-mouse-position) (/ (unbox line-thickness) 2.0)
                           (fade WHITE 0.5)))

    ;; 提示文字
    (when (unbox start-text?)
      (draw-text "try clicking and dragging!" 275 215 20 LIGHTGRAY))

    (end-drawing)

    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-render-texture canvas)
(close-window)
