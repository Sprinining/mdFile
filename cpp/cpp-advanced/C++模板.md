## C++模板

C++ 的模板（Template）是一种 **泛型编程**机制，允许编写与类型无关的代码。模板主要分为两种：

1. **函数模板**（Function Templates）
2. **类模板**（Class Templates）

这让代码在多个类型之间重用，避免了重复实现逻辑。

### 函数模板

交换两个变量：

```cpp
template <typename T>
void swapValues(T &a, T &b) {
    T temp = a;
    a = b;
    b = temp;
}
```

- `template <typename T>`：声明一个类型参数 `T`
- `T` 会在函数调用时根据实际参数类型自动推导

使用方式：

```cpp
int main() {
    int a = 1, b = 2;
    swapValues(a, b); // 自动推导 T 为 int

    double x = 1.1, y = 2.2;
    swapValues(x, y); // 自动推导 T 为 double
}
```

手动指定类型（可选）：

```cpp
swapValues<int>(a, b);
```

#### 类型模板参数

**类型模板参数**表示模板接受一个“类型”作为参数，用于在模板中生成针对该类型的代码。

```cpp
template <typename T>
void func(T val) {
    // 使用 T 类型的参数
}
```

或者用 `class`（功能等价）：

```cpp
template <class T>
void func(T val) { ... }
```

- `typename` 和 `class` 在声明类型参数时是一样的（历史原因允许两种写法）。

- `T` 就是一个类型占位符（type placeholder），在使用模板时由编译器替换为实际类型。

#### 非类型模板参数

非类型模板参数（**Non-Type Template Parameters, NTP**）是 C++ 模板的一种形式，它允许将**值**而不是**类型**作为模板参数传递。

合法的非类型模板参数必须是**编译期常量**，类型受限。

##### 常见支持的类型（C++20 之前）

| 支持的类型                 | 示例                                              |
| -------------------------- | ------------------------------------------------- |
| 整数类型                   | `int`, `char`, `bool`, `enum`                     |
| 指针或引用常量             | `const char*`, `int*`, `void(*)()`                |
| 指向成员的指针             | `int Class::*`                                    |
| `std::nullptr_t`           | 用于特化 nullptr 情况                             |
| `auto`（C++17 起）         | 自动推导                                          |
| 任意字面值类型（C++20 起） | `std::string_view`, 用户自定义的 constexpr 类型等 |

##### 示例

###### 模板中的数组长度

```cpp
template<int N>
struct Buffer {
    char data[N];
};

Buffer<64> buf;  // 生成一个拥有 64 字节缓冲区的类型
```

###### 使用布尔值分支行为

```cpp
template<bool Debug>
void log(const std::string& msg) {
    if constexpr (Debug) {
        std::cout << "[DEBUG] " << msg << std::endl;
    }
}
```

###### 函数模板中的非类型参数

```cpp
template<int N>
void printNTimes(const std::string& s) {
    for (int i = 0; i < N; ++i)
        std::cout << s << "\n";
}
```

##### 非类型模板参数 vs 宏/函数

| 特性         | 宏   | 普通函数 | 非类型模板参数      |
| ------------ | ---- | -------- | ------------------- |
| 类型安全     | ❌    | ✅        | ✅                   |
| 编译期可优化 | 部分 | ❌        | ✅                   |
| 支持泛型     | ❌    | ✅        | ✅（+ 值泛化）       |
| 条件编译     | ✅    | ❌        | ✅（`if constexpr`） |

##### C++17/20 的增强能力

###### C++17：`auto` 非类型参数

```cpp
template<auto N>
void show() {
    std::cout << N << "\n";
}

show<42>();     // int
show<'A'>();    // char
```

###### C++20：**结构体也能作为参数！**

```cpp
struct ConstStr {
    constexpr ConstStr(const char* s) : str(s) {}
    const char* str;
};

template<ConstStr s>
void greet() {
    std::cout << "Hello, " << s.str << "\n";
}
```

##### 常见错误点

| 错误                                          | 原因                   |
| --------------------------------------------- | ---------------------- |
| `template<std::string s>` ❌                   | 非 `constexpr` 类型    |
| `template<int* p>` ❌                          | 指针值必须是常量表达式 |
| 类型写错如 `template<int N>` 用 `Buffer<'a'>` | `'a'` 是 `char` 类型   |

###### 为什么必须是编译期常量表达式

模板实例化是在编译期进行的：

```cpp
template<int N>
struct Array {
    int data[N];
};
```

当你写：

```cpp
Array<10> a;
```

