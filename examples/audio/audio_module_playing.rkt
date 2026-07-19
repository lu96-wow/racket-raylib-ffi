#lang racket/base

;; raylib [audio] example - module playing (Racket FFI 翻译)
;;
;; 对应 C: examples/audio/audio_module_playing.c
;; 复杂度: [★☆☆☆] 1/4

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         racket/format
         racket/list
         racket/math)

(define-runtime-path resource-dir "../../../examples/audio/resources/")
(define (resource f) (path->string (build-path resource-dir f)))

(define MAX-CIRCLES 64)

(define screen-width 800)
(define screen-height 450)

;; MSAA not essential - skip set-config-flags

(init-window screen-width screen-height "raylib [audio] example - module playing")
(init-audio-device)

(define colors
  (vector ORANGE RED GOLD LIME BLUE VIOLET BROWN LIGHTGRAY PINK
          YELLOW GREEN SKYBLUE PURPLE BEIGE))

;; CircleWave struct as vectors: position-x position-y radius alpha speed color
(define circles
  (for/vector ([i (in-range MAX-CIRCLES)])
    (let* ([radius (exact->inexact (get-random-value 10 40))]
           [r (exact-round radius)])
      (vector
       (exact->inexact (get-random-value r (- screen-width r)))
       (exact->inexact (get-random-value r (- screen-height r)))
       radius
       0.0  ; alpha
       (/ (exact->inexact (get-random-value 1 100)) 2000.0)  ; speed
       (vector-ref colors (get-random-value 0 13))))))

(define music (load-music-stream (resource "mini1111.xm")))
;; Music: [0]buffer [1]proc [2]sampleRate [3]sampleSize [4]channels [5]as-pad [6]frameCount [7]looping [8]ctxType [9]ctxData
(set! music (list-set music 7 0))  ; looping = false
(define pitch 1.0)
(play-music-stream music)
(define time-played 0.0)
(define pause #f)

(set-target-fps 60)

(define (update-circle! c)
  ;; Destructively update circle
  (let ([alpha (+ (vector-ref c 3) (vector-ref c 4))]
        [radius (+ (vector-ref c 2) (* (vector-ref c 4) 10.0))]
        [speed (vector-ref c 4)])
    (vector-set! c 3 alpha)
    (vector-set! c 2 radius)
    (when (> alpha 1.0) (vector-set! c 4 (- speed)))
    (when (<= alpha 0.0)
      (let ([new-radius (exact->inexact (get-random-value 10 40))]
            [r (exact-round (exact->inexact (get-random-value 10 40)))])
        (vector-set! c 3 0.0)
        (vector-set! c 2 new-radius)
        (vector-set! c 0 (exact->inexact (get-random-value (exact-round new-radius) (- screen-width (exact-round new-radius)))))
        (vector-set! c 1 (exact->inexact (get-random-value (exact-round new-radius) (- screen-height (exact-round new-radius)))))
        (vector-set! c 5 (vector-ref colors (get-random-value 0 13)))
        (vector-set! c 4 (/ (exact->inexact (get-random-value 1 100)) 2000.0))))))

(define (main-loop)
  (when (not (window-should-close?))
    ;; Update
    (update-music-stream music)
    
    (when (is-key-pressed KEY-SPACE)
      (stop-music-stream music)
      (play-music-stream music)
      (set! pause #f))
    
    (when (is-key-pressed KEY-P)
      (set! pause (not pause))
      (if pause
          (pause-music-stream music)
          (resume-music-stream music)))
    
    (when (is-key-down KEY-DOWN)
      (set! pitch (- pitch 0.01)))
    (when (is-key-down KEY-UP)
      (set! pitch (+ pitch 0.01)))
    (set-music-pitch music pitch)
    
    (set! time-played (* (/ (get-music-time-played music) (get-music-time-length music)) (- screen-width 40.0)))
    
    ;; Animate circles
    (unless pause
      (for ([i (in-range (sub1 MAX-CIRCLES) -1 -1)])
        (update-circle! (vector-ref circles i))))
    
    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)
    
    (for ([i (in-range (sub1 MAX-CIRCLES) -1 -1)])
      (let ([c (vector-ref circles i)])
        (draw-circle-v (vector2 (vector-ref c 0) (vector-ref c 1))
                       (vector-ref c 2)
                       (fade (vector-ref c 5) (vector-ref c 3)))))
    
    ;; Time bar
    (draw-rectangle 20 (- screen-height 20 12) (- screen-width 40) 12 LIGHTGRAY)
    (draw-rectangle 20 (- screen-height 20 12) (exact-round time-played) 12 MAROON)
    (draw-rectangle-lines 20 (- screen-height 20 12) (- screen-width 40) 12 GRAY)
    
    ;; Help panel
    (draw-rectangle 20 20 425 145 WHITE)
    (draw-rectangle-lines 20 20 425 145 GRAY)
    (draw-text "PRESS SPACE TO RESTART MUSIC" 40 40 20 BLACK)
    (draw-text "PRESS P TO PAUSE/RESUME" 40 70 20 BLACK)
    (draw-text "PRESS UP/DOWN TO CHANGE SPEED" 40 100 20 BLACK)
    (draw-text (~a "SPEED: " (real->decimal-string pitch 6)) 40 130 20 MAROON)
    
    (end-drawing)
    (main-loop)))

(main-loop)

(unload-music-stream music)
(close-audio-device)
(close-window)
