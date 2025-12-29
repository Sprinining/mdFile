## CMake 简单使用

------

### CMake 简述

#### CMake 用途

CMake 用来生成构建文件（比如 Makefile），然后再用 make 去编译。

最基本流程：

```bash
cmake ..
make
```

- `cmake ..`
   读取 `CMakeLists.txt`
   **生成 Makefile**
- `make`
   根据 Makefile 调用 `g++` 编译代码

#### 为啥不直接写 Makefile

- Makefile 难写、难维护
- 跨平台很麻烦
- 项目一大就乱

CMake 不是只能生成 Makefile，它还能生成：

- Linux：Makefile / Ninja
- Windows：Visual Studio 工程
- macOS：Xcode 工程

但**原理都一样**：CMake 生成构建文件，构建工具（make）负责真正编译。

------

### 手动编译

#### 源码

main.cpp

```cpp
#include <iostream>
#include "head.h"

using namespace std;

int main(){
    int a = 10;
    int b = 4;
    cout << "a = " << a << ", " << "b = " << b << endl;
    cout << "a + b = " << add(a, b) << endl;
    cout << "a - b = " << subtract(a, b) << endl;
    cout << "a * b = " << multiply(a, b) << endl;
    cout << "a / b = " << divide(a, b) << endl;
    return 0;
}
```

head.h

```cpp
#ifndef _HEAD_H
#define _HEAD_H

int add(int, int);
int subtract(int, int);
int multiply(int, int);
double divide(int, int);

#endif
```

add.cpp

```cpp
#include "head.h"

const char* libVersion = "Library Version 1.0";

int add(int a, int b){
    return a + b;
}
```

sub.cpp

```cpp
#include "head.h"

int subtract(int a, int b){
    return a - b;
}
```

mult.cpp

```cpp
#include "head.h"

int multiply(int a, int b){
    return a * b;
}
```

div.cpp

```cpp
#include "head.h"

double divide(int a, int b){
    return (double) a / b;
}
```

#### 编译命令

在源文件所在目录执行：

```bash
 g++ *.cpp  -o app
```

编译链接后生成可执行文件 app，执行 `./app` 即可运行。

```bash
~/code/demo/d1$ ./app
a = 10, b = 4
a + b = 14
a - b = 6
a * b = 40
a / b = 2.5
```

> `./app` 是“直接运行当前目录的文件”。
>
> `app` 是“找 PATH”，除非把当前目录加到 PATH 中才能通过 `app` 直接执行。**默认不把当前目录加入 PATH，是出于安全考虑，防止误执行恶意程序**。

------

### 编写简单的 CMakeLists.txt

在源码目录创建一个 `CMakeLists.txt`。

```cmake
# 单行注释

#[[
    多行注释
]]

# 指定 CMake 的最低版本要求
# 如果本机 CMake 版本低于 3.22.0，会直接报错
cmake_minimum_required(VERSION 3.22.0)

# 定义项目名称
# test 是项目名，会影响生成的工程名、变量前缀等
project(test)

# 生成一个可执行文件
# app 是最终生成的可执行程序名
# 后面列出所有参与编译的源文件
add_executable(app
    main.cpp
    add.cpp
    sub.cpp
    mult.cpp
    div.cpp
)
```

在源码所在目录新建一个子目录 `build` 作为构建目录，并进入:

```bash
mkdir build
cd ./build
```

执行 `cmake ..` (命令格式为 `cmake CMakeLists.txt所在目录`)：

```bash
~/code/demo/d1/build$ cmake ..
-- The C compiler identification is GNU 11.4.0
-- The CXX compiler identification is GNU 11.4.0
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: /usr/bin/cc - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: /usr/bin/c++ - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Configuring done
-- Generating done
-- Build files have been written to: /home/sylvan/code/demo/d1/build
```

生成了 Makefile + 一堆 CMake 的缓存/配置文件：

```bash
~/code/demo/d1/build$ ls
CMakeCache.txt  CMakeFiles  Makefile  cmake_install.cmake
```

执行 `make` 根据 Makefile 里的规则，把源码编译成可执行文件或库：

```bash
~/code/demo/d1/build$ make
[ 16%] Building CXX object CMakeFiles/app.dir/main.cpp.o
[ 33%] Building CXX object CMakeFiles/app.dir/add.cpp.o
[ 50%] Building CXX object CMakeFiles/app.dir/sub.cpp.o
[ 66%] Building CXX object CMakeFiles/app.dir/mult.cpp.o
[ 83%] Building CXX object CMakeFiles/app.dir/div.cpp.o
[100%] Linking CXX executable app
[100%] Built target app
```

