#lang racket/base

;; raylib [core] example - directory files (Racket FFI 翻译)
;;
;; 对应 C: examples/core/core_directory_files.c
;;
;; 演示: 文件目录浏览器 (替代 raygui, 使用原生 raylib 绘制)
;;   点击 "<" 按钮返回上级目录
;;   点击文件条目进入子目录或选择文件
;;   过滤: DIRS*;.png;.c

(require "../../raylib/raylib.rkt"
         racket/format)

;; ============================================================
;; 常量
;; ============================================================

(define SCREEN-WIDTH  800)
(define SCREEN-HEIGHT 450)
(define FILE-FILTER "DIRS*;.png;.c")
(define LIST-ITEM-HEIGHT 22)
(define VISIBLE-ITEMS 18)

;; ============================================================
;; 初始化
;; ============================================================

(init-window SCREEN-WIDTH SCREEN-HEIGHT
  "raylib [core] example - directory files")

(define directory (box (get-working-directory)))
(define files (box (load-directory-files-ex (unbox directory) FILE-FILTER #f)))

(define scroll-idx (box 0))
(define item-active (box -1))

(set-target-fps 60)

;; ============================================================
;; 辅助: 绘制按钮
;; ============================================================

(define (draw-button x y w h text color)
  (define rect (rectangle (exact->inexact x) (exact->inexact y)
                          (exact->inexact w) (exact->inexact h)))
  (draw-rectangle-rec rect color)
  (draw-text text (+ x 4) (+ y 4) 14 WHITE)
  (set-rectangle-x! rect 0.0)  ;; clean up temp allocation
  rect)

(define (button-pressed? rect)
  (and (check-collision-point-rec (get-mouse-position) rect)
       (is-mouse-button-pressed MOUSE-BUTTON-LEFT)))

;; ============================================================
;; 刷新文件列表
;; ============================================================

(define (reload-files!)
  (set-box! files (load-directory-files-ex (unbox directory) FILE-FILTER #f))
  (set-box! scroll-idx 0)
  (set-box! item-active -1))

;; ============================================================
;; 主循环
;; ============================================================

(let loop ()
  (unless (window-should-close?)
    (define file-list (unbox files))
    (define file-count (length file-list))
    (define cur-dir (unbox directory))

    ;; === 更新 ===

    ;; 返回按钮
    (define back-btn (rectangle 40 10 48 28))
    (when (button-pressed? back-btn)
      (set-box! directory (get-prev-directory-path cur-dir))
      (reload-files!))

    ;; 点击文件条目
    (define mouse-pos (get-mouse-position))
    (define mouse-clicked? (is-mouse-button-pressed MOUSE-BUTTON-LEFT))

    (when mouse-clicked?
      (let ([click-y (inexact->exact (floor (vector2-y mouse-pos)))])
        ;; 计算点击了哪个条目
        (define clicked-idx
          (for/or ([i (in-range (min file-count VISIBLE-ITEMS))])
            (let ([item-y (+ 50 (* i LIST-ITEM-HEIGHT))])
              (and (>= (vector2-x mouse-pos) 0)
                   (< (vector2-x mouse-pos) SCREEN-WIDTH)
                   (>= click-y item-y)
                   (< click-y (+ item-y LIST-ITEM-HEIGHT))
                   (+ (unbox scroll-idx) i)))))
        (when clicked-idx
          (set-box! item-active clicked-idx)
          (define selected-path (list-ref file-list clicked-idx))
          (when (directory-exists? selected-path)
            (set-box! directory selected-path)
            (reload-files!)))))

    ;; 滚轮滚动
    (define wheel (inexact->exact (floor (get-mouse-wheel-move))))
    (unless (zero? wheel)
      (set-box! scroll-idx (max 0 (min (- file-count VISIBLE-ITEMS)
                                       (- (unbox scroll-idx) wheel)))))

    ;; === 绘制 ===
    (begin-drawing)
    (clear-background RAYWHITE)

    ;; 返回按钮
    (draw-rectangle-rec back-btn (color 100 100 100))
    (draw-text "<" 55 14 14 WHITE)

    ;; 目录路径
    (draw-text cur-dir (+ 40 48 10) 14 14 (color 50 50 50))

    ;; 文件列表
    (define (item-color i)
      (cond [(= i (unbox item-active)) (color 200 200 255)]
            [(even? i) (color 245 245 255)]
            [else RAYWHITE]))

    (for ([i (in-range (min file-count VISIBLE-ITEMS))])
      (define idx (+ (unbox scroll-idx) i))
      (define path (list-ref file-list idx))
      (define y (+ 50 (* i LIST-ITEM-HEIGHT)))
      (define is-dir? (directory-exists? path))

      ;; 条目背景
      (draw-rectangle 0 y SCREEN-WIDTH LIST-ITEM-HEIGHT (item-color idx))

      ;; 条目图标 + 文件名
      (define display-name
        (if is-dir?
          (string-append "  " path)
          path))
      (draw-text display-name 5 (+ y 3) 14
                 (if is-dir? (color 0 100 200) (color 50 50 50))))

    ;; 提示
    (draw-text (format "~a files/dirs | scroll to browse" file-count)
               10 (- SCREEN-HEIGHT 20) 10 (color 100 100 100))

    (end-drawing)
    (loop)))

;; ============================================================
;; 清理
;; ============================================================

(close-window)
