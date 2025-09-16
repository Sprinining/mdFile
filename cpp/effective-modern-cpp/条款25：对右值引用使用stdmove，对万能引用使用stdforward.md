## 条款 25：对右值引用使用 std::move，对万能引用使用 std::forward

### 核心要点

| 引用类型       | 用法                      | 原因                                   |
| -------------- | ------------------------- | -------------------------------------- |
| 右值引用 `T&&` | 使用 `std::move(x)`       | 因为它总绑定右值，无条件移动           |
| 万能引用 `T&&` | 使用 `std::forward<T>(x)` | 可能绑定左值或右值，需**有条件地**转发 |

### 示例

#### 正确使用 std::move：右值引用

```cpp
class Widget {
public:
    Widget(Widget&& rhs)
        : name(std::move(rhs.name)), p(std::move(rhs.p)) {}
private:
    std::string name;
    std::shared_ptr<SomeType> p;
};
```

- `rhs` 是一个**具名变量**，它即使是右值引用类型 `Widget&&`，但在表达式中是一个**左值**。所以像 `rhs.name`、`rhs.p` 这些表达式，都是**左值表达式**。如果不加 `std::move`，这些左值就会调用对应类型的**拷贝构造函数**，而不是移动构造函数！
- `rhs` 是右值引用，只能绑定右值，所以可以**安全无条件地**用 `std::move` 触发移动。

#### 正确使用 std::forward：万能引用

```cpp
template<typename T>
void setName(T&& newName) {
    name = std::forward<T>(newName);
}
```

`newName` 是万能引用，可能是左值也可能是右值。`std::forward<T>` 可以根据传入类型安全转发。

#### 错误：在万能引用上用 std::move

```cpp
template<typename T>
void setName(T&& newName) {
    name = std::move(newName); // 即便传的是左值，也会被移动
}
```

调用：

```cpp
std::string n = "name";
w.setName(n); // n 是左值，但被 std::move 移动 → n 变成未定义但有效的状态。
```

> “**未定义但有效（valid but unspecified）**”这个短语是 C++ 标准中的一种术语，它的意思是：对象本身依然是“**合法的、可析构的、不会崩溃的**”，但它的**内容你不能再做出任何假设**，即：值不确定、不保证是什么。

### 重载 vs 模板：使用万能引用更灵活

```cpp
class Widget {
public:
    void setName(const std::string& s);   // 复制
    void setName(std::string&& s);        // 移动
};
```

虽然也可以，但：

- 代码重复
- 性能可能低（有临时对象创建）
- 参数越多，重载爆炸（2ⁿ 种组合）
- 无法扩展到可变参数场景

推荐改用万能引用：

```cpp
template<typename T>
void setName(T&& newName) {
    name = std::forward<T>(newName);
}
```

### 多次使用时只在最后 std::move / std::forward

```cpp
template<typename T>
void setSignText(T&& text) {
    sign.setText(text);                         // 保留值
    auto now = std::chrono::system_clock::now();
    signHistory.add(now, std::forward<T>(text)); // 最后再转右值
}
```

- **前面保留 text 的值，不能移动**（后面还要用）
- **最后一次使用 text，可以考虑移动**（提高性能）

如果一上来就 `std::move(text)`，那前面用的时候就已经“掏空”了，值可能就乱了。

### 按值返回时，右值引用/万能引用需要 std::move / std::forward

```cpp
Matrix operator+(Matrix&& lhs, const Matrix& rhs) {
    lhs += rhs;
    return std::move(lhs); // 正确：移动返回，避免拷贝
}
```

对于万能引用同理：

```cpp
template<typename T>
Fraction reduceAndCopy(T&& frac) {
    frac.reduce();
    return std::forward<T>(frac); // 正确转发
}
```

- 返回局部变量时，编译器允许且通常会做返回值优化（RVO），直接在调用者分配的内存构造返回值，避免拷贝和移动。

