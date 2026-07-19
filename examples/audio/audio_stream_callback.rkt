#lang racket/base

;; raylib [audio] example - stream callback (Racket FFI 翻译)
;;
;; 对应 C: examples/audio/audio_stream_callback.c
;; 复杂度: [★★★☆] 3/4

(require "../../raylib/raylib.rkt"
         racket/math
         racket/format
         ffi/unsafe)

(define BUFFER-SIZE 4096)
(define SAMPLE-RATE 44100)

;; Mutable state shared with callbacks
(define wave-frequency 440)
(define new-wave-frequency 440)
(define wave-index 0)

;; Buffer to keep the last second of uploaded audio for drawing
(define draw-buffer (malloc (* SAMPLE-RATE (ctype-sizeof _float)) 'atomic))

;; Wave type indices
(define SINE     #t)   ; placeholder
(define SQUARE   #t)
(define TRIANGLE #t)
(define SAWTOOTH #t)

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height "raylib [audio] example - stream callback")
(init-audio-device)

(set-audio-stream-buffer-size-default BUFFER-SIZE)

;; Init raw audio stream
(define stream (load-audio-stream SAMPLE-RATE 32 1))
(play-audio-stream stream)

;; Save samples to draw buffer and shift
(define (save-to-draw-buffer frames-out frame-count)
  (for ([i (in-range (- SAMPLE-RATE frame-count))])
    (ptr-set! draw-buffer _float i (ptr-ref draw-buffer _float (+ i frame-count))))
  (for ([i (in-range frame-count)])
    (ptr-set! draw-buffer _float (+ (- SAMPLE-RATE frame-count) i)
              (ptr-ref frames-out _float i))))

;; Callback: sine wave
(define (sine-callback frames-out frame-count)
  (let ([wavelength (/ SAMPLE-RATE wave-frequency)])
    (for ([i (in-range frame-count)])
      (ptr-set! frames-out _float i (exact->inexact (sin (* 2 pi (/ wave-index wavelength)))))
      (set! wave-index (add1 wave-index))
      (when (>= wave-index wavelength)
        (set! wave-frequency new-wave-frequency)
        (set! wave-index 0))))
  (save-to-draw-buffer frames-out frame-count))

;; Callback: square wave
(define (square-callback frames-out frame-count)
  (let ([wavelength (/ SAMPLE-RATE wave-frequency)])
    (for ([i (in-range frame-count)])
      (ptr-set! frames-out _float i (if (< wave-index (/ wavelength 2)) 1.0 -1.0))
      (set! wave-index (add1 wave-index))
      (when (>= wave-index wavelength)
        (set! wave-frequency new-wave-frequency)
        (set! wave-index 0))))
  (save-to-draw-buffer frames-out frame-count))

;; Callback: triangle wave
(define (triangle-callback frames-out frame-count)
  (let* ([wavelength (/ SAMPLE-RATE wave-frequency)]
         [half-w (/ wavelength 2)])
    (for ([i (in-range frame-count)])
      (ptr-set! frames-out _float i
                (if (< wave-index half-w)
                    (+ -1.0 (* 2.0 (/ wave-index half-w)))
                    (- 1.0 (* 2.0 (/ (- wave-index half-w) half-w)))))
      (set! wave-index (add1 wave-index))
      (when (>= wave-index wavelength)
        (set! wave-frequency new-wave-frequency)
        (set! wave-index 0))))
  (save-to-draw-buffer frames-out frame-count))

;; Callback: sawtooth wave
(define (sawtooth-callback frames-out frame-count)
  (let ([wavelength (/ SAMPLE-RATE wave-frequency)])
    (for ([i (in-range frame-count)])
      (ptr-set! frames-out _float i (+ -1.0 (* 2.0 (/ wave-index wavelength))))
      (set! wave-index (add1 wave-index))
      (when (>= wave-index wavelength)
        (set! wave-frequency new-wave-frequency)
        (set! wave-index 0))))
  (save-to-draw-buffer frames-out frame-count))

(define wave-callbacks (vector sine-callback square-callback triangle-callback sawtooth-callback))
(define wave-type-names (vector "sine" "square" "triangle" "sawtooth"))

(define wave-type 0)  ; start at SINE
(set-audio-stream-callback stream (vector-ref wave-callbacks wave-type))

(set-target-fps 30)

(define (main-loop)
  (when (not (window-should-close?))
    ;; Update
    (when (is-key-down KEY-UP)
      (set! new-wave-frequency (+ new-wave-frequency 10))
      (when (> new-wave-frequency 12500) (set! new-wave-frequency 12500)))
    
    (when (is-key-down KEY-DOWN)
      (set! new-wave-frequency (- new-wave-frequency 10))
      (when (< new-wave-frequency 20) (set! new-wave-frequency 20)))
    
    (when (is-key-pressed KEY-LEFT)
      (set! wave-type (if (= wave-type 0) 3 (- wave-type 1)))
      (set-audio-stream-callback stream (vector-ref wave-callbacks wave-type)))
    
    (when (is-key-pressed KEY-RIGHT)
      (set! wave-type (modulo (+ wave-type 1) 4))
      (set-audio-stream-callback stream (vector-ref wave-callbacks wave-type)))
    
    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)
    
    (draw-text (~a "frequency: " new-wave-frequency) (- screen-width 220) 10 20 RED)
    (draw-text (~a "wave type: " (vector-ref wave-type-names wave-type)) (- screen-width 220) 30 20 RED)
    (draw-text "Up/down to change frequency" 10 10 20 DARKGRAY)
    (draw-text "Left/right to change wave type" 10 30 20 DARKGRAY)
    
    ;; Draw the last 10ms of uploaded audio
    (for ([i (in-range screen-width)])
      (let* ([base (- SAMPLE-RATE (quotient SAMPLE-RATE 100))]
             [idx0 (+ base (quotient (* i (quotient SAMPLE-RATE 100)) screen-width))]
             [idx1 (+ base (quotient (* (add1 i) (quotient SAMPLE-RATE 100)) screen-width))]
             [start-pos (vector2 (exact->inexact i) (- 250 (* 50 (ptr-ref draw-buffer _float idx0))))]
             [end-pos (vector2 (exact->inexact (add1 i)) (- 250 (* 50 (ptr-ref draw-buffer _float idx1))))])
        (draw-line-v start-pos end-pos RED)))
    
    (end-drawing)
    (main-loop)))

(main-loop)

(unload-audio-stream stream)
(close-audio-device)
(close-window)
