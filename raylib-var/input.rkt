#lang racket/base

;; raylib-var/input.rkt — 输入设备常量 (键盘/鼠标/手柄/手势)

;; ============================================================
;; 键盘键值
;; ============================================================

(define KEY-NULL          0)
(define KEY-APOSTROPHE    39) (define KEY-COMMA   44)
(define KEY-MINUS         45) (define KEY-PERIOD  46)
(define KEY-SLASH         47)
(define KEY-ZERO          48) (define KEY-ONE     49)
(define KEY-TWO           50) (define KEY-THREE   51)
(define KEY-FOUR          52) (define KEY-FIVE    53)
(define KEY-SIX           54) (define KEY-SEVEN   55)
(define KEY-EIGHT         56) (define KEY-NINE    57)
(define KEY-SEMICOLON     59) (define KEY-EQUAL   61)
(define KEY-A             65) (define KEY-B       66)
(define KEY-C             67) (define KEY-D       68)
(define KEY-E             69) (define KEY-F       70)
(define KEY-G             71) (define KEY-H       72)
(define KEY-I             73) (define KEY-J       74)
(define KEY-K             75) (define KEY-L       76)
(define KEY-M             77) (define KEY-N       78)
(define KEY-O             79) (define KEY-P       80)
(define KEY-Q             81) (define KEY-R       82)
(define KEY-S             83) (define KEY-T       84)
(define KEY-U             85) (define KEY-V       86)
(define KEY-W             87) (define KEY-X       88)
(define KEY-Y             89) (define KEY-Z       90)
(define KEY-LEFT-BRACKET  91) (define KEY-BACKSLASH     92)
(define KEY-RIGHT-BRACKET 93) (define KEY-GRAVE         96)
(define KEY-SPACE         32) (define KEY-ESCAPE       256)
(define KEY-ENTER         257)(define KEY-TAB         258)
(define KEY-BACKSPACE     259)(define KEY-INSERT      260)
(define KEY-DELETE        261)(define KEY-RIGHT       262)
(define KEY-LEFT          263)(define KEY-DOWN        264)
(define KEY-UP            265)(define KEY-PAGE-UP     266)
(define KEY-PAGE-DOWN     267)(define KEY-HOME        268)
(define KEY-END           269)
(define KEY-CAPS-LOCK     280)(define KEY-SCROLL-LOCK 281)
(define KEY-NUM-LOCK      282)(define KEY-PRINT-SCREEN 283)
(define KEY-PAUSE         284)
(define KEY-F1            290)(define KEY-F2          291)
(define KEY-F3            292)(define KEY-F4          293)
(define KEY-F5            294)(define KEY-F6          295)
(define KEY-F7            296)(define KEY-F8          297)
(define KEY-F9            298)(define KEY-F10         299)
(define KEY-F11           300)(define KEY-F12         301)
(define KEY-LEFT-SHIFT    340)
(define KEY-LEFT-CONTROL  341)(define KEY-LEFT-ALT   342)
(define KEY-LEFT-SUPER    343)(define KEY-RIGHT-SHIFT 344)
(define KEY-RIGHT-CONTROL 345)(define KEY-RIGHT-ALT   346)
(define KEY-RIGHT-SUPER   347)(define KEY-KB-MENU    348)

;; ============================================================
;; 鼠标按钮
;; ============================================================

(define MOUSE-BUTTON-LEFT      0)
(define MOUSE-BUTTON-RIGHT     1)
(define MOUSE-BUTTON-MIDDLE    2)
(define MOUSE-BUTTON-SIDE      3)
(define MOUSE-BUTTON-EXTRA     4)
(define MOUSE-BUTTON-FORWARD   5)
(define MOUSE-BUTTON-BACK      6)

;; ============================================================
;; 手势
;; ============================================================

(define GESTURE-NONE        0)  (define GESTURE-TAP        1)
(define GESTURE-DOUBLETAP   2)  (define GESTURE-HOLD       4)
(define GESTURE-DRAG        8)  (define GESTURE-SWIPE-RIGHT 16)
(define GESTURE-SWIPE-LEFT  32) (define GESTURE-SWIPE-UP   64)
(define GESTURE-SWIPE-DOWN  128)(define GESTURE-PINCH-IN  256)
(define GESTURE-PINCH-OUT   512)

;; ============================================================
;; 手柄按钮
;; ============================================================

(define GAMEPAD-BUTTON-UNKNOWN          0)
(define GAMEPAD-BUTTON-LEFT-FACE-UP     1)
(define GAMEPAD-BUTTON-LEFT-FACE-RIGHT  2)
(define GAMEPAD-BUTTON-LEFT-FACE-DOWN   3)
(define GAMEPAD-BUTTON-LEFT-FACE-LEFT   4)
(define GAMEPAD-BUTTON-RIGHT-FACE-UP    5)
(define GAMEPAD-BUTTON-RIGHT-FACE-RIGHT 6)
(define GAMEPAD-BUTTON-RIGHT-FACE-DOWN  7)
(define GAMEPAD-BUTTON-RIGHT-FACE-LEFT  8)
(define GAMEPAD-BUTTON-LEFT-TRIGGER-1   9)
(define GAMEPAD-BUTTON-LEFT-TRIGGER-2   10)
(define GAMEPAD-BUTTON-RIGHT-TRIGGER-1  11)
(define GAMEPAD-BUTTON-RIGHT-TRIGGER-2  12)
(define GAMEPAD-BUTTON-MIDDLE-LEFT      13)
(define GAMEPAD-BUTTON-MIDDLE           14)
(define GAMEPAD-BUTTON-MIDDLE-RIGHT     15)
(define GAMEPAD-BUTTON-LEFT-THUMB       16)
(define GAMEPAD-BUTTON-RIGHT-THUMB      17)

