#lang racket/base

;; local-raylib-lib.rkt
;;
;; 存放 raylib 共享库的可能位置列表，按优先级尝试加载。
;; 首个成功加载的路径将被使用。
;;
;; 导出:
;;   find-raylib-lib  — 无参数，返回 ffi-lib 对象
;;   raylib-lib       — 加载后的 ffi-lib 对象（与 types.rkt 中 lib 等效）

(require ffi/unsafe
         racket/string)

;; 候选路径列表 — 按优先级排序
;;
;; 1. 环境变量 RAYLIB_SO_PATH (运行时可通过环境变量覆盖)
;; 2. 项目本地 build 目录 (最常用)
;; 3. libraylib.so (依赖 ldconfig / LD_LIBRARY_PATH)
;; 4. 系统标准安装路径
;; 5. 使用 raylib_pkg-config 探测
(define candidate-paths
  (list
    ;; 环境变量覆盖 (最高优先级)
    (λ () (getenv "RAYLIB_SO_PATH"))
    ;; 本地构建输出 开发时
    (λ () "/home/debian/raylib/build/raylib/libraylib.so")
    ;; 相对路径: 从 types.rkt 所在目录的 ../../build/raylib/ 找
    (λ () (let-values ([(dir _1 _2) (split-path (or (current-load-relative-directory) (current-directory)))])
            (build-path dir ".." ".." "build" "raylib" "libraylib.so")))
    ;; 标准系统安装
    (λ () "/usr/local/lib/libraylib.so")
    (λ () "/usr/lib/libraylib.so")
    (λ () "/usr/lib/x86_64-linux-gnu/libraylib.so")
    ;; ldconfig 默认名 (不指定路径)
    (λ () "libraylib.so")))

(define (find-raylib-lib)
  ;; 依次尝试候选路径，返回第一个加载成功的 ffi-lib 对象
  ;; 如果全部失败，抛出错误并列出所有尝试过的路径
  (let loop ([remaining candidate-paths]
             [tried '()])
    (if (null? remaining)
        (error 'find-raylib-lib
               "Cannot find libraylib.so. Tried paths:\n  ~a\nSet RAYLIB_SO_PATH environment variable to the correct location."
               (string-join (reverse tried) "\n  "))
        (let* ([path-thunk (car remaining)]
               [path (path-thunk)])
          (if (not path)
              (loop (cdr remaining) (cons "(null path)" tried))
              (with-handlers ([exn:fail:filesystem?
                               (λ (e)
                                 (loop (cdr remaining)
                                       (cons (format "~a (FAILED: ~a)" path (exn-message e))
                                             tried)))])
                (let ([lib (ffi-lib path)])
                  lib)))))))

;; 绑定时就加载 — 这样 types.rkt 可以直接 (require "local-raylib-lib.rkt") 拿到 raylib-lib
(define raylib-lib (find-raylib-lib))

(provide raylib-lib
         find-raylib-lib
         candidate-paths)
