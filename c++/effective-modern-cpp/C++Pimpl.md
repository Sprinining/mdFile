## C++Pimpl

Pimpl（Pointer to IMPLementation），也叫作**编译防火墙（Compilation Firewall）**，是一种在 C++ 中常用的设计技术，用于实现**封装（Encapsulation）\**和\**降低编译依赖（Decoupling）**。

### Pimpl 的核心目标

1. **隐藏实现细节**：实现对类私有成员的完全封装。
2. **减少编译依赖和耦合**：避免修改内部实现后触发大规模重编译。
3. **二进制兼容（ABI 稳定）**：对库的使用者隐藏实现变化，提高库版本兼容性。

### 基本写法

```cpp
// Foo.h（对外头文件）
#ifndef FOO_H
#define FOO_H

#include <memory>

class FooImpl;  // 前向声明

class Foo {
public:
    Foo();
    ~Foo();

    void doSomething();

private:
    std::unique_ptr<FooImpl> impl_;  // 指向实现类的智能指针
};

#endif
```

```cpp
// Foo.cpp（实现文件）
#include "Foo.h"

class FooImpl {
public:
    void doSomethingImpl() {
        // 实现细节，可能包含很多私有成员
    }
};

Foo::Foo() : impl_(std::make_unique<FooImpl>()) {}
Foo::~Foo() = default;

void Foo::doSomething() {
    impl_->doSomethingImpl();
}
```

### Pimpl 技术优点

| 优点                       | 说明                                                         |
| -------------------------- | ------------------------------------------------------------ |
| **封装性强**               | 用户无法访问到私有实现（比如成员变量、私有函数）。           |
| **减小编译依赖**           | 修改 `FooImpl` 的成员，不会影响 `Foo.h`，用户代码不需要重新编译。 |
| **提高 ABI 稳定性**        | 改动不影响对外接口，更适合发布库。                           |
| **可以用于跨平台实现隐藏** | 不同平台的 `FooImpl` 可以实现不同逻辑。                      |

### 缺点与注意事项

| 缺点                   | 说明                                       |
| ---------------------- | ------------------------------------------ |
| **略微增加运行时开销** | 多了一次指针跳转和动态分配内存。           |
| **不利于内联优化**     | 编译器无法看到具体实现，可能无法优化调用。 |
| **复杂度增加**         | 增加了一层类结构和管理逻辑。               |

### 实用建议

- 使用 `std::unique_ptr<T>`（C++11 起）管理 Pimpl 指针，无需手动释放资源。
- 如果要支持拷贝语义，可使用 **复制控制技巧（比如 deep copy）**。
- 如果开发**长期维护的库**或**暴露 API 给外部模块**，强烈推荐使用 Pimpl。

### 拓展：可复制的 Pimpl（Copyable Pimpl）

默认情况下，`std::unique_ptr<FooImpl>` 使 `Foo` 不可复制，如果需要支持：

```cpp
class Foo {
public:
    Foo();
    Foo(const Foo& other);
    Foo& operator=(const Foo& other);
    ~Foo();

private:
    std::unique_ptr<FooImpl> impl_;
};
```

并在 `.cpp` 中实现深拷贝逻辑：

```cpp
Foo::Foo(const Foo& other)
    : impl_(std::make_unique<FooImpl>(*other.impl_)) {}

Foo& Foo::operator=(const Foo& other) {
    if (this != &other) {
        *impl_ = *other.impl_;  // 需要 FooImpl 支持拷贝赋值
    }
    return *this;
}
```

- Pimpl 是一种将类的实现细节完全隐藏在 .cpp 文件中、通过指针转发实现功能、同时显著降低编译依赖和提高封装性的设计技巧。

### 使用 std::unique_ptr 来实现的 Pimpl 指针，必须在头文件中声明特种成员函数，且在实现文件中实现

最典型的是析构函数：

```cpp
// Foo.h
class Foo {
public:
    Foo();
    ~Foo();  // 必须手动声明，不能写成 = default

private:
    std::unique_ptr<FooImpl> impl_;  // FooImpl 是不完整类型
};
```

如果写成 `~Foo() = default;`，编译器会**在头文件中尝试生成析构函数**，这时 `unique_ptr<FooImpl>` 的析构函数需要完整的 `FooImpl` 类型 —— 但头文件中还只有前向声明：

```cpp
class FooImpl;  // 不完整类型
```

于是就报错了：

```css
error: invalid application of ‘sizeof’ to incomplete type ‘FooImpl’
```

- 因为 `std::unique_ptr<T>` 的析构需要 T 是完整类型，而 Pimpl 模式中头文件只有前向声明，所以必须将特种成员函数的**实现放在 `.cpp` 中**，防止编译器在类型不完整时自动生成这些函数。