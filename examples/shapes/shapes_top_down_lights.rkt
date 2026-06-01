#lang racket/base

;; raylib [shapes] example - top down lights (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_top_down_lights.c
;;
;; 与 C 版的区别:
;;   C 版: 每光源独立 mask → draw-texture-rec 合并到 global mask
;;   Racket: 每帧直接画 shapes (circle + triangles) 到 global mask
;;   原因是 draw-texture-rec + CUSTOM blend + RenderTexture 组合
;;   在 FFI 下不稳定, 但 shapes + CUSTOM blend + RT 是正常的。

(require "../../raylib/raylib.rkt" racket/math)

(define MAX-BOXES 20) (define MAX-SHADOWS (* MAX-BOXES 3)) (define MAX-LIGHTS 16)
(define W 800) (define H 450)

;; 结构体
(struct sgeom (v0 v1 v2 v3) #:transparent #:mutable)
(define (sg-make) (sgeom (v2 0 0)(v2 0 0)(v2 0 0)(v2 0 0)))
(define (v2 x y) (vector2 x y))
(define (sg-set! s i v)
  (case i[(0)(set-sgeom-v0! s v)][(1)(set-sgeom-v1! s v)]
         [(2)(set-sgeom-v2! s v)][(3)(set-sgeom-v3! s v)]))
(define (sg-ref s i)
  (case i[(0)(sgeom-v0 s)][(1)(sgeom-v1 s)][(2)(sgeom-v2 s)][(3)(sgeom-v3 s)]))
(define (rx r) (rectangle-x r))(define (ry r)(rectangle-y r))
(define (rw r)(rectangle-w r))(define (rh r)(rectangle-h r))
(define vx vector2-x)(define vy vector2-y)

(struct light (active dirty pos radius bounds sgs sc) #:transparent #:mutable)
(define (mklight)
  (light #f #f (v2 0 0) 0.0 (rectangle 0 0 0 0)
         (for/vector([i MAX-SHADOWS])(sg-make)) 0))
(define lights (for/vector([i MAX-LIGHTS])(mklight)))

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

;; boxes
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

(init-window W H "raylib [shapes] example - top down lights")
(setup-boxes)
(define bg-img (gen-image-checked 64 64 32 32 DARKBROWN DARKGRAY))
(define bg-tex (load-texture-from-image bg-img))
(unload-image bg-img)
(define global-mask (load-render-texture W H))
(setup-light 0 600.0 400.0 300.0)
(define next-light 1)
(define show-lines? (box #f))
(set-target-fps 60)

(let main ()
  (unless (window-should-close?)
    ;; 控制
    (when (is-mouse-button-down MOUSE-BUTTON-LEFT)
      (move-light 0 (vx (get-mouse-position))(vy (get-mouse-position))))
    (when (and (is-mouse-button-pressed MOUSE-BUTTON-RIGHT)(< next-light MAX-LIGHTS))
      (setup-light next-light (vx (get-mouse-position))(vy (get-mouse-position)) 200.0)
      (set! next-light (+ next-light 1)))
    (when (is-key-pressed KEY-F1)(set-box! show-lines?(not (unbox show-lines?))))

    ;; 更新所有 dirty 光源
    (for ([i (in-range MAX-LIGHTS)])(update-light i boxes MAX-BOXES))

    ;; 每帧重建 global mask: 清 BLACK → 画所有光源
    (begin-texture-mode global-mask)
    (clear-background BLACK)
    (for ([i (in-range MAX-LIGHTS)])
      (let ([li (vector-ref lights i)])
        (when (light-active li)
          (rl-set-blend-factors RLGL-SRC-ALPHA RLGL-SRC-ALPHA RLGL-MIN)
          (rl-set-blend-mode BLEND-CUSTOM)
          (draw-circle-gradient (light-pos li)(light-radius li)
                                (color-alpha WHITE 0.0) WHITE)
          (rl-draw-render-batch-active)
          (rl-set-blend-mode BLEND-ALPHA)
          (rl-set-blend-factors RLGL-SRC-ALPHA RLGL-SRC-ALPHA RLGL-MAX)
          (rl-set-blend-mode BLEND-CUSTOM)
          (for ([j (in-range (light-sc li))])
            (let ([s (vector-ref (light-sgs li) j)])
              (draw-triangle-fan (vector (sg-ref s 0)(sg-ref s 1)(sg-ref s 2)(sg-ref s 3)) 4 BLACK)))
          (rl-draw-render-batch-active)
          (rl-set-blend-mode BLEND-ALPHA))))
    (end-texture-mode)

    ;; 绘制
    (begin-drawing)
    (clear-background BLACK)
    (draw-texture-pro bg-tex (rectangle 0 0 64 64)
      (rectangle 0 0 (exact->inexact W)(exact->inexact H))(v2 0 0) 0.0 WHITE)
    (draw-texture-rec
      (list (list-ref global-mask 1)(list-ref global-mask 2)
            (list-ref global-mask 3)(list-ref global-mask 4)(list-ref global-mask 5))
      (rectangle 0 0 (exact->inexact W)(exact->inexact (- H)))(v2 0 0) WHITE)
    (for ([i (in-range MAX-LIGHTS)])
      (let ([li (vector-ref lights i)])
        (when (light-active li)
          (draw-circle (exact-round (vx (light-pos li)))(exact-round (vy (light-pos li)))
                       10.0 (if (= i 0) YELLOW WHITE)))))
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

(unload-texture bg-tex)
(unload-render-texture global-mask)
(close-window)
