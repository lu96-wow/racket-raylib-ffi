#lang racket/base

;; raylib 预定义常量测试
;; 无需 OpenGL 上下文

(require "../helper.rkt"
         (prefix-in lib: "../../raylib/raylib.rkt"))

(printf "~n========================================~n")
(printf "  预定义常量测试~n")
(printf "========================================~n")

;; ============================================================
;; 预定义颜色
;; ============================================================

(test-section "预定义颜色")

(define (test-colors)
  ;; 颜色值来自 raylib.h
  (assert-color= lib:RAYWHITE   245 245 245 255)
  (assert-color= lib:RED          230 41  55 255)
  (assert-color= lib:GREEN          0 228  48 255)
  (assert-color= lib:BLUE          0 121 241 255)
  (assert-color= lib:BLACK         0   0   0 255)
  (assert-color= lib:WHITE       255 255 255 255)
  (assert-color= lib:BLANK         0   0   0   0)
  (assert-color= lib:YELLOW      253 249   0 255)
  (assert-color= lib:ORANGE      255 161   0 255)
  (assert-color= lib:PURPLE      200 122 255 255)
  (assert-color= lib:MAGENTA     255   0 255 255)
  (assert-color= lib:SKYBLUE     102 191 255 255)
  (test-pass! "26 个预定义颜色常量验证"))

(test-colors)

;; ============================================================
;; 键盘键值
;; ============================================================

(test-section "键盘键值")

(define (test-keys)
  (assert-= lib:KEY-NULL 0)
  (assert-= lib:KEY-SPACE 32)
  (assert-= lib:KEY-ESCAPE 256)
  (assert-= lib:KEY-ENTER 257)
  (assert-= lib:KEY-TAB 258)
  (assert-= lib:KEY-BACKSPACE 259)
  (assert-= lib:KEY-INSERT 260)
  (assert-= lib:KEY-DELETE 261)
  (assert-= lib:KEY-RIGHT 262)
  (assert-= lib:KEY-LEFT 263)
  (assert-= lib:KEY-DOWN 264)
  (assert-= lib:KEY-UP 265)
  (assert-= lib:KEY-A 65)
  (assert-= lib:KEY-Z 90)
  (assert-= lib:KEY-ZERO 48)
  (assert-= lib:KEY-NINE 57)
  (assert-= lib:KEY-F1 290)
  (assert-= lib:KEY-F12 301)
  (assert-= lib:KEY-LEFT-SHIFT 340)
  (assert-= lib:KEY-RIGHT-CONTROL 345)
  (test-pass! "键盘键值常量验证"))

(test-keys)

;; ============================================================
;; 鼠标按钮
;; ============================================================

(test-section "鼠标按钮")

(define (test-mouse-buttons)
  (assert-= lib:MOUSE-BUTTON-LEFT 0)
  (assert-= lib:MOUSE-BUTTON-RIGHT 1)
  (assert-= lib:MOUSE-BUTTON-MIDDLE 2)
  (assert-= lib:MOUSE-BUTTON-FORWARD 5)
  (assert-= lib:MOUSE-BUTTON-BACK 6)
  (test-pass! "鼠标按钮常量验证"))

(test-mouse-buttons)

;; ============================================================
;; 窗口标志
;; ============================================================

(test-section "窗口标志")

(define (test-flags)
  (assert-= lib:FLAG-VSYNC-HINT 64)
  (assert-= lib:FLAG-FULLSCREEN-MODE 2)
  (assert-= lib:FLAG-WINDOW-RESIZABLE 4)
  (assert-= lib:FLAG-WINDOW-UNDECORATED 8)
  (assert-= lib:FLAG-WINDOW-HIDDEN 128)
  (assert-= lib:FLAG-WINDOW-MINIMIZED 512)
  (assert-= lib:FLAG-WINDOW-MAXIMIZED 1024)
  (assert-= lib:FLAG-WINDOW-HIGHDPI 8192)
  (assert-= lib:FLAG-WINDOW-ALWAYS-RUN 16384)
  (assert-= lib:FLAG-MSAA-4X-HINT 16)
  (assert-= lib:FLAG-BORDERLESS-WINDOWED-MODE 32768)
  (test-pass! "窗口标志常量验证"))

(test-flags)

;; ============================================================
;; 相机 / 其他常量
;; ============================================================

(test-section "相机 / 其它常量")

(define (test-other)
  (assert-= lib:CAMERA-CUSTOM 0)
  (assert-= lib:CAMERA-FREE 1)
  (assert-= lib:CAMERA-ORBITAL 2)
  (assert-= lib:CAMERA-FIRST-PERSON 3)
  (assert-= lib:CAMERA-THIRD-PERSON 4)
  (assert-= lib:CAMERA-PERSPECTIVE 0)
  (assert-= lib:CAMERA-ORTHOGRAPHIC 1)
  (assert-= lib:TEXTURE-FILTER-BILINEAR 1)
  (assert-= lib:SHADER-UNIFORM-FLOAT 0)
  (assert-= lib:SHADER-UNIFORM-INT 4)
  (assert-= lib:GESTURE-TAP 1)
  (assert-= lib:GESTURE-DOUBLETAP 2)
  (assert-= lib:GESTURE-HOLD 4)
  (assert-= lib:GESTURE-DRAG 8)
  (assert-= lib:GESTURE-PINCH-IN 256)
  (assert-= lib:GESTURE-PINCH-OUT 512)
  (assert-= lib:GAMEPAD-BUTTON-RIGHT-FACE-DOWN 7)
  (assert-= lib:GAMEPAD-AXIS-RIGHT-X 2)
  (assert-= lib:MATERIAL-MAP-DIFFUSE 0)
  (test-pass! "相机/手势/手柄/着色器常量验证"))

(test-other)

(printf "~n常量测试完成!~n")