编译器 **立刻**要知道 `Array<10>` 是什么结构，具体到 `int data[10];`。它必须在模板实例化阶段**完全展开并生成代码**。

如果传的是运行时变量，比如：

```cpp
int n = 10;
Array<n> a;  // ❌ 不行！
```

这会报错：因为 `n` 是运行时变量，编译器**不知道** `n` 的值，就无法生成 `data[n]` 这种固定大小的数组。所以要求：传给非类型模板的值必须是常量表达式（compile-time constant expression）。

###### 为什么类型必须是 `constexpr` 支持的类型

C++ 的非类型模板参数之所以一开始限制只能是 `int` / `char` 等“字面值类型”，是因为：

模板参数是要用来参与编译期比较、符号查找、类型匹配的。

```cpp
template<SomeType X>
void f();
```

调用：

```cpp
f<some_value>();
```

编译器会问自己：“这个 `some_value` 跟之前见过的参数一样吗？我是不是要重新实例化一份？”

这就要求 `X` 必须是 **可以比较、可以唯一确定、可以用于编译期推导** 的东西。

举个不能用的例子：

```cpp
template<std::string s>
void print();  // ❌ 不合法：std::string 不是字面值类型
```

原因：

- `std::string` 不是编译期常量（它可能动态分配内存）
- 编译器无法比较两个 `std::string` 值是否“相同”，也不能用于模板查找
- 所以不能做模板参数

> `std::string_view` + `constexpr` 字面值对象可以（C++20），但 `std::string` 不行。

###### 所以 C++ 标准设定了这些规则

| 要求                                | 原因                             |
| ----------------------------------- | -------------------------------- |
| 值是常量表达式                      | 为了在 **编译期** 完全展开模板   |
| 类型是 `constexpr` 支持的字面值类型 | 为了能进行编译期的比较和模板匹配 |
| 指针参数必须指向常量对象或函数      | 否则编译器无法判断模板是否相同   |

#### 模板编译

##### 模板是代码生成的蓝图

- 模板定义时并不会生成可执行代码，而是为编译器提供一种“代码模板”或“生成规则”。
- 编译器仅对模板定义做语法和基本语义检查，但不生成具体函数或类代码。

##### 模板实例化发生在编译期

- 当程序中使用模板时（例如调用模板函数或实例化模板类），编译器根据具体模板参数**在编译阶段**生成对应的代码。
- 这个过程称为**模板实例化（Template Instantiation）**。
- 实例化会把模板参数替换到模板代码中，生成具体的函数或类定义，随后编译成机器码。

##### 模板实例化方式

- **隐式实例化**
  编译器自动根据代码中出现的模板参数生成实例。比如调用 `func<int>(10)`，编译器会自动生成 `func<int>` 的代码。
- **显式实例化**
  程序员通过 `template class Foo<int>;` 或 `template void func<int>(int);` 等语句告诉编译器必须实例化某个模板。

```cpp
#include <iostream>

template<typename T>
void print(T val) {
    std::cout << val << std::endl;
}

// 显式实例化，告诉编译器：必须生成 print<int> 版本
template void print<int>(int);

int main() {
    print(123);    // 使用的是显式实例化生成的 print<int>
    print(3.14);   // 隐式实例化，编译器自动生成 print<double>
    return 0;
}
```

- `template void print<int>(int);` 这一行是显式实例化声明，编译器会立即生成 `print<int>` 这个版本的代码。
- 显式实例化一般写在 `.cpp` 文件中，防止模板定义写在头文件导致每个翻译单元都生成重复代码。
- 其他模板参数（比如 `double`）仍然可以隐式实例化。

###### 何时用显式实例化

- 当你想控制模板实例化的位置，减少代码重复和编译时间时。
- 当模板定义在 `.cpp` 文件里，需要强制生成某些实例代码。

##### 模板定义与实例化的代码位置

- 模板通常写在头文件中，因为模板实例化发生在使用模板的翻译单元（编译单元）中，需要看到完整模板定义才能实例化。
- 如果模板定义和实例化分开放，必须显式实例化，避免链接错误。

##### 模板编译的优缺点

- 优点：通过模板实现代码复用，避免手写重复代码；生成高效的特化代码。
- 缺点：可能导致代码膨胀，编译时间变长，错误提示晚（实例化时才报错）。

##### 小结

| 编译阶段       | 发生内容                             | 是否生成代码       |
| -------------- | ------------------------------------ | ------------------ |
| 模板定义阶段   | 语法和语义检查，生成模板信息         | 否                 |
| 模板实例化阶段 | 根据具体模板参数生成对应函数或类代码 | 是，编译期生成代码 |
| 编译代码阶段   | 将实例化的代码编译成机器码           | 是                 |

