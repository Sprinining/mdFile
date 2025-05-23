## C++异常处理

C++ 的异常处理机制是通过 `try`、`throw` 和 `catch` 三个关键字来实现的，其设计目的是在程序发生错误时提供一种清晰的处理流程，而不是像 C 一样靠返回值或错误码。

### 基本语法结构

```cpp
try {
    // 可能抛出异常的代码
    ...
    throw 异常对象; // 抛出异常
} catch (异常类型1 变量名) {
    // 处理异常类型1
} catch (异常类型2 变量名) {
    // 处理异常类型2
} catch (...) {
    // 捕获所有异常
}
```

### 关键字解释

#### 1. `try`

用于包裹可能发生异常的代码块。

#### 2. `throw`

用于抛出异常，可以抛出任意类型（如整型、字符串、对象等）。例如：

```cpp
throw 1;                      // 抛出 int 类型
throw "Error occurred";       // 抛出 const char* 类型
throw std::runtime_error("xx"); // 抛出异常类对象
```

#### 3. `catch`

用于捕获异常。参数的类型决定了它能捕获哪类异常（匹配类型或其子类）。`catch(...)` 可用于捕获所有异常。

### 示例

```cpp
#include <iostream>
#include <stdexcept>

void mightFail(bool shouldThrow) {
    if (shouldThrow) {
        throw std::runtime_error("Something went wrong!");
    }
}

int main() {
    try {
        mightFail(true);
    } catch (const std::runtime_error& e) {
        std::cout << "Caught a runtime error: " << e.what() << std::endl;
    } catch (...) {
        std::cout << "Caught some other exception." << std::endl;
    }
    return 0;
}
```

### 异常类体系

C++ 标准库提供了许多内置的异常类，它们都继承自 `std::exception`，常见的有：

| 异常类                  | 描述                         |
| ----------------------- | ---------------------------- |
| `std::exception`        | 所有标准异常的基类           |
| `std::runtime_error`    | 表示运行时错误               |
| `std::logic_error`      | 表示逻辑错误（如非法参数等） |
| `std::bad_alloc`        | 内存分配失败                 |
| `std::out_of_range`     | 越界访问                     |
| `std::invalid_argument` | 非法参数                     |

这些类都支持 `what()` 方法返回描述信息。

### 注意事项

#### 1. 异常匹配机制

C++ 使用“从上到下”按类型匹配 `catch`，一旦匹配成功则不再继续向下匹配。

#### 2. 异常对象的拷贝

异常对象是被**复制**到 catch 块中的，通常使用引用（如 `const std::exception&`）避免拷贝开销。

#### 3. 析构函数抛异常的问题

如果析构函数抛异常，可能会导致程序在异常传播时终止（特别是在栈展开过程中已抛出异常的情况下），**建议析构函数不抛异常**。

### C++11/17 的补充说明

#### 1. `noexcept`

用于声明函数不会抛异常，编译器可进行优化：

```cpp
void func() noexcept;
```

#### 2.`throw()`（已弃用）

C++98 的异常说明符（如 `void f() throw(int);`）在 C++11 后已弃用。

### 自定义异常类

自定义异常类并重写 `what()` 方法：

```cpp
class MyError : public std::exception {
    std::string msg;
public:
    MyError(const std::string& m) : msg(m) {}
    const char* what() const noexcept override {
        return msg.c_str();
    }
};
```

```cpp
try {
    throw MyError("网络连接失败");
} catch (const std::exception& e) {
    std::cout << e.what() << std::endl;
}
```

### 异常与资源管理

推荐使用 RAII（资源获取即初始化）来管理资源，这样即使发生异常，资源也能自动释放。例如使用 `std::vector`、`std::unique_ptr` 管理内存资源。

> RAII 是一种 C++ 中非常重要的资源管理策略，它利用对象生命周期（构造/析构）自动处理资源，避免手动 `new/delete`，从而防止内存泄漏、文件未关闭、死锁等问题。

**RAII + 异常机制 = 安全 + 简洁 + 高效** 是 C++ 最强大的组合之一。