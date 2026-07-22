#lang racket/base

;; core/rtextures.rkt — 纹理/图像函数绑定 (rtextures.h)

(require ffi/unsafe
         "ffi-helpers.rkt"
         "types/image.rkt")

(define load-texture
  (let ([f (get-ffi-obj "LoadTexture" lib (_fun _string -> (t : _texture-bytes)))])
    (λ (filename) (f filename))))
(define load-texture-from-image
  (let ([f (get-ffi-obj "LoadTextureFromImage" lib
                        (_fun (img : _image-bytes) -> (t : _texture-bytes)))])
    (λ (image) (f image))))
(define load-texture-cubemap
  (let ([f (get-ffi-obj "LoadTextureCubemap" lib
                        (_fun (img : _image-bytes) _int -> (t : _texture-bytes)))])
    (lambda (image layout) (f image layout))))
(define unload-texture
  (let ([f (get-ffi-obj "UnloadTexture" lib (_fun (t : _texture-bytes) -> _void))])
    (λ (t) (f t))))
(define is-texture-valid
  (let ([f (get-ffi-obj "IsTextureValid" lib (_fun (t : _texture-bytes) -> _stdbool))])
    (lambda (t) (f t))))
(define update-texture
  (let ([f (get-ffi-obj "UpdateTexture" lib (_fun (t : _texture-bytes) _pointer -> _void))])
    (λ (t p) (f t p))))
(define (update-texture-rec texture ptr rec)
  ((get-ffi-obj "UpdateTextureRec" lib (_fun (t : _texture-bytes) (r : _rectangle-bytes) _pointer -> _void))
   texture (rectangle->bytes rec) ptr))
(define set-texture-filter
  (let ([f (get-ffi-obj "SetTextureFilter" lib (_fun (t : _texture-bytes) _int -> _void))])
    (λ (t fm) (f t fm))))
(define (set-texture-wrap texture wrap)
  ((get-ffi-obj "SetTextureWrap" lib (_fun (t : _texture-bytes) _int -> _void)) texture wrap))
(define (gen-texture-mipmaps texture-ptr)
  ((get-ffi-obj "GenTextureMipmaps" lib (_fun _pointer -> _void)) texture-ptr))
(define draw-texture
  (let ([f (get-ffi-obj "DrawTexture" lib
                        (_fun (t : _texture-bytes) _int _int (c : _color-bytes) -> _void))])
    (λ (t x y c) (f t x y (color->bytes c)))))
(define draw-texture-v
  (let ([f (get-ffi-obj "DrawTextureV" lib
                        (_fun (t : _texture-bytes) (pos : _vec2-bytes) (c : _color-bytes) -> _void))])
    (lambda (t p c) (f t (vec2->bytes p) (color->bytes c)))))
(define draw-texture-rec
  (let ([f (get-ffi-obj "DrawTextureRec" lib
                        (_fun (t : _texture-bytes) (r : _rectangle-bytes)
                              (p : _vec2-bytes) (c : _color-bytes) -> _void))])
    (λ (t src pos c) (f t (rectangle->bytes src) (vec2->bytes pos) (color->bytes c)))))
(define draw-texture-ex
  (let ([f (get-ffi-obj "DrawTextureEx" lib
                        (_fun (t : _texture-bytes) (p : _vec2-bytes) _float _float
                              (c : _color-bytes) -> _void))])
    (λ (t p rot scl c) (f t (vec2->bytes p) rot scl (color->bytes c)))))
(define draw-texture-pro
  (let ([f (get-ffi-obj "DrawTexturePro" lib
                        (_fun (t : _texture-bytes) (src : _rectangle-bytes) (dst : _rectangle-bytes)
                              (org : _vec2-bytes) _float (col : _color-bytes) -> _void))])
    (λ (t src dst org rot c)
      (f t (rectangle->bytes src) (rectangle->bytes dst) (vec2->bytes org) rot (color->bytes c)))))
(define draw-texture-n-patch
  (let ([f (get-ffi-obj "DrawTextureNPatch" lib
                        (_fun (t : _texture-bytes) (n : _npatch-info-bytes)
                              (dst : _rectangle-bytes) (orig : _vec2-bytes) _float
                              (c : _color-bytes) -> _void))])
    (lambda (t npi dst orig rot c)
      (f t npi (rectangle->bytes dst) (vec2->bytes orig) rot (color->bytes c)))))
(define load-render-texture
  (let ([f (get-ffi-obj "LoadRenderTexture" lib
                        (_fun _int _int -> (rt : _render-texture-bytes)))])
    (λ (w h) (f w h))))
