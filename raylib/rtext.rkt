#lang racket/base

(require ffi/unsafe
         (prefix-in T: "types.rkt")
         (prefix-in C: "rcore.rkt"))

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

(define load-font-data
  (let ([f (get-ffi-obj "LoadFontData" lib
             (_fun _pointer _int _int _pointer _int _int -> _pointer))])
    (lambda (data-ptr data-size font-size codepoints-ptr codepoint-count type)
      (f data-ptr data-size font-size codepoints-ptr codepoint-count type))))

(define gen-image-font-atlas
  (let ([f (get-ffi-obj "GenImageFontAtlas" lib
             (_fun _pointer _pointer _int _int _int _int -> _pointer))])
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

(define get-glyph-info
  (let ([f (get-ffi-obj "GetGlyphInfo" lib
             (_fun (font : _font-bytes) _int -> _pointer))])
    (lambda (font codepoint) (f font codepoint))))

(define get-glyph-atlas-rec
  (let ([f (get-ffi-obj "GetGlyphAtlasRec" lib
             (_fun (font : _font-bytes) _int -> (r : C:_rect-bytes)))])
    (lambda (font codepoint)
      (C:rect-bytes->rect (f font codepoint)))))

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
