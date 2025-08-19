## C++ 函数指针

函数指针是 C++ 中一种**保存函数地址**的指针变量，允许像调用普通函数那样通过指针调用函数。它是理解回调机制、策略模式、以及 C/C++ 中函数灵活性的基础。

```cpp
返回类型 (*函数指针名)(参数类型列表);
```

```cpp
int add(int a, int b) {
    return a + b;
}

// 定义函数指针
int (*funcPtr)(int, int);

// 把函数地址赋给指针
funcPtr = add;

// 通过指针调用函数
int result = funcPtr(3, 4);  // 结果是 7
```

### 回调函数

排序比较器示例：

```cpp
bool cmp(int a, int b) {
    return a > b;
}

void sort(int* arr, int n, bool (*cmpFunc)(int, int)) {
    for (int i = 0; i < n - 1; ++i)
        for (int j = i + 1; j < n; ++j)
            if (!cmpFunc(arr[i], arr[j]))
                std::swap(arr[i], arr[j]);
}
```

调用：

```cpp
int arr[] = {3, 1, 5, 2};
sort(arr, 4, cmp);  // 使用 cmp 作为比较器
```

### 简化语法

#### 使用 typedef

```cpp
typedef int (*CalcFunc)(int, int);
CalcFunc f = add;
```

#### 使用 using

```cpp
using CalcFunc = int(*)(int, int);
CalcFunc f = add;
```

### 函数指针数组（策略表）

```cpp
int add(int a, int b) { return a + b; }
int sub(int a, int b) { return a - b; }

using CalcFunc = int(*)(int, int);
CalcFunc ops[] = {add, sub};

int result = ops[0](10, 5);  // 调用 add，结果是 15
```

### 对比

#### 函数指针

```cpp
int add(int a, int b) { return a + b; }
int (*fptr)(int, int) = add;
fptr(3, 4); // 结果 7
```

- 开销低、语义清晰
- 不能绑定状态、不支持捕获、不支持类成员函数

#### Lambda 表达式

```cpp
auto f = [](int a, int b) { return a + b; };
f(3, 4); // 结果 7

int x = 10;
auto g = [x](int y) { return x + y; }; // 捕获外部变量
```

- 有状态时是类对象（编译器生成），**不能隐式转函数指针**
- **无捕获时可以自动转成函数指针**

#### std::function

```cpp
#include <functional>

std::function<int(int, int)> f = [](int a, int b) {
    return a + b;
};
f(3, 4); // 结果 7
```

- 支持 lambda（有/无捕获）、函数指针、成员函数、仿函数
- 内部封装复杂类型，**易用但可能有堆内存开销**
- 推荐用于高抽象、插件系统、通用回调接口

#### 虚函数指针

```cpp
class Strategy {
public:
    virtual int apply(int a, int b) = 0;
    virtual ~Strategy() = default;
};

class Add : public Strategy {
public:
    int apply(int a, int b) override { return a + b; }
};
```

- 支持接口多态（运行时绑定）
- 类中通过虚函数表调用，支持成员状态
- 有轻微开销（虚表指针跳转），但是**面向对象设计核心**

| 特性/维度          | 函数指针                 | Lambda                     | std::function                | 虚函数指针                 |
| ------------------ | ------------------------ | -------------------------- | ---------------------------- | -------------------------- |
| 类型安全           | 是（依赖函数签名匹配）   | 是（编译器推导类型）       | 是（模板封装类型安全）       | 是（通过类层次保证）       |
| 可捕获变量（闭包） | 否                       | 是                         | 是                           | 否                         |
| 运行时可替换性     | 是（指向不同函数）       | 是（可替换不同闭包）       | 是（可存储不同可调用对象）   | 是（运行时多态，虚表切换） |
| 调用开销（性能）   | 极低（等同普通函数调用） | 极低（无捕获时几乎零开销） | 略高（类型擦除，可能堆分配） | 低（一次虚表指针间接寻址） |
| 存储/语法复杂度    | 中（函数签名书写繁琐）   | 简洁（尤其是内联定义）     | 简洁（统一接口，代价是性能） | 中（需类定义和虚函数声明） |
| 可用于类成员       | 不能直接                 | 可以（成员或自由函数均可） | 可以（存储任意可调用对象）   | 是（虚函数机制专用）       |
| 可用于策略/回调    | 是                       | 是                         | 是                           | 是                         |
| 是否编译期可求值   | 否                       | 无捕获时可（constexpr）    | 否                           | 否                         |

| 场景                          | 推荐方案                 | 理由       |
| ----------------------------- | ------------------------ | ---------- |
| 高性能、无状态策略（如 sort） | 函数指针 / 无捕获 Lambda | 快，简单   |
| 动态策略，有捕获              | `std::function`          | 支持闭包   |
| 面向对象策略，多态结构        | 虚函数                   | 扩展性强   |
| 编译期策略                    | 模板 / `constexpr` 函数  | 编译时计算 |
| 小工具函数 / callback         | Lambda                   | 简洁、现代 |