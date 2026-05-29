#lang racket/base

;; raylib [core] example - 3d camera first person
;;
;; 对应 C: examples/core/core_3d_camera_first_person.c
;; 演示: 第一人称/自由/第三人称/轨道相机模式切换, 正交/透视投影切换
;;
;; 控制:
;;   1/2/3/4 - 切换相机模式 (FREE / FIRST_PERSON / THIRD_PERSON / ORBITAL)
;;   P       - 切换投影 (PERSPECTIVE <-> ORTHOGRAPHIC)
;;   WASD    - 移动
;;   鼠标/方向键 - 视角
;;   Space/Left-Ctrl - 上/下
;;
;; WARNING: 此环境 (llvmpipe + GLFW X11) 启用 GLFW_RAW_MOUSE_MOTION 后,
;; GetMouseDelta() 返回 ~25000 量级的原始硬件 counts, 而非正常像素差值 (~1-10)。
;; raylib UpdateCamera() 用固定灵敏度 0.003f 计算:
;;   angle = 25000 x 0.003 = 75 rad -> 一次打满 CameraPitch 极限
;; 导致相机立刻垂直看地。C 语言版测试结果完全相同, 非 Racket 绑定问题。

(require "../../raylib/raylib.rkt")

(define MAX-COLUMNS 20)
(define DEG2RAD (/ 3.141592653589793 180.0))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
             "raylib [core] example - 3d camera first person")

(define camera
  (camera3d 0.0 2.0 4.0     ;; position
            0.0 2.0 0.0      ;; target
            0.0 1.0 0.0      ;; up
            60.0             ;; fovy
            CAMERA-PERSPECTIVE))

(define camera-mode (box CAMERA-FIRST-PERSON))

