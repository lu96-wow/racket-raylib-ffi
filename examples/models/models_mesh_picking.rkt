#lang racket/base

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

(define screen-width 800)
(define screen-height 450)
(define-runtime-path resource-dir "../../../examples/models/resources/")

(init-window screen-width screen-height "raylib [models] example - mesh picking")

(define camera (camera3d 20.0 20.0 20.0  0.0 8.0 0.0  0.0 1.6 0.0  45.0 CAMERA-PERSPECTIVE))
(define tower (load-model (path->string (build-path resource-dir "models/obj/turret.obj"))))
(define texture (load-texture (path->string (build-path resource-dir "models/obj/turret_diffuse.png"))))
(define tower-pos (vector3 0.0 0.0 0.0))

;; 设置材质纹理
(set-material-texture (list-ref tower 19) MATERIAL-MAP-DIFFUSE texture)

;; 获取包围盒
(define meshes-ptr (list-ref tower 18))
(define (list->bounding-box lst)
  (bounding-box (list-ref lst 0) (list-ref lst 1) (list-ref lst 2)
                (list-ref lst 3) (list-ref lst 4) (list-ref lst 5)))
(define mesh0 (ptr-ref meshes-ptr _mesh-bytes 0))
(define tower-bbox (list->bounding-box (get-mesh-bounding-box mesh0)))

;; 地面四边形 / 测试三角形 / 球体
(define g0 (vector3 -50.0 0.0 -50.0))
(define g1 (vector3 -50.0 0.0  50.0))
(define g2 (vector3  50.0 0.0  50.0))
(define g3 (vector3  50.0 0.0 -50.0))
(define ta (vector3 -25.0 0.5 0.0))
(define tb (vector3 -4.0  2.5 1.0))
(define tc (vector3 -8.0  6.5 0.0))
(define sp (vector3 -30.0 5.0 5.0))
(define sr 4.0)

;; model.transform = 前16 float
(define (model-transform model)
  (for/list ([i (in-range 16)]) (list-ref model i)))

;; RayCollision list → point/normal
(define (rc-point rc) (vector3 (list-ref rc 2) (list-ref rc 3) (list-ref rc 4)))
(define (rc-normal rc) (vector3 (list-ref rc 5) (list-ref rc 6) (list-ref rc 7)))

(define FLT-MAX 3.4028235e+38)

(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (when (is-cursor-hidden?) (update-camera camera CAMERA-FIRST-PERSON))
    (when (is-mouse-button-pressed MOUSE-BUTTON-RIGHT)
      (if (is-cursor-hidden?) (enable-cursor) (disable-cursor)))

    (define collision-hit? #f)
    (define collision-dist FLT-MAX)
    (define collision-pt (vector3 0 0 0))
    (define collision-nm (vector3 0 0 0))
    (define cursor-color WHITE)
    (define hit-object-name "None")
    (define box-hit? #f)

    (define ray (get-screen-to-world-ray (get-mouse-position) camera))

    ;; 地面
    (let ([hit (get-ray-collision-quad ray g0 g1 g2 g3)])
      (when (and (list-ref hit 0) (< (list-ref hit 1) collision-dist))
        (set! collision-hit? #t) (set! collision-dist (list-ref hit 1))
        (set! collision-pt (rc-point hit)) (set! collision-nm (rc-normal hit))
        (set! cursor-color GREEN) (set! hit-object-name "Ground")))

    ;; 三角形
    (let ([hit (get-ray-collision-triangle ray ta tb tc)])
      (when (and (list-ref hit 0) (< (list-ref hit 1) collision-dist))
        (set! collision-hit? #t) (set! collision-dist (list-ref hit 1))
        (set! collision-pt (rc-point hit)) (set! collision-nm (rc-normal hit))
        (set! cursor-color PURPLE) (set! hit-object-name "Triangle")))

    ;; 球体
    (let ([hit (get-ray-collision-sphere ray sp sr)])
      (when (and (list-ref hit 0) (< (list-ref hit 1) collision-dist))
        (set! collision-hit? #t) (set! collision-dist (list-ref hit 1))
        (set! collision-pt (rc-point hit)) (set! collision-nm (rc-normal hit))
        (set! cursor-color ORANGE) (set! hit-object-name "Sphere")))

    ;; 包围盒 + 网格
    (let ([hit (get-ray-collision-box ray tower-bbox)])
      (when (and (list-ref hit 0) (< (list-ref hit 1) collision-dist))
        (set! collision-hit? #t) (set! collision-dist (list-ref hit 1))
        (set! collision-pt (rc-point hit)) (set! collision-nm (rc-normal hit))
        (set! cursor-color ORANGE) (set! hit-object-name "Box")
        (set! box-hit? #t)
        (for ([m (in-range (list-ref tower 16))])
          (let* ([mesh-ptr (ptr-add meshes-ptr (* m 120))]  ; Mesh-size = 120
                 [mhit (get-ray-collision-mesh ray mesh-ptr (model-transform tower))])
            (when (and (list-ref mhit 0) (< (list-ref mhit 1) collision-dist))
              (set! collision-hit? #t) (set! collision-dist (list-ref mhit 1))
              (set! collision-pt (rc-point mhit)) (set! collision-nm (rc-normal mhit))
              (set! cursor-color ORANGE) (set! hit-object-name "Mesh"))))))

    ;; Draw
    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)
    (draw-model tower tower-pos 1.0 WHITE)
    (draw-line-3d ta tb PURPLE) (draw-line-3d tb tc PURPLE) (draw-line-3d tc ta PURPLE)
    (draw-sphere-wires sp sr 8 8 PURPLE)
    (when box-hit? (draw-bounding-box tower-bbox LIME))
    (when collision-hit?
      (draw-cube collision-pt 0.3 0.3 0.3 cursor-color)
      (draw-cube-wires collision-pt 0.3 0.3 0.3 RED)
      (draw-line-3d collision-pt
        (vector3 (+ (vector3-x collision-pt) (vector3-x collision-nm))
                 (+ (vector3-y collision-pt) (vector3-y collision-nm))
                 (+ (vector3-z collision-pt) (vector3-z collision-nm))) RED))
    (draw-ray ray MAROON)
    (draw-grid 10 10.0)
    (end-mode-3d)

    (draw-text (format "Hit Object: ~a" hit-object-name) 10 50 10 BLACK)
    (when collision-hit?
      (draw-text (format "Distance: ~a" (real->decimal-string collision-dist 2)) 10 70 10 BLACK)
      (draw-text (format "Hit Pos: ~a ~a ~a"
                         (real->decimal-string (vector3-x collision-pt) 2)
                         (real->decimal-string (vector3-y collision-pt) 2)
                         (real->decimal-string (vector3-z collision-pt) 2)) 10 85 10 BLACK)
      (draw-text (format "Hit Norm: ~a ~a ~a"
                         (real->decimal-string (vector3-x collision-nm) 2)
                         (real->decimal-string (vector3-y collision-nm) 2)
                         (real->decimal-string (vector3-z collision-nm) 2)) 10 100 10 BLACK))
    (draw-text "Right click mouse to toggle camera controls" 10 430 10 GRAY)
    (draw-text "(c) Turret 3D model by Alberto Cano" (- screen-width 200) (- screen-height 20) 10 GRAY)
    (draw-fps 10 10)
    (end-drawing)
    (loop)))

(unload-texture texture)
(unload-model tower)
(close-window)
