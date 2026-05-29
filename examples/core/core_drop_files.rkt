#lang racket/base

;; raylib [core] example - drop files
;;
;; Racket 翻译自 examples/core/core_drop_files.c
;;
;; 设计说明:
;;   C 版需要手动 TextCopy + RL_CALLOC 管理内存
;;   Racket 版 load-dropped-files 自动读取所有字符串并释放 C 内存
;;   返回纯 Racket 字符串列表，更安全简洁

(require "../../raylib/raylib.rkt")

(define MAX-FILEPATH-RECORDED 4096)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
             "raylib [core] example - drop files")

;; 用 Vector 存储历史拖放文件路径（Racket 字符串）
(define file-paths (make-vector MAX-FILEPATH-RECORDED ""))
(define file-path-counter 0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()
  (unless (window-should-close?)
    ;; --- 更新 ---
    (when (is-file-dropped)
      ;; load-dropped-files 返回 Racket 字符串列表，C 内存已自动释放
      (for ([path (in-list (load-dropped-files))])
        (when (< file-path-counter (sub1 MAX-FILEPATH-RECORDED))
          (vector-set! file-paths file-path-counter path)
          (set! file-path-counter (add1 file-path-counter)))))

    ;; --- 绘制 ---
    (begin-drawing)
    (clear-background RAYWHITE)

    (if (zero? file-path-counter)
        ;; 无拖放文件时
        (draw-text "Drop your files to this window!" 100 40 20 DARKGRAY)
        ;; 有拖放文件时
        (begin
          (draw-text "Dropped files:" 100 40 20 DARKGRAY)
          (for ([i (in-range file-path-counter)])
            (if (even? i)
                (draw-rectangle 0 (+ 85 (* 40 i)) screen-width 40
                                (fade LIGHTGRAY 0.5))
                (draw-rectangle 0 (+ 85 (* 40 i)) screen-width 40
                                (fade LIGHTGRAY 0.3)))
            (draw-text (vector-ref file-paths i)
                       120 (+ 100 (* 40 i)) 10 GRAY))
          (draw-text "Drop new files..."
                     100 (+ 110 (* 40 file-path-counter)) 20 DARKGRAY)))

    (end-drawing)

    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
