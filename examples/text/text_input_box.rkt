#lang racket/base

;; raylib [text] example - input box (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_input_box.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define max-input-chars 9)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - input box")

(define name (make-string (+ max-input-chars 1) #\nul))
(define-var letter-count 0)

(define text-box (rectangle (- (/ screen-width 2.0) 100) 180.0 225.0 50.0))
(define-var mouse-on-text? #f)
(define-var frames-counter 0)

(set-target-fps 60)

;; ============================================================
;; 辅助: CheckCollisionPointRec wrapper
;; Since check-collision-point-rec expects Rectangle pointer and Vector2 pointer
;; ============================================================

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (let ([mouse-pos (get-mouse-position)])
      (set-box! mouse-on-text? (check-collision-point-rec mouse-pos text-box)))

    (when (unbox mouse-on-text?)
      ;; Set mouse cursor to I-Beam
      (set-mouse-cursor MOUSE-CURSOR-IBEAM)

      ;; Get char pressed (unicode character) on the queue
      (let key-loop ([key (get-char-pressed)])
        (when (> key 0)
          ;; NOTE: Only allow keys in range [32..125]
          (when (and (>= key 32) (<= key 125) (< (unbox letter-count) max-input-chars))
            (string-set! name (unbox letter-count) (integer->char key))
            (string-set! name (+ (unbox letter-count) 1) (integer->char 0))
            (+= letter-count 1))
          (key-loop (get-char-pressed))))

      (when (is-key-pressed KEY-BACKSPACE)
        (-= letter-count 1)
        (when (< (unbox letter-count) 0)
          (set-box! letter-count 0))
        (string-set! name (unbox letter-count) (integer->char 0))))

    (unless (unbox mouse-on-text?)
      (set-mouse-cursor MOUSE-CURSOR-DEFAULT))

    (if (unbox mouse-on-text?)
        (+= frames-counter 1)
        (set-box! frames-counter 0))

    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    (draw-text "PLACE MOUSE OVER INPUT BOX!" 240 140 20 GRAY)

    (draw-rectangle-rec text-box LIGHTGRAY)
    (if (unbox mouse-on-text?)
        (draw-rectangle-lines (inexact->exact (rectangle-x text-box))
                              (inexact->exact (rectangle-y text-box))
                              (inexact->exact (rectangle-w text-box))
                              (inexact->exact (rectangle-h text-box))
                              RED)
        (draw-rectangle-lines (inexact->exact (rectangle-x text-box))
                              (inexact->exact (rectangle-y text-box))
                              (inexact->exact (rectangle-w text-box))
                              (inexact->exact (rectangle-h text-box))
                              DARKGRAY))

    (draw-text (substring name 0 (unbox letter-count))
               (+ (inexact->exact (rectangle-x text-box)) 5)
               (+ (inexact->exact (rectangle-y text-box)) 8)
               40 MAROON)

    (draw-text (format "INPUT CHARS: ~a/~a" (unbox letter-count) max-input-chars)
               315 250 20 DARKGRAY)

    (when (unbox mouse-on-text?)
      (if (< (unbox letter-count) max-input-chars)
          ;; Draw blinking underscore char
          (when (= (modulo (quotient (unbox frames-counter) 20) 2) 0)
            (draw-text "_"
                       (+ (inexact->exact (rectangle-x text-box)) 8
                          (measure-text (substring name 0 (unbox letter-count)) 40))
                       (+ (inexact->exact (rectangle-y text-box)) 12)
                       40 MAROON))
          (draw-text "Press BACKSPACE to delete chars..." 230 300 20 GRAY)))

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
