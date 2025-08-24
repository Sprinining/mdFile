## C++ 回调函数

C++ 中的**回调函数（Callback Function）**是一种**把函数当作参数传递给另一个函数，并在特定时机调用它**的机制。

```cpp
#include <iostream>

void onEvent() {
    std::cout << "Event triggered!" << std::endl;
}

// 回调接受者
void doSomething(void (*callback)()) {
    std::cout << "Doing something...\n";
    callback();  // 调用回调
}

int main() {
    doSomething(onEvent);  // 把函数传进去作为回调
    return 0;
}
```

### 现代写法

Lambda + std::function：

```cpp
#include <iostream>
#include <functional>

void doSomething(std::function<void()> callback) {
    std::cout << "Doing something...\n";
    callback();  // 调用回调
}

int main() {
    doSomething([]() {
        std::cout << "Lambda callback triggered!" << std::endl;
    });
    return 0;
}
```

这里的 `std::function<void()>` 可以接收：

- 函数指针
- lambda 表达式
- 函数对象（只要重载了 `operator()`）

### 为什么需要回调函数

1. **解耦通用流程与个性逻辑**
   - 库/框架实现固定流程（如排序、事件循环）。
   - 用户只需提供某些细节（如比较规则、点击响应）。
2. **提高代码复用性**
   - 公共逻辑由框架统一实现，避免每个人都重复写一遍。
   - 回调只负责变化部分，使库保持通用。
3. **事件驱动与异步处理**
   - 程序在特定事件发生时（如按钮点击、网络数据到达）再执行用户逻辑。
   - 回调让框架能在合适的时机调用用户代码。
4. **控制反转（IoC）**
   - 正常情况是“我调用库”，而回调让“库反过来调用我”。
   - 这样用户只需填空，而不用关心完整控制流程。

### 为什么普通成员函数不能直接作为回调

1. **成员函数有隐含的 this 指针**
   - 普通成员函数的真实签名不是 `void f()`，而是 `void f(MyClass* this)`。
   - 当库要求回调函数类型是 `void (*)(int)` 这样的 **普通函数指针** 时，成员函数因为额外的 `this` 参数不匹配。
2. **函数指针类型不兼容**
   - 普通函数指针：`void(*)(int)`
   - 成员函数指针：`void (MyClass::*)(int)`
   - 两者在底层表示和调用方式上完全不同，不能混用。

如何解决？

1. **用静态成员函数 / 普通函数**
   - 静态成员函数没有 `this`，签名和普通函数一样，可以直接作为回调。
2. **用函数对象 / lambda**
   - C++11 之后，可以用 `std::function` + lambda 捕获对象，然后传给需要回调的地方。
3. **库本身支持成员函数绑定**
   - 比如 Qt 的 signal/slot，Boost.Asio 的 `std::bind`，都解决了 this 绑定问题。

### 常见应用场景

#### 排序函数

**C 标准库 `qsort`**：排序流程由库实现，但比较规则交给用户回调。

```cpp
int cmp(const void* a, const void* b) {
    return (*(int*)a - *(int*)b);
}
qsort(arr, n, sizeof(int), cmp);
```

#### GUI 编程

按钮点击、窗口关闭等事件，本身由系统检测，但响应逻辑由用户定义。

```cpp
button.onClick([](){ std::cout << "Button clicked!\n"; });
```

#### 异步 I/O / 网络编程

网络库（如 libevent、Boost.Asio）负责事件循环，用户只写收到数据时的处理函数。

```cpp
socket.async_read(buffer, handler); // handler 是回调
```

#### 多线程

`pthread_create` 需要用户传递一个函数指针作为线程入口。

```cpp
void* worker(void* arg) { /* 线程执行体 */ }
pthread_create(&tid, NULL, worker, NULL);
```

#### 算法框架

STL 里的 `for_each`、`transform` 接受函数对象/回调，用于对容器元素做用户自定义操作。

```cpp
std::for_each(v.begin(), v.end(), [](int x){ std::cout << x << "\n"; });
```