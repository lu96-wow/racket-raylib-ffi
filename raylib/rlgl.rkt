#lang racket/base

;; raylib rlgl 模块 — 底层 OpenGL 抽象层
;;
;; 对应 C: rlgl.h
;; 提供伪 OpenGL 1.1 即时模式 API，封装跨 OpenGL 版本的差异

(require ffi/unsafe
         (prefix-in T: "types.rkt"))

(define lib T:lib)

(define-syntax-rule (def-ffi name c-name fun-spec)
  (define name (get-ffi-obj c-name lib fun-spec)))

;; ============================================================
;; 绘制模式常量
;; ============================================================

(define RL-LINES      1)
(define RL-TRIANGLES  4)
(define RL-QUADS      7)

;; ============================================================
;; rlBlendMode 常量
;; ============================================================

(define RL-BLEND-ALPHA              0)
(define RL-BLEND-ADDITIVE           1)
(define RL-BLEND-MULTIPLIED         2)
(define RL-BLEND-ADD-COLORS         3)
(define RL-BLEND-SUBTRACT-COLORS    4)
(define RL-BLEND-ALPHA-PREMULTIPLY  5)
(define RL-BLEND-CUSTOM             6)
(define RL-BLEND-CUSTOM-SEPARATE    7)

;; ============================================================
;; Matrix 模式 / OpenGL blend 常量
;; ============================================================