此时构建目录下多出个可执行文件 `app`：

```bash
~/code/demo/d1/build$ ls
CMakeCache.txt  CMakeFiles  Makefile  app  cmake_install.cmake

~/code/demo/d1/build$ ./app
a = 10, b = 4
a + b = 14
a - b = 6
a * b = 40
a / b = 2.5
```

------

### set

#### 基本用法

```cmake
set(VAR_NAME value)
```

- `VAR_NAME` 是变量名
- `value` 是变量值（可以是单个值，也可以是列表）

例如：

```cmake
set(SOURCES main.cpp add.cpp sub.cpp mult.cpp div.cpp)
```

- 定义了一个叫 `SOURCES` 的变量
- 里面存了五个文件名

#### 使用变量

用 `${}` 访问变量：

```cmake
add_executable(app ${SOURCES})
```

效果和直接写源文件一样。

#### 列表写法

CMake 变量内部本质是**列表**，元素用 `;` 分隔：

```cmake
set(MYLIST a;b;c)
message("${MYLIST}")  # 执行 cmake . 时，会在终端输出 a;b;c
```

- 在命令中 `${MYLIST}` 会被展开成空格分隔列表

#### 额外参数（可选）

- `CACHE`：把变量写入 CMakeCache.txt，用户可在 GUI/命令行修改
- `FORCE`：覆盖已有值

示例：

```cmake
set(MYVAR "Debug" CACHE STRING "Build type" FORCE)
```

- `MYVAR`
  - 变量名，这里叫 `MYVAR`
  - 后续可以用 `${MYVAR}` 访问

- `"Debug"`
  - 变量值，这里设置为 `"Debug"`
  - 通常用于指定编译模式（Debug / Release）

- `CACHE`
  - 表示把这个变量存入 **CMakeCache.txt**
  - 存入缓存后，可以在 CMake GUI 或命令行修改

- `STRING`
  - 指定变量类型
  - 还有 `BOOL`、`PATH` 等类型，CMake 会根据类型做简单校验

- `"Build type"`
  - 变量的描述信息
  - 用于 CMake GUI 显示提示文字，帮助用户理解这个变量干啥的

- `FORCE`
  - 如果变量已经存在缓存里，也会**强制覆盖为新值**
  - 没加 FORCE 的话，已有缓存值不会被覆盖

#### 内置的特殊变量

##### C++ 标准

控制编译器使用哪一版 C++：

```cmake
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)   # 必须严格使用这个标准
set(CMAKE_CXX_EXTENSIONS OFF)         # 不使用编译器特有扩展
```

- `CMAKE_CXX_STANDARD`：C++版本（11/14/17/20 …）
- `CMAKE_CXX_STANDARD_REQUIRED`：是否必须严格遵守
- `CMAKE_CXX_EXTENSIONS`：关闭 GNU/MSC 扩展，保证跨平台

##### 输出目录

控制可执行文件或库生成位置：

```cmake
# 可执行文件输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# 静态/动态库输出目录
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
```

- `${CMAKE_BINARY_DIR}` 是构建目录
- 这样可以把所有可执行文件和库统一放到 `build/bin` 或 `build/lib`，源码目录干净

##### 构建类型（Debug/Release）

```cmake
set(CMAKE_BUILD_TYPE Debug)   # 可选：Debug, Release, RelWithDebInfo, MinSizeRel
```

- **Debug**：开启调试信息，通常不优化
- **Release**：优化编译，关闭调试信息
- **RelWithDebInfo**：优化 + 带调试信息
- **MinSizeRel**：优化 + 尽量小的二进制

注意：在多配置 IDE（如 VS/Xcode）里，这个变量不起作用，用 IDE 自己选择配置。

##### 编译选项

可以针对所有目标添加编译参数：

```cmake
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")
```

或者针对某个目标：

```cmake
target_compile_options(app PRIVATE -Wall -Wextra)
```

------

### 搜索文件

`file()` 是 CMake 的“文件系统工具命令”，用来操作和查询文件。

```cmake
file(GLOB SRC "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp")

add_executable(app ${SRC})
```

- 在**当前 CMakeLists.txt 所在目录**
- 找所有匹配 `*.cpp` 的文件
- 存到变量 `SRC`（列表）

递归搜索：

```cmake
file(GLOB_RECURSE VAR "bulid/*.cpp")
```