;; ============================================================
;; 手柄轴
;; ============================================================

(define GAMEPAD-AXIS-LEFT-X        0)
(define GAMEPAD-AXIS-LEFT-Y        1)
(define GAMEPAD-AXIS-RIGHT-X       2)
(define GAMEPAD-AXIS-RIGHT-Y       3)
(define GAMEPAD-AXIS-LEFT-TRIGGER  4)
(define GAMEPAD-AXIS-RIGHT-TRIGGER 5)

(provide
 KEY-NULL KEY-SPACE KEY-ESCAPE KEY-ENTER KEY-TAB
 KEY-BACKSPACE KEY-INSERT KEY-DELETE
 KEY-RIGHT KEY-LEFT KEY-DOWN KEY-UP
 KEY-PAGE-UP KEY-PAGE-DOWN KEY-HOME KEY-END
 KEY-CAPS-LOCK KEY-SCROLL-LOCK KEY-NUM-LOCK
 KEY-PRINT-SCREEN KEY-PAUSE
 KEY-LEFT-SHIFT KEY-LEFT-CONTROL KEY-LEFT-ALT KEY-LEFT-SUPER
 KEY-RIGHT-SHIFT KEY-RIGHT-CONTROL KEY-RIGHT-ALT KEY-RIGHT-SUPER
 KEY-KB-MENU
 KEY-F1 KEY-F2 KEY-F3 KEY-F4 KEY-F5 KEY-F6
 KEY-F7 KEY-F8 KEY-F9 KEY-F10 KEY-F11 KEY-F12
 KEY-A KEY-B KEY-C KEY-D KEY-E KEY-F KEY-G
 KEY-H KEY-I KEY-J KEY-K KEY-L KEY-M KEY-N
 KEY-O KEY-P KEY-Q KEY-R KEY-S KEY-T KEY-U
 KEY-V KEY-W KEY-X KEY-Y KEY-Z
 KEY-ZERO KEY-ONE KEY-TWO KEY-THREE KEY-FOUR
 KEY-FIVE KEY-SIX KEY-SEVEN KEY-EIGHT KEY-NINE
 KEY-APOSTROPHE KEY-COMMA KEY-MINUS KEY-PERIOD KEY-SLASH
 KEY-SEMICOLON KEY-EQUAL KEY-GRAVE
 KEY-LEFT-BRACKET KEY-BACKSLASH KEY-RIGHT-BRACKET

 MOUSE-BUTTON-LEFT MOUSE-BUTTON-RIGHT MOUSE-BUTTON-MIDDLE
 MOUSE-BUTTON-SIDE MOUSE-BUTTON-EXTRA
 MOUSE-BUTTON-FORWARD MOUSE-BUTTON-BACK

 GESTURE-NONE GESTURE-TAP GESTURE-DOUBLETAP
 GESTURE-HOLD GESTURE-DRAG
 GESTURE-SWIPE-RIGHT GESTURE-SWIPE-LEFT
 GESTURE-SWIPE-UP GESTURE-SWIPE-DOWN
 GESTURE-PINCH-IN GESTURE-PINCH-OUT

 GAMEPAD-BUTTON-UNKNOWN GAMEPAD-BUTTON-LEFT-FACE-UP
 GAMEPAD-BUTTON-LEFT-FACE-RIGHT GAMEPAD-BUTTON-LEFT-FACE-DOWN
 GAMEPAD-BUTTON-LEFT-FACE-LEFT GAMEPAD-BUTTON-RIGHT-FACE-UP
 GAMEPAD-BUTTON-RIGHT-FACE-RIGHT GAMEPAD-BUTTON-RIGHT-FACE-DOWN
 GAMEPAD-BUTTON-RIGHT-FACE-LEFT
 GAMEPAD-BUTTON-LEFT-TRIGGER-1 GAMEPAD-BUTTON-LEFT-TRIGGER-2
 GAMEPAD-BUTTON-RIGHT-TRIGGER-1 GAMEPAD-BUTTON-RIGHT-TRIGGER-2
 GAMEPAD-BUTTON-MIDDLE-LEFT GAMEPAD-BUTTON-MIDDLE
 GAMEPAD-BUTTON-MIDDLE-RIGHT
 GAMEPAD-BUTTON-LEFT-THUMB GAMEPAD-BUTTON-RIGHT-THUMB
 GAMEPAD-AXIS-LEFT-X GAMEPAD-AXIS-LEFT-Y
 GAMEPAD-AXIS-RIGHT-X GAMEPAD-AXIS-RIGHT-Y
 GAMEPAD-AXIS-LEFT-TRIGGER GAMEPAD-AXIS-RIGHT-TRIGGER)
