#lang racket/base

;; raylib [audio] example - raw stream (Racket FFI 翻译)
;;
;; 对应 C: examples/audio/audio_raw_stream.c
;; 复杂度: [★★★☆] 3/4

(require "../../raylib/raylib.rkt"
         racket/math
         racket/format
         ffi/unsafe)

(define BUFFER-SIZE 4096)
(define SAMPLE-RATE 44100)

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height "raylib [audio] example - raw stream")
(init-audio-device)

(set-audio-stream-buffer-size-default BUFFER-SIZE)
(define buffer (malloc (* BUFFER-SIZE (ctype-sizeof _float)) 'atomic))

;; Init raw audio stream (sample rate: 44100, sample size: 32bit-float, channels: 1-mono)
(define stream (load-audio-stream SAMPLE-RATE 32 1))
(define pan 0.0)
(set-audio-stream-pan stream pan)
(play-audio-stream stream)

(define sine-frequency 440)
(define new-sine-frequency 440)
(define sine-index 0)
(define sine-start-time 0.0)

(set-target-fps 30)

(define (main-loop)
  (when (not (window-should-close?))
    ;; Update
    (when (is-key-down KEY-UP)
      (set! new-sine-frequency (+ new-sine-frequency 10))
      (when (> new-sine-frequency 12500) (set! new-sine-frequency 12500)))
    
    (when (is-key-down KEY-DOWN)
      (set! new-sine-frequency (- new-sine-frequency 10))
      (when (< new-sine-frequency 20) (set! new-sine-frequency 20)))
    
    (when (is-key-down KEY-LEFT)
      (set! pan (- pan 0.01))
      (when (< pan -1.0) (set! pan -1.0))
      (set-audio-stream-pan stream pan))
    
    (when (is-key-down KEY-RIGHT)
      (set! pan (+ pan 0.01))
      (when (> pan 1.0) (set! pan 1.0))
      (set-audio-stream-pan stream pan))
    
    (when (is-audio-stream-processed? stream)
      (let ([wavelength (/ SAMPLE-RATE sine-frequency)])
        (for ([i (in-range BUFFER-SIZE)])
          (ptr-set! buffer _float i
                    (exact->inexact (sin (* 2 pi (/ sine-index wavelength)))))
          (set! sine-index (add1 sine-index))
          (when (>= sine-index wavelength)
            (set! sine-frequency new-sine-frequency)
            (set! sine-index 0)
            (set! sine-start-time (get-time))))
        (update-audio-stream stream buffer BUFFER-SIZE)))
    
    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)
    
    (draw-text (~a "sine frequency: " sine-frequency) (- screen-width 220) 10 20 RED)
    (draw-text (~a "pan: " (real->decimal-string pan 2)) (- screen-width 220) 30 20 RED)
    (draw-text "Up/down to change frequency" 10 10 20 DARKGRAY)
    (draw-text "Left/right to pan" 10 30 20 DARKGRAY)
    
    (let* ([window-start (exact-round (* (- (get-time) sine-start-time) SAMPLE-RATE))]
           [window-size (exact-round (* 0.1 SAMPLE-RATE))]
           [wavelength (/ SAMPLE-RATE sine-frequency)])
      (for ([i (in-range screen-width)])
        (let* ([t0 (+ window-start (quotient (* i window-size) screen-width))]
               [t1 (+ window-start (quotient (* (add1 i) window-size) screen-width))]
               [start-pos (vector2 (exact->inexact i)
                                   (+ 250 (* 50 (sin (* 2 pi (/ t0 wavelength))))))]
               [end-pos (vector2 (exact->inexact (add1 i))
                                 (+ 250 (* 50 (sin (* 2 pi (/ t1 wavelength))))))])
          (draw-line-v start-pos end-pos RED))))
    
    (end-drawing)
    (main-loop)))

(main-loop)

(unload-audio-stream stream)
(close-audio-device)
(close-window)
