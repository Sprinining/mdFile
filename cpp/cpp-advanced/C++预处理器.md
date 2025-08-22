## C++ 预处理器

C++ 的预处理器（Preprocessor）是一个在编译之前运行的文本处理工具，它主要用于对源代码进行宏替换、文件包含、条件编译等操作。预处理器指令都是以 `#` 开头的，在真正的编译过程开始前执行。

### 常用的预处理指令

#### 定义宏：#define

```cpp
#define PI 3.14159
#define MAX(a, b) ((a) > (b) ? (a) : (b))
```

- **对象宏**：将 `PI` 替换为 `3.14159`
- **函数宏**：可传参，注意加括号避免优先级错误

#### 取消宏定义：#undef

```cpp
#undef PI
```

取消之前通过 `#define` 定义的宏。

#### 包含文件：#include

```cpp
#include <iostream>   // 标准库头文件
#include "myheader.h" // 自定义头文件
```

- `<>`：查找系统目录中的头文件
- `""`：先在当前目录查找，再查找系统目录

#### 条件编译

`#if`、`#ifdef`、`#ifndef`、`#else`、`#elif`、`#endif`。

##### 防止头文件重复包含

```cpp
#ifndef MY_HEADER_H
#define MY_HEADER_H

// 头文件内容

#endif
```

常用于防止头文件重复定义。

##### 宏控制

```cpp
#define DEBUG

#ifdef DEBUG
    std::cout << "调试信息" << std::endl;
#endif
```

#### 强制报错：#error

```cpp
#ifndef VERSION
#error "VERSION 未定义"
#endif
```

#### 编译器相关扩展指令：#pragma

```cpp
#pragma once
```

- 作用类似于 include guard，防止头文件重复包含。
- 非标准但几乎所有主流编译器支持。

### 预处理器的工作流程

#### 处理源文件输入

编译器读入 `.cpp` 源文件，开始扫描。所有**预处理指令**（以 `#` 开头）在这个阶段被处理。

#### 删除注释

所有的 `// 行注释` 和 `/* 块注释 */` 都会被移除，替换为空格。

```cpp
int a = 1; // 这是一条注释
```

转换为

```cpp
int a = 1; 
```

#### 处理宏定义和替换

- `#define` 定义的符号宏、函数宏会被简单的文本替换。
- `#undef` 会取消宏定义。

```cpp
#define PI 3.14
float r = PI * 2;
```

预处理后：

```cpp
float r = 3.14 * 2;
```

#### 处理条件编译

- `#if` / `#ifdef` / `#ifndef` / `#else` / `#endif`
- 根据条件是否成立，决定代码是否被保留。

```cpp
#ifdef DEBUG
    printf("调试模式\n");
#endif
```

如果没有定义 `DEBUG`，这段代码会被移除。

#### 处理文件包含

- `#include` 会把指定文件的内容直接拷贝进来。
- `#include "xxx.h"` → 在当前目录和系统目录找
- `#include <xxx.h>` → 在系统目录找

```cpp
#include <stdio.h>
```

预处理器会把 `stdio.h` 文件的内容直接插入到代码中。

#### 处理特殊指令

- `#pragma`（编译器相关的特殊指令，比如 `#pragma once`）
- `#error`（手动报错）
- `#line`（修改源码行号，用于调试）

#### 生成预处理后的源文件

经过上面所有步骤后，预处理器会输出一个“纯净”的源码文件（通常扩展名 `.i`）。这个文件已经没有注释、没有 `#include`，所有宏都替换完成，只剩下**标准 C++ 代码**，然后交给编译器的下一阶段（词法分析 → 语法分析 → 语义分析 → 代码生成）。

### 调试预处理结果

GCC / Clang：

```bash
g++ -E main.cpp -o main.i
```

- `-E` 表示只做预处理。
- `-o main.i` 把结果输出到 `main.i` 文件里。

这样就能打开 `main.i` 查看预处理结果。

### 注意事项

宏只是文本替换

- 不会检查类型，容易出错。
- 推荐用 `constexpr`、`enum`、`inline` 替代。

