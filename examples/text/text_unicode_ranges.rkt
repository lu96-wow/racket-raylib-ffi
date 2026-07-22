#lang racket/base

;; raylib [text] example - unicode ranges (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_unicode_ranges.c
;; 按键 0-4 切换 Unicode 区块，右侧显示字体图集纹理

(require ffi/unsafe
         "../../raylib/raylib.rkt"
         racket/runtime-path)

;; ============================================================
;; 资源路径 — 使用 define-runtime-path 确保路径相对于本文件
;; ============================================================

(define-runtime-path resource-dir
  "../../../examples/text/resources")
(define font-path (path->string (build-path resource-dir "NotoSansTC-Regular.ttf")))

;; ============================================================
;; build-codepoints — 构建码点数组（malloc _int 缓冲区）
;; ranges: list of (start . stop) 对
;; ============================================================

(define (build-codepoints ranges)
  (define total 0)
  (for ([(cons s e) (in-list ranges)])
    (set! total (+ total (- e s -1))))
  (define codepoints (malloc _int total 'atomic))
  (define idx 0)
  (for ([(cons s e) (in-list ranges)])
    (for ([cp (in-range s (+ e 1))])
      (ptr-set! codepoints _int idx cp)
      (set! idx (+ idx 1))))
  (values codepoints total))

;; Unicode 范围定义
(define basic-range  (list (cons 32 127)))
(define european     (append basic-range (list (cons #xc0 #x24f))))
(define greek        (append european  (list (cons #x370 #x3ff) (cons #x1f00 #x1fff))))
(define cyrillic     (append greek     (list (cons #x400 #x4ff) (cons #x500 #x52f))))
(define cjk          (append cyrillic  (list (cons #x4e00 #x9fff) (cons #x3400 #x4dbf)
                                             (cons #x3000 #x303f) (cons #x3040 #x309f)
                                             (cons #x30A0 #x30ff) (cons #x31f0 #x31ff)
                                             (cons #xff00 #xffef))))
(define all-ranges   (vector basic-range european greek cyrillic cjk))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [text] example - unicode ranges")

(define-var font-box (load-font font-path))
;; set-texture-filter 需要 Texture2D (5 元素)，Font 是 10 元素
(define (font-texture font)
  (list (list-ref font 3) (list-ref font 4) (list-ref font 5)
        (list-ref font 6) (list-ref font 7)))
(set-texture-filter (font-texture (unbox font-box)) TEXTURE-FILTER-BILINEAR)
(define-var unicode-range 0)
(define-var prev-unicode-range 0)
(define-var generating? #f)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- 更新: 切换 Unicode 范围 ----
    (when (is-key-pressed KEY-ZERO) (set-box! unicode-range 0))
    (when (is-key-pressed KEY-ONE)  (set-box! unicode-range 1))
    (when (is-key-pressed KEY-TWO)  (set-box! unicode-range 2))
    (when (is-key-pressed KEY-THREE) (set-box! unicode-range 3))
    (when (is-key-pressed KEY-FOUR) (set-box! unicode-range 4))

    (when (not (= (unbox unicode-range) (unbox prev-unicode-range)))
      (set-box! generating? #t)
      (set-box! prev-unicode-range (unbox unicode-range))
      (define ranges (vector-ref all-ranges (unbox unicode-range)))
      (define-values (codepoints count) (build-codepoints ranges))
      (unload-font (unbox font-box))
      (define new-font (load-font-ex font-path 32 codepoints count))
      (set-box! font-box new-font)
      (set-texture-filter (font-texture new-font) TEXTURE-FILTER-BILINEAR))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (define font (unbox font-box))

    (draw-text "ADD CODEPOINTS: [1][2][3][4]" 20 20 20 MAROON)

    ;; 多语言文本
    (draw-text-ex font "> English: Hello World!" (vector2 50.0 70.0) 32.0 1.0 DARKGRAY)
    (draw-text-ex font "> Español: Hola mundo!" (vector2 50.0 120.0) 32.0 1.0 DARKGRAY)
    (draw-text-ex font "> Ελληνικά: Γειά σου κόσμε!" (vector2 50.0 170.0) 32.0 1.0 DARKGRAY)
    (draw-text-ex font "> Русский: Привет мир!" (vector2 50.0 220.0) 32.0 0.0 DARKGRAY)
    (draw-text-ex font "> 中文: 你好世界!" (vector2 50.0 270.0) 32.0 1.0 DARKGRAY)
    (draw-text-ex font "> 日本語: こんにちは世界!" (vector2 50.0 320.0) 32.0 1.0 DARKGRAY)

    ;; 右侧: 字体图集纹理（缩放显示）
    (let* ([tex-w (exact->inexact (list-ref font 4))]
           [tex-h (exact->inexact (list-ref font 5))]
           [atlas-scale (/ 380.0 tex-w)]
           [tex-id (list-ref font 3)]
           [font-tex (list (list-ref font 3) (list-ref font 4) (list-ref font 5)
                           (list-ref font 6) (list-ref font 7))])
      (draw-rectangle-rec (rectangle 400.0 16.0 (* tex-w atlas-scale) (* tex-h atlas-scale)) BLACK)
      (draw-texture-pro font-tex
                        (rectangle 0.0 0.0 tex-w tex-h)
                        (rectangle 400.0 16.0 (* tex-w atlas-scale) (* tex-h atlas-scale))
                        (vector2 0.0 0.0) 0.0 WHITE)
      (draw-rectangle-lines 400 16 380 380 RED)

      (draw-text (format "ATLAS SIZE: ~ax~a px (x~a)"
                         (inexact->exact tex-w) (inexact->exact tex-h)
                         (real->decimal-string atlas-scale 2))
                 20 380 20 BLUE)
      (draw-text (format "CODEPOINTS GLYPHS LOADED: ~a" (list-ref font 1))
                 20 410 20 LIME))

    (draw-text "Font: Noto Sans TC. License: SIL Open Font License 1.1"
               (- screen-width 300) (- screen-height 20) 10 GRAY)

    ;; "GENERATING..." 覆盖层
    (when (unbox generating?)
      (draw-rectangle 0 0 screen-width screen-height (fade WHITE 0.8))
      (draw-rectangle 0 125 screen-width 200 GRAY)
      (draw-text "GENERATING FONT ATLAS..." 120 210 40 BLACK)
      (set-box! generating? #f))

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-font (unbox font-box))
(close-window)
