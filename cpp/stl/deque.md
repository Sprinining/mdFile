## deque

`deque` 是一个非常强大的容器，兼顾了随机访问和双端插删，适合做队列、缓存、滑动窗口等场景。底层结构比 `vector` 复杂，但性能更稳健，是 STL 容器中非常实用的一种。

### 基本特点

| 特性项   | 描述                                                         |
| -------- | ------------------------------------------------------------ |
| 全称     | Double Ended Queue（双端队列）                               |
| 隶属     | STL 顺序容器之一                                             |
| 存储结构 | **分段连续内存结构**（不像 `vector` 那样完全连续）           |
| 支持操作 | **随机访问 + 头尾插入删除**，不适合中间插入                  |
| 默认底层 | 一般实现为**指针数组 + 块状内存区块**（典型 chunk size 为 512 字节） |
| 访问速度 | 访问中间元素略慢于 vector，但比 list 快                      |

### 底层原理图解

```css
逻辑视图：     [a0][a1][a2]...[an]
               ↑   ↑   ↑     ↑
            指向不同的内存块（元素连续）

内部结构：
- 一张“指针表”指向每一块内存
- 每块内存用于存储若干元素
- 逻辑顺序连续，但物理上非一整块
```

相比 `vector`：

| 特性     | `vector`         | `deque`                |
| -------- | ---------------- | ---------------------- |
| 内存布局 | 单块连续         | 分段连续               |
| 尾插效率 | 快               | 快                     |
| 头插效率 | 慢（要整体搬移） | 快（内部分配前段空间） |
| 随机访问 | O(1)             | O(1)（稍慢）           |
| 中间插删 | 慢               | 慢（要移动多个块内容） |

### 常见接口

```cpp
#include <deque>
using namespace std;

deque<int> dq;

// 基本操作
dq.push_back(1);
dq.push_front(2);
dq.pop_back();
dq.pop_front();

// 元素访问
dq[0];         // 支持随机访问
dq.at(1);      // 边界检查
dq.front();    // 访问头部
dq.back();     // 访问尾部

// 其他接口
dq.size();
dq.empty();
dq.clear();
dq.insert(dq.begin() + 1, 99);
dq.erase(dq.begin());
```

### 示例代码

```cpp
#include <deque>
#include <iostream>
using namespace std;

int main() {
    deque<int> dq = {1, 2, 3};
    dq.push_front(0);  // {0, 1, 2, 3}
    dq.push_back(4);   // {0, 1, 2, 3, 4}
    dq.pop_back();     // {0, 1, 2, 3}
    dq.pop_front();    // {1, 2, 3}

    for (int x : dq)
        cout << x << " ";  // 输出：1 2 3
}
```

### 和其他容器对比

| 操作     | `vector` | `deque`    | `list`             |
| -------- | -------- | ---------- | ------------------ |
| 尾部插入 | 快       | 快         | 快                 |
| 头部插入 | 慢       | 快         | 快                 |
| 中间插入 | 慢       | 慢         | 快（但无随机访问） |
| 随机访问 | 快       | 快（略慢） | 慢（无支持）       |

`deque` 是 vector 和 list 的中间态，平衡性能更适合做队列/缓存。

### 预留空间

容器预留空间，是为了避免频繁扩容时重新分配和移动数据。

- `vector`：**只在尾部预留空间**，所以头部插入效率很低，要整体移动数据。
- `deque`：**头部和尾部都能动态扩展**，而且提前预留了一些空间。

`deque` 内部不是一整块内存，而是 **多个连续大小的“内存块（chunk）”**，用一个**指针表**来管理：

```css
内部结构（简化）：
-------------------------------
[ chunk0 ][ chunk1 ][ chunk2 ]
   ↑         ↑         ↑
指针表：管理每个内存块的位置
```

当调用 `push_front()` 插入元素时：

- 如果 `chunk0` 前面还有空块，它直接用，不用移动元素。
- 如果没有，就再分配一个新的块插入到前面，更新指针表。

这就叫做**前端预留空间**：deque 会提前在头部保留一些块（或能扩容的空间），**让你能在前面 O(1) 插入**，而不像 vector 要搬整个数组。

### 使用建议场景

适合：

- 实现队列（`std::queue` 默认就用 `deque`）
- 频繁头尾插入删除
- 不希望扩容时复制整个内存（vs `vector`）

不适合：

- 中间频繁插入删除（不如 `list`）
- 元素地址不能变（如需要稳定指针）

### 注意事项

- `&dq[0]` 得到的内存不一定连续，**不能当数组用**
- 指向元素的指针/引用在插入头部/尾部时可能失效（尤其跨块）
- `insert` 在中间插入效率低（需搬动多个块内容）
- 适配器 `std::queue` 默认使用的是 `deque`，不是 `list`

### deque 的中控器

#### deque 是“分段连续空间”

**vector** 是“单块连续空间”，只能尾部扩张，扩张时需要：

1. 申请新空间；
2. 拷贝旧数据；
3. 释放旧空间；

> 所以其“可成长”是种假象，代价高昂。

**deque** 是“多块定量连续空间”，可从**两端**扩展，每块空间叫做 **缓冲区（buffer）**。

- 每个缓冲区大小固定（如默认 512 字节）。
- 每次扩展只需新加一块 buffer，无需整体复制移动。

#### deque 的“map 控制结构”

```cpp
// deque 类模板：T 为元素类型，Alloc 为配置器类型，BufSiz 表示每个缓冲区的大小（单位：元素数）
// BufSiz 默认为 0，SGI STL 会根据 T 类型大小自动计算每个缓冲区的字节数（默认约 512 bytes）
template <class T, class Alloc = alloc, size_t BufSiz = 0>
class deque {
public: 
    // 基本型别定义
    typedef T value_type;          // 元素类型
    typedef value_type* pointer;   // 指向元素的指针
    ...
protected:
    // 内部型别定义（为了实现方便和类型安全）

    // map_pointer 是指向指针的指针，即 T** 类型
    // 它指向一块指针数组（即“map”），每个指针指向一个缓冲区
    typedef pointer* map_pointer;

protected:
    // 数据成员

    // map 是指针数组的首地址，其类型为 T**，即指向指针的指针
    // 每个 map[n] 是一个指针（T*），指向一块缓冲区（buffer），缓冲区里存储若干个 T 元素
    map_pointer map;

    // map_size 表示 map 这块指针数组最多可以容纳多少个指针（即最多有多少个缓冲区）
    // 注意，不一定每个位置都有数据，有的可能暂时没使用
    size_type map_size;

    ...
};
```

