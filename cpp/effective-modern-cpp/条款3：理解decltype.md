## 条款3：理解 decltype

- `decltype(expr)` 会**返回表达式 `expr` 的类型**（精确地，不做修改）。
- 它**不像 `auto` 使用模板类型推导规则**，不会剥去引用、cv 限定等信息。

### decltype 的常见行为

```cpp
const int i = 0;
decltype(i)       // => const int

bool f(const Widget& w);
decltype(w)       // => const Widget&
decltype(f)       // => bool(const Widget&)
decltype(f(w))    // => bool

vector<int> v;
decltype(v)       // => vector<int>
decltype(v[0])    // => int&（如果是 vector<int>）
```

### decltype 的用途：函数模板返回值推导

目标：写一个模板函数 `authAndAccess`，能返回容器 `c[i]` 的值，并带有认证操作。

#### C++11 尾置返回类型

```cpp
template<typename Container, typename Index>
auto authAndAccess(Container& c, Index i)
    -> decltype(c[i])  // 使用 decltype 精确推导返回类型
{
    authenticateUser();
    return c[i];
}
```

#### C++14 简化写法（错误版本）

```cpp
template<typename Container, typename Index>
auto authAndAccess(Container& c, Index i)
{
    authenticateUser();
    return c[i];  // 使用 auto 推导类型，但会丢掉引用属性！
}
```

- `auto` 使用 **模板类型推导规则**。
- 会导致 `decltype(c[i])` 是 `T&`，而 `auto` 推导为 `T`。
- 结果是返回值变为右值（非引用），无法进行赋值等操作。

#### C++14 正确写法：`decltype(auto)`

```cpp
template<typename Container, typename Index>
decltype(auto) authAndAccess(Container& c, Index i)
{
    authenticateUser();
    return c[i];  // 推导为真正的 decltype(c[i])
}
```

#### 进一步支持右值容器：使用通用引用 + `std::forward`

```cpp
template<typename Container, typename Index>
decltype(auto) authAndAccess(Container&& c, Index i)
{
    authenticateUser();
    return std::forward<Container>(c)[i];  // 完美转发
}
```

- `Container&&` 是通用引用：既支持左值也支持右值。
- `std::forward` 保持值类别（左值/右值）不变。

支持以下场景：

```cpp
std::deque<std::string> makeDeque();
auto s = authAndAccess(makeDeque(), 2);  // 合法：返回副本而不是悬垂引用
```

> **悬垂引用**指的是：一个引用（或指针）指向了一块已经被释放或销毁的内存区域。一旦再去访问它，行为是**未定义的**（Undefined Behavior, UB）。

`makeDeque()` 是一个函数，返回一个临时的 `std::deque<std::string>`：这是一个**右值容器**，即返回的是一个**临时对象**。

把这个右值传给 `authAndAccess`：

```cpp
template<typename Container, typename Index>
decltype(auto)
authAndAccess(Container&& c, Index i)
{
    authenticateUser();
    return std::forward<Container>(c)[i];
}
```

- `Container&&` 是 **通用引用**（可绑定左值或右值）。
- `std::forward<Container>(c)[i]` 会在右值情况下调用 `std::move(c)[i]`，把 `c` 显式转换为右值。
- `operator[]` 会返回一个 **值对象或引用**，根据容器的定义。

对于 `std::deque<std::string>`，`operator[]` 返回 `std::string&`。

**重点问题**：`authAndAccess` 返回了 `c[i]` 的结果，但 `c` 是一个临时对象。

如果返回的是 **`std::string&`**，那么会得到一个 **悬垂引用**（Dangling Reference）——因为 `makeDeque()` 生成的容器在 `authAndAccess` 返回后就被销毁了！

**解决方案**：使用 `decltype(auto)` + 通用引用的模板组合，它能根据调用上下文**决定是否返回引用还是值**。

在这行代码中：

```cpp
auto s = authAndAccess(makeDeque(), 2);
```

- `s` 是用 `auto` 定义的变量。
- 因为 `s` 是值类型（不是引用），所以 `authAndAccess` 最终会返回一个 `std::string`（值拷贝），而不是 `std::string&`。
- 拷贝是安全的，即便容器是临时的，也不会产生悬垂引用。

换句话说：

- 函数 `authAndAccess` 返回的是 `const T&`（引用）
- 但外面 `auto s` 不绑定引用，是直接创建了**副本**
- 因为 `s` 是局部变量，拷贝了临时容器元素的值，所以是安全的

### decltype(auto) 与表达式细节

在 C++14 中，`decltype(auto)` 会根据返回语句使用 **decltype 的规则** 来推导类型。

```cpp
decltype(auto) f1() {
    int x = 0;
    return x;      // decltype(x) 是 int
}

decltype(auto) f2() {
    int x = 0;
    return (x);    // decltype((x)) 是 int&，⚠️ 悬垂引用！
}
```

注意：在 `return (x);` 中，加了括号后变成左值表达式，`decltype` 推导结果变为引用类型。

### decltype 推导规则总结

| 表达式或名字                           | 推导类型                    |
| -------------------------------------- | --------------------------- |
| `int x = 0; decltype(x)`               | `int`                       |
| `decltype((x))`                        | `int&`（左值表达式）        |
| `const Widget& cw = ...; decltype(cw)` | `const Widget&`             |
| `auto w = cw;`                         | `Widget`（auto 去引用）     |
| `decltype(auto) w = cw;`               | `const Widget&`（保持引用） |

1. `decltype(expr)` 给出表达式的**精确类型**（包括引用和 `const`）。
2. 对于非变量名的左值表达式，`decltype` 会推导为 **T&**。
3. `decltype(auto)` 使用 `decltype` 规则进行自动推导，和 `auto` 不一样。
4. `(x)` 和 `x` 在 `decltype` 中是不一样的，前者返回引用类型。
5. 返回值使用 `decltype(auto)` 时需**避免返回局部变量的引用**。