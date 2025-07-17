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

