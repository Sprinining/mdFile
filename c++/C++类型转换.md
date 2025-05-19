## C++类型转换

C++ 中的类型转换（Type Conversion）是指将一种数据类型的值转换为另一种数据类型。C++ 提供了 **隐式类型转换** 和 **显式类型转换** 两种方式，另外引入了更安全和可控的 **C++ 风格的类型转换**。

### 一、隐式类型转换（Implicit Conversion）

编译器自动完成的类型转换，主要发生在以下情况：

1. **算术运算中不同类型的转换**：

   ```cpp
   int a = 10;
   double b = 3.14;
   double c = a + b; // a 被自动转换为 double
   ```

2. **函数参数传递时类型不匹配**：

   ```cpp
   void func(double x);
   func(5); // 5 是 int，会被自动转换为 double
   ```

3. **赋值语句中类型不同**：

   ```cpp
   int i = 3.14; // double -> int，发生截断
   ```

### 二、显式类型转换（Explicit Conversion）

显式转换由程序员主动触发，常见形式：

#### 1. C 风格的强制类型转换（不推荐）

```cpp
double d = 3.14;
int i = (int)d;
```

#### 2. C++ 风格的类型转换（推荐）

更安全、语义更清晰。主要包括以下四种：

### 三、C++ 类型转换运算符

#### 1. `static_cast<T>(expression)`(静态转换)

用于 **基本类型之间的转换**，或类之间 **存在继承关系且已知安全的转换**。

```cpp
int i = 10;
double d = static_cast<double>(i); // int -> double

class Base {};
class Derived : public Base {};
Base* b = new Derived();
Derived* d = static_cast<Derived*>(b); // 已知 b 实际上指向 Derived*
```

#### 2. `dynamic_cast<T>(expression)`(动态转换)

用于 **运行时类型检查的指针或引用转换**，只能用于多态类型（即有虚函数的类）。

```cpp
class Base { virtual void foo() {} };
class Derived : public Base {};

Base* b = new Derived();
Derived* d = dynamic_cast<Derived*>(b); // 安全转换
```

> 如果转换失败，指针返回 `nullptr`，引用会抛出 `std::bad_cast`。

#### 3. `const_cast<T>(expression)`(常量转换)

用于添加或去除 `const`、`volatile` 属性。

```cpp
const int* p = new int(10);
int* q = const_cast<int*>(p); // 去掉 const 限定
```

> 注意：去掉 const 后修改值是未定义行为，除非原本就不是 const。

#### 4. `reinterpret_cast<T>(expression)`(重新解释转换)

**极端转换**，将数据的二进制表示强制解释为另一种类型。

```cpp
int* p = new int(10);
char* c = reinterpret_cast<char*>(p); // 直接 reinterpret 成 char*
```

> 通常用于底层编程，需特别小心，避免未定义行为。

### 四、总结对比

| 类型转换           | 检查时机 | 适用范围                 | 安全性 | 用法示例                                  |
| ------------------ | -------- | ------------------------ | ------ | ----------------------------------------- |
| 隐式转换           |          | 基本类型、兼容类型       | 高     | `double d = 5;`                           |
| C 风格强制转换     |          | 所有类型                 | 低     | `int i = (int)3.14;`                      |
| `static_cast`      | 编译时   | 编译期可判断的类型转换   | 中高   | `double d = static_cast<double>(i);`      |
| `dynamic_cast`     | 运行时   | 多态类的指针/引用转换    | 高     | `Derived* d = dynamic_cast<Derived*>(b);` |
| `const_cast`       | 编译时   | 修改 const/volatile 属性 | 中     | `int* q = const_cast<int*>(p);`           |
| `reinterpret_cast` | 无检查   | 底层二进制转换           | 低     | `char* c = reinterpret_cast<char*>(p);`   |

最佳实践建议：

1. 优先使用 `static_cast`
2. 多态类型向下转型使用 `dynamic_cast`
3. 除非必要，避免使用 `const_cast` 和 `reinterpret_cast`
4. 完全避免使用C风格强制转换 `(type)expr`
5. 对不确定的转换，添加运行时检查

```cpp
// 安全转换示例
if (Derived* d = dynamic_cast<Derived*>(basePtr)) {
    // 转换成功，安全使用d
} else {
    // 处理转换失败
}
```
