#lang racket/base

;; raylib [models] example - bone socket (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_bone_socket.c

(require "../../raylib/raylib.rkt"
         racket/runtime-path
         (only-in ffi/unsafe ptr-ref ptr-add _float _int _ubyte _pointer))

;; ============================================================
;; 常量
;; ============================================================

(define BONE-SOCKETS 3)
(define BONE-SOCKET-HAT 0)
(define BONE-SOCKET-HAND-R 1)
(define BONE-SOCKET-HAND-L 2)
(define DEG2RAD (/ (* 4 (atan 1)) 180))

;; ============================================================
;; 布局常量 (gen-layout 确认)
;; ============================================================

(define BONEINFO-SIZE 36)         ;; sizeof(BoneInfo) — gen-layout 确认
(define TRANSFORM-SIZE 40)        ;; sizeof(Transform)
(define TRANSFORM-ROTATION-OFF 12) ;; offsetof(Transform, rotation)
(define MODEL-ANIMATION-SIZE 48)  ;; sizeof(ModelAnimation)

;; ============================================================
;; 辅助: C 字符串 → Racket string
;; ============================================================

(define (cstr->string ptr max-len)
  (list->string
   (for/list ([i (in-range max-len)]
              #:break (zero? (ptr-ref ptr _ubyte i)))
     (integer->char (ptr-ref ptr _ubyte i)))))

;; ============================================================
;; 动画访问辅助
;; ============================================================

(define (anim-ptr anims-ptr idx)
  (ptr-add anims-ptr (* idx MODEL-ANIMATION-SIZE)))

(define (anim-keyframe-poses anim-ptr)
  (ptr-ref anim-ptr _pointer 5))  ;; byte offset 40

(define (anim->list anim-ptr)
  ;; 将 ModelAnimation cpointer 转换为 _model-animation-bytes list
  (append (for/list ([i 32]) (ptr-ref anim-ptr _ubyte i))
          (list (ptr-ref anim-ptr _int 8)    ;; boneCount @32
                (ptr-ref anim-ptr _int 9)     ;; keyframeCount @36
                (ptr-ref anim-ptr _pointer 5)))) ;; keyframePoses @40

(define (transform-rotation transform-ptr)
  (ptr-add transform-ptr TRANSFORM-ROTATION-OFF))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(define-runtime-path resource-dir "../../../examples/models/resources/")
(define (res . parts) (path->string (simplify-path (apply build-path resource-dir parts))))

(init-window screen-width screen-height "raylib [models] example - bone socket")

(define camera (camera3d 5.0 5.0 5.0  0.0 2.0 0.0  0.0 1.0 0.0  45.0 CAMERA-PERSPECTIVE))

;; 加载模型
(define character-model (load-model (res "models/gltf/greenman.glb")))
(define equip-model
  (vector (load-model (res "models/gltf/greenman_hat.glb"))
          (load-model (res "models/gltf/greenman_sword.glb"))
          (load-model (res "models/gltf/greenman_shield.glb"))))
(define show-equip (vector #t #t #t))

;; 加载动画并运行
(let-values ([(anims-ptr anim-count) (load-model-animations (res "models/gltf/greenman.glb"))])

  (define anim-index 0)
  (define anim-current-frame 0)

  ;; 搜索骨骼 socket
  (define bone-socket-index (make-vector BONE-SOCKETS -1))
  (let ([bone-count (list-ref character-model 21)]
        [bones-ptr (list-ref character-model 23)])
    (for ([i (in-range bone-count)])
      (let ([name (cstr->string (ptr-add bones-ptr (* i BONEINFO-SIZE)) 32)])
        (cond [(string=? name "socket_hat")    (vector-set! bone-socket-index BONE-SOCKET-HAT i)]
              [(string=? name "socket_hand_R") (vector-set! bone-socket-index BONE-SOCKET-HAND-R i)]
              [(string=? name "socket_hand_L") (vector-set! bone-socket-index BONE-SOCKET-HAND-L i)]))))

  (define position (vector3 0.0 0.0 0.0))
  (define angle 0)
  (disable-cursor)
  (set-target-fps 60)

  (let loop ()
    (unless (window-should-close?)

      ;; ---- Update ----
      (update-camera camera CAMERA-THIRD-PERSON)

      (cond [(is-key-down KEY-F) (set! angle (modulo (add1 angle) 360))]
            [(is-key-down KEY-H) (set! angle (modulo (- angle 1) 360))])
      (when (is-key-pressed KEY-T)
        (set! anim-index (modulo (add1 anim-index) anim-count)))
      (when (is-key-pressed KEY-G)
        (set! anim-index (modulo (+ anim-index anim-count -1) anim-count)))
      (when (is-key-pressed KEY-ONE)
        (vector-set! show-equip BONE-SOCKET-HAT (not (vector-ref show-equip BONE-SOCKET-HAT))))
      (when (is-key-pressed KEY-TWO)
        (vector-set! show-equip BONE-SOCKET-HAND-R (not (vector-ref show-equip BONE-SOCKET-HAND-R))))
      (when (is-key-pressed KEY-THREE)
        (vector-set! show-equip BONE-SOCKET-HAND-L (not (vector-ref show-equip BONE-SOCKET-HAND-L))))

      ;; 更新动画帧
      (let* ([a-ptr (anim-ptr anims-ptr anim-index)]
             [kf-count (ptr-ref a-ptr _int 9)])
        (set! anim-current-frame (modulo (add1 anim-current-frame) kf-count)))

      ;; ---- Draw ----
      (begin-drawing)
      (clear-background RAYWHITE)
      (begin-mode-3d camera)

      ;; 角色旋转
      (define char-rotate (quaternion-from-axis-angle (vector3 0.0 1.0 0.0) (* angle DEG2RAD)))
      (define char-transform
        (matrix-multiply (quaternion-to-matrix char-rotate)
                         (matrix-translate 0.0 0.0 0.0)))

      ;; 更新角色动画
      (define a-ptr (anim-ptr anims-ptr anim-index))
      (define anim-list (anim->list a-ptr))
      (define model-list (append char-transform (list-tail character-model 16)))
      (update-model-animation model-list anim-list (exact->inexact anim-current-frame))

      ;; 绘制角色 (meshes[0], materials[1])
      (let ([meshes-ptr (model-meshes model-list)]
            [mats-ptr (model-materials model-list)])
        (draw-mesh (mesh-ptr->list meshes-ptr)
                   (material-ptr->list (ptr-add mats-ptr 40))
                   char-transform))

      ;; 绘制装备
      (let ([bind-pose-ptr (list-ref model-list 24)]   ;; skeleton.bindPose
            [kf-poses (anim-keyframe-poses a-ptr)])
        (for ([i (in-range BONE-SOCKETS)])
          (when (vector-ref show-equip i)
            (let* ([bone-idx (vector-ref bone-socket-index i)])
              (when (>= bone-idx 0)
                (let* ([frame-ptr (ptr-ref kf-poses _pointer anim-current-frame)]
                       [t-ptr (ptr-add frame-ptr (* bone-idx TRANSFORM-SIZE))]
                       [in-rot (transform-rotation (ptr-add bind-pose-ptr (* bone-idx TRANSFORM-SIZE)))]
                       [out-rot (transform-rotation t-ptr)]
                       [rotate-q (quaternion-multiply out-rot (quaternion-invert in-rot))]
                       [bone-tf (quaternion-to-matrix rotate-q)]
                       [trans (ptr-add t-ptr 0)]  ;; transform.translation @0
                       [bone-tf2 (matrix-multiply bone-tf
                                    (matrix-translate (ptr-ref trans _float 0)
                                                     (ptr-ref trans _float 1)
                                                     (ptr-ref trans _float 2)))]
                       [final-tf (matrix-multiply bone-tf2 char-transform)]
                       [eq-model (vector-ref equip-model i)]
                       [eq-meshes (list-ref eq-model 18)]
                       [eq-mats (list-ref eq-model 19)])
                  (draw-mesh (mesh-ptr->list eq-meshes)
                             (material-ptr->list (ptr-add eq-mats 40))
                             final-tf)))))))

      (draw-grid 10 1.0)
      (end-mode-3d)

      (draw-text "T/G: switch animation" 10 10 20 GRAY)
      (draw-text "F/H: rotate character" 10 35 20 GRAY)
      (draw-text "1/2/3: toggle hat/sword/shield" 10 60 20 GRAY)
      (end-drawing)
      (loop)))

  (unload-model-animations anims-ptr anim-count))

(unload-model character-model)
(for ([i (in-range BONE-SOCKETS)]) (unload-model (vector-ref equip-model i)))
(close-window)
