## C++智能指针

**智能指针（Smart Pointer）** 是 C++ 中用于**自动管理动态内存**的一种机制，能有效避免手动 `new` / `delete` 带来的内存泄漏、重复释放、悬挂指针等问题。

### 一、什么是智能指针

智能指针本质上是一个**封装了原始指针的类模板对象**，它负责：

- 自动释放所管理的内存；
- 控制对象的所有权（谁该释放）；
- 提供与原始指针一样的操作方式（支持 `*`, `->` 等操作符）；

它是 C++ RAII（资源获取即初始化）思想的经典体现。

### 二、智能指针的三大核心类型（C++11 引入）

| 名称              | 功能简介                                  |
| ----------------- | ----------------------------------------- |
| `std::unique_ptr` | 独占所有权，不能共享                      |
| `std::shared_ptr` | 引用计数，共享所有权                      |
| `std::weak_ptr`   | 弱引用，用于观察 `shared_ptr`，不拥有资源 |

### 三、逐个详解

#### 1. `std::unique_ptr`（独占指针）推荐使用！

- 不能被拷贝，只能移动（move-only）；
- 自动释放所管理的对象；
- 非常轻量，开销小；

```cpp
#include <memory>
#include <iostream>

struct Test { Test() { std::cout << "Ctor\n"; } ~Test() { std::cout << "Dtor\n"; } };

int main() {
    std::unique_ptr<Test> ptr1 = std::make_unique<Test>();
    // std::unique_ptr<Test> ptr2 = ptr1;      // ❌ 编译错误，不能拷贝
    std::unique_ptr<Test> ptr2 = std::move(ptr1); // ✅ 移交所有权
}
```

> 使用 `std::make_unique<T>()` 是最推荐的方式。

#### 2. `std::shared_ptr`（共享指针）

- 多个 `shared_ptr` 可以共享同一个对象；
- 内部通过**引用计数（reference count）**来管理；
- 最后一个引用离开作用域时释放资源；
- 稍重一些，但适合对象在多个地方被共享使用。

```cpp
#include <memory>
#include <iostream>

struct Test { Test() { std::cout << "Ctor\n"; } ~Test() { std::cout << "Dtor\n"; } };

int main() {
    std::shared_ptr<Test> p1 = std::make_shared<Test>();
    std::shared_ptr<Test> p2 = p1;  // 引用计数 +1
    std::cout << p1.use_count() << std::endl;  // 输出 2
}
```

#### 3. `std::weak_ptr`（弱引用指针）

- 不拥有对象，只是“观察者”；
- 不会增加引用计数；
- 常用于解决 `shared_ptr` 的**循环引用（内存泄漏）**问题；
- 通过 `.lock()` 可转成 `shared_ptr` 使用。

循环引用：

```cpp
#include <iostream>
#include <memory>

struct B;  // 前向声明

struct A {
    std::shared_ptr<B> b_ptr;
    ~A() { std::cout << "A destroyed\n"; }
};

struct B {
    std::shared_ptr<A> a_ptr;
    ~B() { std::cout << "B destroyed\n"; }
};

int main() {
    auto a = std::make_shared<A>();
    auto b = std::make_shared<B>();
    a->b_ptr = b;
    b->a_ptr = a;

    // 主函数结束后 a 和 b 超出作用域，但它们互相引用
}
```

什么也不输出，`a` 和 `b` 超出了作用域，但它们的 `shared_ptr` 相互引用，引用计数都 > 0，**所以析构函数不被调用，内存泄漏！**

用 `weak_ptr` 打破环：

```cpp
struct B;  // 前向声明

struct A {
    std::shared_ptr<B> b_ptr;
    ~A() { std::cout << "A destroyed\n"; }
};

struct B {
    std::weak_ptr<A> a_ptr;  // 用 weak_ptr 防止循环引用
    ~B() { std::cout << "B destroyed\n"; }
};

int main() {
    auto a = std::make_shared<A>();
    auto b = std::make_shared<B>();
    a->b_ptr = b;
    b->a_ptr = a;  // 现在不再增加引用计数！

    // 主函数结束时，两者都能正常销毁
}
```

