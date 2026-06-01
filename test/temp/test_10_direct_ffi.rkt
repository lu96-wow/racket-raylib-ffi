#lang racket/base

;; test_10: 用 _cprocedure 直接绑 DrawTextureRec, 绕过 _list-struct

(require ffi/unsafe
         (prefix-in T: "../../raylib/types.rkt")
         (prefix-in C: "../../raylib/rcore.rkt"))

;; 手动定义 Texture bytes (和 _texture-bytes 一样)
(define _texture-bytes (_list-struct _uint _int _int _int _int))

;; 用 _cprocedure 直接绑定 (测试 list-struct vs ctype 的区别)
(define draw-texture-rec-direct
  (let ([f (get-ffi-obj "DrawTextureRec" T:lib
             (_fun (t : _texture-bytes)
                   (r : C:_rect-bytes)
                   (p : C:_vec2-bytes)
                   (c : C:_color-bytes) -> _void))])
    f))  ;; 直接返回 f, 不包 λ

(printf "Direct binding type: ~a\n" (object-name draw-texture-rec-direct))
(printf "Test passed - binding exists\n")
