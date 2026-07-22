#lang racket/base

;; raylib [textures] example - framebuffer rendering (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_framebuffer_rendering.c
;;
;; 演示:
;;   1. 用 RenderTexture 做离屏渲染（分左右两块）
;;   2. 左侧: 观察者相机 (observer) 自由漫游，能看到 3D 世界和 subject 相机的视锥体
;;   3. 右侧: 被观察者相机 (subject) 轨道旋转，显示 3D 世界
;;   4. 将两个 render texture 都绘制到屏幕上，外加裁剪区域放大预览
;;
;; 控制:
;;   WASD + 鼠标 — 移动观察者相机
;;   鼠标滚轮 — 缩放观察者相机
;;   R — 重置观察者相机目标
;;   鼠标左键拖拽 — 轨道旋转 subject 相机

(require racket/math
         "../../raylib/raylib.rkt")

;; ============================================================
;; 模块函数: 绘制相机视锥体（棱锥）
;; ============================================================

;; 在 3D 空间中绘制 subject 相机的视锥体，展示其在世界中的可见范围
;; camera — 要绘制的相机指针
;; aspect — 纹理长宽比
;; color  — 线条颜色
(define (draw-camera-prism! camera aspect color)
  ;; 计算相机到目标的距离，用作透视投影的 far 参数
  (let* ([px (camera3d-pos-x camera)]
         [py (camera3d-pos-y camera)]
         [pz (camera3d-pos-z camera)]
         [tx (camera3d-tar-x camera)]
         [ty (camera3d-tar-y camera)]
         [tz (camera3d-tar-z camera)]
         [fovy (camera3d-fovy camera)]
         [length (sqrt (+ (* (- px tx) (- px tx))
                          (* (- py ty) (- py ty))
                          (* (- pz tz) (- pz tz))))]

         ;; NDC 空间中位于目标远平面的 4 个角
         [plane-ndc (list (vector -1.0 -1.0 1.0)   ; 左下
                          (vector  1.0 -1.0 1.0)   ; 右下
                          (vector  1.0  1.0 1.0)   ; 右上
                          (vector -1.0  1.0 1.0))] ; 左上

         ;; 构建矩阵: view × proj 的逆矩阵，用于 NDC → 世界坐标
         [view (get-camera-matrix camera)]
         [proj (matrix-perspective (* fovy (/ pi 180.0)) aspect 0.05 length)]
         [view-proj (matrix-multiply view proj)]
         [inv-view-proj (matrix-invert view-proj)]

         ;; 提取逆矩阵 16 个分量
         ;; 注意: raylib Matrix 是 column-major 内存布局
         ;;   C 结构: m0,m4,m8,m12, m1,m5,m9,m13, m2,m6,m10,m14, m3,m7,m11,m15
         ;;   list-ref 索引 → 矩阵元素:
         [m0  (list-ref inv-view-proj 0)]   ; idx 0  → m0
         [m4  (list-ref inv-view-proj 1)]   ; idx 1  → m4
         [m8  (list-ref inv-view-proj 2)]   ; idx 2  → m8
         [m12 (list-ref inv-view-proj 3)]   ; idx 3  → m12
         [m1  (list-ref inv-view-proj 4)]   ; idx 4  → m1
         [m5  (list-ref inv-view-proj 5)]   ; idx 5  → m5
         [m9  (list-ref inv-view-proj 6)]   ; idx 6  → m9
         [m13 (list-ref inv-view-proj 7)]   ; idx 7  → m13
         [m2  (list-ref inv-view-proj 8)]   ; idx 8  → m2
         [m6  (list-ref inv-view-proj 9)]   ; idx 9  → m6
         [m10 (list-ref inv-view-proj 10)]  ; idx 10 → m10
         [m14 (list-ref inv-view-proj 11)]  ; idx 11 → m14
         [m3  (list-ref inv-view-proj 12)]  ; idx 12 → m3
         [m7  (list-ref inv-view-proj 13)]  ; idx 13 → m7
         [m11 (list-ref inv-view-proj 14)]  ; idx 14 → m11
         [m15 (list-ref inv-view-proj 15)]  ; idx 15 → m15

         ;; 将 4 个 NDC 角变换到世界空间
         [corners
          (for/list ([ndc (in-list plane-ndc)])
            (let* ([x (vector-ref ndc 0)]
                   [y (vector-ref ndc 1)]
                   [z (vector-ref ndc 2)]
                   ;; 齐次坐标变换: (x,y,z,1) × invViewProj
                   [vx (+ (* m0 x) (* m4 y) (* m8  z) m12)]
                   [vy (+ (* m1 x) (* m5 y) (* m9  z) m13)]
                   [vz (+ (* m2 x) (* m6 y) (* m10 z) m14)]
                   [vw (+ (* m3 x) (* m7 y) (* m11 z) m15)])
              ;; 透视除法 → 世界坐标
              (vector3 (/ vx vw) (/ vy vw) (/ vz vw))))]

         [cam-pos (vector3 px py pz)])

    ;; 绘制远平面四边形
    (draw-line-3d (list-ref corners 0) (list-ref corners 1) color)
    (draw-line-3d (list-ref corners 1) (list-ref corners 2) color)
    (draw-line-3d (list-ref corners 2) (list-ref corners 3) color)
    (draw-line-3d (list-ref corners 3) (list-ref corners 0) color)

    ;; 从相机位置到 4 个角的棱线
    (for ([i (in-range 4)])
      (draw-line-3d cam-pos (list-ref corners i) color))))

;; ============================================================
;; 主程序入口
;; ============================================================

;; ---- 常量 ----
(define screen-width  800)
(define screen-height 450)
(define split-width   (/ screen-width 2))

(init-window screen-width screen-height
             "raylib [textures] example - framebuffer rendering")

;; ---- 相机设置 ----

;; subject 相机: 被观察的 3D 世界视图（轨道旋转模式）
(define subject-camera
  (camera3d 5.0 5.0 5.0    ; position
            0.0 0.0 0.0    ; target
            0.0 1.0 0.0    ; up
            45.0 CAMERA-PERSPECTIVE))

;; observer 相机: 观察 subject 相机和 3D 世界的自由相机（自由漫游模式）
(define observer-camera
  (camera3d 10.0 10.0 10.0  ; position
            0.0  0.0  0.0   ; target
            0.0  1.0  0.0   ; up
            45.0 CAMERA-PERSPECTIVE))

;; ---- 渲染纹理设置 ----
;; RenderTexture 返回 11 元素 list:
;;   (rt-id tex-id tex-w tex-h tex-mip tex-fmt dep-id dep-w dep-h dep-mip dep-fmt)
;; 纹理部分是索引 1..5: (tex-id width height mipmaps format)

(define observer-target (load-render-texture split-width screen-height))

(define observer-src
  (rectangle 0.0 0.0
             (exact->inexact (list-ref observer-target 2))           ;; width
             (- (exact->inexact (list-ref observer-target 3)))))     ;; -height (OpenGL Y 翻转)

(define observer-dst
  (rectangle 0.0 0.0
             (exact->inexact split-width)
             (exact->inexact screen-height)))

(define subject-target (load-render-texture split-width screen-height))

(define subject-src
  (rectangle 0.0 0.0
             (exact->inexact (list-ref subject-target 2))            ;; width
             (- (exact->inexact (list-ref subject-target 3)))))      ;; -height

(define subject-dst
  (rectangle (exact->inexact split-width) 0.0
             (exact->inexact split-width)
             (exact->inexact screen-height)))

;; 纹理长宽比（用于在 observer 视图中绘制 subject 相机的视锥体）
(define texture-aspect-ratio
  (/ (exact->inexact (list-ref subject-target 2))
     (exact->inexact (list-ref subject-target 3))))

;; ---- 裁剪预览矩形 ----
(define capture-size 128.0)

(define crop-src
  (let ([tw (exact->inexact (list-ref subject-target 2))]
        [th (exact->inexact (list-ref subject-target 3))])
    (rectangle (/ (- tw capture-size) 2.0)
               (/ (- th capture-size) 2.0)
               capture-size
               (- capture-size))))    ;; 负高度 = Y 轴翻转

(define crop-dst
  (rectangle (+ (exact->inexact split-width) 20.0)
             20.0
             capture-size
             capture-size))

;; ---- 辅助函数: 从 RenderTexture 提取 Texture2D ----
;; RenderTexture list: (rt-id tex-id w h mip fmt dep-id ...) 共 11 元素
;; Texture2D list:     (id w h mip fmt)
(define (rt->texture rt)
  (list (render-texture-tex-id rt)  ;; id
        (render-texture-tex-width rt)  ;; width
        (render-texture-tex-height rt)  ;; height
        (render-texture-tex-mipmaps rt)  ;; mipmaps
        (render-texture-tex-format rt)));; format

(set-target-fps 60)
(disable-cursor)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    ;; ---- 更新 ----
    (update-camera observer-camera CAMERA-FREE)
    (update-camera subject-camera CAMERA-ORBITAL)

    ;; R 键重置 observer 相机目标
    (when (is-key-pressed KEY-R)
      (set-camera3d-tar-x! observer-camera 0.0)
      (set-camera3d-tar-y! observer-camera 0.0)
      (set-camera3d-tar-z! observer-camera 0.0))

    ;; ---- 构建左侧: observer 视角渲染纹理 ----
    (begin-texture-mode observer-target)
    (clear-background RAYWHITE)

    (begin-mode-3d observer-camera)
    (draw-grid 10 1.0)
    (draw-cube (vector3 0.0 0.0 0.0) 2.0 2.0 2.0 GOLD)
    (draw-cube-wires (vector3 0.0 0.0 0.0) 2.0 2.0 2.0 PINK)
    (draw-camera-prism! subject-camera texture-aspect-ratio GREEN)
    (end-mode-3d)

    (draw-text "Observer View" 10
               (- (list-ref observer-target 3) 30) 20 BLACK)
    (draw-text "WASD + Mouse to Move" 10 10 20 DARKGRAY)
    (draw-text "Scroll to Zoom" 10 30 20 DARKGRAY)
    (draw-text "R to Reset Observer Target" 10 50 20 DARKGRAY)
    (end-texture-mode)

    ;; ---- 构建右侧: subject 视角渲染纹理 ----
    (begin-texture-mode subject-target)
    (clear-background RAYWHITE)

    (begin-mode-3d subject-camera)
    (draw-cube (vector3 0.0 0.0 0.0) 2.0 2.0 2.0 GOLD)
    (draw-cube-wires (vector3 0.0 0.0 0.0) 2.0 2.0 2.0 PINK)
    (draw-grid 10 1.0)
    (end-mode-3d)

    ;; 在 subject 视图上绘制裁剪区域参考框
    (let* ([tw (exact->inexact (list-ref subject-target 2))]
           [th (exact->inexact (list-ref subject-target 3))])
      (draw-rectangle-lines (inexact->exact (/ (- tw capture-size) 2.0))
                            (inexact->exact (/ (- th capture-size) 2.0))
                            (inexact->exact capture-size)
                            (inexact->exact capture-size) GREEN))

    (draw-text "Subject View" 10
               (- (list-ref subject-target 3) 30) 20 BLACK)
    (end-texture-mode)

    ;; ---- 绘制到屏幕 ----
    (begin-drawing)
    (clear-background BLACK)

    ;; 左侧: observer 纹理
    (draw-texture-pro (rt->texture observer-target)
                      observer-src observer-dst
                      (vector2 0.0 0.0) 0.0 WHITE)

    ;; 右侧: subject 纹理
    (draw-texture-pro (rt->texture subject-target)
                      subject-src subject-dst
                      (vector2 0.0 0.0) 0.0 WHITE)

    ;; 裁剪区域放大预览（叠加在右侧上方）
    (draw-texture-pro (rt->texture subject-target)
                      crop-src crop-dst
                      (vector2 0.0 0.0) 0.0 WHITE)
    (draw-rectangle-lines-ex crop-dst 2.0 BLACK)

    ;; 分隔线
    (draw-line split-width 0 split-width screen-height BLACK)

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(unload-render-texture observer-target)
(unload-render-texture subject-target)
(close-window)