输出：

``` css
A destroyed
B destroyed
```

### 四、底层实现机制简述

- `unique_ptr`: 就是一个简单的所有权对象，析构时调用 `delete`；

- `shared_ptr`: 内部有一个**控制块**（Control Block），包含：

  - 原始指针；

  - 引用计数（ `use_count`）：记录有多少个 `shared_ptr` 正在共享这个对象。

  - 弱引用计数（`weak_count`）：记录有多少个 `weak_ptr` 指向该对象。

- `weak_ptr`: 指向 `shared_ptr` 的控制块，不影响引用计数。

### 五、常见陷阱和注意点

#### 1. 不要用 `shared_ptr` 管理同一指针多次

```cpp
int* raw = new int(10);
std::shared_ptr<int> p1(raw);
std::shared_ptr<int> p2(raw);  // ❌ 两个 shared_ptr 都会尝试 delete raw，导致 double free
```

正确做法：

```cpp
auto p1 = std::make_shared<int>(10);
auto p2 = p1;  // 正确共享
```

#### 2. make_shared

##### 两种写法的区别

方式一：推荐

```cpp
auto obj = std::make_shared<MyClass>();
```

方式二：传统但不推荐

```cpp
std::shared_ptr<MyClass> obj(new MyClass());
```

##### 核心差别

| 特性                               | `std::make_shared`       | `shared_ptr<T>(new T)`                             |
| ---------------------------------- | ------------------------ | -------------------------------------------------- |
| **性能**                           | ✅ 更高性能，单次内存分配 | ❌ 两次内存分配                                     |
| **异常安全**                       | ✅ 是                     | ⚠️ 可能泄漏资源（手动写 new 时）                    |
| **代码简洁**                       | ✅ 简洁、现代             | ❌ 较繁琐                                           |
| **构造时传参**                     | ✅ 支持构造函数参数转发   | ✅ 同样支持                                         |
| **使用 `enable_shared_from_this`** | ✅ 完美支持               | ✅ 也支持（只要在 shared_ptr 构造时第一次管理对象） |

##### 为什么 `make_shared` 更快

`make_shared` 的内部机制如下：

```cpp
template<typename T, typename... Args>
std::shared_ptr<T> make_shared(Args&&... args) {
    // 一次性分配控制块 + T 对象在同一块内存中
    // 控制块 + 对象 = contiguous
    return std::shared_ptr<T>(...);  // 构造优化
}
```

它会 **一次性分配一整块内存**，包括：

- 控制块（引用计数）
- `MyClass` 对象本身

两者在一起，空间局部性更好，减少堆内存碎片，也避免了两次 `malloc` 调用。

而下面这种：

```cpp
std::shared_ptr<MyClass> obj(new MyClass());
```

会发生两次分配：

1. `new MyClass()` 分配 `MyClass` 对象。
2. `shared_ptr` 分配控制块。

##### 异常安全问题

来看这个错误例子：

```cpp
std::shared_ptr<MyClass> obj(new MyClass(arg1, mayThrow()));  // ❌ 如果 mayThrow 抛异常，内存泄漏
```

- `new MyClass(...)` 先执行。
- `shared_ptr` 构造前发生异常，`new` 出来的对象泄漏！

但：

```cpp
auto obj = std::make_shared<MyClass>(arg1, mayThrow());  // ✅ 安全
```

- `make_shared` 是一个整体表达式，不会泄漏。

| 场景               | 推荐用法                                 |
| ------------------ | ---------------------------------------- |
| 一般情况下创建对象 | ✅ `std::make_shared<T>()`                |
| 需要自定义 deleter | ❌ 必须用 `shared_ptr<T>(new T, deleter)` |
| 从裸指针接管管理权 | ❌ 不推荐（更推荐用 `unique_ptr`）        |

