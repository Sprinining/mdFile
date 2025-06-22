---
title: forward_list
date: 2024-08-20 07:24:14 +0800
categories: [c++]
tags: [C++, C++ STL]
description: 
---
## forward_list

forward_list 容器以单链表的形式存储元素。forward_list 的模板定义在头文件 forward_list 中。fdrward_list 和 list 最主要的区别是:它不能反向遍历元素；只能从头到尾遍历。

forward_list 的单向链接性也意味着它会有一些其他的特性：

1. 无法使用反向迭代器。只能从它得到前向迭代器，这些迭代器都不能解引用，只能自增；
2. 没有可以返回最后一个元素引用的成员函数 `back()`;只有成员函数 `front()`;
3. 因为只能通过自增前面元素的迭代器来到达序列的终点，所以 `push_back()`、`pop_back()`、`emplace_back()` 也无法使用。

forward_list 容器的构造函数的使用方式和 list 容器相同。forward_list 的迭代器都是前向迭代器。它没有成员函数 `size()`，因此不能用一个前向迭代器减去另一个前向迭代器，但是可以通过使用定义在头文件 iterator 中的 `distance()` 函数来得到元素的个数。

因为 forward_list 正向链接元素，所以只能在元素的后面插入或粘接另一个容器的元素，这一点和 list 容器的操作不同，list 可以在元素前进行操作。因为这个，forward_list 包含成员函数 `splice_after()` 和 `insert_after()`，用来代替 list 容器的 `splice()` 和 `insert()`；顾名思义，元素会被粘接或插入到 list 中的一个特定位置。当需要在 forward_list 的开始处粘接或插入元素时，这些操作仍然会有问题。除了第一个元素，不能将它们粘接或插入到任何其他元素之前。

这个问题可以通过使用成员函数 `cbefore_begin()` 和 `before_begin()` 来解决。它们分别可以返回指向第一个元素之前位置的 const 和 non-const 迭代器。所以可以使用它们在开始位置插入或粘接元素。

```c++
#include <string>
#include <forward_list>

using namespace std;

int main() {
    forward_list<string> my_words{"three", "six", "eight"};
    forward_list<string> your_words{"seven", "four", "nine"};
    // 1.单个元素
    // 将 your_words 的最后一个元素粘接到 my_words 的开始位置
    // 第三个参数指向待转移元素之前的一个元素，只有后面的单个元素被转移。
    my_words.splice_after(my_words.before_begin(), your_words, ++begin(your_words));
    // my_words: nine three six eight
    // your_words: seven four

    // 2.一段元素
    // 后两个参数 first 和 last，它包括 first 和 last 之间的所有元素，但不包括 first 和 last 元素本身
    my_words.splice_after(my_words.before_begin(), your_words, begin(your_words), end(your_words));
    // my_words: four nine three six eight
    // your_words: seven

    // 3.所有元素
    my_words.splice_after(my_words.before_begin(), your_words);
    // my_words: seven four nine three six eight
    // your_words: 
}
```

forward_list 和 list —样都有成员函数 sort() 和 merge()，它们也都有 remove()、remove_if() 和unique()，所有这些函数的用法都和 list 相同。
