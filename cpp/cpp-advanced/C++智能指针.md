## C++ 智能指针

智能指针（Smart Pointer）是 C++ 提供的一种用于**自动管理动态分配内存**的工具，能够在对象生命周期结束时自动释放资源，从而减少内存泄漏、重复释放和悬挂指针等问题。该机制从 C++11 开始引入标准库。

智能指针本质上是一个**封装了原始指针的类模板对象**，它负责：

- 自动释放所管理的内存；
- 控制对象的所有权（谁该释放）；
- 提供与原始指针一样的操作方式（支持 `*`, `->` 等操作符）；

它是 C++ RAII（资源获取即初始化）思想的经典体现。

| 名称                          | 功能简介                                  |
| ----------------------------- | ----------------------------------------- |
| `std::unique_ptr`（独占指针） | 独占所有权，不能共享                      |
| `std::shared_ptr`（共享指针） | 引用计数，共享所有权                      |
| `std::weak_ptr`（弱引用指针） | 弱引用，用于观察 `shared_ptr`，不拥有资源 |

### std::unique_ptr

```cpp
#include <memory>
#include <iostream>

struct Test { Test() { std::cout << "Ctor\n"; } ~Test() { std::cout << "Dtor\n"; } };

int main() {
    std::unique_ptr<Test> ptr1 = std::make_unique<Test>();
    // std::unique_ptr<Test> ptr2 = ptr1;      // 编译错误，不能拷贝
    std::unique_ptr<Test> ptr2 = std::move(ptr1); // 移交所有权
}
```

- 不能被拷贝，只能移动（move-only）；
- 自动释放所管理的对象；
- 非常轻量，开销小；
- `std::move` 的本质是**类型转换**：把左值转换成对应的右值引用。它本身并不移动资源，只是让编译器允许移动语义发生。

### std::shared_ptr

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

- 多个 `shared_ptr` 可以共享同一个对象；
- 内部通过**引用计数（reference count）**来管理；
- 最后一个引用离开作用域时释放资源；
- 稍重一些，但适合对象在多个地方被共享使用。

### std::weak_ptr

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

### 底层实现机制

- `unique_ptr`: 就是一个简单的所有权对象，析构时调用 `delete`；

- `shared_ptr`: 内部有一个**控制块**（Control Block），包含：

  - 原始指针；

  - 引用计数（ `use_count`）：记录有多少个 `shared_ptr` 正在共享这个对象。

  - 弱引用计数（`weak_count`）：记录有多少个 `weak_ptr` 指向该对象。

- `weak_ptr`: 指向 `shared_ptr` 的控制块，不影响引用计数。

### 注意点

#### 不要用 `shared_ptr` 管理同一指针多次

```cpp
int* raw = new int(10);
std::shared_ptr<int> p1(raw);
std::shared_ptr<int> p2(raw);  // 两个 shared_ptr 都会尝试 delete raw，导致 double free
```

正确做法：

```cpp
auto p1 = std::make_shared<int>(10);
auto p2 = p1;  // 正确共享
```

#### make_shared

##### 两种写法

方式一：推荐

```cpp
auto obj = std::make_shared<MyClass>();
```

方式二：传统但不推荐

```cpp
std::shared_ptr<MyClass> obj(new MyClass());
```

##### 核心差别

| 特性                               | `std::make_shared`     | `shared_ptr<T>(new T)`                           |
| ---------------------------------- | ---------------------- | ------------------------------------------------ |
| **性能**                           | 更高性能，单次内存分配 | 两次内存分配                                     |
| **异常安全**                       | 是                     | 可能泄漏资源（手动写 new 时）                    |
| **代码简洁**                       | 简洁、现代             | 较繁琐                                           |
| **构造时传参**                     | 支持构造函数参数转发   | 同样支持                                         |
| **使用 `enable_shared_from_this`** | 完美支持               | 也支持（只要在 shared_ptr 构造时第一次管理对象） |

##### 为什么 make_shared 更快

`make_shared` 的内部机制如下：

```cpp
template<typename T, typename... Args>
std::shared_ptr<T> make_shared(Args&&... args) {
    // 一次性分配控制块 + T 对象在同一块内存中
    // 控制块 + 对象 = contiguous
    return std::shared_ptr<T>(...);  // 构造优化
}
```

