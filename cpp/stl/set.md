## set

`set` 是一个基于平衡二叉搜索树（如红黑树）的容器。它会自动对元素进行排序，且保证每个元素在集合中唯一。因为元素是有序的，所以查找、插入和删除的时间复杂度都是 O(log N)。

主要特性：

- **唯一性**：`set` 中的元素不允许重复。
- **自动排序**：元素会自动按照升序排序，如果需要自定义排序规则，可以通过自定义比较器（`comp`）来实现。
- **查找操作**：`set` 提供了 O(log N) 时间复杂度的查找操作。
- **支持迭代器**：`set` 支持通过迭代器遍历其元素。
- **不支持修改元素**：`set` 中的元素一旦插入后，不能修改；但是可以删除和插入新的元素。

### 底层实现原理

`set` 底层通常使用 **红黑树**（Red-Black Tree）来实现。红黑树是一种自平衡的二叉查找树，它通过对树结构的平衡操作确保插入、删除和查找操作的时间复杂度为 O(log N)。

红黑树的基本性质：

1. 每个节点要么是红色，要么是黑色。
2. 根节点是黑色。
3. 叶节点（NIL 节点）是黑色。
4. 红色节点的子节点必须是黑色的（即没有两个红色节点相连）。
5. 从任一节点到其所有后代叶子节点的路径上，黑色节点的数量相同。

由于红黑树的这些性质，`set` 可以确保在最坏情况下，操作时间复杂度不会超过 O(log N)，从而保证效率。

### 常用接口

1. **构造函数**
   - `set<T>`：默认构造函数，创建一个空的 `set`。
   - `set<T>(begin, end)`：使用另一个范围内的元素来初始化 `set`。
   - `set<T>(compare)`：使用指定的比较函数来初始化。
   - `set<T>(begin, end, compare)`：使用指定的比较函数和范围内的元素初始化。
2. **插入元素**
   - `insert(const T& value)`：插入一个元素，若元素已存在，则不插入。
   - `insert(iterator hint, const T& value)`：在指定位置插入元素，若元素已存在，则不插入。
   - `emplace(args...)`：就地构造一个元素并插入，避免了不必要的拷贝或移动。
3. **查找元素**
   - `find(const T& value)`：查找指定元素，返回一个迭代器，若找不到则返回 `end()`。
   - `count(const T& value)`：返回集合中指定元素的个数（`set` 中最多只有一个元素）。
4. **删除元素**
   - `erase(const T& value)`：删除指定元素。
   - `erase(iterator pos)`：删除指定位置的元素。
   - `erase(iterator first, iterator last)`：删除指定范围内的元素。
   - `clear()`：删除所有元素。
5. **大小和容量**
   - `size()`：返回元素个数。
   - `empty()`：判断集合是否为空。
   - `max_size()`：返回集合能够容纳的最大元素数。
6. **迭代器**
   - `begin()`：返回指向集合第一个元素的迭代器。
   - `end()`：返回指向集合最后一个元素后一个位置的迭代器。
   - `rbegin()`：返回指向集合最后一个元素的反向迭代器。
   - `rend()`：返回指向集合第一个元素之前的反向迭代器。
7. **自定义排序**
   - `set<T, Compare>`：通过 `Compare` 类型的比较器来控制元素的排序。

### 示例代码

#### 基本用法示例

```cpp
#include <iostream>
#include <set>

int main() {
    std::set<int> s;

    // 插入元素
    s.insert(10);
    s.insert(20);
    s.insert(15);

    // 查找元素
    if (s.find(20) != s.end()) {
        std::cout << "Found 20!" << std::endl;
    }

    // 遍历 set
    for (const int& x : s) {
        std::cout << x << " ";
    }
    std::cout << std::endl;

    // 删除元素
    s.erase(15);

    // 查看大小
    std::cout << "Size of set: " << s.size() << std::endl;

    return 0;
}
```

#### 使用自定义排序规则

```cpp
#include <iostream>
#include <set>

struct CustomCompare {
    bool operator()(int a, int b) const {
        return a > b;  // 降序排列
    }
};

int main() {
    std::set<int, CustomCompare> s;
    s.insert(10);
    s.insert(20);
    s.insert(15);

    for (const int& x : s) {
        std::cout << x << " ";
    }
    std::cout << std::endl;

    return 0;
}
```

