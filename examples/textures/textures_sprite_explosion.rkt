#lang racket/base

;; raylib [textures] example - sprite explosion (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_sprite_explosion.c
;;
;; 演示: 使用精灵表网格实现爆炸动画
;;   鼠标点击触发爆炸，播放声音并循环 5×5 帧动画

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
(define num-frames-per-line 5)
(define num-lines 5)

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - sprite explosion")

(init-audio-device)

(define fx-boom (load-sound (string-append resource-dir "boom.wav")))
(define explosion (load-texture (string-append resource-dir "explosion.png")))

;; 计算每帧尺寸
(define frame-width (/ (list-ref explosion 1) num-frames-per-line 1.0))
(define frame-height (/ (list-ref explosion 2) num-lines 1.0))

(define frame-rec (rectangle 0.0 0.0 frame-width frame-height))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ([active? #f]
           [current-frame 0]
           [current-line 0]
           [frames-counter 0]
           [pos-x 0.0]
           [pos-y 0.0])
  (unless (window-should-close?)
    ;; 更新
    (let-values ([(active? current-frame current-line frames-counter pos-x pos-y)
                  (cond
                    ;; 鼠标点击触发爆炸
                    [(and (is-mouse-button-pressed MOUSE-BUTTON-LEFT) (not active?))
                     (let ([mp (get-mouse-position)])
                       (play-sound fx-boom)
                       (values #t 0 0 0
                               (- (vector2-x mp) (/ frame-width 2.0))
                               (- (vector2-y mp) (/ frame-height 2.0))))]

                    ;; 爆炸动画进行中
                    [active?
                     (let* ([fc (+ frames-counter 1)])
                       (if (> fc 2)
                           (let* ([cf (+ current-frame 1)])
                             (if (>= cf num-frames-per-line)
                                 (let* ([cl (+ current-line 1)])
                                   (if (>= cl num-lines)
                                       (values #f 0 0 0 pos-x pos-y)   ;; 动画结束
                                       (values #t 0 cl 0 pos-x pos-y))) ;; 下一行
                                 (values #t cf current-line 0 pos-x pos-y))) ;; 下一帧
                           (values #t current-frame current-line fc pos-x pos-y)))]

                    [else (values #f current-frame current-line frames-counter pos-x pos-y)])])

      ;; 更新帧矩形
      (set-rectangle-x! frame-rec (* frame-width current-frame))
      (set-rectangle-y! frame-rec (* frame-height current-line))

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)

      (when active?
        (draw-texture-rec explosion frame-rec
                          (vector2 pos-x pos-y) WHITE))

      (end-drawing)
      (loop active? current-frame current-line frames-counter pos-x pos-y))))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture explosion)
(unload-sound fx-boom)
(close-audio-device)
(close-window)
