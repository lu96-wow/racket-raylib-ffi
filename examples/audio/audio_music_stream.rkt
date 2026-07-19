#lang racket/base

;; raylib [audio] example - music stream (Racket FFI 翻译)
;;
;; 对应 C: examples/audio/audio_music_stream.c
;; 复杂度: [★☆☆☆] 1/4

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         racket/format
         racket/math)

(define-runtime-path resource-dir "../../../examples/audio/resources/")
(define (resource f) (path->string (build-path resource-dir f)))

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height "raylib [audio] example - music stream")
(init-audio-device)

(define music (load-music-stream (resource "country.mp3")))
(play-music-stream music)
(define time-played 0.0)
(define pause #f)

(define pan 0.0)
(set-music-pan music pan)

(define volume 0.8)
(set-music-volume music volume)

(set-target-fps 30)

(define (main-loop)
  (when (not (window-should-close?))
    ;; Update
    (update-music-stream music)
    
    ;; Restart music playing (stop and play)
    (when (is-key-pressed KEY-SPACE)
      (stop-music-stream music)
      (play-music-stream music))
    
    ;; Pause/Resume
    (when (is-key-pressed KEY-P)
      (set! pause (not pause))
      (if pause
          (pause-music-stream music)
          (resume-music-stream music)))
    
    ;; Pan control
    (when (is-key-down KEY-LEFT)
      (set! pan (- pan 0.05))
      (when (< pan -1.0) (set! pan -1.0))
      (set-music-pan music pan))
    (when (is-key-down KEY-RIGHT)
      (set! pan (+ pan 0.05))
      (when (> pan 1.0) (set! pan 1.0))
      (set-music-pan music pan))
    
    ;; Volume control
    (when (is-key-down KEY-DOWN)
      (set! volume (- volume 0.05))
      (when (< volume 0.0) (set! volume 0.0))
      (set-music-volume music volume))
    (when (is-key-down KEY-UP)
      (set! volume (+ volume 0.05))
      (when (> volume 1.0) (set! volume 1.0))
      (set-music-volume music volume))
    
    ;; Get normalized time played
    (set! time-played (/ (get-music-time-played music) (get-music-time-length music)))
    (when (> time-played 1.0) (set! time-played 1.0))
    
    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)
    
    (draw-text "MUSIC SHOULD BE PLAYING!" 255 150 20 LIGHTGRAY)
    
    (draw-text "LEFT-RIGHT for PAN CONTROL" 320 74 10 DARKBLUE)
    (draw-rectangle 300 100 200 12 LIGHTGRAY)
    (draw-rectangle-lines 300 100 200 12 GRAY)
    (let ([pan-x (+ 300 (exact-round (* (/ (+ pan 1.0) 2.0) 200)) -5)])
      (draw-rectangle pan-x 92 10 28 DARKGRAY))
    
    (draw-rectangle 200 200 400 12 LIGHTGRAY)
    (draw-rectangle 200 200 (exact-round (* time-played 400.0)) 12 MAROON)
    (draw-rectangle-lines 200 200 400 12 GRAY)
    
    (draw-text "PRESS SPACE TO RESTART MUSIC" 215 250 20 LIGHTGRAY)
    (draw-text "PRESS P TO PAUSE/RESUME MUSIC" 208 280 20 LIGHTGRAY)
    
    (draw-text "UP-DOWN for VOLUME CONTROL" 320 334 10 DARKGREEN)
    (draw-rectangle 300 360 200 12 LIGHTGRAY)
    (draw-rectangle-lines 300 360 200 12 GRAY)
    (let ([vol-x (+ 300 (exact-round (* volume 200)) -5)])
      (draw-rectangle vol-x 352 10 28 DARKGRAY))
    
    (end-drawing)
    (main-loop)))

(main-loop)

(unload-music-stream music)
(close-audio-device)
(close-window)
