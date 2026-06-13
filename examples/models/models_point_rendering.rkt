#lang racket/base

;; raylib [models] example - point rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/models/models_point_rendering.c

(require ffi/unsafe
         "../../raylib/raylib.rkt"
         racket/runtime-path
         racket/math)

;; ============================================================
;; 辅助绑定 (尚未在 rcore.rkt 中的函数)
;; ============================================================

(define mem-alloc
  (get-ffi-obj "MemAlloc" lib (_fun _uint -> _pointer)))

(define color-from-hsv
  (let ([f (get-ffi-obj "ColorFromHSV" lib
             (_fun _float _float _float -> (c : _color-bytes)))])
    (lambda (h s v) (f h s v))))

;; ColorFromHSV 返回 list (r g b a)，转成 color pointer
(define (color-from-hsv->ptr h s v)
  (let ([lst (color-from-hsv h s v)])
    (let ([c (malloc _Color 'atomic)])
      (ptr-set! c _ubyte 0 (list-ref lst 0))
      (ptr-set! c _ubyte 1 (list-ref lst 1))
      (ptr-set! c _ubyte 2 (list-ref lst 2))
      (ptr-set! c _ubyte 3 (list-ref lst 3))
      c)))
;; ============================================================
;; GenMeshPoints — 生成球形点云 (纯 Racket 实现)
;; ============================================================

(define mesh-sizeof (ctype-sizeof _Mesh))
;; _mesh-bytes 的 _list-struct 缺少 C 对齐 padding (boneCount 后的 4B, vaoId 后的 4B)
;; LoadModelFromMesh 读到的 vaoId 是错位的 → 改用 draw-mesh 直接渲染原始 mesh 指针
(define identity-matrix-ptr
  (let ([m (malloc _Matrix 'atomic)])
    (ptr-set! m _float 0 1.0) (ptr-set! m _float 1 0.0) (ptr-set! m _float 2 0.0) (ptr-set! m _float 3 0.0)
    (ptr-set! m _float 4 0.0) (ptr-set! m _float 5 1.0) (ptr-set! m _float 6 0.0) (ptr-set! m _float 7 0.0)
    (ptr-set! m _float 8 0.0) (ptr-set! m _float 9 0.0) (ptr-set! m _float 10 1.0) (ptr-set! m _float 11 0.0)
    (ptr-set! m _float 12 0.0) (ptr-set! m _float 13 0.0) (ptr-set! m _float 14 0.0) (ptr-set! m _float 15 1.0)
    m))

(define default-material (load-material-default))

(define (gen-mesh-points num-points)
  ;; 使用 MemAlloc 分配并零初始化 Mesh 结构体 (与 raylib 内部一致)
  (define mesh-ptr (mem-alloc mesh-sizeof))

  ;; 分配顶点数组 (numPoints * 3 floats)
  (define verts-ptr (mem-alloc (* num-points 3 4)))  ;; 4 = sizeof(float)
  ;; 分配颜色数组 (numPoints * 4 ubytes)
  (define colors-ptr (mem-alloc (* num-points 4)))    ;; 1 = sizeof(ubyte)

  ;; 填充顶点和颜色
  (for ([i (in-range num-points)])
    (let* ([rnd-max 2147483647.0]  ;; RAND_MAX = 2^31 - 1
           [theta (* pi (/ (random) rnd-max))]
           [phi   (* 2.0 pi (/ (random) rnd-max))]
           [r     (* 10.0 (/ (random) rnd-max))]
           [x (* r (sin theta) (cos phi))]
           [y (* r (sin theta) (sin phi))]
           [z (* r (cos theta))]
           [hue (* r 360.0)])
      ;; 设置顶点
      (ptr-set! verts-ptr _float (+ (* i 3) 0) x)
      (ptr-set! verts-ptr _float (+ (* i 3) 1) y)
      (ptr-set! verts-ptr _float (+ (* i 3) 2) z)
      ;; 设置颜色
      (let ([c (color-from-hsv->ptr hue 1.0 1.0)])
        (ptr-set! colors-ptr _ubyte (+ (* i 4) 0) (ptr-ref c _ubyte 0))
        (ptr-set! colors-ptr _ubyte (+ (* i 4) 1) (ptr-ref c _ubyte 1))
        (ptr-set! colors-ptr _ubyte (+ (* i 4) 2) (ptr-ref c _ubyte 2))
        (ptr-set! colors-ptr _ubyte (+ (* i 4) 3) (ptr-ref c _ubyte 3)))))

  ;; 设置 Mesh 字段 (MemAlloc 已零初始化，未设置的字段均为 0/NULL)
  ;; _Mesh: _int vertexCount@byte0, _int triangleCount@byte4,
  ;;         _pointer vertices@byte8, _pointer colors@byte48
  (ptr-set! mesh-ptr _int 0 num-points)     ;; vertexCount
  (ptr-set! mesh-ptr _int 1 1)              ;; triangleCount
  (ptr-set! mesh-ptr _pointer 1 verts-ptr)  ;; vertices (_pointer idx 1 = byte 8)
  (ptr-set! mesh-ptr _pointer 6 colors-ptr) ;; colors (_pointer idx 6 = byte 48)

  ;; 上传到 GPU
  (upload-mesh mesh-ptr #f)

  mesh-ptr)

;; 从 Mesh 指针构造 mesh-bytes list (用于 LoadModelFromMesh 传值)
;; 注意: ptr-ref 的索引是类型元素号, 不是结构体字段号!
;; _Mesh 布局 (bytes):
;;   0-3:   _int vertexCount      → _int idx 0
;;   4-7:   _int triangleCount    → _int idx 1
;;   8-15:  _pointer vertices     → _pointer idx 1
;;   16-23: _pointer texcoords    → _pointer idx 2
;;   24-31: _pointer texcoords2   → _pointer idx 3
;;   32-39: _pointer normals      → _pointer idx 4
;;   40-47: _pointer tangents     → _pointer idx 5
;;   48-55: _pointer colors       → _pointer idx 6
;;   56-63: _pointer indices      → _pointer idx 7
;;   64-67: _int boneCount        → _int idx 16
;;   72-79: _pointer boneIndices  → _pointer idx 9
;;   80-87: _pointer boneWeights  → _pointer idx 10
;;   88-95: _pointer animVertices → _pointer idx 11
;;   96-103:_pointer animNormals   → _pointer idx 12
;;   104-107:_uint vaoId          → _uint idx 26
;;   112-119:_pointer vboId       → _pointer idx 14
(define (mesh-ptr->list mesh-ptr)
  ;; 使用 cpointer 偏移量辅助: 对 mixed-type struct, 用 byte 偏移 + 对应的 ptr-ref 类型
  (list
   ;; 0: vertexCount (_int at byte 0)
   (ptr-ref mesh-ptr _int 0)
   ;; 1: triangleCount (_int at byte 4)
   (ptr-ref mesh-ptr _int 1)
   ;; 2-8: 7 pointers starting at byte 8
   (ptr-ref mesh-ptr _pointer 1)   ;; vertices at byte 8
   (ptr-ref mesh-ptr _pointer 2)   ;; texcoords at byte 16
   (ptr-ref mesh-ptr _pointer 3)   ;; texcoords2 at byte 24
   (ptr-ref mesh-ptr _pointer 4)   ;; normals at byte 32
   (ptr-ref mesh-ptr _pointer 5)   ;; tangents at byte 40
   (ptr-ref mesh-ptr _pointer 6)   ;; colors at byte 48
   (ptr-ref mesh-ptr _pointer 7)   ;; indices at byte 56
   ;; 9: boneCount (_int at byte 64 → _int idx 16)
   (ptr-ref mesh-ptr _int 16)
   ;; 10-13: 4 pointers from byte 72
   (ptr-ref mesh-ptr _pointer 9)   ;; boneIndices at byte 72
   (ptr-ref mesh-ptr _pointer 10)  ;; boneWeights at byte 80
   (ptr-ref mesh-ptr _pointer 11)  ;; animVertices at byte 88
   (ptr-ref mesh-ptr _pointer 12)  ;; animNormals at byte 96
   ;; 14: vaoId (_uint at byte 104 → _uint idx 26)
   (ptr-ref mesh-ptr _uint 26)
   ;; 15: vboId (_pointer at byte 112 → _pointer idx 14)
   (ptr-ref mesh-ptr _pointer 14)))

;; ============================================================
;; 初始化
;; ============================================================

(define screen-width 800)
(define screen-height 450)

(init-window screen-width screen-height
  "raylib [models] example - point rendering")

(define camera (camera3d 3.0 3.0 3.0
                         0.0 0.0 0.0
                         0.0 1.0 0.0
                         45.0 CAMERA-PERSPECTIVE))

(define position (vector3 0.0 0.0 0.0))

(define use-draw-model-points? (box #t))
(define num-points-changed? (box #f))
(define num-points (box 1000))

;; 生成初始点云 (使用 draw-mesh 直接渲染，绕过 _mesh-bytes padding 问题)
(define mesh-ptr (gen-mesh-points (unbox num-points)))

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- Update ----
    (update-camera camera CAMERA-ORBITAL)

    (when (is-key-pressed KEY-SPACE)
      (set-box! use-draw-model-points? (not (unbox use-draw-model-points?))))

    (when (is-key-pressed KEY-UP)
      (let ([n (unbox num-points)])
        (set-box! num-points (if (> (* n 10) 10000000) 10000000 (* n 10)))
        (set-box! num-points-changed? #t)))

    (when (is-key-pressed KEY-DOWN)
      (let ([n (unbox num-points)])
        (set-box! num-points (if (< (quotient n 10) 1000) 1000 (quotient n 10)))
        (set-box! num-points-changed? #t)))

    ;; 更换点云尺寸 (直接替换 mesh-ptr, 无需 model)
    (when (unbox num-points-changed?)
      (set! mesh-ptr (gen-mesh-points (unbox num-points)))
      (set-box! num-points-changed? #f))

    ;; ---- Draw ----
    (begin-drawing)
    (clear-background BLACK)

    (begin-mode-3d camera)

    (if (unbox use-draw-model-points?)
        ;; 使用 DrawModel + rlEnablePointMode (点渲染模式)
        (begin
          (rl-enable-point-mode)
          (rl-disable-backface-culling)
          (draw-mesh mesh-ptr default-material identity-matrix-ptr)
          (rl-enable-backface-culling)
          (rl-disable-point-mode))
        ;; 老方法: 逐个 DrawPoint3D (慢)
        (let* ([n (unbox num-points)]
               [verts-ptr (ptr-ref mesh-ptr _pointer 1)]
               [colors-ptr (ptr-ref mesh-ptr _pointer 6)])
          (for ([i (in-range n)])
            (let ([pos (vector3 (ptr-ref verts-ptr _float (+ (* i 3) 0))
                                (ptr-ref verts-ptr _float (+ (* i 3) 1))
                                (ptr-ref verts-ptr _float (+ (* i 3) 2)))]
                  [col (let ([c (malloc _Color 'atomic)])
                         (ptr-set! c _ubyte 0 (ptr-ref colors-ptr _ubyte (+ (* i 4) 0)))
                         (ptr-set! c _ubyte 1 (ptr-ref colors-ptr _ubyte (+ (* i 4) 1)))
                         (ptr-set! c _ubyte 2 (ptr-ref colors-ptr _ubyte (+ (* i 4) 2)))
                         (ptr-set! c _ubyte 3 (ptr-ref colors-ptr _ubyte (+ (* i 4) 3)))
                         c)])
              (draw-point-3d pos col)))))

    ;; 绘制参考单位球 (线框，黄色)
    (draw-sphere-wires position 1.0 10 10 YELLOW)
    ;; DEBUG: 额外绘制两个彩色球确认渲染管线正常
    (draw-sphere (vector3 2.0 0.0 0.0) 0.2 RED)
    (draw-sphere (vector3 -2.0 0.0 0.0) 0.2 GREEN)
    (draw-sphere (vector3 0.0 2.0 0.0) 0.2 BLUE)

    (end-mode-3d)

    ;; UI 文字
    (draw-text (format "Point Count: ~a" (unbox num-points)) 10 (- screen-height 50) 40 WHITE)
    (draw-text "UP - Increase points" 10 40 20 WHITE)
    (draw-text "DOWN - Decrease points" 10 70 20 WHITE)
    (draw-text "SPACE - Drawing function" 10 100 20 WHITE)

    (if (unbox use-draw-model-points?)
        (draw-text "Using: DrawModelPoints()" 10 130 20 GREEN)
        (draw-text "Using: DrawPoint3D()" 10 130 20 RED))

    (draw-fps 10 10)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
