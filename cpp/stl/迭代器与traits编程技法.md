## 迭代器与 traits 编程技法

迭代器（Iterator）是 STL 的灵魂，它是一种通用指针机制，提供统一的方式来遍历容器中的元素。它允许算法与容器解耦。你可以将算法用于任何支持相同迭代器接口的容器上。

在 C++ STL 中，迭代器是一种对象，它重载了解引用 `*` 和自增 `++` 操作符，使得用户可以使用它像指针一样访问和操作容器中的元素。

例如：

```cpp
vector<int> vec = {1, 2, 3};
vector<int>::iterator it = vec.begin();
while (it != vec.end()) {
    cout << *it << endl;
    ++it;
}
```

从接口看，迭代器非常像指针。实际上，原始指针也可以作为迭代器。

### 自定义迭代器的实现

```cpp
// 链表节点定义，双向链表节点结构
template <typename T>
struct ListNode {
    T data;                  // 节点存储的数据
    ListNode* prev;          // 指向前一个节点的指针
    ListNode* next;          // 指向后一个节点的指针
};

// 迭代器定义，用于遍历 ListNode 构成的双向链表
template <typename T>
struct ListIterator {
    // 类型别名定义（可供 traits 萃取使用）
    typedef ListIterator<T>           self;         // 自身类型
    typedef T                         value_type;   // 元素类型
    typedef T*                        pointer;      // 指针类型
    typedef T&                        reference;    // 引用类型

    ListNode<T>* node; // 当前迭代器所指的节点指针

    // 构造函数，允许传入一个节点指针，默认为 nullptr
    ListIterator(ListNode<T>* x = nullptr) : node(x) {}

    // 解引用操作符，返回当前节点的数据的引用
    reference operator*() const { return node->data; }

    // 成员访问操作符，返回数据的指针
    pointer operator->() const { return &(operator*()); }

    // 前置递增，移动到下一个节点
    self& operator++() {
        node = node->next;
        return *this;
    }

    // 后置递增，先保存当前迭代器副本，再移动到下一个节点
    self operator++(int) {
        self tmp = *this;    // 保存当前状态
        ++(*this);           // 调用前置递增
        return tmp;          // 返回旧状态
    }

    // 判断两个迭代器是否指向相同节点
    bool operator==(const self& x) const { return node == x.node; }

    // 判断两个迭代器是否指向不同节点
    bool operator!=(const self& x) const { return node != x.node; }
};
```

- 这个迭代器能在链表上正常使用，支持解引用、前置与后置递增、比较等。
- 但问题来了 —— 这个迭代器的“型别信息”很不清晰，完全靠用户定义，如果模板算法中需要判断它是不是双向迭代器、是否支持随机访问，就很难判断。

#### 缺陷

自定义的迭代器，标准库压根不知道它是什么类型！

- 是 `input_iterator`？（只能 ++）
- 还是 `bidirectional_iterator`？（++ 和 --）
- 还是 `random_access_iterator`？（支持 +=、-=）

标准库无法判断，只能靠“显式提供型别信息”。

看下面这个模板函数（用到了 `advance`）：

```cpp
template<typename Iterator>
void walk_n_steps(Iterator it, int n) {
    std::advance(it, n);
    std::cout << *it << std::endl;
}
```

把自定义迭代器传进去，编译器内部的 `advance()` 想 dispatch 到合适的重载实现（input/bidirectional/random）时就懵了：

- `ListIterator<T>` 虽然是双向的，但你没告诉我！
- 没有 `iterator_category` 信息，没法做 dispatch！

自定义迭代器如果没有提供类型信息（iterator traits），会导致 STL 算法如 `advance()`、`distance()` 无法识别其能力，失去泛型编程的意义。

#### 解决办法

- 在迭代器内部提供型别信息（嵌套 typedef）
- 偏特化 `iterator_traits`

### 为迭代器设计相应的型别（type traits）

C++ 算法库中的很多算法，如 `distance()` 和 `advance()`，需要知道迭代器的类型（如输入、双向、随机访问），但普通模板参数是无法获得这些“类型特性”的。

例如：

```cpp
template <typename Iterator>
void advance(Iterator& it, int n);
```

我们希望 `advance()` 能根据迭代器类型选择不同策略：

