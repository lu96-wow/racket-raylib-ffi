#lang racket/base

;; raylib [audio] example - sound loading (Racket FFI 翻译)
;;
;; 对应 C: examples/audio/audio_sound_loading.c
;; 复杂度: [★☆☆☆] 1/4

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define-runtime-path resource-dir "../../../examples/audio/resources/")
(define (resource f) (path->string (build-path resource-dir f)))

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height "raylib [audio] example - sound loading")
(init-audio-device)

(define fx-wav (load-sound (resource "sound.wav")))
(define fx-ogg (load-sound (resource "target.ogg")))

(set-target-fps 60)

(define (main-loop)
  (when (not (window-should-close?))
    ;; Update
    (when (is-key-pressed KEY-SPACE) (play-sound fx-wav))
    (when (is-key-pressed KEY-ENTER) (play-sound fx-ogg))
    
    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)
    (draw-text "Press SPACE to PLAY the WAV sound!" 200 180 20 LIGHTGRAY)
    (draw-text "Press ENTER to PLAY the OGG sound!" 200 220 20 LIGHTGRAY)
    (end-drawing)
    
    (main-loop)))

(main-loop)

(unload-sound fx-wav)
(unload-sound fx-ogg)
(close-audio-device)
(close-window)
