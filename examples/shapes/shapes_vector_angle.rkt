#lang racket/base
;; raylib [shapes] example - vector angle (Racket FFI 翻译)
;; SPACE 切换模式，右键拖动 V1
(require "../../raylib/raylib.rkt" racket/math)

(define screen-w 800) (define screen-h 450)
(init-window screen-w screen-h "raylib [shapes] example - vector angle")
(set-target-fps 60)

(define RAD2DEG (/ 180.0 pi))
(define DEG2RAD (/ pi 180.0))

(define v0 (vector2 (/ screen-w 2.0) (/ screen-h 2.0)))
(define v1 (vec2-add v0 (vector2 100.0 80.0)))
(define v2 (vector2 0.0 0.0))

(define angle-mode (box 0))

(define (vec2-angle a b)
  (let* ([ax (ptr-ref a _float 0)] [ay (ptr-ref a _float 1)]
         [bx (ptr-ref b _float 0)] [by (ptr-ref b _float 1)]
         [dot (+ (* ax bx) (* ay by))]
         [len-a (sqrt (+ (* ax ax) (* ay ay)))]
         [len-b (sqrt (+ (* bx bx) (* by by)))])
    (acos (/ dot (* len-a len-b)))))

(define (vec2-line-angle start end)
  (let ([dx (- (ptr-ref end _float 0) (ptr-ref start _float 0))]
        [dy (- (ptr-ref end _float 1) (ptr-ref start _float 1))])
    (atan dy dx)))

(let main-loop ()
  (unless (window-should-close?)
    (ptr-set! v2 _float 0 (exact->inexact (get-mouse-x)))
    (ptr-set! v2 _float 1 (exact->inexact (get-mouse-y)))

    (when (is-key-pressed KEY-SPACE)
      (set-box! angle-mode (- 1 (unbox angle-mode))))

    (when (and (= (unbox angle-mode) 0) (is-mouse-button-down MOUSE-BUTTON-RIGHT))
      (ptr-set! v1 _float 0 (exact->inexact (get-mouse-x)))
      (ptr-set! v1 _float 1 (exact->inexact (get-mouse-y))))

    (define angle
      (if (= (unbox angle-mode) 0)
          (let* ([v1n (vec2-normalize (vec2-subtract v1 v0))]
                 [v2n (vec2-normalize (vec2-subtract v2 v0))])
            (* (vec2-angle v1n v2n) RAD2DEG))
          (* (vec2-line-angle v0 v2) RAD2DEG)))

    (define start-angle
      (if (= (unbox angle-mode) 0)
          (* -1 (vec2-line-angle v0 v1) RAD2DEG)
          0.0))

    (begin-drawing)
    (clear-background RAYWHITE)

    (if (= (unbox angle-mode) 0)
        (begin
          (draw-text "MODE 0: Angle between V1 and V2" 10 10 20 BLACK)
          (draw-text "Right Click to Move V1" 10 30 20 DARKGRAY)
          (draw-line-ex v0 v1 2.0 BLACK)
          (draw-line-ex v0 v2 2.0 RED)
          (draw-circle-sector v0 40.0 start-angle (+ start-angle angle) 32 (fade GREEN 0.6)))
        (begin
          (draw-text "MODE 1: Angle formed by line V1 to V2" 10 10 20 BLACK)
          (draw-line 0 (/ screen-h 2) screen-w (/ screen-h 2) LIGHTGRAY)
          (draw-line-ex v0 v2 2.0 RED)
          (draw-circle-sector v0 40.0 start-angle (- start-angle angle) 32 (fade GREEN 0.6))))

    ;; 标签
    (draw-text "v0" (exact-round (ptr-ref v0 _float 0)) (exact-round (ptr-ref v0 _float 1)) 10 DARKGRAY)
    (when (= (unbox angle-mode) 0)
      (let ([dy (- (ptr-ref v0 _float 1) (ptr-ref v1 _float 1))])
        (draw-text "v1" (exact-round (ptr-ref v1 _float 0))
                   (- (exact-round (ptr-ref v1 _float 1)) (if (> dy 0) 10 0)) 10 DARKGRAY)))
    (when (= (unbox angle-mode) 1)
      (draw-text "v1" (+ (exact-round (ptr-ref v0 _float 0)) 40)
                 (exact-round (ptr-ref v0 _float 1)) 10 DARKGRAY))
    (draw-text "v2" (- (exact-round (ptr-ref v2 _float 0)) 10)
               (- (exact-round (ptr-ref v2 _float 1)) 10) 10 DARKGRAY)

    (draw-text "Press SPACE to change MODE" 460 10 20 DARKGRAY)
    (draw-text (format "ANGLE: ~a" (real->decimal-string angle 2)) 10 70 20 LIME)
    (end-drawing)
    (main-loop)))

(close-window)
