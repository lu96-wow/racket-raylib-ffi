#lang racket/base

;; raylib [textures] example - cellular automata (Racket FFI 翻译)
;; 对应 C: examples/textures/textures_cellular_automata.c
;; 演示: 一维元胞自动机 (Wolfram rules)

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe
         (prefix-in T: "../../raylib/types.rkt"))

;; Image list ↔ C Image* 指针转换

(define (image-ptr->list ptr)
  (list (ptr-ref ptr _pointer 0)
        (ptr-ref ptr _int 2)
        (ptr-ref ptr _int 3)
        (ptr-ref ptr _int 4)
        (ptr-ref ptr _int 5)))

;; 常量
(define screen-width 800)
(define screen-height 450)
(define image-width 800)
(define image-height 400)
(define draw-rule-start-x 585)
(define draw-rule-start-y 10)
(define draw-rule-spacing 15)
(define draw-rule-group-spacing 50)
(define draw-rule-size 14)
(define draw-rule-inner-size 10)
(define presets-size-x 42)
(define presets-size-y 22)
(define lines-per-frame 4)

;; ComputeLine: 用规则计算下一行像素
(define (compute-line img-ptr img-list line rule)
  (for ([i (in-range 1 (sub1 image-width))])
    (define prev-value
      (+ (if (< (car (get-image-color img-list (sub1 i) (sub1 line))) 5) 4 0)
         (if (< (car (get-image-color img-list i       (sub1 line))) 5) 2 0)
         (if (< (car (get-image-color img-list (add1 i) (sub1 line))) 5) 1 0)))
    (image-draw-pixel img-ptr i line
                      (if (bitwise-bit-set? rule prev-value) BLACK RAYWHITE))))


;; ============================================================
;; 初始化
;; ============================================================
(init-window screen-width screen-height
             "raylib [textures] example - cellular automata")

(define image-list (gen-image-color image-width image-height RAYWHITE))
(define image-ptr (image-list->ptr image-list))
(image-draw-pixel image-ptr (quotient image-width 2) 0 BLACK)
(define texture (load-texture-from-image (image-ptr->list image-ptr)))

(define preset-values '(18 30 60 86 102 124 126 150 182 225))
(define presets-count (length preset-values))
(define rule 30)
(define line 1)
(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================
(let loop ()
  (unless (window-should-close?)
    (let* ([mouse (get-mouse-position)]
           [mx (vector2-x mouse)] [my (vector2-y mouse)]
           [mouse-in-cell -1])

      ;; 检测鼠标在哪个规则位上
      (let mloop ([i 0])
        (when (and (< i 8) (< mouse-in-cell 0))
          (let* ([cx (+ draw-rule-start-x draw-rule-spacing
                       (- (* draw-rule-group-spacing i)))]
                 [cy (+ draw-rule-start-y draw-rule-spacing)])
            (when (and (>= mx cx) (<= mx (+ cx draw-rule-size))
                       (>= my cy) (<= my (+ cy draw-rule-size)))
              (set! mouse-in-cell i))
            (mloop (+ i 1)))))

      ;; 检测鼠标在哪个预设按钮上
      (when (< mouse-in-cell 0)
        (let mloop ([i 0])
          (when (and (< i presets-count) (< mouse-in-cell 0))
            (let* ([cx (+ 4 (* (+ presets-size-x 2) (quotient i 2)))]
                   [cy (+ 2 (* (+ presets-size-y 2) (modulo i 2)))])
              (when (and (>= mx cx) (<= mx (+ cx presets-size-x))
                         (>= my cy) (<= my (+ cy presets-size-y)))
                (set! mouse-in-cell (+ i 8)))
              (mloop (+ i 1))))))

      ;; 点击切换规则 / 选预设
      (when (and (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
                 (>= mouse-in-cell 0))
        (set! rule
              (if (< mouse-in-cell 8)
                  (bitwise-xor rule (arithmetic-shift 1 mouse-in-cell))
                  (list-ref preset-values (- mouse-in-cell 8))))
        (image-clear-background image-ptr RAYWHITE)
        (image-draw-pixel image-ptr (quotient image-width 2) 0 BLACK)
        (set! line 1))

      ;; 逐帧计算若干行
      (when (< line image-height)
        (let ([cur-list (image-ptr->list image-ptr)])
          (for ([li (in-range line (min (+ line lines-per-frame) image-height))])
            (compute-line image-ptr cur-list li rule))
          (set! line (+ line lines-per-frame))
          (update-texture texture (list-ref (image-ptr->list image-ptr) 0))))

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)
      (draw-texture texture 0 (- screen-height image-height) WHITE)

      ;; 预设按钮
      (for ([i (in-range presets-count)])
        (let ([px (+ 4 (* (+ presets-size-x 2) (quotient i 2)))]
              [py (+ 2 (* (+ presets-size-y 2) (modulo i 2)))])
          (draw-text (format "~a" (list-ref preset-values i))
                     (+ 8 (* (+ presets-size-x 2) (quotient i 2)))
                     (+ 4 (* (+ presets-size-y 2) (modulo i 2))) 20 GRAY)
          (draw-rectangle-lines px py presets-size-x presets-size-y BLUE)
          (when (= mouse-in-cell (+ i 8))
            (draw-rectangle-lines-ex
             (rectangle (+ 2 (* (+ presets-size-x 2) (quotient i 2)))
                        (* (+ presets-size-y 2) (modulo i 2))
                        (+ presets-size-x 4.0) (+ presets-size-y 4.0))
             3.0 RED))))

      ;; 规则位
      (for ([i (in-range 8)])
        (for ([j (in-range 3)])
          (let ([x (+ draw-rule-start-x (- (* draw-rule-group-spacing i))
                      (* draw-rule-spacing j))]
                [y draw-rule-start-y])
            (draw-rectangle-lines x y draw-rule-size draw-rule-size GRAY)
            (when (bitwise-bit-set? i (list-ref '(2 1 0) j))
              (draw-rectangle (+ x 2) (+ y 2)
                              draw-rule-inner-size draw-rule-inner-size BLACK))))
        (let* ([x (+ draw-rule-start-x draw-rule-spacing
                     (- (* draw-rule-group-spacing i)))]
               [y (+ draw-rule-start-y draw-rule-spacing)])
          (draw-rectangle-lines x y draw-rule-size draw-rule-size BLUE)
          (when (bitwise-bit-set? rule i)
            (draw-rectangle (+ x 2) (+ y 2)
                            draw-rule-inner-size draw-rule-inner-size BLACK))
          (when (= mouse-in-cell i)
            (draw-rectangle-lines-ex
             (rectangle (- x 2.0) (- y 2.0)
                        (+ draw-rule-size 4.0) (+ draw-rule-size 4.0))
             3.0 RED))))

      (draw-text (format "RULE: ~a" rule)
                 (+ draw-rule-start-x (* draw-rule-spacing 4))
                 (+ draw-rule-start-y 1) 30 GRAY)

      (end-drawing)
      (loop))))

(unload-image (image-ptr->list image-ptr))
(unload-texture texture)
(close-window)
