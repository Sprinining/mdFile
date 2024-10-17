---
title: list
date: 2024-08-20 07:23:36 +0800
categories: [c++]
tags: [C++, C++ STL]
description: 
---
## list

`list<T>` 容器模板定义在 list 头文件中，是 T 类型对象的双向链表。

list 容器具有一些 vector 和 deque 容器所不具备的优势，它可以在常规时间内，在序列已知的任何位置插入或删除元素。这是我们使用 list，而不使用 vector 或 deque 容器的主要原因。

list 的缺点是无法通过位置来直接访问序列中的元素，也就是说，不能索引元素。为了访问 list 内部的一个元素，必须一个一个地遍历元素，通常从第一个元素或最后一个元素开始遍历。

![img](./list.assets/2-1P912134314345.jpg)

可以用和其他序列容器相同的方式，来获取 list 容器的迭代器。因为不能随机访问 list 中的元素，获取到的迭代器都是双向迭代器。

以 list 为参数，调用 begin() 可以得到指向 list 中第一个元素的迭代器。通过调用 end()，可以得到一个指向最后一个元素下一个位置的迭代器，因此像其他序列容器一样，可以用它们来指定整个范围的元素。

### 创建

```c++
#include <string>
#include <list>

using namespace std;

int main() {
    // list 容器的构造函数的用法类似于 vector 或 deque 容器
    list<string> words;
    // 带有给定数量的默认元素的列表
    list<string> sayings{10};
    // 生成一个包含给定数量的相同元素的列表
    list<double> values(10, 3.14);
    // 生成一个现有 list 容器的副本
    list<double> save_values{values};
    // 用另一个序列的开始和结束迭代器所指定的一段元素，来构造 list 容器的初始化列表
    // 因为 list 容器的 begin() 和 end() 函数返回的都是双向迭代器，所以不能用它们加减整数。
    // 修改双向迭代器的唯一方式是使用自增或自减运算符。
    list<double> samples{++cbegin(values), --cend(values)};
}
```

可以通过调用 list 容器的成员函数 `size()` 来获取它的元素个数。也可以使用它的 `resize()` 函数来改变元素个数。如果 `resize()` 的参数小于当前元素个数，会从尾部开始删除多余的元素。如果参数比当前元素个数大，会使用所保存元素类型的默认构造函数来添加元素。

### 增加和插入

```c++
#include <string>
#include <list>
#include <vector>
#include <iostream>

using namespace std;

int main() {
    list<int> data(4, 0);
    // 1.在迭代器指定的位置插入一个新的元素
    data.insert(++begin(data), 3);
    // list: 0 3 0 0 0

    // 2.在给定位置插入几个相同元素的副本
    auto iter = begin(data);
    // 使用定义在 iterator 头文件中的全局函数 advance()，将迭代器增加 3。只能增加或减小双向迭代器。
    // 因为迭代器不能直接加 3，所以 advance() 会在循环中自增迭代器。
    advance(iter, 3);
    // 第一个参数是用来指定插入位置的迭代器，第二个参数是被插入元素的个数，第三个参数是被重复插入的元素
    data.insert(iter, 3, 88);
    // list: 0 3 0 88 88 88 0 0

    // 3.将一段元素插入到data列表
    vector<int> numbers(2, 5);
    data.insert(--(--end(data)), cbegin(numbers), cend(numbers));
    // list: 0 3 0 88 88 88 5 5 0 0
}
```

```c++
#include <string>
#include <list>
#include <vector>
#include <iostream>

using namespace std;

int main() {
    list<string> names{"a", "b", "c", "d"};
    // 1.参数作为对象被添加
    names.push_front("e");
    names.push_back("f");
    // 2.成员函数 emplace_front() 和 emplace_back() 可以做得更好
    names.emplace_front("g");
    names.emplace_back("h");
    // names: g e a b c d f h

    string name("x");
    names.emplace_back(std::move(name));
    // move() 函数将 name 的右值引用传入 emplace_back() 函数。
    // 这个操作执行后，names 变为空，因为它的内容已经被移到 list 中.
    cout << "name = " << name << endl;
    names.emplace(++begin(names), "z");
    // names: g z e a b c d f h x 
}
```

### 删除

对于 list 的成员函数 clear() 和 erase()，它们的工作方式及效果，和前面的序列容器相同。

```c++
#include <string>
#include <list>

using namespace std;

int main() {
    list<int> numbers{2, 5, 2, 3, 6, 7, 8, 2, 9};
    // 移除和参数匹配的元素
    numbers.remove(2);
    // numbers: 5 3 6 7 8 9

    // 删除偶数，这里的参数是一个 lambda 表达式，但也可以是一个函数对象
    numbers.remove_if([](int n) { return n % 2 == 0; });
    // numbers: 5 3 7 9

    list<string> words{"one", "two", "two", "two", "three", "two", "four", "four"};
    // 移除连续的重复元素，只留下其中的第一个
    words.unique();
    // words: one two three two four
    // 可以在对元素进行排序后，再使用 unique()，这样可以保证移除序列中全部的重复元素
}
```

### 排序