### 类模板

类模板允许创建通用类，比如容器类 `vector`, `stack` 就是使用模板实现的。

简单的栈：

```cpp
template <typename T>
class MyStack {
private:
    vector<T> data;
public:
    void push(const T& val) { data.push_back(val); }
    void pop() { data.pop_back(); }
    T top() const { return data.back(); }
    bool empty() const { return data.empty(); }
};

```

使用方式：

```cpp
MyStack<int> s1;
s1.push(10);
s1.push(20);
cout << s1.top(); // 输出 20

MyStack<string> s2;
s2.push("hello");
cout << s2.top(); // 输出 hello
```

### 模板的高级特性

#### 一、模板特化（Template Specialization）

##### 1.1 全特化（Full Specialization）

对某个特定类型的模板进行完全定义。

```cpp
template<typename T>
struct TypePrinter {
    void print() { std::cout << "Generic type\n"; }
};

template<>
struct TypePrinter<int> {
    void print() { std::cout << "int type\n"; }
};
```

调用：

```cpp
TypePrinter<double>().print();  // Generic type
TypePrinter<int>().print();     // int type
```

##### 1.2 偏特化（Partial Specialization）

部分参数被特化，仍保留部分模板泛型。

```cpp
template<typename T1, typename T2>
struct Pair {};

template<typename T>
struct Pair<T, int> {
    void print() { std::cout << "Second is int\n"; }
};
```

#### 二、模板元编程（Template Metaprogramming）

利用模板在编译期进行计算。

##### 2.1 编译期阶乘计算

```cpp
template<int N>
struct Factorial {
    static const int value = N * Factorial<N - 1>::value;
};

template<>
struct Factorial<0> {
    static const int value = 1;
};
```

调用：`Factorial<5>::value // 120`

#### 三、SFINAE（Substitution Failure Is Not An Error）

用于**条件编译**，决定某个模板是否可用。

##### 3.1 利用 `std::enable_if`

```cpp
#include <type_traits>

template<typename T>
typename std::enable_if<std::is_integral<T>::value, void>::type
process(T t) {
    std::cout << "Integral\n";
}

template<typename T>
typename std::enable_if<std::is_floating_point<T>::value, void>::type
process(T t) {
    std::cout << "Floating point\n";
}
```

#### 四、变参模板（Variadic Templates）

支持任意数量的模板参数（C++11 引入）。

##### 4.1 展开参数包

```cpp
template<typename T>
void print(T t) {
    std::cout << t << "\n";
}

template<typename T, typename... Args>
void print(T t, Args... args) {
    std::cout << t << ", ";
    print(args...);
}
```

调用：`print(1, 2.0, "hello");`

#### 五、模板别名（Template Alias）

简化冗长类型的书写（C++11 引入）。

```cpp
template<typename T>
using Vec = std::vector<T>;

Vec<int> v; // 等价于 std::vector<int>
```

#### 六、Concepts（C++20）

用于约束模板参数类型，是现代模板机制的重要升级。

```cpp
#include <concepts>

template<typename T>
concept Integral = std::is_integral<T>::value;

template<Integral T>
T add(T a, T b) {
    return a + b;
}
```

相比于传统的 SFINAE 更清晰、可读性更强。

#### 七、模板默认参数

模板也可以定义默认参数：

```cpp
template<typename T = int, int N = 10>
struct Array {
    T data[N];
};
```

#### 八、模板的递归继承（Curiously Recurring Template Pattern, CRTP）

一种利用模板实现静态多态的技巧。

```cpp
template<typename Derived>
class Base {
public:
    void interface() {
        static_cast<Derived*>(this)->implementation();
    }
};

class Derived : public Base<Derived> {
public:
    void implementation() {
        std::cout << "Derived implementation\n";
    }
};
```

#### 九、类型萃取（Type Traits）

用于类型推断和变换（主要由 `<type_traits>` 提供）：

##### 示例：

```cpp
std::is_pointer<T>::value
std::remove_reference<T>::type
std::add_const<T>::type
```

#### 十、模板实例化控制

C++支持显式实例化和显式特化，可以控制编译单位实例化模板的位置。

```cpp
// 显式实例化声明（只声明，不定义）
extern template class MyClass<int>;

// 显式实例化定义
template class MyClass<int>;
```

### 模板和编译器

- 模板是**在编译时实例化的**

- 每种类型生成一份对应代码（会增加编译体积，这叫**代码膨胀**）

