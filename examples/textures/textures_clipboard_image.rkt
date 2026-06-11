#lang racket/base

;; raylib [textures] example - clipboard image (Racket FFI 翻译)
;;
;; 对应 C: examples/textures/textures_clipboard_image.c
;;
;; 演示: 从剪贴板粘贴图像
;;   按 Ctrl+V 从剪贴板粘贴图像，按 R 重置

(require "../../raylib/raylib.rkt")

;; ============================================================
;; 常量
;; ============================================================

(define screen-width 800)
(define screen-height 450)
(define max-texture-collection 20)

;; ============================================================
;; 初始化
;; ============================================================

(init-window screen-width screen-height
  "raylib [textures] example - clipboard image")

;; 用 list 存储已粘贴的纹理及其位置
;; 每个元素是 (texture pos-x pos-y)
(define collection '())
(define current-collection-index 0)

(set-target-fps 60)

;; ============================================================
;; 主循环
;; ============================================================

(let loop ([collection collection]
           [current-index current-collection-index])
  (unless (window-should-close?)
    ;; 更新
    (let-values ([(collection current-index)
                  (cond
                    ;; 按 R 重置
                    [(is-key-pressed KEY-R)
                     ;; 卸载所有纹理
                     (for-each (λ (item) (unload-texture (car item))) collection)
                     (values '() 0)]

                    ;; Ctrl+V 从剪贴板粘贴
                    [(and (is-key-down KEY-LEFT-CONTROL)
                          (is-key-pressed KEY-V)
                          (< current-index max-texture-collection))
                     (let ([img (get-clipboard-image)])
                       (if (is-image-valid img)
                           (let* ([tex (load-texture-from-image img)]
                                  [pos (get-mouse-position)]
                                  [new-collection (append collection
                                                    (list (list tex (vector2-x pos) (vector2-y pos))))])
                             (unload-image img)
                             (values new-collection (+ current-index 1)))
                           (begin
                             (values collection current-index))))]

                    [else (values collection current-index)])])

      ;; 绘制
      (begin-drawing)
      (clear-background RAYWHITE)

      ;; 绘制所有已粘贴的纹理（以鼠标位置为中心）
      (for-each (λ (item)
                  (let ([tex (list-ref item 0)]
                        [px  (list-ref item 1)]
                        [py  (list-ref item 2)])
                    (when (is-texture-valid tex)
                      (let ([w (list-ref tex 1)]
                            [h (list-ref tex 2)])
                        (draw-texture-pro tex
                                          (rectangle 0 0 w h)
                                          (rectangle px py w h)
                                          (vector2 (/ w 2.0) (/ h 2.0))
                                          0.0
                                          WHITE)))))
                collection)

      ;; 绘制状态栏
      (draw-rectangle 0 0 screen-width 40 BLACK)
      (draw-text "Clipboard Image - Ctrl+V to Paste and R to Reset "
                 120 10 20 LIGHTGRAY)

      (end-drawing)
      (loop collection current-index))))

;; ============================================================
;; 清理
;; ============================================================

(for-each (λ (item) (unload-texture (car item))) collection)
(close-window)
