## 条款16：让 const 成员函数线程安全

### 背景与问题

- `const` 成员函数在概念上**不修改对象状态**，是“只读操作”。
- 但实际中，为了性能或便利，`const` 函数可能做**缓存（lazy evaluation）**，修改某些 `mutable` 成员（比如缓存值和状态标志）。
- 如果多个线程同时调用同一个对象的 `const` 成员函数，而函数内部修改 `mutable` 成员，没有同步机制，就会产生**数据竞争（data race）**，导致**未定义行为**。

### 经典示例

多线程调用时，`rootsAreValid` 和 `rootVals` 被多个线程**并发读写**，没有同步保护，产生数据竞争。

```cpp
class Polynomial {
public:
    // 定义 RootsType 类型，用于保存多项式的根（零点）集合
    using RootsType = std::vector<double>;

    // const成员函数：返回多项式的根
    RootsType roots() const {
        // 如果缓存的根尚未计算或无效
        if (!rootsAreValid) {
            // TODO: 计算多项式的根，并存储在 rootVals 中
            // 例如：rootVals = computeRoots();

            // 标记缓存有效，表示 rootVals 已包含最新计算的根
            rootsAreValid = true;
        }

        // 返回缓存的根集合
        return rootVals;
    }

private:
    // 用于缓存根是否有效的标志，mutable 修饰允许在 const 函数中修改
    mutable bool rootsAreValid{false};

    // 用于缓存计算出的根，mutable 修饰允许在 const 函数中修改
    mutable RootsType rootVals{};
};

```

- `mutable` 修饰符的意义：
  允许即使在 `const` 成员函数中，也能修改这两个成员变量（缓存状态和缓存数据），因为逻辑上这些修改不改变对象的“表面状态”。
- 该类设计为“懒计算缓存”机制：
  只有第一次调用 `roots()` 时，才计算并缓存结果，之后直接返回缓存的值，避免重复计算。
- 需要注意线程安全问题：
  如果多线程同时调用 `roots()`，可能会产生数据竞争，需要用互斥量等同步手段保护。

### 解决方法：互斥量（mutex）

在 `const` 函数中使用 `mutable std::mutex` 来保护访问。

```cpp
class Polynomial {
public:
    using RootsType = std::vector<double>;

    RootsType roots() const {
        std::lock_guard<std::mutex> guard(m);  // 加锁，保证线程安全，防止多个线程同时访问和修改缓存

        if (!rootsAreValid) {                   // 如果缓存的根无效（未计算过或需要更新）
            // 计算根（具体计算逻辑省略）
            rootsAreValid = true;               // 标记缓存有效，表示根已经计算并保存
        }

        return rootVals;                        // 返回缓存的根集合
    }

private:
    mutable std::mutex m;                      // 互斥锁，用于保护缓存数据的读写，mutable允许在const函数中修改
    mutable bool rootsAreValid{false};        // 标记缓存是否有效，mutable允许在const函数中修改
    mutable RootsType rootVals{};              // 缓存计算得到的根，mutable允许在const函数中修改
};
```

- `std::mutex` 必须是 `mutable`，因为在 `const` 成员函数中依然需要修改它。
- 使用互斥量保证了多线程调用时不会产生数据竞争。

### 使用 std::atomic 的场景与限制

`std::atomic` 适合对单个变量进行线程安全的读写，性能开销比互斥量低。

```cpp
class Point {
public:
    // 计算点到原点的距离，声明为const保证不修改点的逻辑状态
    // noexcept表示此函数不会抛异常
    double distanceFromOrigin() const noexcept {
        ++callCount;  // 线程安全地递增调用计数，std::atomic保证无数据竞争
        return std::sqrt(x * x + y * y);  // 计算欧几里得距离
    }

private:
    mutable std::atomic<unsigned> callCount{0};  // 可变的原子计数器，用于统计调用次数，允许const函数修改
    double x, y;                                 // 点的坐标
};
```

**注意**：`std::atomic` 不适合需要多个变量作为整体（事务）操作的场景。

### 复杂缓存场景下 `std::atomic` 的坑

使用两个 `std::atomic` 变量缓存值和有效标志时，可能出现：

