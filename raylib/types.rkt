#lang racket/base

;; raylib 结构体/类型定义
;;
;; 对应 raylib.h 的类型定义部分 (struct, enum, typedef)
;; 所有结构体用 define-cstruct 定义，Racket 侧一律按指针操作
;;
;; 设计约定:
;;   - 在 Racket 中通过 make-Xxx 构造 boxed 指针
;;   - 对 C 侧传值的小结构体 (Color, Vector2 等),
;;     由各模块定义对应的 _xxx-pass 类型自动解包
;;
;; 导出: _Color, _Vector2 等类型 + make-Xxx / Xxx? / 字段访问器

(require ffi/unsafe
         racket/runtime-path)

(define-runtime-path local-raylib-lib-path "local-raylib-lib.rkt")

;; ============================================================
;; 共享库 — 由 local-raylib-lib.rkt 统一管理路径查找
;; ============================================================

(define lib
  (dynamic-require local-raylib-lib-path 'raylib-lib))

;; ============================================================
;; 基础类型
;; raylib 使用 C99 的 _Bool（1 字节），FFI 签名中统一用 _stdbool。
;; 不覆盖 _bool（4 字节），避免与 ffi/unsafe 冲突。
;; ============================================================

;; ============================================================
;; Color (raylib.h:248) — 4 字节小结构体
;; ============================================================

(define-cstruct _Color
  ([r _ubyte]
   [g _ubyte]
   [b _ubyte]
   [a _ubyte]))

;; Vector2 (raylib.h:216)
(define-cstruct _Vector2
  ([x _float]
   [y _float]))

;; Vector3 (raylib.h:222) — 12 字节: 3 × float
(define-cstruct _Vector3
  ([x _float]
   [y _float]
   [z _float]))

;; Vector4 / Quaternion (raylib.h:229) — 16 字节: 4 × float
(define-cstruct _Vector4
  ([x _float]
   [y _float]
   [z _float]
   [w _float]))

;; Rectangle (raylib.h:256)
(define-cstruct _Rectangle
  ([x _float]
   [y _float]
   [width _float]
   [height _float]))

;; Camera2D (raylib.h:338)
;;   Vector2 offset;    // offset.x @ _float 0, offset.y @ _float 1
;;   Vector2 target;    // target.x @ _float 2, target.y @ _float 3
;;   float rotation;    // @ _float 4
;;   float zoom;        // @ _float 5
(define-cstruct _Camera2D
  ([off-x _float]
   [off-y _float]
   [tar-x _float]
   [tar-y _float]
   [rotation _float]
   [zoom _float]))

;; Camera3D (raylib.h:327) — 44 字节
;;   内嵌 Vector3 position (3 floats), Vector3 target (3 floats), Vector3 up (3 floats),
;;   float fovy, int projection
;;   布局: pos-x,y,z @ float 0-2; tar-x,y,z @ float 3-5; up-x,y,z @ float 6-8;
;;         fovy @ float 9; projection @ int 0 (byte 40)
(define-cstruct _Camera3D
  ([pos-x _float] [pos-y _float] [pos-z _float]
   [tar-x _float] [tar-y _float] [tar-z _float]
   [up-x _float]  [up-y _float]  [up-z _float]
   [fovy _float]
   [projection _int]))

;; Ray (raylib.h:445) — 24 字节: 2 × Vector3 (position, direction)
(define-cstruct _Ray
  ([pos-x _float] [pos-y _float] [pos-z _float]
   [dir-x _float] [dir-y _float] [dir-z _float]))

;; RayCollision (raylib.h:451)
;;   bool hit;            // 1B + 3 padding
;;   float distance;      // 4B
;;   Vector3 point;       // 12B
;;   Vector3 normal;      // 12B
;;   总计: 32B
(define-cstruct _RayCollision
  ([hit _stdbool]
   [distance _float]
   [point-x _float] [point-y _float] [point-z _float]
   [norm-x _float]  [norm-y _float]  [norm-z _float]))

;; BoundingBox (raylib.h:459) — 24 字节: 2 × Vector3 (min, max)
(define-cstruct _BoundingBox
  ([min-x _float] [min-y _float] [min-z _float]
   [max-x _float] [max-y _float] [max-z _float]))

;; RenderTexture (raylib.h:288)
;;   unsigned int id;           // @ _uint 0
;;   Texture texture (inline):  // Texture → { unsigned int id; int w, h, mip, fmt; }
;;     unsigned int tex_id;     // @ _uint 1
;;     int tex_width;           // @ _int 2
;;     int tex_height;          // @ _int 3
;;     int tex_mipmaps;         // @ _int 4
;;     int tex_format;          // @ _int 5
;;   Texture depth (inline):
;;     unsigned int dep_id;     // @ _uint 6
;;     int dep_width;           // @ _int 7
;;     int dep_height;          // @ _int 8
;;     int dep_mipmaps;         // @ _int 9
;;     int dep_format;          // @ _int 10
;; 总计: 44 字节, 11 个字段
(define-cstruct _RenderTexture
  ([id _uint]
   [tex-id _uint] [tex-width _int] [tex-height _int] [tex-mipmaps _int] [tex-format _int]
   [dep-id _uint] [dep-width _int] [dep-height _int] [dep-mipmaps _int] [dep-format _int]))


;; Image (raylib.h:277) — 24 字节: void* data + 4× int
(define-cstruct _Image
  ([data _pointer]
   [width _int] [height _int]
   [mipmaps _int] [format _int]))

;; Texture / Texture2D / TextureCubemap (raylib.h:273) — 20 字节
;;   unsigned int id; int width, height, mipmaps, format
(define-cstruct _Texture
  ([id _uint]
   [width _int] [height _int]
   [mipmaps _int] [format _int]))

;; NPatchInfo (raylib.h:298) — 36 字节
;;   Rectangle source (4 floats); int left, top, right, bottom, layout
(define-cstruct _NPatchInfo
  ([src-x _float] [src-y _float] [src-width _float] [src-height _float]
   [left _int] [top _int] [right _int] [bottom _int] [layout _int]))

;; GlyphInfo (raylib.h:308) — 40 字节
;;   int value, offsetX, offsetY, advanceX; Image image (pointer + 4 ints)
(define-cstruct _GlyphInfo
  ([value _int] [offsetX _int] [offsetY _int] [advanceX _int]
   [image-data _pointer] [image-width _int] [image-height _int]
   [image-mipmaps _int] [image-format _int]))

;; Font (raylib.h:317) — 48 字节
;;   int baseSize, glyphCount, glyphPadding; Texture2D texture (uint+4ints);
;;   Rectangle *recs; GlyphInfo *glyphs
(define-cstruct _Font
  ([baseSize _int] [glyphCount _int] [glyphPadding _int]
   [tex-id _uint] [tex-width _int] [tex-height _int] [tex-mipmaps _int] [tex-format _int]
   [recs _pointer] [glyphs _pointer]))

;; Mesh (raylib.h:346) — ~120 字节
;;   大量指针字段; define-cstruct 自动处理对齐
(define-cstruct _Mesh
  ([vertexCount _int] [triangleCount _int]
   [vertices _pointer] [texcoords _pointer] [texcoords2 _pointer]
   [normals _pointer] [tangents _pointer] [colors _pointer] [indices _pointer]
   [boneCount _int]
   [boneIndices _pointer] [boneWeights _pointer]
   [animVertices _pointer] [animNormals _pointer]
   [vaoId _uint]
   [vboId _pointer]))

;; Shader (raylib.h:375) — 12 字节: unsigned int id + int* locs
(define-cstruct _Shader
  ([id _uint]
   [locs _pointer]))

;; MaterialMap (raylib.h:381) — 28 字节
;;   Texture2D texture (uint+4ints); Color color (4 ubytes); float value
(define-cstruct _MaterialMap
  ([tex-id _uint] [tex-width _int] [tex-height _int] [tex-mipmaps _int] [tex-format _int]
   [color-r _ubyte] [color-g _ubyte] [color-b _ubyte] [color-a _ubyte]
   [value _float]))

;; Material (raylib.h:388) — ~40 字节
;;   Shader shader (uint+pointer); MaterialMap *maps; float params[4]
(define-cstruct _Material
  ([shader-id _uint] [shader-locs _pointer]
   [maps _pointer]
   [param0 _float] [param1 _float] [param2 _float] [param3 _float]))

;; Transform (raylib.h:395) — 40 字节
;;   Vector3 translation (3 floats); Quaternion rotation (4 floats); Vector3 scale (3 floats)
(define-cstruct _Transform
  ([trans-x _float] [trans-y _float] [trans-z _float]
   [rot-x _float] [rot-y _float] [rot-z _float] [rot-w _float]
   [scale-x _float] [scale-y _float] [scale-z _float]))

;; BoneInfo (raylib.h:405) — 36 字节
;;   char name[32]; int parent
(define-cstruct _BoneInfo
  ([name0 _ubyte] [name1 _ubyte] [name2 _ubyte] [name3 _ubyte]
   [name4 _ubyte] [name5 _ubyte] [name6 _ubyte] [name7 _ubyte]
   [name8 _ubyte] [name9 _ubyte] [name10 _ubyte] [name11 _ubyte]
   [name12 _ubyte] [name13 _ubyte] [name14 _ubyte] [name15 _ubyte]
   [name16 _ubyte] [name17 _ubyte] [name18 _ubyte] [name19 _ubyte]
   [name20 _ubyte] [name21 _ubyte] [name22 _ubyte] [name23 _ubyte]
   [name24 _ubyte] [name25 _ubyte] [name26 _ubyte] [name27 _ubyte]
   [name28 _ubyte] [name29 _ubyte] [name30 _ubyte] [name31 _ubyte]
   [parent _int]))

;; ModelSkeleton (raylib.h:411) — 24 字节
;;   int boneCount; BoneInfo *bones; Transform *bindPose
(define-cstruct _ModelSkeleton
  ([boneCount _int]
   [bones _pointer]
   [bindPose _pointer]))

;; Model (raylib.h:418) — ~136 字节
;;   Matrix transform (16 floats); int meshCount, materialCount;
;;   Mesh *meshes; Material *materials; int *meshMaterial;
;;   ModelSkeleton skeleton (int+2pointers); Transform *currentPose; Matrix *boneMatrices
(define-cstruct _Model
  ([tr-m0 _float] [tr-m1 _float] [tr-m2 _float] [tr-m3 _float]
   [tr-m4 _float] [tr-m5 _float] [tr-m6 _float] [tr-m7 _float]
   [tr-m8 _float] [tr-m9 _float] [tr-m10 _float] [tr-m11 _float]
   [tr-m12 _float] [tr-m13 _float] [tr-m14 _float] [tr-m15 _float]
   [meshCount _int] [materialCount _int]
   [meshes _pointer] [materials _pointer] [meshMaterial _pointer]
   [skeleton-boneCount _int]
   [skeleton-bones _pointer] [skeleton-bindPose _pointer]
   [currentPose _pointer] [boneMatrices _pointer]))

;; ModelAnimation (raylib.h:436) — ~56 字节
;;   char name[32]; int boneCount; int keyframeCount; ModelAnimPose *keyframePoses
(define-cstruct _ModelAnimation
  ([name0 _ubyte] [name1 _ubyte] [name2 _ubyte] [name3 _ubyte]
   [name4 _ubyte] [name5 _ubyte] [name6 _ubyte] [name7 _ubyte]
   [name8 _ubyte] [name9 _ubyte] [name10 _ubyte] [name11 _ubyte]
   [name12 _ubyte] [name13 _ubyte] [name14 _ubyte] [name15 _ubyte]
   [name16 _ubyte] [name17 _ubyte] [name18 _ubyte] [name19 _ubyte]
   [name20 _ubyte] [name21 _ubyte] [name22 _ubyte] [name23 _ubyte]
   [name24 _ubyte] [name25 _ubyte] [name26 _ubyte] [name27 _ubyte]
   [name28 _ubyte] [name29 _ubyte] [name30 _ubyte] [name31 _ubyte]
   [boneCount _int] [keyframeCount _int]
   [keyframePoses _pointer]))

;; ============================================================
;; Matrix (raylib.h:239) — 64 字节: 16 floats
(define-cstruct _Matrix
  ([m0 _float] [m1 _float] [m2 _float] [m3 _float]
   [m4 _float] [m5 _float] [m6 _float] [m7 _float]
   [m8 _float] [m9 _float] [m10 _float] [m11 _float]
   [m12 _float] [m13 _float] [m14 _float] [m15 _float]))

;; Wave (raylib.h:465) — 32 字节
;;   unsigned int frameCount, sampleRate, sampleSize, channels; void *data
(define-cstruct _Wave
  ([frameCount _uint] [sampleRate _uint] [sampleSize _uint] [channels _uint]
   [data _pointer]))

;; AudioStream (raylib.h:479) — 32 字节
;;   rAudioBuffer *buffer; rAudioProcessor *processor;
;;   unsigned int sampleRate, sampleSize, channels
(define-cstruct _AudioStream
  ([buffer _pointer] [processor _pointer]
   [sampleRate _uint] [sampleSize _uint] [channels _uint]))

;; Sound (raylib.h:489) — 40 字节
;;   AudioStream stream (32B含4B尾填充); unsigned int frameCount
;;   C: AudioStream 28B+4pad=32B; Sound: 32+4=36+4pad=40B
(define-cstruct _Sound
  ([stream-buffer _pointer] [stream-processor _pointer]
   [stream-sampleRate _uint] [stream-sampleSize _uint] [stream-channels _uint]
   [_stream-pad _uint]    ;; AudioStream 尾部填充(28→32)
   [frameCount _uint]))

;; Music (raylib.h:495) — 56 字节
;;   AudioStream stream (32B含4B尾填充); unsigned int frameCount;
;;   bool looping; (+3B pad) int ctxType; void *ctxData
(define-cstruct _Music
  ([stream-buffer _pointer] [stream-processor _pointer]
   [stream-sampleRate _uint] [stream-sampleSize _uint] [stream-channels _uint]
   [_stream-pad _uint]    ;; AudioStream 尾部填充(28→32)
   [frameCount _uint]
   [looping _stdbool]
   ;; define-cstruct 自动在 looping(_stdbool 1B) 和 ctxType(_int 4B) 间插入 3B 填充
   [ctxType _int]
   [ctxData _pointer]))

;; VrDeviceInfo (raylib.h:505) — 60 字节
;;   int h/vResolution; 7 floats; float[4] lensDistortionValues; float[4] chromaAbCorrection
(define-cstruct _VrDeviceInfo
  ([hResolution _int] [vResolution _int]
   [hScreenSize _float] [vScreenSize _float]
   [eyeToScreenDistance _float] [lensSeparationDistance _float]
   [interpupillaryDistance _float]
   [lensDist0 _float] [lensDist1 _float] [lensDist2 _float] [lensDist3 _float]
   [chromaAb0 _float] [chromaAb1 _float] [chromaAb2 _float] [chromaAb3 _float]))

;; VrStereoConfig (raylib.h:518) — 304 字节
;;   Matrix projection[2] (32 floats); Matrix viewOffset[2] (32 floats);
;;   float leftLensCenter[2], rightLensCenter[2];
;;   float leftScreenCenter[2], rightScreenCenter[2];
;;   float scale[2], scaleIn[2]
(define-cstruct _VrStereoConfig
  ([proj0-m0 _float] [proj0-m1 _float] [proj0-m2 _float] [proj0-m3 _float]
   [proj0-m4 _float] [proj0-m5 _float] [proj0-m6 _float] [proj0-m7 _float]
   [proj0-m8 _float] [proj0-m9 _float] [proj0-m10 _float] [proj0-m11 _float]
   [proj0-m12 _float] [proj0-m13 _float] [proj0-m14 _float] [proj0-m15 _float]
   [proj1-m0 _float] [proj1-m1 _float] [proj1-m2 _float] [proj1-m3 _float]
   [proj1-m4 _float] [proj1-m5 _float] [proj1-m6 _float] [proj1-m7 _float]
   [proj1-m8 _float] [proj1-m9 _float] [proj1-m10 _float] [proj1-m11 _float]
   [proj1-m12 _float] [proj1-m13 _float] [proj1-m14 _float] [proj1-m15 _float]
   [view0-m0 _float] [view0-m1 _float] [view0-m2 _float] [view0-m3 _float]
   [view0-m4 _float] [view0-m5 _float] [view0-m6 _float] [view0-m7 _float]
   [view0-m8 _float] [view0-m9 _float] [view0-m10 _float] [view0-m11 _float]
   [view0-m12 _float] [view0-m13 _float] [view0-m14 _float] [view0-m15 _float]
   [view1-m0 _float] [view1-m1 _float] [view1-m2 _float] [view1-m3 _float]
   [view1-m4 _float] [view1-m5 _float] [view1-m6 _float] [view1-m7 _float]
   [view1-m8 _float] [view1-m9 _float] [view1-m10 _float] [view1-m11 _float]
   [view1-m12 _float] [view1-m13 _float] [view1-m14 _float] [view1-m15 _float]
   [leftLensCenter0 _float] [leftLensCenter1 _float]
   [rightLensCenter0 _float] [rightLensCenter1 _float]
   [leftScreenCenter0 _float] [leftScreenCenter1 _float]
   [rightScreenCenter0 _float] [rightScreenCenter1 _float]
   [scale0 _float] [scale1 _float]
   [scaleIn0 _float] [scaleIn1 _float]))

;; FilePathList (raylib.h:530) — 16 字节
;;   unsigned int count; char **paths
(define-cstruct _FilePathList
  ([count _uint]
   [paths _pointer]))

;; AutomationEvent (raylib.h:536) — 24 字节
;;   unsigned int frame; unsigned int type; int params[4]
(define-cstruct _AutomationEvent
  ([frame _uint] [type _uint]
   [param0 _int] [param1 _int] [param2 _int] [param3 _int]))

;; AutomationEventList (raylib.h:543) — 24 字节
;;   unsigned int capacity; unsigned int count; AutomationEvent *events
(define-cstruct _AutomationEventList
  ([capacity _uint] [count _uint]
   [events _pointer]))

;; 导出
;; ============================================================

;; types.rkt 只导出 C 结构体类型 + lib
;; 结构体访问器/构造器请使用 raylib-var/core.rkt 中的小写辅助函数
;; (color, vector2, vector2-x, set-vector2-x! 等)
(provide
 lib
 ;; 基础类型
 _Color _Vector2 _Vector3 _Vector4 _Rectangle _Matrix
 ;; 纹理/图像
 _Image _Texture _RenderTexture _NPatchInfo
 ;; 字体/文字
 _GlyphInfo _Font
 ;; 相机
 _Camera2D _Camera3D
 ;; 3D/模型
 _Mesh _Shader _MaterialMap _Material _Transform
 _BoneInfo _ModelSkeleton _Model _ModelAnimation
 ;; 射线/碰撞
 _Ray _RayCollision _BoundingBox
 ;; 音频
 _Wave _AudioStream _Sound _Music
 ;; VR
 _VrDeviceInfo _VrStereoConfig
 ;; 文件/自动化
 _FilePathList _AutomationEvent _AutomationEventList)