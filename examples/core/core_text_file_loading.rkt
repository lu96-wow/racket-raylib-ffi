#lang racket/base

;; raylib [core] example - text file loading
;;
;; 对应 C: examples/core/core_text_file_loading.c
;;
;; 展示文本文件加载、自动换行、滚动浏览
;;
;; 注意:
;;   - LoadFileText 用 Racket 包装自动释放 C 内存
;;   - LoadTextLines 用 Racket 的 string-split 替代（避免 C malloc+out参数）
;;   - TextFormat 用 Racket format 替代

(require "../../raylib/raylib.rkt"
         racket/string)

;; ============================================================
;; 全局常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define font-size 20)
(define text-top (+ 25 font-size))
(define wrap-width (- screen-width 20))
(define line-spacing 10)

;; ============================================================
;; 文本文件路径（相对 racket-bind/ 工作目录）
;; ============================================================

(define file-name "examples/core/core_text_file_loading.rkt")

;; ============================================================
;; 自动换行 — 纯 Racket 实现
;; 对应 C 中 for 循环逐行扫描空格的逻辑
;; ============================================================

(define (wrap-line line wrap-w)
  ;; 对单行文本做自动换行, 返回 (list of strings)
  (let ([len (string-length line)])
    (let loop ([i 0] [last-space 0] [last-wrap-start 0] [result '()])
      (cond
        [(> i len)
         ;; 结尾：加入最后一段
         (reverse (cons (substring line last-wrap-start) result))]
        [else
         (let ([ch (if (< i len) (string-ref line i) #\nul)])
           (if (or (char=? ch #\space) (= i len))
               ;; 遇到空格或结尾
               (let* ([segment (substring line last-wrap-start i)])
                 (if (> (measure-text segment font-size) wrap-w)
                     ;; 超宽 → 在 last-space 处换行
                     (let ([wrapped (substring line last-wrap-start last-space)])
                       (loop (+ i 1) i (+ last-space 1)
                             (cons wrapped result)))
                     ;; 未超宽 → 继续
                     (loop (+ i 1) i last-wrap-start result)))
               (loop (+ i 1) last-space last-wrap-start result)))]))))

(define (wrap-all-lines lines wrap-w)
  (apply append (map (lambda (line) (wrap-line line wrap-w)) lines)))

;; ============================================================
;; 主程序
;; ============================================================

(define (main)
  ;; 初始化
  (init-window screen-width screen-height
               "raylib [core] example - text file loading")

  ;; 加载文本文件
  (printf "Loading file: ~a...~n" file-name)
  (define file-text (load-file-text file-name))
  (unless file-text
    (printf "ERROR: Could not load file: ~a~n" file-name)
    (close-window)
    (exit 1))
  (printf "File loaded: ~a bytes~n" (string-length file-text))

  ;; 按行拆分 + 自动换行
  (define raw-lines (string-split file-text "\n"))
  (define lines (wrap-all-lines raw-lines wrap-width))
  (define line-count (length lines))
  (printf "Lines (after wrap): ~a~n" line-count)

  ;; 计算总文本高度
  (define default-font (get-font-default))
  (define text-height
    (for/sum ([line (in-list lines)])
      (let ([size (if (equal? line "")
                      (measure-text-ex default-font " " (exact->inexact font-size) 2.0)
                      (measure-text-ex default-font line (exact->inexact font-size) 2.0))]
            [h 0])
        (+ (inexact->exact (floor (vector2-y size))) line-spacing))))
  (printf "Text height: ~a~n" text-height)

  ;; Camera2D 设置
  (define cam (camera2d 0 0 0 0 0 1))

  ;; 滚动条
  (define scroll-bar-h (inexact->exact
                        (floor (* screen-height 100.0
                                  (/ (max 1 (- text-height screen-height)))))))
  (define scroll-bar (rectangle (- screen-width 5) 0 5 (inexact->exact scroll-bar-h)))

  (set-target-fps 60)

  ;; 主循环
  (let loop ()
    (unless (window-should-close?)
      ;; === 更新 ===
      (let ([scroll (get-mouse-wheel-move)])
        (set-camera2d-target-y! cam
                                (max 0.0
                                     (- (camera2d-target-y cam) (* scroll font-size 1.5))))
        ;; 限制不超过文本底部
        (when (> (camera2d-target-y cam)
                 (- text-height screen-height text-top))
          (set-camera2d-target-y! cam
                                  (exact->inexact (- text-height screen-height text-top)))))

      ;; 滚动条位置
      (let* ([cam-y (camera2d-target-y cam)]
             [scroll-range (max 1.0 (- text-height screen-height))]
             [t (/ (- cam-y text-top) scroll-range)]
             [bar-y (lerp text-top (- screen-height (rectangle-h scroll-bar)) t)])
        (set-rectangle-y! scroll-bar bar-y))

      ;; === 绘制 ===
      (begin-drawing)
      (clear-background RAYWHITE)

      ;; 用 Camera2D 滚动文本
      (begin-mode-2d cam)
      (let ([y text-top])
        (for ([line (in-list lines)])
          (let* ([display-line (if (equal? line "") " " line)]
                 [size (measure-text-ex default-font display-line (exact->inexact font-size) 2.0)]
                 [h (inexact->exact (floor (vector2-y size)))])
            (draw-text line 10 y font-size RED)
            (set! y (+ y h line-spacing)))))
      (end-mode-2d)

      ;; 文件标题栏
      (draw-rectangle 0 0 screen-width (- text-top 10) BEIGE)
      (draw-text (format "File: ~a" file-name) 10 10 font-size MAROON)

      ;; 滚动条
      (draw-rectangle-rec scroll-bar MAROON)

      (end-drawing)
      (loop)))

  ;; 清理
  (close-window))

;; 运行
(main)
