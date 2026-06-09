#lang racket/base

;; raylib [shapes] example - recursive tree (Racket FFI 翻译)
;;
;; 逐行翻译 C: examples/shapes/shapes_recursive_tree.c
;; raygui 替代: 用 raylib 原生绘制 + 鼠标交互实现滑块/复选框

(require racket/math
         racket/match
         "../../raylib/raylib.rkt")

;; ============================================================
;; 滑块控件 (复用)
;; ============================================================
(define (make-slider x y w h vmin vmax init)
  (box (list x y w h vmin vmax init #f)))
(define SLIDER-HANDLE-W 12)
(define (update-slider sl)
  (match-define (list x y w h vmin vmax cur drag?) (unbox sl))
  (define mx (get-mouse-x)) (define my (get-mouse-y))
  (define md (is-mouse-button-down MOUSE-BUTTON-LEFT))
  (define mr (is-mouse-button-released MOUSE-BUTTON-LEFT))
  (define in? (and (>= mx (- x 2)) (<= mx (+ x w 2)) (>= my (- y 2)) (<= my (+ y h 2))))
  (define nd (cond [mr #f] [(and md in? (not drag?)) #t] [drag? (and md #t)] [else #f]))
  (define nv (if nd (exact-round (+ vmin (* (max 0.0 (min 1.0 (/ (- mx x) w))) (- vmax vmin)))) cur))
  (set-box! sl (list x y w h vmin vmax nv nd)))
(define (draw-slider sl)
  (match-define (list x y w h vmin vmax cur drag?) (unbox sl))
  (define rng (- vmax vmin))
  (define t (if (zero? rng) 0.0 (/ (- cur vmin) rng)))
  (define hx (+ x (exact-round (* w t))))
  (draw-rectangle x (+ y (quotient h 2) -2) w 4 (fade GRAY 0.3))
  (draw-rectangle (- hx (quotient SLIDER-HANDLE-W 2)) y SLIDER-HANDLE-W h
                  (if drag? MAROON (fade DARKGRAY 0.7)))
  (draw-text (number->string cur) (+ x w 8) (- (+ y (quotient h 2)) 5) 10 DARKGRAY))
(define (slider-val sl) (cadddr (cdddr (unbox sl))))
(define (draw-checkbox x y label checked?)
  (define sz 16) (define mx (get-mouse-x)) (define my (get-mouse-y))
  (define mc (is-mouse-button-pressed MOUSE-BUTTON-LEFT))
  (define nv (if (and mc (>= mx x) (<= mx (+ x sz 80)) (>= my y) (<= my (+ y sz)))
                 (not checked?) checked?))
  (draw-rectangle-lines x y sz sz DARKGRAY)
  (when nv (draw-rectangle (+ x 3) (+ y 3) (- sz 6) (- sz 6) MAROON))
  (draw-text label (+ x 22) (- (+ y (quotient sz 2)) 5) 10 DARKGRAY)
  nv)

;; ============================================================
;; 分支结构体 — 严格对应 C:
;;   typedef struct { Vector2 start; Vector2 end; float angle; float length; } Branch;
;; ============================================================
(struct branch (start end angle len) #:transparent)
(define MAX-BRANCHES 1030)

;; ============================================================
;; 初始化
;; ============================================================
(define W 800) (define H 450)
(init-window W H "raylib [shapes] example - recursive tree")

;; C: Vector2 start = { (screenWidth/2.0f) - 125.0f, (float)screenHeight };
(define root-start (vector2 (- (/ W 2.0) 125.0) H))

;; 滑块
(define sl-angle (make-slider 640 42 120 16 0   180 40))
(define sl-len   (make-slider 640 74 120 16 12  240 120))
(define sl-decay (make-slider 640 106 120 16 10  78  66))
(define sl-depth (make-slider 640 138 120 16 1   10  10))
(define sl-thick (make-slider 640 170 120 16 1   8   1))
(define bezier? #f)

(set-target-fps 60)

;; ============================================================
;; 分支生成 — 逐行翻译 C 算法
;;
;; C:
;;   float theta = angle*DEG2RAD;
;;   int maxBranches = (int)(powf(2, floorf(treeDepth)));
;;   Branch branches[1030] = { 0 };
;;   int count = 0;
;;
;;   Vector2 initialEnd = { start.x + length*sinf(0.0f),
;;                           start.y - length*cosf(0.0f) };
;;   branches[count++] = (Branch){start, initialEnd, 0.0f, length};
;;
;;   for (int i = 0; i < count; i++) {
;;       Branch b = branches[i];
;;       if (b.length < 2) continue;
;;       float nextLen = b.length * decay;
;;       if (count < maxBranches && nextLen >= 2) {
;;           Vector2 bs = b.end;
;;           float a1 = b.angle + theta, a2 = b.angle - theta;
;;           Vector2 e1 = { bs.x + nextLen*sinf(a1), bs.y - nextLen*cosf(a1) };
;;           Vector2 e2 = { bs.x + nextLen*sinf(a2), bs.y - nextLen*cosf(a2) };
;;           branches[count++] = { bs, e1, a1, nextLen };
;;           branches[count++] = { bs, e2, a2, nextLen };
;;       }
;;   }
;; ============================================================
(define (generate-branches theta max-branch decay len-start)
  ;; 可变数组
  (define arr (make-vector MAX-BRANCHES #f))

  ;; C: initialEnd = { start.x + length*sinf(0), start.y - length*cosf(0) }
  ;; sin(0)=0, cos(0)=1
  (define initial-end
    (vector2 (vector2-x root-start)
             (- (vector2-y root-start) len-start)))
  ;; C: branches[count++] = ...
  (vector-set! arr 0 (branch root-start initial-end 0.0 len-start))

  ;; C: for (int i = 0; i < count; i++)
  (let iter ([i 0] [count 1])
    (cond [(>= i count) (values arr count)]
          [else
           (define b (vector-ref arr i))
           (define bl (branch-len b))
           (cond [(< bl 2.0) (iter (add1 i) count)]
                 [else
                  (define next-len (* bl decay))
                  (if (and (< count max-branch) (>= next-len 2.0))
                      (let* ([bs (branch-end b)]
                             [bsx (vector2-x bs)] [bsy (vector2-y bs)]
                             [a1 (+ (branch-angle b) theta)]
                             [a2 (- (branch-angle b) theta)]
                             [e1 (vector2 (+ bsx (* next-len (sin a1)))
                                          (- bsy (* next-len (cos a1))))]
                             [e2 (vector2 (+ bsx (* next-len (sin a2)))
                                          (- bsy (* next-len (cos a2))))]
                             ;; C: branches[count++] = ...
                             [_ (vector-set! arr count (branch bs e1 a1 next-len))]
                             [_ (vector-set! arr (add1 count) (branch bs e2 a2 next-len))])
                        (iter (add1 i) (+ count 2)))
                      (iter (add1 i) count))])])))
;; ============================================================
;; 主循环
;; ============================================================
(let main-loop ()
  (unless (window-should-close?)
    ;; ---- 输入 ----
    (update-slider sl-angle)
    (update-slider sl-len)
    (update-slider sl-decay)
    (update-slider sl-depth)
    (update-slider sl-thick)

    (define angle-val (exact->inexact (slider-val sl-angle)))
    (define len-val   (exact->inexact (slider-val sl-len)))
    (define decay-val (/ (exact->inexact (slider-val sl-decay)) 100.0))
    (define depth-val (exact->inexact (slider-val sl-depth)))
    (define thick-val (exact->inexact (slider-val sl-thick)))

    ;; C: float theta = angle*DEG2RAD;
    (define theta-rad (* angle-val (/ pi 180.0)))
    ;; C: int maxBranches = (int)(powf(2, floorf(treeDepth)));
    (define max-branch (expt 2 (exact-floor depth-val)))

    ;; 生成
    (define-values (branch-arr branch-count)
      (generate-branches theta-rad max-branch decay-val len-val))

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; C: for (int i = 0; i < count; i++) { ... }
    (for ([i (in-range branch-count)])
      (define b (vector-ref branch-arr i))
      (when (and b (>= (branch-len b) 2.0))
        (if bezier?
            (draw-line-bezier (branch-start b) (branch-end b) thick-val RED)
            (draw-line-ex    (branch-start b) (branch-end b) thick-val RED))))

    ;; 面板
    (draw-line 580 0 580 (get-screen-height) (color 218 218 218))
    (draw-rectangle 580 0 (get-screen-width) (get-screen-height) (color 232 232 232))

    ;; 标签 + 滑块
    (draw-text "Angle" 590 42 10 DARKGRAY) (draw-slider sl-angle)
    (draw-text "Length" 590 74 10 DARKGRAY) (draw-slider sl-len)
    (draw-text "Decay" 590 106 10 DARKGRAY) (draw-slider sl-decay)
    (draw-text "Depth" 590 138 10 DARKGRAY) (draw-slider sl-depth)
    (draw-text "Thick" 590 170 10 DARKGRAY) (draw-slider sl-thick)
    (set! bezier? (draw-checkbox 590 200 "Bezier" bezier?))

    (draw-fps 10 10)
    (end-drawing)

    (main-loop)))

(close-window)