(define heights (make-vector MAX-COLUMNS 0.0))
(define positions (make-vector MAX-COLUMNS #f))
(define colors   (make-vector MAX-COLUMNS #f))

(for ([i (in-range MAX-COLUMNS)])
  (let ([h (exact->inexact (get-random-value 1 12))])
    (vector-set! heights i h)
    (vector-set! positions i
      (vector3 (exact->inexact (get-random-value -15 15))
               (/ h 2.0)
               (exact->inexact (get-random-value -15 15))))
    (vector-set! colors i
      (make-color (get-random-value 20 255)
                  (get-random-value 10 55)
                  30))))

(disable-cursor)
(set-target-fps 60)

(define (reset-camera-up!)
  (set-camera3d-up-x! camera 0.0)
  (set-camera3d-up-y! camera 1.0)
  (set-camera3d-up-z! camera 0.0))

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (cond
      [(is-key-pressed KEY-ONE)
       (set-box! camera-mode CAMERA-FREE) (reset-camera-up!)]
      [(is-key-pressed KEY-TWO)
       (set-box! camera-mode CAMERA-FIRST-PERSON) (reset-camera-up!)]
      [(is-key-pressed KEY-THREE)
       (set-box! camera-mode CAMERA-THIRD-PERSON) (reset-camera-up!)]
      [(is-key-pressed KEY-FOUR)
       (set-box! camera-mode CAMERA-ORBITAL) (reset-camera-up!)])

    (when (is-key-pressed KEY-P)
      (if (= (camera3d-proj camera) CAMERA-PERSPECTIVE)
        (begin
          (set-box! camera-mode CAMERA-THIRD-PERSON)
          (set-camera3d-pos-x! camera 0.0)
          (set-camera3d-pos-y! camera 2.0)
          (set-camera3d-pos-z! camera -100.0)
          (set-camera3d-tar-x! camera 0.0)
          (set-camera3d-tar-y! camera 2.0)
          (set-camera3d-tar-z! camera 0.0)
          (reset-camera-up!)
          (set-camera3d-proj! camera CAMERA-ORTHOGRAPHIC)
          (set-camera3d-fovy! camera 20.0)
          (camera-yaw camera (* -135 DEG2RAD) #t)
          (camera-pitch camera (* -45 DEG2RAD) #t #t #f))
        (begin
          (set-box! camera-mode CAMERA-THIRD-PERSON)
          (set-camera3d-pos-x! camera 0.0)
          (set-camera3d-pos-y! camera 2.0)
          (set-camera3d-pos-z! camera 10.0)
          (set-camera3d-tar-x! camera 0.0)
          (set-camera3d-tar-y! camera 2.0)
          (set-camera3d-tar-z! camera 0.0)
          (reset-camera-up!)
          (set-camera3d-proj! camera CAMERA-PERSPECTIVE)
          (set-camera3d-fovy! camera 60.0))))

    (update-camera camera (unbox camera-mode))

    (begin-drawing)
    (clear-background RAYWHITE)
    (begin-mode-3d camera)

    (draw-plane (vector3 0.0 0.0 0.0) (vector2 32.0 32.0) LIGHTGRAY)
    (draw-cube (vector3 -16.0 2.5 0.0) 1.0 5.0 32.0 BLUE)
    (draw-cube (vector3 16.0 2.5 0.0)  1.0 5.0 32.0 LIME)
    (draw-cube (vector3 0.0 2.5 16.0)  32.0 5.0 1.0 GOLD)

    (for ([i (in-range MAX-COLUMNS)])
      (let ([pos (vector-ref positions i)]
            [h   (vector-ref heights i)]
            [col (vector-ref colors i)])
        (draw-cube pos 2.0 h 2.0 col)
        (draw-cube-wires pos 2.0 h 2.0 MAROON)))

    (when (= (unbox camera-mode) CAMERA-THIRD-PERSON)
      (let ([tx (camera3d-tar-x camera)]
            [ty (camera3d-tar-y camera)]
            [tz (camera3d-tar-z camera)])
        (draw-cube (vector3 tx ty tz) 0.5 0.5 0.5 PURPLE)
        (draw-cube-wires (vector3 tx ty tz) 0.5 0.5 0.5 DARKPURPLE)))

    (end-mode-3d)

    (draw-rectangle 5 5 330 100 (fade SKYBLUE 0.5))
    (draw-rectangle-lines 5 5 330 100 BLUE)
    (draw-text "Camera controls:" 15 15 10 BLACK)
    (draw-text "- Move keys: W, A, S, D, Space, Left-Ctrl" 15 30 10 BLACK)
    (draw-text "- Look around: arrow keys or mouse" 15 45 10 BLACK)
    (draw-text "- Camera mode keys: 1, 2, 3, 4" 15 60 10 BLACK)
    (draw-text "- Zoom keys: num-plus, num-minus or mouse scroll" 15 75 10 BLACK)
    (draw-text "- Camera projection key: P" 15 90 10 BLACK)

    (draw-rectangle 600 5 195 100 (fade SKYBLUE 0.5))
    (draw-rectangle-lines 600 5 195 100 BLUE)
    (draw-text "Camera status:" 610 15 10 BLACK)

    (let ([mode-str (cond [(= (unbox camera-mode) CAMERA-FREE) "FREE"]
                          [(= (unbox camera-mode) CAMERA-FIRST-PERSON) "FIRST_PERSON"]
                          [(= (unbox camera-mode) CAMERA-THIRD-PERSON) "THIRD_PERSON"]
                          [(= (unbox camera-mode) CAMERA-ORBITAL) "ORBITAL"]
                          [else "CUSTOM"])])
      (draw-text (format "- Mode: ~a" mode-str) 610 30 10 BLACK))

    (let ([proj-str (if (= (camera3d-proj camera) CAMERA-PERSPECTIVE)
                      "PERSPECTIVE" "ORTHOGRAPHIC")])
      (draw-text (format "- Projection: ~a" proj-str) 610 45 10 BLACK))

    (draw-text (format "- Position: (~a, ~a, ~a)"
                       (camera3d-pos-x camera)
                       (camera3d-pos-y camera)
                       (camera3d-pos-z camera))
               610 60 10 BLACK)
    (draw-text (format "- Target: (~a, ~a, ~a)"
                       (camera3d-tar-x camera)
                       (camera3d-tar-y camera)
                       (camera3d-tar-z camera))
               610 75 10 BLACK)
    (draw-text (format "- Up: (~a, ~a, ~a)"
                       (camera3d-up-x camera)
                       (camera3d-up-y camera)
                       (camera3d-up-z camera))
               610 90 10 BLACK)

    (end-drawing)
    (loop)))

(close-window)
