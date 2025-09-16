## 条款33：对 auto&& 形参使用 decltype 以 std::forward 它们

C++14 支持泛型 lambda，可以用 `auto` 作为形参类型，实现模板化的 `operator()`。

### 问题

普通写法：

```cpp
auto f = [](auto x) {
    return func(normalize(x));
};
```

这里 `x` 是按值传递，导致右值传入时被当成左值传递给 `normalize`，破坏了右值传递的语义。

### 正确写法：使用通用引用 + 完美转发

```cpp
auto f = [](auto&& x) {
    return func(normalize(std::forward<???>(x)));
};
```

模板参数 `???` 是难点，普通函数模板中用模板参数 `T`，但泛型 lambda 内没有直接可用的 `T`。

### 用 decltype 获取参数的精确类型

```cpp
auto f = [](auto&& x) {
    return func(normalize(std::forward<decltype(x)>(x)));
};
```

这样，`decltype(x)` 会根据传入实参是左值还是右值，自动产生左值引用或右值引用类型，`std::forward` 完美转发参数。

### 多参数版本

```cpp
auto f = [](auto&&... params) {
    return func(normalize(std::forward<decltype(params)>(params)...));
};
```

- `auto&& x` 是通用引用，可以绑定任意左值或右值。
- `decltype(x)` 得到的类型保持了参数的引用属性。
- `std::forward<decltype(x)>(x)` 完美转发参数，保持实参左值/右值的语义。