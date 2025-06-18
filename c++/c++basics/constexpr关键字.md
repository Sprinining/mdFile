## constexpr 关键字

`constexpr` 表示“**编译期常量**”，即表达式、变量或函数的值**必须**能在**编译期**被求出来。

### 用途总览

| 场景         | 示例                              | 意义                         |
| ------------ | --------------------------------- | ---------------------------- |
| 修饰变量     | `constexpr int a = 5;`            | `a` 是编译期常量             |
| 修饰函数     | `constexpr int add(int a, int b)` | 函数在编译期就可以被求值     |
| 修饰构造函数 | `constexpr MyClass(int)`          | 可用于生成编译期常量对象     |
| 修饰类       | 类内所有成员/函数均是 `constexpr` | 表示可在编译期完全构造和使用 |

### 与 `const` 的区别

| `const`                      | `constexpr`                          |
| ---------------------------- | ------------------------------------ |
| 表示“只读”（不可修改）       | 表示“编译期常量表达式”               |
| 值可能是运行期确定           | 值**必须是编译期可确定**             |
| 可用于任何类型               | 要求类型支持编译期使用（字面值类型） |
| 可修饰对象、成员函数、指针等 | 可修饰变量、函数、构造函数、对象等   |
| 不等价于常量表达式           | 一定是常量表达式                     |

```cpp
const int x = rand();     // ✅ 运行时常量
constexpr int y = rand(); // ❌ 错误：不是编译期常量
```

### 常见用法

#### `constexpr` 变量

```cpp
constexpr int size = 10;
int arr[size];  // ✅ OK：size 是常量表达式
```

不能这么写：

```cpp
int n = 10;             // ✅ n 是运行期变量（尽管值为 10）
constexpr int x = n;    // ❌ 错误：n 不是编译期常量表达式
```

`int n = 10;` 是普通变量初始化，不是常量表达式！

这句是 **运行期变量初始化**，也就是说：

- 编译器允许你把 `n` 的值改掉（即使你没有改）
- 它不会对 `n` 做任何“常量表达式”验证

编译器只允许下面这种形式：

```cpp
constexpr int n = 10;   // ✅ n 是编译期常量表达式
constexpr int x = n;    // ✅ OK，n 是 constexpr
```

或者

```cpp
const int n = 10;       // ✅ 有条件接受（见下）
constexpr int x = n;    // ✅ 这在很多实现中也允许（因为常量初始化是常量表达式）
```

`int n = 10;` 虽然值是常数，但它没有“常量表达式”的语义标记。

编译器不会去猜测你的意图，它只信你用没用 `constexpr` 或 `const`。

C++ 的 `constexpr` 是一种 **语义承诺机制**，它告诉编译器：

> “我承诺这个值一定能在编译期被确定，绝不会依赖运行期的行为。”

而写 `int n = 10;`，没有这种承诺，编译器就不会把它当成编译期常量，即使写的是 10、20、30。

实际执行时**可能在编译期就被优化常量赋值**，但语义上仍然是运行期求值。

#### `constexpr` 函数（C++11 起）

```cpp
constexpr int square(int x) {
    return x * x;
}

int arr[square(5)];   // ✅ OK
```

函数要求：

- 函数体内只能有 **一条 return 语句（C++11）**
- 参数和返回值类型都必须是 `constexpr` 支持的类型
- **C++14+** 起支持复杂函数体，允许 `if`、循环等语法

#### `constexpr` 构造函数 & 对象

```cpp
struct Point {
    int x, y;
    constexpr Point(int a, int b) : x(a), y(b) {}
};

constexpr Point p(1, 2);  // ✅ 编译期创建 Point 对象
```

#### `constexpr` 类

C++20 起可以声明类为 `constexpr`：

```cpp
struct constexpr_string {
    char data[100];
    constexpr constexpr_string(const char* s) {
        // 编译期拷贝字符串
    }
};
```

#### 用于模板参数

```cpp
template<int N>
struct Array {
    int data[N];
};

constexpr int n = 8;
Array<n> arr;  // ✅ OK：n 是常量表达式
```

#### 与 `if constexpr` 搭配（C++17）

```cpp
template<typename T>
void print_type_info() {
    if constexpr (std::is_integral_v<T>) {
        std::cout << "int type\n";
    } else {
        std::cout << "non-int type\n";
    }
}
```

- 这段代码**在编译期根据类型 `T` 判断，选择打印整型类型信息还是非整型类型信息**。

- 使用 `if constexpr` 让代码更加灵活和高效，避免无用代码编译。

- 只编译满足条件的分支，**不会导致模板实例化错误**。

### 编译器怎么判断是不是 `constexpr`？

判断标准：

