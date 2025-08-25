## C++ 类型萃取

C++ 类型萃取（Type Traits）是**模板元编程**的核心工具之一，用于在**编译期分析和操纵类型信息**。它们常用于**泛型编程**中，帮助我们写出更通用、类型安全的代码，特别是在 **STL、标准库实现、SFINAE、concepts** 等地方广泛使用。

### 核心思想

通过模板结构体和偏特化机制，在编译期对类型进行**判断、提取、转换**，比如：

- 判断一个类型是不是指针？
- 判断两个类型是否相同？
- 从 `const int*` 中去除 `const` 或指针修饰？
- 把某类型转换成引用？

### 常见标准类型萃取

#### 类型判断类模板

判断一个类型是否满足某种特性，结果都提供一个静态成员变量 `::value`。

| Trait                       | 说明           | 示例                                   |
| --------------------------- | -------------- | -------------------------------------- |
| `std::is_integral<T>`       | 是否为整型     | `std::is_integral<int>::value == true` |
| `std::is_floating_point<T>` | 是否为浮点类型 | `float, double`                        |
| `std::is_pointer<T>`        | 是否为指针     | `int*` 是                              |
| `std::is_const<T>`          | 是否为 const   | `const int` 是                         |
| `std::is_reference<T>`      | 是否为引用     | `int&`, `int&&` 是                     |
| `std::is_array<T>`          | 是否是数组     | `int[3]` 是                            |

C++17 起也可以用 `std::is_pointer_v<T>` 简化书写。

```cpp
static_assert(std::is_pointer<int*>::value, "yes");   // C++11/14 写法
static_assert(std::is_pointer_v<int*>, "yes");        // C++17 起简写
```

#### 类型修改类模板

这些萃取模板用于“去掉”或“添加”某些类型修饰。

| Trait                    | 功能                                       | 示例                                    |
| ------------------------ | ------------------------------------------ | --------------------------------------- |
| `std::remove_const<T>`   | 移除 const 修饰                            | `remove_const<const int>::type` → `int` |
| `std::remove_pointer<T>` | 移除指针                                   | `remove_pointer<int*>::type` → `int`    |
| `std::add_const<T>`      | 添加 const 修饰                            | `add_const<int>::type` → `const int`    |
| `std::decay<T>`          | 衰变类型（去引用、去 const、数组转指针等） | `int[3]` → `int*`                       |

#### 类型比较类模板

| Trait                            | 功能             | 示例                               |
| -------------------------------- | ---------------- | ---------------------------------- |
| `std::is_same<T, U>`             | 判断类型是否相同 | `is_same<int, int>::value == true` |
| `std::is_base_of<Base, Derived>` | 判断是否为基类   | `is_base_of<A, B>`                 |
| `std::is_convertible<T, U>`      | 判断能否隐式转换 | `is_convertible<int, double>`      |

### 自定义类型萃取

判断是否为指针类型的简化实现：

```cpp
// 通用模板，默认情况下假设 T 不是指针类型
template<typename T>
struct is_pointer {
    static constexpr bool value = false;
};

// 偏特化版本：当 T 是指针类型（T*）时，特化这个模板
template<typename T>
struct is_pointer<T*> {
    static constexpr bool value = true;
};
```

使用：

```cpp
std::cout << is_pointer<int>::value << std::endl;   // false
std::cout << is_pointer<int*>::value << std::endl;  // true
```

### std::enable_if

类型萃取 + `std::enable_if` 可用于 SFINAE 机制控制函数模板是否可用。

```cpp
template<typename T>
typename std::enable_if<std::is_integral<T>::value, T>::type
add_one(T val) {
    return val + 1;
}
```

- `template<typename T>`
  定义了一个函数模板 `add_one`，它的参数和返回类型依赖于模板参数 `T`。

- `std::is_integral<T>::value`

  - 这是一个 type trait，用来检测 `T` 是否是整型（integral type），比如 `int`, `char`, `long` 等。

  - 如果 `T` 是整型 → 返回 `true`（即 `1`）。

  - 否则返回 `false`（即 `0`）。

