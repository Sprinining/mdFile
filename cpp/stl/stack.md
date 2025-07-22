## stack

`std::stack` 是一个 **容器适配器（container adapter）**，用于模拟 **后进先出（LIFO）** 的栈结构。

它 **封装了一个底层容器**（默认是 `deque`），并 **仅暴露部分接口**（如 `push`, `pop`, `top`），从而屏蔽掉底层容器的其余功能。

### 常见接口

```cpp
#include <stack>
using namespace std;

stack<int> s;
s.push(1);      // 入栈
s.push(2);
s.top();        // 查看栈顶（不弹出），返回 2
s.pop();        // 弹出栈顶，栈变为 [1]
s.empty();      // 判断是否为空
s.size();       // 返回元素个数
```

接口列表：

| 接口        | 说明                   |
| ----------- | ---------------------- |
| `push(x)`   | 入栈                   |
| `pop()`     | 出栈（移除栈顶元素）   |
| `top()`     | 查看栈顶元素（不移除） |
| `empty()`   | 是否为空               |
| `size()`    | 元素个数               |
| `emplace()` | 原地构造元素（C++11）  |

### 底层原理

stack 本质上是对底层容器的封装（默认 `deque`）：

```cpp
template<
    class T,
    class Container = std::deque<T>
> class stack;
```

也可以指定 `vector<T>` 或 `list<T>` 作为底层容器：

```cpp
stack<int, vector<int>> s1;
stack<int, list<int>> s2;
```

要求底层容器必须支持：`back()`, `push_back()`, `pop_back()`。

### 示例代码

```cpp
#include <iostream>
#include <stack>
using namespace std;

int main() {
    stack<int> s;
    for (int i = 1; i <= 5; ++i) s.push(i);  // 入栈 1~5

    while (!s.empty()) {
        cout << s.top() << " ";  // 5 4 3 2 1
        s.pop();
    }
}
```

### 使用场景举例

- 表达式求值（中缀转后缀、逆波兰表达式）
- 括号匹配
- 深度优先搜索（DFS）
- 回溯/撤销操作
- 浏览器前进/后退功能模拟

### 常见问题

1. **`stack` 能用哪些容器做底层？为啥默认是 `deque`？**
   - 要求底层容器支持 `back()`, `push_back()`, `pop_back()`
   - `deque` 支持更快的尾部插入删除，且可双端扩展，默认更安全
2. **能不能遍历 `stack`？**
   - ❌ 不能，`stack` 故意不暴露迭代器
   - 若需遍历，可用 `vector` 实现类栈行为
3. **stack 的线程安全性？**
   - STL 的容器默认不是线程安全的，需用户自行加锁
4. **top() 后能否继续使用栈？**
   - 可以，`top()` 不会移除元素，`pop()` 才会

### 注意事项

- `stack.pop()` **不会返回值**！你要先用 `top()` 获取，再 `pop()`。

  ```cpp
  int x = s.top();
  s.pop();  // 正确方式
  ```

- 不支持遍历（无 `begin()`/`end()`），如需遍历请用其他容器模拟。

- C++ STL `stack` 是**容器适配器**，并非底层容器，效率受限于其底层实现。

### stack 定义完整列表

SGI STL 默认使用 deque 作为 stack 的底层容器。stack 本身只是对底层容器的一层封装，实现非常简单。这种“改变接口以适配新用途”的做法，称为 **adapter（配接器）**，所以 stack 被归类为 **容器适配器（container adapter）**，而不是一般的容器（container）。

```cpp
// stack 是一个容器适配器，默认使用 deque 作为底层容器
template <class T, class Sequence = deque<T> >
class stack {

// 声明友元函数，使得非成员函数 operator== 和 operator< 可以访问 stack 的私有成员 c
// __STL_NULL_TMPL_ARGS 通常会展开为空模板参数列表（即 <>），见《STL源码剖析》1.9.1 节
friend bool operator== __STL_NULL_TMPL_ARGS (const stack&, const stack&);
friend bool operator< __STL_NULL_TMPL_ARGS (const stack&, const stack&);

public:
    // 类型定义，从底层容器 Sequence 中导出
    typedef typename Sequence::value_type        value_type;
    typedef typename Sequence::size_type         size_type;
    typedef typename Sequence::reference         reference;
    typedef typename Sequence::const_reference   const_reference;

protected:
    Sequence c;  // 底层容器，负责存储元素。默认是 deque<T>

public:
    // 基本操作都委托到底层容器 c 上完成
    bool empty() const { return c.empty(); }      // 判空
    size_type size() const { return c.size(); }   // 返回元素个数
    reference top() { return c.back(); }          // 返回栈顶元素（最后一个元素）
    const_reference top() const { return c.back(); }

    // push 是在底层容器的末尾插入元素
    void push(const value_type& x) { c.push_back(x); }

    // pop 是移除底层容器的末尾元素
    void pop() { c.pop_back(); }
};

// 非成员函数重载：判断两个 stack 是否相等
template <class T, class Sequence>
bool operator==(const stack<T, Sequence>& x, const stack<T, Sequence>& y) {
    return x.c == y.c;  // 委托到底层容器的 == 运算
}

// 非成员函数重载：判断一个 stack 是否小于另一个 stack
template <class T, class Sequence>
bool operator<(const stack<T, Sequence>& x, const stack<T, Sequence>& y) {
    return x.c < y.c;   // 委托到底层容器的 < 运算（按字典序比较）
}
```

- **stack 并不是一个真正的容器**，而是 **容器适配器**（adapter），对底层容器（默认是 `deque`）的操作进行了封装。
- 所有操作都基于 `c.push_back()` / `c.pop_back()` / `c.back()`，从而实现 **后进先出（LIFO）** 行为。
- `operator==` 和 `operator<` 也是通过底层容器来实现比较操作的。
- 如果你想用 `vector` 或 `list` 作为 stack 的底层，也可以显式地传模板参数：如 `stack<int, vector<int>>`。

### stack 没有迭代器

stack 的所有操作都遵循“后进先出”原则，只能访问栈顶元素，不支持遍历，也不提供迭代器。
