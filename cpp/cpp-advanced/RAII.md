## RAII

RAII（Resource Acquisition Is Initialization）是 C++ 中一项非常重要的**资源管理**思想。它是 C++ 语言设计中自动管理资源的一种惯用方法，广泛应用于标准库（如 `std::vector`, `std::unique_ptr`, `std::lock_guard`）中。

### 定义

**RAII（资源获取即初始化）**：将资源的生命周期绑定到对象的生命周期上，通过构造函数申请资源，在析构函数中释放资源。

- 资源包括：内存、文件句柄、互斥锁、网络连接等。
- 构造函数负责「获取资源」；
- 析构函数负责「释放资源」。

一旦对象离开作用域，自动调用析构函数，释放资源，**不需要手动释放**，从而避免内存泄漏、资源泄漏等问题。

### 示例

#### 简单例子

```cpp
#include <iostream>
#include <fstream>

void writeFile() {
    std::ofstream file("example.txt");  // 构造函数打开文件
    if (!file) {
        std::cerr << "Failed to open file.\n";
        return;
    }
    file << "Hello RAII!\n";
    // 作用域结束时，file 的析构函数会自动关闭文件
}
```

这里的 `std::ofstream` 就是一个典型的 RAII 对象：

- 构造时打开文件；
- 析构时自动关闭文件，无需手动 `close()`。

#### 自定义 RAII 类

```cpp
class Buffer {
    char* data;
public:
    Buffer(size_t size) {
        data = (char*)malloc(size);
        std::cout << "Allocated\n";
    }

    ~Buffer() {
        free(data);
        std::cout << "Freed\n";
    }

    char* get() const { return data; }
};
```

用法：

```cpp
void foo() {
    Buffer buf(100);  // 自动分配
    // 使用 buf.get()
} // 自动释放
```

### 优势

#### 异常安全

```cpp
void func() {
    std::lock_guard<std::mutex> lock(mtx);  // 自动加锁
    // 发生异常也能自动解锁
    riskyOperation();
} // 离开作用域时 lock 析构 -> mtx.unlock()
```

- 避免忘记 `unlock()`；
- 即使函数抛出异常，也不会导致资源泄露或死锁。

#### 代码简洁，易于维护

- 不再需要手动 `delete`、`close`；
- 减少错误（如重复释放、忘记释放）；
- 更符合 C++ 面向对象的设计思想。

### 标准库中的 RAII 示例

| 类型                          | 管理资源 | 说明                 |
| ----------------------------- | -------- | -------------------- |
| `std::vector`                 | 动态数组 | 自动申请和释放内存   |
| `std::ifstream/std::ofstream` | 文件句柄 | 自动打开/关闭文件    |
| `std::unique_ptr`             | 动态内存 | 智能指针，唯一拥有权 |
| `std::shared_ptr`             | 动态内存 | 引用计数指针         |
| `std::lock_guard`             | 互斥锁   | 自动加解锁           |

智能指针是 RAII 的典型应用：

```cpp
#include <memory>

void smart() {
    std::unique_ptr<int> p(new int(42));  // 自动释放
    // *p = 100;
} // 离开作用域，自动 delete
```

### RAII 使用建议

- 优先使用标准库 RAII 类，如智能指针、容器等；
- 避免裸 `new/delete`，除非封装成 RAII；
- 对所有资源型对象（如线程、文件、锁）尽量 RAII 化管理；
- RAII 非常适合用在异常频繁的环境中（如资源管理、文件 IO、并发等）。