- `std::enable_if<condition, Type>::type`
  
  - `enable_if` 的作用是：
    - 如果 `condition == true` → 定义一个别名 `type = Type`。
    - 如果 `condition == false` → 根本没有 `type` 这个成员，替换失败（SFINAE），该模板版本就被丢弃。
  - 在这里：
  
    ```cpp
    typename std::enable_if<std::is_integral<T>::value, T>::type
    ```
  
    意味着：
  
    - 如果 `T` 是整型 → `返回类型` 就是 `T`。
  
    - 如果 `T` 不是整型 → 替换失败，该函数模板不可用。
  

这个函数只有在 `T` 是整型时才会参与编译。

#### typename

##### 常见的 typename A B 形式

```cpp
typename Foo<T>::bar x;
```

- `Foo<T>::bar` 是一个**依赖于模板参数 T 的类型名**（dependent name）。
- 编译器光看语法时分不清 `bar` 是成员类型还是成员变量，所以需要用 `typename` 显式告诉编译器：**这是一个类型**。
- 然后 `x` 就是这个类型的变量。

##### typename std::enable_if<...>::type

```cpp
typename std::enable_if<std::is_integral<T>::value, T>::type
```

这里是另一种用法：

- `std::enable_if<cond, Type>` 是个模板结构体，里面可能定义一个成员 `using type = Type;`。
- 所以 `std::enable_if<cond, T>::type` 就是取这个成员 `type`。

但有个问题：

- 如果 `cond == false`，那 `enable_if` 根本没有 `type` 这个成员。
- 这时 `typename std::enable_if<...>::type` 在替换时失败（SFINAE 生效）。

所以这里的 `typename` 其实是告诉编译器：“`std::enable_if<...>::type` 这是一个**类型**，不是别的东西。”

##### 举个完整例子

```cpp
template<typename T>
struct Foo {
    using bar = int;
};

template<typename T>
typename Foo<T>::bar func() {   // bar 依赖于 T，所以要写 typename
    return 42;
}
```

对应 `enable_if` 的情况就是：

```cpp
template<typename T>
typename std::enable_if<std::is_integral<T>::value, T>::type
add_one(T val) {
    return val + 1;
}
```

这里 `typename std::enable_if<...>::type` 就是一个**返回类型**。

#### SFINAE

SFINAE 是 C++ 模板元编程里一个非常核心的概念，全称是：**S**ubstitution **F**ailure **I**s **N**ot **A**n **E**rror（替换失败不是错误）

当编译器在对模板参数进行**实参替换**时，如果某个模板在替换过程中出现了语义错误（比如某个类型不满足要求），这**不会导致编译错误**，而是让这个模板候选被丢弃。编译器会继续尝试其他候选函数或模板。

如果最后没有任何候选能匹配，才会报错。

```cpp
#include <type_traits>
#include <iostream>

// 只有当 T 是指针类型时，这个重载才有效
template <typename T>
typename std::enable_if<std::is_pointer<T>::value, void>::type
func(T t) {
    std::cout << "Pointer overload\n";
}

// 只有当 T 不是指针类型时，这个重载才有效
template <typename T>
typename std::enable_if<!std::is_pointer<T>::value, void>::type
func(T t) {
    std::cout << "Non-pointer overload\n";
}

int main() {
    int x = 42;
    int* p = &x;

    func(x);  // Non-pointer overload
    func(p);  // Pointer overload
}
```

- `func(x)` 替换 `T = int`，第一个模板里 `std::is_pointer<int>::value == false`，所以 `enable_if<false, void>::type` 替换失败 → 这个版本被丢弃。
- `func(p)` 替换 `T = int*`，第一个模板里 `std::is_pointer<int*>::value == true`，替换成功 → 匹配第一个重载。

这就是 **SFINAE** 在起作用。

##### 常见用途

1. **约束模板**：限制模板参数类型，避免误用。
2. **重载选择**：根据参数类型或属性选择不同实现。
3. **检测能力（trait 技巧）**：比如“某类型是否有某个成员函数”。

##### C++20 的改进

到了 **C++20**，SFINAE 很多场景被 **concepts** 和 `requires` 语法替代，写法更直观：

```cpp
template <typename T>
requires std::is_pointer_v<T>
void func(T t) { std::cout << "Pointer overload\n"; }

template <typename T>
requires (!std::is_pointer_v<T>)
void func(T t) { std::cout << "Non-pointer overload\n"; }
```

