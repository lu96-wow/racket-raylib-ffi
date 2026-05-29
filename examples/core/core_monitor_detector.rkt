#lang racket/base

(require "../../raylib/raylib.rkt")

(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 450)

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - monitor detector")

(define current-monitor (box 0))
(set-target-fps 60)

(define (build-monitors count)
  (for/list ([i (in-range count)])
    (list (get-monitor-position i) (get-monitor-name i)
          (get-monitor-width i) (get-monitor-height i)
          (get-monitor-physical-width i) (get-monitor-physical-height i)
          (get-monitor-refresh-rate i))))

(let loop ()
  (unless (window-should-close?)
    (let* ([count (get-monitor-count)]
           [monitors (build-monitors count)]
           [maxW (apply max 1
                   (for/list ([m monitors])
                     (+ (inexact->exact (floor (vector2-x (list-ref m 0))))
                        (list-ref m 2))))]
           [maxH (apply max 1
                   (for/list ([m monitors])
                     (+ (inexact->exact (floor (vector2-y (list-ref m 0))))
                        (list-ref m 3))))]
           [offX (- 0 (apply min 0
                       (for/list ([m monitors])
                         (inexact->exact (floor (vector2-x (list-ref m 0)))))))])

      (when (and (is-key-pressed KEY-ENTER) (> count 1))
        (set-box! current-monitor (modulo (add1 (unbox current-monitor)) count))
        (set-window-monitor (unbox current-monitor)))
      (unless (is-key-pressed KEY-ENTER)
        (set-box! current-monitor (get-current-monitor)))

      (let* ([base-scale 0.6]
             [scale (if (> maxH (+ maxW offX))
                      (* base-scale (/ SCREEN-HEIGHT maxH))
                      (* base-scale (/ SCREEN-WIDTH (+ maxW offX))))]
             [fs (λ (x) (inexact->exact (floor (* x scale))))])

        (begin-drawing)
        (clear-background RAYWHITE)
        (draw-text "Press [Enter] to move window to next monitor available"
          20 20 20 DARKGRAY)
        (draw-rectangle-lines 20 60 (- SCREEN-WIDTH 40) (- SCREEN-HEIGHT 100) DARKGRAY)

        (for ([i (in-range count)])
          (let* ([m (list-ref monitors i)]
                 [pos (list-ref m 0)]
                 [px (+ (* (+ (inexact->exact (floor (vector2-x pos))) offX) scale) 140)]
                 [py (+ (* (inexact->exact (floor (vector2-y pos))) scale) 80)]
                 [is-cur? (= i (unbox current-monitor))]
                 [rec (rectangle px py (* (list-ref m 2) scale) (* (list-ref m 3) scale))])
            (draw-rectangle-lines-ex rec 5.0 (if is-cur? RED GRAY))
            (draw-text (format "[~a] ~a" i (list-ref m 1))
              (inexact->exact (floor (+ px 10)))
              (inexact->exact (floor (+ py (* 100 scale))))
              (fs 120) BLUE)
            (draw-text (format "Resolution: [~apx x ~apx]\nRefreshRate: [~ahz]\nPhysical Size: [~amm x ~amm]\nPosition: ~a x ~a"
                        (list-ref m 2) (list-ref m 3) (list-ref m 6)
                        (list-ref m 4) (list-ref m 5)
                        (inexact->exact (floor (vector2-x pos)))
                        (inexact->exact (floor (vector2-y pos))))
              (inexact->exact (floor (+ px 10)))
              (inexact->exact (floor (+ py (* 200 scale))))
              (fs 120) DARKGRAY)
            (when is-cur?
              (let ([wp (get-window-position)])
                (draw-rectangle-v
                  (vector2 (+ (* (+ (vector2-x wp) offX) scale) 140)
                           (+ (* (vector2-y wp) scale) 80))
                  (vector2 (* SCREEN-WIDTH scale) (* SCREEN-HEIGHT scale))
                  (fade GREEN 0.5))))))

        (end-drawing)
        (loop)))))

(close-window)
