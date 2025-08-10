## multiset

`std::multiset` 是 C++ STL 中的**关联容器**，与 `std::set` 类似，但它允许容器中存储重复的元素。`multiset` 元素是按特定顺序排列的，默认按照升序排序，底层通常使用**红黑树**来实现。

### 基本特性

- **元素可重复**：与 `std::set` 不同，`std::multiset` 可以存储重复的元素。
- **自动排序**：元素会根据 `key` 自动排序（默认是升序排序），可以通过自定义比较函数来改变排序规则。
- **底层实现**：`std::multiset` 使用**平衡二叉树**（如红黑树）实现，保证 O(logN) 的时间复杂度。
- **元素访问**：通过迭代器访问，不能随机访问元素（不像 `std::vector`）。

### 常用接口

#### 定义方式

```cpp
#include <set>
std::multiset<int> ms;  // 定义一个 multiset 容器，存储 int 类型元素
```

#### 插入元素

```cpp
ms.insert(5);   // 插入 5
ms.insert(2);   // 插入 2
ms.insert(5);   // 插入 5，重复元素可以插入
```

#### 查找元素

```cpp
auto it = ms.find(5);  // 查找元素 5，返回指向该元素的迭代器
if (it != ms.end()) {
    std::cout << "Found 5" << std::endl;
}
```

```cpp
// 查找所有值为 5 的元素
auto range = ms.equal_range(5);

// 输出所有值为 5 的元素
for (auto it = range.first; it != range.second; ++it) {
    std::cout << *it << " ";  // 输出：5 5 5
}
```

#### 遍历 `multiset`

```cpp
for (const auto& elem : ms) {
    std::cout << elem << " ";
}
// 输出: 2 5 5
```

#### 删除元素

```cpp
ms.erase(5);  // 删除所有值为 5 的元素
ms.erase(ms.find(2));  // 删除一个指定位置的元素
```

#### 获取元素个数

```cpp
std::cout << "Number of 5s: " << ms.count(5) << std::endl;  // 返回 5 的出现次数
```

#### 清空容器

```cpp
ms.clear();  // 清空 multiset
```

#### 常用接口汇总

| 方法              | 说明                                 |
| ----------------- | ------------------------------------ |
| `insert()`        | 插入元素，允许重复                   |
| `find()`          | 查找元素，返回指向该元素的迭代器     |
| `count()`         | 返回指定元素出现的次数               |
| `erase()`         | 删除指定元素（所有重复元素都会删除） |
| `clear()`         | 清空容器                             |
| `begin()`/`end()` | 返回容器的迭代器                     |

### 使用示例

```cpp
#include <iostream>
#include <set>

int main() {
    // 创建 multiset 并插入元素
    std::multiset<int> ms = {1, 5, 3, 5, 7, 5};

    // 遍历 multiset，输出所有元素
    for (const auto& elem : ms) {
        std::cout << elem << " ";  // 输出: 1 3 5 5 5 7
    }
    std::cout << std::endl;

    // 查找元素 5
    auto it = ms.find(5);
    if (it != ms.end()) {
        std::cout << "Found 5" << std::endl;
    }

    // 删除元素 5
    ms.erase(5);
    for (const auto& elem : ms) {
        std::cout << elem << " ";  // 输出: 1 3 7
    }
    std::cout << std::endl;

    return 0;
}
```

**输出**：

```css
1 3 5 5 5 7 
Found 5
1 3 7 
```

### 常见问题

#### `multiset` 和 `set` 的区别？

| 特性         | `set`                    | `multiset`                                                   |
| ------------ | ------------------------ | ------------------------------------------------------------ |
| 元素是否重复 | 不允许重复元素           | 允许重复元素                                                 |
| 查找元素     | 查找时返回第一个匹配元素 | 查找时返回第一个匹配元素（可以通过其他方式查找所有匹配元素） |
| 性能         | 查找、插入、删除 O(logN) | 查找、插入、删除 O(logN)                                     |

#### 如何按自定义顺序排序？

可以通过提供自定义比较函数来改变排序规则：

```cpp
struct Compare {
    bool operator()(const int& a, const int& b) const {
        return a > b;  // 降序排序
    }
};

std::multiset<int, Compare> ms;  // 使用自定义比较器
```

#### 如何删除容器中的重复元素？

`std::multiset` 本身就支持重复元素。如果需要删除所有重复元素，可以使用 `erase` 方法删除特定元素。例如，删除所有值为 5 的元素：

```cpp
ms.erase(5);  // 删除所有值为 5 的元素
```

### 拓展建议

- 如果不需要重复元素，请使用 `std::set`。
- 对于频繁插入和查找的情况，`multiset` 由于其平衡二叉树的结构，可以提供较高的性能。
- 如果需要按 `value` 排序，可以先将 `multiset` 转换为 `vector`，再用 `std::sort()` 排序。

### multiset 源码提要（与 set 的不同点）

```cpp
// multiset 的特性与 set 几乎完全相同，唯一差别：允许键值重复
// 因此所有插入操作使用底层 RB-tree 的 insert_equal() 而非 insert_unique()

template <class Key, class Compare = less<Key>, class Alloc = alloc>
class multiset {
public:
    // typedefs（与 set 相同，不再重复列出）
    // ...
    
    //===============================
    // 构造函数（与 set 相比，构造时插入调用 insert_equal）
    //===============================

    // 构造函数：用迭代器区间初始化，比较器使用默认 Compare()
    // 注意：底层调用 t.insert_equal()，允许重复键值
    template <class InputIterator>
    multiset(InputIterator first, InputIterator last)
        : t(Compare()) 
    { 
        t.insert_equal(first, last); 
    }

    // 构造函数：用迭代器区间初始化，并自定义 Compare 比较器
    template <class InputIterator>
    multiset(InputIterator first, InputIterator last, const Compare& comp)
        : t(comp) 
    { 
        t.insert_equal(first, last); 
    }

    // ...（其它成员与 set 相同）
    
    //===============================
    // 插入操作（与 set 最大区别：调用 insert_equal）
    //===============================

    // 单元素插入，允许重复键值
    iterator insert(const value_type& x) {
        return t.insert_equal(x);
    }

    // 提供“插入位置”提示的插入（效率可能提高）
    iterator insert(iterator position, const value_type& x) {
        typedef typename rep_type::iterator rep_iterator;
        return t.insert_equal((rep_iterator&)position, x);
    }

    // 区间插入
    template <class InputIterator>
    void insert(InputIterator first, InputIterator last) {
        t.insert_equal(first, last);
    }

    // ...（其它与 set 相同）
    
private:
    // 底层红黑树（与 set 相同）
    rep_type t;  
};
```

- **允许重复键值**

  - `set` 调用 `insert_unique()`，不允许插入相同键。

  - `multiset` 调用 `insert_equal()`，允许重复键。

- **插入函数**
  - 构造函数、`insert()`、`insert(position, value)`、`insert(first, last)` 全部改为 `insert_equal()`。

- **底层实现**
  - `t` 是红黑树（RB-tree）对象，`insert_equal()` 会在相同键值的元素后面插入新节点，不会拒绝重复。