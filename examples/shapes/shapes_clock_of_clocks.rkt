#lang racket/base

;; raylib [shapes] example - clock of clocks (Racket FFI 翻译)
;;
;; 对应 C: examples/shapes/shapes_clock_of_clocks.c
;; SPACE 切换 12/24 小时制
;;
;; 每个时间数字由 6×4=24 个小表盘组成, 每个表盘有两根指针(大针/小针),
;; 指针指向不同角度拼出 7 段数码管风格的阿拉伯数字, 指针之间有平滑过渡动画.


(require "../../raylib/raylib.rkt" racket/date racket/math)


;; ============================================================
;; 初始化
;; ============================================================

(define screen-w 800)
(define screen-h 450)

(set-config-flags FLAG-MSAA-4X-HINT)
(init-window screen-w screen-h
  "raylib [shapes] example - clock of clocks")
(set-target-fps 60)


;; ------------------------------------------------------------
;; custom color-lerp (raylib ColorLerp)
;; ------------------------------------------------------------

(define (color-lerp c1 c2 t)
  (define r (exact-round (+ (ptr-ref c1 _ubyte 0)
                            (* t (- (ptr-ref c2 _ubyte 0)
                                    (ptr-ref c1 _ubyte 0))))))
  (define g (exact-round (+ (ptr-ref c1 _ubyte 1)
                            (* t (- (ptr-ref c2 _ubyte 1)
                                    (ptr-ref c1 _ubyte 1))))))
  (define b (exact-round (+ (ptr-ref c1 _ubyte 2)
                            (* t (- (ptr-ref c2 _ubyte 2)
                                    (ptr-ref c1 _ubyte 2))))))
  (define a (exact-round (+ (ptr-ref c1 _ubyte 3)
                            (* t (- (ptr-ref c2 _ubyte 3)
                                    (ptr-ref c1 _ubyte 3))))))
  (color r g b a))

(define bg-color    (color-lerp DARKBLUE BLACK 0.75))
(define hands-color (color-lerp YELLOW RAYWHITE 0.25))


;; ------------------------------------------------------------
;; 布局常量
;; ------------------------------------------------------------

(define clock-face-size 24.0)
(define clock-spacing     8.0)
(define section-spacing  16.0)

;; 每个表盘有 24 个 cell (6 行 × 4 列), 共 6 位数字 (HHMMSS)
(define CELLS    24)
(define DIGITS    6)
(define TOTAL  (* DIGITS CELLS))   ;; 144


;; ------------------------------------------------------------
;; 数字笔画角度 (7 段式: TL/TR/BR/BL/HH/VV/ZZ)
;; ------------------------------------------------------------

(define (vx v) (ptr-ref v _float 0))
(define (vy v) (ptr-ref v _float 1))

(define TL (vector2   0.0  90.0))   ; 左上
(define TR (vector2  90.0 180.0))   ; 右上
(define BR (vector2 180.0 270.0))   ; 右下
(define BL (vector2   0.0 270.0))   ; 左下
(define HH (vector2   0.0 180.0))   ; 水平线
(define VV (vector2  90.0 270.0))   ; 垂直线
(define ZZ (vector2 135.0 135.0))   ; 占位 (不画)

