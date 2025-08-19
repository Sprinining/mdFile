## static 关键字

### 静态的局部变量：**函数退出也保留值**

**`static` 定义的局部变量**在函数第一次调用时初始化，之后不会再次初始化；在随后的函数调用中会保留之前的值。它具有**静态存储期**，即在整个程序运行期间始终存在。

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

### 静态的全局变量：**只在本文件可见**

被 `static` 修饰的全局变量或函数**仅在当前源文件内可访问**，对其他 `.cpp` 文件不可见。这是 C 风格的模块化手段，可防止在头文件中出现符号冲突。

```cpp
// file1.cpp
static void helper() {  // 只能在 file1.cpp 中调用
    std::cout << "Helper" << std::endl;
}
```

`static` 修饰的局部变量具有静态存储期，即在整个程序运行期间都存在，但它的作用域仍仅限于定义它的函数内部，不能被其他函数访问。

### 静态的成员变量：**属于类本身**

所有对象共享，**无需创建实例即可访问**。**静态成员变量**必须在类外进行定义。

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

由于 `static` 成员变量是**类级别的，不属于任何对象**，它不参与构造函数初始化，也不会随对象创建而自动构造。它存储在全局数据区，而非类对象内部。

因此，**`static` 成员必须在类外单独定义并初始化**，不像普通成员变量（如 `int a = 10`）那样随对象构造自动初始化。

### 静态的成员函数：**属于类本身**

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

### 注意事项

- 静态成员变量**必须在类外定义**，否则链接失败。

- `static` 成员函数不能访问类的非静态成员（因为没有 `this`）。

- `static` 修饰的局部变量在多线程下不一定安全，推荐配合 `std::mutex` 或 `thread_local`。

- C++17 起还可以使用 `inline static` 在类中定义静态常量变量（避免类外定义）。

  - C++17 引入了 `inline static` 成员变量，告诉编译器：“我知道这个变量会在多个 `.cpp` 文件中重复出现，但它的定义一致，请你放心，别报重复定义。”

  ```cpp
  class MyClass {
  public:
      inline static int count = 0; // 合法，类内定义、多个翻译单元（Translation Unit, TU）不冲突
  };
  ```

  - 这是对变量应用 inline 的第一次正式标准化，也是借鉴了 C 的 `inline function` 模型。


### 如何写一个 “跨多个文件共享的类静态成员变量” 

要在 C++ 中正确地**定义一个“跨多个文件共享”的类静态成员变量**，要满足 C++ 的两个要求：

1. **类中声明**（头文件中）
2. **类外定义**（仅在一个 `.cpp` 文件中）

#### 正确写法（经典方式，适用于 C++98 ~ C++20）

头文件：`MyClass.h`

```cpp
#ifndef MYCLASS_H
#define MYCLASS_H

class MyClass {
public:
    static int counter; // 只是声明，不能在这里初始化（除非 inline 或 constexpr）
};

#endif
```

源文件：`MyClass.cpp`

```cpp
#include "MyClass.h"

int MyClass::counter = 0; // 必须在类外定义一次，负责分配存储空间
```

使用它的地方：

```cpp
#include "MyClass.h"

int main() {
    MyClass::counter++;
}
```

#### C++17 起的新写法：inline static

可以这样直接写在头文件中：

```cpp
// MyClass.h
class MyClass {
public:
    inline static int counter = 0; // C++17 起，类内定义也分配空间
};
```

然后就不需要在 `.cpp` 中再写一遍定义了。

> 多个翻译单元中 include 这个头文件也不会报 multiple definition，因为 `inline` 保证了 ODR（One Definition Rule）。

#### C++20 起更进一步：constinit

如果想在编译期就初始化，而且保证变量**一定初始化（不依赖顺序）**：

```cpp
class MyClass {
public:
    inline static constinit int counter = 0; // C++20，防止未初始化
};
```