- **map**：不是 STL 容器 `map`，而是一个指针数组（`T**`）。

  - map 是一个 **指针的数组**（也称为节点数组），每个元素是指向一个缓冲区的指针（`T*`）。

  - 所以 map 的类型为：

    ```cpp
    typedef T* pointer;
    typedef pointer* map_pointer; // 即 T**
    ```

- **缓冲区（buffer）**：

  - 是真正保存元素的空间：一段长度固定的连续空间。

  - 由 map 的每个节点（T*）指向。

- **整体结构**如下图：

![image-20250721214351751](./deque.assets/image-20250721214351751.png)

### deque 的迭代器

**deque 是分段连续空间，迭代器负责维护其“整体连续”的假象。**

为了实现这一点，deque 的迭代器需要：

1. **知道当前元素所在的缓冲区位置**；
2. **判断是否已到缓冲区边界**；
3. **若到达边界，能正确跳到下一个或上一个缓冲区**。

因此，deque 的迭代器结构比一般容器复杂，必须配合 map（缓冲区指针数组，也就是索引数组）来实现跨缓冲区的跳跃行为。

#### deque 迭代器的定义与数据结构

```cpp
template <class T, class Ref, class Ptr, size_t BufSiz>
struct __deque_iterator { // deque 的专属迭代器结构（未继承 std::iterator）
    
    // 普通迭代器类型（传入 T&, T*）
    // BufSiz 表示每个 buffer 的容量（以元素个数计）
    typedef __deque_iterator<T, T&, T*, BufSiz> iterator;

    // 常量迭代器类型（传入 const T&, const T*）
    typedef __deque_iterator<T, const T&, const T*, BufSiz> const_iterator;

    // 获取当前缓冲区可容纳元素个数
    static size_t buffer_size() {
        return __deque_buf_size(BufSiz, sizeof(T));
    }

    // 以下五个类型是 STL 迭代器所需的标准类型定义

    typedef random_access_iterator_tag iterator_category; // 迭代器类别：随机访问
    typedef T value_type;            // 元素类型
    typedef Ptr pointer;             // 指针类型（如 T* 或 const T*）
    typedef Ref reference;           // 引用类型（如 T& 或 const T&）
    typedef size_t size_type;        // 通常用于表示容器中元素数量
    typedef ptrdiff_t difference_type; // 迭代器之间的距离类型

    typedef T** map_pointer;         // 指向 map 中节点的指针，即 T**（map 是 T* 的数组）
    typedef __deque_iterator self;   // 当前类型的别名

    // ===== 以下是迭代器的核心数据成员 =====

    T* cur;        // 当前迭代器指向的位置（当前 buffer 中的元素位置）
    T* first;      // 当前缓冲区的起始位置（指向 buffer 的头部）
    T* last;       // 当前缓冲区的结束位置（指向 buffer 的尾后）
    map_pointer node; // 指向当前 buffer 在 map 中的位置（即 map 中的一个节点）

    ...
};
```

其中 `__deque_buf_size` 是个全局函数：

```cpp
// 用于计算 deque 中每个缓冲区（buffer）可以容纳多少个元素
// n：用户指定的缓冲区大小（以元素个数为单位）
// sz：元素大小（sizeof(T)）

inline size_t __deque_buf_size(size_t n, size_t sz) {
    // 如果用户传入了非 0 的 n，说明用户显式指定了缓冲区大小，直接返回该值
    return n != 0 ? n
        // 否则使用默认策略：
        // 如果元素较小（小于 512 bytes），则尽量填满 512 bytes 的缓冲区
        // 否则，元素很大时（大于等于 512 bytes），每个缓冲区只放一个元素
        : (sz < 512 ? size_t(512 / sz) : size_t(1));
}
```

![image-20250721220517236](./deque.assets/image-20250721220517236.png)

#### deque 元素分布与迭代器位置示意

假设我们创建一个 `deque<int>`，并设定每个缓冲区大小为 32 字节。由于 `sizeof(int) = 8`，所以每个缓冲区最多可容纳 `32 / 8 = 4` 个元素。

经过某些操作后，deque 中共有 20 个元素，因此需要 `20 / 4 = 5` 个缓冲区。map 中将使用 5 个指针节点来管理这 5 个缓冲区。

- `start` 是 begin() 返回的迭代器，指向第一个元素所在的位置；
- `finish` 是 end() 返回的迭代器，指向最后一个元素之后的位置（可能处于缓冲区末尾，或指向下一块的开头）；
- 最后一块缓冲区可能还有空闲空间，后续新元素可以直接插入，不需要扩容。

下图中，此 deque 目前有 20 个 `int` 元素，分布在 3 个缓冲区中。每个缓冲区大小为 32 字节，可容纳 8 个 `int`。map 的容量为 8（初始设定），当前使用了其中 3 个节点来管理缓冲区。

![image-20250721221002071](./deque.assets/image-20250721221002071.png)

`deque::begin()` 返回迭代器 `start`，`deque::end()` 返回 `finish`，它们都是 deque 的数据成员。

#### deque 迭代器的跨缓冲区跳跃机制

deque 迭代器重载了各种指针运算（如加减、前进后退），不能简单视为普通指针操作。

关键在于：**当移动到缓冲区边界时**，必须根据前进或后退的方向，调用 `set_node()` 来跳转到下一个或上一个缓冲区。

