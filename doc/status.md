# raylib Racket 绑定 — 绑定状态报告

**生成日期**: 2026-06-03  
**raylib 版本**: 6.0  
**分析依据**: `src/raylib.h` (600 个 RLAPI 函数) vs `racket-bind/raylib/*.rkt`

---

## 概览

| 模块 | raylib API 总数 | 已绑定 | 完成度 |
|------|:-------:|:------:|:------:|
| **rcore** (窗口/输入/绘制/系统) | 262 | ~95 | **~36%** |
| **rshapes** (2D 形状) | 77 | ~45 | **~58%** |
| **rtextures** (纹理/图像) | 116 | ~12 | **~10%** |
| **rtext** (文字/字体) | 63 | **0** | **0%** |
| **rmodels** (3D/模型) | 73 | ~15 | **~21%** |
| **raudio** (音频) | 69 | **0** | **0%** |
| **rcamera** (相机控制) | 2 | 2 | **100%** |
| **raymath** (纯 Racket 数学) | — | ~30 函数 | 纯 Racket 实现 |
| **raylib-racket/automation** | 8 (FFI) | 8+ 纯 Racket | 完整实现 |
| **types.rkt** (结构体定义) | — | 12 结构体 | 持续扩展 |

---

## ✅ 完整绑定的输入子模块

### 键盘输入 (9/9 = 100%)
全部绑定: `is-key-pressed/repeat/down/released/up`,
`get-key-pressed/char-pressed/key-name`, `set-exit-key`

### 鼠标输入 (14/14 = 100%)
全部绑定: 按钮 4 个, 坐标 4 个, 设置 3 个, 滚轮 2 个, `set-mouse-cursor`

### 手柄输入 (11/11 = 100%)
全部绑定: `is-gamepad-available?/name`, 按钮 5 个, 轴 2 个,
`set-gamepad-mappings/vibration`

### 触摸输入 (5/5 = 100%)
`get-touch-x/y/point-id/point-count/position`

### 手势 (8/8 = 100%)
全部绑定: `set-gestures-enabled`, `is-gesture-detected?`,
`get-gesture-detected/hold-duration/drag-vector/drag-angle/pinch-vector/pinch-angle`

### 光标控制 (6/6 = 100%)
全部绑定: `show/hide-cursor`, `is-cursor-hidden?`, `enable/disable-cursor`,
`is-cursor-on-screen?`

---

## 基本完成的模块

### 绘制上下文 (15/17 ≈ 88%)
✅ `begin/end-drawing`, `clear-background`, `begin/end-mode-2d/3d`,
`begin/end-shader-mode`, `begin/end-scissor-mode`, `begin/end-vr-stereo-mode`,
`begin/end-texture-mode`
❌ `BeginBlendMode`, `EndBlendMode`

### VR/着色器/屏幕空间/计时/随机 (26/33 ≈ 79%)
✅ `LoadShader/GetShaderLocation/SetShaderValue/UnloadShader`,
`GetScreenToWorldRay/GetWorldToScreen/GetCameraMatrix`,
屏幕/渲染宽高, `SetTargetFPS/GetFrameTime/GetTime/GetFPS`,
`SwapScreenBuffer/PollInputEvents/WaitTime`,
`SetRandomSeed/GetRandomValue/LoadRandomSequence`
❌ `LoadShaderFromMemory`, `IsShaderValid`, `GetShaderLocationAttrib`,
`SetShaderValueV/Matrix/Texture`, `GetScreenToWorldRayEx`,
`GetWorldToScreenEx`, `GetCameraMatrix2D`

### 窗口管理 (26/49 ≈ 53%)
✅ 基础窗口 (4), 窗口状态 (8), 显示器 (10), 窗口位置 (2),
剪贴板 (2)
❌ `IsWindowReady/Fullscreen/Hidden/Minimized/Maximized/Focused`,
`SetWindowIcon/Icons/Title/Position/Size/MaxSize/Opacity/Focused`,
`GetWindowHandle`, `GetClipboardImage`, `Enable/DisableEventWaiting`

### Misc / 日志 / 文件系统 / 编码
✅ `set-config-flags`, `set-trace-log-callback`, `load-file-text`,
`directory-exists?`, `get-working-directory/prev-directory-path/application-directory`,
`load-directory-files-ex`, `is-file-dropped`, `load-dropped-files`,
`compute-crc32/md5/sha1/sha256`, `encode-data-base64`
❌ `TakeScreenshot`, `OpenURL`, `SetTraceLogLevel`, `TraceLog`,
`Load/SaveFileData`, `SaveFileText`, 文件回调/操作 (14),
`CompressData/DecompressData`, `DecodeDataBase64`

---

## 部分完成的模块

### rshapes — 2D 形状 (45/77 ≈ 58%)

