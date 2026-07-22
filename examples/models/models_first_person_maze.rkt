#lang racket/base

;; raylib [models] example - first person maze (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_first_person_maze.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(define-runtime-path resource-dir "../../../examples/models/resources/")

(init-window screen-width screen-height
  "raylib [models] example - first person maze")

;; 定义 3D 相机 (第一人称)
(define camera (camera3d 0.2 0.4 0.2
                         0.185 0.4 0.0
                         0.0 1.0 0.0
                         45.0 CAMERA-PERSPECTIVE))

;; cubicmap 图像 → 网格 → 模型
(define im-map (load-image (path->string (build-path resource-dir "cubicmap.png"))))
(define cubicmap (load-texture-from-image im-map))
(define mesh (gen-mesh-cubicmap im-map (vector3 1.0 1.0 1.0)))
(define model (load-model-from-mesh mesh))
(define texture (load-texture (path->string (build-path resource-dir "cubicmap_atlas.png"))))
(set-material-texture (model-materials model) MATERIAL-MAP-DIFFUSE texture)

;; 读取像素颜色用于碰撞检测
(define map-pixels (load-image-colors im-map))  ;; Color* 指针
(unload-image im-map)

(define map-position (vector3 -16.0 0.0 -8.0))
(define cmap-w (image-width cubicmap))
(define cmap-h (image-height cubicmap))

(disable-cursor)
(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(define player-cell-x 0)
(define player-cell-y 0)

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    (define old-cam-pos (vector3 (camera3d-pos-x camera)
                                  (camera3d-pos-y camera)
                                  (camera3d-pos-z camera)))
    (update-camera camera CAMERA-FIRST-PERSON)

    ;; 2D 碰撞检测
    (let* ([player-pos (vector2 (camera3d-pos-x camera)
                                (camera3d-pos-z camera))]
           [player-radius 0.1]
           [pcx (inexact->exact (floor (+ (- (vector2-x player-pos)
                                             (vector3-x map-position))
                                          0.5)))]
           [pcy (inexact->exact (floor (+ (- (vector2-y player-pos)
                                             (vector3-z map-position))
                                          0.5)))])
      (set! player-cell-x (cond [(< pcx 0) 0]
                                [(>= pcx cmap-w) (sub1 cmap-w)]
                                [else pcx]))
      (set! player-cell-y (cond [(< pcy 0) 0]
                                [(>= pcy cmap-h) (sub1 cmap-h)]
                                [else pcy]))

      ;; 检查周围 3×3 格子
      (for* ([y (in-range (sub1 player-cell-y) (+ player-cell-y 2))]
             [x (in-range (sub1 player-cell-x) (+ player-cell-x 2))]
             #:when (and (>= x 0) (< x cmap-w) (>= y 0) (< y cmap-h)))
        ;; Color*: r,g,b,a 各 1 字节, .r 偏移 0
        (when (= (ptr-ref map-pixels _ubyte (* (+ (* y cmap-w) x) 4)) 255)
          (define cell-rec (rectangle (+ (vector3-x map-position) -0.5 (* x 1.0))
                                      (+ (vector3-z map-position) -0.5 (* y 1.0))
                                      1.0 1.0))
          (when (check-collision-circle-rec player-pos player-radius cell-rec)
            (set-camera3d-pos-x! camera (vector3-x old-cam-pos))
            (set-camera3d-pos-y! camera (vector3-y old-cam-pos))
            (set-camera3d-pos-z! camera (vector3-z old-cam-pos))))))

    ;; ---- Draw ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)
    (draw-model model map-position 1.0 WHITE)
    (end-mode-3d)

    ;; 右下角 cubicmap 预览
    (draw-texture-ex cubicmap
                     (vector2 (- (get-screen-width) (* cmap-w 4.0) 20) 20.0)
                     0.0 4.0 WHITE)
    (draw-rectangle-lines (- (get-screen-width) (* cmap-w 4) 20) 20
                          (* cmap-w 4) (* cmap-h 4) GREEN)

    ;; 玩家位置雷达
    (draw-rectangle (- (get-screen-width) (* cmap-w 4) 20 (* player-cell-x 4))
                    (+ 20 (* player-cell-y 4)) 4 4 RED)

    (draw-fps 10 10)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-image-colors map-pixels)
(unload-texture cubicmap)
(unload-texture texture)
(unload-model model)
(close-window)
