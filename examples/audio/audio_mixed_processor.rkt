#lang racket/base

;; raylib [audio] example - mixed processor (Racket FFI 翻译)
;;
;; 对应 C: examples/audio/audio_mixed_processor.c
;; 复杂度: [★★★★] 4/4

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         racket/format
         racket/math
         ffi/unsafe)

(define-runtime-path resource-dir "../../../examples/audio/resources/")
(define (resource f) (path->string (build-path resource-dir f)))

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height "raylib [audio] example - mixed processor")
(init-audio-device)

;; Mutable exponent value
(define exponent 1.0)
;; Average volume history
(define average-volume (make-vector 400 0.0))

;; Audio processing function
(define (process-audio buffer frames)
  (define samples buffer)
  (define avg 0.0)
  (for ([frame (in-range frames)])
    (define left (ptr-ref samples _float (+ (* frame 2) 0)))
    (define right (ptr-ref samples _float (+ (* frame 2) 1)))
    (define abs-left (abs left))
    (define abs-right (abs right))
    (define sign-left (if (< left 0.0) -1.0 1.0))
    (define sign-right (if (< right 0.0) -1.0 1.0))
    
    (ptr-set! samples _float (+ (* frame 2) 0) (* (expt abs-left exponent) sign-left))
    (ptr-set! samples _float (+ (* frame 2) 1) (* (expt abs-right exponent) sign-right))
    
    (set! avg (+ avg (/ abs-left frames) (/ abs-right frames))))
  
  ;; Shift history left
  (for ([i (in-range 399)])
    (vector-set! average-volume i (vector-ref average-volume (+ i 1))))
  (vector-set! average-volume 399 avg))

(attach-audio-mixed-processor process-audio)

(define music (load-music-stream (resource "country.mp3")))
(define sound (load-sound (resource "coin.wav")))

(play-music-stream music)
(set-target-fps 60)

(define (main-loop)
  (when (not (window-should-close?))
    (update-music-stream music)
    
    (when (is-key-pressed KEY-LEFT)
      (set! exponent (- exponent 0.05)))
    (when (is-key-pressed KEY-RIGHT)
      (set! exponent (+ exponent 0.05)))
    
    (when (<= exponent 0.5) (set! exponent 0.5))
    (when (>= exponent 3.0) (set! exponent 3.0))
    
    (when (is-key-pressed KEY-SPACE) (play-sound sound))
    
    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)
    
    (draw-text "MUSIC SHOULD BE PLAYING!" 255 150 20 LIGHTGRAY)
    (draw-text (~a "EXPONENT = " (real->decimal-string exponent 2)) 215 180 20 LIGHTGRAY)
    
    ;; Volume history graph
    (draw-rectangle 199 199 402 34 LIGHTGRAY)
    (for ([i (in-range 400)])
      (draw-line (+ 201 i) (- 232 (exact-round (* (vector-ref average-volume i) 32)))
                 (+ 201 i) 232 MAROON))
    (draw-rectangle-lines 199 199 402 34 GRAY)
    
    (draw-text "PRESS SPACE TO PLAY OTHER SOUND" 200 250 20 LIGHTGRAY)
    (draw-text "USE LEFT AND RIGHT ARROWS TO ALTER DISTORTION" 140 280 20 LIGHTGRAY)
    
    (end-drawing)
    (main-loop)))

(main-loop)

(unload-music-stream music)
(detach-audio-mixed-processor process-audio)
(close-audio-device)
(close-window)
