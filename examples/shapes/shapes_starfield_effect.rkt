#lang racket/base
;; raylib [shapes] example - starfield effect (Racket FFI 翻译)
(require "../../raylib/raylib.rkt" (only-in ffi/unsafe malloc) racket/math)

(define STAR-COUNT 420) (define screen-w 800) (define screen-h 450)
(init-window screen-w screen-h "raylib [shapes] example - starfield effect")
(set-target-fps 60)

(define bg-color
  (let ([c (malloc _Color 'atomic)])
    (ptr-set! c _ubyte 0 (exact-round (+ (ptr-ref DARKBLUE _ubyte 0) (* 0.69 (- (ptr-ref BLACK _ubyte 0) (ptr-ref DARKBLUE _ubyte 0))))))
    (ptr-set! c _ubyte 1 (exact-round (+ (ptr-ref DARKBLUE _ubyte 1) (* 0.69 (- (ptr-ref BLACK _ubyte 1) (ptr-ref DARKBLUE _ubyte 1))))))
    (ptr-set! c _ubyte 2 (exact-round (+ (ptr-ref DARKBLUE _ubyte 2) (* 0.69 (- (ptr-ref BLACK _ubyte 2) (ptr-ref DARKBLUE _ubyte 2))))))
    (ptr-set! c _ubyte 3 255) c))

(define-var speed (/ 10.0 9.0))
(define-var draw-lines? #t)

(define stars (make-vector STAR-COUNT))
(for ([i (in-range STAR-COUNT)])
  (define v (malloc _Vector3 'atomic))
  (ptr-set! v _float 0 (exact->inexact (get-random-value (- (quotient screen-w 2)) (quotient screen-w 2))))
  (ptr-set! v _float 1 (exact->inexact (get-random-value (- (quotient screen-h 2)) (quotient screen-h 2))))
  (ptr-set! v _float 2 1.0)
  (vector-set! stars i v))

(let main-loop ()
  (unless (window-should-close?)
    (define dt (get-frame-time)) (define sp (unbox speed))

    ;; 鼠标滚轮调速度
    (define mw (get-mouse-wheel-move))
    (when (not (= mw 0.0)) (set-box! speed (max 0.1 (min 2.0 (+ sp (* 2.0 (/ mw 9.0)))))))
    (when (is-key-pressed KEY-SPACE) (set-box! draw-lines? (not (unbox draw-lines?))))

    (set! sp (unbox speed))
    (begin-drawing)
    (clear-background bg-color)

    (for ([i (in-range STAR-COUNT)])
      (define s (vector-ref stars i))
      (define sx (ptr-ref s _float 0)) (define sy (ptr-ref s _float 1)) (define sz (ptr-ref s _float 2))

      ;; 更新深度
      (ptr-set! s _float 2 (- sz (* dt sp)))
      (define new-sz (ptr-ref s _float 2))

      ;; 屏幕坐标
      (define screen-x (+ (/ screen-w 2.0) (/ sx new-sz)))
      (define screen-y (+ (/ screen-h 2.0) (/ sy new-sz)))

      ;; 检测重生
      (when (or (< new-sz 0.0) (< screen-x 0) (< screen-y 0.0)
                (> screen-x screen-w) (> screen-y screen-h))
        (ptr-set! s _float 0 (exact->inexact (get-random-value (- (quotient screen-w 2)) (quotient screen-w 2))))
        (ptr-set! s _float 1 (exact->inexact (get-random-value (- (quotient screen-h 2)) (quotient screen-h 2))))
        (ptr-set! s _float 2 1.0))

      ;; 绘制
      (define final-sz (ptr-ref s _float 2))
      (define fx (+ (/ screen-w 2.0) (/ sx final-sz)))
      (define fy (+ (/ screen-h 2.0) (/ sy final-sz)))

      (if (unbox draw-lines?)
          (let ([t (max 0.0 (min 1.0 (+ final-sz 1/32)))])
            (when (> (- t final-sz) 1e-3)
              (define ox (+ (/ screen-w 2.0) (/ sx t)))
              (define oy (+ (/ screen-h 2.0) (/ sy t)))
              (draw-line-v (vector2 ox oy) (vector2 fx fy) RAYWHITE)))
          (draw-circle-v (vector2 fx fy) (lerp final-sz 1.0 5.0) RAYWHITE)))

    (draw-text (format "[MOUSE WHEEL] Speed: ~a" (real->decimal-string (/ (* 9.0 sp) 2.0) 0)) 10 40 20 RAYWHITE)
    (draw-text (format "[SPACE] Mode: ~a" (if (unbox draw-lines?) "Lines" "Circles")) 10 70 20 RAYWHITE)
    (draw-fps 10 10)
    (end-drawing)
    (main-loop)))

(close-window)