| 变量                       | 含义                             |
| -------------------------- | -------------------------------- |
| `CMAKE_SOURCE_DIR`         | **项目根目录**                   |
| `CMAKE_CURRENT_SOURCE_DIR` | **当前 CMakeLists.txt 所在目录** |

注意：新增 / 删除源文件时，CMake 不会自动重新运行，不推荐在正式项目用 `file(GLOB …)` 用来收集源码。

------

### 指定头文件路径

目录结构：

```bash
~/code/demo/d1$ tree
.
├── CMakeLists.txt
├── build
├── include
│   └── head.h
└── src
    ├── add.cpp
    ├── div.cpp
    ├── main.cpp
    ├── mult.cpp
    └── sub.cpp

3 directories, 7 files
```

CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.22.0)

project(test)

file(GLOB SRC "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")

add_executable(app ${SRC})
```

这时如果执行 cmake，然后再执行 make，会报错：

```bash
~/code/demo/d1/build$ make
[ 16%] Building CXX object CMakeFiles/app.dir/src/add.cpp.o
/home/sylvan/code/demo/d1/src/add.cpp:1:10: fatal error: head.h: No such file or directory
    1 | #include "head.h"
      |          ^~~~~~~~
compilation terminated.
make[2]: *** [CMakeFiles/app.dir/build.make:76: CMakeFiles/app.dir/src/add.cpp.o] Error 1
make[1]: *** [CMakeFiles/Makefile2:83: CMakeFiles/app.dir/all] Error 2
make: *** [Makefile:91: all] Error 2
```

提示找不到头文件。

#### 方案一

有两种解决方案，第一种是修改所有的 `cpp` 源文件：

```cpp
#include "../include/head.h"
```

#### 方案二

第二种方法是在 CMakeLists.txt 中使用 `include_directories` 指定头文件的路径：

```cmake
include_directories(${PROJECT_SOURCE_DIR}/include)
```

- `${PROJECT_SOURCE_DIR}`
  - **项目根目录**
  - 等价于最外层 `CMakeLists.txt` 所在目录

- `/include`
  - 通常放 `.h / .hpp` 的目录

- `include_directories(...)`
  - 告诉编译器：“编译时去这个目录找头文件”

等价于 g++ 的：

```bash
-I/path/to/project/include
```

`include_directories` 是**全局的**，影响后面所有目标。

#### 更推荐的现代写法

```cmake
target_include_directories(app
    PRIVATE
    ${PROJECT_SOURCE_DIR}/include
)
```

- `app`
  - 目标名
  - 必须是已经存在的目标（比如 `add_executable(app ...)`），要写在 `add_executable` 之后

- `PRIVATE`

  - 作用范围关键字：

  | 关键字        | 意义                                          | 传播情况                             | 举例                                                         |
  | ------------- | --------------------------------------------- | ------------------------------------ | ------------------------------------------------------------ |
  | **PRIVATE**   | 只对当前 target 生效                          | 不传播给依赖它的 target              | `target_include_directories(app PRIVATE include/)` → 只有 `app` 自己能看到头文件 |
  | **PUBLIC**    | 对当前 target 生效，并传播给依赖它的 target   | 当前 target + 依赖它的 target 都可见 | `target_include_directories(math PUBLIC include/)` → `math` 自己可见，`app` 链接 `math` 后也能看到头文件 |
  | **INTERFACE** | 只传播给依赖它的 target，本 target 本身不使用 | 只传播，不对自己生效                 | `target_include_directories(math INTERFACE include/)` → `math` 本身不需要头文件，但链接它的 target 会用 |

- `${PROJECT_SOURCE_DIR}/include`
  - 项目根目录下的 `include` 文件夹
  - 编译时会加到 `-I` 搜索路径

------

### 制作库文件

#### 静态库对比动态库

| 特性               | 静态库（Static Library）             | 动态库（Shared / Dynamic Library）                           |
| ------------------ | ------------------------------------ | ------------------------------------------------------------ |
| **文件类型**       | Linux/macOS: `.a` Windows: `.lib`    | Linux: `.so` macOS: `.dylib` Windows: `.dll`（运行）+ `.lib`（导入库） |
| **生成方式**       | `add_library(name STATIC …)`         | `add_library(name SHARED …)`                                 |
| **链接方式**       | 编译时链接，代码直接拷贝到可执行文件 | 编译时只链接符号，运行时加载库文件                           |
| **可执行文件大小** | 较大（包含库代码）                   | 较小（只含符号表）                                           |
| **运行依赖**       | 不依赖外部库                         | 必须能找到库文件（路径或系统搜索）                           |
| **内存占用**       | 每个程序有独立副本                   | 多个程序共享同一份动态库内存                                 |
| **更新与维护**     | 更新库需要重新编译可执行文件         | 更新库文件即可，程序自动使用新版本                           |
| **复用性**         | 低，可执行文件无法共享               | 高，多个程序可共享                                           |
| **适用场景**       | 小项目、独立运行、不依赖外部库       | 多程序共享功能、插件架构、节省磁盘/内存                      |

#### 生成的库名在不同平台的区别

##### 静态库

| 平台               | 文件名规则          | 示例        |
| ------------------ | ------------------- | ----------- |
| **Linux**          | `lib` + 名字 + `.a` | `libmath.a` |
| **macOS**          | `lib` + 名字 + `.a` | `libmath.a` |
| **Windows (MSVC)** | 名字 + `.lib`       | `math.lib`  |

##### 动态库

| 平台        | 文件名规则              | 示例            |
| ----------- | ----------------------- | --------------- |
| **Linux**   | `lib` + 名字 + `.so`    | `libmath.so`    |
| **macOS**   | `lib` + 名字 + `.dylib` | `libmath.dylib` |
| **Windows** | 名字 + `.dll`           | `math.dll`      |

**Windows 动态库通常还会额外生成一个 `.lib`（导入库）**。

动态库在 Windows 实际会有两个文件：

```
math.dll   # 运行时用
math.lib   # 编译/链接时用（导入库）
```

链接时用的是 `.lib`，运行时真正加载的是 `.dll`。

##### CMake 里的“统一视角”

```cmake
add_library(math STATIC ...)   # 静态库
add_library(math SHARED ...)   # 动态库
```

在 CMake 里**永远只用 target 名 `math`**：

```cmake
target_link_libraries(app math)
```

CMake 会自动生成并链接：

- Linux → `libmath.a / libmath.so`
- Windows → `math.lib / math.dll`

#### 制作动态库

文件结构：

```bash
~/code/demo/d2$ tree
.
├── CMakeLists.txt
├── build
├── include
│   └── head.h
├── main.cpp
└── src
    ├── add.cpp
    ├── div.cpp
    ├── mult.cpp
    └── sub.cpp

