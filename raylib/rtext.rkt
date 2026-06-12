#lang racket/base

(require ffi/unsafe
         (prefix-in T: "types.rkt")
         (prefix-in C: "rcore.rkt")
         (prefix-in RL: "rlgl.rkt"))

(define lib T:lib)

(define _font-bytes
  (_list-struct _int _int _int
                _uint _int _int _int _int
                _pointer _pointer))

;; ============================================================
;; Font 加载/卸载
;; ============================================================

(define load-font
  (let ([f (get-ffi-obj "LoadFont" lib
             (_fun _string -> (font : _font-bytes)))])
    (lambda (file-name) (f file-name))))

(define load-font-ex
  (let ([f (get-ffi-obj "LoadFontEx" lib
             (_fun _string _int _pointer _int -> (font : _font-bytes)))])
    (lambda (file-name font-size codepoints-ptr codepoint-count)
      (f file-name font-size codepoints-ptr codepoint-count))))

(define load-font-from-image
  (let ([f (get-ffi-obj "LoadFontFromImage" lib
             (_fun _pointer _uint _int -> (font : _font-bytes)))])
    (lambda (image-ptr key first-char)
      (f image-ptr key first-char))))

(define load-font-from-memory
  (let ([f (get-ffi-obj "LoadFontFromMemory" lib
             (_fun _string _pointer _int _int _pointer _int -> (font : _font-bytes)))])
    (lambda (file-type data-ptr data-size font-size codepoints-ptr codepoint-count)
      (f file-type data-ptr data-size font-size codepoints-ptr codepoint-count))))

(define is-font-valid
  (let ([f (get-ffi-obj "IsFontValid" lib
             (_fun (font : _font-bytes) -> _stdbool))])
    (lambda (font) (f font))))

;; LoadFontData(const unsigned char *fileData, int dataSize, int fontSize,
;;              int *codepoints, int codepointCount, int type, int *glyphCount) -> GlyphInfo*
;; NOTE: glyphCount 是输出参数（int*），调用方需传 malloc 分配的 int 缓冲区
(define load-font-data
  (let ([f (get-ffi-obj "LoadFontData" lib
             (_fun _pointer _int _int _pointer _int _int _pointer -> _pointer))])
    (lambda (data-ptr data-size font-size codepoints-ptr codepoint-count type glyph-count-ptr)
      (f data-ptr data-size font-size codepoints-ptr codepoint-count type glyph-count-ptr))))

;; GenImageFontAtlas(const GlyphInfo *glyphs, Rectangle **glyphRecs, int glyphsCount,
;;                   int fontSize, int padding, int packMethod) -> Image
;; NOTE: 返回 Image 按值，不是指针
(define gen-image-font-atlas
  (let ([f (get-ffi-obj "GenImageFontAtlas" lib
             (_fun _pointer _pointer _int _int _int _int -> (img : C:_image-bytes)))])
    (lambda (glyphs-ptr recs-ptr glyph-count font-size padding pack-method)
      (f glyphs-ptr recs-ptr glyph-count font-size padding pack-method))))

(define (unload-font-data glyphs-ptr glyph-count)
  ((get-ffi-obj "UnloadFontData" lib (_fun _pointer _int -> _void)) glyphs-ptr glyph-count))

(define (unload-font font)
  ((get-ffi-obj "UnloadFont" lib (_fun (font : _font-bytes) -> _void)) font))

(define (export-font-as-code font file-name)
  ((get-ffi-obj "ExportFontAsCode" lib (_fun (font : _font-bytes) _string -> _stdbool))
   font file-name))

;; ============================================================
;; 字体绘制
;; ============================================================

(define draw-text-ex
  (let ([f (get-ffi-obj "DrawTextEx" lib
             (_fun (font : _font-bytes) _string (pos : C:_vec2-bytes) _float _float (c : C:_color-bytes) -> _void))])
    (lambda (font text position font-size spacing tint)
      (f font text (C:vec2->bytes position) font-size spacing (C:color->bytes tint)))))

(define draw-text-pro
  (let ([f (get-ffi-obj "DrawTextPro" lib
             (_fun (font : _font-bytes) _string (pos : C:_vec2-bytes) (orig : C:_vec2-bytes)
                   _float _float _float (c : C:_color-bytes) -> _void))])
    (lambda (font text position origin rotation font-size spacing tint)
      (f font text (C:vec2->bytes position) (C:vec2->bytes origin)
         rotation font-size spacing (C:color->bytes tint)))))

