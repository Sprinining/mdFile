## 条款23：理解 std::move 和 std::forward

### 右值引用、移动语义与完美转发简介

#### 移动语义（Move Semantics）
允许编译器用“廉价”的移动操作代替“昂贵”的拷贝操作。通过移动构造函数和移动赋值操作符，程序员可以控制对象如何被“移动”而不是复制。它使得一些类型（如 `std::unique_ptr`、`std::future`、`std::thread`）可以只被移动而非复制。

#### 完美转发（Perfect Forwarding）
允许函数模板接收任意数量和任意类型的实参，并将这些实参保持其左值/右值属性不变地转发给另一个函数。常用来实现包装器或中间转发函数。

#### 右值引用（Rvalue Reference）
是连接移动语义和完美转发的语言机制基础。用 `T&&` 表示右值引用类型，但需要注意：

- 函数形参（包括右值引用形参）本身是**左值**。
- `T&&` 类型的含义依赖于上下文，特别是在模板中。

### 形参即使是右值引用类型也是左值

"左值/右值" 是表达式的属性，"左值引用/右值引用" 是变量的类型。

```cpp
void f(Widget&& w);  // w的类型是右值引用
```

- 但 `w` 本身是一个左值（变量名），不能直接视为右值。

- 这点很重要，因为它决定了调用时的行为和传参方式。

举个例子说明：

```cpp
void f(Widget&& w) {
    process(w);  // 注意：这里是传 w，而不是 std::move(w)
}
```

你可能以为 `w` 是右值引用，传给 `process(w)` 会调用 `process(Widget&&)`，但**实际上不会**。

因为：

- `w` 是一个有名字的变量，**它是左值**；
- 所以 `process(w)` 调用的是接受左值引用的重载版本（`process(const Widget&)` 或 `process(Widget&)`）；
- 要想让 `w` 被当作右值传下去，必须写成 `std::move(w)` 或 `std::forward<T>(w)`（若 `w` 是通用引用）；

### std::move

- **本质**：仅执行 `static_cast<T&&>(param)`，告诉编译器“我打算把它当右值用”。
- **不会移动对象本身**，是否执行移动行为取决于随后调用的函数（如移动构造函数）。
- **常见用途**：用于明确标记一个对象可以被移动，例如移动构造、移动赋值时。
- **注意事项**：不能对 `const` 对象使用 `std::move` 期待移动行为！

```cpp
std::string s = "text";
std::string s2 = std::move(s);  // s 的内容被移动（实际上由移动构造决定）
```

错误示例（const 导致移动失效）：

```cpp
explicit Annotation(const std::string text)
: value(std::move(text)) // 实际发生的是拷贝！
```

`text` 是 `const std::string`，移动构造无法接受 `const string&&`，因此 **退化为拷贝**。

第一步：构造函数形参声明

```cpp
const std::string text
```

- `text` 是一个**按值传递**的变量
- 即构造函数**入参时已经拷贝了一份（或移动）**
- 此时的 `text` 是一个 **局部变量，类型为 `const std::string`**

第二步：`std::move(text)` 做了什么？

```cpp
std::move(text)
```

等价于：

```cpp
static_cast<std::string&&>(text)
```

**注意！** `text` 的类型是 `const std::string`，所以它变成了：

```cpp
static_cast<const std::string&&>(text) // 是 const string 的右值引用
```

第三步：调用 `value(std::move(text))` → 构造 `value`

此时构造成员变量 `value`，即：

```cpp
std::string value = static_cast<const std::string&&>(text);
```

> 在写 `std::string value = ...` 时，**就是在构造一个对象**。C++ 语言规定：**当对象被构造时，编译器必须从所有可用的构造函数中选择最匹配的那一个**。这一步称为**构造函数重载决议**。

现在，**编译器要在 `std::string` 的构造函数中做重载决议**，看看哪个函数最匹配：

```cpp
string(const string&);  // ✅ 可接受 const string（左值或右值）
string(string&&);       // ❌ 不接受 const string&&
```

所以，编译器选择了：

```cpp
string(const string&) // 即调用拷贝构造函数
```

### std::forward

- **本质**：根据模板类型 `T` 和参数 `param` 的值类别，在编译期选择是否转为右值。
- **用途**：主要用于“**完美转发**”——保留传入参数的值类别，转发给其他函数。

```cpp
template<typename T>
void wrapper(T&& arg) {
    callee(std::forward<T>(arg));  // 保留左/右值特性
}
```

- 如果 `arg` 是左值 → `T` 推导为 `T&` → `forward<T>(arg)` 结果是左值

- 如果 `arg` 是右值 → `T` 推导为 `T` → `forward<T>(arg)` 结果是右值

### 示例对比

`std::move`：明确表达“我要用右值”

```cpp
class Widget {
public:
    Widget(Widget&& rhs)
    : s(std::move(rhs.s))         // 明确：我就是要移动
    { ++moveCtorCalls; }

private:
    std::string s;
    static std::size_t moveCtorCalls;
};
```

若用 `std::forward` 写法：

```cpp
: s(std::forward<std::string>(rhs.s))  // 繁琐、不直观、易错
```

- 不必要地引入模板参数
- 写错 `std::string&` 会导致退化为拷贝
- 含义不明确，不该用于非模板上下文

### 常见误区

| 误区                                                | 解说                                                    |
| --------------------------------------------------- | ------------------------------------------------------- |
| **误以为 `std::move` 会移动对象**                   | 实际上它只是类型转换，是否移动由函数（如构造函数）决定  |
| **对 const 对象使用 `std::move` 会移动**            | 不会，`const T&&` 会阻止移动，转为拷贝                  |
| **在普通函数中用 `std::forward` 更高级**            | 实际上不合适，`std::forward` 主要用于模板通用引用上下文 |
| **以为 `std::move` 和 `std::forward` 是运行期函数** | 它们在运行期没有任何开销，只是编译期类型转换            |

### 总结

- `std::move` 是一种 **无条件右值转换**，用于触发移动操作，但**不保证一定发生移动**。
- `std::forward` 是一种 **有条件右值转换**，仅在实参是右值时才转换，用于模板中的完美转发。
- 它们本质上都只是 **编译期类型转换**，**运行期什么都不做**。