```cpp
// 跳转到新的缓冲区节点，并更新当前缓冲区的起始和结束位置
void set_node(map_pointer new_node) {
    node = new_node;          // 更新当前缓冲区在 map 中的位置（map 中的指针）
    first = *new_node;        // 当前缓冲区的起始地址（map 中存的是 T* 指针）
    // 缓冲区的结束地址 = 起始地址 + 缓冲区可容纳的元素数量
    last = first + difference_type(buffer_size());
}
```

#### 运算符重载

```cpp
// 解引用操作，返回当前元素的引用
reference operator*() const { return *cur; }

// 成员访问操作，返回当前元素的指针
pointer operator->() const { return &(operator*()); }

// 计算两个迭代器之间的距离（返回两个迭代器之间相差的元素个数）
// 假设当前迭代器为 this，参数迭代器为 x
difference_type operator-(const self& x) const {
    return difference_type(buffer_size()) * (node - x.node - 1) +
           (cur - first) + (x.last - x.cur);
    /*
    拆解说明：
    - node - x.node - 1 表示中间完整缓冲区的个数（不包含两端）
      × buffer_size() 得到中间缓冲区中的元素数

    - (cur - first) 是当前迭代器在本缓冲区内的偏移
    - (x.last - x.cur) 是另一个迭代器在其缓冲区内到末尾的剩余元素数
      （即 x 所在缓冲区的有效元素数）

    三者相加，得到从 x 到当前迭代器 this 之间的总距离（单位：元素个数）
    */
}

// 前置++，指向下一个元素
self& operator++() {
    ++cur;
    if (cur == last) {      // 到达当前缓冲区末尾
        set_node(node + 1); // 切换到下一个缓冲区
        cur = first;        // 设置为新缓冲区的起始位置
    }
    return *this;
}

// 后置++，先复制旧值，再调用前置++
self operator++(int) {
    self tmp = *this;
    ++*this;
    return tmp;
}

// 前置--，指向前一个元素
self& operator--() {
    if (cur == first) {     // 到达当前缓冲区起始位置
        set_node(node - 1); // 切换到上一个缓冲区
        cur = last;         // 设置为该缓冲区的末尾
    }
    --cur;
    return *this;
}

// 后置--，先复制旧值，再调用前置--
self operator--(int) {
    self tmp = *this;
    --*this;
    return tmp;
}

// 支持随机跳跃 n 个元素（正向或负向），修改当前迭代器位置
self& operator+=(difference_type n) {
    // offset 是目标位置相对于当前缓冲区 first 的偏移
    difference_type offset = n + (cur - first);

    if (offset >= 0 && offset < difference_type(buffer_size()))
        // 如果目标仍在当前缓冲区内，直接偏移 cur 指针
        cur += n;
    else {
        // 否则目标超出当前缓冲区，需要跳到其他缓冲区

        // 计算应该跳过的缓冲区数 node_offset
        difference_type node_offset =
            offset > 0 
            ? offset / difference_type(buffer_size())  // 正向跳跃
            : -difference_type((-offset - 1) / buffer_size()) - 1;  // 负向跳跃

        // 跳到目标缓冲区
        set_node(node + node_offset);

        // 在新缓冲区中设置 cur 到正确位置
        cur = first + (offset - node_offset * difference_type(buffer_size()));
    }
    return *this;
}

// operator+，等价于复制后调用 operator+=
self operator+(difference_type n) const {
    self tmp = *this;
    return tmp += n;
}

// operator-=，等价于 += 负数
self& operator-=(difference_type n) {
    return *this += -n;
}

// operator-（返回新迭代器），等价于复制后 -=
self operator-(difference_type n) const {
    self tmp = *this;
    return tmp -= n;
}

// 随机访问，等价于 *(this + n)
reference operator[](difference_type n) const {
    return *(*this + n);
}

// 判断两个迭代器是否相等（指向同一元素）
bool operator==(const self& x) const { return cur == x.cur; }

// 判断两个迭代器是否不等
bool operator!=(const self& x) const { return !(*this == x); }

// 判断顺序，先比较缓冲区位置，再比较缓冲区内位置
bool operator<(const self& x) const {
    return (node == x.node) ? (cur < x.cur) : (node < x.node);
}
```

### deque 的数据结构

deque 除了保存一个指向 map 的指针外，还维护两个迭代器 `start` 和 `finish`，分别指向**第一个元素**和**最后一个元素的下一个位置**。此外，还记录当前 map 的大小，以便在节点不够时重新分配更大的 map。

```cpp
// deque 类模板，支持指定元素类型 T、配置器 Alloc，和缓冲区大小 BufSiz
// BufSiz 默认为 0，这样可在 __deque_buf_size() 中根据类型自动决定大小
template <class T, class Alloc = alloc, size_t BufSiz = 0>
class deque {
public: // 基本类型定义
    typedef T value_type;             // 元素类型
    typedef value_type* pointer;      // 元素指针
    typedef size_t size_type;         // 尺寸类型（无符号）

public: // 迭代器类型定义
    typedef __deque_iterator<T, T&, T*, BufSiz> iterator;

protected: // 内部类型定义
    typedef pointer* map_pointer;     // 指向缓冲区指针的指针（map 的指针）

protected: // 成员变量
    iterator start;        // 指向第一个有效元素的迭代器（即第一个缓冲区的起点）
    iterator finish;       // 指向最后一个元素的下一个位置（即最后缓冲区的终点）
    map_pointer map;       // 指向 map，map 是一个指针数组，每个指针指向一个缓冲区
    size_type map_size;    // map 中指针的个数（即缓冲区的数量）
    ...
public: // 基本接口函数
    iterator begin() { return start; }        // 返回起始迭代器
    iterator end() { return finish; }         // 返回结束迭代器（最后元素的下一个位置）

    // 下标访问，第 n 个元素，相当于 start + n，再解引用
    reference operator[](size_type n) {
        return start[difference_type(n)];
    }

    reference front() { return *start; }      // 第一个元素
    reference back() {
        iterator tmp = finish;
        --tmp;                // finish 是最后元素的下一个位置，所以需要 -- 取前一个
        return *tmp;         // 解引用迭代器，获取最后一个元素
        // 不能写为 *(finish - 1)，因为 deque 迭代器重载的 - 需要调用 operator-，非 trivial
    }

    size_type size() const { return finish - start; } // 返回元素个数，两个迭代器相减
    size_type max_size() const { return size_type(-1); } // 支持的最大元素数
    bool empty() const { return finish == start; }       // 是否为空
};
```