- 对于随机访问迭代器，可直接 `it += n;`
- 对于双向迭代器，只能循环 n 次 `++it;`

问题在于：如何从一个类型 `Iterator` 得知它是哪一类迭代器？我们不能写死 if 判断类型名。

这时就需要为迭代器定义“内嵌型别”（iterator traits）。

### Traits 编程技巧的引入（重点：内嵌型别声明）

SGI STL 的解决方式是：**为每个迭代器类型声明五个内嵌型别**，供模板萃取使用。这就是我们熟悉的：

```cpp
typedef iterator_category 迭代器种类标签
typedef value_type        元素类型
typedef difference_type   两迭代器差值类型（如 ptrdiff_t）
typedef pointer           指针类型
typedef reference         引用类型
```

例如：

```cpp
template <typename T>
struct ListIterator {
    typedef bidirectional_iterator_tag iterator_category;
    typedef T                          value_type;
    typedef ptrdiff_t                  difference_type;
    typedef T*                         pointer;
    typedef T&                         reference;
    ...
};
```

**这五个内嵌型别就是 traits 萃取机制的核心**。它们使得 STL 算法能够从迭代器类型中提取出关键元信息，做出“策略选择”。

STL 中 distance 的实现示例：

```cpp
// 输入迭代器版本的 distance：用于非随机访问迭代器
template <typename InputIterator>
inline typename iterator_traits<InputIterator>::difference_type
__distance(InputIterator first, InputIterator last, input_iterator_tag) {
    // 1. 声明差值变量 n，类型由 iterator_traits 推导
    typename iterator_traits<InputIterator>::difference_type n = 0;
    // 2. 一步步前进迭代器，直到走到 last
    while (first != last) {
        ++first;  // 前进一格
        ++n;      // 记录走了几格
    }
    // 3. 返回总步数
    return n;
}

// 随机访问迭代器版本的 distance：可以用减法直接计算距离
template <typename RandomAccessIterator>
inline typename iterator_traits<RandomAccessIterator>::difference_type
__distance(RandomAccessIterator first, RandomAccessIterator last, random_access_iterator_tag) {
    // 对于随机访问迭代器（如指针、vector::iterator），直接用减法
    return last - first;
}

// 外层通用 distance()，根据迭代器类型调用正确的内部实现
template <typename Iterator>
inline typename iterator_traits<Iterator>::difference_type
distance(Iterator first, Iterator last) {
    // 根据迭代器的 iterator_category（通过 traits）选择具体实现
    return __distance(first, last, typename iterator_traits<Iterator>::iterator_category());
}
```

- `distance(first, last)` 返回从 `first` 到 `last` 之间有多少步（元素）。
- **前两个函数通过第三个参数的不同类型（tag dispatching 技术）实现的函数重载**，从而选择最优算法路径。

#### `iterator_traits` 是什么？

`iterator_traits<Iterator>` 是标准库提供的类型萃取器（Traits），可以自动提取用户定义迭代器中的：

- `value_type`
- `difference_type`
- `pointer`
- `reference`
- `iterator_category`

在这里主要用的是：

```cpp
typename iterator_traits<Iterator>::difference_type
typename iterator_traits<Iterator>::iterator_category
```

#### `iterator_category` 起什么作用？

通过传入不同的 `iterator_category` 类型参数，编译器根据类型的不同选择对应的函数重载版本，从而决定了底层 `__distance` 调用哪个实现：

- 如果是 `input_iterator_tag`，调用第一个版本：只能慢慢走，时间复杂度 **O(n)**
- 如果是 `random_access_iterator_tag`，调用第二个版本：直接减法，时间复杂度 **O(1)**

所以这就是 **traits 编程技法** 的威力：**让泛型算法根据类型能力自动做“函数调度”优化**。

### Traits 萃取机制的实现细节

SGI STL 实现了一个 `iterator_traits` 模板结构体，对任意迭代器都可以通过 `iterator_traits<Iterator>` 获取其五个型别。

```cpp
template <typename Iterator>
struct iterator_traits {
    typedef typename Iterator::iterator_category iterator_category;
    typedef typename Iterator::value_type        value_type;
    typedef typename Iterator::difference_type   difference_type;
    typedef typename Iterator::pointer           pointer;
    typedef typename Iterator::reference         reference;
};
```

