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
;; GenImage* — 生成图像 (返回 Image by value)
;; ============================================================

(define gen-image-gradient-linear
  (let ([f (get-ffi-obj "GenImageGradientLinear" T:lib
             (_fun _int _int _int (c1 : C:_color-bytes) (c2 : C:_color-bytes) -> (img : C:_image-bytes)))])
    (lambda (w h dir start end) (f w h dir (C:color->bytes start) (C:color->bytes end)))))

(define gen-image-gradient-radial
  (let ([f (get-ffi-obj "GenImageGradientRadial" T:lib
             (_fun _int _int _float (c1 : C:_color-bytes) (c2 : C:_color-bytes) -> (img : C:_image-bytes)))])
    (lambda (w h density inner outer) (f w h density (C:color->bytes inner) (C:color->bytes outer)))))

(define gen-image-gradient-square
  (let ([f (get-ffi-obj "GenImageGradientSquare" T:lib
             (_fun _int _int _float (c1 : C:_color-bytes) (c2 : C:_color-bytes) -> (img : C:_image-bytes)))])
    (lambda (w h density inner outer) (f w h density (C:color->bytes inner) (C:color->bytes outer)))))

(define gen-image-white-noise
  (let ([f (get-ffi-obj "GenImageWhiteNoise" T:lib
             (_fun _int _int _float -> (img : C:_image-bytes)))])
    (lambda (w h factor) (f w h factor))))

(define gen-image-perlin-noise
  (let ([f (get-ffi-obj "GenImagePerlinNoise" T:lib
             (_fun _int _int _int _int _float -> (img : C:_image-bytes)))])
    (lambda (w h offset-x offset-y scale) (f w h offset-x offset-y scale))))

(define gen-image-cellular
  (let ([f (get-ffi-obj "GenImageCellular" T:lib
             (_fun _int _int _int -> (img : C:_image-bytes)))])
    (lambda (w h tile-size) (f w h tile-size))))

(define gen-image-text
  (let ([f (get-ffi-obj "GenImageText" T:lib
             (_fun _int _int _string -> (img : C:_image-bytes)))])
    (lambda (w h text) (f w h text))))

;; ============================================================
;; Image 加载 / 导出
;; ============================================================

(define load-image-raw
  (let ([f (get-ffi-obj "LoadImageRaw" T:lib
             (_fun _string _int _int _int _int -> (img : C:_image-bytes)))])
    (lambda (filename w h format header-size) (f filename w h format header-size))))

