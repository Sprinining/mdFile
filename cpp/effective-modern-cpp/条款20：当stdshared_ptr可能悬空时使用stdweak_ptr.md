## 条款20：当 std::shared_ptr 可能悬空时使用 std::weak_ptr

### 核心思想

- `std::weak_ptr` 是一个**非拥有型（non-owning）智能指针**，
   它指向 `std::shared_ptr` 所管理的对象，但**不增加引用计数**。
- `std::weak_ptr` 可以在对象被销毁时检测出自己是否悬空（expired）。

### 设计动机

- 有时候想引用一个对象，但不想拥有它的生命周期。
- `std::shared_ptr` 循环引用（互相持有）会导致内存泄露。
- 原始指针无法检测是否悬空，存在未定义行为的风险。

### 基本用法

```cpp
auto sp = std::make_shared<Widget>(); // 创建 shared_ptr，引用计数（strong count）为1
std::weak_ptr<Widget> wp(sp);         // 创建 weak_ptr，引用计数不变（仍为1），weak count +1

if (!wp.expired()) {                  // 判断 weak_ptr 是否指向已销毁对象（非原子操作，存在竞态风险）
    auto sp2 = wp.lock();             // 原子操作：尝试获取 shared_ptr，若成功，strong count +1
    if (sp2) {                       // 如果 lock 成功，即对象仍存在
        // 使用 sp2 访问 Widget，确保对象在此作用域内存活
    }
}
```

- `wp.lock()`：尝试获取 `shared_ptr`，失败则返回空。

- `std::shared_ptr<T> sp(wp);`：另一种构造方式，**wp过期则抛出 `std::bad_weak_ptr` 异常**。

### 适用场景

#### 缓存系统

假设有一个比较昂贵的加载函数 `loadWidget`，它返回一个 `std::shared_ptr<const Widget>`：

```cpp
// 模拟昂贵的加载操作
std::shared_ptr<const Widget> loadWidget(WidgetID id) {
    // 比如从文件、数据库加载数据，构造 Widget 对象
    return std::make_shared<const Widget>(/* ... */);
}
```

我们想写一个“快速加载”的函数 `fastLoadWidget`，它带缓存：

```cpp
std::shared_ptr<const Widget> fastLoadWidget(WidgetID id) {
    // 缓存：key 是 WidgetID，value 是 weak_ptr，不增加对象引用计数
    static std::unordered_map<WidgetID, std::weak_ptr<const Widget>> cache;

    // 尝试从缓存获取 shared_ptr（会尝试提升 weak_ptr）
    auto cachedPtr = cache[id].lock();

    if (!cachedPtr) { // 如果缓存不存在或已经过期（对象被销毁）
        // 调用真正的加载函数
        cachedPtr = loadWidget(id);

        // 缓存最新的 weak_ptr，不增加引用计数
        cache[id] = cachedPtr;
    }

    // 返回 shared_ptr，调用者获得对象所有权（引用计数+1）
    return cachedPtr;
}
```

说明：

- **缓存存储 `std::weak_ptr`：**
   - **`std::shared_ptr` 拥有对象的所有权，会增加引用计数，延长对象生命周期。** 如果缓存存的是 `shared_ptr`，即使程序里其他地方都不再用这个对象，缓存里还持有一个 `shared_ptr`， 对象的引用计数不会归零，导致对象一直不会被销毁，造成**内存泄漏**。

   - **而 `std::weak_ptr` 不拥有对象所有权，不增加引用计数，缓存存它只“观察”对象是否存在。**当所有真正持有对象的 `shared_ptr` 都销毁后，对象被释放，缓存中的 `weak_ptr` 就变成“过期”状态（expired）。
   
- `std::weak_ptr` 有接受对应 `std::shared_ptr` 的构造函数和赋值操作符
  - `std::weak_ptr<T>` 是专门为与 `std::shared_ptr<T>` 配合设计的，
  - 它有一个 **构造函数** 和 **赋值运算符**，可以接受 `std::shared_ptr<T>` 类型，
  - 并从中构造对应的 `weak_ptr`（指向相同对象，但不增加引用计数）。

- **调用 `lock()` 尝试获取 `shared_ptr`：**
   若对象存在，返回有效的 `shared_ptr`，引用计数+1。若对象已销毁，返回空指针。

- **若缓存失效，重新加载并缓存最新 `weak_ptr`：**
   新对象的生命周期由调用者通过 `shared_ptr` 管理。

