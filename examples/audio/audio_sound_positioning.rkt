#lang racket/base

;; raylib [audio] example - sound positioning (Racket FFI 翻译)
;;
;; 对应 C: examples/audio/audio_sound_positioning.c
;; 复杂度: [★★☆☆] 2/4

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         racket/math
         ffi/unsafe)

(define-runtime-path resource-dir "../../../examples/audio/resources/")
(define (resource f) (path->string (build-path resource-dir f)))

;; --- Helpers ---

;; Get camera position as vector3
(define (camera-pos cam) (vector3 (ptr-ref cam _float 0) (ptr-ref cam _float 1) (ptr-ref cam _float 2)))
(define (camera-target cam) (vector3 (ptr-ref cam _float 3) (ptr-ref cam _float 4) (ptr-ref cam _float 5)))
(define (camera-up cam) (vector3 (ptr-ref cam _float 6) (ptr-ref cam _float 7) (ptr-ref cam _float 8)))

;; SetSoundPosition: calculate volume/pan based on 3D position
(define (set-sound-position cam sound position max-dist)
  (define direction (vec3-subtract position (camera-pos cam)))
  (define distance (vec3-length direction))
  
  (define atten (/ 1.0 (+ 1.0 (/ distance max-dist))))
  (define attenuation (clamp atten 0.0 1.0))
  
  (define norm-dir (vec3-normalize direction))
  (define forward (vec3-normalize (vec3-subtract (camera-target cam) (camera-pos cam))))
  (define right (vec3-normalize (vec3-cross-product (camera-up cam) forward)))
  
  (define dot-product (vec3-dot-product forward norm-dir))
  (define final-atten (if (< dot-product 0.0) (* attenuation (+ 1.0 (* dot-product 0.5))) attenuation))
  
  (define pan (+ 0.5 (* 0.5 (vec3-dot-product norm-dir right))))
  
  (set-sound-volume sound final-atten)
  (set-sound-pan sound pan))

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height "raylib [audio] example - sound positioning")
(init-audio-device)

(define sound (load-sound (resource "coin.wav")))

;; Camera: position(0,5,5) target(0,0,0) up(0,1,0) fovy=60 projection=CAMERA_PERSPECTIVE(0)
(define camera (camera3d 0.0 5.0 5.0 0.0 0.0 0.0 0.0 1.0 0.0 60.0 0))

(disable-cursor)
(set-target-fps 60)

(define (main-loop)
  (when (not (window-should-close?))
    ;; Simple free camera update
    (define mouse-delta (get-mouse-delta))
    (when (is-mouse-button-down MOUSE-BUTTON-RIGHT)
      (camera-yaw camera (* (vector2-x mouse-delta) 0.003) #f)
      (camera-pitch camera (* (vector2-y mouse-delta) 0.003) #t #f #f))
    
    (define wheel (get-mouse-wheel-move))
    (unless (zero? wheel)
      (camera-move-to-target camera (* wheel 0.5)))
    
    (define th (get-time))
    (define sphere-pos (vector3 (* 5.0 (cos th)) 0.0 (* 5.0 (sin th))))
    
    (set-sound-position camera sound sphere-pos 1.0)
    
    (unless (is-sound-playing? sound)
      (play-sound sound))
    
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (draw-grid 10 2)
    (draw-sphere sphere-pos 0.5 RED)
    (end-mode-3d)
    (end-drawing)
    
    (main-loop)))

(main-loop)

(unload-sound sound)
(close-audio-device)
(close-window)
