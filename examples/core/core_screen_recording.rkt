#lang racket/base

;; raylib [core] example - screen recording (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_screen_recording.c
;;
;; 演示: 正弦波动画 + 屏幕帧录制
;;   Ctrl+R - 开始/停止录制
;;   每帧保存为 PNG 文件
;;
;; ============================================================
;; C 版差异说明
;; ============================================================
;;
;; C 版使用 msf_gif 外部库 (不在 libraylib.so 中):
;;   #define MSF_GIF_IMPL
;;   #include "msf_gif.h"
;;   msf_gif_begin() / msf_gif_frame() / msf_gif_end()
;;   → 输出单个动画 GIF 文件
;;
;; Racket 版直接用 raylib 的 ExportImage (在 libraylib.so 中):
;;   load-image-from-screen → export-image (PNG)
;;   → 输出多个 PNG 帧文件
;;
;; 相同点: 都是 Ctrl+R 录制, LoadImageFromScreen() 抓帧,
;;          UnloadImage() 释放内存, GetApplicationDirectory() 确定路径
;;

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)
(define FRAME-SKIP 5)
(define MAX-SINEWAVE-POINTS 256)
(define PI (* 4 (atan 1.0)))

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - screen recording")

(define recording? (box #f))
(define frame-skip-counter (box 0))
(define frame-number (box 0))

(define circle-pos (vector2 0.0 (/ SCREEN-HEIGHT 2.0)))
(define time-counter (box 0.0))

;; 预计算正弦波点
(define sine-points
  (for/vector ([i (in-range MAX-SINEWAVE-POINTS)])
    (vector2
      (* i (/ SCREEN-WIDTH 180.0))
      (+ (/ SCREEN-HEIGHT 2.0)
         (* 150 (sin (* (/ (* 2 PI) 1.5) (/ 1.0 60.0) i)))))))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (define delta (get-frame-time))
    (define screen-w (get-screen-width))
    (define screen-h (get-screen-height))

    ;; === 更新 ===

    ;; 正弦波动画
    (set-box! time-counter (+ (unbox time-counter) delta))
    (set-vector2-x! circle-pos (+ (vector2-x circle-pos) (/ screen-w 180.0)))
    (set-vector2-y! circle-pos
      (+ (/ screen-h 2.0)
         (* 150 (sin (* (/ (* 2 PI) 1.5) (unbox time-counter))))))
    (when (> (vector2-x circle-pos) screen-w)
      (set-vector2-x! circle-pos 0.0)
      (set-vector2-y! circle-pos (/ screen-h 2.0))
      (set-box! time-counter 0.0))

    ;; Ctrl+R 开始/停止录制
    (when (and (is-key-down KEY-LEFT-CONTROL) (is-key-pressed KEY-R))
      (if (unbox recording?)
        (begin
          (set-box! recording? #f)
          (printf "Recording stopped: ~a frames saved~%"
                  (unbox frame-number)))
        (begin
          (set-box! recording? #t)
          (set-box! frame-skip-counter 0)
          (set-box! frame-number 0)
          (printf "Recording started... Ctrl+R to stop~%"))))

    ;; 录制帧 (每隔 FRAME-SKIP 帧抓取一次)
    (when (unbox recording?)
      (set-box! frame-skip-counter (+ (unbox frame-skip-counter) 1))
      (when (> (unbox frame-skip-counter) FRAME-SKIP)
        (set-box! frame-skip-counter 0)
        (set-box! frame-number (+ (unbox frame-number) 1))
        (define img (load-image-from-screen))
        (define filename
          (format "screenrec_~a.png" (unbox frame-number)))
        (export-image img filename)
        (unload-image img)))

    ;; === 绘制 ===
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 正弦波连线 + 点
    (for ([i (in-range (sub1 MAX-SINEWAVE-POINTS))])
      (draw-line-v (vector-ref sine-points i)
                   (vector-ref sine-points (add1 i)) MAROON)
      (draw-circle-v (vector-ref sine-points i) 3.0 MAROON))

    ;; 移动圆圈
    (draw-circle-v circle-pos 30.0 RED)

    (draw-fps 10 10)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
