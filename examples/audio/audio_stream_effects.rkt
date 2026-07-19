#lang racket/base

;; raylib [audio] example - stream effects (Racket FFI 翻译)
;;
;; 对应 C: examples/audio/audio_stream_effects.c
;; 复杂度: [★★★★] 4/4

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         racket/format
         racket/list
         racket/math
         ffi/unsafe)

(define-runtime-path resource-dir "../../../examples/audio/resources/")
(define (resource f) (path->string (build-path resource-dir f)))

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height "raylib [audio] example - stream effects")
(init-audio-device)

(define music (load-music-stream (resource "country.mp3")))

;; Extract AudioStream from Music (first 6 fields)
(define (music-stream m) (take m 6))

;; Allocate buffer for delay effect (~1 second)
(define delay-buffer-size (* 48000 2))
(define delay-buffer ((get-ffi-obj "calloc" #f (_fun _uint _uint -> _pointer)) delay-buffer-size (ctype-sizeof _float)))
(define delay-read-index 2)
(define delay-write-index 0)

(define get-free (get-ffi-obj "free" #f (_fun _pointer -> _void)))

(play-music-stream music)

(define time-played 0.0)
(define pause #f)
(define enable-effect-lpf #f)
(define enable-effect-delay #f)

;; Audio effect: lowpass filter
(define (make-lpf)
  (let ([low (malloc (* 2 (ctype-sizeof _float)) 'atomic)])
    (ptr-set! low _float 0 0.0)
    (ptr-set! low _float 1 0.0)
    (lambda (buffer frames)
      (define cutoff (/ 70.0 44100.0))
      (define k (/ cutoff (+ cutoff 0.1591549431)))
      (for ([i (in-range 0 (* frames 2) 2)])
        (define l (ptr-ref buffer _float i))
        (define r (ptr-ref buffer _float (+ i 1)))
        (define low0 (+ (ptr-ref low _float 0) (* k (- l (ptr-ref low _float 0)))))
        (define low1 (+ (ptr-ref low _float 1) (* k (- r (ptr-ref low _float 1)))))
        (ptr-set! low _float 0 low0)
        (ptr-set! low _float 1 low1)
        (ptr-set! buffer _float i low0)
        (ptr-set! buffer _float (+ i 1) low1)))))

(define lpf-func (make-lpf))

;; Audio effect: delay (1 second)
(define delay-func
  (lambda (buffer frames)
    (for ([i (in-range 0 (* frames 2) 2)])
      (define left-delay (ptr-ref delay-buffer _float delay-read-index))
      (set! delay-read-index (add1 delay-read-index))
      (define right-delay (ptr-ref delay-buffer _float delay-read-index))
      (set! delay-read-index (add1 delay-read-index))
      (when (= delay-read-index delay-buffer-size) (set! delay-read-index 0))
      
      (ptr-set! buffer _float i
                (+ (* 0.5 (ptr-ref buffer _float i)) (* 0.5 left-delay)))
      (ptr-set! buffer _float (+ i 1)
                (+ (* 0.5 (ptr-ref buffer _float (+ i 1))) (* 0.5 right-delay)))
      
      (ptr-set! delay-buffer _float delay-write-index (ptr-ref buffer _float i))
      (set! delay-write-index (add1 delay-write-index))
      (ptr-set! delay-buffer _float delay-write-index (ptr-ref buffer _float (+ i 1)))
      (set! delay-write-index (add1 delay-write-index))
      (when (= delay-write-index delay-buffer-size) (set! delay-write-index 0)))))

(define delay-cb (_cprocedure '(_fun _pointer _uint -> _void) delay-func))

(set-target-fps 60)

(define (main-loop)
  (when (not (window-should-close?))
    ;; Update
    (update-music-stream music)
    
    (when (is-key-pressed KEY-SPACE)
      (stop-music-stream music)
      (play-music-stream music))
    
    (when (is-key-pressed KEY-P)
      (set! pause (not pause))
      (if pause
          (pause-music-stream music)
          (resume-music-stream music)))
    
    ;; Toggle LPF effect
    (when (is-key-pressed KEY-F)
      (set! enable-effect-lpf (not enable-effect-lpf))
      (if enable-effect-lpf
          (attach-audio-stream-processor (music-stream music) lpf-func)
          (detach-audio-stream-processor (music-stream music) lpf-func)))
    
    ;; Toggle delay effect
    (when (is-key-pressed KEY-D)
      (set! enable-effect-delay (not enable-effect-delay))
      (if enable-effect-delay
          (attach-audio-stream-processor (music-stream music) delay-func)
          (detach-audio-stream-processor (music-stream music) delay-func)))
    
    (set! time-played (/ (get-music-time-played music) (get-music-time-length music)))
    (when (> time-played 1.0) (set! time-played 1.0))
    
    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)
    
    (draw-text "MUSIC SHOULD BE PLAYING!" 245 150 20 LIGHTGRAY)
    
    (draw-rectangle 200 180 400 12 LIGHTGRAY)
    (draw-rectangle 200 180 (exact-round (* time-played 400.0)) 12 MAROON)
    (draw-rectangle-lines 200 180 400 12 GRAY)
    
    (draw-text "PRESS SPACE TO RESTART MUSIC" 215 230 20 LIGHTGRAY)
    (draw-text "PRESS P TO PAUSE/RESUME MUSIC" 208 260 20 LIGHTGRAY)
    
    (draw-text (~a "PRESS F TO TOGGLE LPF EFFECT: " (if enable-effect-lpf "ON" "OFF")) 200 320 20 GRAY)
    (draw-text (~a "PRESS D TO TOGGLE DELAY EFFECT: " (if enable-effect-delay "ON" "OFF")) 180 350 20 GRAY)
    
    (end-drawing)
    (main-loop)))

(main-loop)

(unload-music-stream music)
(close-audio-device)
(get-free delay-buffer)
(close-window)
