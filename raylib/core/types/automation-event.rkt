#lang racket/base

;; types/automation-event.rkt — AutomationEvent (24 bytes)

(require ffi/unsafe)

(define-cstruct _AutomationEvent
  ([frame _uint] [type _uint]
   [param0 _int] [param1 _int] [param2 _int] [param3 _int]))


;; pass-by-value
(define _automation-event-bytes
  (_list-struct _uint _uint _int _int _int _int))

(provide _AutomationEvent _automation-event-bytes)
