#lang racket/base

;; raylib/core/ffi-helpers.rkt — 共享 FFI 基础设施
;;
;; 提供:
;;   1. def-ffi 宏 (消除 rcore/rlgl 中的重复定义)
;;   2. 所有 _xxx-bytes 传值类型 & 转换器 (从 types/ 聚合)
;;   3. malloc 辅助

(require ffi/unsafe
         "lib.rkt"
         "types/color.rkt"
         "types/vector2.rkt"
         "types/vector3.rkt"
         "types/vector4.rkt"
         "types/rectangle.rkt"
         "types/matrix.rkt"
         "types/camera2d.rkt"
         "types/camera3d.rkt"
         "types/ray.rkt"
         "types/ray-collision.rkt"
         "types/bounding-box.rkt"
         "types/image.rkt"
         "types/texture.rkt"
         "types/render-texture.rkt"
         "types/npatch-info.rkt"
         "types/glyph-info.rkt"
         "types/font.rkt"
         "types/shader.rkt"
         "types/mesh.rkt"
         "types/material.rkt"
         "types/model.rkt"
         "types/model-animation.rkt"
         "types/wave.rkt"
         "types/audio-stream.rkt"
         "types/sound.rkt"
         "types/music.rkt"
         "types/vr-device-info.rkt"
         "types/vr-stereo-config.rkt"
         "types/file-path-list.rkt"
         "types/automation-event.rkt")

;; ═══════════════════════════════════════════════════════════
;; 宏
;; ═══════════════════════════════════════════════════════════

(define-syntax-rule (def-ffi name c-name fun-spec)
  (define name
    (get-ffi-obj c-name lib fun-spec)))

;; ═══════════════════════════════════════════════════════════
;; 游戏循环可变状态
;; ═══════════════════════════════════════════════════════════

(define-syntax-rule (define-var name expr)
  (define name (box expr)))

(define-syntax-rule (+= var delta)
  (set-box! var (+ (unbox var) delta)))

(define-syntax-rule (-= var delta)
  (set-box! var (- (unbox var) delta)))

;; ═══════════════════════════════════════════════════════════
;; malloc 辅助
;; ═══════════════════════════════════════════════════════════

(define (vec2-vector->float-buf points-vec point-count)
  (let ([buf (malloc _float (* 2 point-count) 'atomic)])
    (for ([i (in-range point-count)])
      (let ([v (vector-ref points-vec i)])
        (ptr-set! buf _float (* 2 i)     (ptr-ref v _float 0))
        (ptr-set! buf _float (+ (* 2 i) 1) (ptr-ref v _float 1))))
    buf))

;; ═══════════════════════════════════════════════════════════
;; 导出
;; ═══════════════════════════════════════════════════════════

(provide
 ;; 共享库
 lib

 ;; 宏
 def-ffi define-var += -=

 ;; pass-by-value 类型
 _color-bytes _vec2-bytes _vec3-bytes _vec4-bytes
 _rect-bytes _matrix-bytes
 _camera2d-bytes _camera3d-bytes
 _ray-bytes _ray-collision-bytes _bounding-box-bytes
 _image-bytes _texture-bytes _render-texture-bytes
 _npatch-info-bytes _glyph-info-bytes _font-bytes
 _shader-bytes
 _mesh-bytes _material-bytes _model-bytes _model-animation-bytes
 _wave-bytes _audio-stream-bytes _sound-bytes _music-bytes
 _vrdeviceinfo-bytes _vrstereoconfig-bytes
 _filepathlist-bytes _automation-event-bytes

 ;; 转换器
 color->bytes vec2->bytes vec3->bytes vec4->bytes
 rect->bytes camera2d->bytes camera3d->bytes
 ray->bytes bounding-box->bytes
 bytes->vec2 bytes->vec3 bytes->vec4 bytes->rect bytes->color bytes->bounding-box
 malloc-float-vec2 malloc-float-vec3 malloc-float-vec4

 ;; 辅助
 vec2-vector->float-buf)
