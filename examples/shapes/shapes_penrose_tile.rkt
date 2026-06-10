#lang racket/base
;; raylib [shapes] example - penrose tile (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_penrose_tile.c
;; Penrose 拼贴 - 基于 L-system 的海龟绘图

(require "../../raylib/raylib.rkt" racket/math)

;; ============================================================
;; 常量
;; ============================================================

(define TURTLE-STACK-MAX 50)

;; ============================================================
;; 数据结构
;; ============================================================

;; TurtleState: 海龟状态 (x, y, angle)
(struct turtle-state (x y angle) #:mutable #:transparent)

;; 海龟栈
(define turtle-stack (make-vector TURTLE-STACK-MAX (turtle-state 0.0 0.0 0.0)))
(define turtle-top (box -1))

(define (push-turtle-state! ts)
  (when (< (unbox turtle-top) (sub1 TURTLE-STACK-MAX))
    (set-box! turtle-top (add1 (unbox turtle-top)))
    (vector-set! turtle-stack (unbox turtle-top) ts)))

(define (pop-turtle-state!)
  (if (>= (unbox turtle-top) 0)
      (let ([ts (vector-ref turtle-stack (unbox turtle-top))])
        (set-box! turtle-top (sub1 (unbox turtle-top)))
        ts)
      (turtle-state 0.0 0.0 0.0)))

;; ============================================================
;; Penrose L-System
;; ============================================================

(struct penrose-ls (steps production rule-w rule-x rule-y rule-z draw-length theta)
  #:mutable #:transparent)

(define (create-penrose-ls draw-length)
  (penrose-ls 0
              "[X]++[X]++[X]++[X]++[X]"
              "YF++ZF4-XF[-YF4-WF]++"
              "+YF--ZF[3-WF--XF]+"
              "-WF++XF[+++YF++ZF]-"
              "--YF++++WF[+ZF++++XF]--XF"
              draw-length
              36.0))

(define (build-production-step! ls)
  (define old (penrose-ls-production ls))
  (define new (make-string (min (* (string-length old) 8) 100000)))
  (define new-len (box 0))
  (define (append-str s)
    (for ([ch (in-string s)])
      (when (< (unbox new-len) (string-length new))
        (string-set! new (unbox new-len) ch)
        (set-box! new-len (add1 (unbox new-len))))))
  (for ([ch (in-string old)])
    (case ch
      [(#\W) (append-str (penrose-ls-rule-w ls))]
      [(#\X) (append-str (penrose-ls-rule-x ls))]
      [(#\Y) (append-str (penrose-ls-rule-y ls))]
      [(#\Z) (append-str (penrose-ls-rule-z ls))]
      [(#\F) (void)]  ;; skip F
      [else  (append-str (string ch))]))
  (set-penrose-ls-draw-length! ls (* (penrose-ls-draw-length ls) 0.5))
  (set-penrose-ls-production! ls (substring new 0 (unbox new-len))))

(define (draw-penrose-ls! ls)
  (define cx (/ (get-screen-width) 2.0))
  (define cy (/ (get-screen-height) 2.0))
  (define deg2rad (/ pi 180.0))

  (define turtle (turtle-state 0.0 0.0 -90.0))
  (define repeats (box 1))
  (define prod (penrose-ls-production ls))
  (define prod-len (string-length prod))

  (set-penrose-ls-steps! ls (+ (penrose-ls-steps ls) 12))
  (when (> (penrose-ls-steps ls) prod-len)
    (set-penrose-ls-steps! ls prod-len))

  (for ([i (in-range (penrose-ls-steps ls))])
    (define ch (string-ref prod i))
    (let ([r (unbox repeats)])
      (cond
       [(char=? ch #\F)
        (for ([j (in-range r)])
          (define sx (turtle-state-x turtle))
          (define sy (turtle-state-y turtle))
          (define rad (* deg2rad (turtle-state-angle turtle)))
          (define dx (* (penrose-ls-draw-length ls) (cos rad)))
          (define dy (* (penrose-ls-draw-length ls) (sin rad)))
          (set-turtle-state-x! turtle (+ sx dx))
          (set-turtle-state-y! turtle (+ sy dy))
          (define ex (turtle-state-x turtle))
          (define ey (turtle-state-y turtle))
          (draw-line-ex (vector2 (+ sx cx) (+ sy cy))
                        (vector2 (+ ex cx) (+ ey cy))
                        2.0 (fade BLACK 0.2)))
        (set-box! repeats 1)]
       [(char=? ch #\+)
        (for ([j (in-range r)])
          (set-turtle-state-angle! turtle (+ (turtle-state-angle turtle) (penrose-ls-theta ls))))
        (set-box! repeats 1)]
       [(char=? ch #\-)
        (for ([j (in-range r)])
          (set-turtle-state-angle! turtle (- (turtle-state-angle turtle) (penrose-ls-theta ls))))
        (set-box! repeats 1)]
       [(char=? ch #\[)
        (push-turtle-state!
         (turtle-state (turtle-state-x turtle) (turtle-state-y turtle)
                       (turtle-state-angle turtle)))]
       [(char=? ch #\]) (set! turtle (pop-turtle-state!))]
       [else
        (when (and (char>=? ch #\0) (char<=? ch #\9))
          (set-box! repeats (- (char->integer ch) 48)))])))

  (set-box! turtle-top -1))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window screen-width screen-height
  "raylib [shapes] example - penrose tile")

(define draw-length 460.0)
(define min-generations 0)
(define max-generations 4)
(define generations (box 0))

;; 初始化 L-system
(define ls (create-penrose-ls (* draw-length (/ (unbox generations) max-generations 1.0))))
(for ([i (in-range (unbox generations))]) (build-production-step! ls))

(set-target-fps 120)

;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()
  (unless (window-should-close?)
    (define rebuild? #f)
    (when (is-key-pressed KEY-UP)
      (when (< (unbox generations) max-generations)
        (set-box! generations (add1 (unbox generations)))
        (set! rebuild? #t)))
    (when (is-key-pressed KEY-DOWN)
      (when (> (unbox generations) min-generations)
        (set-box! generations (sub1 (unbox generations)))
        (when (> (unbox generations) 0) (set! rebuild? #t))))
    (when rebuild?
      (set! ls (create-penrose-ls
                (* draw-length (/ (unbox generations) max-generations 1.0))))
      (for ([i (in-range (unbox generations))]) (build-production-step! ls)))
    (begin-drawing)
    (clear-background RAYWHITE)
    (when (> (unbox generations) 0) (draw-penrose-ls! ls))
    (draw-text "penrose l-system" 10 10 20 DARKGRAY)
    (draw-text "press up or down to change generations" 10 30 20 DARKGRAY)
    (draw-text (format "generations: ~a" (unbox generations)) 10 50 20 DARKGRAY)
    (end-drawing)
    (main-loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)

