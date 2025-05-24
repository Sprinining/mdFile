## C++预处理器

C++ 的预处理器（Preprocessor）是一个在编译之前运行的文本处理工具，它主要用于对源代码进行宏替换、文件包含、条件编译等操作。预处理器指令都是以 `#` 开头的，在真正的编译过程开始前执行。

### 常用的预处理指令

#### 1. `#define`：定义宏

```cpp
#define PI 3.14159
#define MAX(a, b) ((a) > (b) ? (a) : (b))
```

- **对象宏**：将 `PI` 替换为 `3.14159`
- **函数宏**：可传参，注意加括号避免优先级错误

#### 2. `#undef`：取消宏定义

```cpp
#undef PI
```

取消之前通过 `#define` 定义的宏。

------

#### 3. `#include`：包含文件

```cpp
#include <iostream>  // 标准库头文件
#include "myheader.h" // 自定义头文件
```

- `<>`：查找系统目录中的头文件
- `""`：先在当前目录查找，再查找系统目录

------

#### 4. 条件编译：`#if`、`#ifdef`、`#ifndef`、`#else`、`#elif`、`#endif`

##### 示例 1：防止头文件重复包含

```cpp
#ifndef MY_HEADER_H
#define MY_HEADER_H

// 头文件内容

#endif
```

常用于防止头文件重复定义。

##### 示例 2：宏控制

```cpp
#define DEBUG

#ifdef DEBUG
    std::cout << "调试信息" << std::endl;
#endif
```

------

#### 5. `#error` 和 `#pragma`

##### `#error`：强制报错

```cpp
#ifndef VERSION
#error "VERSION 未定义"
#endif
```

##### `#pragma`：编译器相关扩展指令

```cpp
#pragma once
```

- 作用类似于 include guard，防止头文件重复包含。
- 非标准但几乎所有主流编译器支持。

### 预处理器的工作流程（编译前）

源文件 `main.cpp`：

```cpp
#include <iostream>
#define PI 3.14

int main() {
    std::cout << "PI = " << PI << std::endl;
    return 0;
}
```

预处理后代码：

```cpp
// #include 展开 iostream 的内容
// #define PI 替换为 3.14

int main() {
    std::cout << "PI = " << 3.14 << std::endl;
    return 0;
}
```

### 调试预处理结果

GCC / Clang：

```bash
g++ -E main.cpp -o main.i
```

`-E` 表示只运行预处理阶段，输出到 `main.i` 文件中。

### 预处理器使用技巧与注意事项

#### 优点

- 条件编译灵活控制平台相关、调试信息
- 宏可简化重复代码
- 支持跨平台编译

#### 注意事项

- 宏不是类型安全的，比如函数宏容易出错
- 宏无作用域，容易污染命名空间
- 能用 `const`、`inline`、`template` 替代宏时，尽量不用宏

### 现代 C++ 替代方案（推荐）

| 宏功能           | 替代方案                   |
| ---------------- | -------------------------- |
| `#define 常量`   | `const` 或 `constexpr`     |
| `#define 宏函数` | `inline` 函数或 `template` |
| 条件编译         | `if constexpr`（C++17 起） |