#### 特化版本：为原生指针（T*）提供 traits

因为 `int*` 没有 `::value_type` 这些内嵌型别，所以必须特化：

```cpp
// 针对指针类型的 iterator_traits 偏特化
template <typename T>
struct iterator_traits<T*> {
    // 指针被视为随机访问迭代器，支持快速访问和跳转
    typedef random_access_iterator_tag iterator_category;

    // 迭代器指向的元素类型
    typedef T                          value_type;

    // 迭代器之间的距离类型（通常是带符号整型）
    // 以 C++ 内建的 ptrdiff_t 作为原生指针的 difference_type
    typedef ptrdiff_t                  difference_type;

    // 指针类型本身（迭代器的指针类型）
    typedef T*                         pointer;

    // 迭代器解引用后得到的引用类型
    typedef T&                         reference;
};

// 针对 const 指针类型的 iterator_traits 偏特化
template <typename T>
struct iterator_traits<const T*> {
    // const 指针同样是随机访问迭代器
    typedef random_access_iterator_tag iterator_category;

    // 元素类型仍是 T（不含 const）
    typedef T                          value_type;

    // 迭代器距离类型
    typedef ptrdiff_t                  difference_type;

    // const 指针类型
    typedef const T*                   pointer;

    // 解引用得到 const 引用
    typedef const T&                   reference;
};
```

- 这是针对**原生指针**（`T*` 和 `const T*`）的 `iterator_traits` 偏特化版本。
- 原生指针在 STL 中被视为**随机访问迭代器**，因为它们支持快速指针运算（如 `ptr + n`）。
- `iterator_category` 明确指出指针迭代器的类别，方便 STL 算法做特化优化。
- 其他类型别名为 STL 提供必要的类型信息，支持泛型编程。

### 自定义一个支持 traits 的迭代器

```cpp
struct MyIter {
    typedef random_access_iterator_tag iterator_category;
    typedef int                        value_type;
    typedef ptrdiff_t                  difference_type;
    typedef int*                       pointer;
    typedef int&                       reference;

    int* ptr;
    MyIter(int* p) : ptr(p) {}
    reference operator*() const { return *ptr; }
    MyIter& operator++() { ++ptr; return *this; }
    bool operator!=(const MyIter& rhs) const { return ptr != rhs.ptr; }
};
```

然后在算法中使用：

```cpp
template <typename Iter>
void print_iter(Iter first, Iter last) {
    // 通过 iterator_traits 提取迭代器指向的元素类型，并声明 sum 变量
    // typename 关键字告诉编译器 value_type 是一个类型，而不是静态成员
    typename iterator_traits<Iter>::value_type sum = 0;

    // 遍历区间 [first, last)，累加每个元素的值
    while (first != last) {
        sum += *first;  // 解引用迭代器获得元素，累加到 sum
        ++first;        // 迭代器前进到下一个元素
    }

    // 输出累加结果
    cout << "sum = " << sum << endl;
}
```

### iterator_traits 模板的五个型别详解

#### `iterator_category` —— 迭代器类别标签

在 STL 中，迭代器被分为五大类，每一类表示该迭代器支持的操作能力。这五类是通过**空类类型**来区分的，每类都继承自更“基础”的迭代器类别，形成一种**继承层次结构**，用于在模板中做类型分发（function overloading dispatching）。

##### 五种迭代器类别（从弱到强）

| 迭代器类别                   | 能力描述                                         | 可用于算法                                    | 时间复杂度 | 典型容器                          |
| ---------------------------- | ------------------------------------------------ | --------------------------------------------- | ---------- | --------------------------------- |
| `input_iterator_tag`         | 只读，只能单向移动一次，不可回退                 | `find`, `accumulate`, `distance`（线性）等    | O(n)       | `istream_iterator` 等输入流迭代器 |
| `output_iterator_tag`        | 只写，只能单向移动一次                           | `copy`, `fill` 等                             | O(n)       | `ostream_iterator` 等输出流迭代器 |
| `forward_iterator_tag`       | 可读可写，支持多次读取，每次都能 forward（向前） | 所有 input 算法 + 多次遍历                    | O(n)       | `slist`                           |
| `bidirectional_iterator_tag` | 可 forward 和 backward（前进与后退）             | `reverse`, `list::rbegin` 等                  | O(n)       | `list`, `map`, `set`              |
| `random_access_iterator_tag` | 所有上面功能 + 随机跳转、支持 `[]`、`+`、`-`     | `sort`, `binary_search`, `distance`（O(1)）等 | O(1) 跳转  | `vector`, `deque`, 原始指针       |