- 多个线程同时计算缓存值，浪费资源。
- 缓存标志先被设为 `true`，但缓存值未写完，导致其他线程读到错误值。

```cpp
class Widget {
public:
    // 返回魔法值的函数，声明为const表示不会修改对象的逻辑状态
    int magicValue() const {
        if (cacheValid)                     // 如果缓存有效，直接返回缓存值
            return cachedValue;
        else {
            auto val1 = expensiveComputation1();  // 进行开销大的计算1
            auto val2 = expensiveComputation2();  // 进行开销大的计算2
            cachedValue = val1 + val2;             // 更新缓存值
            cacheValid = true;                      // 标记缓存有效
            return cachedValue;                     // 返回新计算的缓存值
        }
    }

private:
    mutable std::atomic<bool> cacheValid{false};  // 缓存是否有效的原子布尔标记，允许在const函数中修改
    mutable std::atomic<int> cachedValue;         // 缓存的整数值，原子类型保证多线程安全
};
```

#### 多个线程同时计算缓存值，浪费资源

假设 `cacheValid` 初始是 `false`，有两个线程几乎同时执行：

```cpp
if (cacheValid) return cachedValue;
else {
    // 这里两个线程都会进来
    auto val1 = expensiveComputation1();
    auto val2 = expensiveComputation2();
    cachedValue = val1 + val2;
    cacheValid = true;
    return cachedValue;
}
```

- 由于 `cacheValid` 还是 `false`，两个线程都会进入计算分支。
- 两个线程都做了同样的昂贵计算，浪费资源。
- 其实期望是第一个线程完成计算并设置缓存后，其他线程直接用缓存值。

#### 缓存标志先被设为 `true`，但缓存值未写完，导致其他线程读到错误值

如果代码改成：

```cpp
cacheValid = true;            // 先标记缓存有效
return cachedValue = val1 + val2;  // 再写缓存值
```

执行时，可能出现以下情况：

- 线程1执行到 `cacheValid = true;`，这时它告诉别的线程缓存有效了。
- 但它还没把 `cachedValue` 写好（`cachedValue = val1 + val2;` 还没完成）。
- 线程2此时看到 `cacheValid == true`，直接返回 `cachedValue`。
- 因为 `cachedValue` 还没写完，所以线程2得到的是错误的（未初始化或部分写入的）值。

这就是所谓的“写操作不是原子性的”，两个变量的更新顺序和可见性没有保证，导致数据竞争和错误结果。

### 推荐方案：缓存多变量使用互斥量保护

```cpp
class Widget {
public:
    int magicValue() const {
        std::lock_guard<std::mutex> guard(m);   // 加锁，保证线程安全，避免多个线程同时执行缓存更新

        if (cacheValid)                       // 如果缓存有效，直接返回缓存值
            return cachedValue;
        else {
            // 缓存无效，进行昂贵的计算
            auto val1 = expensiveComputation1();
            auto val2 = expensiveComputation2();
            cachedValue = val1 + val2;        // 更新缓存值
            cacheValid = true;                // 标记缓存有效
            return cachedValue;               // 返回新计算的缓存值
        }
    }

private:
    mutable std::mutex m;           // 互斥锁，mutable使得即使在const成员函数中也能修改锁
    mutable int cachedValue;        // 缓存的计算结果，mutable允许在const函数中修改
    mutable bool cacheValid{false}; // 缓存是否有效的标志，mutable允许在const函数中修改
};
```

- `mutable` 关键字使这些成员变量可以在`const`成员函数中修改，适合缓存这种逻辑。
- `std::lock_guard<std::mutex>`负责自动加锁和解锁，保证访问缓存的线程安全。
- 先检查缓存有效性，避免重复计算昂贵的操作。

### 总结

- **假设多线程会同时调用同一个对象的 `const` 成员函数，保证其线程安全。**
- `const` 函数中修改 `mutable` 成员，需加同步措施。
- **单变量线程同步用 `std::atomic`，多变量联动操作用 `std::mutex`。**
- 使用互斥量或原子操作会影响类的复制和移动特性（一般不可复制不可移动）。
- 如果确定不会多线程访问，可以避免同步开销，但现代程序中这种场景越来越少。
- 编写库和公共接口时，应默认保证 `const` 成员函数的线程安全。