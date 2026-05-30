#lang racket/base

(require "../../raylib/raylib.rkt"
         ffi/unsafe)

(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 450)

(define custom-trace-log-callback
  (function-ptr
    (λ (msg-type text args)
      ;; C 只做一件事：展开 va_list → Racket 字符串，不打印
      (define buf (make-bytes 4096))
      (define len (vsnprintf buf 4096 text args))
      (define msg (bytes->string/utf-8 (subbytes buf 0 len)))

      ;; 全部在 Racket 侧处理：加前缀 + 打印到终端
      (define level-str
        (case msg-type
          [(1)  "INFO"]
          [(2)  "WARN"]
          [(4)  "ERROR"]
          [(8)  "DEBUG"]
          [else (format "~a" msg-type)]))
      (printf "[Custom Log] [~a] ~a~n" level-str msg))
    (_fun _int _string _pointer -> _void)))

(set-trace-log-callback custom-trace-log-callback)

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - custom logging")

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (begin-drawing)
    (clear-background RAYWHITE)
    (draw-text
      "Check out the console output to see the custom logger in action!"
      60 200 20 LIGHTGRAY)
    (end-drawing)
    (loop)))

(close-window)