(define load-image-anim
  (let ([f (get-ffi-obj "LoadImageAnim" T:lib
             (_fun _string _pointer -> (img : C:_image-bytes)))])
    (lambda (filename)
      (let ([frames-buf (malloc _int 1 'atomic)])
        (let ([img (f filename frames-buf)])
          (values img (ptr-ref frames-buf _int 0)))))))

(define load-image-anim-from-memory
  (let ([f (get-ffi-obj "LoadImageAnimFromMemory" T:lib
             (_fun _string _pointer _int _pointer -> (img : C:_image-bytes)))])
    (lambda (file-type data-ptr data-size)
      (let ([frames-buf (malloc _int 1 'atomic)])
        (let ([img (f file-type data-ptr data-size frames-buf)])
          (values img (ptr-ref frames-buf _int 0)))))))

(define load-image-from-memory
  (let ([f (get-ffi-obj "LoadImageFromMemory" T:lib
             (_fun _string _pointer _int -> (img : C:_image-bytes)))])
    (lambda (file-type data-ptr data-size) (f file-type data-ptr data-size))))

(define load-image-from-texture
  (let ([f (get-ffi-obj "LoadImageFromTexture" T:lib
             (_fun (t : _texture-bytes) -> (img : C:_image-bytes)))])
    (lambda (texture) (f texture))))

(define is-image-valid
  (let ([f (get-ffi-obj "IsImageValid" T:lib
             (_fun (img : C:_image-bytes) -> _stdbool))])
    (lambda (image) (f image))))

(define export-image-to-memory
  (let ([f (get-ffi-obj "ExportImageToMemory" T:lib
             (_fun (img : C:_image-bytes) _string _pointer -> _pointer))])
    (lambda (image file-type)
      (let ([size-buf (malloc _int 1 'atomic)])
        (let ([result (f image file-type size-buf)])
          (values result (ptr-ref size-buf _int 0)))))))

(define export-image-as-code
  (get-ffi-obj "ExportImageAsCode" T:lib
    (_fun (img : C:_image-bytes) _string -> _stdbool)))

;; ============================================================
;; Image 复制/操作
;; ============================================================

(define image-copy
  (let ([f (get-ffi-obj "ImageCopy" T:lib
             (_fun (img : C:_image-bytes) -> (out : C:_image-bytes)))])
    (lambda (image) (f image))))

(define image-from-image
  (let ([f (get-ffi-obj "ImageFromImage" T:lib
             (_fun (img : C:_image-bytes) (r : C:_rect-bytes) -> (out : C:_image-bytes)))])
    (lambda (image rec) (f image (C:rect->bytes rec)))))

(define image-from-channel
  (let ([f (get-ffi-obj "ImageFromChannel" T:lib
             (_fun (img : C:_image-bytes) _int -> (out : C:_image-bytes)))])
    (lambda (image channel) (f image channel))))

(define image-text
  (let ([f (get-ffi-obj "ImageText" T:lib
             (_fun _string _int (c : C:_color-bytes) -> (img : C:_image-bytes)))])
    (lambda (text font-size color) (f text font-size (C:color->bytes color)))))

(define image-text-ex
  (let ([f (get-ffi-obj "ImageTextEx" T:lib
             (_fun _pointer _string _float _float (c : C:_color-bytes) -> (img : C:_image-bytes)))])
    (lambda (font-ptr text font-size spacing tint)
      (f font-ptr text font-size spacing (C:color->bytes tint)))))

(define (image-format image-ptr new-format)
  ((get-ffi-obj "ImageFormat" T:lib (_fun _pointer _int -> _void)) image-ptr new-format))

(define (image-to-pot image-ptr fill-color)
  ((get-ffi-obj "ImageToPOT" T:lib (_fun _pointer (c : C:_color-bytes) -> _void))
   image-ptr (C:color->bytes fill-color)))

(define (image-crop image-ptr crop-rec)
  ((get-ffi-obj "ImageCrop" T:lib (_fun _pointer (r : C:_rect-bytes) -> _void))
   image-ptr (C:rect->bytes crop-rec)))

(define (image-alpha-crop image-ptr threshold)
  ((get-ffi-obj "ImageAlphaCrop" T:lib (_fun _pointer _float -> _void)) image-ptr threshold))

(define (image-alpha-clear image-ptr color threshold)
  ((get-ffi-obj "ImageAlphaClear" T:lib (_fun _pointer (c : C:_color-bytes) _float -> _void))
   image-ptr (C:color->bytes color) threshold))

(define (image-alpha-mask image-ptr mask-image)
  ((get-ffi-obj "ImageAlphaMask" T:lib (_fun _pointer _pointer -> _void)) image-ptr mask-image))

(define (image-alpha-premultiply image-ptr)
  ((get-ffi-obj "ImageAlphaPremultiply" T:lib (_fun _pointer -> _void)) image-ptr))

(define (image-blur-gaussian image-ptr blur-size)
  ((get-ffi-obj "ImageBlurGaussian" T:lib (_fun _pointer _int -> _void)) image-ptr blur-size))

(define (image-kernel-convolution image-ptr kernel-ptr kernel-size)
  ((get-ffi-obj "ImageKernelConvolution" T:lib (_fun _pointer _pointer _int -> _void))
   image-ptr kernel-ptr kernel-size))

(define (image-resize image-ptr new-w new-h)
  ((get-ffi-obj "ImageResize" T:lib (_fun _pointer _int _int -> _void)) image-ptr new-w new-h))

(define (image-resize-nn image-ptr new-w new-h)
  ((get-ffi-obj "ImageResizeNN" T:lib (_fun _pointer _int _int -> _void)) image-ptr new-w new-h))

(define (image-resize-canvas image-ptr new-w new-h offset-x offset-y fill-color)
  ((get-ffi-obj "ImageResizeCanvas" T:lib (_fun _pointer _int _int _int _int (c : C:_color-bytes) -> _void))
   image-ptr new-w new-h offset-x offset-y (C:color->bytes fill-color)))

(define (image-mipmaps image-ptr)
  ((get-ffi-obj "ImageMipmaps" T:lib (_fun _pointer -> _void)) image-ptr))

(define (image-dither image-ptr rb gb bb ab)
  ((get-ffi-obj "ImageDither" T:lib (_fun _pointer _int _int _int _int -> _void)) image-ptr rb gb bb ab))

(define (image-flip-vertical image-ptr)
  ((get-ffi-obj "ImageFlipVertical" T:lib (_fun _pointer -> _void)) image-ptr))

(define (image-flip-horizontal image-ptr)
  ((get-ffi-obj "ImageFlipHorizontal" T:lib (_fun _pointer -> _void)) image-ptr))

(define (image-rotate-cw image-ptr)
  ((get-ffi-obj "ImageRotateCW" T:lib (_fun _pointer -> _void)) image-ptr))

(define (image-rotate-ccw image-ptr)
  ((get-ffi-obj "ImageRotateCCW" T:lib (_fun _pointer -> _void)) image-ptr))

(define (image-color-tint image-ptr color)
  ((get-ffi-obj "ImageColorTint" T:lib (_fun _pointer (c : C:_color-bytes) -> _void))
   image-ptr (C:color->bytes color)))

(define (image-color-invert image-ptr)
  ((get-ffi-obj "ImageColorInvert" T:lib (_fun _pointer -> _void)) image-ptr))

(define (image-color-grayscale image-ptr)
  ((get-ffi-obj "ImageColorGrayscale" T:lib (_fun _pointer -> _void)) image-ptr))

(define (image-color-contrast image-ptr contrast)
  ((get-ffi-obj "ImageColorContrast" T:lib (_fun _pointer _int -> _void)) image-ptr contrast))

(define (image-color-brightness image-ptr brightness)
  ((get-ffi-obj "ImageColorBrightness" T:lib (_fun _pointer _int -> _void)) image-ptr brightness))

(define (image-color-replace image-ptr color replace-color)
  ((get-ffi-obj "ImageColorReplace" T:lib (_fun _pointer (c : C:_color-bytes) (r : C:_color-bytes) -> _void))
   image-ptr (C:color->bytes color) (C:color->bytes replace-color)))

(define load-image-colors
  (get-ffi-obj "LoadImageColors" T:lib (_fun (img : C:_image-bytes) -> _pointer)))

(define load-image-palette
  (let ([f (get-ffi-obj "LoadImagePalette" T:lib
             (_fun (img : C:_image-bytes) _int _pointer -> _pointer))])
    (lambda (image max-pal-size)
      (let ([count-buf (malloc _int 1 'atomic)])
        (let ([result (f image max-pal-size count-buf)])
          (values result (ptr-ref count-buf _int 0)))))))

(define (unload-image-colors colors-ptr)
  ((get-ffi-obj "UnloadImageColors" T:lib (_fun _pointer -> _void)) colors-ptr))

(define (unload-image-palette palette-ptr)
  ((get-ffi-obj "UnloadImagePalette" T:lib (_fun _pointer -> _void)) palette-ptr))

(define get-image-alpha-border
  (let ([f (get-ffi-obj "GetImageAlphaBorder" T:lib
             (_fun (img : C:_image-bytes) _float -> (r : C:_rect-bytes)))])
    (lambda (image threshold)
      (C:rect-bytes->rect (f image threshold)))))

(define get-image-color
  (let ([f (get-ffi-obj "GetImageColor" T:lib
             (_fun (img : C:_image-bytes) _int _int -> (c : C:_color-bytes)))])
    (lambda (image x y) (f image x y))))
;; ============================================================
;; 导出
;; ============================================================
;; ============================================================
;; SetMaterialTexture(Material *material, int mapType, Texture2D texture)
;; ============================================================

(define set-material-texture
  (let ([f (get-ffi-obj "SetMaterialTexture" T:lib
             (_fun _pointer _int (t : _texture-bytes) -> _void))])
    (lambda (material-ptr map-type texture)
      (f material-ptr map-type texture))))
;; ============================================================
;; Image 绘制函数
;; ============================================================

(define (image-clear-background dst-ptr color)
  ((get-ffi-obj "ImageClearBackground" T:lib (_fun _pointer (c : C:_color-bytes) -> _void))
   dst-ptr (C:color->bytes color)))

(define (image-draw-pixel dst-ptr x y color)
  ((get-ffi-obj "ImageDrawPixel" T:lib (_fun _pointer _int _int (c : C:_color-bytes) -> _void))
   dst-ptr x y (C:color->bytes color)))

(define (image-draw-pixel-v dst-ptr pos color)
  ((get-ffi-obj "ImageDrawPixelV" T:lib (_fun _pointer (p : C:_vec2-bytes) (c : C:_color-bytes) -> _void))
   dst-ptr (C:vec2->bytes pos) (C:color->bytes color)))

(define (image-draw-line dst-ptr sx sy ex ey color)
  ((get-ffi-obj "ImageDrawLine" T:lib (_fun _pointer _int _int _int _int (c : C:_color-bytes) -> _void))
   dst-ptr sx sy ex ey (C:color->bytes color)))

(define (image-draw-line-v dst-ptr start end color)
  ((get-ffi-obj "ImageDrawLineV" T:lib (_fun _pointer (s : C:_vec2-bytes) (e : C:_vec2-bytes) (c : C:_color-bytes) -> _void))
   dst-ptr (C:vec2->bytes start) (C:vec2->bytes end) (C:color->bytes color)))

(define (image-draw-line-ex dst-ptr start end thick color)
  ((get-ffi-obj "ImageDrawLineEx" T:lib (_fun _pointer (s : C:_vec2-bytes) (e : C:_vec2-bytes) _int (c : C:_color-bytes) -> _void))
   dst-ptr (C:vec2->bytes start) (C:vec2->bytes end) thick (C:color->bytes color)))

(define (image-draw-circle dst-ptr cx cy r color)
  ((get-ffi-obj "ImageDrawCircle" T:lib (_fun _pointer _int _int _int (c : C:_color-bytes) -> _void))
   dst-ptr cx cy r (C:color->bytes color)))

(define (image-draw-circle-v dst-ptr center r color)
  ((get-ffi-obj "ImageDrawCircleV" T:lib (_fun _pointer (c : C:_vec2-bytes) _int (col : C:_color-bytes) -> _void))
   dst-ptr (C:vec2->bytes center) r (C:color->bytes color)))

(define (image-draw-circle-lines dst-ptr cx cy r color)
  ((get-ffi-obj "ImageDrawCircleLines" T:lib (_fun _pointer _int _int _int (c : C:_color-bytes) -> _void))
   dst-ptr cx cy r (C:color->bytes color)))

(define (image-draw-circle-lines-v dst-ptr center r color)
  ((get-ffi-obj "ImageDrawCircleLinesV" T:lib (_fun _pointer (c : C:_vec2-bytes) _int (col : C:_color-bytes) -> _void))
   dst-ptr (C:vec2->bytes center) r (C:color->bytes color)))

(define (image-draw-rectangle dst-ptr x y w h color)
  ((get-ffi-obj "ImageDrawRectangle" T:lib (_fun _pointer _int _int _int _int (c : C:_color-bytes) -> _void))
   dst-ptr x y w h (C:color->bytes color)))

(define (image-draw-rectangle-v dst-ptr pos size color)
  ((get-ffi-obj "ImageDrawRectangleV" T:lib (_fun _pointer (p : C:_vec2-bytes) (s : C:_vec2-bytes) (c : C:_color-bytes) -> _void))
   dst-ptr (C:vec2->bytes pos) (C:vec2->bytes size) (C:color->bytes color)))

(define (image-draw-rectangle-rec dst-ptr rec color)
  ((get-ffi-obj "ImageDrawRectangleRec" T:lib (_fun _pointer (r : C:_rect-bytes) (c : C:_color-bytes) -> _void))
   dst-ptr (C:rect->bytes rec) (C:color->bytes color)))

(define (image-draw-rectangle-lines dst-ptr x y w h color)
  ((get-ffi-obj "ImageDrawRectangleLines" T:lib (_fun _pointer _int _int _int _int (c : C:_color-bytes) -> _void))
   dst-ptr x y w h (C:color->bytes color)))

(define (image-draw-rectangle-lines-ex dst-ptr rec thick color)
  ((get-ffi-obj "ImageDrawRectangleLinesEx" T:lib (_fun _pointer (r : C:_rect-bytes) _int (c : C:_color-bytes) -> _void))
   dst-ptr (C:rect->bytes rec) thick (C:color->bytes color)))

(define (image-draw-triangle dst-ptr v1 v2 v3 color)
  ((get-ffi-obj "ImageDrawTriangle" T:lib
    (_fun _pointer (p1 : C:_vec2-bytes) (p2 : C:_vec2-bytes) (p3 : C:_vec2-bytes) (c : C:_color-bytes) -> _void))
   dst-ptr (C:vec2->bytes v1) (C:vec2->bytes v2) (C:vec2->bytes v3) (C:color->bytes color)))

(define (image-draw-triangle-ex dst-ptr v1 v2 v3 c1 c2 c3)
  ((get-ffi-obj "ImageDrawTriangleGradient" T:lib
    (_fun _pointer (p1 : C:_vec2-bytes) (p2 : C:_vec2-bytes) (p3 : C:_vec2-bytes)
          (col1 : C:_color-bytes) (col2 : C:_color-bytes) (col3 : C:_color-bytes) -> _void))
   dst-ptr (C:vec2->bytes v1) (C:vec2->bytes v2) (C:vec2->bytes v3)
   (C:color->bytes c1) (C:color->bytes c2) (C:color->bytes c3)))

(define (image-draw-triangle-lines dst-ptr v1 v2 v3 color)
  ((get-ffi-obj "ImageDrawTriangleLines" T:lib
    (_fun _pointer (p1 : C:_vec2-bytes) (p2 : C:_vec2-bytes) (p3 : C:_vec2-bytes) (c : C:_color-bytes) -> _void))
   dst-ptr (C:vec2->bytes v1) (C:vec2->bytes v2) (C:vec2->bytes v3) (C:color->bytes color)))

(define (image-draw-triangle-fan dst-ptr points-ptr point-count color)
  ((get-ffi-obj "ImageDrawTriangleFan" T:lib (_fun _pointer _pointer _int (c : C:_color-bytes) -> _void))
   dst-ptr points-ptr point-count (C:color->bytes color)))

(define (image-draw-triangle-strip dst-ptr points-ptr point-count color)
  ((get-ffi-obj "ImageDrawTriangleStrip" T:lib (_fun _pointer _pointer _int (c : C:_color-bytes) -> _void))
   dst-ptr points-ptr point-count (C:color->bytes color)))

(define (image-draw dst-ptr src-image src-rec dst-rec tint)
  ((get-ffi-obj "ImageDraw" T:lib
    (_fun _pointer (src : C:_image-bytes) (sr : C:_rect-bytes) (dr : C:_rect-bytes) (c : C:_color-bytes) -> _void))
   dst-ptr src-image (C:rect->bytes src-rec) (C:rect->bytes dst-rec) (C:color->bytes tint)))

(define (image-draw-text dst-ptr text x y font-size color)
  ((get-ffi-obj "ImageDrawText" T:lib (_fun _pointer _string _int _int _int (c : C:_color-bytes) -> _void))
   dst-ptr text x y font-size (C:color->bytes color)))

(define (image-draw-text-ex dst-ptr font-ptr text pos font-size spacing tint)
  ((get-ffi-obj "ImageDrawTextEx" T:lib
    (_fun _pointer _pointer _string (p : C:_vec2-bytes) _float _float (c : C:_color-bytes) -> _void))
   dst-ptr font-ptr text (C:vec2->bytes pos) font-size spacing (C:color->bytes tint)))

;; ============================================================
;; 纹理扩展
;; ============================================================

(define load-texture-cubemap
  (let ([f (get-ffi-obj "LoadTextureCubemap" T:lib
             (_fun (img : C:_image-bytes) _int -> (t : _texture-bytes)))])
    (lambda (image layout) (f image layout))))

(define is-texture-valid
  (let ([f (get-ffi-obj "IsTextureValid" T:lib
             (_fun (t : _texture-bytes) -> _stdbool))])
    (lambda (texture) (f texture))))

(define is-render-texture-valid
  (let ([f (get-ffi-obj "IsRenderTextureValid" T:lib
             (_fun (rt : _render-texture-bytes) -> _stdbool))])
    (lambda (render-texture) (f render-texture))))

(define (update-texture-rec texture ptr rec)
  ((get-ffi-obj "UpdateTextureRec" T:lib (_fun (t : _texture-bytes) (r : C:_rect-bytes) _pointer -> _void))
   texture (C:rect->bytes rec) ptr))

(define (gen-texture-mipmaps texture-ptr)
  ((get-ffi-obj "GenTextureMipmaps" T:lib (_fun _pointer -> _void)) texture-ptr))

(define (set-texture-wrap texture wrap)
  ((get-ffi-obj "SetTextureWrap" T:lib (_fun (t : _texture-bytes) _int -> _void)) texture wrap))

(define draw-texture-v
  (let ([f (get-ffi-obj "DrawTextureV" T:lib
             (_fun (t : _texture-bytes) (pos : C:_vec2-bytes) (c : C:_color-bytes) -> _void))])
    (lambda (texture position tint)
      (f texture (C:vec2->bytes position) (C:color->bytes tint)))))

(define draw-texture-n-patch
  (let ([f (get-ffi-obj "DrawTextureNPatch" T:lib
             (_fun (t : _texture-bytes) _pointer (dst : C:_rect-bytes)
                   (orig : C:_vec2-bytes) _float (c : C:_color-bytes) -> _void))])
    (lambda (texture n-patch-info-ptr dest origin rotation tint)
      (f texture n-patch-info-ptr (C:rect->bytes dest)
         (C:vec2->bytes origin) rotation (C:color->bytes tint)))))
(provide
 _texture-bytes _render-texture-bytes
 load-texture unload-texture draw-texture
 load-render-texture unload-render-texture
 begin-texture-mode end-texture-mode
 draw-texture-rec
 set-texture-filter
 draw-texture-pro draw-texture-v draw-texture-ex
 gen-image-checked load-texture-from-image
 load-image load-image-from-texture
 image-rotate image-crop image-flip-vertical image-flip-horizontal
 image-resize image-resize-nn image-resize-canvas
 image-draw image-draw-pixel image-draw-circle-lines image-draw-rectangle
 image-draw-text image-draw-text-ex
 image-to-pot image-alpha-crop image-alpha-clear
 image-alpha-mask image-alpha-premultiply image-blur-gaussian
 image-kernel-convolution image-dither
 image-rotate-cw image-rotate-ccw image-color-tint
 image-color-invert image-color-grayscale image-color-contrast
 image-color-brightness image-color-replace
 gen-image-color gen-image-gradient-linear
 gen-image-gradient-radial gen-image-gradient-square
 gen-image-white-noise gen-image-perlin-noise gen-image-cellular
 gen-image-text
 update-texture update-texture-rec
 is-image-valid is-texture-valid is-render-texture-valid
 export-image-to-memory export-image-as-code
 image-copy image-from-image image-from-channel
 image-text image-text-ex
 load-image-raw load-image-anim load-image-anim-from-memory
 load-image-from-memory load-image-colors load-image-palette
 unload-image-colors unload-image-palette
 get-image-alpha-border get-image-color
 set-material-texture
 gen-texture-mipmaps set-texture-wrap
 load-texture-cubemap
 ;; image-draw-line / image-draw-circle / image-draw-rectangle-lines 等绘制函数
 image-draw-line image-draw-circle image-draw-rectangle-lines
 image-draw-triangle image-draw-triangle-lines
 image-clear-background
 draw-texture-n-patch
 image-draw-pixel-v image-draw-circle-v image-draw-circle-lines-v
 image-draw-rectangle-v image-draw-rectangle-rec image-draw-rectangle-lines-ex
 image-draw-triangle-fan image-draw-triangle-strip
 image-draw-line-v image-draw-line-ex
 image-draw-triangle-ex)

