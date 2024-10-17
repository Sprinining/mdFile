---
title: vector
date: 2024-08-27 09:59:18 +0800
categories: [c++]
tags: [C++, C++ STL]
description: 
---
## vector

`vector<T>` 容器是包含 T 类型元素的序列容器，和 `array<T，N>` 容器相似，不同的是 `vector<T>` 容器的大小可以自动增长，从而可以包含任意数量的元素；因此类型参数 T 不再需要模板参数 N。只要元素个数超出 vector 当前容量，就会自动分配更多的空间。只能在容器尾部高效地删除或添加元素。

`vector<T>` 容器可以方便、灵活地代替数组。在大多数时候，都可以用 `vector<T>` 代替数组存放元素。只要能够意识到，`vector<T>` 在扩展容量，以 及在序列内部删除或添加元素时会产生一些开销；但大多数情况下，代码不会明显变慢。 为了使用 `vector<T>` 容器模板，需要在代码中包含头文件 vector。

### 创建

1. 容器中没有元素，所以没有分配空间，当添加第一个数据项时，会自动分配内存：

```c++
vector<int> values;
```

因为容器中没有元素，所以没有分配空间，当添加第一个数据项时，会自动分配内存。可以像下面这样通过调用 `reserve()` 来增加容器的容量：

```c++
// 设置了容器的内存分配，至少可以容纳 20 个元素
values.reserve(20);
```

如果当前的容量已经大于或等于 20 个元素，那么这条语句什么也不做。注意，调用 `reserve()` 并不会生成任何元素。values 容器这时仍然没有任何元素，直到添加了 20 个元素后，才会分配更多的内存。调用 `reserve()` 并不会影响现有的元素。

如果通过调用 `reserve()` 来增加内存，任何现有的迭代器，例如开始迭代器和结束迭代器，都会失效，所以需要重新生成它们。这是因为，为了增加容器的容量，`vector<T>` 容器的元素可能已经被复制或移到了新的内存地址。

2. 创建 vector 容器的另一种方式是使用初始化列表来指定初始值以及元素个数：

```c++
// 以初始化列表中的値作为元素初始值，生成有 3 个 int 的 vector 容器
vector<int> values{1, 2, 3};
```

3. 使用初始元素个数来生成 vector 容器：

```c++
// 容器开始时有 10 个元素，它们的默认初始值都为 0
// 生成容器时，同时指定元素个数，就能够减少空间额外分配的次数
vector<int> values(10);
```

4. 指定一个其他值作为默认值:

```c++
// 第二个参数指定了所有元素的初始值：10 个元素全都是 7
vector<int> values(10, 7);
```

5. 用元素类型相同的容器来初始化 `vector<T>` 容器

```c++
#include <vector>
#include <array>
#include <iostream>
#include <string>

using namespace std;

int main() {
    array<string, 5> words{"one", "two", "three", "four", "five"};
    // words_copy 被 words 数组容器中的元素初始化
    vector<string> words_copy{begin(words), end(words)};

    // 如果使用移动迭代器指定 words_copy 的初始化范围，words 中的元素将会从 words 移到 words_copy
    vector<string> words_copy2
            {make_move_iterator(begin(words)), make_move_iterator(end(words))};
    // words 数组中的字符串对象现在都是空字符串
}
```

### 容量和大小

vector 的容量大小，是指在不分配更多内存的情况下可以保存的最多元素个数，这时 可能有 20 个元素，也可能没有。vector 的大小是它实际所包含的元素个数，也就是有值的元素的个数。

![img](./vector.assets/2-1P912104441553.jpg)

```c++
#include <vector>
#include <iostream>

using namespace std;

int main() {
    vector<int> values{1, 2, 3};
    cout << "大小：" << values.size() << endl;
    cout << "容量：" << values.capacity() << endl;
    // 把元素的个数变为参数指定的值，所以会增加两个用默认值初始化的元素
    values.resize(5);
    // 将元素增加到第一个参数指定的个数，并用第二个参数初始化增加的新元素
    values.resize(7, 99);
    // 第三个 resize() 凋用将容器大小设为 6，小于当前元素的个数。
    // 当需要减小容器的大小时，会移除多余的元素，这就好像重复调用了几次 pop_back() 函数
    // 减少容器的大小不会影响容器的容量
    values.resize(6);

    // 1 2 3 0 0 99
    for (int i: values) {
        cout << i << " ";
    }
}
```

