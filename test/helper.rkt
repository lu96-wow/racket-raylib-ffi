#lang racket/base

;; raylib 绑定测试辅助工具
;;
;; 提供:
;;   test-fixture  — 创建/销毁窗口的宏（用于需 OpenGL 上下文的测试）
;;   assert-=     — 数值约等断言
;;   assert-color= — Color 指针逐分量断言
;;   assert-true/false 等简写
;;   with-window  — 在窗口上下文中执行测试体，自动 cleanup

(require racket/match
         (prefix-in lib: "../raylib/raylib.rkt"))


;; ============================================================
;; 数值约等断言 (float 比较)
;; ============================================================

(define (assert-true actual)
  (unless actual
    (error 'assert-true "expected #t but got ~a" actual)))

(define (assert-false actual)
  (when actual
    (error 'assert-false "expected #f but got ~a" actual)))

(define (assert-= actual expected #:epsilon [eps 0.001])
  (unless (number? actual)
    (error 'assert-=
           "expected a number but got ~a" actual))
  (unless (number? expected)
    (error 'assert-=
           "expected a number but got ~a" expected))
  (unless (< (abs (- actual expected)) eps)
    (error 'assert-=
           "expected ~a but got ~a (epsilon=~a)"
           expected actual eps)))


;; ============================================================
;; Color 指针断言
;; ============================================================

(define (assert-color= actual r g b a)
  (unless (and (= (lib:ptr-ref actual lib:_ubyte 0) r)
               (= (lib:ptr-ref actual lib:_ubyte 1) g)
               (= (lib:ptr-ref actual lib:_ubyte 2) b)
               (= (lib:ptr-ref actual lib:_ubyte 3) a))
    (error 'assert-color=
           "expected (~a ~a ~a ~a) but got (~a ~a ~a ~a)"
           r g b a
           (lib:ptr-ref actual lib:_ubyte 0)
           (lib:ptr-ref actual lib:_ubyte 1)
           (lib:ptr-ref actual lib:_ubyte 2)
           (lib:ptr-ref actual lib:_ubyte 3))))


;; ============================================================
;; Vector2 指针断言
;; ============================================================

(define (assert-vec2= actual ex ey #:epsilon [eps 0.001])
  (define ax (lib:ptr-ref actual lib:_float 0))
  (define ay (lib:ptr-ref actual lib:_float 1))
  (unless (and (< (abs (- ax ex)) eps) (< (abs (- ay ey)) eps))
    (error 'assert-vec2= "expected (~a ~a) but got (~a ~a)" ex ey ax ay)))


;; ============================================================
;; Vector3 指针断言
;; ============================================================

(define (assert-vec3= actual ex ey ez #:epsilon [eps 0.001])
  (define ax (lib:ptr-ref actual lib:_float 0))
  (define ay (lib:ptr-ref actual lib:_float 1))
  (define az (lib:ptr-ref actual lib:_float 2))
  (unless (and (< (abs (- ax ex)) eps)
               (< (abs (- ay ey)) eps)
               (< (abs (- az ez)) eps))
    (error 'assert-vec3= "expected (~a ~a ~a) but got (~a ~a ~a)" ex ey ez ax ay az)))


;; ============================================================
;; Rectangle 指针断言
;; ============================================================

(define (assert-rect= actual ex ey ew eh #:epsilon [eps 0.001])
  (define ax (lib:ptr-ref actual lib:_float 0))
  (define ay (lib:ptr-ref actual lib:_float 1))
  (define aw (lib:ptr-ref actual lib:_float 2))
  (define ah (lib:ptr-ref actual lib:_float 3))
  (unless (and (< (abs (- ax ex)) eps) (< (abs (- ay ey)) eps)
               (< (abs (- aw ew)) eps) (< (abs (- ah eh)) eps))
    (error 'assert-rect= "expected (~a ~a ~a ~a) but got (~a ~a ~a ~a)"
           ex ey ew eh ax ay aw ah)))


;; ============================================================
;; 窗口测试夹具: with-window
;; 用法: (with-window body-expr ...)
;; 自动 init-window + 主循环 + close-window
;; ============================================================

(define-syntax-rule (with-window w h title body ...)
  (let ()
    (lib:set-config-flags lib:FLAG-VSYNC-HINT)
    (lib:init-window w h title)
    (lib:set-target-fps 60)
    (let loop ()
      (unless (lib:window-should-close?)
        (lib:begin-drawing)
        (lib:clear-background lib:RAYWHITE)
        body ...
        (lib:end-drawing)
        (loop)))
    (lib:close-window)))


;; ============================================================
;; 无窗口测试: 需要手动 init-window / close-window 的测试
;; ============================================================

(define-syntax-rule (with-init-window body ...)
  (let ()
    (lib:init-window 640 480 "test")
    (lib:set-target-fps 60)
    body ...
    (lib:close-window)))


;; ============================================================
;; 简单打印测试结果
;; ============================================================

(define (test-pass! name)
  (printf "  ✓ ~a~n" name))

(define (test-skip! name reason)
  (printf "  ⚠ ~a [SKIP: ~a]~n" name reason))

(define (test-section name)
  (printf "~n=== ~a ===~n" name))


(provide
 ;; 断言
 assert-= assert-true assert-false
 assert-color= assert-vec2= assert-vec3= assert-rect=
 ;; 夹具
 with-window with-init-window
 ;; 打印
 test-pass! test-skip! test-section)
