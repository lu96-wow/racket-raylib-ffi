#lang racket/base

;; raylib [shapes] example - top down lights
;;
;; 用已验证的 API 重写, 避免 CUSTOM blend 的不确定性。
;; 使用 ADDITIVE blend 累积光源 + MULTIPLY blend 叠加光罩。

(require "../../raylib/raylib.rkt" racket/math)

;; ============================================================
;; 常量
;; ============================================================
(define MAX-BOXES 20) (define MAX-SHADOWS (* MAX-BOXES 3)) (define MAX-LIGHTS 16)
(define W 800) (define H 450)
(define vx vector2-x)(define vy vector2-y)
(define (rx r)(rectangle-x r))(define (ry r)(rectangle-y r))
(define (rw r)(rectangle-w r))(define (rh r)(rectangle-h r))
(define (v2 x y)(vector2 x y))

(define GL-ZERO      0)
(define GL-ONE       1)
(define GL-DST-COLOR #x0306)
(define GL-FUNC-ADD  #x8006)

;; ============================================================
;; 数据结构
;; ============================================================
(struct sgeom (v0 v1 v2 v3) #:transparent #:mutable)
(define (sg-make) (sgeom (v2 0 0)(v2 0 0)(v2 0 0)(v2 0 0)))
(define (sg-set! s i v)
  (case i[(0)(set-sgeom-v0! s v)][(1)(set-sgeom-v1! s v)]
         [(2)(set-sgeom-v2! s v)][(3)(set-sgeom-v3! s v)]))
(define (sg-ref s i)
  (case i[(0)(sgeom-v0 s)][(1)(sgeom-v1 s)][(2)(sgeom-v2 s)][(3)(sgeom-v3 s)]))

(struct light (active dirty pos radius bounds sgs sc) #:transparent #:mutable)
(define (mklight)
  (light #f #f (v2 0 0) 0.0 (rectangle 0 0 0 0)
         (for/vector([i MAX-SHADOWS])(sg-make)) 0))
(define lights (for/vector([i MAX-LIGHTS])(mklight)))

;; ============================================================
;; 灯光操作
;; ============================================================
(define (move-light slot x y)
  (let ([li (vector-ref lights slot)])
    (set-light-dirty! li #t)
    (ptr-set! (light-pos li) _float 0 x)
    (ptr-set! (light-pos li) _float 1 y)
    (set-rectangle-x! (light-bounds li)(- x (light-radius li)))
    (set-rectangle-y! (light-bounds li)(- y (light-radius li)))))

(define (setup-light slot x y r)
  (let ([li (vector-ref lights slot)])
    (set-light-active! li #t)
    (set-light-radius! li r)
    (set-rectangle-w! (light-bounds li)(* r 2.0))
    (set-rectangle-h! (light-bounds li)(* r 2.0))
    (move-light slot x y)))

(define (compute-shadow li sp ep)
  (let ([sc (light-sc li)])
    (when (< sc MAX-SHADOWS)
      (let* ([ext (* (light-radius li) 2.0)]
             [lp (light-pos li)]
             [sv (vec2-normalize (vec2-subtract sp lp))]
             [spj (vec2-add sp (vec2-scale sv ext))]
             [ev (vec2-normalize (vec2-subtract ep lp))]
             [epj (vec2-add ep (vec2-scale ev ext))]
             [s (vector-ref (light-sgs li) sc)])
        (sg-set! s 0 sp)(sg-set! s 1 ep)
        (sg-set! s 2 epj)(sg-set! s 3 spj)
        (set-light-sc! li (+ sc 1))))))

(define (update-light slot boxes n)
  (let ([li (vector-ref lights slot)])
    (if (and (light-active li)(light-dirty li))
      (let/ec return
        (set-light-dirty! li #f)
        (set-light-sc! li 0)
        (for ([i (in-range n)])
          (let ([b (vector-ref boxes i)])
            (when (check-collision-point-rec (light-pos li) b)
              (return #f))
            (when (check-collision-recs (light-bounds li) b)
              (let* ([bx (rx b)][by (ry b)][bw (rw b)][bh (rh b)]
                     [lpx (vx (light-pos li))][lpy (vy (light-pos li))])
                (let ([sp (v2 bx by)][ep (v2 (+ bx bw) by)])
                  (when (> lpy (vy ep))(compute-shadow li sp ep)))
                (let ([sp (v2 (+ bx bw) by)][ep (v2 (+ bx bw)(+ by bh))])
                  (when (< lpx (vx ep))(compute-shadow li sp ep)))
                (let ([sp (v2 (+ bx bw)(+ by bh))][ep (v2 bx (+ by bh))])
                  (when (< lpy (vy ep))(compute-shadow li sp ep)))
                (let ([sp (v2 bx (+ by bh))][ep (v2 bx by)])
                  (when (> lpx (vx ep))(compute-shadow li sp ep)))
                (let ([sc (light-sc li)])
                  (when (< sc MAX-SHADOWS)
                    (let ([s (vector-ref (light-sgs li) sc)])
                      (sg-set! s 0 (v2 bx by))(sg-set! s 1 (v2 bx (+ by bh)))
                      (sg-set! s 2 (v2 (+ bx bw)(+ by bh)))(sg-set! s 3 (v2 (+ bx bw) by))
                      (set-light-sc! li (+ sc 1)))))))))
        #t)
      #f)))


;; ============================================================
;; 障碍物
;; ============================================================
(define boxes (make-vector MAX-BOXES (rectangle 0 0 0 0)))
(define (setup-boxes)
  (vector-set! boxes 0 (rectangle 150 80 40 40))
  (vector-set! boxes 1 (rectangle 1200 700 40 40))
  (vector-set! boxes 2 (rectangle 200 600 40 40))
  (vector-set! boxes 3 (rectangle 1000 50 40 40))
  (vector-set! boxes 4 (rectangle 500 350 40 40))
  (for ([i (in-range 5 MAX-BOXES)])
    (vector-set! boxes i
      (rectangle (exact->inexact (get-random-value 0 W))
                 (exact->inexact (get-random-value 0 H))
                 (exact->inexact (get-random-value 10 100))
                 (exact->inexact (get-random-value 10 100))))))

;; ============================================================
;; 绘制辅助
;; ============================================================
(define (draw-light-circle li)
  (draw-circle-gradient (light-pos li)(light-radius li)
                        WHITE (color-alpha WHITE 0.0)))

(define (draw-light-shadows li)
  (for ([j (in-range (light-sc li))])
    (let ([s (vector-ref (light-sgs li) j)])
      (draw-triangle-fan (vector (sg-ref s 0)(sg-ref s 1)(sg-ref s 2)(sg-ref s 3))
                         4 BLACK))))

(define (draw-light-dot li i)
  (draw-circle (exact-round (vx (light-pos li)))(exact-round (vy (light-pos li)))
               10.0 (if (= i 0) YELLOW WHITE)))

;; ============================================================
;; 初始化
;; ============================================================
(init-window W H "raylib [shapes] example - top down lights [FFI]")
(setup-boxes)

(define bg-img (gen-image-checked 64 64 32 32 DARKBROWN DARKGRAY))
(define bg-tex (load-texture-from-image bg-img))
(unload-image bg-img)

(define light-mask (load-render-texture W H))
(setup-light 0 600.0 400.0 300.0)
(define next-light 1)
(define show-lines? (box #f))
(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================
(let main ()
  (unless (window-should-close?)

    (when (is-mouse-button-down MOUSE-BUTTON-LEFT)
      (move-light 0 (vx (get-mouse-position))(vy (get-mouse-position))))
    (when (and (is-mouse-button-pressed MOUSE-BUTTON-RIGHT)(< next-light MAX-LIGHTS))
      (setup-light next-light (vx (get-mouse-position))(vy (get-mouse-position)) 200.0)
      (set! next-light (+ next-light 1)))
    (when (is-key-pressed KEY-F1)(set-box! show-lines?(not (unbox show-lines?))))

    (for ([i (in-range MAX-LIGHTS)])(update-light i boxes MAX-BOXES))

    ;; ── Step 1: 光罩 RT ──
    (begin-texture-mode light-mask)
    (clear-background BLACK)

    ;; ADDITIVE 累积光源
    (rl-set-blend-factors RLGL-SRC-ALPHA GL-ONE GL-FUNC-ADD)
    (rl-set-blend-mode BLEND-CUSTOM)
    (for ([i (in-range MAX-LIGHTS)])
      (let ([li (vector-ref lights i)])
        (when (light-active li)(draw-light-circle li))))
    (rl-draw-render-batch-active)
    (rl-set-blend-mode BLEND-ALPHA)

    ;; 正常 blend 画黑色阴影
    (for ([i (in-range MAX-LIGHTS)])
      (let ([li (vector-ref lights i)])
        (when (light-active li)(draw-light-shadows li))))
    (end-texture-mode)

    ;; ── Step 2: 绘制到屏幕 ──
    (begin-drawing)
    (clear-background BLACK)

    ;; 棋盘格背景
    (draw-texture-pro bg-tex (rectangle 0 0 64 64)
      (rectangle 0 0 (exact->inexact W)(exact->inexact H))(v2 0 0) 0.0 WHITE)

    ;; MULTIPLY 叠加光罩: dst * src
    (rl-set-blend-factors GL-DST-COLOR GL-ZERO GL-FUNC-ADD)
    (rl-set-blend-mode BLEND-CUSTOM)
    (draw-texture-rec
      (list (list-ref light-mask 1)(list-ref light-mask 2)
            (list-ref light-mask 3)(list-ref light-mask 4)(list-ref light-mask 5))
      (rectangle 0 0 (exact->inexact W)(exact->inexact (- H)))(v2 0 0) WHITE)
    (rl-draw-render-batch-active)
    (rl-set-blend-mode BLEND-ALPHA)

    ;; 光源指示点
    (for ([i (in-range MAX-LIGHTS)])
      (let ([li (vector-ref lights i)])
        (when (light-active li)(draw-light-dot li i))))

    ;; F1 调试
    (if (unbox show-lines?)
      (begin
        (for ([s (in-range (light-sc (vector-ref lights 0)))])
          (let* ([sg (vector-ref (light-sgs (vector-ref lights 0)) s)]
                 [pts (vector (sg-ref sg 0)(sg-ref sg 1)(sg-ref sg 2)(sg-ref sg 3))])
            (draw-triangle-fan pts 4 DARKPURPLE)))
        (for ([b (in-range MAX-BOXES)])
          (draw-rectangle-lines (exact-round (rx (vector-ref boxes b)))
            (exact-round (ry (vector-ref boxes b)))
            (exact-round (rw (vector-ref boxes b)))
            (exact-round (rh (vector-ref boxes b))) DARKBLUE))
        (draw-text "(F1) Hide" 10 50 10 GREEN))
      (draw-text "(F1) Show" 10 50 10 GREEN))

    (draw-fps (- W 80) 10)
    (draw-text "Drag=move, Right-click=add" 10 10 10 DARKGREEN)
    (end-drawing)
    (main)))

;; ============================================================
;; 清理
;; ============================================================
(unload-texture bg-tex)
(unload-render-texture light-mask)
(close-window)