3 directories, 7 files
```

CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.22.0)

project(test)

file(GLOB SRC "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")

# 动态库
add_library(math SHARED ${SRC})

target_include_directories(math
    PRIVATE
    ${PROJECT_SOURCE_DIR}/include
)
```

```bash
~/code/demo/d2/build$ cmake ..
-- The C compiler identification is GNU 11.4.0
-- The CXX compiler identification is GNU 11.4.0
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: /usr/bin/cc - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: /usr/bin/c++ - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Configuring done
-- Generating done
-- Build files have been written to: /home/sylvan/code/demo/d2/build

~/code/demo/d2/build$ ls
CMakeCache.txt  CMakeFiles  Makefile  cmake_install.cmake

~/code/demo/d2/build$ make
[ 20%] Building CXX object CMakeFiles/math.dir/src/add.cpp.o
[ 40%] Building CXX object CMakeFiles/math.dir/src/div.cpp.o
[ 60%] Building CXX object CMakeFiles/math.dir/src/mult.cpp.o
[ 80%] Building CXX object CMakeFiles/math.dir/src/sub.cpp.o
[100%] Linking CXX shared library libmath.so
[100%] Built target math

~/code/demo/d2/build$ ls
CMakeCache.txt  CMakeFiles  Makefile  cmake_install.cmake  libmath.so
```

也可以指定库文件的输出目录：

```cmake
set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/lib)
```

不支持按 target 区分静态/动态库输出。

更推荐的写法：

- **全局变量**：

```cmake
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/lib)   # 静态库
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/lib)   # 动态库
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/bin)   # 可执行文件
```

- **target 属性**：

```cmake
set_target_properties(math PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/lib
    LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/lib
)
```

------

### 在程序中链接静态库

**发布库 = 库文件 + 头文件**

- 库文件：实现
- 头文件：接口

**用户拿到这两样，就能在自己的项目里使用库而不需要源码。**

目录结构：

```bash
~/code/demo/d3$ tree
.
├── CMakeLists.txt
├── build
├── include
│   └── head.h
├── lib
│   ├── libmath.a
│   └── libmath.so
└── main.cpp

3 directories, 5 files
```

CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.22.0)
project(test)