它会**一次性分配一整块内存**，包括：

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
std::shared_ptr<MyClass> obj(new MyClass(arg1, mayThrow()));  // 如果 mayThrow 抛异常，内存泄漏
```

- `new MyClass(...)` 先执行。
- `shared_ptr` 构造前发生异常，`new` 出来的对象泄漏！

但：

```cpp
auto obj = std::make_shared<MyClass>(arg1, mayThrow());  // 安全
```

- `make_shared` 是一个整体表达式，不会泄漏。

| 场景               | 推荐用法                               |
| ------------------ | -------------------------------------- |
| 一般情况下创建对象 | `std::make_shared<T>()`                |
| 需要自定义 deleter | 必须用 `shared_ptr<T>(new T, deleter)` |
| 从裸指针接管管理权 | 不推荐（更推荐用 `unique_ptr`）        |

### enable_shared_from_this

`std::enable_shared_from_this` 是 C++11 引入的一个标准库模板类，用于解决**在类的成员函数中安全地获取自身的 `shared_ptr`** 的问题。

#### 背景问题

假设有一个类，其对象是通过 `std::shared_ptr` 管理的。希望在成员函数中获取指向该对象的 `shared_ptr`，可能用于：

- 把自己传给别的管理器。
- 用 `shared_ptr` 控制自己的生命周期（如异步任务中）。

可能会写：

```cpp
class MyClass {
public:
    std::shared_ptr<MyClass> getSelf() {
        return std::shared_ptr<MyClass>(this);  // 错误！
    }
};

int main() {
    std::shared_ptr<MyClass> obj = std::make_shared<MyClass>();
    std::shared_ptr<MyClass> self = obj->getSelf();  // 问题点在这
}
```

调用 `getSelf()` 时创建了**第二个 shared_ptr**，它同样管理这个 `MyClass` 实例，但它是从 `this` 原始指针新建的，而不是共享原来的控制块。

#### 为什么 shared_ptr\<MyClass>(this) 不共享控制块

从 `this` 创建了一个新的 `shared_ptr`，本质上就是：

```cpp
std::shared_ptr<MyClass> another(this);  // 相当于 new MyClass 已经执行过了，但又 new 控制块
```

- `this` 是原来的对象指针，但用它重新 new 了一个**新的控制块**。
- 这个新的控制块对这个对象的生命周期一无所知，它以为刚 new 了这个对象。
- 实际上，这个对象已经被另一个 `shared_ptr` 管理，它的引用计数是属于**另一个控制块**的。

于是现在就出现了这种情况：

| shared_ptr | 控制块 | 管理对象   | use_count |
| ---------- | ------ | ---------- | --------- |
| `obj`      | A      | `MyClass*` | 1         |
| `self`     | B      | `MyClass*` | 1         |

**两者控制块完全无关**，但都尝试析构同一个对象，这就是**重复析构**的根源。

当 `obj` 和 `self` 分别析构时：

1. `obj` 调用析构时释放控制块 A，删除了 `MyClass` 对象。
2. `self` 后析构，控制块 B 也尝试再删除一次这个已经删除的对象 → **二次析构！**
3. 结果可能是：
   - 程序崩溃。
   - 访问野指针。
   - 内存错误调试困难。

####  正确做法

```cpp
#include <iostream>
#include <memory>

class MyClass : public std::enable_shared_from_this<MyClass> {
public:
    std::shared_ptr<MyClass> getSelf() {
        return shared_from_this();  // 正确用法，返回共享控制块中的 shared_ptr
    }

    ~MyClass() {
        std::cout << "MyClass destroyed\n";
    }
};

int main() {
    std::shared_ptr<MyClass> obj = std::make_shared<MyClass>();  // 正确创建方式
    std::shared_ptr<MyClass> self = obj->getSelf();              // 正确获取自身 shared_ptr
}
```

##### 使用 std::make_shared 是关键第一步

```cpp
std::shared_ptr<MyClass> obj = std::make_shared<MyClass>();
```

这行代码做了两件事：

- 创建了一个新的 `MyClass` 对象；
- 创建了一个**控制块（control block）**，用于管理引用计数；
- 把这两者打包成一个 `shared_ptr<MyClass>`。

> 控制块是“引用计数管理中心”，所有共享该对象的 `shared_ptr` 都会用这个控制块。

##### 类继承了 enable_shared_from_this

```cpp
class MyClass : public std::enable_shared_from_this<MyClass>
```

这个继承使得 `MyClass` 拥有了一个隐藏成员：

```cpp
std::weak_ptr<MyClass> weak_this;  // 用于记录当前对象所在的控制块
```

当用 `make_shared` 创建对象时，`shared_ptr` 会**自动设置这个 `weak_this` 指针指向自己的控制块**。

##### 调用 shared_from_this() 正确提取 shared_ptr

```cpp
return shared_from_this();
```

这行代码做的是：

- 用 `weak_this.lock()` 从当前对象的控制块中提取出一个新的 `shared_ptr`。
- 这个新的 `shared_ptr` 和 `obj` 是**共享控制块**的，也就是共享引用计数。

所以：

```cpp
std::shared_ptr<MyClass> self = obj->getSelf();
```

这句代码里的 `self` 和 `obj` 是**完全等价、引用计数一致**的两个指针，引用计数从 1 变成了 2。

##### 实现细节

`std::enable_shared_from_this` 内部结构（简化版）

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

控制块的建立（由 `shared_ptr` 构造时完成）

当写：

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

调用：

```cpp
this->shared_from_this();
```

等价于：

```cpp
std::shared_ptr<T> ptr = weak_this.lock();
```

这就安全地拿到了一个**共享当前控制块的新 `shared_ptr`**。

如果直接用 `shared_ptr<T>(this)` 会绕过上面自动设置的 `weak_this = shared_ptr<T>(...)` 这一步：

```cpp
std::shared_ptr<T> getSelf() {
    return std::shared_ptr<T>(this);  // 控制块完全不同
}
```

这样会创建一个全新的控制块（引用计数系统），跟原来的毫无关系，所以就会导致两次 delete。

### 共享指针和动态数组

- <<C++ Primer>> 12.2.1

#### 共享指针默认不能管理数组（delete[] 问题）

错误示例：会导致未定义行为

```cpp
#include <iostream>
#include <memory>