sort() 函数模板定义在头文件 algorithm 中，要求使用随机访问迭代器。但 list 容器并不提供随机访问迭代器，只提供双向迭代器，因此不能对 list 中的元素使用 sort() 算法。但是，还是可以进行元素排序，因为 list 模板定义了自己的 sort() 函数。sort() 有两个版本：无参 sort() 函数将所有元素升序排列。第二个版本的 sort() 接受一个函数对象或 lambda 表达式作为参数，这两种参数都定义一个断言用来比较两个元素。

```c++
list<string> names{"a", "b", "c", "d"};
// names.sort(greater<string>());
// 简洁版的函数对象可以接受任何类型的参数，使用完美转发 (perfect forwarding) 可以避免不必要的参数拷贝。
// 因此，完美转发总是会快很多，因为被比较的参数会被移动而不是复制到函数中。
names.sort(std::greater<>());
// names: d c b a
```

在必要时可以将自定义的函数对象传给断言来对 list 排序。尽管对一般对象来说，并不需要这样。如果为自己的类定义了 operator()，然后就可以继续使用 greater<>。 当我们需要比较非默认类型时，就需要一个函数对象。

```c++
#include <string>
#include <list>

using namespace std;

class my_greater {
public:
    bool operator()(const string &s1, const string &s2) {
        if (s1[0] == s2[0])
            // 将相同初始字符的字符串按长度排序
            return s1.length() > s2.length();
        else
            return s1 > s2;
    }
};

int main() {
    list<string> names{"Hugo", "Hannah", "Jane", "Jim", "Jules", "Janet", "Ann", "Alan"};
    // 1.函数对象
    // names.sort(my_greater());
    // 2.lambda 表达式
    names.sort([](const string &s1, const string &s2) {
        if (s1[0] == s2[0])
            return s1.length() > s2.length();
        else
            return s1 > s2;
    });
    // names: Jules Janet Jane Jim Hannah Hugo Alan Ann
}
```

### 合并

list 的成员函数 merge() 以另一个具有相同类型元素的 list 容器作为参数。两个容器中的元素都必须是升序。参数 list 容器中的元素会被合并到当前的 list 容器中。

```c++
#include <string>
#include <list>
#include <iostream>

using namespace std;

int main() {
    // 1.两个容器中的元素都必须是升序
    list<int> to_values{2, 4, 6, 14};
    list<int> from_values{-2, 1, 7, 10};
    to_values.merge(from_values);
    // to_values: -2 1 2 4 6 7 10 14

    // 没有元素了
    cout << from_values.empty();

    // 2.提供一个比较函数作为该函数的第二个参数，用来在合并过程中比较元素
    list<string> my_words{"three", "six", "eight"};
    list<string> your_words{"seven", "four", "nine"};
    // 字符串对象比较函数是由 lambda 表达式定义的，这个表达式只比较第一个字符。
    auto comp_str = [](const string &s1, const string &s2) { return s1[0] < s2[0]; };
    my_words.sort(comp_str); //"eight" "six" "three"
    your_words.sort(comp_str);  //"four" "nine" "seven"
    my_words.merge(your_words, comp_str); // "eight" "four" "nine" "six" "seven" "three"
}
```

list 节点在内存中的位置不会改变；只有链接它们的指针变了。在合并的过程中，两个容器中的元素使用 operator() 进行比较。

list 容器的成员函数 splice() 有几个重载版本。这个函数将参数 list 容器中的元素移动到当前容器中指定位置的前面。可以移动单个元素、一段元素或源容器的全部元素。

```c++
#include <string>
#include <list>

using namespace std;

int main() {
    list<string> my_words{"three", "six", "eight"};
    list<string> your_words{"seven", "four", "nine"};
    // 1.移动单个元素
    // 第一个参数是指向目的容器的迭代器。
    // 第二个参数是元素的来源。
    // 第三个参数是一个指向源list容器中被粘接元素的迭代器，它会被插入到第一个参数所指向位置之前。
    my_words.splice(++begin(my_words), your_words, ++begin(your_words));
    // my_words: "three", "four", "six", "eight"
    // your_words: "seven", "nine"

    // 2.当要粘接源 list 容器中的一段元素时，第 3 和第 4 个参数可以定义这段元素的范围
    // 将 my_words 从第二个元素直到末尾的元素，粘接到 your_words 的第二个元素之前
    your_words.splice(++begin(your_words), my_words,
                      ++begin(my_words), end(my_words));
    // my_words: "three"
    // your_words:"seven", "four", "six", "eight","nine"

    // 3.将 your_words 的全部元素粘接到 my_words 中
    // your_words 的所有元素被移到了 my_words 的第一个元素 "three" 之前，your_words 会变为空
    my_words.splice(begin(my_words), your_words);
    // 即使 your_words 为空，也仍然可以向它粘接元素
    // 第一个参数也可以是 begin (your_words)，因为当容器为空时，它也会返回一个结束迭代器。
    your_words.splice(end(your_words), my_words);
}
```

### 访问

list 的成员函数 front() 和 back()，可以各自返回第一个和最后一个元素的引用。在空 list 中调用它们中的任意一个，结果是未知的，因此不要这样使用。可以通过迭代器的自增或自减来访问 list 的内部元素。

begin() 和 end() 分别返回的是指向第一个和最后一个元素下一个位置的双向迭代器。rbegin() 和 rend() 函数返回的双向迭代器，可以让我们逆序遍历元素。因为可以对 list 使用基于范围的循环，所以当我们想要处理所有元素时，可以不使用迭代器。
