## multimap

`std::multimap` 是 C++ STL 中的**关联容器**，它与 `std::map` 类似，但允许**多个相同的键（key）**存在。它存储的是**键值对（key-value）**，并且 **key 不唯一**，但 **按 key 排序**，每个 key 可以关联多个不同的 value。

### 基本特性

- **键允许重复**：`std::multimap` 允许多个相同的 key 存在，因此每个 key 可以关联多个不同的 value。
- **按 key 排序**：与 `std::map` 一样，`std::multimap` 中的元素会根据 key 自动排序（默认升序），可以通过自定义比较函数来改变排序规则。
- **底层实现**：`std::multimap` 使用**平衡二叉树**（如红黑树）实现，保证 O(logN) 的时间复杂度。
- **元素访问**：通过迭代器访问，不能随机访问元素（不像 `std::vector`）。

### 常用接口

#### 定义方式

```cpp
#include <map>
std::multimap<int, std::string> mmap;  // 定义一个 multimap，键为 int，值为 string
```

#### 插入元素

```cpp
mmap.insert({1, "apple"});    // 插入 key 为 1，值为 "apple"
mmap.insert({1, "banana"});   // 插入另一个 key 为 1 的元素，值为 "banana"
mmap.insert({2, "orange"});   // 插入 key 为 2，值为 "orange"
```

#### 查找元素

```cpp
auto it = mmap.find(1);   // 查找 key 为 1 的第一个匹配元素
if (it != mmap.end()) {
    std::cout << it->first << " => " << it->second << std::endl;  // 输出：1 => apple
}
```

#### 查找所有匹配的元素

由于 `multimap` 允许重复的键，因此 `find()` 只会返回第一个匹配元素。如果需要查找所有匹配的元素，应该使用 `equal_range()`。

```cpp
auto range = mmap.equal_range(1);  // 查找所有 key 为 1 的元素
for (auto it = range.first; it != range.second; ++it) {
    std::cout << it->first << " => " << it->second << std::endl;  // 输出：1 => apple 1 => banana
}
```

#### 删除元素

```cpp
mmap.erase(1);  // 删除所有 key 为 1 的元素
mmap.erase(mmap.find(2));  // 删除 key 为 2 的第一个元素
```

#### 获取元素个数

```cpp
std::cout << "Number of elements with key 1: " << mmap.count(1) << std::endl;  // 输出：2
```

#### 清空容器

```cpp
mmap.clear();  // 清空 multimap
```

#### 常用接口汇总

| 方法              | 说明                                      |
| ----------------- | ----------------------------------------- |
| `insert()`        | 插入键值对，允许重复键                    |
| `find()`          | 查找指定 key 的第一个匹配元素             |
| `equal_range()`   | 查找所有具有相同 key 的元素               |
| `count()`         | 返回指定 key 的元素个数                   |
| `erase()`         | 删除指定 key 的元素（所有重复的会被删除） |
| `clear()`         | 清空容器                                  |
| `begin()`/`end()` | 返回容器的迭代器                          |

### 使用示例

```cpp
#include <iostream>
#include <map>

int main() {
    std::multimap<int, std::string> mmap;

    // 插入元素
    mmap.insert({1, "apple"});
    mmap.insert({1, "banana"});
    mmap.insert({2, "orange"});
    mmap.insert({2, "grape"});

    // 查找并输出所有 key 为 1 的元素
    auto range = mmap.equal_range(1);
    for (auto it = range.first; it != range.second; ++it) {
        std::cout << it->first << " => " << it->second << std::endl;
    }

    // 查找并输出所有 key 为 2 的元素
    range = mmap.equal_range(2);
    for (auto it = range.first; it != range.second; ++it) {
        std::cout << it->first << " => " << it->second << std::endl;
    }

    return 0;
}
```

**输出**：

```css
1 => apple
1 => banana
2 => orange
2 => grape
```

### 常见面试问题

#### `multimap` 和 `map` 的区别？

| 特性       | `map`                    | `multimap`                                                   |
| ---------- | ------------------------ | ------------------------------------------------------------ |
| 键是否重复 | 不允许重复键             | 允许重复键                                                   |
| 查找方式   | 查找时返回第一个匹配元素 | 查找时返回第一个匹配元素（可以通过 `equal_range()` 查找所有） |
| 插入       | 插入一个唯一的键值对     | 插入相同键的多个值                                           |

#### 如何删除指定 key 的所有元素？

使用 `erase()` 删除所有具有相同 key 的元素：

```cpp
mmap.erase(1);  // 删除所有 key 为 1 的元素
```

#### 如何按值排序 `multimap`？

`multimap` 默认按 key 排序。如果想按 value 排序，可以将 `multimap` 转为 `vector`，然后使用 `std::sort()` 排序。

```cpp
std::vector<std::pair<int, std::string>> vec(mmap.begin(), mmap.end());
std::sort(vec.begin(), vec.end(), [](const auto& a, const auto& b) {
    return a.second < b.second;  // 按 value 升序排序
});
```

### 拓展建议

- **使用场景**：`std::multimap` 非常适用于需要存储一个键对应多个值的场景，例如：学生成绩（同一科目多次成绩）、订单商品（一个订单可能包含多个相同商品）。
- 如果不需要重复的 key，可以使用 `std::map`，这会提供更高的性能和简化的逻辑。

### multimap 源码提要（只列出与 map 不同之处）

```cpp
template <class Key, class T, class Compare = less<Key>, class Alloc = alloc>
class multimap {
public:
    // typedefs：
    // ...(与 set 相同)

    // allocation / deallocation
    // 注意：multimap 一定使用 insert_equal() 而不使用 insert_unique()
    //       map 才使用 insert_unique()

    // 构造函数
    template <class InputIterator>
    multimap(InputIterator first, InputIterator last)
        : t(Compare()) {
        t.insert_equal(first, last);
    }

    template <class InputIterator>
    multimap(InputIterator first, InputIterator last, const Compare& comp)
        : t(comp) {
        t.insert_equal(first, last);
    }

    // insert / erase
    iterator insert(const value_type& x) {
        return t.insert_equal(x);
    }

    iterator insert(iterator position, const value_type& x) {
        return t.insert_equal(position, x);
    }

    template <class InputIterator>
    void insert(InputIterator first, InputIterator last) {
        t.insert_equal(first, last);
    }

    // ...(其它与 map 相同)
};
```

- **特性**：
   `multimap` 的特性和用法与 `map` 完全相同，唯一的差别在于 **允许键值重复**。
   因此它的插入操作采用底层机制 **RB-tree** 的 `insert_equal()`，而非 `insert_unique()`。
- **区别总结**：
  - `map` → 使用 `insert_unique()`，不允许相同键值。
  - `multimap` → 使用 `insert_equal()`，允许相同键值。