(define unload-render-texture
  (let ([f (get-ffi-obj "UnloadRenderTexture" lib
                        (_fun (rt : _render-texture-bytes) -> _void))])
    (λ (t) (f t))))
(define is-render-texture-valid
  (let ([f (get-ffi-obj "IsRenderTextureValid" lib
                        (_fun (rt : _render-texture-bytes) -> _stdbool))])
    (lambda (rt) (f rt))))
(define begin-texture-mode
  (let ([f (get-ffi-obj "BeginTextureMode" lib
                        (_fun (rt : _render-texture-bytes) -> _void))])
    (λ (t) (f t))))
(define end-texture-mode (get-ffi-obj "EndTextureMode" lib (_fun -> _void)))
(define load-image
  (let ([f (get-ffi-obj "LoadImage" lib (_fun _string -> (img : _image-bytes)))])
    (λ (fn) (f fn))))
(define load-image-raw
  (let ([f (get-ffi-obj "LoadImageRaw" lib
                        (_fun _string _int _int _int _int -> (img : _image-bytes)))])
    (lambda (fn w h fmt hs) (f fn w h fmt hs))))
(define load-image-anim
  (let ([f (get-ffi-obj "LoadImageAnim" lib (_fun _string _pointer -> (img : _image-bytes)))])
    (lambda (fn) (let ([fb (malloc _int 1 'atomic)])
                   (let ([img (f fn fb)]) (values img (ptr-ref fb _int 0)))))))
(define load-image-anim-from-memory
  (let ([f (get-ffi-obj "LoadImageAnimFromMemory" lib
                        (_fun _string _pointer _int _pointer -> (img : _image-bytes)))])
    (lambda (ft dp ds) (let ([fb (malloc _int 1 'atomic)])
                          (let ([img (f ft dp ds fb)]) (values img (ptr-ref fb _int 0)))))))
(define load-image-from-memory
  (let ([f (get-ffi-obj "LoadImageFromMemory" lib
                        (_fun _string _pointer _int -> (img : _image-bytes)))])
    (lambda (ft dp ds) (f ft dp ds))))
(define load-image-from-texture
  (let ([f (get-ffi-obj "LoadImageFromTexture" lib
                        (_fun (t : _texture-bytes) -> (img : _image-bytes)))])
    (lambda (t) (f t))))
(define is-image-valid
  (let ([f (get-ffi-obj "IsImageValid" lib (_fun (img : _image-bytes) -> _stdbool))])
    (lambda (img) (f img))))
(define image-copy
  (let ([f (get-ffi-obj "ImageCopy" lib (_fun (img : _image-bytes) -> (out : _image-bytes)))])
    (lambda (img) (f img))))
(define image-from-image
  (let ([f (get-ffi-obj "ImageFromImage" lib
                        (_fun (img : _image-bytes) (r : _rectangle-bytes) -> (out : _image-bytes)))])
    (lambda (img rec) (f img (rectangle->bytes rec)))))
(define image-from-channel
  (let ([f (get-ffi-obj "ImageFromChannel" lib
                        (_fun (img : _image-bytes) _int -> (out : _image-bytes)))])
    (lambda (img ch) (f img ch))))
(define (image-format! ip nf) ((get-ffi-obj "ImageFormat" lib (_fun _pointer _int -> _void)) ip nf))
(define (image-to-pot ip fc)
  ((get-ffi-obj "ImageToPOT" lib (_fun _pointer (c : _color-bytes) -> _void)) ip (color->bytes fc)))
(define (image-crop ip cr)
  ((get-ffi-obj "ImageCrop" lib (_fun _pointer (r : _rectangle-bytes) -> _void)) ip (rectangle->bytes cr)))
(define (image-alpha-crop ip t) ((get-ffi-obj "ImageAlphaCrop" lib (_fun _pointer _float -> _void)) ip t))
(define (image-alpha-clear ip c t)
  ((get-ffi-obj "ImageAlphaClear" lib (_fun _pointer (c : _color-bytes) _float -> _void))
   ip (color->bytes c) t))
(define (image-alpha-mask ip mi)
  ((get-ffi-obj "ImageAlphaMask" lib (_fun _pointer (mask : _image-bytes) -> _void)) ip mi))
(define (image-alpha-premultiply ip) ((get-ffi-obj "ImageAlphaPremultiply" lib (_fun _pointer -> _void)) ip))
(define (image-blur-gaussian ip bs) ((get-ffi-obj "ImageBlurGaussian" lib (_fun _pointer _int -> _void)) ip bs))
(define (image-kernel-convolution ip kp ks)
  ((get-ffi-obj "ImageKernelConvolution" lib (_fun _pointer _pointer _int -> _void)) ip kp ks))
(define (image-resize ip w h) ((get-ffi-obj "ImageResize" lib (_fun _pointer _int _int -> _void)) ip w h))
(define (image-resize-nn ip w h) ((get-ffi-obj "ImageResizeNN" lib (_fun _pointer _int _int -> _void)) ip w h))
(define (image-resize-canvas ip w h ox oy fc)
  ((get-ffi-obj "ImageResizeCanvas" lib (_fun _pointer _int _int _int _int (c : _color-bytes) -> _void))
   ip w h ox oy (color->bytes fc)))
(define (image-mipmaps! ip) ((get-ffi-obj "ImageMipmaps" lib (_fun _pointer -> _void)) ip))
(define (image-dither ip r g b a)
  ((get-ffi-obj "ImageDither" lib (_fun _pointer _int _int _int _int -> _void)) ip r g b a))
(define (image-flip-vertical ip) ((get-ffi-obj "ImageFlipVertical" lib (_fun _pointer -> _void)) ip))
(define (image-flip-horizontal ip) ((get-ffi-obj "ImageFlipHorizontal" lib (_fun _pointer -> _void)) ip))
(define (image-rotate-cw ip) ((get-ffi-obj "ImageRotateCW" lib (_fun _pointer -> _void)) ip))
(define (image-rotate-ccw ip) ((get-ffi-obj "ImageRotateCCW" lib (_fun _pointer -> _void)) ip))
(define (image-color-tint ip c)
  ((get-ffi-obj "ImageColorTint" lib (_fun _pointer (c : _color-bytes) -> _void)) ip (color->bytes c)))
(define (image-color-invert ip) ((get-ffi-obj "ImageColorInvert" lib (_fun _pointer -> _void)) ip))
(define (image-color-grayscale ip) ((get-ffi-obj "ImageColorGrayscale" lib (_fun _pointer -> _void)) ip))
(define (image-color-contrast ip ct) ((get-ffi-obj "ImageColorContrast" lib (_fun _pointer _int -> _void)) ip ct))
(define (image-color-brightness ip br) ((get-ffi-obj "ImageColorBrightness" lib (_fun _pointer _int -> _void)) ip br))
(define (image-color-replace ip c rc)
  ((get-ffi-obj "ImageColorReplace" lib (_fun _pointer (c : _color-bytes) (r : _color-bytes) -> _void))
   ip (color->bytes c) (color->bytes rc)))
(define image-rotate
  (let ([rf (get-ffi-obj "ImageRotate" lib (_fun _pointer _int -> _void))])
    (λ (image degrees)
      (let ([ip (malloc _Image 'atomic)])
        (ptr-set! ip _pointer 0 (list-ref image 0))
        (ptr-set! ip _int 2 (list-ref image 1)) (ptr-set! ip _int 3 (list-ref image 2))
        (ptr-set! ip _int 4 (list-ref image 3)) (ptr-set! ip _int 5 (list-ref image 4))
        (rf ip degrees)
        (list (ptr-ref ip _pointer 0) (ptr-ref ip _int 2) (ptr-ref ip _int 3)
              (ptr-ref ip _int 4) (ptr-ref ip _int 5))))))
(define export-image-to-memory
  (let ([f (get-ffi-obj "ExportImageToMemory" lib
                        (_fun (img : _image-bytes) _string _pointer -> _pointer))])
    (lambda (image ft) (let ([sb (malloc _int 1 'atomic)])
                          (let ([r (f image ft sb)]) (values r (ptr-ref sb _int 0)))))))
(define export-image-as-code
  (get-ffi-obj "ExportImageAsCode" lib (_fun (img : _image-bytes) _string -> _stdbool)))
(define load-image-colors (get-ffi-obj "LoadImageColors" lib (_fun (img : _image-bytes) -> _pointer)))
(define load-image-palette
  (let ([f (get-ffi-obj "LoadImagePalette" lib
                        (_fun (img : _image-bytes) _int _pointer -> _pointer))])
    (lambda (image mps) (let ([cb (malloc _int 1 'atomic)])
                           (let ([r (f image mps cb)]) (values r (ptr-ref cb _int 0)))))))
(define (unload-image-colors cp) ((get-ffi-obj "UnloadImageColors" lib (_fun _pointer -> _void)) cp))
(define (unload-image-palette pp) ((get-ffi-obj "UnloadImagePalette" lib (_fun _pointer -> _void)) pp))
(define get-image-alpha-border
  (let ([f (get-ffi-obj "GetImageAlphaBorder" lib
                        (_fun (img : _image-bytes) _float -> (r : _rectangle-bytes)))])
    (lambda (image t) (bytes->rectangle (f image t)))))
(define get-image-color
  (let ([f (get-ffi-obj "GetImageColor" lib
                        (_fun (img : _image-bytes) _int _int -> (c : _color-bytes)))])
    (lambda (image x y) (f image x y))))
(define gen-image-color
  (let ([f (get-ffi-obj "GenImageColor" lib
                        (_fun _int _int (c : _color-bytes) -> (img : _image-bytes)))])
    (λ (w h c) (f w h (color->bytes c)))))
(define gen-image-checked
  (let ([f (get-ffi-obj "GenImageChecked" lib
                        (_fun _int _int _int _int (c1 : _color-bytes) (c2 : _color-bytes) -> (img : _image-bytes)))])
    (λ (w h cx cy c1 c2) (f w h cx cy (color->bytes c1) (color->bytes c2)))))
(define gen-image-gradient-linear
  (let ([f (get-ffi-obj "GenImageGradientLinear" lib
                        (_fun _int _int _int (c1 : _color-bytes) (c2 : _color-bytes) -> (img : _image-bytes)))])
    (lambda (w h dir s e) (f w h dir (color->bytes s) (color->bytes e)))))
(define gen-image-gradient-radial
  (let ([f (get-ffi-obj "GenImageGradientRadial" lib
                        (_fun _int _int _float (c1 : _color-bytes) (c2 : _color-bytes) -> (img : _image-bytes)))])
    (lambda (w h d i o) (f w h d (color->bytes i) (color->bytes o)))))
(define gen-image-gradient-square
  (let ([f (get-ffi-obj "GenImageGradientSquare" lib
                        (_fun _int _int _float (c1 : _color-bytes) (c2 : _color-bytes) -> (img : _image-bytes)))])
    (lambda (w h d i o) (f w h d (color->bytes i) (color->bytes o)))))
(define gen-image-white-noise
  (let ([f (get-ffi-obj "GenImageWhiteNoise" lib (_fun _int _int _float -> (img : _image-bytes)))])
    (lambda (w h fct) (f w h fct))))
(define gen-image-perlin-noise
  (let ([f (get-ffi-obj "GenImagePerlinNoise" lib
                        (_fun _int _int _int _int _float -> (img : _image-bytes)))])
    (lambda (w h ox oy s) (f w h ox oy s))))
(define gen-image-cellular
  (let ([f (get-ffi-obj "GenImageCellular" lib (_fun _int _int _int -> (img : _image-bytes)))])
    (lambda (w h ts) (f w h ts))))
(define gen-image-text
  (let ([f (get-ffi-obj "GenImageText" lib (_fun _int _int _string -> (img : _image-bytes)))])
    (lambda (w h t) (f w h t))))
(define image-text
  (let ([f (get-ffi-obj "ImageText" lib
                        (_fun _string _int (c : _color-bytes) -> (img : _image-bytes)))])
    (lambda (text fs c) (f text fs (color->bytes c)))))
(define image-text-ex
  (let ([f (get-ffi-obj "ImageTextEx" lib
                        (_fun _pointer _string _float _float (c : _color-bytes) -> (img : _image-bytes)))])
    (lambda (fp text fs sp t) (f fp text fs sp (color->bytes t)))))
(define (image-clear-background dp c)
  ((get-ffi-obj "ImageClearBackground" lib (_fun _pointer (c : _color-bytes) -> _void)) dp (color->bytes c)))
(define (image-draw-pixel dp x y c)
  ((get-ffi-obj "ImageDrawPixel" lib (_fun _pointer _int _int (c : _color-bytes) -> _void))
   dp x y (color->bytes c)))
(define (image-draw-pixel-v dp p c)
  ((get-ffi-obj "ImageDrawPixelV" lib (_fun _pointer (p : _vec2-bytes) (c : _color-bytes) -> _void))
   dp (vec2->bytes p) (color->bytes c)))
(define (image-draw-line dp sx sy ex ey c)
  ((get-ffi-obj "ImageDrawLine" lib (_fun _pointer _int _int _int _int (c : _color-bytes) -> _void))
   dp sx sy ex ey (color->bytes c)))
(define (image-draw-line-v dp s e c)
  ((get-ffi-obj "ImageDrawLineV" lib (_fun _pointer (s : _vec2-bytes) (e : _vec2-bytes) (c : _color-bytes) -> _void))
   dp (vec2->bytes s) (vec2->bytes e) (color->bytes c)))
(define (image-draw-line-ex dp s e t c)
  ((get-ffi-obj "ImageDrawLineEx" lib
    (_fun _pointer (s : _vec2-bytes) (e : _vec2-bytes) _int (c : _color-bytes) -> _void))
   dp (vec2->bytes s) (vec2->bytes e) t (color->bytes c)))
(define (image-draw-circle dp cx cy r c)
  ((get-ffi-obj "ImageDrawCircle" lib (_fun _pointer _int _int _int (c : _color-bytes) -> _void))
   dp cx cy r (color->bytes c)))
(define (image-draw-circle-v dp center r c)
  ((get-ffi-obj "ImageDrawCircleV" lib
    (_fun _pointer (cc : _vec2-bytes) _int (col : _color-bytes) -> _void))
   dp (vec2->bytes center) r (color->bytes c)))
(define (image-draw-circle-lines dp cx cy r c)
  ((get-ffi-obj "ImageDrawCircleLines" lib
    (_fun _pointer _int _int _int (c : _color-bytes) -> _void)) dp cx cy r (color->bytes c)))
(define (image-draw-circle-lines-v dp center r c)
  ((get-ffi-obj "ImageDrawCircleLinesV" lib
    (_fun _pointer (cc : _vec2-bytes) _int (col : _color-bytes) -> _void))
   dp (vec2->bytes center) r (color->bytes c)))
(define (image-draw-rectangle dp x y w h c)
  ((get-ffi-obj "ImageDrawRectangle" lib
    (_fun _pointer _int _int _int _int (c : _color-bytes) -> _void)) dp x y w h (color->bytes c)))
(define (image-draw-rectangle-v dp p s c)
  ((get-ffi-obj "ImageDrawRectangleV" lib
    (_fun _pointer (p : _vec2-bytes) (s : _vec2-bytes) (c : _color-bytes) -> _void))
   dp (vec2->bytes p) (vec2->bytes s) (color->bytes c)))
(define (image-draw-rectangle-rec dp rec c)
  ((get-ffi-obj "ImageDrawRectangleRec" lib
    (_fun _pointer (r : _rectangle-bytes) (c : _color-bytes) -> _void)) dp (rectangle->bytes rec) (color->bytes c)))
(define (image-draw-rectangle-lines dp x y w h c)
  ((get-ffi-obj "ImageDrawRectangleLines" lib
    (_fun _pointer _int _int _int _int (c : _color-bytes) -> _void)) dp x y w h (color->bytes c)))
(define (image-draw-rectangle-lines-ex dp rec t c)
  ((get-ffi-obj "ImageDrawRectangleLinesEx" lib
    (_fun _pointer (r : _rectangle-bytes) _int (c : _color-bytes) -> _void)) dp (rectangle->bytes rec) t (color->bytes c)))
(define (image-draw-triangle dp v1 v2 v3 c)
  ((get-ffi-obj "ImageDrawTriangle" lib
    (_fun _pointer (p1 : _vec2-bytes) (p2 : _vec2-bytes) (p3 : _vec2-bytes) (c : _color-bytes) -> _void))
   dp (vec2->bytes v1) (vec2->bytes v2) (vec2->bytes v3) (color->bytes c)))
(define (image-draw-triangle-ex dp v1 v2 v3 c1 c2 c3)
  ((get-ffi-obj "ImageDrawTriangleGradient" lib
    (_fun _pointer (p1 : _vec2-bytes) (p2 : _vec2-bytes) (p3 : _vec2-bytes)
          (co1 : _color-bytes) (co2 : _color-bytes) (co3 : _color-bytes) -> _void))
   dp (vec2->bytes v1) (vec2->bytes v2) (vec2->bytes v3)
   (color->bytes c1) (color->bytes c2) (color->bytes c3)))
(define (image-draw-triangle-lines dp v1 v2 v3 c)
  ((get-ffi-obj "ImageDrawTriangleLines" lib
    (_fun _pointer (p1 : _vec2-bytes) (p2 : _vec2-bytes) (p3 : _vec2-bytes) (c : _color-bytes) -> _void))
   dp (vec2->bytes v1) (vec2->bytes v2) (vec2->bytes v3) (color->bytes c)))
(define (image-draw-triangle-fan dp pp pc c)
  ((get-ffi-obj "ImageDrawTriangleFan" lib
    (_fun _pointer _pointer _int (c : _color-bytes) -> _void)) dp pp pc (color->bytes c)))
(define (image-draw-triangle-strip dp pp pc c)
  ((get-ffi-obj "ImageDrawTriangleStrip" lib
    (_fun _pointer _pointer _int (c : _color-bytes) -> _void)) dp pp pc (color->bytes c)))
(define (image-draw dp si sr dr t)
  ((get-ffi-obj "ImageDraw" lib
    (_fun _pointer (src : _image-bytes) (sr : _rectangle-bytes) (dr : _rectangle-bytes) (c : _color-bytes) -> _void))
   dp si (rectangle->bytes sr) (rectangle->bytes dr) (color->bytes t)))
(define (image-draw-text dp text x y fs c)
  ((get-ffi-obj "ImageDrawText" lib
    (_fun _pointer _string _int _int _int (c : _color-bytes) -> _void)) dp text x y fs (color->bytes c)))
(define (image-draw-text-ex dp font text pos fs sp t)
  ((get-ffi-obj "ImageDrawTextEx" lib
    (_fun _pointer (font : _font-bytes) _string (p : _vec2-bytes) _float _float (c : _color-bytes) -> _void))
   dp font text (vec2->bytes pos) fs sp (color->bytes t)))
(define set-material-texture
  (let ([f (get-ffi-obj "SetMaterialTexture" lib (_fun _pointer _int (t : _texture-bytes) -> _void))])
    (lambda (mp mt t) (f mp mt t))))
(define (set-material-shader mp s) (ptr-set! mp _shader-bytes s))
(define (set-material-color mp mt cp)
  (let ([maps-ptr (ptr-ref mp _pointer 2)])
    (let ([map-ptr (ptr-add maps-ptr (* mt 28))])
      (ptr-set! map-ptr _ubyte 20 (ptr-ref cp _ubyte 0))
      (ptr-set! map-ptr _ubyte 21 (ptr-ref cp _ubyte 1))
      (ptr-set! map-ptr _ubyte 22 (ptr-ref cp _ubyte 2))
      (ptr-set! map-ptr _ubyte 23 (ptr-ref cp _ubyte 3)))))

(provide
 load-texture load-texture-from-image
 load-texture-cubemap unload-texture is-texture-valid
 update-texture update-texture-rec set-texture-filter set-texture-wrap
 gen-texture-mipmaps draw-texture draw-texture-v draw-texture-rec
 draw-texture-ex draw-texture-pro draw-texture-n-patch
 load-render-texture unload-render-texture is-render-texture-valid
 begin-texture-mode end-texture-mode
 load-image load-image-raw load-image-anim load-image-anim-from-memory
 load-image-from-memory load-image-from-texture is-image-valid
 image-copy image-from-image image-from-channel
 image-format! image-to-pot image-crop image-alpha-crop image-alpha-clear
 image-alpha-mask image-alpha-premultiply image-blur-gaussian
 image-kernel-convolution image-resize image-resize-nn image-resize-canvas
 image-mipmaps! image-dither image-flip-vertical image-flip-horizontal
 image-rotate-cw image-rotate-ccw image-color-tint image-color-invert
 image-color-grayscale image-color-contrast image-color-brightness
 image-color-replace image-rotate
 export-image-to-memory export-image-as-code
 load-image-colors load-image-palette unload-image-colors unload-image-palette
 get-image-alpha-border get-image-color
 gen-image-color gen-image-checked gen-image-gradient-linear
 gen-image-gradient-radial gen-image-gradient-square
 gen-image-white-noise gen-image-perlin-noise gen-image-cellular
 gen-image-text image-text image-text-ex
 image-clear-background image-draw image-draw-pixel image-draw-pixel-v
 image-draw-line image-draw-line-v image-draw-line-ex
 image-draw-circle image-draw-circle-v image-draw-circle-lines
 image-draw-circle-lines-v image-draw-rectangle image-draw-rectangle-v
 image-draw-rectangle-rec image-draw-rectangle-lines image-draw-rectangle-lines-ex
 image-draw-triangle image-draw-triangle-ex image-draw-triangle-lines
 image-draw-triangle-fan image-draw-triangle-strip
 image-draw-text image-draw-text-ex
 set-material-texture set-material-shader set-material-color)
