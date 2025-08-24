## C++ Lambda

C++ 的 Lambda 表达式（lambda expression）是一种**轻量级函数对象**，可以在需要函数对象的地方（如算法或回调）快速定义匿名函数。它在 C++11 中引入，后续版本也有增强（如 C++14、C++17、C++20）。

```cpp
[capture](parameters) -> return_type {
    function_body;
};
```

各部分说明：

| 部分             | 说明                   |
| ---------------- | ---------------------- |
| `capture`        | 捕获列表               |
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

如果返回类型可以推导，可省略 `-> int`，甚至连 `auto` 都能省略（如直接用在 `std::sort()` 里）。

### 捕获列表

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
#include <iostream>

int main() {
    int x = 10;
    int y = 20;

    // 按值捕获，lambda 内部修改不会影响外部变量
    auto f1 = [=]() mutable { x += 5; y += 5; return x + y; };

    // 按引用捕获，lambda 内部修改会影响外部变量
    auto f2 = [&]() { x += 5; y += 5; return x + y; };

    std::cout << "f1: " << f1() << "\n"; // 输出 40
    std::cout << "外部 x, y after f1: " << x << ", " << y << "\n"; // 输出 10, 20

    std::cout << "f2: " << f2() << "\n"; // 输出 40
    std::cout << "外部 x, y after f2: " << x << ", " << y << "\n"; // 输出 15, 25
}
```

- `[=]` 按值捕获

  - `x` 和 `y` 在 lambda 内部被拷贝了一份。

  - lambda 修改拷贝不会影响外部变量。

  - 需要 `mutable` 才能修改 lambda 内部的拷贝。

- `[&]` 按引用捕获
  - `x` 和 `y` 被引用捕获，lambda 内部修改会直接作用于外部变量。

### 应用场景

#### 简化函数对象 / 回调

- 替代传统的 `struct` 或函数对象，减少冗长代码。
- 常用于 STL 算法、GUI 回调、事件处理。

```cpp
#include <vector>
#include <algorithm>
#include <iostream>

std::vector<int> v{1, 2, 3, 4, 5};
std::for_each(v.begin(), v.end(), [](int x){ std::cout << x << " "; });
```

#### 按值或按引用捕获变量

- 按值 `[=]`：在 lambda 内部读取外部变量，不修改原变量；适合异步任务。
- 按引用 `[&]`：允许 lambda 修改外部变量；适合累加器或状态更新。

```cpp
int sum = 0;
std::vector<int> nums{1,2,3};
std::for_each(nums.begin(), nums.end(), [&](int x){ sum += x; });
```

#### 延迟执行 / 异步任务

- 将逻辑封装为 lambda，传递给线程、计时器或异步库执行。

```cpp
#include <thread>
int x = 5;
std::thread t([=]{ std::cout << x * 2; });
t.join();
```

#### 临时函数 / 局部封装

- 用于局部逻辑封装，避免全局函数污染。
- 可与模板、泛型算法结合，写出高内聚、简洁代码。

```cpp
auto is_even = [](int n){ return n % 2 == 0; };
std::cout << is_even(4); // 输出 1 (true)
```

#### 组合与高阶函数

- Lambda 可以捕获状态并返回另一个 lambda，实现函数式风格，如柯里化、闭包。

```cpp
auto add = [](int a){ return [a](int b){ return a + b; }; };
std::cout << add(2)(3); // 输出 5
```

### 发展历程

#### C++11：首次引入 Lambda

```cpp
auto f = [](int x, int y) { return x + y; };
std::cout << f(2, 3); // 输出 5
```

- 可以定义匿名函数（无需单独命名）。
- 可以捕获外部变量（按值 `[=]` 或按引用 `[&]`）。
- 可作为函数对象使用，直接传给 STL 算法或回调。

#### C++14：Lambda 改进

- **泛型 lambda（auto 参数）**

```cpp
auto f = [](auto x, auto y) { return x + y; };
```

- **`decltype(auto)` 返回类型推导增强**
- 捕获初始化（capture with initializer）

```cpp
int x = 10;
auto f = [y = x + 5]() { return y * 2; };
```

- 允许在捕获列表中定义新的变量并初始化，解决了 C++11 中捕获复杂表达式的限制。

#### C++17：小幅改进

- 支持 **结构化绑定捕获**（解包绑定变量）

```cpp
auto tup = std::make_tuple(1, 2);
auto f = [a, b = std::get<1>(tup)]() { return a + b; };
```

- 允许 `constexpr` lambda：在编译期求值。

#### C++20：进一步增强

- **模板 lambda**（改进泛型 lambda，使其更像模板函数）

```cpp
auto f = []<typename T>(T x, T y){ return x + y; };
```

- `constexpr` lambda 功能增强，更强大的编译期计算能力。
- 捕获 `this` 时更灵活。

### Lambda 是什么类型

C++ 中的 Lambda 表达式本质上是一个编译器自动生成的“匿名类”的实例，它重载了 `operator()` 运算符，因此可以像函数一样被调用。

一个**匿名类（anonymous class）**就是没有名字的类。没写 `class MyLambda { ... };`，但**编译器自动生成了一个**。例如这段 Lambda 表达式：

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