- **当所有 `shared_ptr` 都析构时，对象释放，缓存的 `weak_ptr` 过期。**

优点：

- 避免重复加载耗时资源。
- 对象生命周期由 `shared_ptr` 自动管理，缓存不会导致内存泄漏。
- 访问缓存时能自动感知对象是否仍然有效。

#### 观察者模式

```cpp
#include <iostream>
#include <vector>
#include <memory>

class Observer {
public:
    virtual ~Observer() = default;
    virtual void onNotify(int data) = 0;
};

class Subject {
    // 用 weak_ptr 存储观察者，避免拥有它们的生命周期
    std::vector<std::weak_ptr<Observer>> observers_;

public:
    void addObserver(std::shared_ptr<Observer> obs) {
        observers_.push_back(obs);
    }

    void notify(int data) {
        // 遍历所有观察者，尝试提升 weak_ptr
        for (auto it = observers_.begin(); it != observers_.end(); ) {
            if (auto obs = it->lock()) {
                obs->onNotify(data);  // 有效观察者，调用通知
                ++it;
            } else {
                // 观察者已销毁，移除过期的 weak_ptr
                it = observers_.erase(it);
            }
        }
    }
};

// 具体观察者实现
class ConcreteObserver : public Observer, public std::enable_shared_from_this<ConcreteObserver> {
public:
    void onNotify(int data) override {
        std::cout << "Observer notified with data: " << data << "\n";
    }
};

int main() {
    Subject subject;

    {
        auto obs1 = std::make_shared<ConcreteObserver>();
        subject.addObserver(obs1);

        subject.notify(42);  // 通知，有效观察者会收到
    } // obs1 作用域结束，析构，观察者销毁

    subject.notify(100); // 此时观察者已销毁，通知时会跳过并清理过期 weak_ptr

    return 0;
}
```

- `Subject` 持有 `std::weak_ptr<Observer>`，不影响 `Observer` 生命周期。
- `notify()` 时通过 `lock()` 提升为 `shared_ptr`，确保访问安全。
  - 当需要调用观察者方法（如 `onNotify`）时，不能直接用 `weak_ptr`，因为它可能指向已经被销毁的对象（悬空）。
  - 如果观察者对象还存在，`lock()` 返回有效的 `shared_ptr`，**这时引用计数+1，保证对象在这段代码里不被销毁**。
- 如果观察者已销毁，`lock()` 返回空指针，`Subject` 会移除过期的观察者指针。
- 这样既避免了悬空访问，也避免了循环引用导致内存泄漏。

#### 打破循环引用

场景：A ↔ B，A 持有 B，B 弱引用 A

```cpp
#include <iostream>
#include <memory>

struct B; // 前置声明

struct A {
    std::shared_ptr<B> b_ptr;  // 拥有B的所有权
    ~A() { std::cout << "A destroyed\n"; }
};

struct B {
    std::weak_ptr<A> a_ptr;    // 弱引用A，避免循环引用
    ~B() { std::cout << "B destroyed\n"; }
};

int main() {
    {
        auto a = std::make_shared<A>();
        auto b = std::make_shared<B>();

        a->b_ptr = b;    // A拥有B
        b->a_ptr = a;    // B弱引用A，不增加引用计数

        // 两个对象相互关联，但不会循环引用导致泄漏
    } // 作用域结束，a和b都正确销毁

    return 0;
}
```

如果用 `shared_ptr` 循环引用（错误示范）

```cpp
struct B {
    std::shared_ptr<A> a_ptr; // 强引用A，循环引用
    ~B() { std::cout << "B destroyed\n"; }
};
```

- 这会导致 `A` 和 `B` 互相持有强引用，引用计数都不为零，

- 即使超出作用域，析构函数也不会被调用，造成内存泄漏。

结论

- **用 `weak_ptr` 替代其中一个方向的 `shared_ptr`，打破循环引用。**
- 这样，资源才能被正确释放，不会泄漏。

### 注意事项

- `std::weak_ptr` 不是“弱化版” `shared_ptr`，而是用于**观察（observe）资源**而非管理资源。
- `expired()` 检查非原子，**只应与 `lock()` 搭配使用**。
- `weak_ptr` 本身也增加控制块的“弱引用计数”，管理其自身生命周期。

### 总结

- **用 `weak_ptr` 替代可能悬空的 `shared_ptr`。**

- **典型应用：缓存、观察者列表、打破 `shared_ptr` 循环引用。**

- **用 `lock()` 原子地检测有效性并获取 `shared_ptr`。**
