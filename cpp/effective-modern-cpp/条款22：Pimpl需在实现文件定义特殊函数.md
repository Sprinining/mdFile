## 条款22：Pimpl 需在实现文件定义特殊函数

当在类中使用 Pimpl（Pointer to Implementation）惯用法，并用 `std::unique_ptr` 管理实现类指针时，类的特殊成员函数（如：析构函数、移动构造函数、拷贝构造函数等）不能只在头文件中默认生成，而必须在 `.cpp` 实现文件中显式定义出来。

### Pimpl 惯用法的目的

- **降低编译依赖**，减少头文件暴露的类型和编译时间。
- 将实现细节（如 `std::string`、`std::vector`、自定义类 `Gadget`）隐藏在 `.cpp` 中。

```cpp
// widget.h
class Widget {
public:
    Widget();
    ~Widget();  // 只声明，不定义

private:
    struct Impl;
    std::unique_ptr<Impl> pImpl;
};
```

### 为什么要在 `.cpp` 中定义特殊成员函数？

#### 问题来源

- `std::unique_ptr<Impl>` 在析构、移动时需要 `Impl` 是**完整类型**。
- 但在头文件中 `Impl` 是**不完整类型（incomplete type）**，导致：
  - 错误信息：`sizeof`、`delete` 应用于不完整类型时编译失败。

#### 正确做法

- **先在 `.cpp` 中定义 `Impl`**，再定义析构、移动/拷贝函数。

```cpp
// widget.cpp

// 定义实现类 Impl，包含 Widget 的所有私有数据成员
struct Widget::Impl {
    std::string name;
    std::vector<double> data;
    Gadget g1, g2, g3;
};

// Widget 构造函数，使用 std::make_unique 创建 Impl 实例
Widget::Widget() 
    : pImpl(std::make_unique<Impl>()) 
{}

// Widget 析构函数，放在 cpp 文件，编译器自动生成（默认实现）
// 这里可以访问完整类型 Impl，正确调用 unique_ptr 的析构
Widget::~Widget() = default;

// 移动构造函数，默认实现
// 通过移动 pImpl 智能指针实现高效移动语义
Widget::Widget(Widget&& rhs) = default;

// 移动赋值操作符，默认实现
// 通过移动 pImpl 智能指针实现高效赋值
Widget& Widget::operator=(Widget&& rhs) = default;

// 拷贝构造函数，深拷贝实现
// 新建一个 Impl，内容为 rhs.pImpl 指向对象的副本
Widget::Widget(const Widget& rhs)
    : pImpl(std::make_unique<Impl>(*rhs.pImpl)) 
{}

// 拷贝赋值操作符，深拷贝实现
// 将 rhs.pImpl 指向的 Impl 对象的内容赋给当前对象的 Impl
Widget& Widget::operator=(const Widget& rhs) {
    *pImpl = *rhs.pImpl;
    return *this;
}
```

### 为什么不能只在头文件中 `= default`？

- **`= default`**：告诉编译器自动生成特殊成员函数（比如析构函数、移动构造函数、移动赋值运算符等）。
- **自动生成的函数默认是 `inline`**：也就是说，函数体代码会直接放在头文件里，编译器在看到头文件时就尝试生成这些函数的代码。
- **而头文件里 `Impl` 只是个“声明”，没有完整定义**，属于**不完整类型**。
- **编译器要生成析构函数等代码时，需要知道 `Impl` 的大小和结构（完整类型）才能正确调用 `delete`，否则会报错**。

### 拷贝支持（深拷贝）

由于 `std::unique_ptr` 是只可移动（move-only），编译器不会自动生成拷贝函数，需要自己定义：

```cpp
Widget(const Widget& rhs)
    : pImpl(std::make_unique<Impl>(*rhs.pImpl)) {}

Widget& Widget::operator=(const Widget& rhs) {
    *pImpl = *rhs.pImpl;
    return *this;
}
```

### 使用 `std::shared_ptr` 时例外

- `shared_ptr` 删除器不依赖类型完整性，因此**不需要**显式定义析构/移动函数。
- 缺点：性能较差，控制块更大。

```cpp
class Widget {
    // 没有声明析构、移动等函数也能正常工作
private:
    struct Impl;
    std::shared_ptr<Impl> pImpl;
};
```

#### `std::unique_ptr` 的删除器是其类型的一部分

- `std::unique_ptr<T>` 的默认删除器本质上是调用 `delete` 来释放 `T*` 指针。

- **删除器的类型是 `unique_ptr` 模板类型的一部分**，即：

  ```cpp
  template<typename T, typename Deleter = std::default_delete<T>>
  class unique_ptr { ... };
  ```

- **编译器生成特殊成员函数（如析构函数）时，会内联调用默认删除器（`delete`），必须在编译时能知道 `T` 的完整类型**，否则 `delete` 不合法。

- 因为 `unique_ptr` 内部直接调用 `delete`，需要对 `T` 完全了解，才能正确生成内联代码。

#### `std::shared_ptr` 的删除器不是类型的一部分

- `shared_ptr` 不是模板参数携带删除器类型，而是通过**类型擦除**（type erasure）保存删除器，实际运行时调用。
- 其实现内部维护一个控制块（control block），里面保存指向删除器的函数指针或可调用对象。
- **`shared_ptr` 的析构函数并不直接调用 `delete`，而是调用存储在控制块里的删除器函数**。
- 这部分代码是运行时绑定的，不需要编译期知道 `T` 的完整类型，**只要调用删除器时 `T` 是完整类型即可**。
- 因此，`shared_ptr` 在头文件中生成析构函数时，不强制要求 `T` 是完整类型。

### 总结

| 目标                      | 做法                               |
| ------------------------- | ---------------------------------- |
| 使用 `Pimpl` 减少编译依赖 | 把实现细节移到 `.cpp`              |
| 使用 `std::unique_ptr`    | 在 `.cpp` 中定义析构/移动/拷贝操作 |
| 为什么                    | 避免 `delete` 应用于不完整类型     |
| 拷贝操作                  | 必须手写，需深拷贝 `Impl`          |
| 使用 `std::shared_ptr`    | 可不用定义特殊成员函数，但开销更大 |