#lang racket/base

;; raylib Racket FFI 绑定 — 主入口
;;
;; 使用:
;;   (require "raylib.rkt")
;;
;; 模块结构（对应 C 源文件）:
;;   ┌─────────────┬──────────────────┬──────────────────────┐
;;   │ 模块文件    │ 对应 C 源        │ 功能                 │
;;   ├─────────────┼──────────────────┼──────────────────────┤
;;   │ types.rkt   │ raylib.h (类型)  │ struct/enum 定义     │
;;   │ rcore.rkt   │ rcore.c          │ 窗口/输入/绘制上下文 │
;;   │ rshapes.rkt │ rshapes.c        │ 2D 形状绘制          │
;;   │ rtextures.rkt│ rtextures.c     │ 纹理/图像            │
;;   │ rtext.rkt   │ rtext.c          │ 文字/字体            │
;;   │ rmodels.rkt │ rmodels.c        │ 3D/模型              │
;;   │ raudio.rkt  │ raudio.c         │ 音频                 │
;;   │ rcamera.rkt │ rcamera.h        │ 相机控制             │
;;   └─────────────┴──────────────────┴──────────────────────┘
;;
;; 策略: 按需绑定
;;   - 从 core 示例开始，用到哪个函数/结构体就绑哪个
;;   - 不预先绑定全部 API，避免无法测试的裸露 FFI

(require "rcore.rkt"
         "types.rkt"
         "rshapes.rkt"
         "rtextures.rkt"
         "rmodels.rkt"
         "rcamera.rkt"
         "../raylib-var/var.rkt")

;; 统一导出所有子模块内容
(provide (all-from-out "rcore.rkt" "types.rkt" "rshapes.rkt" "rtextures.rkt" "rmodels.rkt" "rcamera.rkt" "../raylib-var/var.rkt"))

