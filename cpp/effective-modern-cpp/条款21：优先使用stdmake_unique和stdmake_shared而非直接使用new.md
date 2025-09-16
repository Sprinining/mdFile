## 条款21：优先使用 std::make_unique 和 std::make_shared 而非直接使用 new

### 背景与引入

- `std::make_shared` 从 C++11 标准开始提供。
- `std::make_unique` 从 C++14 标准开始提供，C++11 中可自定义实现。
- 这两个“make函数”接收任意参数，完美转发给对象构造函数，返回智能指针。

### 使用 make 函数的主要优点

#### 避免代码重复

直接使用 `new` 时需重复写类型，如：

```cpp
std::shared_ptr<Widget> spw(new Widget);
```

使用 `make_shared` 只需写一次类型：

```cpp
auto spw = std::make_shared<Widget>();
```

减少重复代码，降低 bug 风险，提高代码简洁性。

#### 提高异常安全性

直接用 `new` 和传递多个参数时，编译器对参数求值顺序不定，可能导致资源泄漏：

```cpp
processWidget(std::shared_ptr<Widget>(new Widget), computePriority());
```

这行代码里有两个函数参数：

1. `std::shared_ptr<Widget>(new Widget)`：创建一个智能指针，管理 `new` 出来的对象
2. `computePriority()`：计算一个整数优先级

**问题来了：C++ 中函数参数的求值顺序是未定义的！**

这意味着编译器可能按任意顺序计算这两个参数，比如：

- 先执行 `new Widget`
- 然后执行 `computePriority()`
- 最后调用 `std::shared_ptr<Widget>` 构造函数

那如果 `computePriority()` 抛异常呢？

- `new Widget` 已经分配了内存（堆上创建了对象）
- 但 `std::shared_ptr` 还没来得及拿到这个指针去“托管”
- 结果就是这个指针永远没人管了 → **内存泄漏！**

`std::make_shared` 保证分配和智能指针构造是原子操作，避免泄漏：

```cpp
processWidget(std::make_shared<Widget>(), computePriority());
```

#### 性能优化（仅限 `std::make_shared`）

- 直接 `shared_ptr` 使用 `new` 会分别分配对象内存和控制块内存，两次堆分配。
- `std::make_shared` 一次分配内存，包含对象和控制块，减少分配次数，提高速度，降低内存开销。

### 不能或不应使用 make 函数的情况

#### 需要自定义删除器时

- `make_unique` 和 `make_shared` 不支持指定自定义删除器。

- 只能通过直接使用 `new` 并传递删除器构造智能指针：

```cpp
std::unique_ptr<Widget, decltype(deleter)> upw(new Widget, deleter);
std::shared_ptr<Widget> spw(new Widget, deleter);
```

#### 需要使用花括号初始化

- `make_shared` 和 `make_unique` 参数完美转发时用的是小括号初始化，不能直接完美转发花括号初始化（`std::initializer_list`）。
- 若要使用花括号初始化，需要先用 `auto initList = { ... };` 初始化 `initializer_list`，再传递给 make 函数。

##### 举例

想创建一个 `std::vector<int>`，希望它包含两个元素 10 和 20，用花括号初始化：

```cpp
std::vector<int> v{10, 20};  // 正确，用 initializer_list 构造
```

可能想这样用 `make_shared` 创建它：

```cpp
auto sp = std::make_shared<std::vector<int>>({10, 20});  // 不行！
```

这并不会调用 `std::initializer_list` 的构造函数，而是会被解释成两个独立参数（编译失败或构造错误对象）。因为 `make_shared` 是模板函数，它用**完美转发**把参数传给构造函数，但完美转发时参数是用**小括号 `( )`** 包装的，不能处理花括号 `{}` 的 initializer list。

> **花括号初始化无法被完美转发**，是 C++ 的一个限制。

##### 正确的做法

先用 `auto` 创建一个 `initializer_list`，再传给 `make_shared`：

```cpp
auto initList = {10, 20};
auto sp = std::make_shared<std::vector<int>>(initList);
```

这样就明确告诉编译器：“我要用 initializer_list 构造函数。”

#### 类重载了 operator new / operator delete

- 这类类可能有特殊内存管理需求，不适合 `make_shared`。
- 因为 `make_shared` 需要分配比对象大得多的内存（包含控制块），与重载的内存管理冲突。

##### 正常用 new 的对象

```cpp
struct Widget {
    Widget() { std::cout << "construct\n"; }
    ~Widget() { std::cout << "destruct\n"; }
};

std::shared_ptr<Widget> sp(new Widget);
```

- 只为 `Widget` 分配一块内存。
- 控制块（引用计数信息）单独再分配一块内存。
- 没有冲突，没问题。

##### 用 make_shared

```cpp
auto sp = std::make_shared<Widget>();
```

- `make_shared` 优化了性能：它会分配“一大块内存”，**把控制块和 Widget 一起放进去**。
- 只分配一次，提高性能。