- 模板函数必须放在**头文件**或定义处可见（编译器需要看到模板的定义才能实例化）

### STL中的模板

#### 一、`std::vector` 与模板默认参数 + 分配器参数

```cpp
template<
    class T,
    class Allocator = std::allocator<T>
> class vector;
```

##### 特性：

- 使用了**模板默认参数**：`Allocator = std::allocator<T>`
- 分离了数据类型与内存分配策略，是经典的**策略模式**应用。
- `std::allocator<T>` 本身也是一个模板类。

------

#### 二、`std::enable_if` + `std::is_integral`：如 `std::is_sorted`

```cpp
template<class ForwardIt>
bool is_sorted(ForwardIt first, ForwardIt last) {
    if (first == last) return true;
    ForwardIt next = first;
    while (++next != last) {
        if (*next < *first) return false;
        ++first;
    }
    return true;
}
```

在 STL 中，一些函数如 `std::bitset`, `std::advance`, `std::copy`, `std::fill_n` 等有多个重载版本，有些会使用 `std::enable_if` 来判断是否可以对特定类型使用操作。

##### 内部类似这样处理：

```cpp
template <typename T>
typename std::enable_if<std::is_integral<T>::value, bool>::type
is_even(T n) {
    return n % 2 == 0;
}
```

------

#### 三、`std::iterator_traits`：**偏特化** + **SFINAE**

```cpp
template<class Iterator>
struct iterator_traits {
    using difference_type   = typename Iterator::difference_type;
    using value_type        = typename Iterator::value_type;
    using pointer           = typename Iterator::pointer;
    using reference         = typename Iterator::reference;
    using iterator_category = typename Iterator::iterator_category;
};

// 原生指针特化
template<class T>
struct iterator_traits<T*> {
    using difference_type   = std::ptrdiff_t;
    using value_type        = T;
    using pointer           = T*;
    using reference         = T&;
    using iterator_category = std::random_access_iterator_tag;
};
```

##### 特性：

- `iterator_traits<T*>` 是 `iterator_traits` 的**偏特化**版本
- 自动支持原生数组指针当做迭代器使用。

------

#### 四、`std::function` 与 **类型擦除 + 可变参数模板**

```cpp
template<typename>
class function;  // 主模板声明

template<typename R, typename... Args>
class function<R(Args...)> {
    // 存储、调用、类型擦除等实现
};
```

##### 特性：

- 使用 **变参模板（variadic templates）** 实现支持任意函数签名的通用包装器。
- `function<int(int, double)>` 等价于 `R = int`, `Args... = int, double`

------

#### 五、`std::tuple`：**递归继承 + 变参模板**

```cpp
template<typename... Types>
class tuple;
```

STL 实现中，`std::tuple` 可能使用**递归继承**和**类型列表拆解**方式实现：

```cpp
template<std::size_t I, typename T>
struct tuple_leaf {
    T value;
};

template<typename Indices, typename... Types>
class tuple_impl;

template<std::size_t... I, typename... Types>
class tuple_impl<std::index_sequence<I...>, Types...>
    : tuple_leaf<I, Types>... {
    // 继承所有叶子节点
};

template<typename... Types>
class tuple : public tuple_impl<std::index_sequence_for<Types...>, Types...> {
};
```

##### 特性：

- **变参模板**：支持任意数量的参数
- **递归继承 + index_sequence**：静态索引访问元素
- **SFINAE** 用于区分默认构造、拷贝构造、移动构造等

####  六、`std::is_same` / `std::remove_reference` 等 Type Traits：**偏特化**

```cpp
template<class T, class U>
struct is_same {
    static constexpr bool value = false;
};

template<class T>
struct is_same<T, T> {
    static constexpr bool value = true;
};
```

这类类型工具在 STL 中广泛用于实现**类型推导和限制**，如：

- `std::is_const<T>` 判断是否为 const
- `std::remove_reference<T>` 移除引用
- `std::decay<T>` 模拟函数传参过程中的类型转换

------

#### 七、`std::less<void>`（C++14）：模板偏特化 + 类型推导

```cpp
template<>
struct less<void> {
    template<typename T, typename U>
    constexpr auto operator()(T&& t, U&& u) const
        -> decltype(std::forward<T>(t) < std::forward<U>(u)) {
        return std::forward<T>(t) < std::forward<U>(u);
    }
};
```

##### 特性：

- 允许 `std::less<void>` 可以比较任何可比较的类型。
- 利用了 **泛型 lambda 风格的 SFINAE 自动推导返回值类型**。
