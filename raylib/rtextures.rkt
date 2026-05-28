#lang racket/base

;; raylib textures 模块 — 纹理/图像加载与绘制
;;
;; 对应 C: rtextures.c / raylib.h "Module: textures"
;; 包括: LoadTexture, UnloadTexture, DrawTexture 等
;;
;; Texture / Texture2D 是 20 字节小结构体：
;;   unsigned int id;     // _uint   4B
;;   int width;           // _int    4B
;;   int height;          // _int    4B
;;   int mipmaps;         // _int    4B
;;   int format;          // _int    4B
;; 总计: 20B，C 侧传值，Racket 侧以 list 持有

(require ffi/unsafe
         (prefix-in T: "types.rkt")
         (prefix-in C: "rcore.rkt"))

;; ============================================================
;; Texture 传值类型
;; ============================================================

(define _texture-bytes
  (_list-struct _uint _int _int _int _int))

;; ============================================================
;; LoadTexture(const char *fileName) -> Texture2D
;; 返回: list (id width height mipmaps format)
;; ============================================================

(define load-texture
  (let ([f (get-ffi-obj "LoadTexture" T:lib
             (_fun _string -> (t : _texture-bytes)))])
    (λ (filename) (f filename))))

;; ============================================================
;; UnloadTexture(Texture2D texture) -> void
;; ============================================================

(define unload-texture
  (let ([f (get-ffi-obj "UnloadTexture" T:lib
             (_fun (t : _texture-bytes) -> _void))])
    (λ (texture) (f texture))))

;; ============================================================
;; DrawTexture(Texture2D texture, int posX, int posY, Color tint)
;; ============================================================

(define draw-texture
  (let ([f (get-ffi-obj "DrawTexture" T:lib
             (_fun (t : _texture-bytes) _int _int (c : C:_color-bytes) -> _void))])
    (λ (texture posX posY tint)
      (f texture posX posY (C:color->bytes tint)))))

;; ============================================================
;; 导出
;; ============================================================

(provide
 _texture-bytes
 load-texture unload-texture draw-texture)

