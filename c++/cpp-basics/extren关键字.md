## extern关键字

在 C++ 中，`extern` 是一个关键字，用来 **声明** 一个变量或函数是在其他文件（或作用域）中定义的，从而允许在多个文件中共享变量或函数定义。`extern` 主要用于 **跨文件访问变量或函数**，是实现多文件模块化编程的常用手段。

### 详细用法解析

#### 1. `extern` 用于变量

示例：跨文件共享变量

**file1.cpp**

```cpp
int globalVar = 42;  // 定义变量
```

**file2.cpp**

```cpp
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

#### 2. `extern` 用于函数

函数默认具有外部链接属性，因此即使不写 `extern`，也能跨文件使用。但加上 `extern` 更显式。

**file1.cpp**

```cpp
void sayHello() {
    std::cout << "Hello from file1!" << std::endl;
}
```

**file2.cpp**

```cpp
#include <iostream>
extern void sayHello();  // 声明函数

int main() {
    sayHello();
    return 0;
}
```

### 与 `static` 的对比

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

- `int x;` → 变量声明 + 定义（如果是全局变量，且不加 `extern`）

- `int x = 42;` → 明确初始化，是定义

- `extern int x;` → 纯声明，不分配内存，变量在别的地方定义

如果没有定义就使用，会链接错误（Linker Error）

```cpp
extern int x;
int main() {
    std::cout << x; // 如果没有定义 x，会链接失败
}
```

###  `extern` 常见用法场景

#### 场景1：共享全局变量

**头文件 global.h**

```cpp
extern int count;
```

**文件 global.cpp**

```cpp
int count = 0;
```

**文件 main.cpp**

```cpp
#include "global.h"
#include <iostream>

int main() {
    std::cout << count << std::endl;
}
```

#### 场景2：C++ 调用 C 语言函数（`extern "C"`）

```cpp
extern "C" void c_function(); // 告诉编译器用 C 的方式来链接
```

> #### 背景知识：C++ 和 C 的「名字修饰」不同（Name Mangling）
>
> - 在 C++ 中，函数名会被编译器**修饰（mangle）**，以支持函数重载。例如：
>
> ```cpp
> void foo(int);
> void foo(double);
> ```
>
> C++ 会把这两个函数的名字改为内部符号（伪代码）：
>
> ```cpp
> _Z3fooi        // foo(int)
> _Z3food        // foo(double)
> ```
>
> - 但在 C 语言中，不支持函数重载，函数名直接就是原始名字，例如：
>
> ```c
> void foo();  // 编译后就是符号 foo
> ```
> 
> ------
> 
> #### 问题来了：C++ 想调用一个用 C 写的函数怎么办？
>
> 如果在 C++ 中写：
>
> ```cpp
>void c_function();  // 默认是 C++ 链接方式，编译器可能找不到符号
> ```
>
> 但是实际这个函数是 C 写的、编译出来的符号叫 `c_function`（没有被修饰），C++ 链接器就找不到它，会报错：
> 
> ```javascript
> undefined reference to `c_function`
> ```
> 
> ------
>
> ####  正确做法：加 `extern "C"`，禁用 C++ 的 name mangling
>
> ```cpp
> extern "C" void c_function();
> ```
> 
> 这句告诉 C++ 编译器：
> 
> > “这个函数是用 C 的方式定义的，不要给它改名字，按 C 的方式来链接。”

##### 举个实际例子

**C 语言文件（c_code.c）：**

```c
#include <stdio.h>

void say_hello() {
    printf("Hello from C!\n");
}
```

**C++ 文件（main.cpp）：**

```cpp
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

##### 拓展：`extern "C"` 块状写法（推荐用于头文件）

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

##### 总结

| 写法                    | 含义                                     |
| ----------------------- | ---------------------------------------- |
| `extern "C"`            | 用 C 的方式链接（关闭 C++ 的函数名修饰） |
| `extern "C" { ... }`    | 一组函数都按 C 的方式链接                |
| `extern "C"` + C 头文件 | C++ 调用 C 编写的库的标准做法            |