#lang racket/base

;; raylib [audio] example - sound multi (Racket FFI 翻译)
;;
;; 对应 C: examples/audio/audio_sound_multi.c
;; 复杂度: [★★☆☆] 2/4

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define-runtime-path resource-dir "../../../examples/audio/resources/")
(define (resource f) (path->string (build-path resource-dir f)))

(define MAX-SOUNDS 10)

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height "raylib [audio] example - sound multi")
(init-audio-device)

;; Load audio file into the first slot as the 'source' sound,
;; this sound owns the sample data
(define sound-array
  (let ([sounds (make-vector MAX-SOUNDS)])
    (vector-set! sounds 0 (load-sound (resource "sound.wav")))
    ;; Load an alias of the sound into slots 1-9
    (for ([i (in-range 1 MAX-SOUNDS)])
      (vector-set! sounds i (load-sound-alias (vector-ref sounds 0))))
    sounds))

(define current-sound 0)
(set-target-fps 60)

(define (main-loop)
  (when (not (window-should-close?))
    ;; Update
    (when (is-key-pressed KEY-SPACE)
      (play-sound (vector-ref sound-array current-sound))
      (set! current-sound (add1 current-sound))
      (when (>= current-sound MAX-SOUNDS)
        (set! current-sound 0)))
    
    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)
    (draw-text "Press SPACE to PLAY a WAV sound!" 200 180 20 LIGHTGRAY)
    (end-drawing)
    
    (main-loop)))

(main-loop)

;; Unload sound aliases first, then source sound
(for ([i (in-range 1 MAX-SOUNDS)])
  (unload-sound-alias (vector-ref sound-array i)))
(unload-sound (vector-ref sound-array 0))
(close-audio-device)
(close-window)
