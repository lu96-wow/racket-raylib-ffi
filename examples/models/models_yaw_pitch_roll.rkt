#lang racket/base

;; raylib [models] example - yaw pitch roll (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_yaw_pitch_roll.c
;; 注意: C 版直接赋值 model.transform = MatrixRotateXYZ(...)
;;       FFI 不支持直接修改模型矩阵，改为计算 Euler 矩阵后重建 model list

(require "../../raylib/raylib.rkt"
         racket/runtime-path)

;; ============================================================
;; 辅助: Euler 旋转矩阵 (Rx*Ry*Rz, 列主序, 16 floats)
;; ============================================================

(define (euler-xyz-matrix pitch yaw roll)
  (define sp (sin pitch)) (define cp (cos pitch))
  (define sy (sin yaw))   (define cy (cos yaw))
  (define sr (sin roll))  (define cr (cos roll))
  (list (* cy cr)                              ;; m0
        (* cy sr)                              ;; m1
        (- sy)                                 ;; m2
        0.0                                    ;; m3
        (- (* sp sy cr) (* cp sr))             ;; m4
        (+ (* sp sy sr) (* cp cr))             ;; m5
        (* sp cy)                              ;; m6
        0.0                                    ;; m7
        (+ (* cp sy cr) (* sp sr))             ;; m8
        (- (* cp sy sr) (* sp cr))             ;; m9
        (* cp cy)                              ;; m10
        0.0                                    ;; m11
        0.0 0.0 0.0 1.0))                      ;; m12-m15

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(define-runtime-path resource-dir "../../../examples/models/resources/")

(init-window screen-width screen-height
  "raylib [models] example - yaw pitch roll")

;; 定义 3D 相机
(define camera (camera3d 0.0 50.0 -120.0
                         0.0 0.0 0.0
                         0.0 1.0 0.0
                         30.0 CAMERA-PERSPECTIVE))

;; 加载模型 & 纹理
(define model (load-model (path->string (build-path resource-dir "models/obj/plane.obj"))))
(define texture (load-texture (path->string (build-path resource-dir "models/obj/plane_diffuse.png"))))
(set-material-texture (list-ref model 19) MATERIAL-MAP-DIFFUSE texture)

(define pitch 0.0)
(define roll 0.0)
(define yaw 0.0)

;; DEG2RAD
(define DEG2RAD (/ (* 4 (atan 1)) 180))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    ;; 俯仰 (X轴): UP/DOWN
    (cond [(is-key-down KEY-DOWN)  (set! pitch (+ pitch 0.6))]
          [(is-key-down KEY-UP)    (set! pitch (- pitch 0.6))]
          [else (cond [(> pitch 0.3)  (set! pitch (- pitch 0.3))]
                      [(< pitch -0.3) (set! pitch (+ pitch 0.3))])])

    ;; 偏航 (Y轴): A/S
    (cond [(is-key-down KEY-S) (set! yaw (- yaw 1.0))]
          [(is-key-down KEY-A) (set! yaw (+ yaw 1.0))]
          [else (cond [(> yaw 0.0)  (set! yaw (- yaw 0.5))]
                      [(< yaw 0.0)  (set! yaw (+ yaw 0.5))])])

    ;; 翻滚 (Z轴): LEFT/RIGHT
    (cond [(is-key-down KEY-LEFT)  (set! roll (- roll 1.0))]
          [(is-key-down KEY-RIGHT) (set! roll (+ roll 1.0))]
          [else (cond [(> roll 0.0)  (set! roll (- roll 0.5))]
                      [(< roll 0.0)  (set! roll (+ roll 0.5))])])

    ;; 计算 Euler 矩阵并替换 model list 的 transform (前 16 个元素)
    (define mat (euler-xyz-matrix (* DEG2RAD pitch)
                                  (* DEG2RAD yaw)
                                  (* DEG2RAD roll)))
    (define transformed-model
      (list* (list-ref mat 0) (list-ref mat 1) (list-ref mat 2) (list-ref mat 3)
             (list-ref mat 4) (list-ref mat 5) (list-ref mat 6) (list-ref mat 7)
             (list-ref mat 8) (list-ref mat 9) (list-ref mat 10) (list-ref mat 11)
             (list-ref mat 12) (list-ref mat 13) (list-ref mat 14) (list-ref mat 15)
             (list-tail model 16)))  ;; 剩余字段: meshCount, materialCount, ...

    ;; ---- Draw ----
    (begin-drawing)
    (clear-background RAYWHITE)

    (begin-mode-3d camera)
    (draw-model transformed-model (vector3 0.0 -8.0 0.0) 1.0 WHITE)
    (draw-grid 10 10.0)
    (end-mode-3d)

    ;; 控制提示
    (draw-rectangle 30 370 260 70 (fade GREEN 0.5))
    (draw-rectangle-lines 30 370 260 70 (fade DARKGREEN 0.5))
    (draw-text "Pitch controlled with: KEY_UP / KEY_DOWN" 40 380 10 DARKGRAY)
    (draw-text "Roll controlled with: KEY_LEFT / KEY_RIGHT" 40 400 10 DARKGRAY)
    (draw-text "Yaw controlled with: KEY_A / KEY_S" 40 420 10 DARKGRAY)

    (draw-text "(c) WWI Plane Model created by GiaHanLam"
               (- screen-width 240) (- screen-height 20) 10 DARKGRAY)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-model model)
(unload-texture texture)
(close-window)