- 为什么不能写 `*(finish - 1)`？

  - 术语 **non-trivial（非平凡）**，意思是：

    > 这个操作不是一个编译器可以直接展开的、开销为常数时间的操作，它需要调用自己定义的逻辑。

    对于 `deque::iterator` 的 `operator-` 和 `operator+`，内部必须判断是否要跨缓冲区、跳转 map 节点、更新 `cur`、`first`、`last` 等，逻辑很复杂，不是普通指针那种 "finish - 1" 的语义。

  - 简单说，`finish - 1` 是个“整体跳跃”的复杂操作，不是单纯指针减1，写起来容易出错，且实现逻辑复杂。`--tmp` 是标准的“前移一个元素”，更安全可靠。

- `size_type max_size() const { return size_type(-1); }` 里的 `-1` 其实是利用了无符号整数的特性。

  具体原因是：

  - `size_type` 通常是 `unsigned` 类型，比如 `unsigned int` 或 `size_t`。
  - 对无符号类型赋值 `-1`，会被解释成该类型能表示的最大值（比如 `size_t` 的最大值）。
  - 所以 `size_type(-1)` 就是无符号类型的最大可能值，表示理论上容器能支持的最大元素数量。

  换句话说，这是一种用来返回“最大可能容量”的惯用写法。

### deque 的构造与内存管理

#### 测试代码示例

```cpp
#include <deque>
#include <iostream>
#include <algorithm>
using namespace std;

int main() {
    // 创建含 20 个元素、初值为 9 的 deque
    // 注意：alloc 只适用于 SGI STL，现代编译器可能无法编译通过
    deque<int, alloc, 32> ideq(20, 9);  // 缓冲区大小为 32

    cout << "size=" << ideq.size() << endl;  
    // 输出：size=20

    // 设置每个元素为 0 ~ 19
    for (int i = 0; i < ideq.size(); ++i)
        ideq[i] = i;

    for (int i = 0; i < ideq.size(); ++i)
        cout << ideq[i] << ' ';
    cout << endl;
    // 输出：0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19

    // 尾部添加 3 个元素：0 1 2
    for (int i = 0; i < 3; i++)
        ideq.push_back(i);

    for (int i = 0; i < ideq.size(); ++i)
        cout << ideq[i] << ' ';
    cout << endl;
    // 输出：0 1 2 3 ... 19 0 1 2

    cout << "size=" << ideq.size() << endl;  
    // 输出：size=23

    // 再添加一个尾部元素 3
    ideq.push_back(3);

    for (int i = 0; i < ideq.size(); ++i)
        cout << ideq[i] << ' ';
    cout << endl;
    // 输出：0 1 2 3 ... 19 0 1 2 3

    cout << "size=" << ideq.size() << endl;
    // 输出：size=24

    // 前端插入元素 99
    ideq.push_front(99);

    for (int i = 0; i < ideq.size(); ++i)
        cout << ideq[i] << ' ';
    cout << endl;
    // 输出：99 0 1 2 3 ... 19 0 1 2 3

    cout << "size=" << ideq.size() << endl;
    // 输出：size=25

    // 前端继续插入两个元素：98, 97
    ideq.push_front(98);
    ideq.push_front(97);

    for (int i = 0; i < ideq.size(); ++i)
        cout << ideq[i] << ' ';
    cout << endl;
    // 输出：97 98 99 0 1 2 3 ... 19 0 1 2 3

    cout << "size=" << ideq.size() << endl;
    // 输出：size=27

    // 查找值为 99 的元素
    deque<int, alloc, 32>::iterator itr;
    itr = find(ideq.begin(), ideq.end(), 99);

    cout << *itr << endl;
    // 输出：99

    cout << *(itr.cur) << endl;
    // 输出：99（cur 是底层指针，直接访问同样结果）
}
```

#### 构造函数说明

程序一开始声明了一个 `deque`：

```cpp
deque<int, alloc, 32> ideq(20, 9);
```

这表示建立一个包含 20 个元素的 `deque`，每个元素值为 9，缓冲区大小为 32 字节。

由于要指定第三个模板参数（缓冲区大小），必须显式给出前两个参数（元素类型和分配器 `alloc`），这是 C++ 模板语法的要求。

此时，`deque` 会根据元素大小和缓冲区容量自动分配多个缓冲区，并通过 `map` 指针数组管理这些缓冲区。

#### 空间配置器类型定义

`deque` 定义了两个专属的空间配置器，用于分配不同的内存：

```cpp
protected: // Internal typedefs
// 分配元素用的配置器
typedef simple_alloc<value_type, Alloc> data_allocator;
// 分配 map 指针数组用的配置器
typedef simple_alloc<pointer, Alloc> map_allocator;
```

在构造函数中：

```cpp
deque(int n, const value_type& value)
  : start(), finish(), map(0), map_size(0)
{
  fill_initialize(n, value);
}
```

#### fill_initialize() 函数

`fill_initialize()` 会调用 `create_map_and_nodes()` 完成结构初始化，并填充初值：

```cpp
template <class T, class Alloc, size_t BufSize>
void deque<T, Alloc, BufSize>::fill_initialize(size_type n, const value_type& value) {
  create_map_and_nodes(n); // 创建并安排好 map 和缓冲区结构（n个元素）

  map_pointer cur;
  __STL_TRY {
    // 遍历所有“完整”的缓冲区节点，使用未初始化填充函数设初值
    // 每个 cur 是一个 map 指针，*cur 是对应的缓冲区首地址
    for (cur = start.node; cur < finish.node; ++cur)
      uninitialized_fill(*cur, *cur + buffer_size(), value); // 填满整个缓冲区

    // 最后一个缓冲区可能并未填满（如元素数不能整除缓冲区容量）
    // 所以只填充 finish.first 到 finish.cur 之间的空间
    uninitialized_fill(finish.first, finish.cur, value);
  }
  catch(...) {
    // 如果 fill 过程中抛出异常（如 value 构造失败），则进入异常处理（略）
  }
}
```

