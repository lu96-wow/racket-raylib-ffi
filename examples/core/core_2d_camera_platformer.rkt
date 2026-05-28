#lang racket/base

;; raylib [core] example - 2d camera platformer (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_2d_camera_platformer.c
;;
;; 演示 5 种 2D 相机跟随模式:
;;   0. Follow player center
;;   1. Follow player center, but clamp to map edges
;;   2. Follow player center; smoothed
;;   3. Follow player center horizontally; even out vertically after landing
;;   4. Player push camera on getting too close to screen edge
;;
;; 涉及新增绑定:
;;   get-world-to-screen-2d

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define G 400)
(define PLAYER-JUMP-SPD 350.0)
(define PLAYER-HOR-SPD 200.0)

;; ============================================================
;; 自定义结构体 (纯 Racket, 不涉及 FFI)
;; ============================================================

(struct player (position speed can-jump) #:transparent)
(struct env-item (rect blocking color) #:transparent)

;; ============================================================
;; 向量辅助 (替代 raymath.h)
;; ============================================================

(define (vector2-subtract v1 v2)
  (vector2 (- (vector2-x v1) (vector2-x v2))
           (- (vector2-y v1) (vector2-y v2))))

(define (vector2-length v)
  (sqrt (+ (* (vector2-x v) (vector2-x v))
           (* (vector2-y v) (vector2-y v)))))

(define (vector2-scale v s)
  (vector2 (* (vector2-x v) s) (* (vector2-y v) s)))

(define (vector2-add v1 v2)
  (vector2 (+ (vector2-x v1) (vector2-x v2))
           (+ (vector2-y v1) (vector2-y v2))))

(define (clamp v lo hi)
  (max lo (min hi v)))

;; ============================================================
;; 玩家更新 (UpdatePlayer)
;; ============================================================

(define (update-player p env-items delta)
  (define pos (player-position p))
  (define spd (player-speed p))
  (define can-jump? (player-can-jump p))

  ;; 水平输入
  (define new-x
    (let ([x (vector2-x pos)])
      (cond
        [(is-key-down KEY-LEFT)  (- x (* PLAYER-HOR-SPD delta))]
        [(is-key-down KEY-RIGHT) (+ x (* PLAYER-HOR-SPD delta))]
        [else x])))

  ;; 跳跃
  (define-values (jump-spd jump-can-jump?)
    (if (and (is-key-down KEY-SPACE) can-jump?)
        (values (- PLAYER-JUMP-SPD) #f)
        (values spd can-jump?)))

  ;; 碰撞检测 — 找第一个碰到的平台
  (define hit-y
    (for/first ([ei env-items]
                #:when (= (env-item-blocking ei) 1))
      (define rect (env-item-rect ei))
      (and (<= (rectangle-x rect) new-x)
           (>= (+ (rectangle-x rect) (rectangle-w rect)) new-x)
           (>= (rectangle-y rect) (vector2-y pos))
           (<= (rectangle-y rect) (+ (vector2-y pos) (* jump-spd delta)))
           (rectangle-y rect))))

  (if hit-y
      ;; 站在平台上
      (player (vector2 new-x hit-y) 0.0 #t)
      ;; 自由落体
      (player (vector2 new-x (+ (vector2-y pos) (* jump-spd delta)))
              (+ jump-spd (* G delta))
              #f)))


;; ============================================================
;; 相机更新函数 (各模式)
;; ============================================================

;; 模式 0: Follow player center
(define (update-camera-center camera player _env-items _delta width height)
  (set-camera2d-offset-x! camera (/ width 2.0))
  (set-camera2d-offset-y! camera (/ height 2.0))
  (define p-pos (player-position player))
  (set-camera2d-target-x! camera (vector2-x p-pos))
  (set-camera2d-target-y! camera (vector2-y p-pos)))

;; 模式 1: Follow player center, but clamp to map edges
(define (update-camera-center-inside-map camera player env-items _delta width height)
  (set-camera2d-target-x! camera (vector2-x (player-position player)))
  (set-camera2d-target-y! camera (vector2-y (player-position player)))
  (set-camera2d-offset-x! camera (/ width 2.0))
  (set-camera2d-offset-y! camera (/ height 2.0))

  ;; 计算地图边界
  (define-values (min-x min-y max-x max-y)
    (for/fold ([min-x 1000.0] [min-y 1000.0] [max-x -1000.0] [max-y -1000.0])
              ([ei env-items])
      (define rect (env-item-rect ei))
      (values (min (rectangle-x rect) min-x)
              (min (rectangle-y rect) min-y)
              (max (+ (rectangle-x rect) (rectangle-w rect)) max-x)
              (max (+ (rectangle-y rect) (rectangle-h rect)) max-y))))

  ;; 转换为屏幕坐标
  (define max-screen (get-world-to-screen-2d (vector2 max-x max-y) camera))
  (define min-screen (get-world-to-screen-2d (vector2 min-x min-y) camera))

  ;; 调整 offset 防止相机显示地图外区域
  (when (< (vector2-x max-screen) width)
    (set-camera2d-offset-x! camera (- width (- (vector2-x max-screen) (/ width 2.0)))))
  (when (< (vector2-y max-screen) height)
    (set-camera2d-offset-y! camera (- height (- (vector2-y max-screen) (/ height 2.0)))))
  (when (> (vector2-x min-screen) 0)
    (set-camera2d-offset-x! camera (- (/ width 2.0) (vector2-x min-screen))))
  (when (> (vector2-y min-screen) 0)
    (set-camera2d-offset-y! camera (- (/ height 2.0) (vector2-y min-screen)))))

;; 模式 2: Follow player center; smoothed
(define update-camera-center-smooth-follow
  (let ([min-speed 30]
        [min-effect-length 10]
        [fraction-speed 0.8])
    (λ (camera player _env-items delta width height)
      (set-camera2d-offset-x! camera (/ width 2.0))
      (set-camera2d-offset-y! camera (/ height 2.0))

      (define diff
        (vector2-subtract (player-position player)
                          (vector2 (camera2d-target-x camera) (camera2d-target-y camera))))
      (define len (vector2-length diff))

      (when (> len min-effect-length)
        (define speed (max (* fraction-speed len) min-speed))
        (define step (vector2-scale diff (/ (* speed delta) len)))
        (set-camera2d-target-x! camera (+ (camera2d-target-x camera) (vector2-x step)))
        (set-camera2d-target-y! camera (+ (camera2d-target-y camera) (vector2-y step)))))))



;; 模式 3: Follow player center horizontally; even out vertically after landing
(define update-camera-even-out-on-landing
  (let ([even-out-speed 700]
        [evening-out #f]
        [even-out-target 0.0])
    (λ (camera player _env-items delta width height)
      (set-camera2d-offset-x! camera (/ width 2.0))
      (set-camera2d-offset-y! camera (/ height 2.0))
      (set-camera2d-target-x! camera (vector2-x (player-position player)))

      (cond
        [evening-out
         (if (> even-out-target (camera2d-target-y camera))
             (begin
               (set-camera2d-target-y! camera
                                       (+ (camera2d-target-y camera) (* even-out-speed delta)))
               (when (> (camera2d-target-y camera) even-out-target)
                 (set-camera2d-target-y! camera even-out-target)
                 (set! evening-out #f)))
             (begin
               (set-camera2d-target-y! camera
                                       (- (camera2d-target-y camera) (* even-out-speed delta)))
               (when (< (camera2d-target-y camera) even-out-target)
                 (set-camera2d-target-y! camera even-out-target)
                 (set! evening-out #f))))]
        [else
         (when (and (player-can-jump player)
                    (= (player-speed player) 0)
                    (not (= (vector2-y (player-position player))
                            (camera2d-target-y camera))))
           (set! evening-out #t)
           (set! even-out-target (vector2-y (player-position player))))]))))



;; 模式 4: Player push camera on getting too close to screen edge
(define update-camera-player-bounds-push
  (let ([bbox (vector2 0.2 0.2)])
    (λ (camera player _env-items _delta width height)
      (define bbox-world-min
        (get-screen-to-world-2d
         (vector2 (* (- 1 (vector2-x bbox)) 0.5 width)
                  (* (- 1 (vector2-y bbox)) 0.5 height))
         camera))
      (define bbox-world-max
        (get-screen-to-world-2d
         (vector2 (* (+ 1 (vector2-x bbox)) 0.5 width)
                  (* (+ 1 (vector2-y bbox)) 0.5 height))
         camera))

      (set-camera2d-offset-x! camera (* (- 1 (vector2-x bbox)) 0.5 width))
      (set-camera2d-offset-y! camera (* (- 1 (vector2-y bbox)) 0.5 height))

      (when (< (vector2-x (player-position player)) (vector2-x bbox-world-min))
        (set-camera2d-target-x! camera (vector2-x (player-position player))))
      (when (< (vector2-y (player-position player)) (vector2-y bbox-world-min))
        (set-camera2d-target-y! camera (vector2-y (player-position player))))
      (when (> (vector2-x (player-position player)) (vector2-x bbox-world-max))
        (set-camera2d-target-x! camera
                                (+ (vector2-x bbox-world-min)
                                   (- (vector2-x (player-position player)) (vector2-x bbox-world-max)))))
      (when (> (vector2-y (player-position player)) (vector2-y bbox-world-max))
        (set-camera2d-target-y! camera
                                (+ (vector2-y bbox-world-min)
                                   (- (vector2-y (player-position player)) (vector2-y bbox-world-max))))))))



;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
             "raylib [core] example - 2d camera platformer")

(define pl
  (player (vector2 400 280) 0.0 #f))

(define env-items
  (list (env-item (rectangle 0 0 1000 400) 0 LIGHTGRAY)
        (env-item (rectangle 0 400 1000 200) 1 GRAY)
        (env-item (rectangle 300 200 400 10) 1 GRAY)
        (env-item (rectangle 250 300 100 10) 1 GRAY)
        (env-item (rectangle 650 300 100 10) 1 GRAY)))

;; Camera2D: target=(400,280), offset=(400,225), rotation=0, zoom=1
(define camera (camera2d 400 280 400 225 0.0 1.0))

(define camera-updaters
  (list update-camera-center
        update-camera-center-inside-map
        update-camera-center-smooth-follow
        update-camera-even-out-on-landing
        update-camera-player-bounds-push))

(define camera-descriptions
  (list "Follow player center"
        "Follow player center, but clamp to map edges"
        "Follow player center; smoothed"
        "Follow player center horizontally; update player center vertically after landing"
        "Player push camera on getting too close to screen edge"))

(define camera-option 0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (define delta (get-frame-time))

    ;; --- 更新玩家 ---
    (set! pl (update-player pl env-items delta))

    ;; --- 滚轮缩放 ---
    (define zoom (camera2d-zoom camera))
    (set-camera2d-zoom! camera
                        (clamp (+ zoom (* (get-mouse-wheel-move) 0.05)) 0.25 3.0))

    ;; --- R 键重置 ---
    (when (is-key-pressed KEY-R)
      (set-camera2d-zoom! camera 1.0)
      (set! pl (player (vector2 400 280) 0.0 #f)))

    ;; --- C 键切换相机模式 ---
    (when (is-key-pressed KEY-C)
      (set! camera-option (modulo (+ camera-option 1) (length camera-updaters))))

    ;; --- 调用当前相机更新 ---
    (define updater (list-ref camera-updaters camera-option))
    (updater camera pl env-items delta screen-width screen-height)

    ;; --- 绘制 ---
    (begin-drawing)
    (clear-background LIGHTGRAY)

    (begin-mode-2d camera)

    ;; 绘制环境
    (for ([ei env-items])
      (draw-rectangle-rec (env-item-rect ei) (env-item-color ei)))

    ;; 绘制玩家
    (define p-pos (player-position pl))
    (draw-rectangle-rec
     (rectangle (- (vector2-x p-pos) 20) (- (vector2-y p-pos) 40) 40.0 40.0)
     RED)
    (draw-circle-v p-pos 5.0 GOLD)

    (end-mode-2d)

    ;; 绘制说明 (屏幕坐标)
    (draw-text "Controls:" 20 20 10 BLACK)
    (draw-text "- Right/Left to move" 40 40 10 DARKGRAY)
    (draw-text "- Space to jump" 40 60 10 DARKGRAY)
    (draw-text "- Mouse Wheel to Zoom in-out" 40 80 10 DARKGRAY)
    (draw-text "- R to reset position + zoom" 40 100 10 DARKGRAY)
    (draw-text "- C to change camera mode" 40 120 10 DARKGRAY)
    (draw-text "Current camera mode:" 20 140 10 BLACK)
    (draw-text (list-ref camera-descriptions camera-option) 40 160 10 DARKGRAY)

    (end-drawing)

    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)


