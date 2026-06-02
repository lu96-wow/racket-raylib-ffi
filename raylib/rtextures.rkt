#lang racket/base

;; raylib textures 模块 — 纹理/图像加载与绘制
;;
;; 对应 C: rtextures.c / raylib.h "Module: textures"
;; 包括: LoadTexture, UnloadTexture, DrawTexture, LoadRenderTexture 等
;;
;; Texture / Texture2D 是 20 字节小结构体：
;;   unsigned int id;     // _uint   4B
;;   int width;           // _int    4B
;;   int height;          // _int    4B
;;   int mipmaps;         // _int    4B
;;   int format;          // _int    4B
;; 总计: 20B，C 侧传值，Racket 侧以 list 持有
;;
;; RenderTexture 是 44 字节小结构体（内嵌两个 Texture）:
;;   unsigned int id;     // _uint   4B
;;   Texture texture;     // 20B (内嵌)
;;   Texture depth;       // 20B (内嵌)
;; 总计: 44B

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
;; RenderTexture 传值类型
;; RenderTexture 是 11 字段 flat struct:
;;   id, tex-id, tex-w, tex-h, tex-mip, tex-fmt, dep-id, dep-w, dep-h, dep-mip, dep-fmt
;; ============================================================

(define _render-texture-bytes
  (_list-struct _uint _uint _int _int _int _int _uint _int _int _int _int))

;; ============================================================
;; LoadRenderTexture(int width, int height) -> RenderTexture
;; 返回: 11 元素 list (id tex-id tex-w tex-h tex-mip tex-fmt
;;                      dep-id dep-w dep-h dep-mip dep-fmt)
;; ============================================================

(define load-render-texture
  (let ([f (get-ffi-obj "LoadRenderTexture" T:lib
             (_fun _int _int -> (rt : _render-texture-bytes)))])
    (λ (width height) (f width height))))

;; ============================================================
;; UnloadRenderTexture(RenderTexture target) -> void
;; target 是 load-render-texture 返回的 11 元素 list
;; ============================================================

(define unload-render-texture
  (let ([f (get-ffi-obj "UnloadRenderTexture" T:lib
             (_fun (rt : _render-texture-bytes) -> _void))])
    (λ (target) (f target))))

;; ============================================================
;; BeginTextureMode(RenderTexture target) -> void
;; target 是 load-render-texture 返回的 11 元素 list
;; ============================================================

(define begin-texture-mode
  (let ([f (get-ffi-obj "BeginTextureMode" T:lib
             (_fun (rt : _render-texture-bytes) -> _void))])
    (λ (target) (f target))))

;; ============================================================
;; EndTextureMode(void) -> void
;; Ends drawing to render texture
;; ============================================================

(define end-texture-mode
  (get-ffi-obj "EndTextureMode" T:lib (_fun -> _void)))

;; ============================================================
;; DrawTextureRec(Texture2D texture, Rectangle source, Vector2 position, Color tint)
;; Draw a part of a texture defined by a rectangle
;; ============================================================

(define draw-texture-rec
  (let ([f (get-ffi-obj "DrawTextureRec" T:lib
             (_fun (t : _texture-bytes)
                   (r : C:_rect-bytes)
                   (p : C:_vec2-bytes)
                   (c : C:_color-bytes) -> _void))])
    (λ (texture source position tint)
      (f texture
         (C:rect->bytes source)
         (C:vec2->bytes position)
         (C:color->bytes tint)))))

;; ============================================================
;; SetTextureFilter(Texture2D texture, int filter) — 设置纹理缩放过滤 (core_window_letterbox.c)
;; ============================================================

(define set-texture-filter
  (let ([f (get-ffi-obj "SetTextureFilter" T:lib
             (_fun (t : _texture-bytes) _int -> _void))])
    (λ (texture filter-mode)
      (f texture filter-mode))))

;; ============================================================
;; DrawTexturePro(Texture2D texture, Rectangle source, Rectangle dest,
;;                Vector2 origin, float rotation, Color tint)
;; 高级纹理绘制 (core_window_letterbox.c)
;; ============================================================

(define draw-texture-pro
  (let ([f (get-ffi-obj "DrawTexturePro" T:lib
             (_fun (t : _texture-bytes)
                   (src : C:_rect-bytes) (dst : C:_rect-bytes)
                   (org : C:_vec2-bytes) _float
                   (col : C:_color-bytes) -> _void))])
    (λ (texture source dest origin rotation tint)
      (f texture
         (C:rect->bytes source) (C:rect->bytes dest)
         (C:vec2->bytes origin) rotation
         (C:color->bytes tint)))))

;; ============================================================
;; Image 生成与纹理加载 (shapes_top_down_lights.c)
;; GenImageChecked / LoadTextureFromImage
;; (_image-bytes 和 unload-image 已在 rcore.rkt 中定义)
;; ============================================================

;; GenImageChecked(int width, int height, int checksX, int checksY, Color c1, Color c2) -> Image
(define gen-image-checked
  (let ([f (get-ffi-obj "GenImageChecked" T:lib
             (_fun _int _int _int _int (c1 : C:_color-bytes) (c2 : C:_color-bytes)
                   -> (img : C:_image-bytes)))])
    (λ (w h cx cy col1 col2)
      (f w h cx cy (C:color->bytes col1) (C:color->bytes col2)))))

