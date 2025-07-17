## list

`std::list` 是 STL 中的一个容器，底层实现为 **双向链表**，每个元素是一个节点，拥有前后指针，可以快速在任意位置插入或删除元素。

### 底层原理

每个节点：

```cpp
struct Node {
    T data;
    Node* prev;
    Node* next;
};
```

容器维护两个指针：

- `head` 指向首节点
- `tail` 指向尾节点（或一个哨兵节点）

特性：

- 内存不连续，节点动态分配
- 插入删除某个位置元素时间复杂度是 O(1)
- 不支持随机访问（`list[i]` 会报错）

### 常用接口

#### 构造与遍历

```cpp
#include <iostream>
#include <list>
using namespace std;

int main() {
    list<int> lst = {1, 2, 3};

    lst.push_back(4);    // 尾部插入
    lst.push_front(0);   // 头部插入

    for (int x : lst)    // 范围for遍历
        cout << x << " ";
    // 0 1 2 3 4
}
```

#### 插入 / 删除元素

```cpp
list<int> lst = {0, 1, 2, 3};
auto it = lst.begin(); // it -> 0
++it;                  // it -> 1
++it;                  // it -> 2

lst.insert(it, 99);    // 在 2 前插入 99 -> {0, 1, 99, 2, 3}
lst.erase(it);         // 删除 2 -> {0, 1, 99, 3}
```

#### `splice`：O(1) 把一个 list 的内容移动到另一个位置

```cpp
list<int> a = {1, 2, 3};
list<int> b = {4, 5};

auto it = a.begin();
++it;  // 指向 2
a.splice(it, b);  // 把 b 的所有元素移到 a 的 2 之前

for (int x : a) cout << x << " ";
// 1 4 5 2 3
```

#### `reverse()` / `sort()` / `unique()`

```cpp
list<int> l = {3, 1, 2, 2, 4};

l.sort();      // 升序排序
l.unique();    // 去重（相邻）
l.reverse();   // 反转

for (int x : l) cout << x << " ";
// 4 3 2 1
```

### 性能特点

| 操作          | 时间复杂度 | 备注                           |
| ------------- | ---------- | ------------------------------ |
| 访问元素      | O(1)       | 只能访问 `front()` 和 `back()` |
| 随机访问      | O(n)       | 迭代器需要遍历                 |
| 插入/删除     | O(1)       | 已知迭代器位置，操作快速       |
| 插入/删除尾部 | O(1)       |                                |
| 搜索元素      | O(n)       | 遍历                           |

### 使用建议

- 适合频繁 **中间插入删除**，且不需要随机访问的场景。
- 不适合频繁随机访问元素或按索引访问。
- 迭代器在插入删除时保持有效（除了被删除节点）。
- 使用 `splice` 实现链表间的高效节点移动。