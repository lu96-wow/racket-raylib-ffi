#lang racket/base

;; raylib [textures] example - framebuffer rendering (Racket FFI 翻译)

(require racket/list
         racket/math
         "../../raylib/raylib.rkt")

(define screen-width 800)
(define screen-height 450)
(define split-width (quotient screen-width 2))

(define (draw-camera-prism! camera aspect color)
  (let* ([px (Camera3D-pos-x camera)]
         [py (Camera3D-pos-y camera)]
         [pz (Camera3D-pos-z camera)]
         [tx (Camera3D-tar-x camera)]
         [ty (Camera3D-tar-y camera)]
         [tz (Camera3D-tar-z camera)]
         [fovy (Camera3D-fovy camera)]
         [len (sqrt (+ (* (- px tx) (- px tx)) (* (- py ty) (- py ty)) (* (- pz tz) (- pz tz))))]
         [ndcs (list (vector -1.0 -1.0 1.0) (vector 1.0 -1.0 1.0)
                     (vector 1.0  1.0 1.0) (vector -1.0  1.0 1.0))]
         [vm (get-camera-matrix camera)]
         [pm (matrix-perspective (* fovy (/ pi 180.0)) aspect 0.05 len)]
         [vp (matrix-multiply vm pm)]
         [ivp (matrix-invert vp)]
         [m0 (list-ref ivp 0)]  [m1 (list-ref ivp 1)]
         [m2 (list-ref ivp 2)]  [m3 (list-ref ivp 3)]
         [m4 (list-ref ivp 4)]  [m5 (list-ref ivp 5)]
         [m6 (list-ref ivp 6)]  [m7 (list-ref ivp 7)]
         [m8 (list-ref ivp 8)]  [m9 (list-ref ivp 9)]
         [m10 (list-ref ivp 10)] [m11 (list-ref ivp 11)]
         [m12 (list-ref ivp 12)] [m13 (list-ref ivp 13)]
         [m14 (list-ref ivp 14)] [m15 (list-ref ivp 15)]
         [corners
          (for/list ([ndc (in-list ndcs)])
            (let* ([x (vector-ref ndc 0)] [y (vector-ref ndc 1)] [z (vector-ref ndc 2)]
                   [wx (+ (* m0 x) (* m4 y) (* m8  z) m12)]
                   [wy (+ (* m1 x) (* m5 y) (* m9  z) m13)]
                   [wz (+ (* m2 x) (* m6 y) (* m10 z) m14)]
                   [ww (+ (* m3 x) (* m7 y) (* m11 z) m15)])
              (make-Vector3 (/ wx ww) (/ wy ww) (/ wz ww))))]
         [cam-pos (make-Vector3 px py pz)])
    (draw-line-3d (list-ref corners 0) (list-ref corners 1) color)
    (draw-line-3d (list-ref corners 1) (list-ref corners 2) color)
    (draw-line-3d (list-ref corners 2) (list-ref corners 3) color)
    (draw-line-3d (list-ref corners 3) (list-ref corners 0) color)
    (for ([i (in-range 4)])
      (draw-line-3d cam-pos (list-ref corners i) color))))

(init-window screen-width screen-height
  "raylib [textures] example - framebuffer rendering")

(define subj-cam (make-Camera3D 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 45.0 0))
(set-Camera3D-pos-x! subj-cam 5.0)
(set-Camera3D-pos-y! subj-cam 5.0)
(set-Camera3D-pos-z! subj-cam 5.0)
(set-Camera3D-tar-x! subj-cam 0.0)
(set-Camera3D-tar-y! subj-cam 0.0)
(set-Camera3D-tar-z! subj-cam 0.0)
(set-Camera3D-up-x! subj-cam 0.0)
(set-Camera3D-up-y! subj-cam 1.0)
(set-Camera3D-up-z! subj-cam 0.0)
(set-Camera3D-fovy! subj-cam 45.0)
(set-Camera3D-projection! subj-cam CAMERA-PERSPECTIVE)

(define obs-cam (make-Camera3D 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0 45.0 0))
(set-Camera3D-pos-x! obs-cam 10.0)
(set-Camera3D-pos-y! obs-cam 10.0)
(set-Camera3D-pos-z! obs-cam 10.0)
(set-Camera3D-tar-x! obs-cam 0.0)
(set-Camera3D-tar-y! obs-cam 0.0)
(set-Camera3D-tar-z! obs-cam 0.0)
(set-Camera3D-up-x! obs-cam 0.0)
(set-Camera3D-up-y! obs-cam 1.0)
(set-Camera3D-up-z! obs-cam 0.0)
(set-Camera3D-fovy! obs-cam 45.0)
(set-Camera3D-projection! obs-cam CAMERA-PERSPECTIVE)