;; LoadTextureFromImage(Image image) -> Texture2D
(define load-texture-from-image
  (let ([f (get-ffi-obj "LoadTextureFromImage" T:lib
             (_fun (img : C:_image-bytes) -> (t : _texture-bytes)))])
    (λ (image) (f image))))
;; ============================================================
;; Image 文件加载 (textures_image_rotate.c)
;; LoadImage(const char *fileName) -> Image
;; ============================================================

(define load-image
  (let ([f (get-ffi-obj "LoadImage" T:lib
             (_fun _string -> (img : C:_image-bytes)))])
    (λ (filename) (f filename))))

;; ============================================================
;; ImageRotate(Image *image, int degrees) — 图像旋转
;; C 函数接受指针，所以需要 malloc 创建临时 struct，调用后回读
;;
;; Image struct 布局（24 字节，64-bit）：
;;   byte  0-7:  data  (_pointer)
;;   byte  8-11: width (_int)    → ptr-ref _int 2
;;   byte 12-15: height (_int)   → ptr-ref _int 3
;;   byte 16-19: mipmaps (_int)  → ptr-ref _int 4
;;   byte 20-23: format (_int)   → ptr-ref _int 5
;; ============================================================

(define image-rotate
  ;; 注意: image-rotate 是函数式调用，返回新列表，不修改原列表！
  ;; C 的 ImageRotate 会释放旧 data 指针并分配新 data，
  ;; 所以返回的列表包含新 data 指针，原列表的 data 指针变为垂悬。
  ;; 调用方需用 (set! img (image-rotate img deg)) 更新。
  (let ([rotate-f (get-ffi-obj "ImageRotate" T:lib
                    (_fun _pointer _int -> _void))])
    (λ (image degrees)
      ;; image 是 5 元素列表: (data width height mipmaps format)
      (let ([img-ptr (malloc T:_Image 'atomic)])
        ;; 将 list 数据写入 struct
        (ptr-set! img-ptr _pointer 0 (list-ref image 0))
        (ptr-set! img-ptr _int 2 (list-ref image 1))
        (ptr-set! img-ptr _int 3 (list-ref image 2))
        (ptr-set! img-ptr _int 4 (list-ref image 3))
        (ptr-set! img-ptr _int 5 (list-ref image 4))
        ;; 调用 C 函数修改 struct
        (rotate-f img-ptr degrees)
        ;; 回读修改后的数据
        (let ([new-data (ptr-ref img-ptr _pointer 0)]
              [new-width (ptr-ref img-ptr _int 2)]
              [new-height (ptr-ref img-ptr _int 3)]
              [new-mipmaps (ptr-ref img-ptr _int 4)]
              [new-format (ptr-ref img-ptr _int 5)])
          ;; 注意: malloc 'atomic 是 GC 内存，不需要 free
          (list new-data new-width new-height new-mipmaps new-format))))))

;; ============================================================
;; GenImageColor(int width, int height, Color color) -> Image
;; 生成纯色图像 (textures_screen_buffer.c)
;; ============================================================

(define gen-image-color
  (let ([f (get-ffi-obj "GenImageColor" T:lib
             (_fun _int _int (c : C:_color-bytes) -> (img : C:_image-bytes)))])
    (λ (w h color)
      (f w h (C:color->bytes color)))))

;; ============================================================
;; UpdateTexture(Texture2D texture, const void *pixels) -> void
;; 更新 GPU 纹理数据 (textures_screen_buffer.c)
;; ============================================================

(define update-texture
  (let ([f (get-ffi-obj "UpdateTexture" T:lib
             (_fun (t : _texture-bytes) _pointer -> _void))])
    (λ (texture pixels) (f texture pixels))))

;; ============================================================
;; DrawTextureEx(Texture2D texture, Vector2 position,
;;               float rotation, float scale, Color tint) -> void
;; 高级纹理绘制 (textures_screen_buffer.c)
;; ============================================================

(define draw-texture-ex
  (let ([f (get-ffi-obj "DrawTextureEx" T:lib
             (_fun (t : _texture-bytes)
                   (p : C:_vec2-bytes) _float _float
                   (c : C:_color-bytes) -> _void))])
    (λ (texture position rotation scale tint)
      (f texture
         (C:vec2->bytes position)
         rotation scale
         (C:color->bytes tint)))))

;; ============================================================
;; 导出
;; ============================================================

(provide
 _texture-bytes _render-texture-bytes
 load-texture unload-texture draw-texture
 load-render-texture unload-render-texture
 begin-texture-mode end-texture-mode
 draw-texture-rec
 set-texture-filter
 draw-texture-pro
 gen-image-checked load-texture-from-image
 load-image image-rotate
 gen-image-color update-texture draw-texture-ex)


;; ============================================================
;; 导出
;; ============================================================

(provide
 _texture-bytes _render-texture-bytes
 load-texture unload-texture draw-texture
 load-render-texture unload-render-texture
 begin-texture-mode end-texture-mode
 draw-texture-rec
 set-texture-filter
 draw-texture-pro
 gen-image-checked load-texture-from-image
 load-image image-rotate)

