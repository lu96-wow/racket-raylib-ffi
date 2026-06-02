#lang racket/base
;; raylib [shapes] example - clock of clocks (Racket FFI 翻译)
(require "../../raylib/raylib.rkt" (only-in ffi/unsafe malloc) racket/date racket/math)

(define screen-w 800) (define screen-h 450)
(set-config-flags FLAG-MSAA-4X-HINT)
(init-window screen-w screen-h "raylib [shapes] example - clock of clocks")
(set-target-fps 60)

(define (color-lerp c1 c2 t)
  (let ([c (malloc _Color 'atomic)])
    (ptr-set! c _ubyte 0 (exact-round (+ (ptr-ref c1 _ubyte 0) (* t (- (ptr-ref c2 _ubyte 0) (ptr-ref c1 _ubyte 0))))))
    (ptr-set! c _ubyte 1 (exact-round (+ (ptr-ref c1 _ubyte 1) (* t (- (ptr-ref c2 _ubyte 1) (ptr-ref c1 _ubyte 1))))))
    (ptr-set! c _ubyte 2 (exact-round (+ (ptr-ref c1 _ubyte 2) (* t (- (ptr-ref c2 _ubyte 2) (ptr-ref c1 _ubyte 2))))))
    (ptr-set! c _ubyte 3 (exact-round (+ (ptr-ref c1 _ubyte 3) (* t (- (ptr-ref c2 _ubyte 3) (ptr-ref c1 _ubyte 3))))))
    c))

(define bg-color (color-lerp DARKBLUE BLACK 0.75))
(define hands-color (color-lerp YELLOW RAYWHITE 0.25))

(define clock-face-size 24.0) (define spacing 8.0) (define sec-spacing 16.0)

(define TL (vector2 0.0 90.0)) (define TR (vector2 90.0 180.0))
(define BR (vector2 180.0 270.0)) (define BL (vector2 0.0 270.0))
(define HH (vector2 0.0 180.0)) (define VV (vector2 90.0 270.0))
(define ZZ (vector2 135.0 135.0))

(define digit-angles (vector
  (vector TL HH HH TR VV TL TR VV VV VV VV VV VV VV VV VV VV BL BR VV BL HH HH BR)  ;; 0
  (vector TL HH TR ZZ BL TR VV ZZ ZZ VV VV ZZ ZZ VV VV ZZ TL BR BL TR BL HH HH BR)  ;; 1
  (vector TL HH HH TR BL HH TR VV VV TL HH BR VV VV TL HH BR VV BL HH TR BL HH HH BR)  ;; 2
  (vector TL HH HH TR BL HH TR VV TL HH BR VV BL HH TR VV TL HH BR VV BL HH HH BR)  ;; 3
  (vector TL TR TL TR VV VV VV VV VV BL BR VV BL HH TR VV ZZ ZZ VV VV ZZ ZZ BL BR)  ;; 4
  (vector TL HH HH TR VV TL HH BR VV BL HH TR BL HH TR VV TL HH BR VV BL HH HH BR)  ;; 5
  (vector TL HH HH TR VV TL HH BR VV BL HH TR VV TL TR VV VV BL BR VV BL HH HH BR)  ;; 6
  (vector TL HH HH TR BL HH TR VV ZZ ZZ VV VV ZZ ZZ VV VV ZZ ZZ VV VV ZZ ZZ BL BR)  ;; 7
  (vector TL HH HH TR VV TL TR VV VV BL BR VV VV TL TR VV VV BL BR VV BL HH HH BR)  ;; 8
  (vector TL HH HH TR VV TL TR VV VV BL BR VV BL HH TR VV TL HH BR VV BL HH HH BR)))  ;; 9

(define prev-seconds (box -1))
(define cur-ang (make-vector (* 6 24)))
(define hands-move-timer (box 0.0))
(define hands-move-duration 0.5)
(define hour-mode (box 24))
(define (smoothstep t) (* t t (- 3.0 (* 2.0 t))))
(let main-loop ()
  (unless (window-should-close?)
    (define dt (get-frame-time))
    (define now (current-date))
    (define s (date-second now)) (define m (date-minute now)) (define h (date-hour now))
    (define hm (unbox hour-mode))
    (define hd (modulo h hm))
    (define ts (format "~a~a~a~a~a~a" (quotient hd 10) (modulo hd 10)
                       (quotient m 10) (modulo m 10)
                       (quotient s 10) (modulo s 10)))

    (when (not (= s (unbox prev-seconds)))
      (set-box! prev-seconds s)
      (for ([digit (in-range 6)])
        (define dv (- (char->integer (string-ref ts digit)) 48))
        (define target (vector-ref digit-angles dv))
        (for ([cell (in-range 24)])
          (define idx (+ (* digit 24) cell))
          (define cur (vector-ref cur-ang idx))
          (define dst (vector-ref target cell))
          (define sx (if cur (ptr-ref cur _float 0) 0.0))
          (define sy (if cur (ptr-ref cur _float 1) 0.0))
          (define dx (ptr-ref dst _float 0)) (define dy (ptr-ref dst _float 1))
          (when (> sx dx) (set! sx (- sx 360.0)))
          (when (> sy dy) (set! sy (- sy 360.0)))
          (define cp (malloc _Vector2 'atomic))
          (ptr-set! cp _float 0 sx) (ptr-set! cp _float 1 sy)
          (vector-set! cur-ang idx cp)))
      (set-box! hands-move-timer (- dt)))

    (let ([t (unbox hands-move-timer)])
      (when (< t hands-move-duration)
        (set-box! hands-move-timer (max 0.0 (min hands-move-duration (+ t dt))))
        (define prog (smoothstep (/ (unbox hands-move-timer) hands-move-duration)))
        (for ([digit (in-range 6)])
          (define dv (- (char->integer (string-ref ts digit)) 48))
          (define target (vector-ref digit-angles dv))
          (for ([cell (in-range 24)])
            (define idx (+ (* digit 24) cell))
            (define src (vector-ref cur-ang idx))
            (define dst (vector-ref target cell))
            (define np (malloc _Vector2 'atomic))
            (ptr-set! np _float 0 (lerp (ptr-ref src _float 0) (ptr-ref dst _float 0) prog))
            (ptr-set! np _float 1 (lerp (ptr-ref src _float 1) (ptr-ref dst _float 1) prog))
            (vector-set! cur-ang idx np)))))

    (when (is-key-pressed KEY-SPACE) (set-box! hour-mode (- 36 (unbox hour-mode))))

    (begin-drawing)
    (clear-background bg-color)
    (draw-text (format "~a-h mode, space to change" hm) 10 30 20 RAYWHITE)

    (let loop-digit ([digit 0] [x-offset 4.0])
      (when (< digit 6)
        (for ([row (in-range 6)]) (for ([col (in-range 4)])
          (define cx (+ x-offset (* col (+ clock-face-size spacing)) (/ clock-face-size 2)))
          (define cy (+ 100 (* row (+ clock-face-size spacing)) (/ clock-face-size 2)))
          (define centre (vector2 cx cy))
          (draw-ring centre (- (/ clock-face-size 2) 2.0) (/ clock-face-size 2) 0 360 24 DARKGRAY)
          (define idx (+ (* digit 24) (* row 4) col))
          (define ang (vector-ref cur-ang idx))
          (when ang
            (draw-rectangle-pro (rectangle cx cy (+ (/ clock-face-size 2) 4.0) 4.0)
              (vector2 2.0 2.0) (ptr-ref ang _float 0) hands-color)
            (draw-rectangle-pro (rectangle cx cy (+ (/ clock-face-size 2) 2.0) 4.0)
              (vector2 2.0 2.0) (ptr-ref ang _float 1) hands-color))))
        (define noff (+ x-offset (* 4 (+ clock-face-size spacing))))
        (when (= (modulo digit 2) 1)
          (draw-ring (vector2 (+ noff 4.0) 160.0) 6.0 8.0 0 360 24 hands-color)
          (draw-ring (vector2 (+ noff 4.0) 225.0) 6.0 8.0 0 360 24 hands-color)
          (set! noff (+ noff sec-spacing)))
        (loop-digit (add1 digit) noff)))

    (draw-fps 10 10)
    (end-drawing)
    (main-loop)))

(close-window)

