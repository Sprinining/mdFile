## 条款9：优先考虑别名声明 (using) 而非 typedef

### 基本用法对比

| 类型                | 语法            | 示例                               |
| ------------------- | --------------- | ---------------------------------- |
| `typedef`           | 旧写法（C++98） | `typedef std::vector<int> VecInt;` |
| `using`（别名声明） | 新写法（C++11） | `using VecInt = std::vector<int>;` |

两者功能一致，但 `using` 更简洁、可读性更高，推荐使用。

### 函数指针写法对比

```cpp
// typedef 形式
typedef void (*FP)(int, const std::string&);

// using 形式（更清晰）
using FP = void (*)(int, const std::string&);
```

### using 支持别名模板，typedef 不支持

#### C++11：别名模板写法更简洁

```cpp
// 定义一个别名模板 MyAllocList，用于简化带有自定义分配器 MyAlloc 的 std::list 写法
// 对于任意类型 T，MyAllocList<T> 就等价于 std::list<T, MyAlloc<T>>
template<typename T>
using MyAllocList = std::list<T, MyAlloc<T>>;

// 创建一个名为 lw 的变量，它的类型是 MyAllocList<Widget>
// 实际类型是 std::list<Widget, MyAlloc<Widget>>
MyAllocList<Widget> lw;  // 直接使用，语法简洁明了
```

#### C++98：typedef 只能通过嵌套 struct 实现

```cpp
// 定义一个模板结构体 MyAllocList，接收一个类型参数 T
template<typename T>
struct MyAllocList {
    // 在结构体中定义一个类型别名 type，表示使用自定义分配器 MyAlloc 的 std::list
    // 即 type 等价于 std::list<T, MyAlloc<T>>
    typedef std::list<T, MyAlloc<T>> type;
};

// 使用 MyAllocList<Widget>::type 定义一个对象 lw
// 由于我们用了 typedef，获取定义的类型要写成 "::type" 的形式，比较繁琐
MyAllocList<Widget>::type lw;
```

### 编译器对 typename 的要求不同

先看这个例子：

```cpp
template<typename T>
struct MyAllocList {
    typedef std::list<T> type;
};
```

现在在另一个模板中想用它：

```cpp
template<typename T>
class Widget {
    MyAllocList<T>::type list;  // 编译报错
};
```

为什么报错？

- 因为 `MyAllocList<T>::type` 依赖于模板参数 `T`，编译器无法知道 `type` 是一个类型还是一个静态成员变量（比如 `int type;`）；
- 这在 C++ 术语里叫 **dependent name（依赖名字）**；
- 所以必须显式告诉编译器：这是一个类型，用 `typename`：

正确写法：

```cpp
template<typename T>
class Widget {
    typename MyAllocList<T>::type list;  // 明确告诉编译器：type 是类型
};
```

再看对比：`using` 就不需要 `typename`

```cpp
template<typename T>
using MyAllocList = std::list<T>;

template<typename T>
class Widget {
    MyAllocList<T> list;  // 不需要 typename，编译器知道 MyAllocList<T> 是类型
};
```

### C++14 的改进：提供统一的 _t 后缀别名

C++11 写法（繁琐）：

```cpp
typename std::remove_const<T>::type
typename std::add_lvalue_reference<T>::type
```

C++14 新写法：

```cpp
std::remove_const_t<T>
std::add_lvalue_reference_t<T>
```

如果项目还在用 C++11，可以手动实现这些别名：

```cpp
template <typename T>
using remove_const_t = typename std::remove_const<T>::type;
```

### 总结

- **优先使用 `using` 声明别名，取代 `typedef`**。
- **使用别名模板 (`using`) 可以让模板代码更简洁，省去 `::type` 和 `typename`**。
- **C++14 起应优先使用 `_t` 后缀形式的 type traits 别名（如 `remove_const_t<T>`）**。
- 避免在现代 C++ 中使用繁琐的 `typedef` 结构，特别是模板相关的。