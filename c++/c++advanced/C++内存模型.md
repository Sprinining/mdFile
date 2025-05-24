## C++内存模型

C++ 内存模型是 C++11 标准引入的重要概念，用于规定 **多线程程序中变量在不同线程之间的可见性与操作顺序**，使得并发程序行为可预测。它定义了原子性、可见性和有序性规则。

### 一、内存模型的基本概念

#### 1. 什么是内存模型（Memory Model）？

C++ 的内存模型描述了：

- 多线程环境下，**变量的值是如何在不同线程中传播的**
- 编译器和 CPU 可以**如何重排序指令**
- 程序如何通过特定的同步原语来防止这种重排序

> C++11 之前并没有正式的内存模型，行为全靠平台实现（比如 POSIX 或 Windows API）。C++11 引入了 std::atomic 和 memory_order 来标准化行为。

------

### 二、原子操作（Atomic Operations）

C++11 引入了 `<atomic>` 头文件，提供了原子类型，如：

```cpp
#include <atomic>
std::atomic<int> x;
```

#### 原子操作的特点：

- **不可中断**：即使有其他线程正在运行，也无法观察到中间状态。
- **内存可见性**：原子操作可以通过特定的内存序来影响其他线程看到的顺序。

------

### 三、内存顺序（memory_order）

这是 C++ 内存模型的核心内容，定义了各种原子操作对内存访问的排序约束。

```cpp
enum memory_order {
    memory_order_relaxed,
    memory_order_consume,  // 实际已废弃
    memory_order_acquire,
    memory_order_release,
    memory_order_acq_rel,
    memory_order_seq_cst
};
```

#### 各个 memory_order 的含义：

| 序名称                 | 含义说明                                                     |
| ---------------------- | ------------------------------------------------------------ |
| `memory_order_relaxed` | **最弱保证**，只保证原子性，不保证顺序或可见性               |
| `memory_order_acquire` | **读取操作**：确保当前线程此操作之后的内存访问不会被重排到此操作之前 |
| `memory_order_release` | **写入操作**：确保当前线程此操作之前的内存访问不会被重排到此操作之后 |
| `memory_order_acq_rel` | 同时具有 acquire 和 release 效果，常用于 read-modify-write 操作（如 `fetch_add`） |
| `memory_order_seq_cst` | **最强保证（默认）**：顺序一致性，所有线程看到的顺序一致     |

#### 示例代码：

```cpp
std::atomic<bool> flag = false;
int data = 0;

// 线程 A
data = 42;
flag.store(true, std::memory_order_release); // 写入 data 后发布 flag

// 线程 B
if (flag.load(std::memory_order_acquire)) {  // 读取 flag 后获取 data
    assert(data == 42);  // 保证成立
}
```

------

### 四、顺序一致性模型（Sequential Consistency）

这是 C++ 默认的 memory_order（即 `memory_order_seq_cst`），它模拟了人们对多线程程序执行的直觉：**所有操作按某个全局顺序执行**。

> 虽然使用最简单，但代价较高，不利于性能优化。

------

### 五、数据竞争（Data Race）

C++11 定义：

- **数据竞争发生条件**：
  - 至少两个线程访问同一个变量
  - 其中至少一个是写操作
  - 没有同步机制（如 mutex 或原子操作）保护

**数据竞争将导致未定义行为（undefined behavior）**！

避免方法：

- 使用 `std::atomic`
- 使用 `std::mutex` 等同步原语

------

### 六、原子类型与操作

#### 常用原子类型：

```cpp
std::atomic<int>
std::atomic<bool>
std::atomic_flag
std::atomic<T*> // 任意指针类型
```

#### 常用操作：

```cpp
a.store(value, memory_order);
a.load(memory_order);
a.exchange(value);
a.compare_exchange_weak/strong(expected, desired);
a.fetch_add(x), fetch_sub(x) 等
```

------

### 七、示例：无锁标志位同步

```cpp
std::atomic<bool> ready = false;
int result;

// 生产者线程
result = compute();
ready.store(true, std::memory_order_release);

// 消费者线程
while (!ready.load(std::memory_order_acquire));
std::cout << result << std::endl;
```

由于使用了 release-acquire 语义，`result` 的写入对消费者线程可见。

------

### 八、memory_order_relaxed 示例（仅原子性无同步）

```cpp
std::atomic<int> counter = 0;

// 多线程并发递增
void thread_func() {
    for (int i = 0; i < 1000; ++i)
        counter.fetch_add(1, std::memory_order_relaxed); // 无顺序保证
}
```

虽然保证最终结果是准确的，但不能保证操作间的可见性顺序。

------

### 九、内存模型与 mutex、条件变量等关系

mutex、condition_variable 等是 **基于更强同步机制** 实现的，它们内部保证了合适的 acquire-release 语义：

```cpp
std::mutex m;
std::unique_lock<std::mutex> lock(m); // 隐式 acquire
// 临界区
lock.unlock();                        // 隐式 release
```

------

### 十、小结

| 类型                   | 特点                 | 典型用途         |
| ---------------------- | -------------------- | ---------------- |
| `memory_order_relaxed` | 仅保证原子性         | 性能极限优化     |
| `memory_order_acquire` | 获取同步             | 读共享数据前使用 |
| `memory_order_release` | 发布同步             | 写共享数据后使用 |
| `memory_order_acq_rel` | 修改型原子操作       | fetch_add 等     |
| `memory_order_seq_cst` | 默认，最强的同步顺序 | 简单安全，代价高 |