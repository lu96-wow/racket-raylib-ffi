#lang racket/base

;; raylib [shaders] example - hot reloading (Racket FFI 翻译)
;;
;; 对应 C: examples/shaders/shaders_hot_reloading.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         racket/date
         ffi/unsafe
         (only-in ffi/unsafe ptr-set! _float malloc))

(define GLSL-VERSION 330)

(define-runtime-path resource-dir "../../../examples/shaders/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window 800 450 "raylib [shaders] example - hot reloading")

(define frag-shader-filepath (res (format "shaders/glsl~a/reload.fs" GLSL-VERSION)))
(define frag-shader-file-mod-time (get-file-mod-time frag-shader-filepath))

;; 加载初始着色器
(define shader (load-shader #f frag-shader-filepath))

;; 获取 uniform 位置
(define resolution-loc (get-shader-location shader "resolution"))
(define mouse-loc (get-shader-location shader "mouse"))
(define time-loc (get-shader-location shader "time"))

(define resolution (malloc _float 2 'atomic))
(ptr-set! resolution _float 0 800.0) (ptr-set! resolution _float 1 450.0)
(set-shader-value shader resolution-loc resolution SHADER-UNIFORM-VEC2)

(define total-time 0.0)
(define shader-auto-reloading #f)

(define mouse-pos (malloc _float 2 'atomic))

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    ;; Update
    (set! total-time (+ total-time (get-frame-time)))

    (let ([mouse (get-mouse-position)])
      (ptr-set! mouse-pos _float 0 (ptr-ref mouse _float 0))
      (ptr-set! mouse-pos _float 1 (ptr-ref mouse _float 1)))

    ;; 设置 uniform
    (set-shader-value shader time-loc
                      (let ([t (malloc _float 1 'atomic)])
                        (ptr-set! t _float 0 total-time) t)
                      SHADER-UNIFORM-FLOAT)
    (set-shader-value shader mouse-loc mouse-pos SHADER-UNIFORM-VEC2)

    ;; 热重装着色器
    (when (or shader-auto-reloading (is-mouse-button-pressed MOUSE-BUTTON-LEFT))
      (let ([current-mod-time (get-file-mod-time frag-shader-filepath)])
        (unless (= current-mod-time frag-shader-file-mod-time)
          (let ([updated-shader (load-shader #f frag-shader-filepath)])
            (unless (= (car updated-shader) (rl-get-shader-id-default))
              ;; 着色器加载成功
              (unload-shader shader)
              (set! shader updated-shader)
              (set! resolution-loc (get-shader-location shader "resolution"))
              (set! mouse-loc (get-shader-location shader "mouse"))
              (set! time-loc (get-shader-location shader "time"))
              (set-shader-value shader resolution-loc resolution SHADER-UNIFORM-VEC2)))
          (set! frag-shader-file-mod-time current-mod-time))))

    (when (is-key-pressed KEY-A)
      (set! shader-auto-reloading (not shader-auto-reloading)))

    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-shader-mode shader)
    (draw-rectangle 0 0 800 450 WHITE)
    (end-shader-mode)

    (draw-text (format "PRESS [A] to TOGGLE SHADER AUTOLOADING: ~a"
                       (if shader-auto-reloading "AUTO" "MANUAL"))
               10 10 10 (if shader-auto-reloading RED BLACK))
    (unless shader-auto-reloading
      (draw-text "MOUSE CLICK to SHADER RE-LOADING" 10 30 10 BLACK))

    (let ([dt (seconds->date frag-shader-file-mod-time)])
      (draw-text (format "Shader last modification: ~a"
                         (date->string dt #t))
                 10 430 10 BLACK))

    (end-drawing)
    (loop)))

(unload-shader shader)
(close-window)
