## C++类型萃取

C++ 类型萃取（Type Traits）是 **模板元编程** 的核心工具之一，用于在 **编译期分析和操纵类型信息**。它们常用于 **泛型编程** 中，帮助我们写出更通用、类型安全的代码，特别是在 **STL、标准库实现、SFINAE、concepts** 等地方广泛使用。

### 一、类型萃取的核心思想

通过模板结构体和偏特化机制，在编译期对类型进行**判断、提取、转换**，比如：

- 判断一个类型是不是指针？
- 判断两个类型是否相同？
- 从 `const int*` 中去除 `const` 或指针修饰？
- 把某类型转换成引用？

### 二、常见标准类型萃取（`<type_traits>`）

#### 1. 类型判断类模板（Type Property Checks）

判断一个类型是否满足某种特性，结果都提供一个静态成员变量 `::value`。

| Trait                       | 说明           | 示例                                   |
| --------------------------- | -------------- | -------------------------------------- |
| `std::is_integral<T>`       | 是否为整型     | `std::is_integral<int>::value == true` |
| `std::is_floating_point<T>` | 是否为浮点类型 | `float, double`                        |
| `std::is_pointer<T>`        | 是否为指针     | `int*` 是                              |
| `std::is_const<T>`          | 是否为 const   | `const int` 是                         |
| `std::is_reference<T>`      | 是否为引用     | `int&`, `int&&` 是                     |
| `std::is_array<T>`          | 是否是数组     | `int[3]` 是                            |

> ✅ C++17 起也可以用 `std::is_pointer_v<T>` 简化书写。

#### 2. 类型修改类模板（Type Modifiers）

这些萃取模板用于“去掉”或“添加”某些类型修饰。

| Trait                    | 功能                                       | 示例                                    |
| ------------------------ | ------------------------------------------ | --------------------------------------- |
| `std::remove_const<T>`   | 移除 const 修饰                            | `remove_const<const int>::type` → `int` |
| `std::remove_pointer<T>` | 移除指针                                   | `remove_pointer<int*>::type` → `int`    |
| `std::add_const<T>`      | 添加 const 修饰                            | `add_const<int>::type` → `const int`    |
| `std::decay<T>`          | 衰变类型（去引用、去 const、数组转指针等） | `int[3]` → `int*`                       |

#### 3. 类型比较类模板（Type Relations）

| Trait                            | 功能             | 示例                               |
| -------------------------------- | ---------------- | ---------------------------------- |
| `std::is_same<T, U>`             | 判断类型是否相同 | `is_same<int, int>::value == true` |
| `std::is_base_of<Base, Derived>` | 判断是否为基类   | `is_base_of<A, B>`                 |
| `std::is_convertible<T, U>`      | 判断能否隐式转换 | `is_convertible<int, double>`      |

### 三、自定义类型萃取（简化实现）

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

### 四、搭配 `enable_if` 使用

类型萃取 + `std::enable_if` 可用于 SFINAE（Substitution Failure Is Not An Error）机制控制函数模板是否可用。

```cpp
template<typename T>
typename std::enable_if<std::is_integral<T>::value, T>::type
add_one(T val) {
    return val + 1;
}
```

这个函数只有在 `T` 是整型时才会参与编译。

### 五、C++20 Concepts 替代传统 SFINAE

C++20 引入了 concepts，使类型约束变得更清晰：

```cpp
template<typename T>
concept Integral = std::is_integral_v<T>;

template<Integral T>
T add_one(T x) {
    return x + 1;
}
```

### 六、实际应用场景

- STL 容器如 `std::vector` 优化不同类型的构造方式
- `std::move_if_noexcept` 等函数中用来判断是否应该移动或拷贝
- 自定义容器或算法模板时做类型检查

### 七、使用类型萃取来选择不同的函数实现

#### 方案一：使用 `std::enable_if` + 类型萃取

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

调用示例：

```cpp
int main() {
    print_type_info(42);          // 整数类型
    print_type_info(3.14);        // 浮点类型
    print_type_info("hello");     // 未知类型
}
```

> | 写法                       | 条件满足时的 `type` | 用途举例                                         |
> | -------------------------- | ------------------- | ------------------------------------------------ |
> | `enable_if<cond>::type`    | `void`              | 作为函数返回类型，用于启用/禁用函数（返回 void） |
> | `enable_if<cond, T>::type` | `T`                 | 函数返回类型是 `T`，同时满足条件启用             |

#### 方案二（更现代）：使用 C++17 `if constexpr`（推荐）

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

### 八、总结

| 分类     | 常用萃取                                  |
| -------- | ----------------------------------------- |
| 类型判断 | `is_integral`, `is_pointer`, `is_class`   |
| 类型变换 | `remove_cv`, `decay`, `add_pointer`       |
| 类型关系 | `is_same`, `is_base_of`, `is_convertible` |
| 工具类   | `enable_if`, `conditional`, `declval`     |