### 六、enable_shared_from_this

`std::enable_shared_from_this` 是 C++11 引入的一个标准库模板类，用于解决 **在类的成员函数中安全地获取自身的 `shared_ptr`** 的问题。

#### 1. 背景问题

假设有一个类，其对象是通过 `std::shared_ptr` 管理的。希望在成员函数中获取指向该对象的 `shared_ptr`，可能用于：

- 把自己传给别的管理器。
- 用 `shared_ptr` 控制自己的生命周期（如异步任务中）。

可能会写：

```cpp
class MyClass {
public:
    std::shared_ptr<MyClass> getSelf() {
        return std::shared_ptr<MyClass>(this);  // ❌ 错误！
    }
};

int main() {
    std::shared_ptr<MyClass> obj = std::make_shared<MyClass>();
    std::shared_ptr<MyClass> self = obj->getSelf();  // 问题点在这
}
```

调用 `getSelf()` 时创建了 **第二个 shared_ptr**，它同样管理这个 `MyClass` 实例，但它是从 `this` 原始指针新建的，而不是共享原来的控制块。

> #### 为什么 `shared_ptr<MyClass>(this)` 不共享控制块？
>
> 在下面的例子中：
>
> ```cpp
> class MyClass {
> public:
>     std::shared_ptr<MyClass> getSelf() {
>         return std::shared_ptr<MyClass>(this);  // 问题点
>     }
> };
> ```
>
> 从 `this` 创建了一个新的 `shared_ptr`，本质上就是：
>
> ```cpp
> std::shared_ptr<MyClass> another(this);  // 相当于 new MyClass 已经执行过了，但你又 new 控制块
> ```
> 
> - `this` 是原来的对象指针，但你用它重新 new 了一个 **新的控制块**。
> - 这个新的控制块对这个对象的生命周期一无所知，它以为你刚 new 了这个对象。
> - 实际上，这个对象已经被另一个 `shared_ptr` 管理，它的引用计数是属于**另一个控制块**的。
>
> 于是现在就出现了这种情况：
> 
> | shared_ptr | 控制块 | 管理对象   | use_count |
>| ---------- | ------ | ---------- | --------- |
> | `obj`      | A      | `MyClass*` | 1         |
>| `self`     | B      | `MyClass*` | 1         |
> 
> **两者控制块完全无关**，但都尝试析构同一个对象，这就是**重复析构**的根源。

结果：

- 现在有两个 **独立的** `shared_ptr<MyClass>`：
  - `obj`：引用计数控制块 A，引用计数为 1。
  - `self`：引用计数控制块 B，引用计数也为 1。

后果：对象被 **析构两次**，程序崩溃！

当 `obj` 和 `self` 分别析构时：

1. `obj` 调用析构时释放控制块 A，删除了 `MyClass` 对象。
2. `self` 后析构，控制块 B 也尝试再删除一次这个已经删除的对象 → **二次析构！**
3. 结果可能是：
   - 程序崩溃。
   - 访问野指针。
   - 内存错误调试困难。

####  2. 正确做法：使用 `enable_shared_from_this`

```cpp
#include <iostream>
#include <memory>

class MyClass : public std::enable_shared_from_this<MyClass> {
public:
    std::shared_ptr<MyClass> getSelf() {
        return shared_from_this();  // ✅ 正确用法，返回共享控制块中的 shared_ptr
    }

    ~MyClass() {
        std::cout << "MyClass destroyed\n";
    }
};

int main() {
    std::shared_ptr<MyClass> obj = std::make_shared<MyClass>();  // ✅ 正确创建方式
    std::shared_ptr<MyClass> self = obj->getSelf();              // ✅ 正确获取自身 shared_ptr
}
```

##### 2.1 使用 `std::make_shared` 是关键第一步

```cpp
std::shared_ptr<MyClass> obj = std::make_shared<MyClass>();
```

这行代码做了两件事：

