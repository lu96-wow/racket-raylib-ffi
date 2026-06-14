#lang racket/base

;; raylib [models] example - basic voxel (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_basic_voxel.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define WORLD-SIZE 8)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [models] example - basic voxel")

(disable-cursor) ; 锁定鼠标到窗口中心

;; 定义 3D 相机（第一人称）
(define camera (camera3d -2.0 0.0 -2.0
                          0.0 0.0  0.0
                          0.0 1.0  0.0
                          45.0 CAMERA-PERSPECTIVE))

;; 创建立方体模型，用 BEIGE 作底色
(define cube-model (load-model-from-mesh (gen-mesh-cube 1.0 1.0 1.0)))

;; 初始化体素世界 (3D bool array: 8×8×8, 全部填满)
(define voxels
  (let ([v (make-vector WORLD-SIZE)])
    (for ([x (in-range WORLD-SIZE)])
      (let ([yv (make-vector WORLD-SIZE)])
        (for ([y (in-range WORLD-SIZE)])
          (vector-set! yv y (make-vector WORLD-SIZE #t)))
        (vector-set! v x yv)))
    v))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    (update-camera camera CAMERA-FIRST-PERSON)

    ;; 鼠标左键点击 → 射线检测移除体素
    (when (is-mouse-button-pressed MOUSE-BUTTON-LEFT)
      (let* ([screen-center (vector2 (/ screen-width 2.0) (/ screen-height 2.0))]
             [ray (get-screen-to-world-ray screen-center camera)]
             [closest-distance 99999.0]
             [closest-x -1]
             [closest-y -1]
             [closest-z -1]
             [voxel-found? #f])
        ;; 遍历所有体素做射线-包围盒碰撞检测
        (for* ([x (in-range WORLD-SIZE)]
               [y (in-range WORLD-SIZE)]
               [z (in-range WORLD-SIZE)])
          (when (vector-ref (vector-ref (vector-ref voxels x) y) z)
            (let* ([px (+ x 0.0)] [py (+ y 0.0)] [pz (+ z 0.0)]
                   [box (bounding-box (- px 0.5) (- py 0.5) (- pz 0.5)
                                      (+ px 0.5) (+ py 0.5) (+ pz 0.5))]
                   [collision (get-ray-collision-box ray box)])
              (when (and (list-ref collision 0)          ; .hit
                         (< (list-ref collision 1) closest-distance))
                (set! closest-distance (list-ref collision 1))
                (set! closest-x x)
                (set! closest-y y)
                (set! closest-z z)
                (set! voxel-found? #t)))))
        ;; 移除最近的体素
        (when voxel-found?
          (vector-set! (vector-ref (vector-ref voxels closest-x) closest-y)
                       closest-z #f))))

    ;; ---- Draw ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)

    (draw-grid 10 1.0)

    ;; 绘制所有体素
    (for* ([x (in-range WORLD-SIZE)]
           [y (in-range WORLD-SIZE)]
           [z (in-range WORLD-SIZE)])
      (when (vector-ref (vector-ref (vector-ref voxels x) y) z)
        (let ([pos (vector3 (+ x 0.0) (+ y 0.0) (+ z 0.0))])
          (draw-model cube-model pos 1.0 BEIGE)
          (draw-cube-wires pos 1.0 1.0 1.0 BLACK))))

    (end-mode-3d)

    ;; 准星
    (draw-circle (/ screen-width 2) (/ screen-height 2) 4.0 RED)

    (draw-text "Left-click a voxel to remove it!" 10 10 20 DARKGRAY)
    (draw-text "WASD to move, mouse to look around" 10 35 10 GRAY)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-model cube-model)
(close-window)
