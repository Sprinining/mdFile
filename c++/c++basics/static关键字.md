## static关键字

### 1. 函数内的 `static` 局部变量：**保留值，不随函数退出销毁**

- **作用：** 定义的变量只初始化一次，并在后续函数调用中保留上一次的值。
- **生命周期：** 整个程序运行期间（静态存储期）。

```cpp
void countCalls() {
    static int counter = 0;
    counter++;
    std::cout << "Call count: " << counter << std::endl;
}

int main() {
    countCalls(); // 输出 1
    countCalls(); // 输出 2
}
```

### 2. 类中的 `static` 成员变量或函数：**属于类，而不是某个对象**

- **作用：** 所有对象共享，不需要实例化对象即可访问。
- **静态成员变量**必须在类外定义。

```cpp
class MyClass {
public:
    int a = 10;
    static int count;      // 声明
    static void showCount() {
        std::cout << count << std::endl;
    }
};

int MyClass::count = 0;    // 定义

int main() {
    MyClass::count = 42;
    MyClass::showCount();  // 输出 42
}
```

因为 `static` 成员变量是**类级别的变量，不属于某个对象**，它不是构造函数初始化的一部分，也不会随着对象创建而自动构造。它的存储位置在全局数据区，不是类对象里。

所以 `static` 成员必须**单独定义并初始化**，不像 `int a = 10` 这种是随对象构造初始化的。

### 3. 全局作用域下的 `static`：**限制链接范围（内部链接）**

- **作用：** 被 `static` 修饰的全局变量或函数**只能在当前文件中访问**，不对其他 `.cpp` 文件可见。
- 这是 C 风格的模块化技巧，在头文件中避免符号冲突。

```cpp
// file1.cpp
static void helper() {  // 只能在 file1.cpp 中调用
    std::cout << "Helper" << std::endl;
}
```

### 4. 静态类函数（可配合 `this` 使用限制）

静态成员函数**不能访问非静态成员**，因为它不依赖类对象：

```cpp
class A {
    int x = 10;
    static int y;
public:
    static void printY() {
        // std::cout << x; // 错误！无法访问非静态成员
        std::cout << y << std::endl;
    }
};
int A::y = 100;
```

### 5. 注意事项

- 静态成员变量**必须在类外定义**，否则链接失败。

- `static` 成员函数不能访问类的非静态成员（因为没有 `this`）。

- `static` 修饰的局部变量在多线程下不一定安全，推荐配合 `std::mutex` 或 `thread_local`。

- C++17 起还可以使用 `inline static` 在类中定义静态常量变量（避免类外定义）。

C++17 引入了 `inline static` 成员变量，告诉编译器：

> “我知道这个变量会在多个 `.cpp` 文件中重复出现，但它的定义一致，请你放心，别报重复定义。”

```cpp
class MyClass {
public:
    inline static int count = 0; // ✅ 合法，类内定义、多个 TU 不冲突
};
```

这是对变量应用 inline 的第一次正式标准化，也是借鉴了 C 的 `inline function` 模型。

TU 通俗理解：

> 每个 `.cpp` 文件加上它 `#include` 的所有头文件，预处理完之后，就构成了一个独立的 **翻译单元（Translation Unit, TU）**。

也就是说：

```bash
main.cpp + 所有 #include 的头文件 → 一个 TU
util.cpp + 所有 #include 的头文件 → 另一个 TU
```

然后编译器会**分别**把每个 TU 编译成 `.o` 或 `.obj` 文件，最后交由链接器统一链接成可执行文件。

如果把变量或函数的定义写进头文件里，那就可能在多个 TU 中重复，必须用 `inline` 或 `static` 或 `constexpr` 这样的关键字让它合法。

### 6. 如何写一个 “跨多个文件共享的类静态成员变量” 

要在 C++ 中正确地 **定义一个“跨多个文件共享”的类静态成员变量**，要满足 C++ 的两个要求：

1. **类中声明**（头文件中）
2. **类外定义**（仅在一个 `.cpp` 文件中）

#### 正确写法（经典方式，适用于 C++98 ~ C++20）

头文件：`MyClass.h`

```cpp
#ifndef MYCLASS_H
#define MYCLASS_H

class MyClass {
public:
    static int counter; // ✅ 只是声明，不能在这里初始化（除非 inline 或 constexpr）
};

#endif
```

源文件：`MyClass.cpp`

```cpp
#include "MyClass.h"

int MyClass::counter = 0; // ✅ 必须在类外定义一次，负责分配存储空间
```

使用它的地方：

```cpp
#include "MyClass.h"

int main() {
    MyClass::counter++;
}
```

#### C++17 起的新写法：`inline static`（推荐，免 cpp 定义）

你可以这样直接写在头文件中：

```cpp
// MyClass.h
class MyClass {
public:
    inline static int counter = 0; // ✅ C++17 起，类内定义也分配空间
};
```

然后就不需要在 `.cpp` 中再写一遍定义了。

> 多个翻译单元中 include 这个头文件也不会报 multiple definition，因为 `inline` 保证了 ODR（One Definition Rule）。

#### C++20 起更进一步：`constinit`

如果你想在编译期就初始化，而且保证变量**一定初始化（不依赖顺序）**：

```cpp
class MyClass {
public:
    inline static constinit int counter = 0; // C++20，防止未初始化
};
```