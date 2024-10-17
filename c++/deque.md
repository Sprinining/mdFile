---
title: deque
date: 2024-08-20 03:09:01 +0800
categories: [c++]
tags: [C++, C++ STL]
description: 
---
## deque

`deque<T>`，一个定义在 deque 头文件中的容器模板，可以生成包含 T 类型元素的容器，它以双端队列的形式组织元素。可以在容器的头部和尾部高效地添加或删除对象，这是它相对于 vector 容器的优势。

### 创建

![img](./deque.assets/2-1P912112354246.jpg)

```c++
#include <algorithm>
#include <string>
#include <deque>

using namespace std;

int main() {
    // 默认的构造函数生成 deque 容器，容器中没有任何元素，因此添加第一个元素，就会导致内存的分配
    deque<int> data1;
    // 生成给定元素个数的 deque 容器，每个元素保存的都是这种元素类型的默认值
    deque<int> data2(10);
    // 用初始化列表来生成 deque 容器
    deque<string> words{"one", "none", "some", "all", "none", "most", "many"};

    // 生成现有容器的副本
    deque<string> words_copy{words};
    // 由两个迭代器标识的一段元素来初始化它，作为初始值的一段元素，可以来自任何种类的容器，不需要一定是 deque
    // 这个容器有 5 个元素，它们和 words 容器的前 5 个元素相等
    deque<string> words_part{begin(words), begin(words) + 5};
}
```

### 访问

deque 容器中的元素是序列，但是内部的存储方式和 vector 不同。它组织元素的方式导致容器的大小总是和容量相等。因此没有定义成员函数 `capacity()`，deque 只有成员函数 `size()`，它以成员类型 size_type 的无符号整型来返回当前元素个数。

可以用下标运算符来访问元素，但是索引并没有进行边界检查。为了用进行边界检查的索引来访问元素，可以选择使用成员函数 `at()`，这和 vector 相同。

deque 成员函数 `front()` 和 `back()` 的用法也和 vector 相同，然而，deque 却没有成员函数 `data()`，因为元素并没有被存放在数组中。deque 容器和 vector 一样，有三种不同重载版本的 `resize()` 函数，它们的操作基本相同。

### 添加和删除

deque 和 vector 都有成员函数 push_back() 和 pop_back()，它们在序列尾部添加或删除元素的方式相同。deque 也有成员函数 push_front() 和 pop_front()，可以在序列头部执行相似的操作。

除了和 vector —样都有 emplace_back() 函数外，deque 还有成员函数 emplace_front()，可以在序列的开始位置生成新的元素。和 vector 一样，也可以使用 emplace() 或 insert() 在 deque 内部添加或移除元素。这个过程相对要慢一些，因为这些操作需要移动现有的元素。

关于 vector 容器的所有 insert() 函数也同样适用于 deque 容器。在 deque 的任意位置插入一个元素会让现有的迭代器全部失效，因此需要重新生成它们。deque 的成员函数 erase() 也和 vector 的相同，它的成员函数 clear() 可以移除一些元素。

### 修改

```c++
#include <algorithm>
#include <string>
#include <deque>
#include <iostream>
#include <vector>

using namespace std;

int main() {
    deque<string> words{"one", "two", "three", "four"};
    auto init_list = {string{"seven"}, string{"eight"}, string{"nine"}};

    // 1.用 init_list 中的 string 对象替换掉了 words 中的元素
    /*
     * 这里不能直接把字符放入初始化列表。
     * 如果这么做，init_list 的类型会被推导为 initializer_list<const char*>，
     * 然而 assign() 需要的是一个 initializer_list<string> 类型的实参，这样就无法通过编译。
     */
    words.assign(init_list);
    // 也可以不单独定义 init_list，可以在 assign() 的实参中定义初始化列表
    // words.assign({"seven", "eight", "nine"});
    // deque: seven eight nine

    // 2.提供两个迭代器作为参数
    vector<string> wordSet{"this", "that", "these", "those"};
    words.assign(begin(wordSet) + 1, end(wordSet) - 1);
    // deque: that these

    // 3.用重复的对象来替换容器中的内容
    words.assign(2, "two");
    // deque: two two

    // 为 deque 替换一套新元素
    // otlier_words 会包含和 words 相同的元素，words 则包含初始化列表中的那些元素
    deque<string> other_words;
    other_words = words;
    words = {"seven", "eight", "nine"};
}
```
