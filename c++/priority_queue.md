---
title: priority_queue
date: 2024-08-25 04:29:31 +0800
categories: [c++]
tags: [C++, C++ STL]
description: 
---
## priority_queue

`priority_queue `容器适配器定义了一个元素有序排列的队列。默认队列头部的元素优先级最高。因为它是一个队列，所以只能访问第一个元素，这也意味着优先级最高的元素总是第一个被处理。

```c++
// 有 3 个参数，其中两个有默认的参数；第一个参数是存储对象的类型，第二个参数是存储元素的底层容器，第三个参数是函数对象，它定义了一个用来决定元素顺序的断言。
template <typename T, typename Container=vector<T>, typename Compare=less<T>> class priority_queue
```

`priority_queue` 实例默认有一个 `vector `容器。函数对象类型 `less<T>` 是一个默认的排序断言，定义在头文件 `function `中（其中还定义了 `greater<T>`），决定了容器中==最大的元素会排在队列前面==。

```c++
int main() {
    vector<int> ary = {9, 5, 2, 7};
    // 默认用 less<>，队头（堆顶）是最大元素
    priority_queue<int> heap{begin(ary), end(ary)};

    // 使用 greater<>，队头（堆顶）是最小元素
    priority_queue<int, vector<int>, greater<>> heap2{begin(ary), end(ary)};

    // 优先级队列可以使用任何容器来保存元素，只要容器有成员函数 front()、push_back()、pop_back()、size()、empty()。这显然包含了 deque 容器
    priority_queue<int, deque<int>, greater<>> heap3{begin(ary), end(ary)};
}
```

![img](./priority_queue.assets/2-1P913134031947.jpg)

### 创建和初始化

```c++
int main() {
    // 1.生成一个空的优先级队列
    priority_queue<string> words;

    // 初始化列表中的序列可以来自于任何容器，并且不需要有序。优先级队列会对它们进行排序
    string wrds[]{"one", "two", "three", "four"};
    // 2.用适当类型的对象初始化一个优先级队列
    priority_queue<string> words2{begin(wrds), end(wrds)}; // "two" "three" "one" "four"

    // 3.拷贝构造函数会生成一个和现有对象同类型的 priority_queue 对象，它是现有对象的一个副本
    priority_queue<string> copy_words{words2};

    // 4.可以生成 vector 或 deque 容器，然后用它们来初始化 priority_queue
    vector<int> values{21, 22, 12, 3, 24, 54, 56};
    // 第一个参数对元素排序的函数对象，第二个参数是一个提供初始元素的容器
    priority_queue<int> numbers{less<int>(), values};
	// 在队列中用函数对象对 vector 元素的副本排序。values 中元素的顺序没有变，但是优先级队列中的元素顺序会改变。优先级队列中用来保存元素的容器是私有的，因此只能通过调用 priority_queue 对象的成员函数来对容器进行操作。

    // 5.如果想使用不同类型的比较函数，需要指定全部的模板类型参数
    priority_queue<int, vector<int>, greater<>> numbers2{greater<>(), values};
}
```

### priority_queue 操作

对 priority_queue 进行操作有一些限制：

- `push(const T& obj)`：将 obj 的副本放到容器的适当位置，这通常会包含一个排序操作。
- `push(T&& obj)`：将 obj 放到容器的适当位置，这通常会包含一个排序操作。
- `emplace(T constructor a rgs...)`：通过调用传入参数的构造函数，在序列的适当位置构造一个T对象。为了维持优先顺序，通常需要一个排序操作。
- `top()`：返回优先级队列中第一个元素的引用。
- `pop()`：移除第一个元素。
- `size()`：返回队列中元素的个数。
- `empty()`：如果队列为空的话，返回true。
- `swap(priority_queue<T>& other)`：和参数的元素进行交换，所包含对象的类型必须相同。

priority_queue 也实现了赋值运算，可以将右操作数的元素赋给左操作数；同时也定义了拷贝和移动版的赋值运算符。需要注意的是，priority_queue 容器并没有定义比较运算符。因为需要保持元素的顺序，所以添加元素通常会很慢。

### 自定义比较函数

#### 定义函数

- 属于传入函数指针的方式

```c++
#include <vector>
#include <iostream>
#include <queue>

using namespace std;

struct ListNode {
    int val;
    ListNode *next;

    ListNode() : val(0), next(nullptr) {}

    ListNode(int x) : val(x), next(nullptr) {}

    ListNode(int x, ListNode *next) : val(x), next(next) {}
};

class Solution {
public:
    // 作为类成员函数，一定要声明static
    static bool cmp(ListNode *a, ListNode *b) {
        return (*a).val > (*b).val;
    }
};

int main() {
    priority_queue<ListNode *, vector<ListNode *>, decltype(&Solution::cmp)> heap(Solution::cmp);
    heap.push(new ListNode(2));
    heap.push(new ListNode(1));
    heap.push(new ListNode(6));
    heap.push(new ListNode(3));

    while (!heap.empty()) {
        cout << (*heap.top()).val << " ";
        heap.pop();
    }
    return 0;
}
```

#### class 重载运算符()

- 属于传入函数对象的方式

```c++
class cmp {
public:
    bool operator()(int a, int b) {
        return a > b;
    }
};
// 小顶堆
priority_queue<int, vector<int>, cmp> heap;
```

#### struct 重载运算符

- 属于传入函数对象的方式

```c++
struct cmp {
    bool operator()(int a, int b) {
        return a > b;
    }
};
// 小顶堆
priority_queue<int, vector<int>, cmp> heap;
```

#### lambda 表达式

- 属于传入函数指针的方式

```c++
auto cmp = [](int a, int b) -> bool {
    return a > b;
};
// 小顶堆
priority_queue<int, vector<int>, decltype(cmp)> heap(cmp);
```

#### function 包装 lambda 表达式

- 属于传入函数指针的方式

```c++
// 要导入头文件
#include <functional>
```

```c++
function<bool(int, int)> cmp = [](int a, int b) -> bool {
    return a > b;
};
// 小顶堆
priority_queue<int, vector<int>, decltype(cmp)> heap(cmp);
```