### 访问

```c++
#include <vector>
#include <iostream>

using namespace std;

int main() {
    vector<int> values{1, 2, 3};
    values[1] = 0;
    // 以当索引可能越界时，应该通过 at() 函数去使用这个元素
    values.at(2) = 3;

    // front() 和 back() 分別返回序列中第一个和最后一个元素的引用
    cout << values.front() << endl;
    // 返回的是引用，所以可以出现在赋值运算符的左边
    values.back() = 10;

    // 成员函数 data() 返回一个指向数组的指针
    // 一般来说，data() 返回 vector<T> 容器的 T* 类型的值
    int *pInt = values.data();
}
```

### 迭代器

### 添加

```c++
#include <vector>
#include <iostream>

using namespace std;

int main() {
    vector<int> values{1, 2, 3};
    values.push_back(12);
    // emplace back() 比 push_back() 更有效率
    // 可以在 emplace_back() 函数中使用尽可能多的参数，只要它们满足对象构造函数的要求
    values.emplace_back(13);

    // 1 2 3 12 13
    for (auto i: values) {
        cout << i << " ";
    }
}
```

### 插入

通过使用成员函数 emplace()，可以在 vector 序列中插入新的元素。对象会在容器中直接生成，而不是先单独生成对象，然后再把它作为参数传入。

```c++
#include <vector>
#include <iostream>
#include <string>

using namespace std;

int main() {
    vector<string> words{"first", "second"};
    // emplace() 的第一个参数是一个迭代器，它确定了对象生成的位置
    // 第一个参数后的参数，都作为插入元素的构造函数的参数传入。
    // 在开头插入
    auto iter = words.emplace(begin(words), 5, 'A');
    // 在第一个元素后面插入
    words.emplace(++iter, "$$$$");

    // AAAAA $$$$ first second
    for (const auto &i: words) {
        cout << i << " ";
    }
}
```

```c++
#include <vector>
#include <iostream>
#include <string>

using namespace std;

int main() {
    vector<string> words{"one", "three", "eight"};
    //  插入第二个参数指定的单个元素
    // 返回的迭代器指向被插入的元素 "two"
    auto iter = words.insert(++begin(words), "two");
    // "one" "two" "three" "eight"
    /*
     * 在使用同样参数的情况下，调用 insert() 没有调用 emplace() 高效。
     * 在 insert() 调用中，构造函数调用 string("two") 生成了一个对象，作为传入的第二个参数。
     * 在 emplace() 调用中，构造函数用第二个参数直接在容器中生成了字符串对象。
     */

    // 插入一个由第二个和第三个参数指定的元素序列
    string more[]{"five", "six", "seven"};
    iter = words.insert(--end(words), begin(more), end(more));
    // "one" "two" "three" "five" "six" "seven" "eight"

    // 在 vector 的末尾插入一个元素
    iter = words.insert(end(words), "ten");
    // "one" "two" "three" "five" "six" "seven" "eight" "ten"

    // 在插入点插入多个单个元素。第二个参数是第三个参数所指定对象的插入次数
    iter = words.insert(cend(words)-1, 2, "nine");
    // 返回的迭代器指向插入的第一个元素 "nine"
    // "one" "two" "three" "five" "six" "seven" "eight" "nine" "nine" "ten"

    //  在插入点，插入初始化列表指定的元素。第二个参数就是被插入元素的初始化列表
    // 返回的迭代器指向插入的第一个元素"twelve"
    iter = words.insert(end(words), {string {"twelve"},string {"thirteen"}});
    // "one" "two" "three" "five" "six" "seven" "eight" "nine" "nine" "ten" "twelve" "thirteen"

    for (const auto &i: words) {
        cout << i << " ";
    }
}
```

所有不在 vector 尾部的插入点都会有开销，需要移动插入点后的所有元素，从而为新元素空出位置。当然，如果插入点后的元素个数超出了容量，容器会分配更多的内存，这会增加更多额外开销。