**✅ 已绑定 (~45 个):**
- 圆 (7): `draw-circle/v/gradient/lines/lines-v/sector/sector-lines`
- 矩形 (12): `draw-rectangle/v/rec/pro/lines/lines-ex/rounded/
  rounded-lines-ex/gradient-h/gradient-ex`
- 三角形 (4): `draw-triangle/lines/fan/strip`
- 线段 (4): `draw-line-v/ex/bezier/dashed`
- 椭圆 (2): `draw-ellipse/lines`
- 环 (2): `draw-ring/lines`
- 多边形 (3): `draw-poly/lines/lines-ex`
- 样条线 (10): 8 个 draw spline + 2 个辅助
- 碰撞 (4): `check-collision-point-rec/circle/recs`, `get-collision-rec`
- 额外: `get-shapes-texture/rectangle`, `draw-rectangle-rounded-gradient-h`

**❌ 未绑定 (~32 个):**
- `DrawPixel/V`, `DrawLineStrip`, `DrawEllipseV/LinesV`,
  `DrawRectangleGradientV`, `DrawRectangleRoundedLines`, `DrawTriangleGradient`
- `DrawSplineBezierQuadratic`, `DrawSplineSegmentBezierQuadratic`
- `GetSplinePointLinear/Basis/CatmullRom/BezierQuadratic/BezierCubic`
- `CheckCollisionCircles/CircleRec/CircleLine/PointTriangle/PointLine/PointPoly/Lines`
- `SetShapesTexture`

---

### rtextures — 纹理/图像 (12/116 ≈ 10%)

**✅ 已绑定 (GPU 纹理 + 基础图片):**
- 纹理加载/卸载: `load-texture`, `load-texture-from-image`, `unload-texture`
- 纹理绘制: `draw-texture`, `draw-texture-ex/rec/pro`
- 纹理配置: `set-texture-filter`
- 渲染纹理: `load-render-texture`, `unload-render-texture`,
  `begin-texture-mode`, `end-texture-mode`
- 图像: `load-image`, `load-image-from-screen`, `gen-image-color/checked`,
  `image-rotate`, `export-image`, `unload-image`, `update-texture`
- 材质: `set-material-texture`
- 颜色工具: `fade`, `color-alpha`, `color-from-hsv`

**❌ 未绑定 (~104 个):**
- Image 加载 (7): `LoadImageRaw/Anim/AnimFromMemory/FromMemory/
  FromTexture`, `IsImageValid`, `ExportImageToMemory/AsCode`
- Image 生成 (7): `GenImageGradientLinear/Radial/Square/WhiteNoise/
  PerlinNoise/Cellular/Text`
- Image 操作 (35): 全部 `ImageCopy/FromImage/FromChannel/Text/TextEx/
  Format/ToPOT/Crop/AlphaCrop/...` 等
- Image 软件渲染 (23): 全部 `ImageDraw*/ClearBackground` 等
- Texture GPU (3): `LoadTextureCubemap`, `IsTextureValid`,
  `IsRenderTextureValid`, `UpdateTextureRec`
- Texture 配置 (2): `GenTextureMipmaps`, `SetTextureWrap`
- Texture 绘制 (2): `DrawTextureV`, `DrawTextureNPatch`
- Color 函数 (14): `ColorIsEqual/ToInt/Normalize/FromNormalized/
  ToHSV/Tint/Brightness/Contrast/AlphaBlend/Lerp/GetColor/
  GetPixelColor/SetPixelColor/GetPixelDataSize`

---

### rtext — 文字/字体 (0/63 ≈ 0%)

**rtext.rkt 是空白文件，只含 `(provide)`**

少量文本函数在 rcore.rkt 中散落绑定:
- `draw-text`, `draw-fps`, `measure-text`, `measure-text-ex`
- `text-subtext`, `get-font-default`, `load-file-text`

**❌ 完全未绑定:**
- Font 加载 (8): `LoadFont/Ex/FromImage/FromMemory`, `IsFontValid`,
  `LoadFontData`, `GenImageFontAtlas`, `UnloadFontData/UnloadFont`,
  `ExportFontAsCode`
- Text 绘制 (3): `DrawTextPro`, `DrawTextCodepoint`, `DrawTextCodepoints`
- 字体信息 (4): `SetTextLineSpacing`, `MeasureTextCodepoints`,
  `GetGlyphIndex/Info/AtlasRec`
- Codepoint (9): `LoadUTF8/UnloadUTF8`, `LoadCodepoints/UnloadCodepoints`,
  `GetCodepointCount/GetCodepoint/GetCodepointNext/Previous/CodepointToUTF8`
- 字符串管理 (22): `TextCopy/IsEqual/Length/Format/RemoveSpaces/...`
  等全部未绑定

---

### rmodels — 3D/模型 (15/73 ≈ 21%)