- 但当返回的不是局部对象本身，而是局部对象的引用（右值引用或万能引用）时，RVO 不成立了，编译器必须把该引用所指对象移动或拷贝到返回值内存中。
- **`return std::move(lhs);` 的作用是告诉编译器“把 lhs 当做右值来处理，使用移动构造而非拷贝构造”**
- 同理，万能引用使用 `std::forward<T>(frac)` 保持左右值属性，保证当传入右值时移动，传入左值时拷贝。

#### 不用 `std::move` / `std::forward` 会怎样？

```cpp
return lhs;
```

- `lhs` 是一个**左值**（因为它有名字），
- 编译器会使用拷贝构造函数，而不是移动构造函数，
- 可能导致效率低下。

#### 为什么不能总用 `std::move`？

- **千万不要对普通局部变量直接使用 `std::move` 返回，否则会阻止编译器做返回值优化（RVO）**，导致性能反而变差。
- 但**如果返回的是右值引用参数，或者万能引用参数，则必须显式 `std::move` / `std::forward` 以启用移动构造**。

#### 小结

| 返回方式     | 是否需要 `std::move` / `std::forward`  | 说明                           |
| ------------ | -------------------------------------- | ------------------------------ |
| 按值返回对象 | 需要（右值引用/万能引用参数时）        | 触发移动构造，提高效率         |
| 返回左值引用 | 不需要                                 | 直接返回已有对象的引用，无拷贝 |
| 返回右值引用 | 不建议返回局部变量引用；合理时不需移动 | 避免悬挂引用，确保引用有效     |

| 场景             | 返回时是否用 `std::move` / `std::forward` | 说明                   |
| ---------------- | ----------------------------------------- | ---------------------- |
| 返回普通局部变量 | 不用                                      | 让编译器做 RVO，最高效 |
| 返回右值引用参数 | 需要用 `std::move`                        | 告诉编译器用移动构造   |
| 返回万能引用参数 | 需要用 `std::forward`                     | 保留左值或右值属性     |

通俗地说就是：

- 调用者传入一个右值（临时对象或 `std::move` 产生的右值），
- 函数内部用一个右值引用或者万能引用形参接收，
- 函数如果要把这个形参返回（按值返回），需要用 `std::move` 或 `std::forward` 把它“转成右值”再返回，
- 这样才能触发移动构造，避免不必要的拷贝，提高效率。

### 误用：对局部变量返回时使用 std::move

错误做法：

```cpp
Widget makeWidget() {
    Widget w;
    // ...
    return std::move(w);  // 禁止 RVO（返回值优化）
}
```

应当写：

```cpp
Widget makeWidget() {
    Widget w;
    return w; // 编译器执行 RVO，避免拷贝/移动
}
```

- **返回局部变量**满足 RVO（或 NRVO）条件，编译器会优化掉复制或移动。

- 如果加了 `std::move`，会阻止编译器做优化！

### 特例：函数参数按值返回

```cpp
Widget makeWidget(Widget w) {
    return w; // 语义上等价于 return std::move(w)，无需显式写
}
```

- 这里的 `w` 是函数的按值参数，在调用时通过拷贝或移动构造生成的局部变量。
- 函数返回时写 `return w;`，看起来是返回一个左值（`w` 是有名字的局部变量）。
- **但 C++ 标准允许**（并推荐）对返回的按值参数做**隐式的右值转换**，这意味着返回语句等价于 `return std::move(w);`，从而触发移动构造，避免不必要的拷贝。
- 这是语言层面的规定，而不是强制编译器必须这么做（编译器可以选择是否执行拷贝消除，但必须保证结果语义一致）。

额外说明

- 注意，这与**返回值优化（RVO）**不同，RVO 是编译器的优化行为，通常针对函数内部定义的局部变量，而非按值参数。
- 对按值参数返回时，RVO 无法应用，因此编译器通过隐式转换为右值来提高效率。