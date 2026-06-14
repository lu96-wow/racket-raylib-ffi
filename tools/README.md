# tools/

## 设计目标

raylib C 结构体在不同编译器/平台上的内存布局（padding、对齐）不可预测。
在 Racket FFI 中手工推算偏移会导致 segfault。

**本目录提供一套"用 C 编译器自行计算布局"的工具链**，
将编译器权威的 `offsetof`/`sizeof` 输出为 Racket 常量模块。

## 工作流

```
gen-layout.c          C 程序，include raylib.h，用 offsetof/sizeof 打印所有结构体字段偏移
    ↓ gcc -I../../src
gen-layout            编译产物
    ↓ ./gen-layout
layout.rkt            自动生成的 Racket 模块，提供如 Material-maps-off, Mesh-size 等常量
    ↓ require
Racket 绑定侧         用 (ptr-ref ptr _pointer Material-maps-off) 替代手工写的 16
```

## gen-layout.c 维护规则

1. **只依赖 raylib.h** — 不用任何第三方库
2. **每个结构体一个 section** — 注释分隔，格式统一
3. **新增结构体时**：
   - 在 `gen-layout.c` 添加对应的 `offsetof`/`sizeof` printf
   - 重新编译运行，生成新的 `layout.rkt`
4. **输出格式**：`(define StructName-field-off <number>)`，尾部 `(provide (all-defined-out))`

## 使用 layout.rkt 的约定

在 Racket 绑定代码中：

```racket
;; ❌ 手工推算（不可靠）
(ptr-ref mat-ptr _pointer 12)   ; 猜的

;; ✅ 从 layout.rkt 取（编译器确认）
(require "layout.rkt")
(ptr-ref mat-ptr _pointer Material-maps-off)  ; 来自 offsetof(Material, maps)
```

`ptr-add` 偏移同理：

```racket
(ptr-add meshes-ptr (* m Mesh-size))  ; Mesh-size = 120, 来自 sizeof(Mesh)
```

## 已知局限

- **`ptr-ref _pointer` 在某些偏移可能仍有对齐问题**
  （如 `set-material-color` 中 `ptr-ref mat-ptr _pointer 16` 读到无效指针，
  但同偏移的 C 函数 `SetMaterialTexture` 正常）
  成因待查，可能是 Racket FFI 与栈传参 ABI 的边界问题。

- **layout.rkt 已纳入 `raylib/` 目录**，可被示例和绑定直接 require。
