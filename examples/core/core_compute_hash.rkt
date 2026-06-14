#lang racket/base

;; raylib [core] example - compute hash
;;
;; 对应 C: examples/core/core_compute_hash.c
;;
;; 展示 hash 计算功能：
;;   - 文本输入框，输入要计算 hash 的数据
;;   - COMPUTE 按钮触发计算
;;   - 显示 CRC32、MD5、SHA1、SHA256 hash 值
;;   - Bonus: Base64 编码
;;
;; 注意: 用原生 raylib 绘制替代 raygui
;;
;; 更新 v2:
;;   MD5/SHA1/BASE64 → Racket 内置 (openssl/md5, openssl/sha1, net/base64)
;;   CRC32 → Racket 纯实现 (查表法)
;;   SHA256 → raylib FFI (compute-sha256)

(require "../../raylib/raylib.rkt"
         openssl/md5
         openssl/sha1
         net/base64)

;; ============================================================
;; CRC32 — Racket 纯实现 (查表法)
;; ============================================================

(define crc32-table
  (let ([table (make-bytes 1024)])
    (for ([i (in-range 256)])
      (let loop ([j 0] [crc i])
        (if (< j 8)
            (loop (add1 j)
                  (if (bitwise-bit-set? crc 0)
                      (bitwise-xor (arithmetic-shift crc -1) #xEDB88320)
                      (arithmetic-shift crc -1)))
            (begin
              (bytes-set! table (* i 4) (bitwise-and crc #xFF))
              (bytes-set! table (+ (* i 4) 1) (bitwise-and (arithmetic-shift crc -8) #xFF))
              (bytes-set! table (+ (* i 4) 2) (bitwise-and (arithmetic-shift crc -16) #xFF))
              (bytes-set! table (+ (* i 4) 3) (bitwise-and (arithmetic-shift crc -24) #xFF))))))
    table))

(define (bytes->hex-string bs)
  (string-upcase
   (apply string-append
          (for/list ([b (in-bytes bs)])
            (let ([s (number->string b 16)])
              (if (= (string-length s) 1)
                  (string-append "0" s)
                  s))))))

(define (compute-crc32 data)
  (let ([crc #xFFFFFFFF])
    (for ([b (in-bytes data)])
      (define idx (bitwise-xor (bitwise-and crc #xFF) b))
      (define tbl-val (+ (bytes-ref crc32-table (* idx 4))
                         (arithmetic-shift (bytes-ref crc32-table (+ (* idx 4) 1)) 8)
                         (arithmetic-shift (bytes-ref crc32-table (+ (* idx 4) 2)) 16)
                         (arithmetic-shift (bytes-ref crc32-table (+ (* idx 4) 3)) 24)))
      (set! crc (bitwise-xor (arithmetic-shift crc -8) tbl-val)))
    (let ([n (bitwise-xor crc #xFFFFFFFF)])
      (string-upcase
       (let ([s (number->string n 16)])
         (string-append (make-string (- 8 (string-length s)) #\0) s))))))

;; ============================================================
;; SHA256 — 使用 raylib 的 compute-sha256 (已验证)
;; ============================================================

(define (compute-sha256-hex data)
  (let ([result (compute-sha256 data (bytes-length data))])
    (if result
        (uint-list->hex result)
        "ERROR")))

(define (uint-list->hex lst)
  (string-upcase
   (apply string-append
          (map (lambda (x)
                   (let ([s (number->string x 16)])
                     (string-append (make-string (- 8 (string-length s)) #\0) s)))
                 lst))))

;; ============================================================
;; 辅助: 文本输入编辑
;; ============================================================

(define (draw-text-box x y w h text edit-mode?)
  (let ([bg-color (if edit-mode? (fade LIGHTGRAY 0.5) WHITE)])
    (draw-rectangle-rec (rectangle x y w h) bg-color))
  (let ([border-color (if edit-mode? MAROON DARKGRAY)])
    (draw-rectangle-lines-ex (rectangle x y w h) 2.0 border-color))
  (let* ([text-len (string-length text)]
         [max-vis (inexact->exact (floor (/ (- w 8) 8)))]
         [display-text (if (> text-len max-vis)
                           (substring text (- text-len max-vis))
                           text)])
    (draw-text display-text (+ x 4) (+ y 6) 10 DARKGRAY))
  (when edit-mode?
    (let* ([text-len (string-length text)]
           [cursor-x (+ x 4 (if (< text-len 70) (* text-len 8) (* 70 8)))])
      (draw-text "|" cursor-x (+ y 4) 12 MAROON))))

(define (draw-button x y w h text)
  (let ([bounds (rectangle x y w h)]
        [mouse-pos (get-mouse-position)])
    (let ([hover? (check-collision-point-rec mouse-pos bounds)])
      (draw-rectangle-rec bounds (if hover? LIGHTGRAY (color 220 220 220)))
      (draw-rectangle-lines-ex bounds 2.0 DARKGRAY)
      (draw-text text (+ x 10) (+ y 8) 12 DARKGRAY))
    (when (and (check-collision-point-rec mouse-pos bounds)
               (is-mouse-button-pressed MOUSE-BUTTON-LEFT))
      #t)
    #f))

(define (draw-label-value y label value clr)
  (draw-text label 40 (+ y 4) 12 DARKGRAY)
  (let ([val-bounds (rectangle 160 y (- 720 120) 32)])
    (draw-rectangle-rec val-bounds (color 240 240 240))
    (draw-rectangle-lines-ex val-bounds 1.0 LIGHTGRAY)
    (draw-text value 164 (+ y 6) 10 clr)))

;; ============================================================
;; 主程序
;; ============================================================

(define (main)
  (init-window 800 550 "raylib [core] example - compute hash")
  (set-exit-key KEY-NULL)

  (define text-input "The quick brown fox jumps over the lazy dog.")
  (define text-box-edit-mode #f)

  (define hash-crc32 #f)
  (define hash-md5 #f)
  (define hash-sha1 #f)
  (define hash-sha256 #f)
  (define base64-text #f)

  (define btn-bounds (rectangle 40 (+ 64 40) 720 32))
  (define input-bounds (rectangle 40 64 720 32))

  (set-target-fps 30)

  (let loop ()
    (unless (window-should-close?)
      ;; 文本输入编辑
      (set! text-input
        (let ([len (string-length text-input)])
          (let ([ch (get-char-pressed)])
            (when (and (> ch 0) (< len 95))
              (set! text-input (string-append text-input (string (integer->char ch))))))
          (when (and (is-key-pressed KEY-BACKSPACE) (> len 0))
            (set! text-input (substring text-input 0 (- len 1))))
          text-input))

      (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
        (set! text-box-edit-mode
              (check-collision-point-rec (get-mouse-position) input-bounds)))

      (when (and (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
                 (check-collision-point-rec (get-mouse-position) btn-bounds))
        (let* ([bstr (string->bytes/utf-8 text-input)])
          (printf "COMPUTING HASHES for: ~s~n" text-input)
          (set! hash-crc32 (compute-crc32 bstr))
          (set! hash-md5 (string-upcase (md5 (open-input-bytes bstr))))
          (set! hash-sha1 (string-upcase (sha1 (open-input-bytes bstr))))
          (set! hash-sha256 (compute-sha256-hex bstr))
          (set! base64-text (base64-encode bstr #t))
          (printf "  CRC32:   ~a~n" hash-crc32)
          (printf "  MD5:     ~a~n" hash-md5)
          (printf "  SHA1:    ~a~n" hash-sha1)
          (printf "  SHA256:  ~a~n" hash-sha256)
          (printf "  BASE64:  ~a~n" base64-text)))

      (begin-drawing)
      (clear-background RAYWHITE)
      (draw-text "INPUT DATA (TEXT):" 40 26 20 LIGHTGRAY)
      (draw-text-box 40 64 720 32 text-input text-box-edit-mode)
      (draw-button 40 (+ 64 40) 720 32 "COMPUTE INPUT DATA HASHES")
      (draw-text "INPUT DATA HASH VALUES:" 40 160 20 LIGHTGRAY)
      (draw-label-value 200 "CRC32 [32 bit]:"
                        (if hash-crc32 hash-crc32 "-")
                        (color 0 150 0))
      (draw-label-value 236 "MD5 [128 bit]:"
                        (if hash-md5 hash-md5 "-")
                        (color 0 120 180))
      (draw-label-value 272 "SHA1 [160 bit]:"
                        (if hash-sha1 hash-sha1 "-")
                        (color 150 80 0))
      (draw-label-value 308 "SHA256 [256 bit]:"
                        (if hash-sha256 hash-sha256 "-")
                        (color 120 0 120))
      (draw-text "BONUS - BASE64 ENCODED STRING:" 40 (- (+ 200 (* 36 5)) 30) 12 LIGHTGRAY)
      (draw-label-value (+ 200 (* 36 5)) "BASE64 ENCODING:"
                        (if base64-text base64-text "-")
                        (color 0 100 0))
      (end-drawing)
      (loop)))

  (close-window))

(main)