(define draw-text-codepoint
  (let ([f (get-ffi-obj "DrawTextCodepoint" lib
             (_fun (font : _font-bytes) _int (pos : C:_vec2-bytes) _float (c : C:_color-bytes) -> _void))])
    (lambda (font codepoint position font-size tint)
      (f font codepoint (C:vec2->bytes position) font-size (C:color->bytes tint)))))

(define draw-text-codepoints
  (let ([f (get-ffi-obj "DrawTextCodepoints" lib
             (_fun (font : _font-bytes) _pointer _int (pos : C:_vec2-bytes) _float _float (c : C:_color-bytes) -> _void))])
    (lambda (font codepoints-ptr count position font-size spacing tint)
      (f font codepoints-ptr count (C:vec2->bytes position) font-size spacing (C:color->bytes tint)))))

(define (set-text-line-spacing spacing)
  ((get-ffi-obj "SetTextLineSpacing" lib (_fun _int -> _void)) spacing))

(define measure-text-codepoints
  (let ([f (get-ffi-obj "MeasureTextCodepoints" lib
             (_fun (font : _font-bytes) _pointer _int _float _float -> (v : C:_vec2-bytes)))])
    (lambda (font codepoints-ptr count font-size spacing)
      (C:vec2-bytes->vec2 (f font codepoints-ptr count font-size spacing)))))

;; ============================================================
;; Glyph
;; ============================================================

(define get-glyph-index
  (let ([f (get-ffi-obj "GetGlyphIndex" lib
             (_fun (font : _font-bytes) _int -> _int))])
    (lambda (font codepoint) (f font codepoint))))

;; GlyphInfo 按值返回：value, offsetX, offsetY, advanceX, img-data, img-w, img-h, img-mip, img-fmt
(define _glyph-info-bytes
  (_list-struct _int _int _int _int _pointer _int _int _int _int))

(define get-glyph-info
  (let ([f (get-ffi-obj "GetGlyphInfo" lib
             (_fun (font : _font-bytes) _int -> (g : _glyph-info-bytes)))])
    (lambda (font codepoint) (f font codepoint))))

(define get-glyph-atlas-rec
  (let ([f (get-ffi-obj "GetGlyphAtlasRec" lib
             (_fun (font : _font-bytes) _int -> (r : C:_rect-bytes)))])
    (lambda (font codepoint)
      (C:rect-bytes->rect (f font codepoint)))))

;; ============================================================
;; 3D 文字绘制 (基于 rlgl 即时模式)
;; ============================================================

;; GlyphInfo / Rectangle 结构体大小 (用于指针偏移)
(define _glyph-info-size (ctype-sizeof T:_GlyphInfo))
(define _rect-size (ctype-sizeof T:_Rectangle))

;; DrawTextCodepoint3D — 在 3D 空间绘制单个字符
(define (draw-text-codepoint-3d font codepoint position font-size backface? tint)
  (let* ([base-size   (list-ref font 0)]
         [glyph-count (list-ref font 1)]
         [glyph-pad   (list-ref font 2)]
         [tex-id      (list-ref font 3)]
         [tex-width   (list-ref font 4)]
         [tex-height  (list-ref font 5)]
         [recs-ptr    (list-ref font 8)]
         [glyphs-ptr  (list-ref font 9)]
         [index       (get-glyph-index font codepoint)]
         [scale       (/ font-size (exact->inexact base-size))]
         [glyph-ptr   (ptr-add glyphs-ptr (* index _glyph-info-size))]
         [offset-x    (ptr-ref glyph-ptr _int 1)]
         [offset-y    (ptr-ref glyph-ptr _int 2)]
         [rec-ptr     (ptr-add recs-ptr (* index _rect-size))]
         [rec-x       (ptr-ref rec-ptr _float 0)]
         [rec-y       (ptr-ref rec-ptr _float 1)]
         [rec-w       (ptr-ref rec-ptr _float 2)]
         [rec-h       (ptr-ref rec-ptr _float 3)]
         [px (+ (ptr-ref position _float 0) (* (- offset-x glyph-pad) scale))]
         [py (ptr-ref position _float 1)]
         [pz (+ (ptr-ref position _float 2) (* (- offset-y glyph-pad) scale))]
         [src-x  (- rec-x glyph-pad)]
         [src-y  (- rec-y glyph-pad)]
         [src-w  (+ rec-w (* 2.0 glyph-pad))]
         [src-h  (+ rec-h (* 2.0 glyph-pad))]
         [width  (* src-w scale)]
         [height (* src-h scale)]
         [tx  (/ src-x tex-width)]
         [ty  (/ src-y tex-height)]
         [tw  (/ (+ src-x src-w) tex-width)]
         [th  (/ (+ src-y src-h) tex-height)])
    (when (> tex-id 0)
      (RL:rl-check-render-batch-limit (+ 4 (if backface? 4 0)))
      (RL:rl-set-texture tex-id)
      (RL:rl-push-matrix)
      (RL:rl-translate-f px py pz)
      (RL:rl-begin RL:RL-QUADS)
      (let ([r (ptr-ref tint _ubyte 0)]
            [g (ptr-ref tint _ubyte 1)]
            [b (ptr-ref tint _ubyte 2)]
            [a (ptr-ref tint _ubyte 3)])
        (RL:rl-color-4ub r g b a)
        (RL:rl-normal-3f 0.0 1.0 0.0)
        (RL:rl-tex-coord-2f tx ty) (RL:rl-vertex-3f 0.0 0.0 0.0)
        (RL:rl-tex-coord-2f tx th) (RL:rl-vertex-3f 0.0 0.0 height)
        (RL:rl-tex-coord-2f tw th) (RL:rl-vertex-3f width 0.0 height)
        (RL:rl-tex-coord-2f tw ty) (RL:rl-vertex-3f width 0.0 0.0)
        (when backface?
          (RL:rl-normal-3f 0.0 -1.0 0.0)
          (RL:rl-tex-coord-2f tx ty) (RL:rl-vertex-3f 0.0 0.0 0.0)
          (RL:rl-tex-coord-2f tw ty) (RL:rl-vertex-3f width 0.0 0.0)
          (RL:rl-tex-coord-2f tw th) (RL:rl-vertex-3f width 0.0 height)
          (RL:rl-tex-coord-2f tx th) (RL:rl-vertex-3f 0.0 0.0 height)))
      (RL:rl-end)
      (RL:rl-pop-matrix)
      (RL:rl-set-texture 0))))