add_executable(app main.cpp)

# 头文件路径
target_include_directories(app
    PRIVATE ${PROJECT_SOURCE_DIR}/include
)

# 链接已有库
target_link_libraries(app
    PRIVATE
        ${PROJECT_SOURCE_DIR}/lib/libmath.a   # 静态库
        # 或者 ${PROJECT_SOURCE_DIR}/lib/libmath.so 动态库
)
```

#### 链接库搜索路径

##### 使用绝对路径

```cmake
target_link_libraries(app PRIVATE ${PROJECT_SOURCE_DIR}/lib/libmath.a)
```

##### 使用全局搜索路径

```cmake
link_directories(${PROJECT_SOURCE_DIR}/lib)
target_link_libraries(app PRIVATE math)
```

- `link_directories()` 告诉 CMake 在哪些目录找库
- 后面 `target_link_libraries(app PRIVATE math)` 会去这些目录找 `libmath.a` / `libmath.so`

##### CMake 内部 target

如果库是用 `add_library` 定义的 target：

```cmake
add_library(math STATIC math.cpp)
add_executable(app main.cpp)
target_link_libraries(app PRIVATE math)
```

- CMake **自动知道 `math` 的输出目录**，不需要 `link_directories()`

------

### 打印日志

`message()` 是 CMake 提供的一个**输出调试或提示信息的命令**。

```cmake
message([<mode>] "文本内容")
```

- `<mode>` 可选，表示信息类型
- `"文本内容"` 是要输出的字符串

| mode             | 作用                                                         |
| ---------------- | ------------------------------------------------------------ |
| `STATUS`         | 普通状态信息，会在 CMake 配置输出中显示（默认）              |
| `WARNING`        | 警告信息，会在输出中以 `-- WARNING:` 前缀显示                |
| `AUTHOR_WARNING` | 仅当 `CMAKE_SUPPRESS_DEVELOPER_WARNINGS` 为 `FALSE` 时显示，作者警告 |
| `SEND_ERROR`     | 发送错误，但继续配置，不终止 CMake 运行                      |
| `FATAL_ERROR`    | 致命错误，停止 CMake 配置                                    |
| `DEPRECATION`    | 过期提示，用于提醒某些命令或变量不推荐使用                   |

CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.22.0)
project(test)

add_executable(app main.cpp)

# 头文件路径
target_include_directories(app
    PRIVATE ${PROJECT_SOURCE_DIR}/include
)

# 链接已有库
target_link_libraries(app
    PRIVATE
        ${PROJECT_SOURCE_DIR}/lib/libmath.a   # 静态库
)

# 普通状态信息
message(STATUS "Configuring project...")

# 警告信息
message(WARNING "This feature is experimental.")

# 错误信息（仍然继续）
message(SEND_ERROR "Something went wrong.")

# 致命错误（停止 CMake）
# message(FATAL_ERROR "Cannot proceed!")
```

执行 `cmake` 输出：

```bash
~/code/demo/d3/build$ cmake ..
-- The C compiler identification is GNU 11.4.0
-- The CXX compiler identification is GNU 11.4.0
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: /usr/bin/cc - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: /usr/bin/c++ - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Configuring project...
CMake Warning at CMakeLists.txt:22 (message):
  This feature is experimental.


CMake Error at CMakeLists.txt:25 (message):
  Something went wrong.


-- Configuring incomplete, errors occurred!
See also "/home/sylvan/code/demo/d3/build/CMakeFiles/CMakeOutput.log".
```

------

### string

#### 基本语法

```cmake
string(<操作> <输出变量> <参数...>)
```

- `<操作>`：字符串操作类型
- `<输出变量>`：保存结果的 CMake 变量
- `<参数>`：输入的字符串或其他选项

#### 常用操作类型

| 操作                  | 说明           | 示例                                                         |
| --------------------- | -------------- | ------------------------------------------------------------ |
| `LENGTH`              | 计算字符串长度 | `string(LENGTH "Hello" len)` → `len=5`                       |
| `SUBSTRING`           | 取子串         | `string(SUBSTRING "Hello" 1 3 sub)` → `sub="ell"`            |
| `FIND`                | 查找子串位置   | `string(FIND "Hello" "l" pos)` → `pos=2`                     |
| `REPLACE`             | 替换字符串     | `string(REPLACE "l" "x" "Hello" out)` → `out="Hexxo"`        |
| `TOUPPER` / `TOLOWER` | 转大小写       | `string(TOUPPER "Hello" upper)` → `upper="HELLO"`            |
| `APPEND`              | 追加字符串     | `string(APPEND var "World")`                                 |
| `STRIP`               | 去掉前后空格   | `string(STRIP " Hello " stripped)` → `stripped="Hello"`      |
| `REGEX MATCH`         | 正则匹配       | `string(REGEX MATCH "H.*o" match "Hello")` → `match="Hello"` |
| `REGEX REPLACE`       | 正则替换       | `string(REGEX REPLACE "[aeiou]" "*" "Hello" out)` → `out="H*ll*"` |

