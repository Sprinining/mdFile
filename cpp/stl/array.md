---
title: array
date: 2024-08-20 09:03:57 +0800
categories: [c++]
tags: [C++, C++ STL]
description: 
---
## array

array<T,N> 模板定义了一种相当于标准数组的容器类型。它是一个有 N 个 T 类型元素的固定序列。除了需要指定元素的类型和个数之外，它和常规数组没有太大的差别。显然，不能增加或删除元素。

模板实例的元素被内部存储在标准数组中。和标准数组相比，array 容器的额外幵销很小，但提供了两个优点：如果使用 at()，当用一个非法的索引访问数组元素时，能够被检测到，因为容器知道它有多少个元素，这也就意味着数组容器可以作为参数传给函数，而不再需要单独去指定数组元素的个数。

### 创建

```c++
#include <array>
#include <iostream>

using namespace std;

int main() {
    // 创建具有 10 个 int 类型的数组，但未初始化
    array<int, 10> data1;
    // 将所有元素设成给定值
    data1.fill(2);
    // 创建具有 10 个 int 类型的数组，初始化为默认值
    array<int, 10> data2{};
    // 前三个初始化为指定值，后面的都初始化成默认值
    array<int, 10> data3{1, 2, 3};
}
```

### 访问

```c++
#include <array>
#include <iostream>

using namespace std;

int main() {
    array<int, 10> ary{1, 2, 3, 4};

    // 没有做任何边界检査
    // cout << ary[22];
    // 检查越界索引值，会抛出 std::out_of_rang 异常
    // cout << ary.at(22);

    // 访问头尾
    cout << ary.front() + ary.back() << endl;
    // 返回容器底层用来存储元素的标准数组的地址
    cout << ary.data() << endl;
    // 模板函数 get<n>() 是一个辅助函数，它能够获取到容器的第 n 个元素
    cout << get<3>(ary) << endl;
    // 基于范围的循环
    for (int value: ary)
        cout << value << " ";
    cout << endl;

    // 判空和返回大小
    if (!ary.empty())
        cout << ary.size() << endl;
}
```

### 迭代器

数组模板定义了成员函数 begin() 和 end()，分别返回指向第一个元素和最后一个元素的下一个位置的随机访问迭代器。

```c++
#include <array>
#include <iostream>

using namespace std;

int main() {
    array<int, 10> ary{};
    // 迭代器对象是由 array 对象的成员函数 begin() 和 end() 返回
    auto first = ary.begin();
    array<int, 10>::iterator last = ary.end();
    while (first != last) {
        // 在循环中显式地使用迭代器来设置容器的值
        *first = 2;
        first++;
    }

    for (int i = 0; i < 10; ++i) {
        cout << ary[i] << " ";
    }
}
```

最好用全局的 begin() 和 end() 函数来从容器中获取迭代器，因为它们是通用的，first 和 last 可以像下面这样定义：

```c++
auto first = begin(ary);
array<int, 10>::iterator last = end(ary);
```

当迭代器指向容器中的一个特定元素时，它们没有保留任何关于容器本身的信息，所以我们无法从迭代器中判断，它是指向 array 容器还是指向 vector 容器。容器中的一段元素可以由迭代器指定，这让我们有了对它们使用算法的可能。

定义在 algorithm 头文件中的 generate() 函数模板，提供了用函数对象计算值、初始化一切元素的可能:

```c++
#include <array>
#include <iostream>
#include <algorithm>

using namespace std;

int main() {
    array<int, 10> ary{};
    int a{};
    int b{10};
    // generate() 的前两个参数分别是开始迭代器和结束迭代器，用来指定需要设置值的元素的范围
    // 第三个参数是一个 lambda 表达式。lambda 表达式以引用的方式捕获 b
    // mutable 使 lambda 表达式能够更新 a 局部副本的值，它是以值引用的方式捕获的。
    generate(begin(ary), end(ary), [a, &b]()mutable {
        return a++ + b;
    });
}
```

函数模板 iota() 可以做到用连续的递增值初始化一个数组容器:

```c++
#include <array>
#include <iostream>
#include <numeric>

using namespace std;

int main() {
    array<int, 10> ary{};
    // 前两个参数是迭代器，用来定义需要设置值的元素的范围。第三个参数是第一个元素要设置的值，通过递增运算生成了随后每一个元素的值
    iota(begin(ary), end(ary), 10);
}
```

容器定义了成员函数 cbegin() 和 cend()，它们可以返回 const 迭代器。当只想访问元素时，应该使用 const 迭代器。

### 元素比较

```c++
#include <array>
#include <iostream>

using namespace std;

int main() {
    array<int, 4> these{1, 2, 3, 4};
    array<int, 4> those{1, 2, 3, 4};
    array<int, 4> them{1, 3, 3, 2};

    // 对 ==,如果两个数组对应的元素都相等，会返回 true。对于 !=，两个数组中只要有一个元素不相等，就会返回 true。
    if (these == those) cout << "these and those are equal." << endl;
    if (those != them) cout << "those and them are not equal." << endl;
    if (those < them) cout << "those are less than them." << endl;

    // 只要它们存放的是相同类型、相同个数的元素，就可以将一个数组容器赋给另一个
    them = those;
}
```
