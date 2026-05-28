#lang racket/base
;; 最小测试：验证 is-key-down 是否在无按键时返回 #f
(require "../../raylib/raylib.rkt")

(init-window 100 100 "bool test")
(set-target-fps 60)

(printf "is-key-down A (no press): ~a~n" (is-key-down KEY-A))
(printf "is-key-down S (no press): ~a~n" (is-key-down KEY-S))
(printf "is-key-down RIGHT (no press): ~a~n" (is-key-down KEY-RIGHT))
(printf "window-should-close?: ~a~n" (window-should-close?))

(close-window)
