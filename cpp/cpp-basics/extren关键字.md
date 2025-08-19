## extern 关键字

在 C++ 中，`extern` 是一个关键字，用来 **声明** 一个变量或函数是在其他文件（或作用域）中定义的，从而允许在多个文件中共享变量或函数定义。`extern` 主要用于 **跨文件访问变量或函数**，是实现多文件模块化编程的常用手段。

### 详细用法解析

#### 用于变量

```cpp
// file1.cpp
int globalVar = 42;  // 定义变量

// file2.cpp
extern int globalVar;  // 声明变量，告诉编译器它在别处定义

#include <iostream>
int main() {
    std::cout << globalVar << std::endl;
    return 0;
}
```

编译方法（用 g++）：

```cpp
g++ file1.cpp file2.cpp -o program
```

链接器会在链接阶段把 `file1.cpp` 中的定义和 `file2.cpp` 的引用匹配起来。

虽然 `file2.cpp` 可以不用头文件，但**通常建议用头文件统一声明**，例如：

```cpp
// globals.h
extern int globalVar;

// file1.cpp
#include "globals.h"
int globalVar = 42;  // 定义

// file2.cpp
#include "globals.h"
#include <iostream>

int main() {
    std::cout << globalVar << std::endl;
    return 0;
}
```

- 避免在多个源文件中重复写 `extern int globalVar;`
- 如果变量类型或名字改了，只需改头文件，保持一致性

#### 用于函数

函数默认具有外部链接属性，因此即使不写 `extern`，也能跨文件使用。但加上 `extern` 更显式。

**file1.cpp**

```cpp
// file1.cpp
void sayHello() {
    std::cout << "Hello from file1!" << std::endl;
}

// file2.cpp
#include <iostream>
extern void sayHello();  // 声明函数

int main() {
    sayHello();
    return 0;
}
```

虽然可以直接声明 `extern`，但**推荐通过头文件统一声明**：

```cpp
// hello.h
#pragma once
#include <iostream>
void sayHello();

// file1.cpp
#include "hello.h"

void sayHello() {
    std::cout << "Hello from file1!" << std::endl;
}

// file2.cpp
#include "hello.h"

int main() {
    sayHello();
    return 0;
}
```

- 避免在多个源文件中重复写函数声明
- 保证函数签名一致，防止类型不匹配
- 易于维护：修改函数签名只需改头文件

#### 调用 C 语言函数

##### C++ 和 C 的名字修饰不同

在 C++ 中，函数名会被编译器**修饰（mangle）**，以支持函数重载。

```cpp
void foo(int);
void foo(double);
```

- C++ 会把这两个函数的名字改为内部符号（伪代码）：

```cpp
_Z3fooi        // foo(int)
_Z3food        // foo(double)
```

但在 C 语言中，不支持函数重载，函数名直接就是原始名字，：

```c
void foo();  // 编译后就是符号 foo
```

##### C++ 想调用一个用 C 写的函数怎么办？

如果在 C++ 中写：

```cpp
void c_function();  // 默认是 C++ 链接方式，编译器可能找不到符号
```

但是实际这个函数是 C 写的、编译出来的符号叫 `c_function`（没有被修饰），C++ 链接器就找不到它，会报错：

```javascript
undefined reference to `c_function`
```

##### 正确做法

加 `extern "C"`，禁用 C++ 的 name mangling：

```cpp
extern "C" void c_function(); // 告诉编译器用 C 的方式来链接
```

##### 举个实际例子

```c
// c_code.c
#include <stdio.h>

void say_hello() {
    printf("Hello from C!\n");
}

// main.cpp
extern "C" void say_hello();  // 告诉编译器：这是 C 函数

int main() {
    say_hello();
    return 0;
}
```

编译：

```bash
gcc -c c_code.c
g++ main.cpp c_code.o -o program
```

##### extern "C" 块状写法

```cpp
#ifdef __cplusplus
extern "C" {
#endif

void c_function1();
void c_function2();

#ifdef __cplusplus
}
#endif
```

这样写可以让头文件在 **C 和 C++ 中都能兼容使用**。

| 写法                    | 含义                                     |
| ----------------------- | ---------------------------------------- |
| `extern "C"`            | 用 C 的方式链接（关闭 C++ 的函数名修饰） |
| `extern "C" { ... }`    | 一组函数都按 C 的方式链接                |
| `extern "C"` + C 头文件 | C++ 调用 C 编写的库的标准做法            |

### 与 static 的对比

| 关键词   | 作用域         | 链接类型 | 是否跨文件共享 |
| -------- | -------------- | -------- | -------------- |
| `extern` | 全局或局部     | 外部链接 | 可以           |
| `static` | 文件内部或函数 | 内部链接 | 不可以         |

### 注意事项

`extern` 是声明，不是定义

```cpp
extern int x; // 声明，不分配内存
int x = 10;   // 定义，分配内存
```

如果没有定义就使用，会链接错误（Linker Error）

```cpp
extern int x;
int main() {
    std::cout << x; // 如果没有定义 x，会链接失败
}
```

| 写法                          | 声明（Declaration） | 定义（Definition） | 内存分配                  | 说明                                         |
| ----------------------------- | ------------------- | ------------------ | ------------------------- | -------------------------------------------- |
| `int x;`                      | 隐含声明            | 是定义             | 分配内存（全局/BSS 或栈） | 未初始化的全局变量自动为 0，局部变量值未定义 |
| `int x = 42;`                 | 隐含声明            | 是定义             | 分配内存并初始化          | 全局变量放在已初始化数据段，局部变量放在栈上 |
| `extern int x;`               | 仅声明              | 不是定义           | 不分配内存                | 告诉编译器变量定义在别的地方                 |
| `extern int x = 42;` (C++17+) | 声明                | 定义               | 分配内存并初始化          | 同时声明和定义，允许在 C++17 及以后版本使用  |