- 创建了一个新的 `MyClass` 对象；
- 创建了一个 **控制块（control block）**，用于管理引用计数；
- 把这两者打包成一个 `shared_ptr<MyClass>`。

> 控制块是“引用计数管理中心”，所有共享该对象的 `shared_ptr` 都会用这个控制块。

##### 2.2 类继承了 `enable_shared_from_this`

```cpp
class MyClass : public std::enable_shared_from_this<MyClass>
```

这个继承使得 `MyClass` 拥有了一个隐藏成员：

```cpp
std::weak_ptr<MyClass> weak_this;  // 用于记录当前对象所在的控制块
```

当你用 `make_shared` 创建对象时，`shared_ptr` 会**自动设置这个 `weak_this` 指针指向自己的控制块**。

##### 2.3 调用 `shared_from_this()` 正确提取 shared_ptr

```cpp
return shared_from_this();
```

这行代码做的是：

- 用 `weak_this.lock()` 从当前对象的控制块中提取出一个新的 `shared_ptr`。
- 这个新的 `shared_ptr` 和 `obj` 是 **共享控制块** 的，也就是共享引用计数。

所以：

```cpp
std::shared_ptr<MyClass> self = obj->getSelf();
```

这句代码里的 `self` 和 `obj` 是 **完全等价、引用计数一致** 的两个指针，引用计数从 1 变成了 2。

##### 2.4 实现细节

2.4.1 `std::enable_shared_from_this` 内部结构（简化版）

```cpp
template<typename T>
class enable_shared_from_this {
protected:
    // 注意：这是 std 库内部使用的，用户不能访问
    mutable std::weak_ptr<T> weak_this;

public:
    std::shared_ptr<T> shared_from_this() {
        return std::shared_ptr<T>(weak_this);  // 实际调用 lock()
    }

    std::shared_ptr<const T> shared_from_this() const {
        return std::shared_ptr<const T>(weak_this);  // 支持 const
    }

    // 允许 shared_ptr 在构造时设置 weak_this
    friend class std::shared_ptr<T>;
};
```

2.4.2 控制块的建立（由 `shared_ptr` 构造时完成）

当你写：

```cpp
std::shared_ptr<MyClass> obj = std::make_shared<MyClass>();
```

标准库的内部实现会自动检测出：`MyClass` 继承了 `enable_shared_from_this<MyClass>`，于是它会做一件重要的事：

```cpp
if (std::is_base_of<enable_shared_from_this<T>, T>::value) {
    // 设置 weak_this 指向当前 shared_ptr 的控制块
    obj->weak_this = obj;
}
```

也就是说在 `shared_ptr<T>` 构造时，会把 `enable_shared_from_this<T>` 里的 `weak_this` 设置成指向当前控制块的 `weak_ptr`。

> #### 更底层一点的机制（从 `shared_ptr` 源码角度）
>
> 在 C++ 的标准库实现中（如 GCC 的 libstdc++），构造 `shared_ptr<T>` 时，内部代码大致逻辑如下：
>
> ```cpp
> if constexpr (std::is_base_of_v<std::enable_shared_from_this<T>, T>) {
>     if (p->weak_this.expired()) {
>         p->weak_this = shared_ptr<T>(*this);  // 绑定控制块
>     }
> }
> ```
>
> 只有在 `T` 继承了 `enable_shared_from_this<T>`，这个弱引用才会被设置。

2.4.3 使用时：`shared_from_this()` 的效果

调用：

```cpp
this->shared_from_this();
```

等价于：

```cpp
std::shared_ptr<T> ptr = weak_this.lock();
```

这就安全地拿到了一个 **共享当前控制块的新 `shared_ptr`**。

2.4.3 如果直接用 `shared_ptr<T>(this)` 会发生什么

绕过了上面自动设置的 `weak_this = shared_ptr<T>(...)` 这一步：

```cpp
std::shared_ptr<T> getSelf() {
    return std::shared_ptr<T>(this);  // ❌ 控制块完全不同
}
```

