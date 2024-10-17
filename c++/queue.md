---
title: queue
date: 2024-08-20 10:49:00 +0800
categories: [c++]
tags: [C++, C++ STL]
description: 
---
## queue

只能访问 `queue<T>` 容器适配器的第一个和最后一个元素。只能在容器的末尾添加新元素，只能从头部移除元素。

![img](./queue.assets/2-1P913113140553.jpg)

queue 的生成方式和 stack 相同，下面展示如何创建一个保存字符串对象的 queue:

```c++
queue<string> words;
```

也可以使用拷贝构造函数：

```c++
queue<string> copy_words {words}; 
```

`stack<T>`、`queue<T>` 这类适配器类都默认封装了一个 `deque<T>` 容器，也可以通过指定第二个模板类型参数来使用其他类型的容器：

```c++
queue<string, list<string>>words;
```

底层容器必须提供这些操作：front()、back()、push_back()、pop_front()、empty() 和 size()。

### queue 操作

queue 和 stack 有一些成员函数相似，但在一些情况下，工作方式有些不同：

- `front()`：返回 queue 中第一个元素的引用。如果 queue 是常量，就返回一个常引用；如果 queue 为空，返回值是未定义的。
- `back()`：返回 queue 中最后一个元素的引用。如果 queue 是常量，就返回一个常引用；如果 queue 为空，返回值是未定义的。
- `push(const T& obj)`：在 queue 的尾部添加一个元素的副本。这是通过调用底层容器的成员函数 `push_back()` 来完成的。
- `push(T&& obj)`：以移动的方式在 queue 的尾部添加元素。这是通过调用底层容器的具有右值引用参数的成员函数 `push_back()` 来完成的。
- `pop()`：删除 queue 中的第一个元素。
- `size()`：返回 queue 中元素的个数。
- `empty()`：如果 queue 中没有元素的话，返回 true。
- `emplace()`：用传给 emplace() 的参数调用 T 的构造函数，在 queue 的尾部生成对象。
- `swap(queue<T> &other_q)`：将当前 queue 中的元素和参数 queue 中的元素交换。它们需要包含相同类型的元素。也可以调用全局函数模板 `swap()` 来完成同样的操作。

`queue<T>` 模板定义了拷贝和移动版的 operator=()，对于所保存元素类型相同的 queue 对象，它们有一整套的比较运算符，这些运算符的工作方式和 stack 容器相同。

和 stack 一样，queue 也没有迭代器。访问元素的唯一方式是遍历容器内容，并移除访问过的每一个元素。