;; 每个数字由 24 对 (大针角度, 小针角度) 组成
;; 排列: 6 行 × 4 列
(define digit-lines
  (vector
    ;; 0
    (vector TL HH HH TR   VV TL TR VV   VV VV VV VV
            VV VV VV VV   VV BL BR VV   BL HH HH BR)
    ;; 1
    (vector TL HH TR ZZ   BL TR VV ZZ   ZZ VV VV ZZ
            ZZ VV VV ZZ   TL BR BL TR   BL HH HH BR)
    ;; 2
    (vector TL HH HH TR   BL HH TR VV   TL HH BR VV
            VV TL HH BR   VV BL HH TR   BL HH HH BR)
    ;; 3
    (vector TL HH HH TR   BL HH TR VV   TL HH BR VV
            BL HH TR VV   TL HH BR VV   BL HH HH BR)
    ;; 4
    (vector TL TR TL TR   VV VV VV VV   VV BL BR VV
            BL HH TR VV   ZZ ZZ VV VV   ZZ ZZ BL BR)
    ;; 5
    (vector TL HH HH TR   VV TL HH BR   VV BL HH TR
            BL HH TR VV   TL HH BR VV   BL HH HH BR)
    ;; 6
    (vector TL HH HH TR   VV TL HH BR   VV BL HH TR
            VV TL TR VV   VV BL BR VV   BL HH HH BR)
    ;; 7
    (vector TL HH HH TR   BL HH TR VV   ZZ ZZ VV VV
            ZZ ZZ VV VV   ZZ ZZ VV VV   ZZ ZZ BL BR)
    ;; 8
    (vector TL HH HH TR   VV TL TR VV   VV BL BR VV
            VV TL TR VV   VV BL BR VV   BL HH HH BR)
    ;; 9
    (vector TL HH HH TR   VV TL TR VV   VV BL BR VV
            BL HH TR VV   TL HH BR VV   BL HH HH BR)))

;; ------------------------------------------------------------
;; 预提取所有笔画到扁平向量 (x/y 分量分开)
;; digit-ang-x[d*24 + c] = 数字 d 第 c 个 cell 的大针角度
;; digit-ang-y[d*24 + c] = 数字 d 第 c 个 cell 的小针角度
;; ------------------------------------------------------------

(define digit-ang-x (make-vector (* 10 CELLS) 0.0))
(define digit-ang-y (make-vector (* 10 CELLS) 0.0))

(for ([d (in-range 10)])
  (define segs (vector-ref digit-lines d))
  (for ([c (in-range CELLS)])
    (define idx (+ (* d CELLS) c))
    (vector-set! digit-ang-x idx (vx (vector-ref segs c)))
    (vector-set! digit-ang-y idx (vy (vector-ref segs c)))))


;; ------------------------------------------------------------
;; 动画状态 — 用向量存浮点数 (避免 per-frame malloc)
;; ------------------------------------------------------------

(define cur-x (make-vector TOTAL 0.0))
(define cur-y (make-vector TOTAL 0.0))
(define src-x (make-vector TOTAL 0.0))
(define src-y (make-vector TOTAL 0.0))
(define dst-x (make-vector TOTAL 0.0))
(define dst-y (make-vector TOTAL 0.0))

(define prev-seconds      (box -1))
(define hands-move-timer  (box 0.0))
(define hands-move-duration 0.5)
(define hour-mode         (box 24))


;; ------------------------------------------------------------
;; smoothstep 缓动
;; ------------------------------------------------------------

(define (smoothstep t)
  (* t t (- 3.0 (* 2.0 t))))


;; ============================================================
;; 主循环
;; ============================================================