(define obs-tgt (load-render-texture split-width screen-height))
(define subj-tgt (load-render-texture split-width screen-height))




(define obs-src (make-Rectangle 0.0 0.0
                  (exact->inexact (list-ref obs-tgt 2))
                  (- (exact->inexact (list-ref obs-tgt 3)))))
(define obs-dst (make-Rectangle 0.0 0.0
                  (exact->inexact split-width)
                  (exact->inexact screen-height)))
(define subj-src (make-Rectangle 0.0 0.0
                   (exact->inexact (list-ref subj-tgt 2))
                   (- (exact->inexact (list-ref subj-tgt 3)))))
(define subj-dst (make-Rectangle (exact->inexact split-width) 0.0
                   (exact->inexact split-width)
                   (exact->inexact screen-height)))
(define (rt->texture rt)
  (list (list-ref rt 1) (list-ref rt 2) (list-ref rt 3)
        (list-ref rt 4) (list-ref rt 5)))

(define aspect-ratio
  (/ (exact->inexact (list-ref subj-tgt 2))
     (exact->inexact (list-ref subj-tgt 3))))

(define cap 128.0)
(define crop-src
  (let ([tw (list-ref subj-tgt 2)] [th (list-ref subj-tgt 3)])
    (make-Rectangle (/ (- tw cap) 2.0) (/ (- th cap) 2.0) cap (- cap))))
(define crop-dst (make-Rectangle (+ split-width 20.0) 20.0 cap cap))

(set-target-fps 60)
(disable-cursor)

(let loop ()
  (unless (window-should-close?)
    (update-camera obs-cam CAMERA-FREE)
    (update-camera subj-cam CAMERA-ORBITAL)
    (when (is-key-pressed KEY-R)
      (set-Camera3D-tar-x! obs-cam 0.0)
      (set-Camera3D-tar-y! obs-cam 0.0)
      (set-Camera3D-tar-z! obs-cam 0.0))

    (begin-texture-mode obs-tgt)
    (clear-background RAYWHITE)
    (begin-mode-3d obs-cam)
    (draw-grid 10 1.0)
    (draw-cube (make-Vector3 0.0 0.0 0.0) 2.0 2.0 2.0 GOLD)
    (draw-cube-wires (make-Vector3 0.0 0.0 0.0) 2.0 2.0 2.0 PINK)
    (draw-camera-prism! subj-cam aspect-ratio GREEN)
    (end-mode-3d)
    (draw-text "Observer View" 10 (- (list-ref obs-tgt 3) 30) 20 BLACK)
    (draw-text "WASD + Mouse to Move" 10 10 20 DARKGRAY)
    (draw-text "Scroll to Zoom" 10 30 20 DARKGRAY)
    (draw-text "R to Reset Observer Target" 10 50 20 DARKGRAY)
    (end-texture-mode)

    (begin-texture-mode subj-tgt)
    (clear-background RAYWHITE)
    (begin-mode-3d subj-cam)
    (draw-cube (make-Vector3 0.0 0.0 0.0) 2.0 2.0 2.0 GOLD)
    (draw-cube-wires (make-Vector3 0.0 0.0 0.0) 2.0 2.0 2.0 PINK)
    (draw-grid 10 1.0)
    (end-mode-3d)
    (let* ([tw (list-ref subj-tgt 2)] [th (list-ref subj-tgt 3)])
      (draw-rectangle-lines (exact-floor (/ (- tw cap) 2.0))
                            (exact-floor (/ (- th cap) 2.0))
                            (exact-floor cap) (exact-floor cap) GREEN))
    (draw-text "Subject View" 10 (- (list-ref subj-tgt 3) 30) 20 BLACK)
    (end-texture-mode)

    (begin-drawing)
    (clear-background BLACK)
    (draw-texture-pro (rt->texture obs-tgt) obs-src obs-dst (vector2 0.0 0.0) 0.0 WHITE)
    (draw-texture-pro (rt->texture subj-tgt) subj-src subj-dst (vector2 0.0 0.0) 0.0 WHITE)
    (draw-texture-pro (rt->texture subj-tgt) crop-src crop-dst (vector2 0.0 0.0) 0.0 WHITE)
    (draw-rectangle-lines-ex crop-dst 2.0 BLACK)
    (draw-line split-width 0 split-width screen-height BLACK)
    (end-drawing)
    (loop)))

(unload-render-texture obs-tgt)
(unload-render-texture subj-tgt)
(close-window)