### 应用场景

- STL 容器如 `std::vector` 优化不同类型的构造方式
- `std::move_if_noexcept` 等函数中用来判断是否应该移动或拷贝
- 自定义容器或算法模板时做类型检查

### 使用类型萃取来选择不同的函数实现

#### 方案一：使用 std::enable_if + 类型萃取

```cpp
#include <iostream>
#include <type_traits>  // 包含标准类型萃取和 enable_if

// 整型版本：当 T 是整型时启用该函数模板
template <typename T>
typename std::enable_if<std::is_integral<T>::value>::type
print_type_info(T val) {
    std::cout << val << " 是整数类型" << std::endl;
}
// 说明：
// std::enable_if<条件>::type 如果条件为 true，则有一个 typedef type = void，函数有效。
// 如果条件为 false，则该模板无 type 成员，编译失败，编译器忽略此重载。

// 浮点型版本：当 T 是浮点类型时启用该函数模板
template <typename T>
typename std::enable_if<std::is_floating_point<T>::value>::type
print_type_info(T val) {
    std::cout << val << " 是浮点类型" << std::endl;
}

// 默认版本：当 T 既不是整型也不是浮点型时启用该函数模板
template <typename T>
typename std::enable_if<!std::is_integral<T>::value && !std::is_floating_point<T>::value>::type
print_type_info(T val) {
    std::cout << "未知类型" << std::endl;
}
// 注意：
// enable_if 条件是逻辑非的组合，确保只有其他两个版本不满足时，才启用此函数。
// 三个版本利用 SFINAE 机制，根据类型选择合适的函数。
```

- `std::enable_if` 第二个参数有默认值 `void`。

调用示例：

```cpp
int main() {
    print_type_info(42);          // 整数类型
    print_type_info(3.14);        // 浮点类型
    print_type_info("hello");     // 未知类型
}
```

#### 方案二：使用 C++17 if constexpr

```cpp
#include <iostream>
#include <type_traits>

template <typename T>
void print_type_info(T val) {
    if constexpr (std::is_integral_v<T>) {
        std::cout << val << " 是整数类型" << std::endl;
    } else if constexpr (std::is_floating_point_v<T>) {
        std::cout << val << " 是浮点类型" << std::endl;
    } else {
        std::cout << "未知类型" << std::endl;
    }
}
```

这个版本更清晰、易读、易维护，不依赖函数重载和 `enable_if`，在现代 C++ 中更受欢迎。

#### 方案三：C++20 Concepts

```cpp
#include <iostream>
#include <concepts>

template <std::integral T>
void print_type_info(T val) {
    std::cout << val << " 是整数类型" << std::endl;
}

template <std::floating_point T>
void print_type_info(T val) {
    std::cout << val << " 是浮点类型" << std::endl;
}

template <typename T>
void print_type_info(T val) {
    std::cout << "未知类型" << std::endl;
}
```

- `template <std::integral T>` 等价于 `template <typename T> requires std::integral<T>`。
- `requires` 子句可以放在模板参数列表后，也可以直接写在函数体前：

```cpp
template <typename T>
void print_type_info(T val) requires std::integral<T> {
    std::cout << val << " 是整数类型" << std::endl;
}
```

- 功能完全一样，只是语法不同，更灵活。

#### 对比

| 特性                 | if constexpr           | enable_if                            | concepts (C++20)                   |
| -------------------- | ---------------------- | ------------------------------------ | ---------------------------------- |
| 作用位置             | 函数体内部             | 函数签名（返回值 / 参数 / 模板参数） | 模板参数约束、函数签名             |
| 能否影响函数是否存在 | 否（函数始终存在）     | 是（SFINAE）                         | 是（约束不满足时不参与匹配）       |
| 能否影响重载决议     | 否                     | 是                                   | 是                                 |
| 代码可读性           | 简单直观               | 冗长（写法复杂）                     | 直观（语义清晰）                   |
| 出错时提示           | 模糊（可能进入空分支） | 错误信息复杂                         | 错误信息清晰（直接说明不满足概念） |
| 编译期分支裁剪       | 支持（不满足分支丢弃） | 不支持                               | 不支持（只是限制选择）             |
| 标准引入版本         | C++17                  | C++11                                | C++20                              |