- `create_map_and_nodes(n)` 负责分配 map、分配缓冲区、并初始化 `start` 与 `finish`；
- 接着通过 `uninitialized_fill`，把所有缓冲区设置为 `value`；
- 最后一个缓冲区可能是“部分填充”状态，所以单独处理；
- 所有构造动作都在 `__STL_TRY` 中执行，异常安全。

#### create_map_and_nodes() 函数

`create_map_and_nodes()` 是关键的结构构建函数：

```cpp
template <class T, class Alloc, size_t BufSize>
void deque<T, Alloc, BufSize>::create_map_and_nodes(size_type num_elements) {
  // 计算所需缓冲区节点数（每个缓冲区能容纳 buffer_size() 个元素）
  // 多加一个节点是为了防止整除时最后一个缓冲区无法区分尾端
  size_type num_nodes = num_elements / buffer_size() + 1;

  // map 是一个指针数组，指向每个缓冲区的起始地址
  // 为了便于后续头尾扩展，在实际分配时会前后多留两个位置
  // map_size 最少 8 个，最多是所需节点数 + 2
  map_size = max(initial_map_size(), num_nodes + 2);

  // 分配 map 空间，注意：这里每个元素是一个 pointer（指向缓冲区）
  map = map_allocator::allocate(map_size);

  // 将 nstart 指向 map 中间区域，使得 deque 的缓冲区结构位于 map 的中间位置
  // 把多出来的 map 空间（指针槽）平均分配到前后两端，这样无论头尾扩展都还有空间
  map_pointer nstart = map + (map_size - num_nodes) / 2;
  map_pointer nfinish = nstart + num_nodes - 1;

  map_pointer cur;
  __STL_TRY {
    // 遍历 nstart 到 nfinish，为每个 map 节点分配实际的缓冲区内存
    for (cur = nstart; cur <= nfinish; ++cur)
      *cur = allocate_node(); // 分配一个缓冲区（大小为 BufSize * sizeof(T)）
  }
  catch(...) {
    // 如果中途分配失败，需要将已分配的缓冲区回收（回滚），这里略
  }

  // 设置 deque 的两个迭代器：start 和 finish
  start.set_node(nstart);      // 设置 start 所属的缓冲区节点
  finish.set_node(nfinish);    // 设置 finish 所属的缓冲区节点

  start.cur = start.first;     // start.cur 指向起始缓冲区的起始位置
  finish.cur = finish.first + num_elements % buffer_size();
  // finish.cur 指向最后缓冲区的实际结束位置
  // 如果整除，% 为 0，指向最后缓冲区起始位置（表示多分了一个缓冲区）
}
```

| 操作              | 说明                                                         |
| ----------------- | ------------------------------------------------------------ |
| `num_nodes`       | 计算需要的缓冲区节点个数（即多少个指针 + 缓冲区）            |
| `map_size`        | 在 `num_nodes` 基础上多保留前后各一个，便于扩展              |
| `nstart/nfinish`  | 保证 deque 缓冲区节点位于 map 的中央区域                     |
| `allocate_node()` | 实际分配一块缓冲区内存空间                                   |
| `set_node()`      | 设置迭代器的“所在缓冲区节点”                                 |
| `cur`             | 设置迭代器指向当前缓冲区的实际位置（start 是开头，finish 是结尾） |

##### 为什么要加 `+1`？

###### 情况 1：不能整除

`num_elements = 70`，`buffer_size() = 32`

```txt
70 / 32 = 2（整数除法）→ 还需要第三个缓冲区来放下剩下的 6 个元素
所以要加 1，共 3 个缓冲区
```

###### 情况 2：能整除

```txt
num_elements = 64，buffer_size() = 32
64 / 32 = 2 → 好像刚好 2 个缓冲区就够？
```

表面上看没问题，但 **STL 的 deque 实现中，总是多分配一个缓冲区节点**，哪怕最后一个不存任何元素。这是为了：

- 简化 `finish` 的表示（让 `finish.cur` 指向空的缓冲区头，统一逻辑）
- 支持高效 push_back 不用立刻扩容
- 异常安全和一致性

所以无论整除与否，都 +1，更安全也更通用。

##### 计算并分配 `map`（指针数组）的大小

```cpp
map_size = max(initial_map_size(), num_nodes + 2);
```

- **`map` 是指向缓冲区的指针数组**，每个元素指向一个缓冲区的起始地址。deque 通过这个数组管理所有缓冲区。
- **`num_nodes` 是实际需要的缓冲区数量**，即存放元素所需的缓冲区个数。
- **为什么要加 2？**
   为了支持 deque 在头部和尾部高效扩展（插入新元素时，可能需要新缓冲区），`map` 需要在实际用到的缓冲区前后**预留额外的两个空位置**，方便未来动态增加缓冲区而不必频繁重新分配整个 `map`。
- **`initial_map_size()` 是 `map` 的初始大小，通常是一个最小容量的预设值**，防止刚开始时 `map` 太小。
- 最终取 **`initial_map_size()` 和 `num_nodes + 2` 中的较大值**，保证 `map` 至少有足够容量存放当前缓冲区和预留扩展位置。

#### 尾端插入元素

`push_back()` 函数负责在 deque 尾部添加元素，其行为分为两种情况：

- **缓冲区有空余空间时**
   直接在最后一个缓冲区的备用空间内构造新元素，调整 `finish.cur` 指向新元素后的位置。
