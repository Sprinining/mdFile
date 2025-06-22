---
title: stack
date: 2024-08-20 10:42:10 +0800
categories: [c++]
tags: [C++, C++ STL]
description: 
---
## stack

![img](./stack.assets/2-1P913101Q4T2.jpg)

 定义一个用来存放字符串对象的 stack 容器:

```c++
stack<string> words;
```

stack 容器适配器的模板有两个参数。第一个参数是存储对象的类型，第二个参数是底层容器的类型。`stack<T>` 的底层容器默认是 `deque<T>` 容器，因此模板类型其实是 `stack<typename T, typename Container=deque<T>>`。通过指定第二个模板类型参数，可以使用任意类型的底层容器，只要它们支持 `back()`、`push_back()`、`pop_back()`、`empty()`、`size()` 这些操作。下面展示了如何定义一个使用 `list<T>` 的堆栈：

```c++
stack<string,list<string>> fruit;
```

创建堆栈时，不能在初始化列表中用对象来初始化，但是可以用另一个容器来初始化，只要堆栈的底层容器类型和这个容器的类型相同。

```c++
list<double> values{1.414, 3.14159265, 2.71828};
stack<double, list<double>> my_stack(values);
```

第二条语句生成了一个包含 value 元素副本的 my_stack。这里不能在 stack 构造函数中使用初始化列表；必须使用圆括号。如果没有在第二个 stack 模板类型参数中将底层容器指定为 list，那么底层容器可能是 deque，这样就不能用 list 的内容来初始化 stack；只能接受 deque。

`stack<T>` 模板定义了拷贝构造函数，因而可以复制现有的 stack 容器：

```c++
stack<double,list<double>>copy_stack {my_stack}
```

copy_stack 是 my_stack 的副本。如你所见，在使用拷贝构造函数时，既可以用初始化列表，也可以用圆括号。

### 堆栈操作

和其他序列容器相比，stack 是一类存储机制简单、所提供操作较少的容器。下面是 stack 容器可以提供的一套完整操作：

- `top()`：返回一个栈顶元素的引用，类型为 T&。如果栈为空，返回值未定义。
- `push(const T& obj)`：可以将对象副本压入栈顶。这是通过调用底层容器的 `push_back()` 函数完成的。
- `push(T&& obj)`：以移动对象的方式将对象压入栈顶。这是通过调用底层容器的有右值引用参数的 `push_back()` 函数完成的。
- `pop()`：弹出栈顶元素。
- `size()`：返回栈中元素的个数。
- `empty()`：在栈中没有元素的情况下返回 true。
- `emplace()`：用传入的参数调用构造函数，在栈顶生成对象。
- `swap(stack<T> & other_stack)`：将当前栈中的元素和参数中的元素交换。参数所包含元素的类型必须和当前栈的相同。对于 stack 对象有一个特例化的全局函数 swap() 可以使用。
