## forward_list

`std::forward_list` 是 C++11 引入的**单向链表容器**，相比 `std::list`（双向链表）更加轻量，仅维护一个方向的链接指针，适用于低内存开销、简单插删的场景。

### 底层结构与原理

底层是**单向链表（singly linked list）**，每个节点结构类似：

```cpp
struct Node {
    T data;
    Node* next;
};
```

容器只维护一个头指针 `head`，不能双向遍历，也没有 `tail`。

> 优点：比 `list` 更省内存（少一个指针）
> 缺点：不能反向遍历，也不支持 `size()` 常数时间获取大小（需手动统计）

### 常用接口

#### 创建与遍历

```cpp
#include <forward_list>
#include <iostream>
using namespace std;

int main() {
    forward_list<int> fl = {1, 2, 3};

    for (int x : fl)
        cout << x << " ";  // 输出：1 2 3
}
```

#### 插入与删除

```cpp
forward_list<int> fl = {1, 2, 3};
auto it = fl.before_begin();  // forward_list 没有 begin() 前的元素，所以用 before_begin()

fl.insert_after(it, 0);     // 插入到 1 之前 -> {0, 1, 2, 3}

++it;  // 指向 0
fl.erase_after(it);         // 删除 1 -> {0, 2, 3}

for (int x : fl) cout << x << " ";
// 0 2 3
```

注意：`insert_after` / `erase_after` 是 forward_list 的核心插入/删除方式，**操作的是指定节点“之后”的位置**。

#### 其他操作

```cpp
forward_list<int> fl = {5, 2, 1, 3, 2};

fl.sort();       // 排序
fl.unique();     // 相邻去重（如：1,1,2,3 -> 1,2,3）
fl.reverse();    // 反转

for (int x : fl) cout << x << " ";
// 1 2 3 5
```

### 常见操作时间复杂度对比

| 操作             | `forward_list` | `list`   | 说明                   |
| ---------------- | -------------- | -------- | ---------------------- |
| 顺序访问（遍历） | ✅ O(n)         | ✅ O(n)   | 单向 / 双向            |
| 任意位置插入删除 | ✅ O(1)         | ✅ O(1)   | 需迭代器定位前一个位置 |
| 反向遍历         | ❌ 不支持       | ✅ 支持   |                        |
| 获取 size()      | ❌ O(n)         | ✅ O(1)*  | 一些实现中是 O(1)      |
| 随机访问         | ❌ 不支持       | ❌ 不支持 |                        |

### 适用场景

| 场景                  | 推荐容器       | 原因                |
| --------------------- | -------------- | ------------------- |
| 只需要单向遍历        | `forward_list` | 更轻量省内存        |
| 需要频繁双向插入/删除 | `list`         | 双向更方便          |
| 有严格内存限制        | `forward_list` | 少一个指针          |
| 需要常数时间 `size()` | `list`         | forward_list 不支持 |
