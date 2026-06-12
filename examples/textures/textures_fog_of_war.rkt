#lang racket/base

;; raylib [textures] example - fog of war (Racket FFI 翻译)
;; 对应 C: examples/textures/textures_fog_of_war.c
;; 演示: 战争迷雾效果 (RenderTexture 平滑缩放)

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         ffi/unsafe)

(define-runtime-path resource-dir-path "../../../examples/textures/resources/")
(define resource-dir (path->string resource-dir-path))

(define screen-width 800)
(define screen-height 450)
(define MAP-TILE-SIZE 32)
(define PLAYER-SIZE 16)
(define PLAYER-TILE-VISIBILITY 2)
(define TEXTURE-WRAP-CLAMP 1)

(init-window screen-width screen-height "raylib [textures] example - fog of war")

;; 地图数据
(define tiles-x 25)
(define tiles-y 15)
(define tile-count (* tiles-x tiles-y))

(define tile-ids (mem-alloc tile-count))
(define tile-fog (mem-alloc tile-count))

;; 随机生成两种地块
(for ([i (in-range tile-count)])
  (ptr-set! tile-ids _ubyte i (get-random-value 0 1)))

;; 玩家位置 (像素坐标)
(define player-pos-x 180.0)
(define player-pos-y 130.0)

;; RenderTexture 用于战争迷雾 (每个瓦片 1 像素)
(define fog-of-war (load-render-texture tiles-x tiles-y))
(set-texture-filter (list (list-ref fog-of-war 1) (list-ref fog-of-war 2)
                          (list-ref fog-of-war 3) (list-ref fog-of-war 4)
                          (list-ref fog-of-war 5))
                    TEXTURE-FILTER-BILINEAR)
(set-texture-wrap (list (list-ref fog-of-war 1) (list-ref fog-of-war 2)
                         (list-ref fog-of-war 3) (list-ref fog-of-war 4)
                         (list-ref fog-of-war 5))
                  TEXTURE-WRAP-CLAMP)

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    ;; 更新 — 移动玩家
    (when (is-key-down KEY-RIGHT) (set! player-pos-x (+ player-pos-x 5)))
    (when (is-key-down KEY-LEFT)  (set! player-pos-x (- player-pos-x 5)))
    (when (is-key-down KEY-DOWN)  (set! player-pos-y (+ player-pos-y 5)))
    (when (is-key-down KEY-UP)    (set! player-pos-y (- player-pos-y 5)))

    ;; 边界限制
    (when (< player-pos-x 0) (set! player-pos-x 0))
    (when (> (+ player-pos-x PLAYER-SIZE) (* tiles-x MAP-TILE-SIZE))
      (set! player-pos-x (- (* tiles-x MAP-TILE-SIZE) PLAYER-SIZE)))
    (when (< player-pos-y 0) (set! player-pos-y 0))
    (when (> (+ player-pos-y PLAYER-SIZE) (* tiles-y MAP-TILE-SIZE))
      (set! player-pos-y (- (* tiles-y MAP-TILE-SIZE) PLAYER-SIZE)))

    ;; 之前的可见瓦片变半雾
    (for ([i (in-range tile-count)])
      (when (= (ptr-ref tile-fog _ubyte i) 1)
        (ptr-set! tile-fog _ubyte i 2)))

    ;; 计算玩家所在瓦片
    (define player-tile-x
      (inexact->exact (floor (/ (+ player-pos-x (/ MAP-TILE-SIZE 2.0)) MAP-TILE-SIZE))))
    (define player-tile-y
      (inexact->exact (floor (/ (+ player-pos-y (/ MAP-TILE-SIZE 2.0)) MAP-TILE-SIZE))))

    ;; 更新可见范围
    (for* ([y (in-range (- player-tile-y PLAYER-TILE-VISIBILITY)
                         (+ player-tile-y PLAYER-TILE-VISIBILITY))]
           [x (in-range (- player-tile-x PLAYER-TILE-VISIBILITY)
                         (+ player-tile-x PLAYER-TILE-VISIBILITY))])
      (when (and (>= x 0) (< x tiles-x) (>= y 0) (< y tiles-y))
        (ptr-set! tile-fog _ubyte (+ (* y tiles-x) x) 1)))

    ;; 渲染迷雾到 RenderTexture
    (begin-texture-mode fog-of-war)
    (clear-background BLANK)
    (for* ([y (in-range tiles-y)]
           [x (in-range tiles-x)])
      (let ([fog (ptr-ref tile-fog _ubyte (+ (* y tiles-x) x))])
        (cond [(= fog 0) (draw-rectangle x y 1 1 BLACK)]
              [(= fog 2) (draw-rectangle x y 1 1 (fade BLACK 0.8))])))
    (end-texture-mode)

    ;; 绘制
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 绘制地图
    (for* ([y (in-range tiles-y)]
           [x (in-range tiles-x)])
      (let* ([tid (ptr-ref tile-ids _ubyte (+ (* y tiles-x) x))]
             [color (if (= tid 0) BLUE (fade BLUE 0.9))])
        (draw-rectangle (* x MAP-TILE-SIZE) (* y MAP-TILE-SIZE)
                        MAP-TILE-SIZE MAP-TILE-SIZE color)
        (draw-rectangle-lines (* x MAP-TILE-SIZE) (* y MAP-TILE-SIZE)
                              MAP-TILE-SIZE MAP-TILE-SIZE (fade DARKBLUE 0.5))))

    ;; 绘制玩家
    (draw-rectangle-v (vector2 player-pos-x player-pos-y)
                      (vector2 PLAYER-SIZE PLAYER-SIZE) RED)

    ;; 绘制迷雾 (从 RenderTexture 缩放到全地图)
    (let ([tex (list (list-ref fog-of-war 1) (list-ref fog-of-war 2)
                     (list-ref fog-of-war 3) (list-ref fog-of-war 4)
                     (list-ref fog-of-war 5))])
      (draw-texture-pro tex
        (rectangle 0.0 0.0 tiles-x (- tiles-y))
        (rectangle 0.0 0.0 (* tiles-x MAP-TILE-SIZE) (* tiles-y MAP-TILE-SIZE))
        (vector2 0.0 0.0) 0.0 WHITE))

    (draw-text (format "Current tile: [~a,~a]" player-tile-x player-tile-y)
               10 10 20 RAYWHITE)
    (draw-text "ARROW KEYS to move" 10 (- screen-height 25) 20 RAYWHITE)

    (end-drawing)
    (loop)))

(mem-free tile-ids)
(mem-free tile-fog)
(unload-render-texture fog-of-war)
(close-window)