##### 迭代器类别的继承关系图

```cpp
// 这是五种迭代器的继承体系
struct input_iterator_tag {};
struct output_iterator_tag {};
struct forward_iterator_tag : public input_iterator_tag {};
struct bidirectional_iterator_tag : public forward_iterator_tag {};
struct random_access_iterator_tag : public bidirectional_iterator_tag {};
// C++20 还定义了 contiguous_iterator_tag : public random_access_iterator_tag
```

这种层次结构允许我们通过 `iterator_category` 的类型进行模板**函数重载**选择（如 `distance()` 或 `advance()`），实现根据迭代器能力自动调用最优版本。例如：

```cpp
template <typename Iterator>
typename iterator_traits<Iterator>::difference_type
distance(Iterator first, Iterator last) {
    return __distance(first, last, typename iterator_traits<Iterator>::iterator_category());
}
```

举个例子：指针的 `iterator_category`

```cpp
template <typename T>
struct iterator_traits<T*> {
    typedef random_access_iterator_tag iterator_category;
    ...
};
```

所以裸指针支持的是**随机访问迭代器（Random Access Iterator）**，因此 `distance(p1, p2)` 会直接调用 O(1) 的版本：`return p2 - p1;`。

##### C++20 新增 `contiguous_iterator_tag`

- 继承自 `random_access_iterator_tag`，表示它具备随机访问迭代器的所有能力。
- 不仅支持随机访问，还保证迭代器所指元素在内存中是**连续排列的**。
- **用途**：
  - 用于标识类似裸指针、`std::span`、以及其它保证内存连续存储的数据结构的迭代器。
  - 有利于优化，例如能够直接对底层内存块进行快速拷贝或批量操作。

##### 消除单纯传递调用的函数

如果我们对每种迭代器都要提供一个 `advance` 重载，比如 `input_iterator_tag`、`forward_iterator_tag`、`bidirectional_iterator_tag`，而其中某些版本只是单纯调用更基础的版本，会写出类似这样的代码：

```cpp
// 针对 input_iterator_tag
template <typename InputIterator>
void __advance(InputIterator& i, int n, input_iterator_tag) {
    while (n--) ++i;
}

// 针对 forward_iterator_tag
template <typename ForwardIterator>
void __advance(ForwardIterator& i, int n, forward_iterator_tag) {
    // forward_iterator 只要用 input_iterator 的版本就够了
    __advance(i, n, input_iterator_tag());  // 显式调用更基础版本
}
```

**forward 版本的 advance 实际只是调用 input 的 advance —— 是“单纯的传递调用”**。这种写法既冗余又不优雅。

使用标签继承体系的好处就是我们只需要为 `input_iterator_tag` 编写基础版本：

```cpp
template <typename InputIterator>
void __advance(InputIterator& i, int n, input_iterator_tag) {
    while (n--) ++i;
}
```

然后，对于 `forward_iterator_tag` 的情况，不用额外写版本，**因为它是 `input_iterator_tag` 的派生类**，所以这个函数就能被选中（通过参数匹配 + 类型转换规则）。

#### `value_type` —— 迭代器指向的元素类型

- 指明迭代器所指向元素的类型。
- 在泛型算法中定义变量或计算时，用它确定元素类型，保证类型安全。

```cpp
typedef int value_type;  // 迭代器指向的是 int 类型
```

#### `difference_type` —— 迭代器之间的距离类型

- 用来表示两个迭代器之间的距离（差值）。
- 类型通常是有符号整数，比如 `ptrdiff_t`。
- 算法中用它表示元素数量或者距离，支持负数表示反向距离。

#### `pointer` —— 指向迭代器所指元素的指针类型

- 代表迭代器元素的指针类型。
- 泛型代码中，若需要用指针操作元素，使用该类型即可。

```cpp
typedef int* pointer;  // 指向 int 的指针
```

#### `reference` —— 迭代器解引用得到的引用类型

