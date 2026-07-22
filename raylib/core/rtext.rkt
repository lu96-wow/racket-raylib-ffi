#lang racket/base

;; core/rtext.rkt — 文字/字体函数绑定 (rtext.h)

(require ffi/unsafe
         "ffi-helpers.rkt"
         "rlgl.rkt"
         "types/font.rkt"
         "types/glyph-info.rkt"
         "types/rectangle.rkt"
         "types/vector3.rkt")

(define load-font
  (let ([f (get-ffi-obj "LoadFont" lib (_fun _string -> (font : _font-bytes)))])
    (lambda (fn) (f fn))))
(define load-font-ex
  (let ([f (get-ffi-obj "LoadFontEx" lib
                        (_fun _string _int _pointer _int -> (font : _font-bytes)))])
    (lambda (fn fs cp cc) (f fn fs cp cc))))
(define load-font-from-image
  (let ([f (get-ffi-obj "LoadFontFromImage" lib
                        (_fun _pointer _uint _int -> (font : _font-bytes)))])
    (lambda (ip k fc) (f ip k fc))))
(define load-font-from-memory
  (let ([f (get-ffi-obj "LoadFontFromMemory" lib
                        (_fun _string _pointer _int _int _pointer _int -> (font : _font-bytes)))])
    (lambda (ft dp ds fs cp cc) (f ft dp ds fs cp cc))))
(define is-font-valid
  (let ([f (get-ffi-obj "IsFontValid" lib (_fun (font : _font-bytes) -> _stdbool))])
    (lambda (font) (f font))))
(define load-font-data
  (let ([f (get-ffi-obj "LoadFontData" lib
                        (_fun _pointer _int _int _pointer _int _int _pointer -> _pointer))])
    (lambda (dp ds fs cp cc t gcp) (f dp ds fs cp cc t gcp))))
(define gen-image-font-atlas
  (let ([f (get-ffi-obj "GenImageFontAtlas" lib
                        (_fun _pointer _pointer _int _int _int _int -> (img : _image-bytes)))])
    (lambda (gp rp gc fs p pm) (f gp rp gc fs p pm))))
(define (unload-font-data gp gc) ((get-ffi-obj "UnloadFontData" lib (_fun _pointer _int -> _void)) gp gc))
(define (unload-font font) ((get-ffi-obj "UnloadFont" lib (_fun (font : _font-bytes) -> _void)) font))
(define (export-font-as-code font fn)
  ((get-ffi-obj "ExportFontAsCode" lib (_fun (font : _font-bytes) _string -> _stdbool)) font fn))
(define draw-text-ex
  (let ([f (get-ffi-obj "DrawTextEx" lib
                        (_fun (font : _font-bytes) _string (pos : _vec2-bytes)
                              _float _float (c : _color-bytes) -> _void))])
    (lambda (font text p fs sp c) (f font text (vec2->bytes p) fs sp (color->bytes c)))))
(define draw-text-pro
  (let ([f (get-ffi-obj "DrawTextPro" lib
                        (_fun (font : _font-bytes) _string (pos : _vec2-bytes) (orig : _vec2-bytes)
                              _float _float _float (c : _color-bytes) -> _void))])
    (lambda (font text p o rot fs sp c)
      (f font text (vec2->bytes p) (vec2->bytes o) rot fs sp (color->bytes c)))))
(define draw-text-codepoint
  (let ([f (get-ffi-obj "DrawTextCodepoint" lib
                        (_fun (font : _font-bytes) _int (pos : _vec2-bytes)
                              _float (c : _color-bytes) -> _void))])
    (lambda (font cp p fs c) (f font cp (vec2->bytes p) fs (color->bytes c)))))
(define draw-text-codepoints
  (let ([f (get-ffi-obj "DrawTextCodepoints" lib
                        (_fun (font : _font-bytes) _pointer _int (pos : _vec2-bytes)
                              _float _float (c : _color-bytes) -> _void))])
    (lambda (font cpp cnt p fs sp c)
      (f font cpp cnt (vec2->bytes p) fs sp (color->bytes c)))))
(define (set-text-line-spacing s) ((get-ffi-obj "SetTextLineSpacing" lib (_fun _int -> _void)) s))
(define measure-text-codepoints
  (let ([f (get-ffi-obj "MeasureTextCodepoints" lib
                        (_fun (font : _font-bytes) _pointer _int _float _float -> (v : _vec2-bytes)))])
    (lambda (font cpp cnt fs sp) (bytes->vec2 (f font cpp cnt fs sp)))))
(define get-glyph-index
  (let ([f (get-ffi-obj "GetGlyphIndex" lib (_fun (font : _font-bytes) _int -> _int))])
    (lambda (font cp) (f font cp))))
