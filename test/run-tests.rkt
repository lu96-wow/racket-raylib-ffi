#lang racket/base

;; raylib Racket 绑定测试运行器
;;
;; 用法:
;;   racket run-tests.rkt                     # 运行所有测试
;;   racket run-tests.rkt shapes              # 只运行 shapes 测试
;;   racket run-tests.rkt core types math     # 运行指定测试
;;
;; 测试结构:
;;   test/core/        — rcore.rkt 相关
;;   test/shapes/      — rshapes.rkt + textures 相关
;;   test/textures/    — rtextures.rkt 独立测试
;;   test/models/      — rmodels.rkt
;;   test/math/        — raymath.rkt (纯 Racket, 无需窗口)
;;   test/var/         — 常量验证 (纯 Racket, 无需窗口)
;;   test/automation/  — automation.rkt
;;   test/camera/      — rcamera.rkt

(require racket/match)

(printf "~n")
(printf "╔══════════════════════════════════════════╗~n")
(printf "║  raylib Racket 绑定测试套件              ║~n")
(printf "╚══════════════════════════════════════════╝~n")
(printf "~n")

;; ============================================================
;; 测试索引
;; ============================================================

;; 纯 Racket 测试 (无需 OpenGL 上下文, 可安全运行)
(define pure-tests
  (list
   (list "math"   "test-raymath.rkt"   "raymath 纯 Racket 数学测试")
   (list "var"    "test-constants.rkt" "预定义常量/颜色/键值验证")))

;; 需 OpenGL 上下文的测试
(define gpu-tests
  (list
   (list "core/type" "core/test-types.rkt" "结构体构造/访问/修改")
   (list "core/win"  "core/test-window.rkt" "窗口生命周期/状态")
   (list "core/draw" "core/test-drawing.rkt" "绘制上下文/计时/Scissor")
   (list "core/input" "core/test-input.rkt" "键盘/鼠标/手柄/触摸")
   (list "core/misc" "core/test-misc.rkt" "手势/剪贴板/Hash/颜色/文件")
   (list "shapes/light" "shapes/test-top-down-lights-apis.rkt"
         "top-down-lights 示例 API 逐个测试")))

;; ============================================================
;; 运行逻辑
;; ============================================================

(define selected-filters
  (match (current-command-line-arguments)
    [(vector) '()]
    [args (for/list ([a (in-vector args)]) (string-downcase a))]))

(define (should-run? name)
  (or (null? selected-filters)
      (ormap (λ (f) (string-contains? (string-downcase name) f)) selected-filters)))

;; 运行一个测试文件
(define (run-test-file category path desc)
  (printf "─── ~a [~a] ~a~n" category path desc)
  (flush-output)
  (dynamic-require (string->symbol (format "../test/~a" path)) #f)
  (printf "~n"))

;; 运行纯 Racket 测试 (独立进程, 避免污染)
(define (run-pure name path desc)
  (printf "─── [PURE] ~a — ~a~n" name desc)
  (flush-output)
  (dynamic-require (string->symbol (format "../test/~a/~a" name path)) #f)
  (printf "~n"))

;; ============================================================
;; 执行
;; ============================================================

(printf "▸ 纯 Racket 测试 (无需窗口)~n")
(for ([t pure-tests])
  (match-define (list name path desc) t)
  (when (should-run? name)
    (run-pure name path desc)))

(printf "▸ GPU 测试 (需 OpenGL 上下文)~n")
(for ([t gpu-tests])
  (match-define (list category path desc) t)
  (when (should-run? category)
    (run-test-file category path desc)))

(printf "~n╔══════════════════════════════════════════╗~n")
(printf "║  测试完成                                 ║~n")
(printf "╚══════════════════════════════════════════╝~n")
