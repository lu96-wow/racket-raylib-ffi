#lang racket/base

;; raylib [core] example - viewport scaling (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_viewport_scaling.c
;;
;; 演示: 多种视口缩放模式 (整数缩放/非整数缩放/保持宽高比等)
;;
;; 示例复杂度: [★★☆☆] 2/4

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define RESOLUTION-COUNT 4)
(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)

;; ViewportType enum
(define KEEP-ASPECT-INTEGER 0)
(define KEEP-HEIGHT-INTEGER 1)
(define KEEP-WIDTH-INTEGER  2)
(define KEEP-ASPECT         3)
(define KEEP-HEIGHT         4)
(define KEEP-WIDTH          5)
(define VIEWPORT-TYPE-COUNT 6)

(define viewport-type-names
  (vector "KEEP_ASPECT_INTEGER"
          "KEEP_HEIGHT_INTEGER"
          "KEEP_WIDTH_INTEGER"
          "KEEP_ASPECT"
          "KEEP_HEIGHT"
          "KEEP_WIDTH"))

;; 预设分辨率列表
(define resolution-list
  (list (vector2 64 64)
        (vector2 256 240)
        (vector2 320 180)
        (vector2 3840 2160)))  ;; 4K 不支持整数缩放, 仅作演示

;; ============================================================
;; 辅助: 从 RenderTexture 列表提取 Texture 子列表
;; ============================================================

(define (rt->texture rt)
  (list (list-ref rt 1) (list-ref rt 2) (list-ref rt 3)
        (list-ref rt 4) (list-ref rt 5)))

;; ============================================================
;; Viewport 计算函数
;; ============================================================

;; 辅助: 对正数 float 做 (int) 截断再转回 float (模拟 C 的 (float)(int)(x))
(define (trunc-float x)
  (exact->inexact (inexact->exact (truncate x))))

;; 辅助: 标准化 source rect (上下翻转)
(define (setup-source-rect! src game-w game-h flip-y?)
  (set-rectangle-x! src 0.0)
  (set-rectangle-y! src (if flip-y? (exact->inexact game-h) 0.0))
  (set-rectangle-w! src (exact->inexact game-w))
  (set-rectangle-h! src (exact->inexact (if flip-y? (- game-h) game-h))))

;; --- 整数缩放模式 ---