(define get-glyph-info
  (let ([f (get-ffi-obj "GetGlyphInfo" lib
                        (_fun (font : _font-bytes) _int -> (g : _glyph-info-bytes)))])
    (lambda (font cp) (f font cp))))
(define get-glyph-atlas-rec
  (let ([f (get-ffi-obj "GetGlyphAtlasRec" lib
                        (_fun (font : _font-bytes) _int -> (r : _rectangle-bytes)))])
    (lambda (font cp) (bytes->rectangle (f font cp)))))
(define load-utf8
  (let ([f (get-ffi-obj "LoadUTF8" lib (_fun _pointer _int -> _pointer))])
    (lambda (cp l) (f cp l))))
(define (unload-utf8 tp) ((get-ffi-obj "UnloadUTF8" lib (_fun _pointer -> _void)) tp))
(define load-codepoints
  (let ([f (get-ffi-obj "LoadCodepoints" lib (_fun _string _pointer -> _pointer))])
    (lambda (text) (let ([cb (malloc _int 1 'atomic)])
                     (let ([r (f text cb)]) (values r (ptr-ref cb _int 0)))))))
(define (unload-codepoints p) ((get-ffi-obj "UnloadCodepoints" lib (_fun _pointer -> _void)) p))
(define get-codepoint-count
  (let ([f (get-ffi-obj "GetCodepointCount" lib (_fun _string -> _int))])
    (lambda (t) (f t))))
(define get-codepoint
  (let ([f (get-ffi-obj "GetCodepoint" lib (_fun _string _pointer -> _int))])
    (lambda (text) (let ([bp (malloc _int 1 'atomic)])
                     (let ([cp (f text bp)]) (values cp (ptr-ref bp _int 0)))))))
(define get-codepoint-next
  (let ([f (get-ffi-obj "GetCodepointNext" lib (_fun _string _pointer -> _int))])
    (lambda (text) (let ([bp (malloc _int 1 'atomic)])
                     (let ([cp (f text bp)]) (values cp (ptr-ref bp _int 0)))))))
(define get-codepoint-previous
  (let ([f (get-ffi-obj "GetCodepointPrevious" lib (_fun _string _pointer -> _int))])
    (lambda (text) (let ([bp (malloc _int 1 'atomic)])
                     (let ([cp (f text bp)]) (values cp (ptr-ref bp _int 0)))))))
(define codepoint-to-utf8
  (let ([f (get-ffi-obj "CodepointToUTF8" lib (_fun _int _pointer -> _string))])
    (lambda (cp) (let ([bs (malloc _int 1 'atomic)])
                   (let ([r (f cp bs)]) (values r (ptr-ref bs _int 0)))))))
(define load-text-lines
  (let ([f (get-ffi-obj "LoadTextLines" lib (_fun _string -> _pointer))])
    (lambda (t) (f t))))
(define (unload-text-lines lp) ((get-ffi-obj "UnloadTextLines" lib (_fun _pointer -> _void)) lp))
(define text-copy (let ([f (get-ffi-obj "TextCopy" lib (_fun _string _string -> _int))]) (lambda (d s) (f d s))))
(define text-is-equal (let ([f (get-ffi-obj "TextIsEqual" lib (_fun _string _string -> _stdbool))]) (lambda (a b) (f a b))))
(define text-length (let ([f (get-ffi-obj "TextLength" lib (_fun _string -> _uint))]) (lambda (t) (f t))))
(define text-format (get-ffi-obj "TextFormat" lib (_fun _string -> _string)))
(define text-subtext (let ([f (get-ffi-obj "TextSubtext" lib (_fun _string _int _int -> _string))]) (lambda (t p l) (f t p l))))
(define text-replace (let ([f (get-ffi-obj "TextReplace" lib (_fun _string _string _string -> _string))]) (lambda (t r b) (f t r b))))
(define text-insert (let ([f (get-ffi-obj "TextInsert" lib (_fun _string _string _int -> _string))]) (lambda (t it p) (f t it p))))
(define text-join (let ([f (get-ffi-obj "TextJoin" lib (_fun _pointer _int _string -> _string))]) (lambda (tlp c d) (f tlp c d))))
(define text-split (let ([f (get-ffi-obj "TextSplit" lib (_fun _string _int _pointer -> _pointer))]) (lambda (t d) (let ([cb (malloc _int 1 'atomic)]) (let ([r (f t d cb)]) (values r (ptr-ref cb _int 0)))))))
(define text-append (let ([f (get-ffi-obj "TextAppend" lib (_fun _string _string _pointer -> _void))]) (lambda (t a) (f t a #f))))
(define text-find-index (let ([f (get-ffi-obj "TextFindIndex" lib (_fun _string _string -> _int))]) (lambda (t fnd) (f t fnd))))
(define text-to-upper (let ([f (get-ffi-obj "TextToUpper" lib (_fun _string -> _string))]) (lambda (t) (f t))))
(define text-to-lower (let ([f (get-ffi-obj "TextToLower" lib (_fun _string -> _string))]) (lambda (t) (f t))))
(define text-to-pascal (let ([f (get-ffi-obj "TextToPascal" lib (_fun _string -> _string))]) (lambda (t) (f t))))
(define text-to-snake (let ([f (get-ffi-obj "TextToSnake" lib (_fun _string -> _string))]) (lambda (t) (f t))))
(define text-to-camel (let ([f (get-ffi-obj "TextToCamel" lib (_fun _string -> _string))]) (lambda (t) (f t))))
(define text-to-integer (let ([f (get-ffi-obj "TextToInteger" lib (_fun _string -> _int))]) (lambda (t) (f t))))
(define text-to-float (let ([f (get-ffi-obj "TextToFloat" lib (_fun _string -> _float))]) (lambda (t) (f t))))
(define get-text-between (let ([f (get-ffi-obj "GetTextBetween" lib (_fun _string _string _string -> _string))]) (lambda (t s e) (f t s e))))

;; ═══════════════════════════════════════════════════════════
;; 3D 文字绘制
;; ═══════════════════════════════════════════════════════════

(define glyph-info-size (ctype-sizeof _GlyphInfo))
(define rect-size (ctype-sizeof _Rectangle))

(define (draw-text-codepoint-3d font codepoint position font-size backface? tint)
  (let* ([base-size (list-ref font 0)] [glyph-pad (list-ref font 2)]
         [tex-id (list-ref font 3)] [tex-width (list-ref font 4)] [tex-height (list-ref font 5)]
         [recs-ptr (list-ref font 8)] [glyphs-ptr (list-ref font 9)]
         [index (get-glyph-index font codepoint)]
         [scale (/ font-size (exact->inexact base-size))]
         [glyph-ptr (ptr-add glyphs-ptr (* index glyph-info-size))]
         [offset-x (ptr-ref glyph-ptr _int 1)] [offset-y (ptr-ref glyph-ptr _int 2)]
         [rec-ptr (ptr-add recs-ptr (* index rect-size))]
         [rec-x (ptr-ref rec-ptr _float 0)] [rec-y (ptr-ref rec-ptr _float 1)]
         [rec-w (ptr-ref rec-ptr _float 2)] [rec-h (ptr-ref rec-ptr _float 3)]
         [px (+ (ptr-ref position _float 0) (* (- offset-x glyph-pad) scale))]
         [py (ptr-ref position _float 1)]
         [pz (+ (ptr-ref position _float 2) (* (- offset-y glyph-pad) scale))]
         [src-x (- rec-x glyph-pad)] [src-y (- rec-y glyph-pad)]
         [src-w (+ rec-w (* 2.0 glyph-pad))] [src-h (+ rec-h (* 2.0 glyph-pad))]
         [width (* src-w scale)] [height (* src-h scale)]
         [tx (/ src-x tex-width)] [ty (/ src-y tex-height)]
         [tw (/ (+ src-x src-w) tex-width)] [th (/ (+ src-y src-h) tex-height)])
    (when (> tex-id 0)
      (rl-check-render-batch-limit (+ 4 (if backface? 4 0)))
      (rl-set-texture tex-id)
      (rl-push-matrix) (rl-translate-f px py pz) (rl-begin RL-QUADS)
      (let ([r (ptr-ref tint _ubyte 0)] [g (ptr-ref tint _ubyte 1)]
            [b (ptr-ref tint _ubyte 2)] [a (ptr-ref tint _ubyte 3)])
        (rl-color-4ub r g b a) (rl-normal-3f 0.0 1.0 0.0)
        (rl-tex-coord-2f tx ty) (rl-vertex-3f 0.0 0.0 0.0)
        (rl-tex-coord-2f tx th) (rl-vertex-3f 0.0 0.0 height)
        (rl-tex-coord-2f tw th) (rl-vertex-3f width 0.0 height)
        (rl-tex-coord-2f tw ty) (rl-vertex-3f width 0.0 0.0)
        (when backface?
          (rl-normal-3f 0.0 -1.0 0.0)
          (rl-tex-coord-2f tx ty) (rl-vertex-3f 0.0 0.0 0.0)
          (rl-tex-coord-2f tw ty) (rl-vertex-3f width 0.0 0.0)
          (rl-tex-coord-2f tw th) (rl-vertex-3f width 0.0 height)
          (rl-tex-coord-2f tx th) (rl-vertex-3f 0.0 0.0 height)))
      (rl-end) (rl-pop-matrix) (rl-set-texture 0))))

(define (draw-text-3d font text position font-size font-spacing line-spacing backface? tint)
  (let* ([len (string-length text)] [base-size (list-ref font 0)]
         [scale (/ font-size (exact->inexact base-size))]
         [glyphs-ptr (list-ref font 9)] [recs-ptr (list-ref font 8)])
    (let loop ([i 0] [off-x 0.0] [off-y 0.0])
      (when (< i len)
        (let*-values ([(cp cp-bytes) (get-codepoint (substring text i))])
          (let ([next-i (+ i cp-bytes)])
            (if (char=? (integer->char cp) #\newline)
                (loop next-i 0.0 (+ off-y font-size line-spacing))
                (begin
                  (when (and (not (= cp 32)) (not (= cp 9)))
                    (let ([pos (malloc _Vector3 'atomic)])
                      (ptr-set! pos _float 0 (+ (ptr-ref position _float 0) off-x))
                      (ptr-set! pos _float 1 (ptr-ref position _float 1))
                      (ptr-set! pos _float 2 (+ (ptr-ref position _float 2) off-y))
                      (draw-text-codepoint-3d font cp pos font-size backface? tint)))
                  (let* ([index (get-glyph-index font cp)]
                         [glyph-ptr (ptr-add glyphs-ptr (* index glyph-info-size))]
                         [adv-x (ptr-ref glyph-ptr _int 3)]
                         [rec-w (ptr-ref (ptr-add recs-ptr (* index rect-size)) _float 2)]
                         [step (if (zero? adv-x)
                                   (+ (* rec-w scale) font-spacing)
                                   (+ (* adv-x scale) font-spacing))])
                    (loop next-i (+ off-x step) off-y))))))))))

(define (draw-text-wave-3d font text position font-size font-spacing
                           line-spacing backface? wave-speed wave-offset
                           wave-range time tint)
  (let* ([len (string-length text)] [base-size (list-ref font 0)]
         [scale (/ font-size (exact->inexact base-size))]
         [glyphs-ptr (list-ref font 9)] [recs-ptr (list-ref font 8)])
    (let loop ([i 0] [k 0] [off-x 0.0] [off-y 0.0] [wave? #f])
      (when (< i len)
        (if (and (< (+ i 1) len)
                 (char=? (string-ref text i) #\~)
                 (char=? (string-ref text (+ i 1)) #\~))
            (loop (+ i 2) k off-x off-y (not wave?))
            (let*-values ([(cp cp-bytes) (get-codepoint (substring text i))])
              (let ([next-i (+ i cp-bytes)])
                (if (char=? (integer->char cp) #\newline)
                    (loop next-i 0 0.0 (+ off-y font-size line-spacing) wave?)
                    (begin
                      (when (and (not (= cp 32)) (not (= cp 9)))
                        (define pos (malloc _Vector3 'atomic))
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
                      (let* ([index (get-glyph-index font cp)]
                             [glyph-ptr (ptr-add glyphs-ptr (* index glyph-info-size))]
                             [adv-x (ptr-ref glyph-ptr _int 3)]
                             [rec-w (ptr-ref (ptr-add recs-ptr (* index rect-size)) _float 2)]
                             [step (if (zero? adv-x)
                                       (+ (* rec-w scale) font-spacing)
                                       (+ (* adv-x scale) font-spacing))])
                        (loop next-i (+ k 1) (+ off-x step) off-y wave?)))))))))))

(provide
 load-font load-font-ex load-font-from-image load-font-from-memory
 is-font-valid load-font-data gen-image-font-atlas
 unload-font-data unload-font export-font-as-code
 draw-text-ex draw-text-pro draw-text-codepoint draw-text-codepoints
 set-text-line-spacing measure-text-codepoints
 get-glyph-index get-glyph-info get-glyph-atlas-rec
 load-utf8 unload-utf8 load-codepoints unload-codepoints
 get-codepoint-count get-codepoint get-codepoint-next get-codepoint-previous
 codepoint-to-utf8 load-text-lines unload-text-lines
 text-copy text-is-equal text-length text-format text-subtext
 text-replace text-insert text-join text-split text-append
 text-find-index text-to-upper text-to-lower text-to-pascal
 text-to-snake text-to-camel text-to-integer text-to-float get-text-between
 draw-text-codepoint-3d draw-text-3d draw-text-wave-3d)
