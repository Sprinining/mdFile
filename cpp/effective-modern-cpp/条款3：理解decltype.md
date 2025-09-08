## 条款3：理解 decltype

- `decltype(expr)` 会**返回表达式 `expr` 的类型**（精确地，不做修改）。
- 它**不像 `auto` 使用模板类型推导规则**，不会剥去引用、cv 限定等信息。

```cpp
const int i = 0;
decltype(i)       // const int

bool f(const Widget& w);
decltype(w)       // const Widget&
decltype(f)       // bool(const Widget&)
decltype(f(w))    // bool

vector<int> v;
decltype(v)       // vector<int>
decltype(v[0])    // int&
```

### 函数模板返回值推导

目标：写一个模板函数 `authAndAccess`，能返回容器 `c[i]` 的值，并带有认证操作。

#### C++11 尾置返回类型

```cpp
// 使用 decltype 精确推导返回类型
template<typename Container, typename Index>
auto authAndAccess(Container& c, Index i) -> decltype(c[i]) {
    authenticateUser();
    return c[i];
}
```

#### C++14 简化写法（错误版本）

```cpp
template<typename Container, typename Index>
auto authAndAccess(Container& c, Index i) {
    authenticateUser();
    return c[i];  // 使用 auto 推导类型，但会丢掉引用属性
}
```

- `auto` 使用**模板类型推导规则**。
- 会导致 `decltype(c[i])` 是 `T&`，而 `auto` 推导为 `T`。
- 结果是返回值变为右值（非引用），无法进行赋值等操作。

#### C++14 正确写法：`decltype(auto)`

```cpp
template<typename Container, typename Index>
decltype(auto) authAndAccess(Container& c, Index i) {
    authenticateUser();
    return c[i];  // 推导为真正的 decltype(c[i])
}
```

#### 进一步支持右值容器

```cpp
template<typename Container, typename Index>
decltype(auto) authAndAccess(Container&& c, Index i) {
    authenticateUser();
    return std::forward<Container>(c)[i];  // 完美转发
}
```

- `Container&&` 是万能引用：既支持左值也支持右值。
- `std::forward` 保持值类别（左值/右值）不变。

##### 左值容器

```cpp
std::deque<std::string> d;
auto& s = authAndAccess(d, 2);  
// 返回 std::string&，安全
```

##### const 左值容器

```cpp
const std::deque<std::string> d;
auto& s = authAndAccess(d, 2);  
// 返回 const std::string&，安全
```

##### 右值容器

```cpp
auto s = authAndAccess(makeDeque(), 2);
// 实际返回 std::string&，但绑定到临时容器元素
// 容器销毁 → 悬垂引用 → UB
```

- 函数返回类型 `decltype(auto)` → 推导为 **`std::string&`**
- 也就是说，返回的是**对临时 deque 内部元素的引用**
- 而这个临时 deque 在函数返回后立即销毁
  - `s` 得到的引用**指向已经销毁的内存** → **悬垂引用**
  - 使用它就是**未定义行为 (UB)**

修改办法：区分左值/右值容器

```cpp
template<typename Container, typename Index>
decltype(auto) authAndAccess(Container&& c, Index i) {
    authenticateUser();
    if constexpr (std::is_lvalue_reference_v<Container&&>) {
        return c[i];              // 左值容器 → 返回引用
    } else {
        return std::move(c[i]);   // 右值容器 → 返回值（移动/拷贝），避免悬垂
    }
}
```

- `c[i]` 是 `std::string&`（元素的左值引用）
- `std::move(c[i])` 转成 `std::string&&`（右值引用）
- 这告诉编译器可以使用移动构造或移动赋值来初始化外部变量
  - `auto` 去掉引用 → `s` 类型是 **`std::string`**
  - 编译器调用**移动构造函数**，把临时容器中的元素“搬”到 `s` 中
  - 因为是移动/拷贝了一个新对象，所以**安全**，不会悬垂

### decltype(auto) 与表达式细节

在 C++14 中，`decltype(auto)` 会根据返回语句使用 **decltype 的规则**来推导类型。

```cpp
decltype(auto) f1() {
    int x = 0;
    return x;      // decltype(x) 是 int
}

decltype(auto) f2() {
    int x = 0;
    return (x);    // decltype((x)) 是 int&，悬垂引用！
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