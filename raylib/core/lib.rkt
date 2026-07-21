#lang racket/base

;; raylib/core/lib.rkt — 共享库加载
;;
;; 加载优先级:
;;   1. RAYLIB_SO_PATH 环境变量 (开发阶段)
;;   2. ffi-lib "libraylib" 系统搜索 (生产阶段)
;;      → LD_LIBRARY_PATH → ldconfig 缓存 → /usr/lib 等标准路径

(require ffi/unsafe)

(define lib
  (with-handlers ([exn:fail?
                   (λ (e)
                     (error 'raylib-lib
                            (string-append
                             "Cannot load libraylib.\n"
                             "  Development: set RAYLIB_SO_PATH=/path/to/libraylib.so\n"
                             "  Production:  install libraylib.so to /usr/local/lib/ and run ldconfig\n"
                             "  Error: " (exn-message e))))])
    (ffi-lib (or (getenv "RAYLIB_SO_PATH")
                 "libraylib"))))

(provide lib)
