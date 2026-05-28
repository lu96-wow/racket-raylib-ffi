#lang racket/base

;; raylib 预定义常量 — 主入口
;;
;; 提供所有常量、预定义颜色等固定值
;; 与 FFI 绑定分离，可独立使用

(require "core.rkt")

(provide (all-from-out "core.rkt"))
