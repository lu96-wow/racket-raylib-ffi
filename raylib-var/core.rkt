#lang racket/base

;; raylib-var/core.rkt — 预定义常量聚合入口
;;
;; 常量按分类拆分到:
;;   colors.rkt — 预定义颜色
;;   input.rkt  — 键盘/鼠标/手柄/手势
;;   config.rkt — 窗口/相机/图形/纹理等配置

(require "colors.rkt"
         "input.rkt"
         "config.rkt")

(provide (all-from-out "colors.rkt")
         (all-from-out "input.rkt")
         (all-from-out "config.rkt"))
