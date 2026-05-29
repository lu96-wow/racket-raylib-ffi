#lang racket/base

;; raylib [core] example - window flags (Racket FFI 翻译)

(require "../../raylib/raylib.rkt")

(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 450)

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - window flags")

(define ball-pos-x (box (/ SCREEN-WIDTH 2.0)))
(define ball-pos-y (box (/ SCREEN-HEIGHT 2.0)))
(define ball-speed-x (box 5.0))
(define ball-speed-y (box 4.0))
(define ball-radius 20.0)
(define frames-counter (box 0))

(set-target-fps 60)

(define (toggle-flag flag)
  (if (is-window-state? flag)
    (clear-window-state flag)
    (set-window-state flag)))

(define (show-flag label key flag y)
  (draw-text (format "[~a] ~a: ~a" key label (if (is-window-state? flag) "on" "off"))
    10 y 10 (if (is-window-state? flag) LIME MAROON)))

(let loop ()
  (unless (window-should-close?)
    (when (is-key-pressed KEY-F) (toggle-fullscreen))
    (when (is-key-pressed KEY-R) (toggle-flag FLAG-WINDOW-RESIZABLE))
    (when (is-key-pressed KEY-D) (toggle-flag FLAG-WINDOW-UNDECORATED))

    (when (is-key-pressed KEY-H)
      (unless (is-window-state? FLAG-WINDOW-HIDDEN)
        (set-window-state FLAG-WINDOW-HIDDEN))
      (set-box! frames-counter 0))
    (when (is-window-state? FLAG-WINDOW-HIDDEN)
      (set-box! frames-counter (add1 (unbox frames-counter)))
      (when (>= (unbox frames-counter) 240)
        (clear-window-state FLAG-WINDOW-HIDDEN)))

    (when (is-key-pressed KEY-N)
      (unless (is-window-state? FLAG-WINDOW-MINIMIZED)
        (minimize-window))
      (set-box! frames-counter 0))
    (when (is-window-state? FLAG-WINDOW-MINIMIZED)
      (set-box! frames-counter (add1 (unbox frames-counter)))
      (when (>= (unbox frames-counter) 240)
        (restore-window) (set-box! frames-counter 0)))

    (when (is-key-pressed KEY-M)
      (if (is-window-state? FLAG-WINDOW-MAXIMIZED)
        (restore-window) (maximize-window)))

    (when (is-key-pressed KEY-U) (toggle-flag FLAG-WINDOW-UNFOCUSED))
    (when (is-key-pressed KEY-T) (toggle-flag FLAG-WINDOW-TOPMOST))
    (when (is-key-pressed KEY-A) (toggle-flag FLAG-WINDOW-ALWAYS-RUN))
    (when (is-key-pressed KEY-V) (toggle-flag FLAG-VSYNC-HINT))
    (when (is-key-pressed KEY-B) (toggle-borderless-windowed))

    (set-box! ball-pos-x (+ (unbox ball-pos-x) (unbox ball-speed-x)))
    (set-box! ball-pos-y (+ (unbox ball-pos-y) (unbox ball-speed-y)))
    (let ([sw (get-screen-width)] [sh (get-screen-height)])
      (when (or (>= (unbox ball-pos-x) (- sw ball-radius))
                (<= (unbox ball-pos-x) ball-radius))
        (set-box! ball-speed-x (* -1 (unbox ball-speed-x))))
      (when (or (>= (unbox ball-pos-y) (- sh ball-radius))
                (<= (unbox ball-pos-y) ball-radius))
        (set-box! ball-speed-y (* -1 (unbox ball-speed-y)))))

    (begin-drawing)

    (if (is-window-state? FLAG-WINDOW-TRANSPARENT)
      (clear-background BLANK)
      (clear-background RAYWHITE))

    (draw-circle-v (vector2 (unbox ball-pos-x) (unbox ball-pos-y))
                   ball-radius MAROON)

    (draw-rectangle-lines-ex
      (rectangle 0.0 0.0 (exact->inexact (get-screen-width))
                         (exact->inexact (get-screen-height)))
      4.0 RAYWHITE)

    (draw-circle-v (get-mouse-position) 10.0 DARKBLUE)
    (draw-fps 10 10)
    (draw-text (format "Screen Size: [~a, ~a]"
                (get-screen-width) (get-screen-height))
      10 40 10 GREEN)

    (draw-text "Following flags can be set after window creation:" 10 60 10 GRAY)
    (show-flag "FULLSCREEN_MODE"    "F" FLAG-FULLSCREEN-MODE   80)
    (show-flag "WINDOW_RESIZABLE"   "R" FLAG-WINDOW-RESIZABLE  100)
    (show-flag "WINDOW_UNDECORATED" "D" FLAG-WINDOW-UNDECORATED 120)
    (show-flag "WINDOW_HIDDEN"      "H" FLAG-WINDOW-HIDDEN     140)
    (show-flag "WINDOW_MINIMIZED"   "N" FLAG-WINDOW-MINIMIZED  160)
    (show-flag "WINDOW_MAXIMIZED"   "M" FLAG-WINDOW-MAXIMIZED  180)
    (show-flag "WINDOW_UNFOCUSED"   "U" FLAG-WINDOW-UNFOCUSED  200)
    (show-flag "WINDOW_TOPMOST"     "T" FLAG-WINDOW-TOPMOST    220)
    (show-flag "WINDOW_ALWAYS_RUN"  "A" FLAG-WINDOW-ALWAYS-RUN 240)
    (show-flag "VSYNC_HINT"         "V" FLAG-VSYNC-HINT        260)
    (show-flag "BORDERLESS_WINDOWED_MODE" "B" FLAG-BORDERLESS-WINDOWED-MODE 280)

    (draw-text "Flags only before window creation:" 10 320 10 GRAY)
    (show-flag "WINDOW_HIGHDPI"     "" FLAG-WINDOW-HIGHDPI     340)
    (show-flag "WINDOW_TRANSPARENT" "" FLAG-WINDOW-TRANSPARENT 360)
    (show-flag "MSAA_4X_HINT"       "" FLAG-MSAA-4X-HINT      380)

    (end-drawing)
    (loop)))

(close-window)
