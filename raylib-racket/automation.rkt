#lang racket/base

;; raylib Automation Events — 纯 Racket 兼容实现层
;;
;; 录制、存储、导出、加载 → 全部纯 Racket
;; FFI 定义在本模块内（直接引用 raylib/types.rkt 的 lib）
;;
;; .rae 文件格式（兼容 raylib C 导出格式）:
;;   c <count>
;;   e <frame> <type> <p0> <p1> <p2> <p3> [// comment]

(require racket/match
         racket/file
         racket/string
         ffi/unsafe
         (prefix-in T: "../raylib/types.rkt"))

;; ============================================================
;; AutomationEvent 传值类型 + 原始 FFI
;;   C: PlayAutomationEvent(AutomationEvent event) → void
;;   传值调用，24 字节压栈，无指针问题
;; ============================================================

(define _automation-event-bytes
  (_list-struct _uint _uint _int _int _int _int))

(define _play-ae-ffi
  (get-ffi-obj "PlayAutomationEvent" T:lib
    (_fun (evt : _automation-event-bytes) -> _void)))

;; ============================================================
;; 事件结构体 — 纯 Racket
;; ============================================================

(struct automation-event (frame type params) #:transparent)

;; ============================================================
;; AutomationEventType 枚举常量
;; ============================================================

(define EVENT-NONE               0)
(define INPUT-KEY-UP             1)
(define INPUT-KEY-DOWN           2)
(define INPUT-KEY-PRESSED        3)
(define INPUT-KEY-RELEASED       4)
(define INPUT-MOUSE-BUTTON-UP    5)
(define INPUT-MOUSE-BUTTON-DOWN  6)
(define INPUT-MOUSE-POSITION     7)
(define INPUT-MOUSE-WHEEL-MOTION 8)
(define INPUT-GAMEPAD-CONNECT    9)
(define INPUT-GAMEPAD-DISCONNECT 10)
(define INPUT-GAMEPAD-BUTTON-UP  11)
(define INPUT-GAMEPAD-BUTTON-DOWN 12)
(define INPUT-GAMEPAD-AXIS-MOTION 13)
(define INPUT-TOUCH-UP           14)
(define INPUT-TOUCH-DOWN         15)
(define INPUT-TOUCH-POSITION     16)
(define INPUT-GESTURE            17)
(define WINDOW-CLOSE             18)
(define WINDOW-MAXIMIZE          19)
(define WINDOW-MINIMIZE          20)
(define WINDOW-RESIZE            21)
(define ACTION-TAKE-SCREENSHOT   22)
(define ACTION-SETTARGETFPS      23)

;; ============================================================
;; play-automation-event — 结构体包装
;; ============================================================

(define (play-automation-event ae)
  (match-define (automation-event frame type params) ae)
  (match params
    [(list p0 p1 p2 p3)
     (_play-ae-ffi (list frame type p0 p1 p2 p3))]))

;; ============================================================
;; 导出事件到 .rae 文本文件
;; ============================================================

(define (export-automation-events events filename)
  (with-output-to-file filename
    (lambda ()
      (printf "#\n")
      (printf "# Automation events exporter v1.0 - raylib automation events list\n")
      (printf "#\n")
      (printf "#    c <events_count>\n")
      (printf "#    e <frame> <event_type> <param0> <param1> <param2> <param3>\n")
      (printf "#\n")
      (printf "# more info and bugs-report:  github.com/raysan5/raylib\n")
      (printf "# feedback and support:       ray[at]raylib.com\n")
      (printf "#\n")
      (printf "# Copyright (c) 2023-2026 Ramon Santamaria (@raysan5)\n")
      (printf "#\n\n")
      (printf "c ~a\n" (length events))
      (for ([ae events])
        (match-define (automation-event frame type params) ae)
        (match params
          [(list p0 p1 p2 p3)
           (printf "e ~a ~a ~a ~a ~a ~a\n" frame type p0 p1 p2 p3)])))
    #:exists 'replace)
  #t)

;; ============================================================
;; 从 .rae 文本文件加载事件
;; ============================================================

(define (load-automation-events filename)
  (define lines (file->lines filename))
  (define result '())
  (for ([line lines])
    (define trimmed (string-trim line))
    (when (and (not (string=? trimmed ""))
               (not (string-prefix? trimmed "#")))
      (define parts (string-split trimmed))
      (when (pair? parts)
        (case (string->symbol (car parts))
          [(c) (void)]
          [(e)
           (match parts
             [(list _ frame type p0 p1 p2 p3)
              (set! result
                (cons (automation-event (string->number frame)
                                        (string->number type)
                                        (list (string->number p0)
                                              (string->number p1)
                                              (string->number p2)
                                              (string->number p3)))
                      result))])]))))
  (reverse result))

;; ============================================================
;; 录制辅助 — 帧间状态追踪
;; ============================================================

(struct recorder (events             ;; 已录制事件列表
                  prev-keys          ;; 上一帧键盘状态
                  prev-mouse-btns    ;; 上一帧鼠标按钮状态
                  prev-mouse-x       ;; 上一帧鼠标 x
                  prev-mouse-y       ;; 上一帧鼠标 y
                  prev-wheel-x       ;; 上一帧滚轮 x
                  prev-wheel-y)      ;; 上一帧滚轮 y
  #:mutable)

(define (make-recorder)
  (recorder '()
            (make-hasheq)
            (make-hasheq)
            0 0 0 0))

(define (record-frame! rec frame key-down? mouse-btn? mouse-x mouse-y wheel-x wheel-y)
  (define evts (recorder-events rec))
  (define prev-keys (recorder-prev-keys rec))
  (define prev-btns (recorder-prev-mouse-btns rec))
  (define prev-mx (recorder-prev-mouse-x rec))
  (define prev-my (recorder-prev-mouse-y rec))
  (define prev-wx (recorder-prev-wheel-x rec))
  (define prev-wy (recorder-prev-wheel-y rec))

  ;; 键盘事件
  (for ([key (in-range 512)])
    (define now (key-down? key))
    (define prev (hash-ref prev-keys key #f))
    (cond
      [(and prev (not now))
       (set! evts (cons (automation-event frame INPUT-KEY-UP (list key 0 0 0)) evts))]
      [(and (not prev) now)
       (set! evts (cons (automation-event frame INPUT-KEY-DOWN (list key 0 0 0)) evts))])
    (hash-set! prev-keys key now))

  ;; 鼠标按钮事件
  (for ([btn (in-range 3)])
    (define now (mouse-btn? btn))
    (define prev (hash-ref prev-btns btn #f))
    (cond
      [(and prev (not now))
       (set! evts (cons (automation-event frame INPUT-MOUSE-BUTTON-UP (list btn 0 0 0)) evts))]
      [(and (not prev) now)
       (set! evts (cons (automation-event frame INPUT-MOUSE-BUTTON-DOWN (list btn 0 0 0)) evts))])
    (hash-set! prev-btns btn now))

  ;; 鼠标位置事件
  (when (or (not (= mouse-x prev-mx))
            (not (= mouse-y prev-my)))
    (set! evts (cons (automation-event frame INPUT-MOUSE-POSITION
                                       (list mouse-x mouse-y 0 0)) evts))
    (set-recorder-prev-mouse-x! rec mouse-x)
    (set-recorder-prev-mouse-y! rec mouse-y))

  ;; 滚轮事件
  (when (or (not (= wheel-x prev-wx))
            (not (= wheel-y prev-wy)))
    (set! evts (cons (automation-event frame INPUT-MOUSE-WHEEL-MOTION
                                       (list wheel-x wheel-y 0 0)) evts))
    (set-recorder-prev-wheel-x! rec wheel-x)
    (set-recorder-prev-wheel-y! rec wheel-y))

  (set-recorder-events! rec evts))

(define (clear-recorder! rec)
  (set-recorder-events! rec '()))

;; ============================================================
;; 导出
;; ============================================================

(provide
 automation-event automation-event? automation-event-frame
 automation-event-type automation-event-params

 EVENT-NONE INPUT-KEY-UP INPUT-KEY-DOWN INPUT-KEY-PRESSED INPUT-KEY-RELEASED
 INPUT-MOUSE-BUTTON-UP INPUT-MOUSE-BUTTON-DOWN
 INPUT-MOUSE-POSITION INPUT-MOUSE-WHEEL-MOTION
 INPUT-GAMEPAD-CONNECT INPUT-GAMEPAD-DISCONNECT
 INPUT-GAMEPAD-BUTTON-UP INPUT-GAMEPAD-BUTTON-DOWN
 INPUT-GAMEPAD-AXIS-MOTION
 INPUT-TOUCH-UP INPUT-TOUCH-DOWN INPUT-TOUCH-POSITION
 INPUT-GESTURE
 WINDOW-CLOSE WINDOW-MAXIMIZE WINDOW-MINIMIZE WINDOW-RESIZE
 ACTION-TAKE-SCREENSHOT ACTION-SETTARGETFPS

 play-automation-event
 export-automation-events
 load-automation-events

 recorder make-recorder recorder-events
 record-frame! clear-recorder!)