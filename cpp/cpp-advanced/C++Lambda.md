## C++Lambda

C++ 的 Lambda 表达式（lambda expression）是一种 **轻量级函数对象**，可以在需要函数对象的地方（如算法或回调）快速定义匿名函数。它在 C++11 中引入，后续版本也有增强（如 C++14、C++17、C++20）。

### Lambda 的基本语法

```cpp
[capture](parameters) -> return_type {
    function_body;
};
```

各部分说明：

| 部分             | 说明                   |
| ---------------- | ---------------------- |
| `capture`        | 捕获外部变量方式       |
| `parameters`     | 参数列表，类似函数参数 |
| `-> return_type` | 返回类型（可省略）     |
| `{}`             | 函数体                 |

示例：

```cpp
auto add = [](int a, int b) -> int {
    return a + b;
};
std::cout << add(3, 4);  // 输出 7
```

> 如果返回类型可以推导，可省略 `-> int`，甚至连 `auto` 都能省略（如直接用在 `std::sort()` 里）。

### 捕获列表 `[capture]`

Lambda 表达式可以捕获周围作用域的变量。主要有以下几种方式：

| 捕获方式    | 含义                                   |
| ----------- | -------------------------------------- |
| `[=]`       | 捕获外部所有变量（按值）               |
| `[&]`       | 捕获外部所有变量（按引用）             |
| `[a]`       | 捕获变量 `a`（按值）                   |
| `[&a]`      | 捕获变量 `a`（按引用）                 |
| `[=, &a]`   | 捕获 `a` 用引用，其余按值              |
| `[this]`    | 捕获当前对象指针（用于类的成员函数中） |
| `[=, this]` | 同时捕获 `this` 和其他值               |

示例：

```cpp
int x = 10;
int y = 20;
auto f1 = [=]() { return x + y; };     // 捕获x和y（按值）
auto f2 = [&]() { x += 1; return x; }; // 捕获x和y（按引用）
```

### Lambda 的应用场景

#### 1. 与标准算法结合

```cpp
std::vector<int> v = {1, 2, 3, 4, 5};
std::for_each(v.begin(), v.end(), [](int x) {
    std::cout << x << " ";
});
```

#### 2. 排序时自定义比较器

```cpp
std::vector<int> v = {5, 1, 4, 2, 3};
std::sort(v.begin(), v.end(), [](int a, int b) {
    return a > b;
});
```

#### 3. 自定义回调函数（如事件处理、信号槽）

### Lambda 的进阶用法（C++14~20）

#### 1. C++14：泛型 Lambda

```cpp
auto add = [](auto a, auto b) {
    return a + b;
};
std::cout << add(1, 2);      // 3
std::cout << add(1.5, 2.5);  // 4.0
```

#### 2. C++17：捕获初始化（结构化绑定）

```cpp
int a = 1, b = 2;
// 不是捕获 a 和 b，而是直接捕获表达式 a + b 的结果
auto f = [x = a + b]() {
    std::cout << x;
};
```

#### 3. C++20：`constexpr` 和 `template` Lambda

```cpp
auto square = [](auto x) constexpr { return x * x; };
```

### Lambda 与函数对象对比

| 特性 | Lambda         | 函数对象（Functor）    |
| ---- | -------------- | ---------------------- |
| 编写 | 简洁           | 需要额外定义类         |
| 性能 | 可内联，效率高 | 有优化空间但略繁琐     |
| 使用 | 常用于临时逻辑 | 适合复杂状态或多次复用 |

### Lambda 是什么类型

C++ 中的 Lambda 表达式本质上是一个编译器自动生成的“匿名类”的实例，它重载了 `operator()` 运算符，因此可以像函数一样被调用。比如：

```cpp
auto f = [](int x) { return x * 2; };
f(5); // 实际是调用了某个类对象的 operator()
```

一个 **匿名类（anonymous class）** 就是没有名字的类。你没写 `class MyLambda { ... };`，但 **编译器自动帮你生成了一个**。

例如这段 Lambda 表达式：

```cpp
auto f = [](int a, int b) { return a + b; };
std::cout << f(2, 3);  // 输出 5
```

它看起来像是一个函数，其实是编译器在背后生成了一个类似这样的类：

```cpp
class __Lambda {
public:
    int operator()(int a, int b) const {
        return a + b;
    }
};
__Lambda f;
```