函数宏副作用

```cpp
#define SQR(x) ((x)*(x))
int a = 5;
SQR(a++); // 展开成 ((a++)*(a++))，错误！
```

应该改用 `inline` 函数。

条件编译滥用

- 过度使用 `#ifdef` 会让代码可读性差。
- 建议用 **配置头文件** 或 **CMake 配置** 统一管理。

头文件保护必须唯一

- 如果 `#ifndef` 宏名重复，可能导致不同头文件互相屏蔽。
- 推荐统一命名规范（如 `PROJECT_MODULE_FILENAME_H`）。

调试宏开关

- 不要在代码里写死 `#define DEBUG`。
- 用编译器参数 `-DDEBUG` 更灵活。

跨平台宏

- 不要自己乱定义平台宏，直接用编译器内置的：
  - `_WIN32` → Windows
  - `__linux__` → Linux
  - `__APPLE__` → macOS

### 现代 C++ 替代方案

#### 宏常量

`#define PI 3.14` 只是文本替换，没有类型检查，调试信息不明确。

```cpp
const double pi = 3.14;          // 常量
constexpr double pi2 = 3.14159;  // 编译期常量（推荐）
```

- 有类型、安全，可参与模板/编译期计算。

#### 枚举常量 vs 宏枚举

```cpp
#define RED 0
#define GREEN 1
#define BLUE 2
```

- 全局污染、没有作用域。

```cpp
enum class Color { Red, Green, Blue };
```

- 作用域清晰，类型安全，不会与其他名字冲突。

#### 函数宏

`#define SQR(x) ((x)*(x))` 副作用：（`SQR(i++)` 错误）、无类型安全。

```cpp
inline int sqr(int x) { return x * x; }
template<typename T>
inline T sqr(T x) { return x * x; }
```

- 支持重载、模板，避免副作用。

#### 条件编译

`#ifdef DEBUG` 代码膨胀、阅读困难。

```cpp
if constexpr (debug_mode) {   // C++17
    std::cout << "调试信息\n";
}
```

- **编译器参数**控制宏（推荐 `-DDEBUG` 而不是写在代码里）
- **运行时调试开关**，这样不用删掉代码，只在编译期选择性生成。

#### 平台/编译器差异

```cpp
#ifdef _WIN32
    // Windows 代码
#else
    // 其他平台
#endif
```

代码可读性差，分支到处都是。

```cpp
if(WIN32)
    add_definitions(-DWINDOWS)
    add_executable(app win_main.cpp)
else()
    add_executable(app linux_main.cpp)
endif()
```

- 用 **抽象接口 + 多文件实现**
- 结合 **CMake/构建系统** 选择源文件

让构建系统替代 `#ifdef`，逻辑更清晰。

#### 头文件保护

```cpp
#ifndef MY_HEADER_H
#define MY_HEADER_H
...
#endif
```

现代替代：

```cpp
#pragma once
```

（非标准但几乎所有编译器支持，简洁且避免宏名冲突）

#### 调试打印（宏）

```cpp
#ifdef DEBUG
#define LOG(x) std::cout << x << std::endl;
#else
#define LOG(x)
#endif
```

替代（C++20 可变参数 + `if constexpr`）：

```cpp
constexpr bool debug = true;

template<typename... Args>
void log(Args&&... args) {
    if constexpr (debug) {  // 编译期条件
        (std::cout << ... << args) << '\n';  // fold expression
    }
}
```

#### 内置宏 (`__FILE__`, `__LINE__`)

这类还是很有用（调试信息），但可以**结合现代日志库**使用。比如 [spdlog](https://github.com/gabime/spdlog) 支持自动打印源文件、行号，比手动写宏更优雅。

#### 总结

- **宏常量 → `constexpr` / `const` / `enum class`**
- **函数宏 → `inline` 函数 / 模板**
- **条件编译 → `if constexpr` / 构建系统控制**
- **头文件保护 → `#pragma once`**
- **调试宏 → 模板日志函数 / 第三方库**