(define (keep-aspect-centered-integer screen-w screen-h game-w game-h src dst)
  (setup-source-rect! src game-w game-h #t)
  (define ratio-x (quotient screen-w game-w))
  (define ratio-y (quotient screen-h game-h))
  (define resize-ratio (exact->inexact (if (< ratio-x ratio-y) ratio-x ratio-y)))
  (set-rectangle-x! dst (trunc-float (* (- screen-w (* game-w resize-ratio)) 0.5)))
  (set-rectangle-y! dst (trunc-float (* (- screen-h (* game-h resize-ratio)) 0.5)))
  (set-rectangle-w! dst (trunc-float (* game-w resize-ratio)))
  (set-rectangle-h! dst (trunc-float (* game-h resize-ratio))))

(define (keep-height-centered-integer screen-w screen-h game-w game-h src dst)
  (define resize-ratio (/ (exact->inexact screen-h) (exact->inexact game-h)))
  (set-rectangle-x! src 0.0)
  (set-rectangle-y! src 0.0)
  (set-rectangle-w! src (trunc-float (/ screen-w resize-ratio)))
  (set-rectangle-h! src (exact->inexact (- game-h)))
  (set-rectangle-x! dst (trunc-float (* (- screen-w (* (rectangle-w src) resize-ratio)) 0.5)))
  (set-rectangle-y! dst (trunc-float (* (- screen-h (* game-h resize-ratio)) 0.5)))
  (set-rectangle-w! dst (trunc-float (* (rectangle-w src) resize-ratio)))
  (set-rectangle-h! dst (trunc-float (* game-h resize-ratio))))

(define (keep-width-centered-integer screen-w screen-h game-w game-h src dst)
  (define resize-ratio (/ (exact->inexact screen-w) (exact->inexact game-w)))
  (set-rectangle-x! src 0.0)
  (set-rectangle-y! src 0.0)
  (set-rectangle-w! src (exact->inexact game-w))
  (set-rectangle-h! src (trunc-float (/ screen-h resize-ratio)))
  (set-rectangle-x! dst (trunc-float (* (- screen-w (* game-w resize-ratio)) 0.5)))
  (set-rectangle-y! dst (trunc-float (* (- screen-h (* (rectangle-h src) resize-ratio)) 0.5)))
  (set-rectangle-w! dst (trunc-float (* game-w resize-ratio)))
  (set-rectangle-h! dst (trunc-float (* (rectangle-h src) resize-ratio)))
  ;; 翻转 source height
  (set-rectangle-h! src (* -1 (rectangle-h src))))

;; --- 非整数缩放模式 ---

(define (keep-aspect-centered screen-w screen-h game-w game-h src dst)
  (setup-source-rect! src game-w game-h #t)
  (define ratio-x (/ (exact->inexact screen-w) (exact->inexact game-w)))
  (define ratio-y (/ (exact->inexact screen-h) (exact->inexact game-h)))
  (define resize-ratio (if (< ratio-x ratio-y) ratio-x ratio-y))
  (set-rectangle-x! dst (trunc-float (* (- screen-w (* game-w resize-ratio)) 0.5)))
  (set-rectangle-y! dst (trunc-float (* (- screen-h (* game-h resize-ratio)) 0.5)))
  (set-rectangle-w! dst (trunc-float (* game-w resize-ratio)))
  (set-rectangle-h! dst (trunc-float (* game-h resize-ratio))))

(define (keep-height-centered screen-w screen-h game-w game-h src dst)
  (define resize-ratio (/ (exact->inexact screen-h) (exact->inexact game-h)))
  (set-rectangle-x! src 0.0)
  (set-rectangle-y! src 0.0)
  (set-rectangle-w! src (trunc-float (/ screen-w resize-ratio)))
  (set-rectangle-h! src (exact->inexact (- game-h)))
  (set-rectangle-x! dst (trunc-float (* (- screen-w (* (rectangle-w src) resize-ratio)) 0.5)))
  (set-rectangle-y! dst (trunc-float (* (- screen-h (* game-h resize-ratio)) 0.5)))
  (set-rectangle-w! dst (trunc-float (* (rectangle-w src) resize-ratio)))
  (set-rectangle-h! dst (trunc-float (* game-h resize-ratio))))

(define (keep-width-centered screen-w screen-h game-w game-h src dst)
  (define resize-ratio (/ (exact->inexact screen-w) (exact->inexact game-w)))
  (set-rectangle-x! src 0.0)
  (set-rectangle-y! src 0.0)
  (set-rectangle-w! src (exact->inexact game-w))
  (set-rectangle-h! src (trunc-float (/ screen-h resize-ratio)))
  (set-rectangle-x! dst (trunc-float (* (- screen-w (* game-w resize-ratio)) 0.5)))
  (set-rectangle-y! dst (trunc-float (* (- screen-h (* (rectangle-h src) resize-ratio)) 0.5)))
  (set-rectangle-w! dst (trunc-float (* game-w resize-ratio)))
  (set-rectangle-h! dst (trunc-float (* (rectangle-h src) resize-ratio)))
  (set-rectangle-h! src (* -1 (rectangle-h src))))

;; ============================================================
;; ResizeRenderSize: 重新计算视口并重建 RenderTexture
;; 返回 (values screen-w screen-h target)
;; ============================================================

(define (resize-render-size! viewport-type game-w game-h src dst target)
  (define new-screen-w (get-screen-width))
  (define new-screen-h (get-screen-height))
  (case viewport-type
    [(0) (keep-aspect-centered-integer new-screen-w new-screen-h game-w game-h src dst)]
    [(1) (keep-height-centered-integer new-screen-w new-screen-h game-w game-h src dst)]
    [(2) (keep-width-centered-integer new-screen-w new-screen-h game-w game-h src dst)]
    [(3) (keep-aspect-centered new-screen-w new-screen-h game-w game-h src dst)]
    [(4) (keep-height-centered new-screen-w new-screen-h game-w game-h src dst)]
    [(5) (keep-width-centered new-screen-w new-screen-h game-w game-h src dst)])
  (unload-render-texture target)
  (define new-rt (load-render-texture (inexact->exact (floor (rectangle-w src)))
                                      (inexact->exact (floor (abs (rectangle-h src))))))
  (values new-screen-w new-screen-h new-rt))

;; ============================================================
;; Screen2RenderTexturePosition — 将屏幕鼠标坐标映射到纹理坐标
;; ============================================================

(define (screen2render-texture-position point texture-rect scaled-rect)
  (define rel-x (- (vector2-x point) (rectangle-x scaled-rect)))
  (define rel-y (- (vector2-y point) (rectangle-y scaled-rect)))
  (define ratio-x (/ (rectangle-w texture-rect) (rectangle-w scaled-rect)))
  (vector2 (* rel-x ratio-x) (* rel-y ratio-x)))

;; ============================================================
;; 初始化
;; ============================================================

(set-config-flags FLAG-WINDOW-RESIZABLE)
(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - viewport scaling (Racket)")

;; 分辨率索引和游戏分辨率
(define resolution-idx (box 0))
(define game-w (box 64))
(define game-h (box 64))

;; RenderTexture / source / dest rectangles
(define target (box #f))
(define source-rect (rectangle 0 0 0 0))
(define dest-rect (rectangle 0 0 0 0))

;; 当前视口类型
(define viewport-type (box KEEP-ASPECT-INTEGER))

;; 当前屏幕尺寸
(define current-screen-w (box SCREEN-WIDTH))
(define current-screen-h (box SCREEN-HEIGHT))

;; 初始化: 创建初始 render texture
(let-values ([(w h rt) (resize-render-size! (unbox viewport-type)
                                            (unbox game-w) (unbox game-h)
                                            source-rect dest-rect
                                            (or (unbox target) (load-render-texture 64 64)))])
  (set-box! current-screen-w w)
  (set-box! current-screen-h h)
  (set-box! target rt))

;; 按钮矩形
(define decrease-resolution-button (rectangle 200 30 10 10))
(define increase-resolution-button (rectangle 215 30 10 10))
(define decrease-type-button       (rectangle 200 45 10 10))
(define increase-type-button       (rectangle 215 45 10 10))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)

    ;; === 更新 ===
    (when (is-window-resized?)
      (let-values ([(w h rt) (resize-render-size! (unbox viewport-type)
                                                   (unbox game-w) (unbox game-h)
                                                   source-rect dest-rect
                                                   (unbox target))])
        (set-box! current-screen-w w)
        (set-box! current-screen-h h)
        (set-box! target rt)))

    (define mouse-pos (get-mouse-position))
    (define mouse-pressed? (is-mouse-button-pressed MOUSE-BUTTON-LEFT))

    ;; 减小分辨率
    (when (and (check-collision-point-rec mouse-pos decrease-resolution-button) mouse-pressed?)
      (set-box! resolution-idx (modulo (+ (unbox resolution-idx) (sub1 RESOLUTION-COUNT)) RESOLUTION-COUNT))
      (set-box! game-w (inexact->exact (floor (vector2-x (list-ref resolution-list (unbox resolution-idx))))))
      (set-box! game-h (inexact->exact (floor (vector2-y (list-ref resolution-list (unbox resolution-idx))))))
      (let-values ([(w h rt) (resize-render-size! (unbox viewport-type)
                                                   (unbox game-w) (unbox game-h)
                                                   source-rect dest-rect
                                                   (unbox target))])
        (set-box! current-screen-w w)
        (set-box! current-screen-h h)
        (set-box! target rt)))

    ;; 增大分辨率
    (when (and (check-collision-point-rec mouse-pos increase-resolution-button) mouse-pressed?)
      (set-box! resolution-idx (modulo (add1 (unbox resolution-idx)) RESOLUTION-COUNT))
      (set-box! game-w (inexact->exact (floor (vector2-x (list-ref resolution-list (unbox resolution-idx))))))
      (set-box! game-h (inexact->exact (floor (vector2-y (list-ref resolution-list (unbox resolution-idx))))))
      (let-values ([(w h rt) (resize-render-size! (unbox viewport-type)
                                                   (unbox game-w) (unbox game-h)
                                                   source-rect dest-rect
                                                   (unbox target))])
        (set-box! current-screen-w w)
        (set-box! current-screen-h h)
        (set-box! target rt)))

    ;; 减小视口类型
    (when (and (check-collision-point-rec mouse-pos decrease-type-button) mouse-pressed?)
      (set-box! viewport-type (modulo (+ (unbox viewport-type) (sub1 VIEWPORT-TYPE-COUNT)) VIEWPORT-TYPE-COUNT))
      (let-values ([(w h rt) (resize-render-size! (unbox viewport-type)
                                                   (unbox game-w) (unbox game-h)
                                                   source-rect dest-rect
                                                   (unbox target))])
        (set-box! current-screen-w w)
        (set-box! current-screen-h h)
        (set-box! target rt)))

    ;; 增大视口类型
    (when (and (check-collision-point-rec mouse-pos increase-type-button) mouse-pressed?)
      (set-box! viewport-type (modulo (add1 (unbox viewport-type)) VIEWPORT-TYPE-COUNT))
      (let-values ([(w h rt) (resize-render-size! (unbox viewport-type)
                                                   (unbox game-w) (unbox game-h)
                                                   source-rect dest-rect
                                                   (unbox target))])
        (set-box! current-screen-w w)
        (set-box! current-screen-h h)
        (set-box! target rt)))


    ;; 纹理坐标下的鼠标位置
    (define texture-mouse-pos
      (screen2render-texture-position mouse-pos source-rect dest-rect))

    ;; === 绘制场景到 RenderTexture ===
    (begin-texture-mode (unbox target))
    (clear-background WHITE)
    (draw-circle-v texture-mouse-pos 20.0 LIME)
    (end-texture-mode)

    ;; === 绘制主屏 ===
    (begin-drawing)
    (clear-background BLACK)

    ;; 绘制 RenderTexture (带视口缩放)
    (draw-texture-pro (rt->texture (unbox target))
                      source-rect dest-rect
                      (vector2 0.0 0.0) 0.0 WHITE)

    ;; 信息框背景
    (define info-rect (rectangle 5 5 330 105))
    (draw-rectangle-rec info-rect (fade LIGHTGRAY 0.7))
    (draw-rectangle-lines-ex info-rect 1.0 BLUE)

    (draw-text (format "Window Resolution: ~a x ~a"
                       (unbox current-screen-w) (unbox current-screen-h))
               15 15 10 BLACK)
    (draw-text (format "Game Resolution: ~a x ~a"
                       (unbox game-w) (unbox game-h))
               15 30 10 BLACK)
    (draw-text (format "Type: ~a"
                       (vector-ref viewport-type-names (unbox viewport-type)))
               15 45 10 BLACK)

    ;; 缩放比例
    (define scale-x (/ (rectangle-w dest-rect) (rectangle-w source-rect)))
    (define scale-y (/ (- (rectangle-h dest-rect)) (rectangle-h source-rect)))
    (if (or (< scale-x 0.001) (< scale-y 0.001))
      (draw-text "Scale ratio: INVALID" 15 60 10 BLACK)
      (draw-text (format "Scale ratio: ~a x ~a" (real->decimal-string scale-x 2) (real->decimal-string scale-y 2)) 15 60 10 BLACK))

    (draw-text (format "Source size: ~a x ~a"
                       (real->decimal-string (rectangle-w source-rect) 2)
                       (real->decimal-string (- (rectangle-h source-rect)) 2))
               15 75 10 BLACK)
    (draw-text (format "Destination size: ~a x ~a"
                       (real->decimal-string (rectangle-w dest-rect) 2)
                       (real->decimal-string (rectangle-h dest-rect) 2))
               15 90 10 BLACK)

    ;; 绘制按钮
    (draw-rectangle-rec decrease-type-button       SKYBLUE)
    (draw-rectangle-rec increase-type-button       SKYBLUE)
    (draw-rectangle-rec decrease-resolution-button SKYBLUE)
    (draw-rectangle-rec increase-resolution-button SKYBLUE)
    (draw-text "<" (inexact->exact (floor (+ (rectangle-x decrease-type-button) 3))) (inexact->exact (floor (+ (rectangle-y decrease-type-button) 1))) 10 BLACK)
    (draw-text ">" (inexact->exact (floor (+ (rectangle-x increase-type-button) 3))) (inexact->exact (floor (+ (rectangle-y increase-type-button) 1))) 10 BLACK)
    (draw-text "<" (inexact->exact (floor (+ (rectangle-x decrease-resolution-button) 3))) (inexact->exact (floor (+ (rectangle-y decrease-resolution-button) 1))) 10 BLACK)
    (draw-text ">" (inexact->exact (floor (+ (rectangle-x increase-resolution-button) 3))) (inexact->exact (floor (+ (rectangle-y increase-resolution-button) 1))) 10 BLACK)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-render-texture (unbox target))
(close-window)
