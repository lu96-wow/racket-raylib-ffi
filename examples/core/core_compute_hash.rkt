#lang racket/base

;; raylib [core] example - compute hash
;;
;; 对应 C: examples/core/core_compute_hash.c
;;
;; 展示 raylib 的 hash 计算功能：
;;   - 文本输入框，输入要计算 hash 的数据
;;   - COMPUTE 按钮触发计算
;;   - 显示 CRC32、MD5、SHA1、SHA256 hash 值
;;   - Bonus: Base64 编码
;;
;; 注意: 用原生 raylib 绘制替代 raygui

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 辅助: 将 unsigned int 列表格式化为 hex 字符串
;; ============================================================

(define (uint-list->hex lst)
  (apply string-append
         (map (lambda (x) (uint->hex x)) lst)))

(define (uint->hex x)
  (string-upcase
   (let ([s (number->string x 16)])
     (string-append (make-string (- 8 (string-length s)) #\0) s))))

;; ============================================================
;; 辅助: 将 Racket 字符串转为 C 字节串指针
;; ============================================================

(define (string->c-bytes str)
  (string->bytes/utf-8 str))

;; ============================================================
;; 辅助: 文本输入编辑
;; ============================================================

(define (handle-text-input text max-len)
  ;; 处理 get-char-pressed 追加字符
  (let ([ch (get-char-pressed)])
    (when (and (> ch 0) (< (string-length text) max-len))
      (set! text (string-append text (string (integer->char ch))))))
  ;; 处理退格键
  (when (and (is-key-pressed KEY-BACKSPACE) (> (string-length text) 0))
    (set! text (substring text 0 (- (string-length text) 1))))
  text)

;; ============================================================
;; 绘制: 文本框
;; ============================================================

(define (draw-text-box x y w h text edit-mode?)
  ;; 背景
  (let ([bg-color (if edit-mode? (fade LIGHTGRAY 0.5) WHITE)])
    (draw-rectangle-rec (rectangle x y w h) bg-color))
  ;; 边框
  (let ([border-color (if edit-mode? MAROON DARKGRAY)])
    (draw-rectangle-lines-ex (rectangle x y w h) 2.0 border-color))
  ;; 文本（截断到可视区域）
  (let* ([text-len (string-length text)]
         [max-vis (inexact->exact (floor (/ (- w 8) 8)))]  ;; 约每字8像素
         [display-text (if (> text-len max-vis)
                           (substring text (- text-len max-vis))
                           text)])
    (draw-text display-text (+ x 4) (+ y 6) 10 DARKGRAY))
  ;; 编辑模式光标
  (when edit-mode?
    (let* ([text-len (string-length text)]
           [cursor-x (+ x 4 (if (< text-len 70) (* text-len 8) (* 70 8)))])
      (draw-text "|" cursor-x (+ y 4) 12 MAROON))))

;; ============================================================
;; 绘制: 按钮
;; ============================================================

(define (draw-button x y w h text)
  (let ([bounds (rectangle x y w h)]
        [mouse-pos (get-mouse-position)])
    ;; 检测悬停
    (let ([hover? (check-collision-point-rec mouse-pos bounds)])
      (draw-rectangle-rec bounds (if hover? LIGHTGRAY (color 220 220 220)))
      (draw-rectangle-lines-ex bounds 2.0 DARKGRAY)
      (draw-text text (+ x 10) (+ y 8) 12 DARKGRAY))
    ;; 检测点击
    (when (and (check-collision-point-rec mouse-pos bounds)
               (is-mouse-button-pressed MOUSE-BUTTON-LEFT))
      #t)
    #f))

;; ============================================================
;; 绘制: 标签 + 值
;; ============================================================

(define (draw-label-value y label value color)
  (draw-text label 40 (+ y 4) 12 DARKGRAY)
  (let ([val-bounds (rectangle 160 y (- 720 120) 32)])
    (draw-rectangle-rec val-bounds (color 240 240 240))
    (draw-rectangle-lines-ex val-bounds 1.0 LIGHTGRAY)
    (draw-text value 164 (+ y 6) 10 color)))

;; ============================================================
;; 主程序
;; ============================================================

(define (main)
  (init-window 800 550 "raylib [core] example - compute hash")
  (set-exit-key KEY-NULL)

  ;; 状态
  (define text-input "The quick brown fox jumps over the lazy dog.")
  (define text-box-edit-mode #f)
  (define btn-compute-hashes #f)

  ;; Hash 结果
  (define hash-crc32 #f)
  (define hash-md5 #f)
  (define hash-sha1 #f)
  (define hash-sha256 #f)
  (define base64-text #f)

  ;; 按钮区域
  (define btn-bounds (rectangle 40 (+ 64 40) 720 32))

  ;; 文本输入框区域
  (define input-bounds (rectangle 40 64 720 32))

  (set-target-fps 30)

  ;; 主循环
  (let loop ()
    (unless (window-should-close?)
      ;; === 更新 ===
      ;; 文本输入编辑
      (set! text-input
        (let ([len (string-length text-input)])
          ;; 处理字符输入
          (let ([ch (get-char-pressed)])
            (when (and (> ch 0) (< len 95))
              (set! text-input (string-append text-input (string (integer->char ch))))))
          ;; 处理退格键
          (when (and (is-key-pressed KEY-BACKSPACE) (> len 0))
            (set! text-input (substring text-input 0 (- len 1))))
          text-input))

      ;; 文本框点击切换编辑模式
      (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
        (set! text-box-edit-mode
              (check-collision-point-rec (get-mouse-position) input-bounds)))

      ;; 按钮点击 -> 计算 hash
      (when (and (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
                 (check-collision-point-rec (get-mouse-position) btn-bounds))
        (let* ([bstr (string->c-bytes text-input)]
               [len (bytes-length bstr)])
          (printf "COMPUTING HASHES for: ~s~n" text-input)
          (set! hash-crc32 (compute-crc32 bstr len))
          (set! hash-md5 (compute-md5 bstr len))
          (set! hash-sha1 (compute-sha1 bstr len))
          (set! hash-sha256 (compute-sha256 bstr len))
          (set! base64-text (encode-data-base64 bstr len))
          (printf "  CRC32:   ~a~n" (uint->hex hash-crc32))
          (printf "  MD5:     ~a~n" (uint-list->hex hash-md5))
          (printf "  SHA1:    ~a~n" (uint-list->hex hash-sha1))
          (printf "  SHA256:  ~a~n" (uint-list->hex hash-sha256))
          (printf "  BASE64:  ~a~n" base64-text)))

      ;; === 绘制 ===
      (begin-drawing)
      (clear-background RAYWHITE)

      ;; 标题
      (draw-text "INPUT DATA (TEXT):" 40 26 20 LIGHTGRAY)

      ;; 文本输入框
      (draw-text-box 40 64 720 32 text-input text-box-edit-mode)

      ;; COMPUTE 按钮
      (draw-button 40 (+ 64 40) 720 32 "COMPUTE INPUT DATA HASHES")

      ;; 结果标题
      (draw-text "INPUT DATA HASH VALUES:" 40 160 20 LIGHTGRAY)

      ;; CRC32
      (draw-label-value 200 "CRC32 [32 bit]:"
                        (if hash-crc32 (uint->hex hash-crc32) "-")
                        (color 0 150 0))

      ;; MD5
      (draw-label-value 236 "MD5 [128 bit]:"
                        (if hash-md5 (uint-list->hex hash-md5) "-")
                        (color 0 120 180))

      ;; SHA1
      (draw-label-value 272 "SHA1 [160 bit]:"
                        (if hash-sha1 (uint-list->hex hash-sha1) "-")
                        (color 150 80 0))

      ;; SHA256
      (draw-label-value 308 "SHA256 [256 bit]:"
                        (if hash-sha256 (uint-list->hex hash-sha256) "-")
                        (color 120 0 120))

      ;; Base64
      (draw-text "BONUS - BASE64 ENCODED STRING:" 40 (- (+ 200 (* 36 5)) 30) 12 LIGHTGRAY)
      (draw-label-value (+ 200 (* 36 5)) "BASE64 ENCODING:"
                        (if base64-text base64-text "-")
                        (color 0 100 0))

      (end-drawing)
      (loop)))

  (close-window))

;; 运行
(main)