这样会创建一个全新的控制块（引用计数系统），跟原来的毫无关系，所以就会导致两次 delete。

### 七、手写简化版 shared_ptr、weak_ptr

```cpp
#include <iostream>
#include <type_traits>

template <typename T>
class SharedPtr;

template <typename T>
class WeakPtr;

// EnableSharedFromThis 支持
template <typename T>
class EnableSharedFromThis {
private:
    mutable WeakPtr<T> weak_self; // 这里用 WeakPtr 防止循环引用

public:
    SharedPtr<T> shared_from_this() {
        return weak_self.lock(); // 从弱引用尝试生成 SharedPtr
    }
    SharedPtr<T> shared_from_this() const {
        return weak_self.lock();
    }

    template <typename U>
    friend class SharedPtr;  // SharedPtr 需要访问 weak_self
};

// 简化版 SharedPtr，实现引用计数和 enable_shared_from_this 支持
template <typename T>
class SharedPtr {
private:
    T* ptr = nullptr;           // 管理的裸指针
    int* ref_count = nullptr;   // 引用计数（强引用计数）
    int* weak_count = nullptr;  // 弱引用计数，初次使用时分配

    void enableSharedFromThisIfNeeded(T* p) {
        if constexpr (std::is_base_of<EnableSharedFromThis<T>, T>::value) {
            // 让被管理对象内部 weak_self 指向当前 SharedPtr
            p->weak_self = WeakPtr<T>(*this);
        }
    }

public:
    // 赋值nullptr操作符重载，支持 sp = nullptr;
    SharedPtr<T>& operator=(std::nullptr_t) {
        release();
        ptr = nullptr;
        ref_count = nullptr;
        weak_count = nullptr;
        return *this;
    }

    explicit SharedPtr(T* p = nullptr) : ptr(p), ref_count(nullptr), weak_count(nullptr) {
        if (p) {
            ref_count = new int(1);   // 新资源，强引用计数为1
            weak_count = new int(1);  // 弱引用计数为1（至少一个强引用）
            enableSharedFromThisIfNeeded(p);
        }
    }

    // 拷贝构造函数：引用计数都+1
    SharedPtr(const SharedPtr<T>& other) : ptr(other.ptr), ref_count(other.ref_count), weak_count(other.weak_count) {
        if (ref_count) ++(*ref_count);
        if (weak_count) ++(*weak_count);
        if (ptr) enableSharedFromThisIfNeeded(ptr);
    }

    // 从 WeakPtr 升级构造 SharedPtr（lock 操作）
    explicit SharedPtr(const WeakPtr<T>& weak) {
        ptr = nullptr;
        ref_count = nullptr;
        weak_count = nullptr;
        if (weak.expired()) {
            // 对象已销毁，构造空 SharedPtr
            return;
        }
        ptr = weak.ptr;
        ref_count = weak.ref_count;
        weak_count = weak.weak_count;
        ++(*ref_count);
        ++(*weak_count);
        if (ptr) enableSharedFromThisIfNeeded(ptr);
    }

    // 拷贝赋值
    SharedPtr<T>& operator=(const SharedPtr<T>& other) {
        if (this != &other) {
            release();
            ptr = other.ptr;
            ref_count = other.ref_count;
            weak_count = other.weak_count;
            if (ref_count) ++(*ref_count);
            if (weak_count) ++(*weak_count);
            if (ptr) enableSharedFromThisIfNeeded(ptr);
        }
        return *this;
    }

    ~SharedPtr() {
        release();
    }

    T& operator*() const { return *ptr; }
    T* operator->() const { return ptr; }
    int use_count() const { return ref_count ? *ref_count : 0; }
    bool unique() const { return use_count() == 1; }
    explicit operator bool() const { return ptr != nullptr; }

private:
    void release() {
        if (ref_count) {
            --(*ref_count);
            if (*ref_count == 0) {
                delete ptr;
                ptr = nullptr;

                // 强引用计数为0，弱引用计数也减1
                --(*weak_count);
                if (*weak_count == 0) {
                    delete ref_count;
                    delete weak_count;
                    ref_count = nullptr;
                    weak_count = nullptr;
                }
            }
            else {
                ptr = nullptr;
                ref_count = nullptr;
                weak_count = nullptr;
            }
        }
    }

    template <typename U>
    friend class WeakPtr;
};

// WeakPtr 实现，弱引用管理，不拥有对象，引用计数独立
template <typename T>
class WeakPtr {
private:
    T* ptr = nullptr;           // 指向对象（非拥有）
    int* ref_count = nullptr;   // 指向强引用计数
    int* weak_count = nullptr;  // 指向弱引用计数

public:
    WeakPtr() = default;

    // 由 SharedPtr 构造 WeakPtr，增加弱引用计数
    WeakPtr(const SharedPtr<T>& shared) : ptr(shared.ptr), ref_count(shared.ref_count), weak_count(shared.weak_count) {
        if (weak_count) ++(*weak_count);
    }

    // 拷贝构造，弱引用计数加1
    WeakPtr(const WeakPtr<T>& other) : ptr(other.ptr), ref_count(other.ref_count), weak_count(other.weak_count) {
        if (weak_count) ++(*weak_count);
    }

    // 拷贝赋值，正确管理引用计数
    WeakPtr<T>& operator=(const WeakPtr<T>& other) {
        if (this != &other) {
            release();
            ptr = other.ptr;
            ref_count = other.ref_count;
            weak_count = other.weak_count;
            if (weak_count) ++(*weak_count);
        }
        return *this;
    }

    ~WeakPtr() {
        release();
    }

    // 检查对象是否已经被销毁（强引用计数为0即销毁）
    bool expired() const {
        return !ref_count || *ref_count == 0;
    }

    // 尝试获得 SharedPtr（如果对象仍然存在）
    SharedPtr<T> lock() const {
        if (expired()) {
            return SharedPtr<T>(); // 返回空的 SharedPtr
        }
        return SharedPtr<T>(*this); // 使用 SharedPtr 的 WeakPtr 构造函数
    }

private:
    void release() {
        if (weak_count) {
            --(*weak_count);
            if (*weak_count == 0) {
                // 所有弱引用和强引用都释放，删除引用计数指针
                delete ref_count;
                delete weak_count;
            }
            ptr = nullptr;
            ref_count = nullptr;
            weak_count = nullptr;
        }
    }

    template <typename U>
    friend class SharedPtr;
};

```

