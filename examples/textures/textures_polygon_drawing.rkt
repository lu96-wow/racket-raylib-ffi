#lang racket/base

;; raylib [textures] example - polygon drawing (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_polygon_drawing.c
;;
;; 演示: 使用 rlgl 即时模式 API 绘制带纹理的多边形
;;   通过 triangle fan 将一个纹理映射到旋转的多边形上

(require "../../raylib/raylib.rkt"
         ffi/unsafe)

;; ============================================================
;; 资源路径
;; ============================================================

(define resource-dir
  (path->string (build-path (current-directory) "../../../examples/textures/resources/")))

;; ============================================================
;; 常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define max-points 11)  ;; 10 点 + 回到起点

;; ============================================================
;; DrawTexturePoly — 绘制带纹理的多边形（triangle fan）
;; ============================================================

(define (draw-texture-poly texture center-x center-y
                           points-x points-y texcoords-x texcoords-y
                           point-count tint)
  ;; 获取纹理 ID (Texture2D 是 list: id width height mipmaps format)
  (rl-set-texture (list-ref texture 0))

  (rl-begin RL-TRIANGLES)

  ;; 设置顶点颜色
  (rl-color-4ub (ptr-ref tint _ubyte 0) (ptr-ref tint _ubyte 1)
                (ptr-ref tint _ubyte 2) (ptr-ref tint _ubyte 3))

  ;; Triangle fan: 每个三角形由 (center, point[i], point[i+1]) 组成
  (for ([i (in-range (- point-count 1))])
    ;; 中心顶点
    (rl-tex-coord-2f 0.5 0.5)
    (rl-vertex-2f center-x center-y)

    ;; 顶点 i
    (rl-tex-coord-2f (vector-ref texcoords-x i) (vector-ref texcoords-y i))
    (rl-vertex-2f (+ (vector-ref points-x i) center-x)
                  (+ (vector-ref points-y i) center-y))

    ;; 顶点 i+1
    (rl-tex-coord-2f (vector-ref texcoords-x (+ i 1)) (vector-ref texcoords-y (+ i 1)))
    (rl-vertex-2f (+ (vector-ref points-x (+ i 1)) center-x)
                  (+ (vector-ref points-y (+ i 1)) center-y)))

  (rl-end)
  (rl-set-texture 0))

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - polygon drawing")

;; 纹理坐标 (UV) — 定义纹理如何映射到多边形
(define texcoords-x (vector 0.75 0.25 0.0 0.0 0.25 0.375 0.625 0.75 1.0 1.0 0.75))
(define texcoords-y (vector 0.0  0.0  0.5 0.75 1.0 0.875 0.875 1.0 0.75 0.5 0.0))

;; 基础多边形顶点（由 UV 坐标推导）
(define points-x
  (for/vector ([i (in-range max-points)])
    (* (- (vector-ref texcoords-x i) 0.5) 256.0)))

(define points-y
  (for/vector ([i (in-range max-points)])
    (* (- (vector-ref texcoords-y i) 0.5) 256.0)))

;; 加载纹理
(define texture (load-texture (string-append resource-dir "cat.png")))

(define angle 0.0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ([angle 0.0])
  (unless (window-should-close?)
    ;; 更新 — 旋转多边形顶点
    (let* ([angle (+ angle 1.0)]
           [rad (* angle (/ 3.141592653589793 180.0))]
           ;; 对每个基础点做旋转，生成 rotated 向量列表
           [rotated (for/vector ([i (in-range max-points)])
                      (vec2-rotate (vector2 (vector-ref points-x i)
                                            (vector-ref points-y i))
                                   rad))]
           [rotated-x (for/vector ([i (in-range max-points)])
                        (vector2-x (vector-ref rotated i)))]
           [rotated-y (for/vector ([i (in-range max-points)])
                        (vector2-y (vector-ref rotated i)))])

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)

      (draw-text "textured polygon" 20 20 20 DARKGRAY)

      (draw-texture-poly texture
                         (/ screen-width 2.0) (/ screen-height 2.0)
                         rotated-x rotated-y
                         texcoords-x texcoords-y
                         max-points WHITE)

      (end-drawing)
      (loop angle))))

;; ============================================================
;; 清理
;; ============================================================

(unload-texture texture)
(close-window)
