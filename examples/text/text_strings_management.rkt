#lang racket/base

;; raylib [text] example - strings management (Racket FFI 翻译)
;;
;; 对应 C: examples/text/text_strings_management.c
;;
;; 完全移植 C 原版的文本粒子物理模拟:
;;   - 鼠标左键拖拽/抛掷粒子
;;   - 鼠标右键切片（半切），Shift+右键粉碎（逐字切）
;;   - 中键摇动所有粒子
;;   - A-z 键按字符切（仅1个粒子时）
;;   - Ctrl+拖拽合并粒子
;;   - 1-6 键重置为不同文本变换

(require racket/string
         "../../raylib/raylib.rkt")

;; ============================================================
;; 文本粒子结构
;; ============================================================

(define MAX-TEXT-LENGTH 100)

(struct tp (text rect vel ppos padding border-width friction elasticity color grabbed)
  #:mutable)

;; ============================================================
;; 粒子操作函数
;; ============================================================

(define FONT-SIZE 30)

(define (create-text-particle text x y color)
  ;; (x, y) = 左上角，与 C 的 CreateTextParticle 一致
  (let* ([pad 5.0]
         [bw 5.0]
         [txt-w (measure-text text FONT-SIZE)]
         [w (+ txt-w (* pad 2))]
         [h (+ FONT-SIZE (* pad 2))])
    (tp text
        (rectangle x y w h)
        (vector2 (get-random-value -200 200) (get-random-value -200 200))
        (vector2 0.0 0.0)
        pad bw 0.99 0.9 color #f)))

(define (prepare-first-particle text particles)
  (vector-set! particles 0
               (create-text-particle text
                                     (/ (get-screen-width) 2.0)
                                     (/ (get-screen-height) 2.0)
                                     RAYWHITE)))

(define (realocate-particles! particles particle-count idx)
  (for ([i (in-range (+ idx 1) (unbox particle-count))])
    (vector-set! particles (- i 1) (vector-ref particles i)))
  (set-box! particle-count (- (unbox particle-count) 1)))

(define (slice-text-particle! tp particles particle-count slice-len)
  (define text (tp-text tp))
  (define text-len (string-length text))
  (when (and (> text-len 1)
             (< (+ (unbox particle-count) (quotient text-len slice-len))
                (vector-length particles)))
    (define rx (rectangle-x (tp-rect tp)))
    (define ry (rectangle-y (tp-rect tp)))
    (define rw (rectangle-w (tp-rect tp)))
    (for ([i (in-range 0 text-len slice-len)])
      (define piece (if (= slice-len 1)
                        (substring text i (+ i 1))
                        (substring text i (min (+ i slice-len) text-len))))
      (define col (color (get-random-value 0 255) (get-random-value 0 255)
                         (get-random-value 0 255) 255))
      (define x (+ rx (* i (/ rw text-len))))
      (vector-set! particles (unbox particle-count)
                   (create-text-particle piece x ry col))
      (set-box! particle-count (+ (unbox particle-count) 1)))
    (for ([i (in-range (unbox particle-count))])
      (when (eq? (vector-ref particles i) tp)
        (realocate-particles! particles particle-count i)
        (set! i (+ (unbox particle-count) 1))))))

(define (slice-by-char! tp particles particle-count ch)
  (define text (tp-text tp))
  (when (string-contains? text (string ch))
    (define parts (string-split text (string ch)))
    (when (> (length parts) 1)
      (define rx (rectangle-x (tp-rect tp)))
      (define ry (rectangle-y (tp-rect tp)))
      (define rw (rectangle-w (tp-rect tp)))
      (for ([i (in-range (string-length text))])
        (when (char=? (string-ref text i) ch)
          (define col (color (get-random-value 0 255) (get-random-value 0 255)
                             (get-random-value 0 255) 255))
          (vector-set! particles (unbox particle-count)
                       (create-text-particle (string ch) rx ry col))
          (set-box! particle-count (+ (unbox particle-count) 1))))
      (for ([i (in-range (length parts))])
        (define part (list-ref parts i))
        (unless (string=? part "")
          (define col (color (get-random-value 0 255) (get-random-value 0 255)
                             (get-random-value 0 255) 255))
          (define x (+ rx (* i (/ rw (length parts)))))
          (vector-set! particles (unbox particle-count)
                       (create-text-particle part x ry col))
          (set-box! particle-count (+ (unbox particle-count) 1))))
      (realocate-particles! particles particle-count 0))))

(define (shatter-particle! tp particles particle-count)
  (slice-text-particle! tp particles particle-count 1))

(define (glue-particles! grabbed target particles particle-count)
  (define p1 -1)
  (define p2 -1)
  (for ([i (in-range (unbox particle-count))])
    (when (eq? (vector-ref particles i) grabbed) (set! p1 i))
    (when (eq? (vector-ref particles i) target)  (set! p2 i)))
  (when (and (>= p1 0) (>= p2 0))
    (define new-p (create-text-particle
                   (string-append (tp-text grabbed) (tp-text target))
                   (rectangle-x (tp-rect grabbed))
                   (rectangle-y (tp-rect grabbed))
                   RAYWHITE))
    (set-tp-grabbed! new-p #t)
    (vector-set! particles (unbox particle-count) new-p)
    (set-box! particle-count (+ (unbox particle-count) 1))
    (set-tp-grabbed! grabbed #f)
    (if (< p1 p2)
        (begin (realocate-particles! particles particle-count p2)
               (realocate-particles! particles particle-count p1))
        (begin (realocate-particles! particles particle-count p1)
               (realocate-particles! particles particle-count p2)))))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define max-particles 100)

(init-window screen-width screen-height
  "raylib [text] example - strings management")

(define particles (make-vector max-particles #f))
(define particle-count (box 0))
(define grabbed-particle (box #f))
(define press-offset (vector2 0.0 0.0))

(prepare-first-particle "raylib => fun videogames programming!" particles)
(set-box! particle-count 1)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- 更新 ----
    (define delta (get-frame-time))
    (define mouse (get-mouse-position))

    ;; 鼠标左键 — 抓取粒子 (从后往前找，匹配首个即停止)
    (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
      (let grab-loop ([i (- (unbox particle-count) 1)])
        (when (>= i 0)
          (define t (vector-ref particles i))
          (when (check-collision-point-rec mouse (tp-rect t))
            (set-vector2-x! press-offset (- (vector2-x mouse) (rectangle-x (tp-rect t))))
            (set-vector2-y! press-offset (- (vector2-y mouse) (rectangle-y (tp-rect t))))
            (set-tp-grabbed! t #t)
            (set-box! grabbed-particle t))
          (unless (unbox grabbed-particle)
            (grab-loop (- i 1))))))

    ;; 鼠标左键释放 — 释放粒子
    (when (is-mouse-button-released MOUSE-BUTTON-LEFT)
      (when (unbox grabbed-particle)
        (set-tp-grabbed! (unbox grabbed-particle) #f)
        (set-box! grabbed-particle #f)))

    ;; 鼠标右键 — 切片或粉碎 (从后往前找，匹配首个即停止)
    (when (is-mouse-button-pressed MOUSE-BUTTON-RIGHT)
      (let slice-loop ([i (- (unbox particle-count) 1)])
        (when (>= i 0)
          (define t (vector-ref particles i))
          (if (check-collision-point-rec mouse (tp-rect t))
              (begin
                (if (is-key-down KEY-LEFT-SHIFT)
                    (shatter-particle! t particles particle-count)
                    (slice-text-particle! t particles particle-count
                                          (quotient (string-length (tp-text t)) 2))))
              (slice-loop (- i 1))))))

    ;; 鼠标中键 — 摇动所有粒子
    (when (is-mouse-button-pressed MOUSE-BUTTON-MIDDLE)
      (for ([i (in-range (unbox particle-count))])
        (define t (vector-ref particles i))
        (unless (tp-grabbed t)
          (set-tp-vel! t (vector2 (get-random-value -2000 2000)
                                  (get-random-value -2000 2000))))))

    ;; 1-6 键 — 文本转换重置
    (when (is-key-pressed KEY-ONE)
      (prepare-first-particle "raylib => fun videogames programming!" particles)
      (set-box! particle-count 1))
    (when (is-key-pressed KEY-TWO)
      (prepare-first-particle (text-to-upper "raylib => fun videogames programming!") particles)
      (set-box! particle-count 1))
    (when (is-key-pressed KEY-THREE)
      (prepare-first-particle (text-to-lower "raylib => fun videogames programming!") particles)
      (set-box! particle-count 1))
    (when (is-key-pressed KEY-FOUR)
      (prepare-first-particle (text-to-pascal "raylib_fun_videogames_programming") particles)
      (set-box! particle-count 1))
    (when (is-key-pressed KEY-FIVE)
      (prepare-first-particle (text-to-snake "RaylibFunVideogamesProgramming") particles)
      (set-box! particle-count 1))
    (when (is-key-pressed KEY-SIX)
      (prepare-first-particle (text-to-camel "raylib_fun_videogames_programming") particles)
      (set-box! particle-count 1))

    ;; 按字符切片（仅1个粒子时）
    (when (= (unbox particle-count) 1)
      (define ch-code (get-char-pressed))
      (when (and (>= ch-code 65) (<= ch-code 122))
        (slice-by-char! (vector-ref particles 0) particles particle-count
                        (integer->char ch-code))))

    ;; ---- 物理更新 ----
    (for ([i (in-range (unbox particle-count))])
      (define t (vector-ref particles i))
      (unless (tp-grabbed t)
        ;; 速度移动
        (set-rectangle-x! (tp-rect t) (+ (rectangle-x (tp-rect t))
                                         (* (vector2-x (tp-vel t)) delta)))
        (set-rectangle-y! (tp-rect t) (+ (rectangle-y (tp-rect t))
                                         (* (vector2-y (tp-vel t)) delta)))
        ;; 右边界
        (when (>= (+ (rectangle-x (tp-rect t)) (rectangle-w (tp-rect t))) screen-width)
          (set-rectangle-x! (tp-rect t) (- screen-width (rectangle-w (tp-rect t))))
          (set-vector2-x! (tp-vel t) (* (- (vector2-x (tp-vel t))) (tp-elasticity t))))
        ;; 左边界
        (when (<= (rectangle-x (tp-rect t)) 0)
          (set-rectangle-x! (tp-rect t) 0)
          (set-vector2-x! (tp-vel t) (* (- (vector2-x (tp-vel t))) (tp-elasticity t))))
        ;; 下边界
        (when (>= (+ (rectangle-y (tp-rect t)) (rectangle-h (tp-rect t))) screen-height)
          (set-rectangle-y! (tp-rect t) (- screen-height (rectangle-h (tp-rect t))))
          (set-vector2-y! (tp-vel t) (* (- (vector2-y (tp-vel t))) (tp-elasticity t))))
        ;; 上边界
        (when (<= (rectangle-y (tp-rect t)) 0)
          (set-rectangle-y! (tp-rect t) 0)
          (set-vector2-y! (tp-vel t) (* (- (vector2-y (tp-vel t))) (tp-elasticity t))))
        ;; 摩擦力
        (set-vector2-x! (tp-vel t) (* (vector2-x (tp-vel t)) (tp-friction t)))
        (set-vector2-y! (tp-vel t) (* (vector2-y (tp-vel t)) (tp-friction t))))
      (when (and (tp-grabbed t) (unbox grabbed-particle))
        ;; 拖拽跟随鼠标
        (set-rectangle-x! (tp-rect t) (- (vector2-x mouse) (vector2-x press-offset)))
        (set-rectangle-y! (tp-rect t) (- (vector2-y mouse) (vector2-y press-offset)))
        ;; 重新计算速度
        (set-vector2-x! (tp-vel t) (/ (- (rectangle-x (tp-rect t)) (vector2-x (tp-ppos t))) delta))
        (set-vector2-y! (tp-vel t) (/ (- (rectangle-y (tp-rect t)) (vector2-y (tp-ppos t))) delta))
        (set-vector2-x! (tp-ppos t) (rectangle-x (tp-rect t)))
        (set-vector2-y! (tp-ppos t) (rectangle-y (tp-rect t)))
        ;; Ctrl+拖拽 — 合并粒子
        (when (is-key-down KEY-LEFT-CONTROL)
          (for ([j (in-range (unbox particle-count))])
            (define other (vector-ref particles j))
            (when (and (not (eq? other (unbox grabbed-particle)))
                       (check-collision-recs (tp-rect (unbox grabbed-particle))
                                            (tp-rect other)))
              (glue-particles! (unbox grabbed-particle) other particles particle-count)
              (set-box! grabbed-particle (vector-ref particles (- (unbox particle-count) 1))))))))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (for ([i (in-range (unbox particle-count))])
      (define t (vector-ref particles i))
      (define bw (tp-border-width t))
      (define rx (rectangle-x (tp-rect t)))
      (define ry (rectangle-y (tp-rect t)))
      (define rw (rectangle-w (tp-rect t)))
      (define rh (rectangle-h (tp-rect t)))
      (draw-rectangle-rec (rectangle (- rx bw) (- ry bw)
                                     (+ rw (* bw 2)) (+ rh (* bw 2)))
                          BLACK)
      (draw-rectangle-rec (tp-rect t) (tp-color t))
      (draw-text (tp-text t)
                 (inexact->exact (truncate (+ rx (tp-padding t))))
                 (inexact->exact (truncate (+ ry (tp-padding t))))
                 FONT-SIZE BLACK))

    (draw-text "grab a text particle by pressing with the mouse and throw it by releasing" 10 10 10 DARKGRAY)
    (draw-text "slice a text particle by pressing it with the mouse right button" 10 30 10 DARKGRAY)
    (draw-text "shatter a text particle keeping left shift pressed and pressing it with the mouse right button" 10 50 10 DARKGRAY)
    (draw-text "glue text particles by grabbing than and keeping left control pressed" 10 70 10 DARKGRAY)
    (draw-text "1 to 6 to reset" 10 90 10 DARKGRAY)
    (draw-text "when you have only one text particle, you can slice it by pressing a char" 10 110 10 DARKGRAY)
    (draw-text (format "TEXT PARTICLE COUNT: ~a" (unbox particle-count)) 10 (- (get-screen-height) 30) 20 BLACK)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