#### 核心实现原理

##### 1. SharedPtr

- 管理一块动态分配的对象，通过 **引用计数** 机制控制生命周期。
- 维护三个指针：
  - `ptr`：裸指针，指向对象。
  - `ref_count`：指向整数，管理强引用计数（`SharedPtr` 的数量）。
  - `weak_count`：指向整数，管理弱引用计数（`WeakPtr` 的数量 + 强引用的数量，参考下文）。
- 构造时，如果传入裸指针，则创建新的计数，初始时 `ref_count = 1`，`weak_count = 1`。
- 拷贝构造/赋值时，计数器增加。
- 析构或赋值丢弃旧对象时，减少计数器，当强引用计数降到 0 时删除托管对象，同时减少弱引用计数。
- 当弱引用计数降到 0 时，释放计数器内存。
- 支持从 `WeakPtr` 构造（升级锁定），失败时得到空指针。
- 实现了 `operator*`、`operator->` 访问对象。
- 支持赋值 `nullptr` 来重置指针。
- **关键点**：当托管对象继承了 `EnableSharedFromThis`，会调用 `enableSharedFromThisIfNeeded`，设置对象内部 `weak_self` 指向自身的 `WeakPtr`，实现 `shared_from_this()`。

------

##### 2. WeakPtr

- **弱引用**，不拥有对象，不影响对象生命周期。
- 维护裸指针和两个计数指针（和 `SharedPtr` 共享同一组计数器）。
- 构造时会增加弱引用计数，析构时减少。
- 可用 `expired()` 判断对象是否已经被销毁（即强引用计数为 0）。
- `lock()` 尝试返回一个 `SharedPtr`，如果对象没销毁，则引用计数加 1，返回有效的智能指针；否则返回空指针。
- 通过共享计数机制，实现了弱引用观察生命周期的功能。