(let main-loop ()

  (unless (window-should-close?)

    ;; ---- 更新 ----

    (define dt  (get-frame-time))
    (define now (current-date))
    (define s   (date-second now))
    (define m   (date-minute now))
    (define h   (date-hour now))
    (define hm  (unbox hour-mode))
    (define hd  (modulo h hm))

    ;; 6 位数字列表 (对应 HHMMSS)
    (define clock-digits
      (list (quotient hd 10) (modulo hd 10)
            (quotient m  10) (modulo m  10)
            (quotient s  10) (modulo s  10)))

    ;; ---- 秒数变化 → 触发动画 ----
    (when (not (= s (unbox prev-seconds)))
      (set-box! prev-seconds s)

      (for ([digit (in-range DIGITS)])
        (define d    (list-ref clock-digits digit))
        (define base (* d CELLS))
        (for ([cell (in-range CELLS)])
          (define idx (+ (* digit CELLS) cell))

          ;; 当前 → src
          (vector-set! src-x idx (vector-ref cur-x idx))
          (vector-set! src-y idx (vector-ref cur-y idx))

          ;; 目标 → dst
          (vector-set! dst-x idx (vector-ref digit-ang-x (+ base cell)))
          (vector-set! dst-y idx (vector-ref digit-ang-y (+ base cell)))

          ;; 12h 模式: 若小时十位是 0 则隐藏 (用 ZZ 占位)
          (when (and (= digit 0) (= hm 12) (= (list-ref clock-digits 0) 0))
            (vector-set! dst-x idx (vx ZZ))
            (vector-set! dst-y idx (vy ZZ)))

          ;; 最短旋转方向 (若 src > dst 则减 360 避免反向转)
          (when (> (vector-ref src-x idx) (vector-ref dst-x idx))
            (vector-set! src-x idx (- (vector-ref src-x idx) 360.0)))
          (when (> (vector-ref src-y idx) (vector-ref dst-y idx))
            (vector-set! src-y idx (- (vector-ref src-y idx) 360.0)))))

      ;; 重置动画计时器
      (set-box! hands-move-timer (- dt)))

    ;; ---- 插值动画 ----
    (define tm (unbox hands-move-timer))
    (when (< tm hands-move-duration)
      (set-box! hands-move-timer (clamp (+ dt tm) 0.0 hands-move-duration))
      (define t (smoothstep (/ (unbox hands-move-timer) hands-move-duration)))
      (for ([i (in-range TOTAL)])
        (vector-set! cur-x i (lerp (vector-ref src-x i) (vector-ref dst-x i) t))
        (vector-set! cur-y i (lerp (vector-ref src-y i) (vector-ref dst-y i) t))))

    ;; ---- 输入 ----
    (when (is-key-pressed KEY-SPACE)
      (set-box! hour-mode (- 36 hm)))  ;; 24↔12 toggle

    ;; ---- 绘制 ----
    (begin-drawing)
    (clear-background bg-color)

    (draw-text (format "~a-h mode, space to change" hm) 10 30 20 RAYWHITE)

    (let digit-loop ([digit 0] [x-offset 4.0])
      (when (< digit DIGITS)
        ;; 绘制 6×4 个小表盘
        (for ([row (in-range 6)])
          (for ([col (in-range 4)])
            (define cx (+ x-offset
                          (* col (+ clock-face-size clock-spacing))
                          (/ clock-face-size 2)))
            (define cy (+ 100
                          (* row (+ clock-face-size clock-spacing))
                          (/ clock-face-size 2)))

            ;; 表盘外圈
            (draw-ring (vector2 cx cy)
                       (- (/ clock-face-size 2) 2.0)
                       (/ clock-face-size 2)
                       0.0 360.0 24 DARKGRAY)

            (define idx (+ (* digit CELLS) (* row 4) col))

            ;; 大指针 (长度 = 半径+4px)
            (draw-rectangle-pro
              (rectangle cx cy (+ (/ clock-face-size 2) 4.0) 4.0)
              (vector2 2.0 2.0)
              (vector-ref cur-x idx)
              hands-color)

            ;; 小指针 (长度 = 半径+2px)
            (draw-rectangle-pro
              (rectangle cx cy (+ (/ clock-face-size 2) 2.0) 4.0)
              (vector2 2.0 2.0)
              (vector-ref cur-y idx)
              hands-color)))

        ;; 每两个数字之间画分隔圆点
        (define noff (+ x-offset (* 4 (+ clock-face-size clock-spacing))))
        (when (= (modulo digit 2) 1)
          (draw-ring (vector2 (+ noff 4.0) 160.0) 6.0 8.0 0.0 360.0 24 hands-color)
          (draw-ring (vector2 (+ noff 4.0) 225.0) 6.0 8.0 0.0 360.0 24 hands-color)
          (set! noff (+ noff section-spacing)))
        (digit-loop (add1 digit) noff)))

    (draw-fps 10 10)
    (end-drawing)

    (main-loop)))


;; ============================================================
;; 清理
;; ============================================================

(close-window)

