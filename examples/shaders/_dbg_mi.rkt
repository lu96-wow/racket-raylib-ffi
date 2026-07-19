#lang racket/base
(require "../../raylib/raylib.rkt" "../../raylib/rlights.rkt"
         racket/runtime-path racket/math ffi/unsafe
         (only-in ffi/unsafe ptr-set! ptr-ref _float _int _uint _ubyte malloc))
(define GLSL-VERSION 330)
(define-runtime-path rd "../../../examples/shaders/resources/")
(define (res . p) (path->string (simplify-path (apply build-path rd p))))
(init-window 800 450 "debug-mi")

(define shader (load-shader (res (format "shaders/glsl~a/lighting_instancing.vs" GLSL-VERSION))
                            (res (format "shaders/glsl~a/lighting.fs" GLSL-VERSION))))

;; Check material after load-material-default
(printf "A: load-material-default...~n")(flush-output)
(define mat-ptr (load-material-default))
(printf "  ptr=~s~n" mat-ptr)(flush-output)

;; Read the maps pointer and first map's color
(define maps-ptr (ptr-ref mat-ptr _pointer 2))
(printf "  maps-ptr=~s~n" maps-ptr)(flush-output)
(printf "  maps[0].color: r=~a g=~a b=~a a=~a~n"
        (ptr-ref maps-ptr _ubyte 20) (ptr-ref maps-ptr _ubyte 21)
        (ptr-ref maps-ptr _ubyte 22) (ptr-ref maps-ptr _ubyte 23))(flush-output)

;; Set shader
(set-material-shader mat-ptr shader)
(printf "B: shader set, shader-id in mat=~a~n" (ptr-ref mat-ptr _uint 0))(flush-output)

;; Set color to RED
(define red-c (malloc _ubyte 4 'atomic))
(ptr-set! red-c _ubyte 0 230)(ptr-set! red-c _ubyte 1 41)(ptr-set! red-c _ubyte 2 55)(ptr-set! red-c _ubyte 3 255)
(set-material-color mat-ptr MATERIAL-MAP-DIFFUSE red-c)

;; Re-read color
(printf "  after set: r=~a g=~a b=~a a=~a~n"
        (ptr-ref maps-ptr _ubyte 20) (ptr-ref maps-ptr _ubyte 21)
        (ptr-ref maps-ptr _ubyte 22) (ptr-ref maps-ptr _ubyte 23))(flush-output)

;; Check through material-ptr->list
(define mat-list (material-ptr->list mat-ptr))
(printf "  mat-list[0](shader-id)=~a~n" (list-ref mat-list 0))(flush-output)
(printf "  mat-list[3](maps-ptr)=~s~n" (list-ref mat-list 3))(flush-output)

(close-window)
