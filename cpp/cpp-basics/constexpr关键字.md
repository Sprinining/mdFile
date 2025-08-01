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
constexpr int add(int a, int b) {
    return a + b;
}
```

- 如果 `a` 和 `b` 是编译期常量（如字面值），`add(a, b)` 也将在编译期求值；

- 如果 `a` 和 `b` 是运行时值，`add(a, b)` 仍然是普通函数，在运行时执行。
- 特点：
  - **可在编译期执行**（只要实参都是常量表达式）；
  - **也可以在运行时执行**；
  - 被 `constexpr` 修饰的是“函数本身可以在编译期执行”，不是说“调用它的返回值一定是常量”。

函数要求：

- 函数体内只能有 **一条 return 语句（C++11）**

- 传入和返回类型必须是**字面类型**

  - > 字面类型（**Literal Type**）是 C++ 中一个非常基础但很关键的概念，它决定了一个类型的值**能不能在编译期参与计算**，比如作为 `constexpr`、`consteval` 函数的参数或返回值，或者用在 `static_assert`、模板参数等上下文中。
    >
    > - 字面类型就是那些可以在编译期构造并参与常量表达式求值的类型。
    >
    > ### 字面类型的完整分类与标准定义（C++14/17）
    >
    > #### 内建类型（Built-in types）
    >
    > 包括：
    >
    > - 所有算术类型：`int`, `char`, `float`, `double`, `bool`, `long`, `unsigned` 等
    > - 指针类型：`int*`, `void*`，甚至 `nullptr_t`
    > - 枚举类型（包括 `enum class`）
    > - `std::nullptr_t`
    >
    > 这些**天然就是**字面类型。
    >
    > #### 结构体/类类型（Class/struct）
    >
    > 当且仅当它满足以下全部条件：
    >
    > | 条件项                                    | 解释                           |
    > | ----------------------------------------- | ------------------------------ |
    > | 必须有一个 `constexpr` 构造函数           | 用于在编译期构造对象           |
    > | 所有非静态成员必须是字面类型              | 成员类型也必须是可用于编译期的 |
    > | 析构函数是平凡（trivial）并且 `constexpr` | 避免运行时析构逻辑             |
    > | 不能有虚函数或虚基类                      | 这些依赖运行时多态机制         |
    > | 是完整类型（已定义，非前向声明）          | 编译期构造必须是完整类型       |
    >
    > #### 数组类型（Array types）
    >
    > 如果数组的元素类型是字面类型，那么该数组类型也是字面类型。
    >
    > #### 指针和引用类型
    >
    > - 所有指针类型，如 `int*`, `Point*`, `void*`，都是字面类型；
    > - 所有引用类型，如 `int&`, `const Point&`，也是字面类型。
    >
    > 但注意：**引用本身不能作为返回值或成员参与 constexpr 表达式构造**，所以类中包含引用成员，**不是**字面类型。
    >
    > #### 联合体（union）
    >
    > C++14 起，**满足条件的 `union` 也可以是字面类型**，但条件更严格：
    >
    > - 所有成员都必须是字面类型；
    > - 没有虚函数/虚基类；
    > - 拥有 `constexpr` 构造函数；
    > - 析构必须是平凡的。
    >
    > ### 非字面类型的一些常见情况
    >
    > | 类型                    | 原因                          |
    > | ----------------------- | ----------------------------- |
    > | `std::string`           | 非平凡构造/析构，内部有堆内存 |
    > | 包含 `std::vector` 成员 | 成员不是字面类型              |
    > | 包含虚函数的类          | 有虚表指针，不能编译期构造    |
    > | 成员是引用类型          | 引用不能参与 constexpr 构造   |

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