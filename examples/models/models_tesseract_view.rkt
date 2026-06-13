#lang racket/base

;; raylib [models] example - tesseract view (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_tesseract_view.c

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [models] example - tesseract view")

;; 定义 3D 相机 (up = Z)
(define camera (camera3d 4.0 4.0 4.0
                         0.0 0.0 0.0
                         0.0 0.0 1.0
                         50.0 CAMERA-PERSPECTIVE))

;; 超立方体 16 个顶点: (±1, ±1, ±1, ±1)
(define tesseract
  (list (vector  1  1  1  1) (vector  1  1  1 -1)
        (vector  1  1 -1  1) (vector  1  1 -1 -1)
        (vector  1 -1  1  1) (vector  1 -1  1 -1)
        (vector  1 -1 -1  1) (vector  1 -1 -1 -1)
        (vector -1  1  1  1) (vector -1  1  1 -1)
        (vector -1  1 -1  1) (vector -1  1 -1 -1)
        (vector -1 -1  1  1) (vector -1 -1  1 -1)
        (vector -1 -1 -1  1) (vector -1 -1 -1 -1)))

(define (vector4-x v) (vector-ref v 0))
(define (vector4-y v) (vector-ref v 1))
(define (vector4-z v) (vector-ref v 2))
(define (vector4-w v) (vector-ref v 3))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    (define rads (* (/ (* 4 (atan 1)) 180) 45.0 (get-time)))  ;; DEG2RAD * 45 * time

    ;; 旋转 XW 平面 + 投影 4D→3D
    (define-values (transformed w-values)
      (for/lists (t w)
                 ([p (in-list tesseract)])
        ;; XW 旋转 (Vector2Rotate)
        (define px (vector4-x p))
        (define pw (vector4-w p))
        (define rx (- (* px (cos rads)) (* pw (sin rads))))
        (define rw (+ (* px (sin rads)) (* pw (cos rads))))

        ;; 投影: 从 (0,0,0,3) 透视到 W=0 平面
        (define c (/ 3.0 (- 3.0 rw)))
        (values (vector3 (* c rx) (* c (vector4-y p)) (* c (vector4-z p)))
                rw)))

    ;; ---- Draw ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)

    (for ([i (in-range 16)])
      (define ti (list-ref transformed i))
      (define wi (list-ref w-values i))
      ;; 球体大小表示 W 值
      (draw-sphere ti (* (abs wi) 0.1) RED)

      ;; 连线：两顶点相差恰好 1 个坐标分量
      (for ([j (in-range 16)]
            #:when (< i j))
        (define v1 (list-ref tesseract i))
        (define v2 (list-ref tesseract j))
        (define diff (+ (if (= (vector4-x v1) (vector4-x v2)) 1 0)
                        (if (= (vector4-y v1) (vector4-y v2)) 1 0)
                        (if (= (vector4-z v1) (vector4-z v2)) 1 0)
                        (if (= (vector4-w v1) (vector4-w v2)) 1 0)))
        (when (= diff 3)
          (draw-line-3d ti (list-ref transformed j) MAROON))))

    (end-mode-3d)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