- **缓冲区无空余空间时（只剩一个备用位置）**
   调用 `push_back_aux()`，执行以下操作：
  1. 先调用 `reserve_map_at_back()`，确保 `map` 空间足够管理新缓冲区。
  2. 配置一个新的缓冲区节点（调用 `allocate_node()`）。
  3. 在当前位置构造新元素。
  4. 更新 `finish` 迭代器，指向新缓冲区的起始位置。
  5. 若中途异常，释放新分配的缓冲区。

示意：当 `finish.cur == finish.last - 1`（最后缓冲区只剩一个备用元素）时才调用 `push_back_aux()`，保证缓冲区扩展的正确性。

这样保证了 deque 在尾部动态扩容时，数据和迭代器状态的正确维护。

```cpp
void push_back(const value_type& t) {
  if (finish.cur != finish.last - 1) {  // 尾缓冲区还有空位
    construct(finish.cur, t);           // 在当前位置构造元素
    ++finish.cur;                       // 迭代器后移，更新尾部位置
  } else {
    push_back_aux(t);                   // 尾缓冲区满了，调用辅助函数扩容并插入
  }
}

void push_back_aux(const value_type& t) {
  value_type t_copy = t;                // 复制参数，防止异常时出错
  reserve_map_at_back();                // 确保 map 末端有足够空间，可能扩容 map
  *(finish.node + 1) = allocate_node(); // 在 map 中为新缓冲区分配空间（分配新节点）
  __STL_TRY {
    construct(finish.cur, t_copy);       // 在当前尾位置构造元素
    finish.set_node(finish.node + 1);    // 更新 finish 所在缓冲区节点为新节点
    finish.cur = finish.first;           // 迭代器指向新缓冲区起始位置
  }
  __STL_UNWIND(deallocate_node(*(finish.node + 1))); // 出异常时回收新分配的缓冲区
}
```

接下来，程序用下标运算符给每个元素重新赋值，然后在尾部插入3个新元素。
因为最后一个缓冲区还有4个空位，所以不会触发缓冲区扩容。

![image-20250722102918033](./deque.assets/image-20250722102918033.png)

现在，如果再往尾部添加一个新元素：`ideq.push_back(3);`

![image-20250722105927527](./deque.assets/image-20250722105927527.png)

#### 前端插入元素

`push_front()` 函数负责在 deque 头部添加元素，其行为分为两种情况：

- **缓冲区有空余空间时**
   直接在第一个缓冲区的备用空间内构造新元素，调整 `start.cur` 指向新元素的位置。
- **缓冲区无空余空间时（`start.cur == start.first`）**
   调用 `push_front_aux()`，执行以下操作：
  1. 调用 `reserve_map_at_front()`，确保 `map` 前端有空间可用于添加新缓冲区。
  2. 配置一个新的缓冲区节点（调用 `allocate_node()`）。
  3. 更新 `start` 指向新缓冲区，并将 `cur` 指向其末尾位置（`last - 1`），为前插腾出空间。
  4. 在新位置构造元素。
  5. 若中途异常，回滚迭代器并释放新分配的缓冲区。

示意：当 `start.cur == start.first`（第一个缓冲区没有备用空间）时，才调用 `push_front_aux()`，以正确管理缓冲区扩展。

这样保证了 deque 在头部动态扩容时，元素构造、内存分配与迭代器状态的正确性与异常安全。

```cpp
void push_front(const value_type& t) {
  if (start.cur != start.first) {              // 第一个缓冲区还有可用空间
    construct(start.cur - 1, t);               // 在当前位置之前构造元素
    --start.cur;                               // 迭代器前移，更新头部位置
  } else {
    push_front_aux(t);                         // 第一个缓冲区满了，调用辅助函数扩容插入
  }
}

void push_front_aux(const value_type& t) {
  value_type t_copy = t;                       // 拷贝元素，防止异常时被破坏
  reserve_map_at_front();                      // 确保 map 前端有空间，必要时扩容 map
  *(start.node - 1) = allocate_node();         // 分配一个新的缓冲区，挂接到 map 前端

  __STL_TRY {
    start.set_node(start.node - 1);            // 调整 start.node 指向新缓冲区
    start.cur = start.last - 1;                // start.cur 指向缓冲区尾端（预留插入点）
    construct(start.cur, t_copy);              // 在该位置构造元素
  }
  catch(...) {
    // 构造失败则回滚：恢复指针并释放新缓冲区
    start.set_node(start.node + 1);
    start.cur = start.first;
    deallocate_node(*(start.node - 1));
    throw;                                     // 重新抛出异常
  }
}

```

`ideq.push_front(99);` 在 deque 前端插入元素 `99`，若无空间则自动扩展。

![image-20250722112535269](./deque.assets/image-20250722112535269.png)

接下来执行：

```cpp
ideq.push_front(98);
ideq.push_front(97);
```

由于当前缓冲区还有空位，两个元素都会直接构造在前端的备用空间中，无需扩展缓冲区。

![image-20250722112613971](./deque.assets/image-20250722112613971.png)

#### 何时需要重新配置 map？

由 `reserve_map_at_back()` 和 `reserve_map_at_front()` 判断， 实际扩容操作由 `reallocate_map()` 执行。