;; DrawText3D — 在 3D 空间中绘制完整字符串
(define (draw-text-3d font text position font-size font-spacing line-spacing backface? tint)
  (let* ([len        (string-length text)]
         [base-size  (list-ref font 0)]
         [scale      (/ font-size (exact->inexact base-size))]
         [glyphs-ptr (list-ref font 9)]
         [recs-ptr   (list-ref font 8)])
    (let loop ([i 0] [off-x 0.0] [off-y 0.0])
      (when (< i len)
        (let*-values ([(cp cp-bytes) (get-codepoint (substring text i))])
          (let ([next-i (+ i cp-bytes)])
            (if (char=? (integer->char cp) #\newline)
                (loop next-i 0.0 (+ off-y font-size line-spacing))
                (begin
                  (when (and (not (= cp 32)) (not (= cp 9)))
                    (let ([pos (malloc T:_Vector3 'atomic)])
                      (ptr-set! pos _float 0 (+ (ptr-ref position _float 0) off-x))
                      (ptr-set! pos _float 1 (ptr-ref position _float 1))
                      (ptr-set! pos _float 2 (+ (ptr-ref position _float 2) off-y))
                      (draw-text-codepoint-3d font cp pos font-size backface? tint)))
                  (let* ([index     (get-glyph-index font cp)]
                         [glyph-ptr (ptr-add glyphs-ptr (* index _glyph-info-size))]
                         [adv-x     (ptr-ref glyph-ptr _int 3)]
                         [rec-w     (ptr-ref (ptr-add recs-ptr (* index _rect-size)) _float 2)]
                         [step      (if (zero? adv-x)
                                        (+ (* rec-w scale) font-spacing)
                                        (+ (* adv-x scale) font-spacing))])
                    (loop next-i (+ off-x step) off-y))))))))))

;; DrawTextWave3D — 3D 波浪文字
;; 检测 ~~...~~ 标记，标记之间的字符应用 sin 波浪动画
(define (draw-text-wave-3d font text position font-size font-spacing
                           line-spacing backface? wave-speed wave-offset
                           wave-range time tint)
  (let* ([len        (string-length text)]
         [base-size  (list-ref font 0)]
         [scale      (/ font-size (exact->inexact base-size))]
         [glyphs-ptr (list-ref font 9)]
         [recs-ptr   (list-ref font 8)])
    (let loop ([i 0] [k 0] [off-x 0.0] [off-y 0.0] [wave? #f])
      (when (< i len)
        (if (and (< (+ i 1) len)
                 (char=? (string-ref text i) #\~)
                 (char=? (string-ref text (+ i 1)) #\~))
            ;; 遇到 ~~ 标记，切换 wave 状态
            (loop (+ i 2) k off-x off-y (not wave?))
            (let*-values ([(cp cp-bytes) (get-codepoint (substring text i))])
              (let ([next-i (+ i cp-bytes)])
                (if (char=? (integer->char cp) #\newline)
                    (loop next-i 0 0.0 (+ off-y font-size line-spacing) wave?)
                    (begin
                      (when (and (not (= cp 32)) (not (= cp 9)))
                        (define pos (malloc T:_Vector3 'atomic))
                        (if wave?
                            (let ([wx (+ (ptr-ref position _float 0)
                                         (* (sin (- (* time (ptr-ref wave-speed _float 0))
                                                    (* k (ptr-ref wave-offset _float 0))))
                                            (ptr-ref wave-range _float 0)))]
                                  [wy (+ (ptr-ref position _float 1)
                                         (* (sin (- (* time (ptr-ref wave-speed _float 1))
                                                    (* k (ptr-ref wave-offset _float 1))))
                                            (ptr-ref wave-range _float 1)))]
                                  [wz (+ (ptr-ref position _float 2)
                                         (* (sin (- (* time (ptr-ref wave-speed _float 2))
                                                    (* k (ptr-ref wave-offset _float 2))))
                                            (ptr-ref wave-range _float 2)))])
                              (ptr-set! pos _float 0 (+ wx off-x))
                              (ptr-set! pos _float 1 wy)
                              (ptr-set! pos _float 2 (+ wz off-y)))
                            (begin
                              (ptr-set! pos _float 0 (+ (ptr-ref position _float 0) off-x))
                              (ptr-set! pos _float 1 (ptr-ref position _float 1))
                              (ptr-set! pos _float 2 (+ (ptr-ref position _float 2) off-y))))
                        (draw-text-codepoint-3d font cp pos font-size backface? tint))
                      (let* ([index     (get-glyph-index font cp)]
                             [glyph-ptr (ptr-add glyphs-ptr (* index _glyph-info-size))]
                             [adv-x     (ptr-ref glyph-ptr _int 3)]
                             [rec-w     (ptr-ref (ptr-add recs-ptr (* index _rect-size)) _float 2)]
                             [step      (if (zero? adv-x)
                                            (+ (* rec-w scale) font-spacing)
                                            (+ (* adv-x scale) font-spacing))])
                        (loop next-i (+ k 1) (+ off-x step) off-y wave?)))))))))))

;; ============================================================
;; UTF8 / Codepoints
;; ============================================================

(define load-utf8
  (let ([f (get-ffi-obj "LoadUTF8" lib (_fun _pointer _int -> _pointer))])
    (lambda (codepoints-ptr length) (f codepoints-ptr length))))

(define (unload-utf8 text-ptr)
  ((get-ffi-obj "UnloadUTF8" lib (_fun _pointer -> _void)) text-ptr))

(define load-codepoints
  (let ([f (get-ffi-obj "LoadCodepoints" lib (_fun _string _pointer -> _pointer))])
    (lambda (text)
      (let ([count-buf (malloc _int 1 'atomic)])
        (let ([result (f text count-buf)])
          (values result (ptr-ref count-buf _int 0)))))))

(define (unload-codepoints ptr)
  ((get-ffi-obj "UnloadCodepoints" lib (_fun _pointer -> _void)) ptr))

(define get-codepoint-count
  (let ([f (get-ffi-obj "GetCodepointCount" lib (_fun _string -> _int))])
    (lambda (text) (f text))))

(define get-codepoint
  (let ([f (get-ffi-obj "GetCodepoint" lib (_fun _string _pointer -> _int))])
    (lambda (text)
      (let ([bytes-processed (malloc _int 1 'atomic)])
        (let ([cp (f text bytes-processed)])
          (values cp (ptr-ref bytes-processed _int 0)))))))

(define get-codepoint-next
  (let ([f (get-ffi-obj "GetCodepointNext" lib (_fun _string _pointer -> _int))])
    (lambda (text)
      (let ([bytes-processed (malloc _int 1 'atomic)])
        (let ([cp (f text bytes-processed)])
          (values cp (ptr-ref bytes-processed _int 0)))))))

(define get-codepoint-previous
  (let ([f (get-ffi-obj "GetCodepointPrevious" lib (_fun _string _pointer -> _int))])
    (lambda (text)
      (let ([bytes-processed (malloc _int 1 'atomic)])
        (let ([cp (f text bytes-processed)])
          (values cp (ptr-ref bytes-processed _int 0)))))))

(define codepoint-to-utf8
  (let ([f (get-ffi-obj "CodepointToUTF8" lib (_fun _int _pointer -> _string))])
    (lambda (codepoint)
      (let ([byte-size (malloc _int 1 'atomic)])
        (let ([result (f codepoint byte-size)])
          (values result (ptr-ref byte-size _int 0)))))))

;; ============================================================
;; 字符串管理
;; ============================================================

(define load-text-lines
  (let ([f (get-ffi-obj "LoadTextLines" lib (_fun _string -> _pointer))])
    (lambda (text) (f text))))

(define (unload-text-lines lines-ptr)
  ((get-ffi-obj "UnloadTextLines" lib (_fun _pointer -> _void)) lines-ptr))

(define text-copy
  (let ([f (get-ffi-obj "TextCopy" lib (_fun _string _string -> _int))])
    (lambda (dst src) (f dst src))))

(define text-is-equal
  (let ([f (get-ffi-obj "TextIsEqual" lib (_fun _string _string -> _stdbool))])
    (lambda (text1 text2) (f text1 text2))))

(define text-length
  (let ([f (get-ffi-obj "TextLength" lib (_fun _string -> _uint))])
    (lambda (text) (f text))))

(define text-format
  (get-ffi-obj "TextFormat" lib (_fun _string -> _string)))

(define text-subtext
  (let ([f (get-ffi-obj "TextSubtext" lib (_fun _string _int _int -> _string))])
    (lambda (text position length) (f text position length))))

(define text-replace
  (let ([f (get-ffi-obj "TextReplace" lib (_fun _string _string _string -> _string))])
    (lambda (text replace by) (f text replace by))))

(define text-insert
  (let ([f (get-ffi-obj "TextInsert" lib (_fun _string _string _int -> _string))])
    (lambda (text insert-text position) (f text insert-text position))))

(define text-join
  (let ([f (get-ffi-obj "TextJoin" lib (_fun _pointer _int _string -> _string))])
    (lambda (text-list-ptr count delimiter) (f text-list-ptr count delimiter))))

(define text-split
  (let ([f (get-ffi-obj "TextSplit" lib (_fun _string _int _pointer -> _pointer))])
    (lambda (text delimiter)
      (let ([count-buf (malloc _int 1 'atomic)])
        (let ([result (f text delimiter count-buf)])
          (values result (ptr-ref count-buf _int 0)))))))

(define text-append
  (let ([f (get-ffi-obj "TextAppend" lib (_fun _string _string _pointer -> _void))])
    (lambda (text append-text)
      (f text append-text #f))))

(define text-find-index
  (let ([f (get-ffi-obj "TextFindIndex" lib (_fun _string _string -> _int))])
    (lambda (text find) (f text find))))

(define text-to-upper
  (let ([f (get-ffi-obj "TextToUpper" lib (_fun _string -> _string))])
    (lambda (text) (f text))))

(define text-to-lower
  (let ([f (get-ffi-obj "TextToLower" lib (_fun _string -> _string))])
    (lambda (text) (f text))))

(define text-to-pascal
  (let ([f (get-ffi-obj "TextToPascal" lib (_fun _string -> _string))])
    (lambda (text) (f text))))

(define text-to-snake
  (let ([f (get-ffi-obj "TextToSnake" lib (_fun _string -> _string))])
    (lambda (text) (f text))))

(define text-to-camel
  (let ([f (get-ffi-obj "TextToCamel" lib (_fun _string -> _string))])
    (lambda (text) (f text))))

(define text-to-integer
  (let ([f (get-ffi-obj "TextToInteger" lib (_fun _string -> _int))])
    (lambda (text) (f text))))

(define text-to-float
  (let ([f (get-ffi-obj "TextToFloat" lib (_fun _string -> _float))])
    (lambda (text) (f text))))

(define get-text-between
  (let ([f (get-ffi-obj "GetTextBetween" lib (_fun _string _string _string -> _string))])
    (lambda (text start end) (f text start end))))

;; ============================================================
;; 导出
;; ============================================================

(provide
 _font-bytes
 load-font load-font-ex load-font-from-image load-font-from-memory
 is-font-valid load-font-data gen-image-font-atlas
 unload-font-data unload-font export-font-as-code
 draw-text-ex draw-text-pro draw-text-codepoint draw-text-codepoints
 set-text-line-spacing measure-text-codepoints
 draw-text-codepoint-3d draw-text-3d draw-text-wave-3d
 get-glyph-index get-glyph-info get-glyph-atlas-rec
 load-utf8 unload-utf8 load-codepoints unload-codepoints
 get-codepoint-count get-codepoint get-codepoint-next get-codepoint-previous
 codepoint-to-utf8
 load-text-lines unload-text-lines
 text-copy text-is-equal text-length text-format text-subtext
 text-replace text-insert text-join text-split text-append
 text-find-index text-to-upper text-to-lower text-to-pascal
 text-to-snake text-to-camel text-to-integer text-to-float
 get-text-between)
