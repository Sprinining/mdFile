## CMake 简单使用（上）

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