------

##### 3. EnableSharedFromThis

- 设计为基类，供用户继承，实现从对象内部安全地获取自身的 `SharedPtr`。
- 内部维护一个 `WeakPtr<T> weak_self`，指向自身。
- `shared_from_this()` 返回从 `weak_self.lock()` 获得的 `SharedPtr`。
- 只有在 `SharedPtr` 构造时，检测到对象继承了该基类，才会自动把 `weak_self` 绑定到当前智能指针。

#### 使用示例

```cpp
#include <iostream>

// 之前给的 SharedPtr, WeakPtr, EnableSharedFromThis 代码放在这里，或者包含头文件

class MyClass : public EnableSharedFromThis<MyClass> {
public:
    void hello() {
        std::cout << "Hello from MyClass\n";
    }

    void testSharedFromThis() {
        // 从对象内部获取自己的 SharedPtr
        auto sp = shared_from_this();
        std::cout << "use_count from shared_from_this: " << sp.use_count() << std::endl;
    }

    ~MyClass() {
        std::cout << "MyClass destructor called\n";
    }
};

int main() {
    // 创建 SharedPtr 管理 MyClass 对象，此时强引用计数为 1，弱引用计数为 1（至少一条强引用）
    SharedPtr<MyClass> sp1(new MyClass());
    sp1->hello(); // 调用对象方法，输出一条消息

    // 调用成员函数，内部通过 shared_from_this() 获得一个新的 SharedPtr（sp），此时强引用计数临时变为 2
    sp1->testSharedFromThis(); 
    // testSharedFromThis() 执行完毕后，sp 离开作用域，被析构，强引用计数回到 1

    // 使用 sp1 创建一个 WeakPtr，不增加强引用计数，只增加弱引用计数
    WeakPtr<MyClass> wp = sp1;

    // 打印当前强引用计数：仍为 1，因为 testSharedFromThis 中的 sp 已经销毁
    std::cout << "Use count after WeakPtr creation: " << sp1.use_count() << std::endl;

    {
        // 使用 WeakPtr 尝试 lock 成为 SharedPtr（sp2），如果对象仍存在则成功
        SharedPtr<MyClass> sp2 = wp.lock();
        if (sp2) {
            // lock 成功，引用计数变为 2
            std::cout << "Locked from WeakPtr, use_count: " << sp2.use_count() << std::endl;
        } else {
            std::cout << "Failed to lock from WeakPtr, object expired\n";
        }
    } // sp2 出作用域并被析构，引用计数减回 1

    // 显式将 sp1 置空，相当于释放最后一个 SharedPtr，销毁管理的对象
    sp1 = nullptr;

    // 此时强引用计数为 0，对象已销毁，WeakPtr 仍存在但 expired() 返回 true
    if (wp.expired()) {
        std::cout << "WeakPtr detects object is expired\n";
    } else {
        std::cout << "WeakPtr still valid\n";
    }

    // 再次尝试 lock 已经 expired 的 WeakPtr，返回空 SharedPtr
    SharedPtr<MyClass> sp3 = wp.lock();
    if (!sp3) {
        std::cout << "Lock failed, object already destroyed\n";
    }

    return 0;
}
```

运行输出示例：

```txt
Hello from MyClass
use_count from shared_from_this: 2
Use count after WeakPtr creation: 1
Locked from WeakPtr, use_count: 2
MyClass destructor called
WeakPtr detects object is expired
Lock failed, object already destroyed
```