```cpp
// 尾端预留空间不足时，判断是否需要重新配置 map（默认增加 1 个节点）
void reserve_map_at_back(size_type nodes_to_add = 1) {
  // finish.node 是当前尾缓冲区在 map 中的位置
  // map + map_size 是 map 的末尾地址
  // 如果 finish.node 后面剩下的空间不足以容纳新增节点（nodes_to_add + 1：多预留一个空槽）
  if (nodes_to_add + 1 > map_size - (finish.node - map))
    reallocate_map(nodes_to_add, false);  // false 表示从尾部扩容
}

// 前端预留空间不足时，判断是否需要重新配置 map（默认增加 1 个节点）
void reserve_map_at_front(size_type nodes_to_add = 1) {
  // start.node 是当前头缓冲区在 map 中的位置
  // 如果 map 的头部剩余空间小于需要新增的节点数，则重新配置 map
  if (nodes_to_add > start.node - map)
    reallocate_map(nodes_to_add, true);  // true 表示从前端扩容
}

// 实际执行 map 扩容的函数
template <class T, class Alloc, size_t BufSize>
void deque<T, Alloc, BufSize>::reallocate_map(size_type nodes_to_add,
                                              bool add_at_front) {
  size_type old_num_nodes = finish.node - start.node + 1;   // 当前缓冲区数量
  size_type new_num_nodes = old_num_nodes + nodes_to_add;   // 扩容后总缓冲区数量
  map_pointer new_nstart;

  // 如果当前 map 空间足够大，不需要重新配置 map，只需重新安排位置
  if (map_size > 2 * new_num_nodes) {
    // 选择新起点，让缓冲区尽量均匀分布在中间，前后都有空间
    new_nstart = map + (map_size - new_num_nodes) / 2
                 + (add_at_front ? nodes_to_add : 0);

    // 将原节点内容复制到新位置
    if (new_nstart < start.node)
      copy(start.node, finish.node + 1, new_nstart);
    else
      copy_backward(start.node, finish.node + 1, new_nstart + old_num_nodes);
  } else {
    // 当前 map 空间不够，重新配置一块更大的 map 空间
    size_type new_map_size = map_size + max(map_size, nodes_to_add) + 2;

    // 配置新的 map 空间
    map_pointer new_map = map_allocator::allocate(new_map_size);

    // 同样选择一个新的起点，让缓冲区分布在 map 中间
    new_nstart = new_map + (new_map_size - new_num_nodes) / 2
                 + (add_at_front ? nodes_to_add : 0);

    // 拷贝原 map 内容到新 map 中
    copy(start.node, finish.node + 1, new_nstart);

    // 释放旧 map 空间
    map_allocator::deallocate(map, map_size);

    // 更新 map 指针和大小
    map = new_map;
    map_size = new_map_size;
  }

  // 调整 start 和 finish 迭代器指向新的缓冲区位置
  start.set_node(new_nstart);
  finish.set_node(new_nstart + old_num_nodes - 1);
}
```

- `reserve_map_at_back()`：检查 map 尾部是否有足够空间添加新缓冲区，不足则扩容。
- `reserve_map_at_front()`：检查 map 头部是否有足够空间添加新缓冲区，不足则扩容。
- `reallocate_map()`：若 map 不够大，重新分配更大 map，并把原缓冲区地址迁移过去，更新迭代器。

### deque 的元素操作

#### find()

前面用泛型算法 `find()` 找到 deque 中值为 99 的元素：

```cpp
deque<int, alloc, 32>::iterator itr;
itr = find(ideq.begin(), ideq.end(), 99);
```

找到后，`*itr` 和 `*(itr.cur)` 输出结果相同，都是 99，验证了 deque 迭代器底层是通过指针 `cur` 操作的：

```cpp
cout << *itr << endl;      // 输出：99
cout << *(itr.cur) << endl; // 输出：99
```

![image-20250722113334199](./deque.assets/image-20250722113334199.png)

#### pop_back() 和 pop_front()

```cpp
void pop_back() {
  if (finish.cur != finish.first) {
    // 最后一个缓冲区还有元素
    --finish.cur;            // 迭代器后移，排除最后一个元素
    destroy(finish.cur);     // 析构最后一个元素
  } else
    // 最后一个缓冲区已空，需释放缓冲区
    pop_back_aux();
}

// 只有当 finish.cur == finish.first 时才调用，释放最后一个缓冲区
template <class T, class Alloc, size_t BufSize>
void deque<T, Alloc, BufSize>::pop_back_aux() {
  deallocate_node(finish.first);       // 释放最后一个缓冲区
  finish.set_node(finish.node - 1);    // 迭代器指向前一个缓冲区
  finish.cur = finish.last - 1;        // 指向该缓冲区最后一个元素位置
  destroy(finish.cur);                  // 析构该元素
}

void pop_front() {
  if (start.cur != start.last - 1) {
    // 第一个缓冲区还有元素
    destroy(start.cur);      // 析构第一个元素
    ++start.cur;             // 迭代器前移，排除第一个元素
  } else
    // 第一个缓冲区只剩一个元素，释放缓冲区
    pop_front_aux();
}

// 只有当 start.cur == start.last - 1 时才调用，释放第一个缓冲区
template <class T, class Alloc, size_t BufSize>
void deque<T, Alloc, BufSize>::pop_front_aux() {
  destroy(start.cur);              // 析构第一个元素
  deallocate_node(start.first);    // 释放第一个缓冲区
  start.set_node(start.node + 1);  // 迭代器指向下一个缓冲区
  start.cur = start.first;         // 指向该缓冲区第一个元素位置
}
```

#### clear()

`clear()` 用于清空整个 deque。注意，deque 在空状态时仍保留一个缓冲区，因此 `clear()` 执行完毕后，deque 会恢复到初始状态，依然保留一个缓冲区，不会完全释放所有内存。

```cpp
// 注意，deque 的策略是清空后保留一个缓冲区，保持初始状态
template <class T, class Alloc, size_t BufSize>
void deque<T, Alloc, BufSize>::clear() {
  // 清理头尾缓冲区以外的所有满缓冲区
  for (map_pointer node = start.node + 1; node < finish.node; ++node) {
    destroy(*node, *node + buffer_size());              // 逐元素调用析构函数
    data_allocator::deallocate(*node, buffer_size());   // 释放缓冲区内存
  }
  if (start.node != finish.node) {
    // 有至少两个缓冲区时
    destroy(start.cur, start.last);      // 析构头缓冲区中现存元素
    destroy(finish.first, finish.cur);   // 析构尾缓冲区中现存元素
    data_allocator::deallocate(finish.first, buffer_size()); // 释放尾缓冲区内存，保留头缓冲区
  } else {
    // 只有一个缓冲区时，只析构元素不释放缓冲区内存（保留缓冲区）
    destroy(start.cur, finish.cur);
  }
  finish = start; // 重置迭代器，恢复初始状态
}

```

