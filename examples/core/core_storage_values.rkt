#lang racket/base

;; raylib [core] example - storage values
;;
;; Racket 翻译自 examples/core/core_storage_values.c
;;
;; 设计说明:
;;   C 版用 raylib 的 LoadFileData/SaveFileData 实现二进制存储
;;   Racket 版直接用 call-with-input-file/write-bytes 替代
;;   无需新增 FFI 绑定

(require "../../raylib/raylib.rkt")

(define STORAGE-DATA-FILE "storage.data")

;; ============================================================
;; 存储辅助函数
;; ============================================================

;; 保存 int 值到文件指定位置（位置×4 = 字节偏移）
(define (save-storage-value position value)
  ;; 读取现有文件内容（如果存在）
  (define old-data
    (with-handlers ([exn:fail? (λ (_) #f)])
      (call-with-input-file STORAGE-DATA-FILE
        (λ (in) (read-bytes (file-size STORAGE-DATA-FILE) in))
        #:mode 'binary)))
  ;; 准备新数据缓冲区（确保至少容纳 2 个 int）
  (define data-size (* 4 (max 2 (add1 position))))
  (define data (make-bytes data-size 0))
  (when (bytes? old-data)
    (bytes-copy! data 0 old-data 0 (min (bytes-length old-data) data-size)))
  ;; 以 little-endian 写入 int 到指定位置
  (define offset (* position 4))
  (bytes-set! data offset       (bitwise-and value #xFF))
  (bytes-set! data (add1 offset) (bitwise-and (arithmetic-shift value -8) #xFF))
  (bytes-set! data (+ 2 offset)  (bitwise-and (arithmetic-shift value -16) #xFF))
  (bytes-set! data (+ 3 offset)  (bitwise-and (arithmetic-shift value -24) #xFF))
  ;; 写入文件
  (call-with-output-file STORAGE-DATA-FILE
    (λ (out) (write-bytes data out))
    #:mode 'binary
    #:exists 'replace))

;; 从文件指定位置加载 int 值（找不到时返回 0）
(define (load-storage-value position)
  (define old-data
    (with-handlers ([exn:fail? (λ (_) #f)])
      (call-with-input-file STORAGE-DATA-FILE
        (λ (in) (read-bytes (file-size STORAGE-DATA-FILE) in))
        #:mode 'binary)))
  (cond
    [(and (bytes? old-data)
          (>= (bytes-length old-data) (* 4 (add1 position))))
     (define offset (* position 4))
     (+ (bytes-ref old-data offset)
        (arithmetic-shift (bytes-ref old-data (add1 offset)) 8)
        (arithmetic-shift (bytes-ref old-data (+ 2 offset)) 16)
        (arithmetic-shift (bytes-ref old-data (+ 3 offset)) 24))]
    [else 0]))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
             "raylib [core] example - storage values")

(define-var score 0)
(define-var hiscore 0)
(define-var frames-counter 0)

;; 位置常量（对应 C 的 StorageData 枚举）
(define STORAGE-POSITION-SCORE   0)
(define STORAGE-POSITION-HISCORE 1)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()
  (unless (window-should-close?)
    ;; --- 更新 ---
    (when (is-key-pressed KEY-R)
      (set-box! score (get-random-value 1000 2000))
      (set-box! hiscore (get-random-value 2000 4000)))

    (when (is-key-pressed KEY-ENTER)
      (save-storage-value STORAGE-POSITION-SCORE (unbox score))
      (save-storage-value STORAGE-POSITION-HISCORE (unbox hiscore)))

    (when (is-key-pressed KEY-SPACE)
      (set-box! score (load-storage-value STORAGE-POSITION-SCORE))
      (set-box! hiscore (load-storage-value STORAGE-POSITION-HISCORE)))

    (set-box! frames-counter (add1 (unbox frames-counter)))

    ;; --- 绘制 ---
    (begin-drawing)
    (clear-background RAYWHITE)

    (draw-text (format "SCORE: ~a" (unbox score)) 280 130 40 MAROON)
    (draw-text (format "HI-SCORE: ~a" (unbox hiscore)) 210 200 50 BLACK)
    (draw-text (format "frames: ~a" (unbox frames-counter)) 10 10 20 LIME)

    (draw-text "Press R to generate random numbers" 220 40 20 LIGHTGRAY)
    (draw-text "Press ENTER to SAVE values" 250 310 20 LIGHTGRAY)
    (draw-text "Press SPACE to LOAD values" 252 350 20 LIGHTGRAY)

    (end-drawing)

    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
