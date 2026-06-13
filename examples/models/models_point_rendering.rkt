#lang racket/base
;; raylib [models] example - point rendering (Racket FFI)
;; 对应 C: examples/models/models_point_rendering.c
(require "../../raylib/raylib.rkt" ffi/unsafe racket/math)

;; GenMeshPoints — 完全复刻 C 版:
;; 1. mem-alloc 构造 Mesh struct (指针)
;; 2. 填充顶点/颜色数据
;; 3. upload-mesh (指针版, 创建 VAO/VBO)
;; 4. 将 Mesh 转为 _mesh-bytes list (供 load-model-from-mesh)
(define (gen-mesh-points num-points)
  (define verts  (mem-alloc (* num-points 3 4)))
  (define colors (mem-alloc (* num-points 4)))
  (for ([i (in-range num-points)])
    (let* ([theta (* pi (random))] [phi (* 2.0 pi (random))] [r (* 10.0 (random))]
           [x (real->double-flonum (* r (sin theta) (cos phi)))]
           [y (real->double-flonum (* r (sin theta) (sin phi)))]
           [z (real->double-flonum (* r (cos theta)))]
           [hue (* r 36.0)] [col (color-from-hsv hue 1.0 1.0)])
      (ptr-set! verts _float (+ (* i 3) 0) x)
      (ptr-set! verts _float (+ (* i 3) 1) y)
      (ptr-set! verts _float (+ (* i 3) 2) z)
      (ptr-set! colors _ubyte (+ (* i 4) 0) (ptr-ref col _ubyte 0))
      (ptr-set! colors _ubyte (+ (* i 4) 1) (ptr-ref col _ubyte 1))
      (ptr-set! colors _ubyte (+ (* i 4) 2) (ptr-ref col _ubyte 2))
      (ptr-set! colors _ubyte (+ (* i 4) 3) (ptr-ref col _ubyte 3))))
  ;; 构造 Mesh 指针 (mem-alloc 零初始化)
  (define m (mem-alloc (ctype-sizeof _Mesh)))
  (ptr-set! m _int 0 num-points)     ;; vertexCount
  (ptr-set! m _int 1 1)              ;; triangleCount
  (ptr-set! m _pointer 1 verts)      ;; vertices @ byte 8
  (ptr-set! m _pointer 6 colors)     ;; colors   @ byte 48
  ;; upload-mesh → 创建 VAO/VBO (vaoId 变非零)
  (upload-mesh m #f)
  ;; 转为 _mesh-bytes list (读回所有字段)
  (define lst
    (list (ptr-ref m _int 0)         ;; 0: vertexCount
          (ptr-ref m _int 1)         ;; 1: triangleCount
          (ptr-ref m _pointer 1)     ;; 2: vertices
          (ptr-ref m _pointer 2)     ;; 3: texcoords
          (ptr-ref m _pointer 3)     ;; 4: texcoords2
          (ptr-ref m _pointer 4)     ;; 5: normals
          (ptr-ref m _pointer 5)     ;; 6: tangents
          (ptr-ref m _pointer 6)     ;; 7: colors
          (ptr-ref m _pointer 7)     ;; 8: indices
          (ptr-ref m _int 16)        ;; 9: boneCount
          (ptr-ref m _pointer 9)     ;; 10: boneIndices
          (ptr-ref m _pointer 10)    ;; 11: boneWeights
          (ptr-ref m _pointer 11)    ;; 12: animVertices
          (ptr-ref m _pointer 12)    ;; 13: animNormals
          (ptr-ref m _uint 26)       ;; 14: vaoId
          (ptr-ref m _pointer 14)))  ;; 15: vboId
  (values lst verts colors))

(define (draw-model-points model position scale tint)
  (rl-enable-point-mode) (rl-disable-backface-culling)
  (draw-model model position scale tint)
  (rl-enable-backface-culling) (rl-disable-point-mode))

(init-window 800 450 "raylib [models] example - point rendering")
(define cam (camera3d 3.0 3.0 3.0 0.0 0.0 0.0 0.0 1.0 0.0 45.0 CAMERA-PERSPECTIVE))
(define origin (vector3 0.0 0.0 0.0))
(define use-model? (box #t))
(define changed? (box #f))
(define npts (box 1000))
(define-values (mesh-list v c) (gen-mesh-points (unbox npts)))
(define model (load-model-from-mesh mesh-list))
(define tp (malloc _Vector3 'atomic))
(define tc (malloc _Color 'atomic))
(set-target-fps 60)

(let loop ()
  (unless (window-should-close?)
    (update-camera cam CAMERA-ORBITAL)
    (when (is-key-pressed KEY-SPACE) (set-box! use-model? (not (unbox use-model?))))
    (when (is-key-pressed KEY-UP)
      (set-box! npts (min (* (unbox npts) 10) 10000000)) (set-box! changed? #t))
    (when (is-key-pressed KEY-DOWN)
      (set-box! npts (max (quotient (unbox npts) 10) 1000)) (set-box! changed? #t))
    (when (unbox changed?)
      (unload-model model) (mem-free v) (mem-free c)
      (let-values ([(ml v2 c2) (gen-mesh-points (unbox npts))])
        (set! mesh-list ml) (set! v v2) (set! c c2)
        (set! model (load-model-from-mesh ml)))
      (set-box! changed? #f))
    (begin-drawing) (clear-background BLACK) (begin-mode-3d cam)
    (if (unbox use-model?)
        (draw-model-points model origin 1.0 WHITE)
        (for ([i (in-range (unbox npts))])
          (ptr-set! tp _float 0 (ptr-ref v _float (+ (* i 3) 0)))
          (ptr-set! tp _float 1 (ptr-ref v _float (+ (* i 3) 1)))
          (ptr-set! tp _float 2 (ptr-ref v _float (+ (* i 3) 2)))
          (ptr-set! tc _ubyte 0 (ptr-ref c _ubyte (+ (* i 4) 0)))
          (ptr-set! tc _ubyte 1 (ptr-ref c _ubyte (+ (* i 4) 1)))
          (ptr-set! tc _ubyte 2 (ptr-ref c _ubyte (+ (* i 4) 2)))
          (ptr-set! tc _ubyte 3 (ptr-ref c _ubyte (+ (* i 4) 3)))
          (draw-point-3d tp tc)))
    (draw-sphere-wires origin 1.0 10 10 YELLOW) (end-mode-3d)
    (draw-text (format "Points: ~a" (unbox npts)) 10 (- 450 50) 40 WHITE)
    (draw-text "UP/DOWN - Count  SPACE - Method" 10 40 20 WHITE)
    (if (unbox use-model?)
        (draw-text "Using: DrawModelPoints()" 10 70 20 GREEN)
        (draw-text "Using: DrawPoint3D()" 10 70 20 RED))
    (draw-fps 10 10) (end-drawing) (loop)))
(unload-model model) (mem-free v) (mem-free c) (close-window)