(define RL-MODELVIEW  #x1700)
(define RL-PROJECTION #x1701)
(define RL-TEXTURE    #x1702)

(define RL-ZERO                 0)
(define RL-ONE                  1)
(define RL-SRC-ALPHA            #x0302)
(define RL-ONE-MINUS-SRC-ALPHA  #x0303)
(define RL-DST-COLOR            #x0306)
(define RL-ONE-MINUS-DST-COLOR  #x0307)
(define RL-FUNC-ADD             #x8006)
(define RL-MIN                  #x8007)
(define RL-MAX                  #x8008)

(define RL-VERTEX-SHADER   #x8B31)
(define RL-FRAGMENT-SHADER #x8B30)
(define RL-COMPUTE-SHADER  #x91B9)

;; ============================================================
;; 即时模式绘制
;; ============================================================

(def-ffi rl-begin      "rlBegin"      (_fun _int -> _void))
(def-ffi rl-end        "rlEnd"        (_fun -> _void))
(def-ffi rl-vertex-2i  "rlVertex2i"   (_fun _int _int -> _void))
(def-ffi rl-vertex-2f  "rlVertex2f"   (_fun _float _float -> _void))
(def-ffi rl-vertex-3f  "rlVertex3f"   (_fun _float _float _float -> _void))
(def-ffi rl-tex-coord-2f "rlTexCoord2f" (_fun _float _float -> _void))
(def-ffi rl-normal-3f  "rlNormal3f"   (_fun _float _float _float -> _void))
(def-ffi rl-color-4ub  "rlColor4ub"   (_fun _ubyte _ubyte _ubyte _ubyte -> _void))
(def-ffi rl-color-3f   "rlColor3f"    (_fun _float _float _float -> _void))
(def-ffi rl-color-4f   "rlColor4f"    (_fun _float _float _float _float -> _void))

;; ============================================================
;; 纹理
;; ============================================================

(def-ffi rl-set-texture    "rlSetTexture"    (_fun _uint -> _void))
(def-ffi rl-enable-texture "rlEnableTexture"  (_fun _uint -> _void))
(def-ffi rl-disable-texture "rlDisableTexture" (_fun -> _void))
(def-ffi rl-active-texture-slot "rlActiveTextureSlot" (_fun _int -> _void))
(def-ffi rl-load-texture  "rlLoadTexture"  (_fun _pointer _int _int _int _int -> _uint))
(def-ffi rl-unload-texture "rlUnloadTexture" (_fun _uint -> _void))
(def-ffi rl-update-texture "rlUpdateTexture" (_fun _uint _int _int _int _int _int _pointer -> _void))
(def-ffi rl-read-texture-pixels "rlReadTexturePixels" (_fun _uint _int _int _int -> _pointer))
(def-ffi rl-read-screen-pixels  "rlReadScreenPixels"  (_fun _int _int -> _pointer))

;; ============================================================
;; 矩阵变换
;; ============================================================

(def-ffi rl-matrix-mode   "rlMatrixMode"   (_fun _int -> _void))
(def-ffi rl-push-matrix   "rlPushMatrix"   (_fun -> _void))
(def-ffi rl-pop-matrix    "rlPopMatrix"    (_fun -> _void))
(def-ffi rl-load-identity "rlLoadIdentity" (_fun -> _void))
(def-ffi rl-translate-f    "rlTranslatef"   (_fun _float _float _float -> _void))
(def-ffi rl-rotate-f       "rlRotatef"      (_fun _float _float _float _float -> _void))
(def-ffi rl-scale-f        "rlScalef"       (_fun _float _float _float -> _void))
(def-ffi rl-mult-matrix-f  "rlMultMatrixf"  (_fun _pointer -> _void))

;; ============================================================
;; 视口/投影
;; ============================================================

(def-ffi rl-viewport    "rlViewport"    (_fun _int _int _int _int -> _void))
(def-ffi rl-frustum     "rlFrustum"     (_fun _double _double _double _double _double _double -> _void))
(def-ffi rl-ortho       "rlOrtho"       (_fun _double _double _double _double _double _double -> _void))
(def-ffi rl-set-clip-planes "rlSetClipPlanes" (_fun _double _double -> _void))
(def-ffi rl-get-cull-distance-near "rlGetCullDistanceNear" (_fun -> _double))
(def-ffi rl-get-cull-distance-far  "rlGetCullDistanceFar"  (_fun -> _double))

;; ============================================================
;; 状态管理
;; ============================================================

(def-ffi rl-set-blend-mode             "rlSetBlendMode"             (_fun _int -> _void))
(def-ffi rl-set-blend-factors          "rlSetBlendFactors"          (_fun _int _int _int -> _void))
(def-ffi rl-set-blend-factors-separate "rlSetBlendFactorsSeparate" (_fun _int _int _int _int _int _int -> _void))
(def-ffi rl-enable-color-blend         "rlEnableColorBlend"         (_fun -> _void))
(def-ffi rl-disable-color-blend        "rlDisableColorBlend"        (_fun -> _void))
(def-ffi rl-enable-depth-test          "rlEnableDepthTest"          (_fun -> _void))
(def-ffi rl-disable-depth-test         "rlDisableDepthTest"         (_fun -> _void))
(def-ffi rl-enable-depth-mask          "rlEnableDepthMask"          (_fun -> _void))
(def-ffi rl-disable-depth-mask         "rlDisableDepthMask"         (_fun -> _void))
(def-ffi rl-enable-backface-culling    "rlEnableBackfaceCulling"    (_fun -> _void))
(def-ffi rl-disable-backface-culling   "rlDisableBackfaceCulling"   (_fun -> _void))
(def-ffi rl-set-cull-face              "rlSetCullFace"              (_fun _int -> _void))
(def-ffi rl-enable-scissor-test        "rlEnableScissorTest"        (_fun -> _void))
(def-ffi rl-disable-scissor-test       "rlDisableScissorTest"       (_fun -> _void))
(def-ffi rl-scissor                    "rlScissor"                  (_fun _int _int _int _int -> _void))
(def-ffi rl-enable-point-mode          "rlEnablePointMode"          (_fun -> _void))
(def-ffi rl-disable-point-mode         "rlDisablePointMode"         (_fun -> _void))
(def-ffi rl-enable-wire-mode           "rlEnableWireMode"           (_fun -> _void))
(def-ffi rl-disable-wire-mode          "rlDisableWireMode"          (_fun -> _void))
(def-ffi rl-set-line-width             "rlSetLineWidth"             (_fun _float -> _void))
(def-ffi rl-get-line-width             "rlGetLineWidth"             (_fun -> _float))
(def-ffi rl-set-point-size             "rlSetPointSize"             (_fun _float -> _void))
(def-ffi rl-get-point-size             "rlGetPointSize"             (_fun -> _float))
(def-ffi rl-clear-color                "rlClearColor"               (_fun _ubyte _ubyte _ubyte _ubyte -> _void))
(def-ffi rl-clear-screen-buffers       "rlClearScreenBuffers"       (_fun -> _void))
(def-ffi rl-check-errors               "rlCheckErrors"              (_fun -> _void))

;; ============================================================
;; 顶点缓冲 (VBO/VAO)
;; ============================================================

(def-ffi rl-load-vertex-array          "rlLoadVertexArray"          (_fun -> _uint))
(def-ffi rl-unload-vertex-array        "rlUnloadVertexArray"        (_fun _uint -> _void))
(def-ffi rl-enable-vertex-array        "rlEnableVertexArray"        (_fun _uint -> _stdbool))
(def-ffi rl-disable-vertex-array       "rlDisableVertexArray"       (_fun -> _void))
(def-ffi rl-load-vertex-buffer         "rlLoadVertexBuffer"         (_fun _pointer _int _stdbool -> _uint))
(def-ffi rl-update-vertex-buffer       "rlUpdateVertexBuffer"       (_fun _uint _pointer _int _int -> _void))
(def-ffi rl-unload-vertex-buffer       "rlUnloadVertexBuffer"       (_fun _uint -> _void))
(def-ffi rl-set-vertex-attribute       "rlSetVertexAttribute"       (_fun _uint _int _int _stdbool _int _int -> _void))
(def-ffi rl-draw-vertex-array          "rlDrawVertexArray"          (_fun _int _int -> _void))
(def-ffi rl-draw-vertex-array-elements "rlDrawVertexArrayElements"  (_fun _int _int _pointer -> _void))
(def-ffi rl-draw-vertex-array-instanced "rlDrawVertexArrayInstanced" (_fun _int _int _int -> _void))

;; ============================================================
;; 着色器
;; ============================================================

(def-ffi rl-enable-shader              "rlEnableShader"              (_fun _uint -> _void))
(def-ffi rl-disable-shader             "rlDisableShader"             (_fun -> _void))
(def-ffi rl-load-shader                "rlLoadShader"                (_fun _string _int -> _uint))
(def-ffi rl-load-shader-program        "rlLoadShaderProgram"         (_fun _string _string -> _uint))
(def-ffi rl-unload-shader-program      "rlUnloadShaderProgram"       (_fun _uint -> _void))

;; ============================================================
;; 帧缓冲
;; ============================================================

(def-ffi rl-enable-framebuffer         "rlEnableFramebuffer"         (_fun _uint -> _void))
(def-ffi rl-disable-framebuffer        "rlDisableFramebuffer"        (_fun -> _void))
(def-ffi rl-load-framebuffer           "rlLoadFramebuffer"           (_fun -> _uint))
(def-ffi rl-framebuffer-attach         "rlFramebufferAttach"         (_fun _uint _uint _int _int _int -> _void))
(def-ffi rl-framebuffer-complete       "rlFramebufferComplete"       (_fun _uint -> _stdbool))
(def-ffi rl-unload-framebuffer         "rlUnloadFramebuffer"         (_fun _uint -> _void))

;; ============================================================
;; 杂项
;; ============================================================

(def-ffi rl-get-version                "rlGetVersion"                (_fun -> _int))
(def-ffi rl-get-texture-id-default     "rlGetTextureIdDefault"       (_fun -> _uint))
(def-ffi rl-get-shader-id-default      "rlGetShaderIdDefault"        (_fun -> _uint))
(def-ffi rl-check-render-batch-limit   "rlCheckRenderBatchLimit"     (_fun _int -> _stdbool))
(def-ffi rl-draw-render-batch-active   "rlDrawRenderBatchActive"     (_fun -> _void))

;; ============================================================
;; Framebuffer / Texture 扩展
;; ============================================================

(def-ffi rl-get-framebuffer-width   "rlGetFramebufferWidth"   (_fun -> _int))
(def-ffi rl-get-framebuffer-height  "rlGetFramebufferHeight"  (_fun -> _int))
(def-ffi rl-load-texture-depth      "rlLoadTextureDepth"      (_fun _int _int _stdbool -> _uint))
(def-ffi rl-load-texture-cubemap    "rlLoadTextureCubemap"    (_fun _pointer _int _int _int -> _uint))
(def-ffi rl-load-draw-cube          "rlLoadDrawCube"          (_fun -> _void))
(def-ffi rl-set-uniform-matrix      "rlSetUniformMatrix"      (_fun _int _pointer -> _void))

;; ============================================================
;; 导出
;; ============================================================

(provide
 RL-LINES RL-TRIANGLES RL-QUADS
 RL-BLEND-ALPHA RL-BLEND-ADDITIVE RL-BLEND-MULTIPLIED RL-BLEND-ADD-COLORS
 RL-BLEND-SUBTRACT-COLORS RL-BLEND-ALPHA-PREMULTIPLY
 RL-BLEND-CUSTOM RL-BLEND-CUSTOM-SEPARATE
 RL-MODELVIEW RL-PROJECTION RL-TEXTURE
 RL-ZERO RL-ONE RL-SRC-ALPHA RL-ONE-MINUS-SRC-ALPHA
 RL-DST-COLOR RL-ONE-MINUS-DST-COLOR RL-FUNC-ADD RL-MIN RL-MAX
 RL-VERTEX-SHADER RL-FRAGMENT-SHADER RL-COMPUTE-SHADER
 ;; 即时模式绘制
 rl-begin rl-end
 rl-vertex-2i rl-vertex-2f rl-vertex-3f
 rl-tex-coord-2f rl-normal-3f
 rl-color-4ub rl-color-3f rl-color-4f
 ;; 纹理
 rl-set-texture rl-enable-texture rl-disable-texture rl-active-texture-slot
 rl-load-texture rl-unload-texture rl-update-texture
 rl-read-texture-pixels rl-read-screen-pixels
 ;; 矩阵
 rl-matrix-mode rl-push-matrix rl-pop-matrix rl-load-identity
 rl-translate-f rl-rotate-f rl-scale-f rl-mult-matrix-f
 ;; 视口
 rl-viewport rl-frustum rl-ortho
 rl-set-clip-planes rl-get-cull-distance-near rl-get-cull-distance-far
 ;; 状态
 rl-set-blend-mode rl-set-blend-factors rl-set-blend-factors-separate
 rl-enable-color-blend rl-disable-color-blend
 rl-enable-depth-test rl-disable-depth-test
 rl-enable-depth-mask rl-disable-depth-mask
 rl-enable-backface-culling rl-disable-backface-culling rl-set-cull-face
 rl-enable-scissor-test rl-disable-scissor-test rl-scissor
 rl-enable-point-mode rl-disable-point-mode
 rl-enable-wire-mode rl-disable-wire-mode
 rl-set-line-width rl-get-line-width
 rl-set-point-size rl-get-point-size
 rl-clear-color rl-clear-screen-buffers rl-check-errors
 ;; 顶点缓冲
 rl-load-vertex-array rl-unload-vertex-array
 rl-enable-vertex-array rl-disable-vertex-array
 rl-load-vertex-buffer rl-update-vertex-buffer rl-unload-vertex-buffer
 rl-set-vertex-attribute
 rl-draw-vertex-array rl-draw-vertex-array-elements rl-draw-vertex-array-instanced
 ;; 着色器
 rl-enable-shader rl-disable-shader
 rl-load-shader rl-load-shader-program rl-unload-shader-program
 ;; 帧缓冲
 rl-enable-framebuffer rl-disable-framebuffer
 rl-load-framebuffer rl-framebuffer-attach rl-framebuffer-complete rl-unload-framebuffer
 ;; 杂项
 rl-get-version rl-get-texture-id-default rl-get-shader-id-default
 rl-check-render-batch-limit rl-draw-render-batch-active
 ;; 帧缓冲/纹理扩展
 rl-get-framebuffer-width rl-get-framebuffer-height
 rl-load-texture-depth rl-load-texture-cubemap
 rl-load-draw-cube rl-set-uniform-matrix
)
