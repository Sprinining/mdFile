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

### 源码

```cpp
// hash_multimap 的特性与 multimap 基本相同
// 唯一的区别：底层用 hashtable 存储（而不是平衡树），因此元素不会自动排序
// 插入采用 hashtable::insert_equal()，允许 key 重复
// 需要注意：如果 hashtable 不能处理某个类型（缺少 hash function），hash_multimap 也无法处理

template <
    class Key,                              // 键类型
    class T,                                // 值类型
    class HashFcn  = hash<Key>,             // 哈希函数
    class EqualKey = equal_to<Key>,         // 键比较函数（判断相等）
    class Alloc    = alloc                  // 内存分配器
>
class hash_multimap {
private:
    // hashtable 的模板参数说明：
    //   pair<const Key, T>  —— 存储的元素类型（键值对）
    //   Key                 —— 键类型
    //   HashFcn             —— 哈希函数
    //   select1st<...>      —— 从 pair 中取出 key 的函数对象
    //   EqualKey            —— 键比较函数
    //   Alloc               —— 分配器
    typedef hashtable<
        pair<const Key, T>, 
        Key,
        HashFcn,
        select1st<pair<const Key, T>>,
        EqualKey,
        Alloc
    > ht;

    ht rep; // 底层容器

public:
    // 类型定义（大部分直接来自底层 hashtable）
    typedef typename ht::key_type        key_type;
    typedef T                            data_type;
    typedef T                            mapped_type;
    typedef typename ht::value_type      value_type;
    typedef typename ht::hasher          hasher;
    typedef typename ht::key_equal       key_equal;

    typedef typename ht::size_type       size_type;
    typedef typename ht::difference_type difference_type;
    typedef typename ht::pointer         pointer;
    typedef typename ht::const_pointer   const_pointer;
    typedef typename ht::reference       reference;
    typedef typename ht::const_reference const_reference;

    typedef typename ht::iterator        iterator;
    typedef typename ht::const_iterator  const_iterator;

    // 访问哈希函数与键比较函数
    hasher     hash_funct() const { return rep.hash_funct(); }
    key_equal  key_eq()     const { return rep.key_eq(); }

public:
    // 构造函数
    // 默认大小为 100，hashtable 会调整为 >=100 的最接近质数
    hash_multimap() : rep(100, hasher(), key_equal()) {}
    explicit hash_multimap(size_type n) : rep(n, hasher(), key_equal()) {}
    hash_multimap(size_type n, const hasher& hf) : rep(n, hf, key_equal()) {}
    hash_multimap(size_type n, const hasher& hf, const key_equal& eql)
        : rep(n, hf, eql) {}

    // 支持迭代器区间构造（插入允许重复 key）
    template <class InputIterator>
    hash_multimap(InputIterator f, InputIterator l)
        : rep(100, hasher(), key_equal()) { rep.insert_equal(f, l); }

    template <class InputIterator>
    hash_multimap(InputIterator f, InputIterator l, size_type n)
        : rep(n, hasher(), key_equal()) { rep.insert_equal(f, l); }

    template <class InputIterator>
    hash_multimap(InputIterator f, InputIterator l, size_type n, const hasher& hf)
        : rep(n, hf, key_equal()) { rep.insert_equal(f, l); }

    template <class InputIterator>
    hash_multimap(InputIterator f, InputIterator l, size_type n,
                  const hasher& hf, const key_equal& eql)
        : rep(n, hf, eql) { rep.insert_equal(f, l); }

public:
    // 基本容量操作
    size_type size()      const { return rep.size(); }
    size_type max_size()  const { return rep.max_size(); }
    bool      empty()     const { return rep.empty(); }

    void swap(hash_multimap& hs) { rep.swap(hs.rep); }

    // 友元声明（定义在类外）
    friend bool operator== __STL_NULL_TMPL_ARGS(const hash_multimap&,
                       const hash_multimap&) ;

    // 迭代器
    iterator       begin()       { return rep.begin(); }
    iterator       end()         { return rep.end(); }
    const_iterator begin() const { return rep.begin(); }
    const_iterator end()   const { return rep.end(); }

public:
    // 插入（允许重复 key）
    iterator insert(const value_type& obj) { return rep.insert_equal(obj); }

    template <class InputIterator>
    void insert(InputIterator f, InputIterator l) { rep.insert_equal(f, l); }

    iterator insert_noresize(const value_type& obj) {
        return rep.insert_equal_noresize(obj);
    }

    // 查找
    iterator       find(const key_type& key)       { return rep.find(key); }
    const_iterator find(const key_type& key) const { return rep.find(key); }

    size_type count(const key_type& key) const { return rep.count(key); }

    pair<iterator, iterator> equal_range(const key_type& key) {
        return rep.equal_range(key);
    }

    pair<const_iterator, const_iterator> equal_range(const key_type& key) const {
        return rep.equal_range(key);
    }

    // 删除
    size_type erase(const key_type& key) { return rep.erase(key); }
    void erase(iterator it)              { rep.erase(it); }
    void erase(iterator f, iterator l)   { rep.erase(f, l); }
    void clear()                         { rep.clear(); }

public:
    // 桶相关（hash table 特有的）
    void      resize(size_type hint)             { rep.resize(hint); }
    size_type bucket_count()      const          { return rep.bucket_count(); }
    size_type max_bucket_count()  const          { return rep.max_bucket_count(); }
    size_type elems_in_bucket(size_type n) const { return rep.elems_in_bucket(n); }
};

// 友元函数在类外实现
template <class Key, class T, class HF, class EqKey, class Alloc>
inline bool operator==(const hash_multimap<Key, T, HF, EqKey, Alloc>& hm1,
                       const hash_multimap<Key, T, HF, EqKey, Alloc>& hm2) {
    return hm1.rep == hm2.rep;
}
```