### 删除

`pop_back()`、`clear()`、`shrink_to_fit()`：

```c++
#include <vector>
#include <algorithm>

using namespace std;

int main() {
    vector<int> data{1, 2, 3, 4, 5};
    // 1.将第二个元素和最后一个元素互相交换
    swap(*(begin(data) + 1), *(end(data) - 1));
    // vector: 1 5 3 4 2

    // 2.移除末尾元素，相当于从容器中移除了第二个元素，大小变成4，容量为5
    data.pop_back();
    // vector: 1 5 3 4

    // 3.移除所有元素，大小变成0，容量为5
    data.clear();
    // vector: 空

    // 大小1，容量5
    data.push_back(111);
    // 4.去掉容器中多余的容量，大小1，容量1
    data.shrink_to_fit();
    // vector: 111
}
```

`erase()`:

```c++
#include <vector>

using namespace std;

int main() {
    vector<int> data{1, 2, 3, 4, 5};
    // 1.删除第二个元素，会返回一个迭代器，它指向被删除元素后的一个元素
    auto iter = data.erase(begin(data) + 1);

    // 2.如果要移除一个元素序列，只需要传入两个迭代器，用来指定移除元素的范围
    // 第二个迭代器指向这段元素末尾的下一个位置
    // 删除前两个元素，返回被删除元素后的位置
    iter = data.erase(begin(data), begin(data) + 2);
}
```

`remove()`:

```c++
#include <vector>
#include <algorithm>
#include <string>

using namespace std;

int main() {
    vector<string> words{"one", "none", "some", "all", "none", "most", "many"};
    // 在头两个参数指定的元素范围内，移除了所有匹配 remove() 的第三个参数 string("none") 的元素
    auto iter = remove(begin(words), end(words), "none");

    //  remove() 操作后输出 words 中的元素，只会输出前 5 个元素。
    //  尽管 size() 返回的值仍然是 7，而且最后两个元素仍然存在，但是它们被替换成了空字符串对象。
    //  为了摆脱这些多余的元素，可以使用成员函数 erase() 删除后面的空字符串对象
    words.erase(iter, end(words));
}
```

### reserve()、resize() 区别

| **成员方法** | **功能**                                                     |
| ------------ | ------------------------------------------------------------ |
| capacity()   | 告诉我们当前 vector 容器总共可以容纳多少个元素。如果想知道当前 vector 容器有多少未被使用的存储空间，可以通过 capacity()-size() 得知。注意，如果 size() 和 capacity() 返回的值相同，则表明当前 vector 容器中没有可用存储空间了，这意味着，下一次向 vector 容器中添加新元素，将导致 vector 容器扩容。 |
| size()       | 告诉我们当前 vector 容器中已经存有多少个元素，但仅通过此方法，无法得知 vector 容器有多少存储空间。 |
| reserve(n)   | 强制 vector 容器的容量至少为 n。注意，如果 n 比当前 vector 容器的容量小，则该方法什么也不会做；反之如果 n 比当前 vector 容器的容量大，则 vector 容器就会扩容。 |

- vector 的 `reserve` 增加了 vector 的 `capacity`，但是它的 `size` 没有改变。而 `resize` 改变了 vector 的 `capacity` 同时也增加了它的 `size`。
- `reserve` 是容器预留空间，但在空间内不真正创建元素对象，所以在没有添加新的对象之前，不能引用容器内的元素。加入新的元素时，要调用 `push_back()` 等函数。
- `resize` 是改变容器的大小，且在创建对象，因此，调用这个函数之后，就可以引用容器内的对象了，因此当加入新的元素时，用 `operator[]` 操作符，或者用迭代器来引用元素对象。此时再调用 `push_back()` 函数，是加在这个新的空间后面的。
- 两个函数的参数形式也有区别的，`reserve` 函数之后一个参数，即需要预留的容器的空间；`resize` 函数可以有两个参数，第一个参数是容器新的大小，第二个参数是要加入容器中的新元素，如果这个参数被省略，那么就调用元素对象的默认构造函数。