### 常见问题

1. **`set` 和 `unordered_set` 的区别**
   - `set`：基于红黑树，元素有序，查找、插入、删除的时间复杂度为 O(log N)。
   - `unordered_set`：基于哈希表，元素无序，查找、插入、删除的时间复杂度为 O(1)（平均情况下）。
2. **`set` 和 `map` 的区别**
   - `set`：存储的是单一的元素值。
   - `map`：存储的是键值对（key-value）。
3. **如何删除 `set` 中的所有元素？**
   - 使用 `clear()` 方法。
4. **`set` 中元素是否可以重复？**
   - 不可以，`set` 中的每个元素是唯一的。
5. **如何查找 `set` 中的元素是否存在？**
   - 使用 `find()` 方法，若元素存在则返回该元素的迭代器，否则返回 `end()`。
6. **如何实现自定义排序？**
   - 通过定义一个比较函数或函数对象作为模板参数传递给 `set`。

### 其他相关知识

- **`multiset`**：与 `set` 类似，但允许重复元素。底层依然使用平衡二叉树。
- **性能优化**：在需要频繁查找或删除的场景下，`set` 是比 `vector` 或 `list` 更高效的选择。

### 源码

- 元素按键值自动排序，且**键值就是实值**，不允许重复。
- 不能通过迭代器修改元素值，因为修改会破坏排序规则，`set<T>::iterator` 实际是底层红黑树的 `const_iterator`。
- 插入或删除元素时，除被删除元素外，其他迭代器依然有效。
- 提供交集、并集、差集、对称差集等算法。
- 底层实现为 **红黑树**，set 的操作基本是转调用红黑树的接口。

