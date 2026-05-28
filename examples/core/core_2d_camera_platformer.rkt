#lang racket/base

;; raylib [core] example - 2d camera platformer (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_2d_camera_platformer.c
;;
;; 演示 5 种 2D 相机跟随模式:
;;   0. Follow player center          — 始终对准玩家中心
;;   1. Follow player center, but     — 对准玩家, 但不超出地图边界
;;      clamp to map edges
;;   2. Follow player center;         — 平滑跟随, 拉开距离后加速追上
;;      smoothed
;;   3. Follow player center horiz.   — 水平跟随, 落地后垂直对齐
;;      update vertical after landing
;;   4. Player push camera on getting — 玩家靠近屏幕边缘时推动相机
;;      too close to screen edge
;;
;; 注意: 本示例不使用额外 FFI 绑定, 所有 raymath.h 向量运算
;; 用纯 Racket 实现

(require "../../raylib/raylib.rkt"
         racket/unsafe/ops)

;; ============================================================
;; 常量
;; ============================================================

(define G 400.0)
(define PLAYER-JUMP-SPD 350.0)
(define PLAYER-HOR-SPD 200.0)

(define SCREEN-WIDTH 800)
(define SCREEN-HEIGHT 450)

;; ============================================================
;; 自定义数据结构 — 替代 C 的 struct Player / struct EnvItem
;;
;; Player:   (vector pos speed canJump)
;;             pos       — Vector2 指针 (通过 raylib-var 的 set-vector2-x! 等修改)
;;             speed     — 可变的 float (box)
;;             canJump   — 可变的 boolean (box)
;;
;; EnvItem:  (vector rect blocking color)
;;             rect      — Rectangle 指针
;;             blocking  — 整数 (0 或 1)
;;             color     — Color 指针
;; ============================================================

(define (make-player x y)
  (vector (vector2 x y)   ;; position
          (box 0.0)        ;; speed
          (box #f)))       ;; canJump

(define (player-pos p)        (vector-ref p 0))
(define (player-speed p)      (vector-ref p 1))
(define (player-canJump p)    (vector-ref p 2))
(define (set-player-speed! p v)   (set-box! (vector-ref p 1) v))
(define (set-player-canJump! p v) (set-box! (vector-ref p 2) v))

(define (make-env-item x y w h blocking color)
  (vector (rectangle x y w h)
          blocking
          color))

(define (env-item-rect ei)     (vector-ref ei 0))
(define (env-item-blocking ei) (vector-ref ei 1))
(define (env-item-color ei)    (vector-ref ei 2))

;; ============================================================
;; raymath.h 向量辅助 (纯 Racket 实现, 无额外 FFI)
;; ============================================================

(define (vec2-sub v1 v2)
  (vector2 (- (vector2-x v1) (vector2-x v2))
           (- (vector2-y v1) (vector2-y v2))))

(define (vec2-add v1 v2)
  (vector2 (+ (vector2-x v1) (vector2-x v2))
           (+ (vector2-y v1) (vector2-y v2))))

(define (vec2-scale v s)
  (vector2 (* (vector2-x v) s)
           (* (vector2-y v) s)))

(define (vec2-length v)
  (let ([x (vector2-x v)]
        [y (vector2-y v)])
    (sqrt (+ (* x x) (* y y)))))

;; fmaxf / fminf 的 Racket 替代
(define (fmax a b) (if (>= a b) a b))
(define (fmin a b) (if (<= a b) a b))

;; ============================================================
;; UpdatePlayer — 玩家移动 / 重力 / 碰撞
;; ============================================================

(define (update-player player env-items delta)
  (define pos (player-pos player))

  ;; 水平移动
  (when (is-key-down KEY-LEFT)
    (set-vector2-x! pos (- (vector2-x pos) (* PLAYER-HOR-SPD delta))))
  (when (is-key-down KEY-RIGHT)
    (set-vector2-x! pos (+ (vector2-x pos) (* PLAYER-HOR-SPD delta))))

  ;; 跳跃
  (when (and (is-key-down KEY-SPACE) (unbox (player-canJump player)))
    (set-player-speed! player (- PLAYER-JUMP-SPD))
    (set-player-canJump! player #f))

  ;; 碰撞检测 + 垂直移动
  (let loop ([i 0] [hit-obstacle #f])
    (cond
      [(< i (vector-length env-items))
       (define ei (vector-ref env-items i))
       (define rect (env-item-rect ei))
       (define blocking (env-item-blocking ei))
       (define px (vector2-x pos))
       (define py (vector2-y pos))
       (define spd (unbox (player-speed player)))
       (if (and (= blocking 1)
                (<= (rectangle-x rect) px)
                (>= (+ (rectangle-x rect) (rectangle-w rect)) px)
                (>= (rectangle-y rect) py)
                (<= (rectangle-y rect) (+ py (* spd delta))))
           (begin
             (set-player-speed! player 0.0)
             (set-vector2-y! pos (rectangle-y rect))
             (loop (+ i 1) #t))
           (loop (+ i 1) hit-obstacle))]
      [else
       (if hit-obstacle
           (set-player-canJump! player #t)
           (begin
             (set-vector2-y! pos (+ (vector2-y pos) (* (unbox (player-speed player)) delta)))
             (set-player-speed! player (+ (unbox (player-speed player)) (* G delta)))
             (set-player-canJump! player #f)))])))

;; ============================================================
;; 5 种相机跟随模式
;; ============================================================

;; 模式 0: 始终对准玩家中心
(define (update-camera-center camera player env-items delta width height)
  (set-camera2d-offset-x! camera (/ width 2.0))
  (set-camera2d-offset-y! camera (/ height 2.0))
  (set-camera2d-target-x! camera (vector2-x (player-pos player)))
  (set-camera2d-target-y! camera (vector2-y (player-pos player))))

;; 模式 1: 对准玩家, 但不超出地图边缘
(define (update-camera-center-inside-map camera player env-items delta width height)
  (set-camera2d-target-x! camera (vector2-x (player-pos player)))
  (set-camera2d-target-y! camera (vector2-y (player-pos player)))
  (set-camera2d-offset-x! camera (/ width 2.0))
  (set-camera2d-offset-y! camera (/ height 2.0))

  ;; 计算地图边界
  (let loop ([i 0] [min-x 1000.0] [min-y 1000.0] [max-x -1000.0] [max-y -1000.0])
    (if (< i (vector-length env-items))
        (let* ([ei (vector-ref env-items i)]
               [rect (env-item-rect ei)]
               [rx (rectangle-x rect)]
               [ry (rectangle-y rect)]
               [rw (rectangle-w rect)]
               [rh (rectangle-h rect)])
          (loop (+ i 1)
                (fmin rx min-x)
                (fmin ry min-y)
                (fmax (+ rx rw) max-x)
                (fmax (+ ry rh) max-y)))
        ;; 将地图角点转换为屏幕坐标
        (let* ([max (get-world-to-screen-2d (vector2 max-x max-y) camera)]
               [min (get-world-to-screen-2d (vector2 min-x min-y) camera)]
               [w (exact->inexact width)]
               [h (exact->inexact height)])
          (when (< (vector2-x max) w)
            (set-camera2d-offset-x! camera (- w (- (vector2-x max) (/ w 2.0)))))
          (when (< (vector2-y max) h)
            (set-camera2d-offset-y! camera (- h (- (vector2-y max) (/ h 2.0)))))
          (when (> (vector2-x min) 0)
            (set-camera2d-offset-x! camera (- (/ w 2.0) (vector2-x min))))
          (when (> (vector2-y min) 0)
            (set-camera2d-offset-y! camera (- (/ h 2.0) (vector2-y min))))))))


;; 模式 2: 平滑跟随 — 距离越远速度越快
(define update-camera-center-smooth-follow
  (let ([min-speed 30.0]
        [min-effect-length 10.0]
        [fraction-speed 0.8])
    (λ (camera player env-items delta width height)
      (set-camera2d-offset-x! camera (/ width 2.0))
      (set-camera2d-offset-y! camera (/ height 2.0))
      (define diff (vec2-sub (player-pos player)
                             (vector2 (camera2d-target-x camera)
                                      (camera2d-target-y camera))))
      (define len (vec2-length diff))
      (when (> len min-effect-length)
        (define speed (fmax (* fraction-speed len) min-speed))
        (define scaled-diff (vec2-scale diff (/ (* speed delta) len)))
        (define new-target (vec2-add (vector2 (camera2d-target-x camera)
                                              (camera2d-target-y camera))
                                     scaled-diff))
        (set-camera2d-target-x! camera (vector2-x new-target))
        (set-camera2d-target-y! camera (vector2-y new-target))))))

;; 模式 3: 水平跟随, 落地后垂直对齐
(define update-camera-even-out-on-landing
  (let ([even-out-speed 700.0]
        [evening-out #f]
        [even-out-target 0.0])
    (λ (camera player env-items delta width height)
      (set-camera2d-offset-x! camera (/ width 2.0))
      (set-camera2d-offset-y! camera (/ height 2.0))
      (set-camera2d-target-x! camera (vector2-x (player-pos player)))

      (if evening-out
          (if (> even-out-target (camera2d-target-y camera))
              (let ([new-y (+ (camera2d-target-y camera) (* even-out-speed delta))])
                (if (> new-y even-out-target)
                    (begin
                      (set-camera2d-target-y! camera even-out-target)
                      (set! evening-out #f))
                    (set-camera2d-target-y! camera new-y)))
              (let ([new-y (- (camera2d-target-y camera) (* even-out-speed delta))])
                (if (< new-y even-out-target)
                    (begin
                      (set-camera2d-target-y! camera even-out-target)
                      (set! evening-out #f))
                    (set-camera2d-target-y! camera new-y))))
          ;; 检测玩家是否刚落地
          (when (and (unbox (player-canJump player))
                     (= (unbox (player-speed player)) 0.0)
                     (not (= (vector2-y (player-pos player))
                             (camera2d-target-y camera))))
            (set! evening-out #t)
            (set! even-out-target (vector2-y (player-pos player))))))))



;; 模式 4: 玩家靠近屏幕边缘时推动相机
(define update-camera-player-bounds-push
  (let ([bbox-x 0.2]
        [bbox-y 0.2])
    (λ (camera player env-items delta width height)
      (define w (exact->inexact width))
      (define h (exact->inexact height))

      ;; 计算屏幕边界对应的世界坐标
      (define bbox-world-min
        (get-screen-to-world-2d
          (vector2 (* (- 1 bbox-x) 0.5 w)
                   (* (- 1 bbox-y) 0.5 h))
          camera))
      (define bbox-world-max
        (get-screen-to-world-2d
          (vector2 (* (+ 1 bbox-x) 0.5 w)
                   (* (+ 1 bbox-y) 0.5 h))
          camera))

      ;; offset 与 bbox 左上角对齐
      (set-camera2d-offset-x! camera (* (- 1 bbox-x) 0.5 w))
      (set-camera2d-offset-y! camera (* (- 1 bbox-y) 0.5 h))

      (define px (vector2-x (player-pos player)))
      (define py (vector2-y (player-pos player)))
      (when (< px (vector2-x bbox-world-min))
        (set-camera2d-target-x! camera px))
      (when (< py (vector2-y bbox-world-min))
        (set-camera2d-target-y! camera py))
      (when (> px (vector2-x bbox-world-max))
        (set-camera2d-target-x! camera
          (+ (vector2-x bbox-world-min) (- px (vector2-x bbox-world-max)))))
      (when (> py (vector2-y bbox-world-max))
        (set-camera2d-target-y! camera
          (+ (vector2-y bbox-world-min) (- py (vector2-y bbox-world-max))))))))



;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - 2d camera platformer")

;; 玩家
(define player (make-player 400.0 280.0))

;; 环境物品 (平台/地面)
(define env-items (vector
  (make-env-item 0   0   1000 400 0 LIGHTGRAY)   ;; 背景墙 (非阻挡)
  (make-env-item 0   400 1000 200 1 GRAY)         ;; 地面
  (make-env-item 300 200 400  10  1 GRAY)         ;; 平台 1
  (make-env-item 250 300 100  10  1 GRAY)         ;; 平台 2
  (make-env-item 650 300 100  10  1 GRAY)))       ;; 平台 3

;; 相机
(define camera
  (camera2d
    (vector2-x (player-pos player))   ;; target-x
    (vector2-y (player-pos player))   ;; target-y
    (/ SCREEN-WIDTH 2.0)              ;; offset-x
    (/ SCREEN-HEIGHT 2.0)             ;; offset-y
    0.0                               ;; rotation
    1.0))                             ;; zoom

;; 相机模式列表
(define camera-updaters
  (vector
    update-camera-center
    update-camera-center-inside-map
    update-camera-center-smooth-follow
    update-camera-even-out-on-landing
    update-camera-player-bounds-push))

(define camera-descriptions
  (vector
    "Follow player center"
    "Follow player center, but clamp to map edges"
    "Follow player center; smoothed"
    "Follow player center horizontally; update player center vertically after landing"
    "Player push camera on getting too close to screen edge"))

(define camera-option 0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let game-loop ()
  (unless (window-should-close?)
    ;; --- 更新 ---

    (define delta (get-frame-time))

    ;; 更新玩家
    (update-player player env-items delta)

    ;; 缩放
    (let ([zoom (+ (camera2d-zoom camera) (* (get-mouse-wheel-move) 0.05))])
      (set-camera2d-zoom! camera (fmin 3.0 (fmax 0.25 zoom))))

    ;; 重置位置 + 缩放
    (when (is-key-pressed KEY-R)
      (set-camera2d-zoom! camera 1.0)
      (set-vector2-x! (player-pos player) 400.0)
      (set-vector2-y! (player-pos player) 280.0)
      (set-player-speed! player 0.0)
      (set-player-canJump! player #f))

    ;; 切换相机模式
    (when (is-key-pressed KEY-C)
      (set! camera-option (modulo (+ camera-option 1) (vector-length camera-updaters))))

    ;; 调用当前相机更新函数
    (define updater (vector-ref camera-updaters camera-option))
    (updater camera player env-items delta SCREEN-WIDTH SCREEN-HEIGHT)

    ;; --- 绘制 ---
    (begin-drawing)
    (clear-background LIGHTGRAY)

    (begin-mode-2d camera)

    ;; 绘制环境
    (for ([i (in-range (vector-length env-items))])
      (define ei (vector-ref env-items i))
      (draw-rectangle-rec (env-item-rect ei) (env-item-color ei)))

    ;; 绘制玩家 (40x40 矩形, 红色, 原点在底部中心)
    (define px (vector2-x (player-pos player)))
    (define py (vector2-y (player-pos player)))
    (draw-rectangle-rec (rectangle (- px 20) (- py 40) 40.0 40.0) RED)

    ;; 玩家中心点 (金色圆点)
    (draw-circle-v (player-pos player) 5.0 GOLD)

    (end-mode-2d)

    ;; UI 文字
    (draw-text "Controls:" 20 20 10 BLACK)
    (draw-text "- Right/Left to move" 40 40 10 DARKGRAY)
    (draw-text "- Space to jump" 40 60 10 DARKGRAY)
    (draw-text "- Mouse Wheel to Zoom in-out" 40 80 10 DARKGRAY)
    (draw-text "- R to reset position + zoom" 40 100 10 DARKGRAY)
    (draw-text "- C to change camera mode" 40 120 10 DARKGRAY)
    (draw-text "Current camera mode:" 20 140 10 BLACK)
    (draw-text (vector-ref camera-descriptions camera-option)
               40 160 10 DARKGRAY)

    (end-drawing)

    (game-loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)