- 代表迭代器解引用后得到的引用类型。
- 有些迭代器解引用返回普通引用，有些返回代理类或智能引用，统一用该类型方便泛型处理。

```cpp
typedef int& reference;  // 解引用得到 int 的引用
```

##### `*p` 的类型设计

- 前提：`value_type` 是 `T`
- `*p` 的类型本质上就是迭代器的 `reference` 类型

我们将迭代器分为两种：**mutable（可写）** 和 **constant（只读）**，然后逐一讨论。

###### 可写迭代器（mutable iterators）

这种迭代器支持修改所指元素，即 `*p = new_value` 是合法的。

如果定义：

```cpp
value_type = T
reference = T
```

那么：

```cpp
*p = 5;   // 错误！因为 *p 是一个 T 类型的值（右值）
```

右值不能作为赋值的目标，所以这不合法。
而如果定义为：

```cpp
reference = T&
```

就变成了左值引用，`*p` 代表容器中真实的元素，可以被修改，这才是正确的行为。

正确写法：

```cpp
value_type = T
reference = T&
*p 的类型 → T&（左值引用）
```

###### 只读迭代器（constant iterators）

这种迭代器只能读，不能改，`*p = ...` 是不合法的。

如果定义：

```cpp
reference = const T
```

这虽然看起来只读，但 `const T` 是一个值类型，是右值，不能持久地绑定容器中元素。

正确的写法是：

```cpp
reference = const T&
```

这表示是一个 **只读左值引用**，既可以保证数据不被修改，又不会造成复制开销。

正确写法：

```cpp
value_type = T
reference = const T&
*p 的类型 → const T&（只读左值引用）
```

###### 小结

| 迭代器类型           | `value_type` | `reference` | `*p` 的类型 | 是否可修改 |
| -------------------- | ------------ | ----------- | ----------- | ---------- |
| 可写（mutable）      | `T`          | `T&`        | `T&`        | 可以修改   |
| 只读（constant）     | `T`          | `const T&`  | `const T&`  | 不可修改   |
| 输入迭代器（只拷贝） | `T`          | `T`         | `T`         | 不可修改   |

在 C++ 中，函数返回左值必须通过引用（`T&` / `const T&`），因此当迭代器是 mutable 时，`*p` 的类型必须是 `T&`；当是 constant 时，`*p` 的类型必须是 `const T&`，不能是 `T` 或 `const T`。

### std::iterator

早期的 C++（特别是 C++98 到 C++14）提供了一个叫 `std::iterator` 的类模板，**用于帮助用户自定义迭代器时，简化类型定义（traits）信息的编写**。

不过注意：**它已在 C++17 被弃用，并在 C++20 被移除**，现在更推荐手动定义 typedef 或使用 `std::iterator_traits` 推导。

#### 语法

```cpp
namespace std {
template <
    class Category,        // 迭代器类别标签
    class T,               // value_type
    class Distance = ptrdiff_t,
    class Pointer = T*,
    class Reference = T&
>
struct iterator {
    typedef T         value_type;
    typedef Distance  difference_type;
    typedef Pointer   pointer;
    typedef Reference reference;
    typedef Category  iterator_category;
};
}
```

如果想自定义一个迭代器类，可以这样写：

```cpp
template <typename T>
struct MyIter : std::iterator<std::random_access_iterator_tag, T> {
    T* ptr;

    MyIter(T* p) : ptr(p) {}

    T& operator*() const { return *ptr; }
    MyIter& operator++() { ++ptr; return *this; }
    bool operator!=(const MyIter& rhs) const { return ptr != rhs.ptr; }
};
```

好处是不需要自己再手动写这些 typedef。

#### 为啥被弃用？

在 C++17 和 C++20 中，`std::iterator` 被正式弃用并删除，原因如下：

| 原因               | 说明                                                      |
| ------------------ | --------------------------------------------------------- |
| 不够灵活           | 强制从 `std::iterator` 继承，不符合 STL 模板设计原则      |
| 多继承副作用       | 继承可能引入额外复杂性，比如二义性等                      |
| 不适用于所有场景   | 比如某些 proxy iterator 可能不适合这种模板                |
| 更推荐 traits 推导 | 使用 `iterator_traits` 能更灵活地处理所有类型，包括指针等 |

