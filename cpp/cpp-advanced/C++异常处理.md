## C++ 异常处理

C++ 的异常处理机制是通过 `try`、`throw` 和 `catch` 三个关键字来实现的，其设计目的是在程序发生错误时提供一种清晰的处理流程，而不是像 C 一样靠返回值或错误码。

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

- `try`：用于包裹可能发生异常的代码块。

- `throw`：用于抛出异常，可以抛出任意类型（如整型、字符串、对象等）。例如：

```cpp
throw 1;                        // 抛出 int 类型
throw "Error occurred";         // 抛出 const char* 类型
throw std::runtime_error("xx"); // 抛出异常类对象
```

- `catch`：用于捕获异常。参数的类型决定了它能捕获哪类异常（匹配类型或其子类）。`catch(...)` 可用于捕获所有异常。

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

### 异常类

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

#### 异常匹配机制

C++ 使用“从上到下”按类型匹配 `catch`，一旦匹配成功则不再继续向下匹配。

#### 异常对象的拷贝

##### 抛出时

```cpp
throw std::runtime_error("error");
```

- 异常对象通常会**被拷贝或移动**到**异常处理机制内部管理的存储区域**（runtime 内部的“异常缓冲区”）。
- 也就是说，throw 表达式创建的对象本身可能会被复制（或移动）到内部存储，用于后续传递给 catch 块。
- C++11 之后，如果异常对象支持移动构造，会优先使用移动，减少开销。

##### 捕获时

```cpp
try {
    throw std::runtime_error("error");
} catch (std::runtime_error e) { // 捕获方式1
    // e 是异常对象的副本
}
```

- **按值捕获**：catch 块里的变量 e 会再拷贝一份异常对象。
- **按引用捕获**：

```cpp
catch (const std::runtime_error& e) { // 捕获方式2
    // e 是对异常对象的引用，不再拷贝
}
```

- 按引用可以避免 **二次拷贝**，尤其是异常对象较大或复制成本高时推荐使用。

#### 析构函数抛异常的问题

如果析构函数抛异常，可能会导致程序在异常传播时终止（特别是在栈展开过程中已抛出异常的情况下），**建议析构函数不抛异常**。

### C++11/17 的补充说明

#### noexcept

用于声明函数不会抛异常，编译器可进行优化：

```cpp
void func() noexcept;
```

#### throw()（已弃用）

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

**RAII + 异常机制 = 安全 + 简洁 + 高效**是 C++ 最强大的组合之一。

### C++ 析构函数可以抛出异常吗

C++ 析构函数 **不应抛出异常**，因为如果析构函数在栈展开（stack unwinding）过程中抛出异常，会导致 **程序调用 `std::terminate()`** 直接终止。通常做法是在析构函数中捕获异常并处理，避免向外传播。

#### 栈展开

**栈展开（stack unwinding）**指的是：当异常抛出后，程序自动沿着调用栈回退，依次销毁（调用析构函数）已经构造的局部对象，以清理资源的过程。

- 栈展开保证异常发生时资源被清理。
- 如果析构函数在栈展开过程中再抛异常，会导致程序直接终止（`std::terminate()`）。

```cpp
#include <iostream>

struct A {
    ~A() { std::cout << "~A\n"; }
};

struct B {
    ~B() { std::cout << "~B\n"; }
};

void func() {
    A a;
    B b;
    throw std::runtime_error("error");
}

int main() {
    try {
        func();
    } catch (const std::exception& e) {
        std::cout << "Caught: " << e.what() << "\n";
    }
}
```

**执行流程**：

1. `func()` 创建了 `A a` 和 `B b`。
2. `throw` 抛出异常时，程序立即跳出 `func()`。
3. 为了保证资源不泄漏，局部对象 **按照创建顺序的逆序析构**：
   - 先调用 `B` 的析构函数 → 输出 `~B`
   - 再调用 `A` 的析构函数 → 输出 `~A`
4. 异常被 `main` 中的 `catch` 捕获 → 输出 `"Caught: error"`

这个**自动调用局部对象析构函数的过程**就是**栈展开**。

#### 析构函数抛异常可能导致程序崩溃

如果一个对象在栈展开过程中被销毁（即已经在处理另一个异常），**又有析构函数抛出异常**，那么 **C++ 会调用 `std::terminate()`，导致程序崩溃**。

```cpp
#include <iostream>
#include <stdexcept>

class A {
public:
    ~A() {
        std::cout << "A::~A()" << std::endl;
        throw std::runtime_error("Error in destructor");
    }
};

void test() {
    A a;
    throw std::runtime_error("Original exception");
}

int main() {
    try {
        test();
    } catch (const std::exception& e) {
        std::cout << "Caught: " << e.what() << std::endl;
    }
}
```

**输出：**

```txt
A::~A()
terminate called after throwing an instance of 'std::runtime_error'
```

程序终止，`catch` 根本没来得及处理。

#### 正确的做法：捕获并处理析构函数中的异常

如果析构函数中确实可能发生异常，**必须捕获并在内部处理**，**绝不能让异常传播出析构函数**：

```cpp
class A {
public:
    ~A() {
        try {
            // 可能抛异常的代码
        } catch (const std::exception& e) {
            // 记录日志或采取补救措施
        }
    }
};
```

