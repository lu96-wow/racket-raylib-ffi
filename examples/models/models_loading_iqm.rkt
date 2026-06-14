#lang racket/base

;; raylib [models] example - loading iqm (Racket FFI 翻译)
;; 带动画

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define-runtime-path resource-dir "../../../examples/models/resources/")

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [models] example - loading iqm")

(define camera (camera3d 10.0 10.0 10.0
                              0.0 4.0 0.0
                              0.0 1.0 0.0
                              45.0 CAMERA-PERSPECTIVE))

(define guy-model
  (load-model (string-append (path->string resource-dir) "models/iqm/guy.iqm")))

(define guy-texture
  (load-texture (string-append (path->string resource-dir) "models/iqm/guytex.png")))

;; materials is index 19 in model list
(set-material-texture (list-ref guy-model 19) MATERIAL-MAP-DIFFUSE guy-texture)

(define position (vector3 0.0 0.0 0.0))

;; Load animation
(define anim-ok? #f)
(define anim-name "N/A")
(define keyframe-count 0)
(define first-anim #f)
(let-values ([(anims-ptr anim-count)
              (load-model-animations
                (string-append (path->string resource-dir) "models/iqm/guyanim.iqm"))])
  (when (and anims-ptr (> anim-count 0))
    (set! anim-ok? #t)
    (set! anim-name (model-animation-name anims-ptr))
    (set! keyframe-count (model-animation-keyframe-count anims-ptr))
    (set! first-anim (ptr-ref anims-ptr _model-animation-bytes 0)))
  
  (define current-frame 0.0)
  
  (set-target-fps 60)
  
  (let loop ()
    (unless (window-should-close?)
      (update-camera camera CAMERA-ORBITAL)
      
      ;; Update animation (always playing)
      (when anim-ok?
        (set! current-frame (+ current-frame 1.0))
        (update-model-animation guy-model first-anim current-frame)
        (when (>= current-frame keyframe-count)
          (set! current-frame 0.0)))
      
      (begin-drawing)
      (clear-background RAYWHITE)
      
      (begin-mode-3d camera)
      (draw-model-ex guy-model position
                     (vector3 1.0 0.0 0.0) -90.0
                     (vector3 1.0 1.0 1.0) WHITE)
      (draw-grid 10 1.0)
      (end-mode-3d)
      
      (draw-text (format "Animation: ~a" anim-name) 10 10 20 MAROON)
      (draw-text "(c) Guy IQM 3D model by @culacant"
                 (- screen-width 200) (- screen-height 20) 10 GRAY)
      
      (end-drawing)
      (loop)))
  
  (unload-texture guy-texture)
  (unload-model-animations anims-ptr anim-count)
  (unload-model guy-model))

(close-window)
