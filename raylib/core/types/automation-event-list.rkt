#lang racket/base

;; types/automation-event-list.rkt — AutomationEventList (24 bytes)

(require ffi/unsafe)

(define-cstruct _AutomationEventList
  ([capacity _uint] [count _uint] [events _pointer]))

(provide _AutomationEventList)
