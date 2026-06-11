#lang racket/base

;; raylib [text] example - font sdf (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_font_sdf.c

(require ffi/unsafe
         "../../raylib/raylib.rkt")

;; ============================================================
;; 资源路径
;; ============================================================

(define resource-dir
  (path->string (build-path (current-directory) "../../../examples/text/resources/")))

;; ============================================================
;; GLSL 版本
;; ============================================================

(define GLSL-VERSION 330)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - font sdf")

(define msg "Signed Distance Fields")

;; Loading file to memory
(define-values (file-data file-size)
  (load-file-data (string-append resource-dir "anonymous_pro_bold.ttf")))

;; Default font generation from TTF font
(define font-default (get-font-default))
;; The font-default returned is just the default font, we need to load from TTF
;; Actually, in C they create a custom font from file data

;; SDF font generation from TTF font
;; Load font glyphs with SDF mode
;; NOTE: load-font-data 的第7个参数 glyphCount 是 int* 输出参数
;; NOTE: gen-image-font-atlas 的第2个参数 glyphRecs 是 Rectangle** 输出参数，不能传 #f
(define default-glyph-count (malloc _int 1 'atomic))
(ptr-set! default-glyph-count _int 0 95)
(define default-glyphs (load-font-data file-data file-size 16 #f 95 FONT-DEFAULT default-glyph-count))
(define default-recs-out (malloc _pointer 1 'atomic))
(define default-atlas (gen-image-font-atlas default-glyphs default-recs-out 95 16 4 0))
(define default-texture (load-texture-from-image default-atlas))
(unload-image default-atlas)
(define default-recs (ptr-ref default-recs-out _pointer 0))

(define sdf-glyph-count (malloc _int 1 'atomic))
(ptr-set! sdf-glyph-count _int 0 95)
(define sdf-glyphs (load-font-data file-data file-size 16 #f 0 FONT-SDF sdf-glyph-count))
(define sdf-recs-out (malloc _pointer 1 'atomic))
(define sdf-atlas (gen-image-font-atlas sdf-glyphs sdf-recs-out 95 16 0 1))
(define sdf-texture (load-texture-from-image sdf-atlas))
(unload-image sdf-atlas)
(define sdf-recs (ptr-ref sdf-recs-out _pointer 0))

;; Free file data
(unload-file-data file-data)

;; Load SDF required shader (we use default vertex shader, so pass #f = NULL for vs)
(define shader (load-shader #f (string-append resource-dir
                                              "shaders/glsl" (number->string GLSL-VERSION) "/sdf.fs")))
(set-texture-filter sdf-texture TEXTURE-FILTER-BILINEAR)  ; Required for SDF font

;; Build font structures manually
;; Font struct: baseSize glyphCount glyphPadding tex-id tex-w tex-h tex-mip tex-fmt recs-ptr glyphs-ptr
(define font-default-struct
  (list 16 95 0
        (list-ref default-texture 0)   ; tex id
        (list-ref default-texture 1)   ; tex width
        (list-ref default-texture 2)   ; tex height
        (list-ref default-texture 3)   ; tex mipmaps
        (list-ref default-texture 4)   ; tex format
        default-recs                   ; recs ptr (from GenImageFontAtlas)
        default-glyphs))

(define font-sdf-struct
  (list 16 95 0
        (list-ref sdf-texture 0)       ; tex id
        (list-ref sdf-texture 1)       ; tex width
        (list-ref sdf-texture 2)       ; tex height
        (list-ref sdf-texture 3)       ; tex mipmaps
        (list-ref sdf-texture 4)       ; tex format
        sdf-recs                       ; recs ptr (from GenImageFontAtlas)
        sdf-glyphs))

(define font-position (vector2 40.0 (- (/ screen-height 2.0) 50.0)))
(define font-size (box 16.0))
(define current-font (box 0))  ; 0 - fontDefault, 1 - fontSDF

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; 更新
    (set-box! font-size (+ (unbox font-size) (* (get-mouse-wheel-move) 8.0)))

    (when (< (unbox font-size) 6.0)
      (set-box! font-size 6.0))

    (if (is-key-down KEY-SPACE)
        (set-box! current-font 1)
        (set-box! current-font 0))

    (let ([text-size
           (if (= (unbox current-font) 0)
               (measure-text-ex font-default-struct msg (unbox font-size) 0.0)
               (measure-text-ex font-sdf-struct msg (unbox font-size) 0.0))])
      (set-vector2-x! font-position (- (/ (get-screen-width) 2.0) (/ (vector2-x text-size) 2.0)))
      (set-vector2-y! font-position (- (+ (/ (get-screen-height) 2.0) 80.0) (/ (vector2-y text-size) 2.0))))

    ;; 绘制
    (begin-drawing)

    (clear-background RAYWHITE)

    (if (= (unbox current-font) 1)
        (begin
          ;; NOTE: SDF fonts require a custom SDF shader to compute fragment color
          (begin-shader-mode shader)
          (draw-text-ex font-sdf-struct msg font-position (unbox font-size) 0.0 BLACK)
          (end-shader-mode)
          (draw-texture sdf-texture 10 10 BLACK))
        (begin
          (draw-text-ex font-default-struct msg font-position (unbox font-size) 0.0 BLACK)
          (draw-texture default-texture 10 10 BLACK)))

    (if (= (unbox current-font) 1)
        (draw-text "SDF!" 320 20 80 RED)
        (draw-text "default font" 315 40 30 GRAY))

    (draw-text "FONT SIZE: 16.0" (- (get-screen-width) 240) 20 20 DARKGRAY)
    (draw-text (format "RENDER SIZE: ~a" (unbox font-size)) (- (get-screen-width) 240) 50 20 DARKGRAY)
    (draw-text "Use MOUSE WHEEL to SCALE TEXT!" (- (get-screen-width) 240) 90 10 DARKGRAY)
    (draw-text "HOLD SPACE to USE SDF FONT VERSION!" 340 (- (get-screen-height) 30) 20 MAROON)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-font-data default-glyphs 95)
(unload-font-data sdf-glyphs 95)
(unload-shader shader)
(close-window)