- 清除除头尾之外的所有满缓冲区，并释放其内存；
- 头尾缓冲区中的元素也被析构，尾缓冲区内存被释放，头缓冲区保留；
- 如果只有一个缓冲区，只析构元素不释放内存，保持缓冲区存在；
- 最后重置 `start` 和 `finish`，使 deque 处于清空且保留一个缓冲区的初始状态。

#### erase()

```cpp
// 清除 pos 所指的单个元素，pos 为删除位置
iterator erase(iterator pos) {
  iterator next = pos;
  ++next;
  difference_type index = pos - start;  // 计算 pos 前面的元素个数

  if (index < (size() >> 1)) { // 如果 pos 前面的元素较少
    // 将 pos 前面的元素向后移动一格，覆盖要删除的元素
    copy_backward(start, pos, next);
    pop_front();                // 删除头部多余元素
  } else {                     // 如果 pos 后面的元素较少
    // 将 pos 后面的元素向前移动一格，覆盖要删除的元素
    copy(next, finish, pos);
    pop_back();                 // 删除尾部多余元素
  }

  return start + index;         // 返回删除位置的新迭代器
}

// 清除区间 [first, last) 的元素
template <class T, class Alloc, size_t BufSize>
typename deque<T, Alloc, BufSize>::iterator
deque<T, Alloc, BufSize>::erase(iterator first, iterator last) {
  if (first == start && last == finish) { // 删除整个 deque
    clear();                             // 直接清空
    return finish;
  } else {
    difference_type n = last - first;           // 待删除元素数
    difference_type elems_before = first - start; // 删除区间前元素数

    if (elems_before < (size() - n) / 2) { // 删除区间前的元素较少
      // 将区间前的元素向后移动覆盖删除区间
      copy_backward(start, first, last);
      iterator new_start = start + n;       // 新起点位置
      destroy(start, new_start);             // 销毁多余元素

      // 释放删除区间覆盖后的多余缓冲区
      for (map_pointer cur = start.node; cur < new_start.node; ++cur)
        data_allocator::deallocate(*cur, buffer_size());

      start = new_start;                     // 更新起点迭代器
    } else {                               // 删除区间后的元素较少
      // 将区间后的元素向前移动覆盖删除区间
      copy(last, finish, first);
      iterator new_finish = finish - n;     // 新终点位置
      destroy(new_finish, finish);          // 销毁多余元素

      // 释放删除区间覆盖后的多余缓冲区
      for (map_pointer cur = new_finish.node + 1; cur <= finish.node; ++cur)
        data_allocator::deallocate(*cur, buffer_size());

      finish = new_finish;                   // 更新终点迭代器
    }
    return start + elems_before;             // 返回删除区间起始位置的新迭代器
  }
}
```

- **erase(iterator pos)**
  删除单个元素，先判断删除位置前后哪个部分元素少，选择移动较少的那部分元素以减少移动开销。移动完毕后调用 `pop_front()` 或 `pop_back()` 删除多余元素。

- **erase(iterator first, iterator last)**
  删除一个区间，分为两种情况：

  - 删除整个 deque，直接调用 `clear()`。

  - 删除部分区间，根据删除区间前后的元素多少，选择移动前半部分或后半部分元素。移动后销毁多余元素，并释放对应的缓冲区。

  最后返回删除区间起点的新迭代器。

#### insert()

```cpp
// 在 position 位置插入一个元素，值为 x
iterator insert(iterator position, const value_type& x) {
  if (position.cur == start.cur) {  // 插入点在 deque 最前端
    push_front(x);                  // 交给 push_front 处理
    return start;                  // 返回新起点迭代器
  }
  else if (position.cur == finish.cur) {  // 插入点在 deque 最尾端
    push_back(x);                     // 交给 push_back 处理
    iterator tmp = finish;
    --tmp;                           // 返回新元素位置
    return tmp;
  }
  else {
    return insert_aux(position, x);  // 插入点在中间，交给 insert_aux 处理
  }
}

template <class T, class Alloc, size_t BufSize>
typename deque<T, Alloc, BufSize>::iterator
deque<T, Alloc, BufSize>::insert_aux(iterator pos, const value_type& x) {
  difference_type index = pos - start;  // 插入点之前的元素个数
  value_type x_copy = x;                // 复制参数，防止异常

  if (index < size() / 2) {  // 插入点前元素较少
    push_front(front());      // 在最前端插入一个与当前第一个元素相同的值（腾出空间）
    iterator front1 = start;  
    ++front1;
    iterator front2 = front1;
    ++front2;
    pos = start + index;      // 重新定位插入点
    copy(front2, pos + 1, front1);  // 将 [front2, pos+1) 元素向后移动一格
  } 
  else {                    // 插入点后元素较少
    push_back(back());      // 在尾部插入一个与最后一个元素相同的值（腾出空间）
    iterator back1 = finish;
    --back1;
    iterator back2 = back1;
    --back2;
    pos = start + index;    // 重新定位插入点
    copy_backward(pos, back2 + 1, back1);  // 将 [pos, back2+1) 元素向前移动一格
  }

  *pos = x_copy;  // 在腾出的空位写入新元素值
  return pos;     // 返回新元素位置
}
```

- `insert()`
  先判断插入位置是否为头尾，分别调用 `push_front` 或 `push_back` 处理。否则调用辅助函数 `insert_aux` 处理中间插入。
- `insert_aux()`
  为了腾出插入位置空间，会将 deque 头部或尾部插入一个与边界相同的元素（复制第一个或最后一个元素），然后移动中间元素实现空出插入点。
  - 如果插入点靠近头部，先 `push_front`，再移动头部元素往后挪。
  - 如果靠近尾部，先 `push_back`，再移动尾部元素往前挪。
     最后在空出的位置赋值新元素并返回迭代器。

- `deque::insert` 在头尾位置效率很高（接近常数时间）。
- 中间位置插入时间复杂度为 **O(n)**，n 是插入点到头或尾的距离。
- 适用场景以双端插入/删除为主，不建议频繁中间插入。