##### 问题来了：类重载了 operator new

```cpp
struct MyObj {
    void* operator new(std::size_t sz) {
        std::cout << "Custom new for size " << sz << '\n';
        return ::operator new(sz);
    }
};
```

这类类可能只允许分配精确大小（比如 `sizeof(MyObj)`）的内存，不接受“比对象大得多”的内存块。

> 但 `make_shared` 就是干这个事的！它要分配“对象 + 控制块”一大块内存，这就**和自定义的 `operator new` 冲突了**。

结果可能是：

- 自定义的 `operator new` 抛异常（拒绝大内存）
- 或者行为不符合预期（对象地址不对、性能异常等）

##### 为啥冲突了

`std::make_shared<T>()` 会调用类似下面的逻辑（内部实现大致结构）：

```cpp
// 伪代码：简化逻辑
void* rawMemory = ::operator new(sizeof(T) + sizeof(ControlBlock));
T* obj = new (rawMemory) T(...);  // 定位 new，构造对象在预分配内存中
```

- `make_shared` **不是直接用 `T::operator new` 分配内存**！
- 它分配一块内存，自己安排对象和控制块的位置，然后手动在那块内存中**构造对象**（placement new）。

换句话说：它绕开了类自己定义的 `operator new`，**不调用也不尊重**你的重载逻辑！

当你这么写：

```cpp
struct MyObj {
    void* operator new(size_t size) {
        std::cout << "自定义 new，size = " << size << "\n";
        return ::operator new(size);
    }
};
```

你是在告诉编译器：

> **“凡是 new MyObj 的时候，必须经过我定制的分配逻辑！”**

你可能做了很多事：

- 从对象池里分配内存
- 对齐优化
- 限制只分配 `sizeof(MyObj)` 大小
- 加日志、调试标记
- 向外部内存管理系统登记

这些逻辑默认都**不会被 `make_shared` 调用**！

##### 冲突的本质

`make_shared` 直接用 `::operator new` 分配原始内存，然后绕开你的 `operator new` 自己构造对象。 你想控制对象如何被 new，结果 `make_shared` 根本不让你插手。

#### 关注内存释放时机，特别是大对象

##### 控制块的释放规则

- 当强引用计数 = 0 时
  - 被管理的对象（`T`）会被销毁（调用析构函数 + 释放内存）。
  - 但此时控制块**不一定释放**，因为可能还有 `weak_ptr` 在用它。
- 当强引用计数 = 0 且弱引用计数 = 0 时
  - 控制块本身才会被释放。

##### std::make_shared\<T>(...)

- **一次性分配一整块内存**：包含**控制块**和**对象 T**。
- 当最后一个 `shared_ptr` 销毁时：对象析构，但控制块可能继续存在。
- 内存（控制块 + 对象）要等**最后一个 `weak_ptr` 销毁**时才真正释放。

优点：更高效（一次分配），缓存局部性更好。
缺点：如果对象很大，而仍有 `weak_ptr` 存活，会延迟整块内存的释放。

##### std::shared_ptr\<T>(new T)

- **两次分配内存**：
  1. `new T` → 对象的内存
  2. 控制块单独分配
- 当最后一个 `shared_ptr` 销毁时：
  - 对象内存**立即释放**
  - 控制块仍然存活，直到最后一个 `weak_ptr` 销毁才释放。

优点：对象内存可以更早释放（即使还有 `weak_ptr`）。
缺点：分配次数多一次，性能略低，局部性差。

### 异常安全情况下的写法建议

- 不用 `make_shared`，直接用 `new` 传递给智能指针时，建议分两步：

  ```cpp
  std::shared_ptr<Widget> spw(new Widget, cusDel);
  processWidget(std::move(spw), computePriority());
  ```

- 这样确保 `new` 与智能指针构造在一条语句中，避免异常泄漏。

- 使用 `std::move` 传递智能指针以避免不必要的引用计数递增。

### 总结

| 优点               | 说明                                                        |
| ------------------ | ----------------------------------------------------------- |
| 代码简洁           | 避免重复写类型，减少出错                                    |
| 异常安全           | 避免参数求值顺序导致的资源泄漏                              |
| 性能提升（shared） | `make_shared` 一次内存分配，比直接 `new` + `shared_ptr`更快 |

| 限制和特殊情况        | 说明                                                         |
| --------------------- | ------------------------------------------------------------ |
| 自定义删除器          | 需要直接 `new` + 智能指针构造                                |
| 花括号初始化          | 不能直接通过 `make` 完美转发花括号初始化，需特殊处理         |
| 重载了 `operator new` | 可能与 `make_shared` 内存管理冲突                            |
| 大对象延迟释放        | `make_shared` 对象和控制块内存绑定，弱引用存在时内存延迟释放 |

如果没有特殊需求，**推荐优先使用 `std::make_unique` 和 `std::make_shared` 来创建智能指针，提升代码质量和安全性。**