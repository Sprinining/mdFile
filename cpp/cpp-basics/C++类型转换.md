## C++ 类型转换

C++ 中的类型转换是指将一种数据类型的值转换为另一种数据类型。C++ 提供了**隐式类型转换**和**显式类型转换**两种方式，另外引入了更安全和可控的 **C++ 风格的类型转换**。

### 隐式类型转换

编译器自动完成的类型转换，主要发生在以下情况：

#### 算术运算中不同类型的转换

```cpp
int a = 10;
double b = 3.14;
double c = a + b; // a 被自动转换为 double
```

#### 函数参数传递时类型不匹配

```cpp
void func(double x);
func(5); // 5 是 int，会被自动转换为 double
```

#### 赋值语句中类型不同

```cpp
int i = 3.14; // double -> int，发生截断
```

### 显式类型转换

显式转换由程序员主动触发，常见形式：

#### C 风格的强制类型转换（不推荐）

```cpp
double d = 3.14;
int i = (int)d;
```

#### C++ 风格的类型转换（推荐）

更安全、语义更清晰。主要包括以下四种：

### C++ 类型转换运算符

#### 静态转换：static_cast\<T>()

用于**基本类型之间的转换**，或类之间**存在继承关系且已知安全的转换**。

```cpp
int i = 10;
double d = static_cast<double>(i); // int -> double

class Base {};
class Derived : public Base {};
Base* b = new Derived();
Derived* d = static_cast<Derived*>(b); // 已知 b 实际上指向 Derived*
```

#### 动态转换：dynamic_cast\<T>()

用于**运行时类型检查的指针或引用转换**，只能用于多态类型（即有虚函数的类）。

```cpp
class Base { virtual void foo() {} };
class Derived : public Base {};

Base* b = new Derived();
Derived* d = dynamic_cast<Derived*>(b); // 安全转换
```

- 如果转换失败，指针返回 `nullptr`，引用会抛出 `std::bad_cast`。

#### 常量转换：const_cast\<T>()

`const_cast` 的作用是**改变指针或引用的底层类型（pointee type）的 cv 限定符**，可以去除 或添加底层 `const`、`volatile`。

```cpp
// 这里 new int(10) 创建了一个 非 const 的 int，值是 10
// 但是用一个 const int* 指针来接收它，意思是承诺不通过 p 来修改它的值
const int* p = new int(10);
// 使用 const_cast 去掉了 p 的 const 限定，使得 q 成为了可以修改的普通指针
int* q = const_cast<int*>(p);
```

- `const int* p` 只是**承诺不改**，但指向的其实是一个**原本可以修改的对象**（`new int(10)` 创建的是普通 `int`）。

- 也就是说，虽然**声明时用了 `const` 修饰指针类型**，但没有真正地创建一个 `const` 对象，所以这时候能用 `*q = 20` 来修改值。

使用 `const_cast` 修改数据，必须**保证原始对象不是 const 的**：

```cpp
#include <iostream>

int main() {
    const int a = 10;               // 声明一个 const int 类型的变量 a，值为 10，不允许修改
    const int* p = &a;              // 声明一个指向 const int 的指针 p，指向 a，表示不能通过 p 修改 a

    int* q = const_cast<int*>(p);   // 使用 const_cast 去掉指针的 const 限定符，将 p 转换为 int* 类型
                                    // 注意：虽然语法上合法，但如果修改的是一个真正的 const 对象（比如 a），则行为是未定义的！

    *q = 20;                        // 尝试通过 q 修改 a 的值为 20 —— 未定义行为！
                                    // 在某些编译器中，这可能会导致程序崩溃、数据不变、或其他不可预测的结果

    std::cout << "a = " << a << std::endl;  // 输出 a 的值。由于 a 是 const，编译器可能将它优化为常量值输出，结果仍为 10

    return 0;
}
```

- `const_cast` 只能用来修改那些**原本不是 const，但被“临时”视为 const** 的对象。

- 修改原本就声明为 `const` 的对象（如 `const int a = 10`）的值是**未定义行为**（Undefined Behavior）。

- 这种修改行为可能在某些平台或编译器下看似“成功”，但那是偶然的，不可依赖。

#### 重新解释转换：reinterpret_cast\<T>()

**极端转换**，将数据的二进制表示强制解释为另一种类型。

```cpp
int n = 0x12345678;
char* p = reinterpret_cast<char*>(&n);
cout << hex << (int)(*p & 0xff) << endl;
```

- `n` 的内存表示是 **4 个字节**：

  ```txt
  0x12   0x34   0x56   0x78
  ```

- `reinterpret_cast<char*>(&n)` 把 `int*` 强制解释为 `char*`，于是 `p` 指向 `n` 的第一个字节。

- `*p` 读取的就是内存里 `n` 的第一个字节。

- `& 0xff` 的作用

  - `0xff` 是二进制 `11111111`（8 位全 1）。
  - `*p & 0xff` 就是只保留 `*p` 的低 8 位。
  - 这样可以 **避免符号扩展**，确保结果是 0~255 的正整数。

- 通常用于底层编程，需特别小心，避免未定义行为。

### 总结对比

| 类型转换           | 检查时机 | 适用范围                 | 安全性 | 用法示例                                  |
| ------------------ | -------- | ------------------------ | ------ | ----------------------------------------- |
| 隐式转换           |          | 基本类型、兼容类型       | 高     | `double d = 5;`                           |
| C 风格强制转换     |          | 所有类型                 | 低     | `int i = (int)3.14;`                      |
| `static_cast`      | 编译时   | 编译期可判断的类型转换   | 中高   | `double d = static_cast<double>(i);`      |
| `dynamic_cast`     | 运行时   | 多态类的指针/引用转换    | 高     | `Derived* d = dynamic_cast<Derived*>(b);` |
| `const_cast`       | 编译时   | 修改底层类型的 cv 限定符 | 中     | `int* q = const_cast<int*>(p);`           |
| `reinterpret_cast` | 无检查   | 底层二进制转换           | 低     | `char* c = reinterpret_cast<char*>(p);`   |

最佳实践建议：

1. 优先使用 `static_cast`
2. 多态类型向下转型使用 `dynamic_cast`
3. 除非必要，避免使用 `const_cast` 和 `reinterpret_cast`
4. 完全避免使用 C 风格强制转换 `(type)expr`
5. 对不确定的转换，添加运行时检查

```cpp
// 安全转换示例
if (Derived* d = dynamic_cast<Derived*>(basePtr)) {
    // 转换成功，安全使用d
} else {
    // 处理转换失败
}
```