------

### list

#### 基本语法

```cmake
list(<操作> <列表变量> <参数...>)
```

- `<操作>`：列表操作类型
- `<列表变量>`：保存或操作的列表变量
- `<参数>`：操作元素或索引等

#### 常用操作类型

| 操作                     | 说明                 | 示例                           |
| ------------------------ | -------------------- | ------------------------------ |
| `LENGTH`                 | 返回列表长度         | `list(LENGTH mylist len)`      |
| `GET`                    | 取指定索引元素       | `list(GET mylist 1 elem)`      |
| `APPEND`                 | 添加元素到末尾       | `list(APPEND mylist "new")`    |
| `INSERT`                 | 插入元素             | `list(INSERT mylist 2 "x")`    |
| `REMOVE_AT`              | 删除指定索引         | `list(REMOVE_AT mylist 1)`     |
| `REMOVE_ITEM`            | 删除指定值           | `list(REMOVE_ITEM mylist "b")` |
| `FIND`                   | 查找元素索引         | `list(FIND mylist "b" idx)`    |
| `JOIN`                   | 列表元素合并成字符串 | `list(JOIN mylist "," str)`    |
| `POP_FRONT` / `POP_BACK` | 弹出头/尾元素        | `list(POP_BACK mylist elem)`   |
| `REVERSE`                | 反转列表             | `list(REVERSE mylist)`         |
| `SORT`                   | 排序                 | `list(SORT mylist)`            |

------

### 生成编译器预处理宏

```cmake
# 定义一个宏 MY_MACRO
add_definitions(-DMY_MACRO)

# 定义带值的宏 VERSION=3
add_definitions(-DVERSION=3)
```

等价于在 C++ 代码里写：

```cpp
#define MY_MACRO
#define VERSION 3
```

命令行加 `-D` 语法：

```bash
cmake -DMY_MACRO=1 -DVERSION=3 ..
```

这些变量可以在 CMakeLists.txt 中读取，也可以用于控制编译器宏。

**现代 CMake 推荐**用 `target_compile_definitions()` 替代 `add_definitions()`，因为它可以**指定 target 并控制 PRIVATE/PUBLIC/INTERFACE**：

```cmake
add_executable(app main.cpp)
target_compile_definitions(app PRIVATE MY_MACRO=1)
```

------

### 嵌套 CMakeLists.txt

目录结构：

```bash
MyProject/
├── CMakeLists.txt         # 顶层
├── src/
│   ├── CMakeLists.txt     # 子目录
│   ├── math.cpp
│   └── math.h
├── app/
│   ├── CMakeLists.txt     # 子目录
│   └── main.cpp
└── tests/
    ├── CMakeLists.txt     # 子目录
    └── test_main.cpp
```

顶层 CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.22)
project(MyProject)

set(CMAKE_CXX_STANDARD 17)

# 添加子目录
add_subdirectory(src)
add_subdirectory(app)
add_subdirectory(tests)
```

- `add_subdirectory` 会让 CMake 进入对应目录执行子目录的 CMakeLists.txt
- 顶层管理全局选项和子模块构建顺序

src/CMakeLists.txt

```cmake
# 源文件
file(GLOB SRC "*.cpp")

# 创建静态库 math
add_library(math STATIC ${SRC})

# 头文件路径
target_include_directories(math PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
```

- `math` 库在子目录中创建
- `PUBLIC` 表示使用这个库的 target 可以继承头文件路径

app/CMakeLists.txt

```cmake
add_executable(app main.cpp)

# 链接 src 中的 math 库
target_link_libraries(app PRIVATE math)
```

- 可执行文件 `app` 依赖 `math`
- CMake 会自动知道 `math` 是静态库，并处理链接顺序

tests/CMakeLists.txt

```cmake
add_executable(test_app test_main.cpp)

# 链接 math 库
target_link_libraries(test_app PRIVATE math)
```

- 测试程序也依赖 `math`
- 不需要重复添加源文件，只需引用库