**✅ 已绑定:**
- 3D 形状: `draw-cube/v/wires/wires-v`, `draw-plane`, `draw-sphere`,
  `draw-ray`, `draw-grid`, `draw-line-3d`
- Model: `load-model`, `unload-model`, `draw-model-ex`
- 动画: `load-model-animations`, `update-model-animation`,
  `unload-model-animations`
- 碰撞: `get-ray-collision-box`
- 辅助: `model-animation-name`, `model-animation-keyframe-count`

**❌ 未绑定 (~58 个):**
- 3D 形状 (10): `DrawPoint3D/Circle3D/Triangle3D/TriangleStrip3D/
  SphereEx/SphereWires/Cylinder/CylinderEx/CylinderWires/CylinderWiresEx/
  Capsule/CapsuleWires`
- Model 管理 (3): `LoadModelFromMesh`, `IsModelValid`, `GetModelBoundingBox`
- Model 绘制 (7): `DrawModel/Wires/WiresEx`, `DrawBoundingBox`,
  `DrawBillboard/Rec/Pro`
- Mesh (20): 全部 `UploadMesh/UpdateMeshBuffer/UnloadMesh/DrawMesh/
  DrawMeshInstanced/GetMeshBoundingBox/GenMeshTangents/ExportMesh/
  ExportMeshAsCode` + 11 个 `GenMesh*`
- Material (5): `LoadMaterials`, `LoadMaterialDefault`, `IsMaterialValid`,
  `UnloadMaterial`, `SetModelMeshMaterial`
- 动画 (2): `UpdateModelAnimationEx`, `IsModelAnimationValid`
- 碰撞 (7): `CheckCollisionSpheres/Boxes/BoxSphere`,
  `GetRayCollisionSphere/Mesh/Triangle/Quad`

---

### raudio — 音频 (0/69 ≈ 0%)

**raudio.rkt 是空白文件，只含 `(provide)` — 完全未绑定!**

- 设备管理 (5): `InitAudioDevice`, `CloseAudioDevice`,
  `IsAudioDeviceReady`, `SetMasterVolume`, `GetMasterVolume`
- Wave/Sound 加载 (13): `LoadWave/FromMemory`, `IsWaveValid`,
  `LoadSound/FromWave/Alias`, `IsSoundValid`, `UpdateSound`,
  `UnloadWave/Sound/SoundAlias`, `ExportWave/AsCode`
- Wave/Sound 管理 (13): `Play/Stop/Pause/Resume Sound`, `IsSoundPlaying`,
  `SetSoundVolume/Pitch/Pan`, `WaveCopy/Crop/Format`,
  `LoadWaveSamples/UnloadWaveSamples`
- Music (16): `LoadMusicStream/FromMemory`, `IsMusicValid`,
  `UnloadMusicStream`, `Play/Stop/Pause/Resume/Seek/Update MusicStream`,
  `IsMusicStreamPlaying`, `SetMusicVolume/Pitch/Pan`,
  `GetMusicTimeLength/Played`
- AudioStream (19): `Load/Unload/Update/Play/Pause/Resume/Stop AudioStream`,
  `IsAudioStreamValid/Processed/Playing`, `SetAudioStreamVolume/Pitch/Pan`,
  `SetAudioStreamBufferSizeDefault/Callback`,
  `Attach/DetachAudioStream/MixedProcessor`

---

### Automation Events (纯 Racket 实现)
`raylib-racket/automation.rkt` 包含完整的纯 Racket 事件录制/加载/导出系统
(不依赖 raylib C 的 AutomationEventList 管理)

---

## 文件结构

```
racket-bind/
├── raylib/
│   ├── raylib.rkt        # 主入口
│   ├── types.rkt         # 12 个 C struct (Color, Vector2/3, Rect, Camera2D/3D, Ray, RayCollision, BoundingBox, RenderTexture, Image, Shader, Matrix)
│   ├── rcore.rkt         # ~95 函数 (窗口/输入/绘制/系统)
│   ├── rshapes.rkt       # ~45 函数 (2D 形状)
│   ├── rtextures.rkt     # ~12 函数 (纹理/图像)
│   ├── rtext.rkt         # ⚠️ 空白 — 待实现
│   ├── rmodels.rkt       # ~15 函数 (3D/模型)
│   ├── raudio.rkt        # ⚠️ 空白 — 待实现
│   ├── raymath.rkt       # 纯 Racket 数学
│   └── rcamera.rkt       # CameraYaw/Pitch
├── raylib-var/
│   ├── var.rkt           # 常量入口
│   └── core.rkt          # 颜色/键值/标志
├── raylib-racket/
│   └── automation.rkt    # 完整事件系统
├── examples/             # ~60+ 示例
└── doc/
    └── status.md         # 本文件
```
