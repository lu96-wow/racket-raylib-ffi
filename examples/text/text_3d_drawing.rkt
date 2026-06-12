#lang racket/base

;; raylib [text] example - 3d drawing (Racket FFI)
;; 对应 C: examples/text/text_3d_drawing.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         racket/format
         ffi/unsafe
         (prefix-in T: "../../raylib/types.rkt"))

(define-runtime-path shader-dir "../../../examples/text/resources/shaders/glsl330/")
(define alpha-discard-fs (string-append (path->string shader-dir) "alpha_discard.fs"))

(define screen-width 800)
(define screen-height 450)

(set-config-flags (bitwise-ior FLAG-MSAA-4X-HINT FLAG-VSYNC-HINT))
(init-window screen-width screen-height "raylib [text] example - 3d drawing")

(define camera
  (camera3d -10.0 15.0 -10.0  0.0 0.0 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))
(define camera-mode CAMERA-ORBITAL)
(define spin #t)

(define cube-position (vector3 0.0 1.0 0.0))
(define cube-size (vector3 2.0 2.0 2.0))

(define font (get-font-default))
(define font-size 0.8)
(define font-spacing 0.05)
(define line-spacing -0.1)
(define layer-distance 0.01)
(define layers 1)
(define show-letter-boundry #f)
(define show-text-boundry #f)
(define multicolor #f)

;; 波浪文字配置 (Vector3)
(define wave-speed   (vector3 3.0 3.0 0.5))
(define wave-offset  (vector3 0.35 0.35 0.35))
(define wave-range   (vector3 0.45 0.45 0.45))

(define text-str "Hello ~~World~~ in 3D!")
(define light MAROON)
(define dark RED)

(define alpha-discard-shader
  (if (file-exists? alpha-discard-fs)
      (load-shader #f alpha-discard-fs)
      #f))

(disable-cursor)
(set-target-fps 60)

(define time 0.0)

(let loop ()
  (unless (window-should-close?)
    (update-camera camera camera-mode)
    (set! time (+ time (get-frame-time)))

    (define text-measure (measure-text-ex font text-str font-size font-spacing))

    ;; 按键处理
    (when (is-key-pressed KEY-F1) (set! show-letter-boundry (not show-letter-boundry)))
    (when (is-key-pressed KEY-F2) (set! show-text-boundry (not show-text-boundry)))
    (when (is-key-pressed KEY-F3)
      (set! spin (not spin))
      (set! camera-mode (if spin CAMERA-ORBITAL CAMERA-FREE)))
    (when (is-key-pressed KEY-LEFT)   (set! font-size (- font-size 0.5)))
    (when (is-key-pressed KEY-RIGHT)  (set! font-size (+ font-size 0.5)))
    (when (is-key-pressed KEY-UP)     (set! font-spacing (- font-spacing 0.1)))
    (when (is-key-pressed KEY-DOWN)   (set! font-spacing (+ font-spacing 0.1)))
    (when (is-key-pressed KEY-PAGE-UP)   (set! line-spacing (- line-spacing 0.1)))
    (when (is-key-pressed KEY-PAGE-DOWN) (set! line-spacing (+ line-spacing 0.1)))
    (when (is-key-pressed KEY-HOME)  (when (> layers 1) (set! layers (- layers 1))))
    (when (is-key-pressed KEY-END)   (when (< layers 32) (set! layers (+ layers 1))))
    (when (is-key-down KEY-INSERT)   (set! layer-distance (- layer-distance 0.001)))
    (when (is-key-down KEY-DELETE)   (set! layer-distance (+ layer-distance 0.001)))
    (when (is-key-pressed KEY-TAB)   (set! multicolor (not multicolor)))

    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)
    (draw-cube-v cube-position cube-size dark)
    (draw-cube-wires cube-position 2.1 2.1 2.1 light)
    (draw-grid 10 2.0)

    (when alpha-discard-shader
      (begin-shader-mode alpha-discard-shader))

    ;; ==== 主 3D 波浪文字 ====
    (rl-push-matrix)
    (rl-rotate-f 90.0 1.0 0.0 0.0)
    (rl-rotate-f 90.0 0.0 0.0 -1.0)
    (for ([layer (in-range layers)])
      (define clr (if multicolor
                      (let ([c (malloc T:_Color 'atomic)])
                        (ptr-set! c _ubyte 0 (random 256))
                        (ptr-set! c _ubyte 1 (random 256))
                        (ptr-set! c _ubyte 2 (random 256))
                        (ptr-set! c _ubyte 3 (random 256)) c)
                      light))
      (define pos (malloc T:_Vector3 'atomic))
      (ptr-set! pos _float 0 (/ (- (ptr-ref text-measure _float 0)) 2.0))
      (ptr-set! pos _float 1 (exact->inexact (* layer layer-distance)))
      (ptr-set! pos _float 2 -4.5)
      (draw-text-wave-3d font text-str pos font-size font-spacing
                         line-spacing #t wave-speed wave-offset wave-range time clr))
    (rl-pop-matrix)

    ;; ==== 3D 选项文字 ====
    (let ([save-lb show-letter-boundry])
      (set! show-letter-boundry #f)
      (rl-push-matrix)
      (rl-rotate-f 180.0 0.0 1.0 0.0)

      (define opt-size 0.8)
      (define opt-spacing 0.1)
      (define opt-pos (malloc T:_Vector3 'atomic))
      (ptr-set! opt-pos _float 1 0.01)
      (ptr-set! opt-pos _float 2 2.0)

      (define (draw-opt label clr)
        (define m (measure-text-ex font label opt-size opt-spacing))
        (define my (ptr-ref m _float 1))
        (ptr-set! opt-pos _float 0 (/ (- (ptr-ref m _float 0)) 2.0))
        (draw-text-3d font label opt-pos opt-size opt-spacing 0.0 #f clr)
        (ptr-set! opt-pos _float 2 (+ (ptr-ref opt-pos _float 2) 0.5 my)))

      (draw-opt (~a "< SIZE: " (~r font-size #:precision 1) " >") BLUE)
      (draw-opt (~a "< SPACING: " (~r font-spacing #:precision 1) " >") BLUE)
      (draw-opt (~a "< LINE: " (~r line-spacing #:precision 1) " >") BLUE)
      (draw-opt (~a "< LBOX: " (if save-lb "ON" "OFF") " >") RED)
      (draw-opt (~a "< TBOX: " (if show-text-boundry "ON" "OFF") " >") RED)
      (draw-opt (~a "< LAYER DISTANCE: " (~r layer-distance #:precision 3) " >") DARKPURPLE)

      (rl-pop-matrix)
      (set! show-letter-boundry save-lb))

    ;; ==== 3D 操作说明 (默认相机方向，不旋转) ====
    (define info-pos (malloc T:_Vector3 'atomic))
    (ptr-set! info-pos _float 1 0.01)
    (ptr-set! info-pos _float 2 2.0)

    (define (draw-info label size spacing [extra-gap 0.5])
      (define m (measure-text-ex font label size spacing))
      (define my (ptr-ref m _float 1))
      (ptr-set! info-pos _float 0 (/ (- (ptr-ref m _float 0)) 2.0))
      (draw-text-3d font label info-pos size spacing 0.0 #f DARKBLUE)
      (ptr-set! info-pos _float 2 (+ (ptr-ref info-pos _float 2) extra-gap my)))

    (draw-info "All the text displayed here is in 3D" 1.0 0.05 1.5)
    (draw-info "press [Left]/[Right] to change the font size" 0.6 0.05)
    (draw-info "press [Up]/[Down] to change the font spacing" 0.6 0.05)
    (draw-info "press [PgUp]/[PgDown] to change the line spacing" 0.6 0.05)
    (draw-info "press [F1] to toggle the letter boundry" 0.6 0.05)
    (draw-info "press [F2] to toggle the text boundry" 0.6 0.05)

    (when alpha-discard-shader (end-shader-mode))
    (end-mode-3d)

    ;; ==== 2D 信息 ====
    (draw-text
     "Drag & drop a font file to change the font!\nType something, see what happens!\n\nPress [F3] to toggle the camera"
     10 35 10 BLACK)
    (define stats-text (~a layers " layer(s) | " (if spin "ORBITAL" "FREE") " camera"))
    (draw-text stats-text (- screen-width 20 (measure-text stats-text 10)) 10 10 DARKGREEN)
    (define hint1 "[Home]/[End] to add/remove 3D text layers")
    (draw-text hint1 (- screen-width 20 (measure-text hint1 10)) 25 10 DARKGRAY)
    (define hint2 "[Insert]/[Delete] to change distance between layers")
    (draw-text hint2 (- screen-width 20 (measure-text hint2 10)) 40 10 DARKGRAY)
    (define hint3 "click the [CUBE] for a random color")
    (draw-text hint3 (- screen-width 20 (measure-text hint3 10)) 55 10 DARKGRAY)
    (define hint4 "[Tab] to toggle multicolor mode")
    (draw-text hint4 (- screen-width 20 (measure-text hint4 10)) 70 10 DARKGRAY)
    (draw-fps 10 10)

    (end-drawing)
    (loop)))

(when alpha-discard-shader (unload-shader alpha-discard-shader))
(unload-font font)
(close-window)
