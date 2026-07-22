#lang racket/base

;; types/automation-event.rkt — AutomationEvent (24 bytes, pass-by-value)

(require ffi/unsafe)

(define-cstruct _AutomationEvent
  ([frame _uint] [type _uint]
   [param0 _int] [param1 _int] [param2 _int] [param3 _int]))

(define _automation-event-bytes
  (_list-struct _uint _uint _int _int _int _int))

(define (automation-event-frame lst)  (list-ref lst 0))
(define (automation-event-type lst)   (list-ref lst 1))
(define (automation-event-param0 lst) (list-ref lst 2))
(define (automation-event-param1 lst) (list-ref lst 3))
(define (automation-event-param2 lst) (list-ref lst 4))
(define (automation-event-param3 lst) (list-ref lst 5))

(provide _AutomationEvent _automation-event-bytes
         automation-event-frame automation-event-type
         automation-event-param0 automation-event-param1
         automation-event-param2 automation-event-param3)