```cpp
// set 的模板定义
template <class Key,                    // 元素类型（键类型）
          class Compare = less<Key>,    // 比较规则（缺省递增排序）
          class Alloc = alloc>          // 空间配置器
class set {
public:
    // --------------------
    // 类型定义（typedefs）
    // --------------------
    typedef Key key_type;               // 键类型
    typedef Key value_type;             // 元素类型（set 的元素键值即实值）
    typedef Compare key_compare;        // 键的比较函数
    typedef Compare value_compare;      // 元素的比较函数（和键比较相同）

private:
    /*
     identity 定义在 <stl_function.h>：
     template<class T>
     struct identity : public unary_function<T, T> {
         const T& operator()(const T& x) const { return x; }
     };
     identity 用于在底层红黑树中将 value_type 映射为 key_type
     因为 set 的键值和实值相同，所以直接返回元素本身即可。
    */

    // 底层容器类型：红黑树
    typedef rb_tree<key_type, value_type,
                    identity<value_type>, // 键值提取器
                    key_compare,          // 比较规则
                    Alloc> rep_type;

    rep_type t; // 用红黑树实现 set

public:
    // --------------------
    // 指针与引用类型
    // --------------------
    typedef typename rep_type::const_pointer pointer;
    typedef typename rep_type::const_pointer const_pointer;
    typedef typename rep_type::const_reference reference;
    typedef typename rep_type::const_reference const_reference;

    // 注意：iterator 定义为红黑树的 const_iterator
    // 这意味着 set 迭代器不能修改元素值（因为修改会破坏排序规则）
    typedef typename rep_type::const_iterator iterator;
    typedef typename rep_type::const_iterator const_iterator;
    typedef typename rep_type::const_reverse_iterator reverse_iterator;
    typedef typename rep_type::const_reverse_iterator const_reverse_iterator;
    typedef typename rep_type::size_type size_type;
    typedef typename rep_type::difference_type difference_type;

    // --------------------
    // 构造函数
    // --------------------
    set() : t(Compare()) {}
    explicit set(const Compare& comp) : t(comp) {}

    template <class InputIterator>
    set(InputIterator first, InputIterator last)
        : t(Compare()) { t.insert_unique(first, last); }

    template <class InputIterator>
    set(InputIterator first, InputIterator last, const Compare& comp)
        : t(comp) { t.insert_unique(first, last); }

    set(const set<Key, Compare, Alloc>& x) : t(x.t) {}

    set<Key, Compare, Alloc>& operator=(const set<Key, Compare, Alloc>& x) {
        t = x.t;
        return *this;
    }

    // --------------------
    // 访问器
    // --------------------
    key_compare key_comp() const { return t.key_comp(); }
    value_compare value_comp() const { return t.key_comp(); } // 实际上和 key_comp 相同

    iterator begin() const { return t.begin(); }
    iterator end() const { return t.end(); }
    reverse_iterator rbegin() const { return t.rbegin(); }
    reverse_iterator rend() const { return t.rend(); }

    bool empty() const { return t.empty(); }
    size_type size() const { return t.size(); }
    size_type max_size() const { return t.max_size(); }

    void swap(set<Key, Compare, Alloc>& x) { t.swap(x.t); }

    // --------------------
    // 插入操作（使用 insert_unique，保证键唯一）
    // --------------------
    typedef pair<iterator, bool> pair_iterator_bool;

    pair<iterator, bool> insert(const value_type& x) {
        pair<typename rep_type::iterator, bool> p = t.insert_unique(x);
        return pair<iterator, bool>(p.first, p.second);
    }

    iterator insert(iterator position, const value_type& x) {
        typedef typename rep_type::iterator rep_iterator;
        return t.insert_unique((rep_iterator&)position, x);
    }

    template <class InputIterator>
    void insert(InputIterator first, InputIterator last) {
        t.insert_unique(first, last);
    }

    // --------------------
    // 删除操作
    // --------------------
    void erase(iterator position) {
        typedef typename rep_type::iterator rep_iterator;
        t.erase((rep_iterator&)position);
    }

    size_type erase(const key_type& x) {
        return t.erase(x);
    }

    void erase(iterator first, iterator last) {
        typedef typename rep_type::iterator rep_iterator;
        t.erase((rep_iterator&)first, (rep_iterator&)last);
    }

    void clear() { t.clear(); }

    // --------------------
    // 查找与范围操作
    // --------------------
    iterator find(const key_type& x) const { return t.find(x); }
    size_type count(const key_type& x) const { return t.count(x); }

    iterator lower_bound(const key_type& x) const { return t.lower_bound(x); }
    iterator upper_bound(const key_type& x) const { return t.upper_bound(x); }

    pair<iterator, iterator> equal_range(const key_type& x) const {
        return t.equal_range(x);
    }

    // --------------------
    // 比较操作符
    // --------------------
    friend bool operator==(const set& x, const set& y) {
        return x.t == y.t;
    }
    friend bool operator<(const set& x, const set& y) {
        return x.t < y.t;
    }
    // 以下的 __STL_NULL_TMPL_ARGS 被定义为 <>
	// 这里的写法是为了兼容旧式 C++ 编译器的模板语法
	// 相当于 template<>，但写成宏方便统一修改
	operator== __STL_NULL_TMPL_ARGS (const set&, const set&);
	operator<  __STL_NULL_TMPL_ARGS (const set&, const set&);
};

// 上面只是声明，下面才是定义

// 判断两个 set 是否相等（底层红黑树相等）
template <class Key, class Compare, class Alloc>
inline bool operator==(const set<Key, Compare, Alloc>& x,
                       const set<Key, Compare, Alloc>& y) {
    return x.t == y.t;
}

// 判断一个 set 是否小于另一个 set（按底层红黑树的字典序比较）
template <class Key, class Compare, class Alloc>
inline bool operator<(const set<Key, Compare, Alloc>& x,
                      const set<Key, Compare, Alloc>& y) {
    return x.t < y.t;
}
```

- **set 的底层容器是红黑树 (`rb_tree`)**

  - 元素按键值自动排序。

  - 不允许重复（`insert_unique`）。

- **迭代器是 const_iterator**
  - 不能修改元素值，因为键值就是实值，改了会破坏红黑树结构。

- **接口几乎都是转调用红黑树的方法**
  - 插入、删除、查找、范围查询等操作全部委托给 `rb_tree`。

- **identity 函数对象**
  - 用于把元素值直接当作键值返回。