1. 语义上必须明确可在编译期求值（如无 `throw`、无 I/O、无运行时分支）
2. 所有使用到的值、调用的函数也都必须是 `constexpr`
3. 对象在 `constexpr` 上下文中被使用时，必须能推导出唯一值

### C++ 标准对 `constexpr` 的演进

| C++版本 | 特性进化                                              |
| ------- | ----------------------------------------------------- |
| C++11   | 支持 `constexpr` 变量和函数（必须是单 return 表达式） |
| C++14   | 放宽限制：允许 if、for、局部变量等                    |
| C++17   | 支持 `if constexpr`                                   |
| C++20   | 支持 `constexpr` 动态分配、虚函数等更多能力           |
| C++23   | `constexpr` lambda 支持更强的泛化与捕获               |

### “常量表达式” vs “`constexpr` 类型” vs “常量对象”

#### 常量表达式（**constant expression**）—— **值层面**

一个能在编译期**求出结果**的表达式。

```cpp
constexpr int a = 10;      // ✅ 常量表达式
const int b = 20;          // ✅ 可能是常量表达式（看初始化表达式）
int c = 30;                // ❌ 不是常量表达式
```

判断标准：**这个表达式的结果能在编译期算出来吗？**

#### `constexpr` 类型（**Literal Type**）—— **类型层面**

能被用作 `constexpr` 的类型。必须满足一定条件，使得编译器可以在**编译期完整构造并操作它的对象**。

| ✅ 是 `constexpr` 类型         | ❌ 不是                       |
| ----------------------------- | ---------------------------- |
| `int`, `char`, `bool`, 指针   | `std::string`, `std::vector` |
| `std::array<T, N>`            | 拥有虚函数的类               |
| 用户自定义 struct（满足要求） | 非字面值类                   |

一个类型要成为 `constexpr` 类型，通常要：

- 拥有 `constexpr` 构造函数
- 所有成员也必须是 `constexpr` 类型
- 没有虚函数（除非 C++20 起允许）
- 满足编译期构造的要求

用于非类型模板参数的对象类型，**必须是 `constexpr` 类型（字面值类型）**！

#### 常量对象（**const object**）—— **对象层面**

**常量对象**通常就是指被 `const` 修饰的对象，意思是这个对象的值在其生命周期内不能被修改。

使用 `const` 或 `constexpr` 关键字声明的对象。

```cpp
const int a = 10;       // 常量对象（可能在编译期，也可能在运行期）
constexpr int b = 20;   // 编译期常量对象，一定是常量表达式
```

`const` 只是 **不可修改**，但不保证是常量表达式：

```cpp
int x = rand();
const int y = x;     // y 是常量对象，但不是常量表达式！
```

#### 示例

```cpp
constexpr int x = 42;               // ✅ 常量表达式 + 常量对象
const int y = time(0);              // ❌ 不是常量表达式，但 y 是常量对象
template<int N> struct A {};        
A<x> a1;                            // ✅ 合法，x 是常量表达式
A<y> a2;                            // ❌ 不合法，y 不是常量表达式
```

##### 第 1 行

```cpp
constexpr int x = 42;
```

- `constexpr` 意味着：**编译期就必须能求出它的值**

- `42` 是一个**编译期字面值**

- 所以 `x` 的值 = 42，**在编译阶段已知**

- 因此 `x` 是：

  - **常量表达式（可以出现在模板参数、数组长度、`if constexpr` 中）**

  - **常量对象（不能修改）**

##### 第 2 行

```cpp
const int y = time(0);
```

这个是**重点解释的部分**：

- `y` 是用 `const` 修饰的变量，所以它是一个**常量对象**（值不能改）
- 但是 `time(0)` 是一个**运行时函数调用**，**不能在编译期确定其值**
- 所以它是一个**运行时常量对象**，**不是常量表达式**

**关键区别**在于：

```cpp
const int a = 10;          // ✅ 是常量表达式（值是编译期字面值）
const int b = time(0);     // ❌ 不是常量表达式（值只有运行时才知道）
```

所以 `y` 虽然是常量对象，但不是常量表达式，**不能用于模板参数**

##### 第 3 行 & 第 4 行

```cpp
template<int N> struct A {};
A<x> a1;
```

解释：

- 模板参数 `int N` 要求是一个**编译期常量表达式**
- `x` 是 `constexpr int`，且是 42，**值是已知的编译期常量**
- 所以 `A<x>` 编译器是能接受的，会生成 `A<42>` 这个类模板的实例

##### 第 5 行

```cpp
A<y> a2;
```

问题来了：

- `y` 是 `const int`，但初始化用了 `time(0)` —— **不是常量表达式**
- 编译器无法在编译期确定 `y` 的值是多少
- 而模板参数 `N` 要求是常量表达式
- 所以这里 **报错**：不能用 `y` 作为模板参数！