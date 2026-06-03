#lang racket/base

;; rcore.rkt 杂项功能测试
;; 包括: 手势/剪贴板/Hash/颜色工具/随机/配置

(require "../helper.rkt"
         (prefix-in lib: "../../raylib/raylib.rkt"))

(printf "~n========================================~n")
(printf "  杂项功能测试~n")
(printf "========================================~n")

;; ============================================================
;; 手势
;; ============================================================
(test-section "手势")

(define (test-gestures)
  (lib:init-window 400 200 "test-gestures")
  (lib:set-target-fps 60)
  (lib:set-gestures-enabled (bitwise-ior lib:GESTURE-TAP lib:GESTURE-DRAG))
  (test-pass! "set-gestures-enabled")
   (assert-false (lib:is-gesture-detected? lib:GESTURE-TAP))
  (test-pass! "is-gesture-detected? 初始 #f")
  (assert-= (lib:get-gesture-detected) 0)
  (test-pass! "get-gesture-detected 初始 NONE")

  (printf "    hold duration: ~a~n" (lib:get-gesture-hold-duration))
  (printf "    drag angle: ~a~n" (lib:get-gesture-drag-angle))

  (define drag-v (lib:get-gesture-drag-vector))
  (printf "    drag vector: ~a, ~a~n"
          (lib:ptr-ref drag-v lib:_float 0)
          (lib:ptr-ref drag-v lib:_float 1))

  (define pinch-v (lib:get-gesture-pinch-vector))
  (printf "    pinch vector: ~a, ~a~n"
          (lib:ptr-ref pinch-v lib:_float 0)
          (lib:ptr-ref pinch-v lib:_float 1))
  (printf "    pinch angle: ~a~n" (lib:get-gesture-pinch-angle))
  (test-pass! "手势 API (无异常)")
  (lib:close-window))

(test-gestures)

;; ============================================================
;; 剪贴板
;; ============================================================
(test-section "剪贴板")

(define (test-clipboard)
  (lib:init-window 400 200 "test-clipboard")
  (lib:set-target-fps 60)
  (lib:set-clipboard-text "Hello from raylib Racket!")
  (define text (lib:get-clipboard-text))
  (printf "    剪贴板内容: ~a~n" text)
  (test-pass! "set-clipboard-text / get-clipboard-text")
  (lib:close-window))

(test-clipboard)

;; ============================================================
;; 随机数
;; ============================================================
(test-section "随机数")

(define (test-random)
  (lib:init-window 400 200 "test-random")
  (lib:set-target-fps 60)

  (define v (lib:get-random-value 0 100))
  (printf "    get-random-value(0,100) = ~a~n" v)
   (assert-true (>= v 0))
   (assert-true (<= v 100))
  (test-pass! "get-random-value 在范围内")

  (lib:set-random-seed 42)
  (define a1 (lib:get-random-value 0 1000))
  (lib:set-random-seed 42)
  (define a2 (lib:get-random-value 0 1000))
  (assert-= a1 a2)
  (test-pass! "set-random-seed 确定性")

  (define seq (lib:load-random-sequence 10 0 100))
  (assert-= (length seq) 10)
  (printf "    sequence: ~a~n" seq)
  (test-pass! "load-random-sequence (自动释放)")

  (lib:close-window))

(test-random)