#### 替代写法（现代做法）

推荐自己手动定义 typedef（或 using）：

```cpp
template <typename T>
struct MyIter {
    using value_type        = T;
    using pointer           = T*;
    using reference         = T&;
    using difference_type   = std::ptrdiff_t;
    using iterator_category = std::random_access_iterator_tag;

    T* ptr;
    MyIter(T* p) : ptr(p) {}
    reference operator*() const { return *ptr; }
    MyIter& operator++() { ++ptr; return *this; }
    bool operator!=(const MyIter& rhs) const { return ptr != rhs.ptr; }
};
```

### __type_traits

`__type_traits` 是 SGI STL 中一个用于类型萃取（type traits）的结构体模板，核心目的是在编译期判断某种类型是否具备某些“编译器层面”的特性，从而帮助 STL 进行**代码路径优化**，比如：

- 拥有 trivial（平凡）构造函数
- 拥有 trivial 拷贝构造函数
- 拥有 trivial 析构函数
- 是 POD（Plain Old Data）类型

#### 为何需要 `__type_traits`

在 STL 容器如 `vector` 中，当元素类型 `T` 是个普通类型（比如 int、char）时，拷贝/构造/析构等操作可以走最短路径（例如用 `memcpy` 直接复制），但当 `T` 是类类型（例如含虚函数、用户自定义析构函数）时，必须一个一个调用构造函数或析构函数。

但 `vector` 之类是模板，编译期并不知道 `T` 是什么，因此必须有机制判断 `T` 的特性 —— 这就是 `__type_traits` 的作用。

#### 核心结构：`__type_traits`

```cpp
// __type_traits 模板结构体：用于萃取某类型 T 的五项“类型特性”
// 默认版本下，所有特性都被标记为 __false_type（保守处理）
template <typename T>
struct __type_traits {
    // 是否具有 trivial（平凡的）默认构造函数
    // 平凡构造函数的意思是该构造函数什么都不做（比如 int a;）
    typedef __false_type has_trivial_default_constructor;

    // 是否具有 trivial（平凡的）拷贝构造函数
    // 如果可以通过 memcpy 安全地复制该对象，则为平凡拷贝构造
    typedef __false_type has_trivial_copy_constructor;

    // 是否具有 trivial（平凡的）赋值操作符
    // 判断是否可以用简单赋值替代 operator=
    typedef __false_type has_trivial_assignment_operator;

    // 是否具有 trivial（平凡的）析构函数
    // 如果对象析构时无需调用自定义析构函数（比如 int），则为平凡析构
    typedef __false_type has_trivial_destructor;

    // 是否是 POD 类型（Plain Old Data）
    // POD 意味着类型结构简单，无继承/虚函数等，可以整体按字节复制
    typedef __false_type is_POD_type;
};
```

默认情况下，认为所有属性都是 `__false_type`。

特化版本举例：

```cpp
template <>
struct __type_traits<int> {
    typedef __true_type has_trivial_default_constructor;
    typedef __true_type has_trivial_copy_constructor;
    typedef __true_type has_trivial_assignment_operator;
    typedef __true_type has_trivial_destructor;
    typedef __true_type is_POD_type;
};
```

这意味着 `int` 类型在构造/析构/复制/赋值上都是平凡的，可以走优化路径。

#### 配合使用：判断类型优化路径

在比如 uninitialized_copy 中可能有如下代码：

```cpp
__uninitialized_copy_aux(...)
```

内部根据 `_type_traits<T>::is_POD_type` 来选择：

- 如果是 POD 类型 → 使用 `memmove`
- 否则 → 使用构造函数循环拷贝

这种方式称为“分支选择 dispatch based on type traits”。

#### `__true_type` 和 `__false_type` 定义

```cpp
struct __true_type {};
struct __false_type {};
```

它们是空类型，用于做模板特化的选择器。

#### 与 `std::is_trivially_copy_constructible` 区别

在 C++11 起，标准库引入了 `<type_traits>`，提供了更强大的类型萃取机制：

```cpp
std::is_trivially_copy_constructible<T>::value
std::is_pod<T>::value
```

SGI STL 的 `_type_traits` 是早期版本，没有 `constexpr` 等能力，只能靠手动偏特化支持常见类型。