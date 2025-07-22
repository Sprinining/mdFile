## queue

`std::queue` 是 STL 中的**容器适配器（Container Adapter）**，用来实现**先进先出（FIFO）**的队列行为。

它是对一个**底层序列容器的封装**，默认用 `deque` 实现，并只暴露有限的接口。

### 底层原理

```cpp
template<
  class T,
  class Container = std::deque<T>
> class queue;
```

- `queue` 默认底层是 `deque`，也可以替换为支持 `front()`, `back()`, `push_back()`, `pop_front()` 的容器，如 `list`。
- 它只暴露队列语义接口：入队/出队/访问队首尾，而**不提供迭代器遍历等接口**。

### 常用接口

| 方法           | 含义                  |
| -------------- | --------------------- |
| `push(val)`    | 元素入队（尾部）      |
| `pop()`        | 出队（移除头部元素）  |
| `front()`      | 访问队头元素          |
| `back()`       | 访问队尾元素          |
| `empty()`      | 是否为空              |
| `size()`       | 当前元素个数          |
| `emplace(val)` | 原地构造入队（C++11） |

### 示例代码

```cpp
#include <iostream>
#include <queue>
using namespace std;

int main() {
    queue<int> q;
    q.push(10);
    q.push(20);
    q.push(30);

    while (!q.empty()) {
        cout << q.front() << " "; // 10 20 30
        q.pop();
    }
}
```

### 应用场景

- **广度优先搜索（BFS）**：最典型用途
- 多线程任务调度（配合互斥锁）
- 消息队列/生产者-消费者模型
- 数据缓冲区

### 常见问题

1. **queue 是线程安全的吗？**
    ❌ 默认不是。多线程使用需加锁（如 `mutex`）。
2. **和 deque 区别？**
    queue 不能访问中间元素、不支持随机访问，只暴露队列语义。
3. **底层容器有哪些可选？**
    默认 `deque`，可用 `list`。不支持 `vector`（没有 `pop_front()`）。
4. **能否遍历 queue？**
    ❌ 不行，需手动出队（复制一份出队打印，原队列会被清空）。
5. **为什么不直接用 deque？**
    queue 更安全，只暴露 FIFO 接口，防止误用。

### 注意事项

- `pop()` 不返回值。先用 `front()` 获取元素再 pop。

  ```cpp
  int x = q.front();
  q.pop();
  ```

- 不支持遍历（无 `begin()` / `end()`）

- 默认底层是 `deque`，不能改成 `vector`（缺 `pop_front()`）

### queue 与相关容器对比

| 容器    | 行为模型 | 插入位置 | 删除位置 | 典型操作复杂度 | 支持遍历 |
| ------- | -------- | -------- | -------- | -------------- | -------- |
| `queue` | FIFO     | 尾部     | 头部     | O(1)           | ❌        |
| `stack` | LIFO     | 尾部     | 尾部     | O(1)           | ❌        |
| `deque` | 双端     | 两端     | 两端     | O(1)           | ✅        |

### queue 适配器的结构

```cpp
template<class T, class Container = deque<T>>
class queue {
protected:
    Container c;
public:
    void push(const T& val) { c.push_back(val); }
    void pop() { c.pop_front(); }
    T& front() { return c.front(); }
    T& back() { return c.back(); }
    bool empty() const { return c.empty(); }
    size_t size() const { return c.size(); }
};
```

### queue 定义完整列表

只要用已有容器封装并限制其接口，就能实现一个先进先出的队列（queue）。例如使用 deque，并禁止前端插入与尾端删除，就能形成 queue。SGI STL 默认用 deque 作为 queue 的底层容器，因此 queue 的实现非常简单，是一种容器适配器（adapter），不被归类为普通容器（container）。

```cpp
// queue 容器适配器模板，默认以 deque<T> 作为底层容器
template <class T, class Sequence = deque<T> >
class queue {
    // 以下两个友元函数用于比较两个 queue 是否相等或小于
    // __STL_NULL_TMPL_ARGS 会展开为 <>，这是为了解决旧编译器的模板兼容性问题
    friend bool operator== __STL_NULL_TMPL_ARGS (const queue& x, const queue& y);
    friend bool operator<  __STL_NULL_TMPL_ARGS (const queue& x, const queue& y);
public:
    // 类型定义，直接复用底层容器的定义
    typedef typename Sequence::value_type        value_type;
    typedef typename Sequence::size_type         size_type;
    typedef typename Sequence::reference         reference;
    typedef typename Sequence::const_reference   const_reference;

protected:
    Sequence c;  // 实际承载元素的底层容器（默认是 deque<T>）

public:
    // 判断 queue 是否为空
    bool empty() const { return c.empty(); }

    // 返回 queue 中元素数量
    size_type size() const { return c.size(); }

    // 访问队头元素（可以修改）
    reference front() { return c.front(); }

    // 访问队头元素（只读）
    const_reference front() const { return c.front(); }

    // 访问队尾元素（可以修改）
    reference back() { return c.back(); }

    // 访问队尾元素（只读）
    const_reference back() const { return c.back(); }

    // 插入元素到队尾（入队）
    void push(const value_type& x) { c.push_back(x); }

    // 移除队头元素（出队）
    void pop() { c.pop_front(); }
};

// 比较两个 queue 是否相等（元素逐一比较）
template <class T, class Sequence>
bool operator==(const queue<T, Sequence>& x, const queue<T, Sequence>& y) {
    return x.c == y.c;
}

// 比较两个 queue 的大小（按元素字典序比较）
template <class T, class Sequence>
bool operator<(const queue<T, Sequence>& x, const queue<T, Sequence>& y) {
    return x.c < y.c;
}
```

- `queue` 是 **容器适配器（container adapter）**，不是标准容器（如 vector、deque、list）。
- 它通过封装一个底层容器（默认是 `deque`）来实现「先进先出」的行为。
- 所有操作如 `push`、`pop`、`front`、`back` 都直接调用底层容器的对应接口。
- 实现非常简洁，只是对底层容器做了接口限制和方向控制。
- 除了 `deque`，`list` 也是双向开口的结构。前面 `queue` 使用的底层容器接口（如 `empty`、`size`、`back`、`push_back`、`pop_back`）在 `list` 中也都具备。

### queue 没有迭代器

`queue` 所有元素必须遵循「先进先出」原则，只有最前面的元素可以被访问。它不支持遍历操作，也不提供迭代器。