int main() {
    std::shared_ptr<int> sp(new int[3]{1, 2, 3}); // 用 delete 释放 new[]
    
    // 访问内容（虽然可以访问，但释放时会出错）
    std::cout << sp.get()[0] << ", " << sp.get()[1] << ", " << sp.get()[2] << std::endl;

    // 离开作用域时 sp 调用 delete 而不是 delete[]，造成 UB
    return 0;
}
```

正确示例：用自定义删除器管理数组

```cpp
#include <iostream>
#include <memory>

int main() {
    std::shared_ptr<int> sp(new int[3]{1, 2, 3}, [](int* p){ delete[] p; }); // 正确的删除器

    std::cout << sp.get()[0] << ", " << sp.get()[1] << ", " << sp.get()[2] << std::endl;

    return 0; // 离开作用域时调用 delete[]，安全释放
}
```

- 在 C++11 ~ C++17 中，`std::shared_ptr` 默认使用 **单对象删除器 `delete`**。
- 如果用它管理数组，需要显式指定删除器 `delete[]`，否则会**未定义行为**。
- C++20 引入了**对数组类型的 `std::shared_ptr<T[]>` 特化**：
  - 内部自动使用 `delete[]` 释放数组。
  - 不再需要手动提供自定义删除器。

#### 共享指针不提供 operator[]

错误示例：直接 `sp[1]` 无法编译

```cpp
#include <iostream>
#include <memory>

int main() {
    std::shared_ptr<int> sp(new int[3]{10, 20, 30}, [](int* p){ delete[] p; });

    // std::cout << sp[1] << std::endl; // 编译错误：no operator[] defined

    return 0;
}
```

正确示例：通过 `get()` 获取裸指针后访问

```cpp
#include <iostream>
#include <memory>

int main() {
    std::shared_ptr<int> sp(new int[3]{10, 20, 30}, [](int* p){ delete[] p; });

    int* raw = sp.get(); // 返回裸指针
    std::cout << raw[1] << std::endl; // 正确访问

    return 0;
}
```

- 在 C++20 之前，`shared_ptr<T[]>` 只能通过 `.get()` 拿到原始指针，再下标访问。

- C++20 起，`shared_ptr<T[]>` **直接支持 `operator[]`**：

  ```cpp
  sp[0] = 1;
  sp[1] = 2;
  ```

- `std::unique_ptr<int[]> up(new int[10]);` **从一开始（C++11起）就支持下标访问 `operator[]`**，这是 `unique_ptr` 对数组的专门偏特化版本的设计初衷。

#### 像数组一样的共享指针

可以自己封装一个类：

```cpp
#include <iostream>
#include <memory>  // std::shared_ptr

// 自定义共享数组模板类
template<typename T>
class shared_array {
public:
    // 构造函数：创建指定大小的数组
    shared_array(size_t size)
        : size_(size),  // 保存数组长度
          // 使用 std::shared_ptr 管理动态数组
          // 自定义删除器确保使用 delete[] 正确释放内存
          ptr_(std::shared_ptr<T>(new T[size], [](T* p){ delete[] p; })) 
    {}

    // 下标访问运算符（非 const）
    T& operator[](size_t i) { 
        return ptr_.get()[i];  // 获取原始指针并访问元素
    }

    // 下标访问运算符（const 版本）
    const T& operator[](size_t i) const { 
        return ptr_.get()[i]; 
    }

    // 返回数组大小
    size_t size() const { return size_; }

private:
    size_t size_;          // 数组长度
    std::shared_ptr<T> ptr_; // 用 shared_ptr 管理动态数组
};

int main() {
    // 创建一个长度为 3 的共享数组
    shared_array<int> arr(3);

    // 通过下标访问赋值
    arr[0] = 7;
    arr[1] = 14;
    arr[2] = 21;

    // 输出数组内容
    for (size_t i = 0; i < arr.size(); ++i)
        std::cout << arr[i] << " ";
    std::cout << std::endl;

    // 离开作用域时 shared_ptr 自动释放数组内存
    return 0;
}
```

- 提供一个安全、共享、自动释放的动态数组封装，功能类似 C++20 的 `std::shared_ptr<T[]>`。
