## unordered_set

`std::unordered_set` 是一个 **存储唯一元素** 的集合容器，其特点是：

- 元素无序（内部使用哈希表）
- 不允许重复元素
- 插入、查找、删除操作的 **平均时间复杂度为 O(1)**

**典型使用场景：**

- 判断是否存在某元素（查重）
- 快速去重
- 实现集合的“集合运算”：并集、交集、差集（使用循环实现）

### 底层原理

#### 哈希表结构

`unordered_set` 底层使用 **哈希表（hash table）** 实现，结构类似这样：

```css
桶数组（buckets）：每个 bucket 是一个链表或链式结构，称为“槽位”

哈希函数(hash_fn) -> 元素值 -> 哈希值 -> 对 bucket 数取模 -> 落入某个槽位（桶）
```

例如插入元素 `7`：

```cpp
bucket_index = hash(7) % bucket_count;
```

#### 哈希冲突与桶

当多个元素映射到同一个 bucket 时，会在该桶中以链表/链表节点形式保存（C++ STL中常见是链表结构）。这就叫做“哈希冲突”。

例如：

```css
bucket[0] -> 7 -> 17 -> 27（哈希值相同模 bucket_count）
```

#### 负载因子（load factor）

**负载因子 = 元素数量 / 桶数量**

当负载因子超过阈值时（默认为 `1.0`），会自动触发 **rehash**（重新分配更大的桶数组并重新映射元素）。

可以手动控制 rehash：

```cpp
uset.rehash(128);      // 至少分配128个桶
uset.reserve(1000);    // 预留空间，提高性能（避免频繁rehash）
```

#### 哈希函数与相等函数

- 默认使用 `std::hash<T>` 作为哈希函数
- 使用 `==` 判断两个元素是否相等

### 常用接口

#### 构造函数

```cpp
unordered_set<int> uset;
unordered_set<int> uset = {1, 2, 3, 4};
```

#### 插入元素

```cpp
uset.insert(5);          // 插入 5，如果已存在则无效
```

#### 查找元素

```cpp
auto it = uset.find(5);  // 如果找到返回迭代器，否则返回 uset.end()
if (it != uset.end())
    cout << "Found: " << *it << endl;
```

#### 删除元素

```cpp
uset.erase(3);           // 删除 key 为 3 的元素
uset.erase(it);          // 删除某个迭代器指向的元素
```

#### 遍历

```cpp
for (int x : uset)
    cout << x << " ";
```

#### 大小与状态

```cpp
uset.size();             // 当前元素数量
uset.empty();            // 是否为空
uset.clear();            // 清空所有元素
```

#### 哈希表相关

```cpp
uset.bucket_count();           // 当前桶的数量
uset.load_factor();           // 当前负载因子
uset.max_load_factor();       // 最大负载因子
uset.rehash(n);               // 设置桶数量
uset.reserve(n);              // 预留空间，提升性能
```

### 自定义类型支持

自定义类型如结构体、类，必须提供：

1. 哈希函数
2. 等值比较函数

```cpp
struct Point {
    int x, y;
    bool operator==(const Point& other) const {
        return x == other.x && y == other.y;
    }
};

struct PointHash {
    size_t operator()(const Point& p) const {
        return hash<int>()(p.x) ^ (hash<int>()(p.y) << 1);
    }
};

unordered_set<Point, PointHash> points;
```

也可以用 `std::unordered_set<Point, PointHash, PointEqual>` 显式提供相等比较函数。

### 性能分析与对比

| 操作     | `std::set`（红黑树） | `std::unordered_set`（哈希表） |
| -------- | -------------------- | ------------------------------ |
| 插入     | O(log n)             | O(1) 平均                      |
| 删除     | O(log n)             | O(1) 平均                      |
| 查找     | O(log n)             | O(1) 平均                      |
| 有序遍历 | 支持                 | 不支持（无序）                 |
| 占用内存 | 较少（树结构）       | 较多（哈希表和桶）             |

### STL `set` 与 SGI `hash_set`

#### 标准与实现

- **STL 标准**：只规范了容器的**接口**与**复杂度要求**，不规定具体实现方式。
- **常见实现**：`set` 多数以 **红黑树（RB-tree）** 为底层实现。
- **SGI STL 扩展**：额外提供了 `hash_set`，底层使用 **hashtable**。

#### `hash_set` 的实现特点

- `hash_set` 的绝大多数操作都是**转调用 hashtable** 的接口。
- 底层机制不同：
  - **RB-tree**：支持自动排序（`set` 元素有序）。
  - **hashtable**：不保证顺序（`hash_set` 元素无序）。

#### `set` 与 `hash_set` 的共同点

- 都可**快速查找元素**（复杂度：O(log n) vs O(1)）。
- 元素的 **键值即实值**（不同于 `map` 的 key-value 结构）。
- 使用方式几乎相同。

#### 限制

- 若底层 hashtable 无法处理某种类型（例如缺少 `hash function`），`hash_set` 也无法处理，需用户自定义 `hash`。

### 源码

```cpp
template <
    class Value,
    class HashFcn = hash<Value>,                 // 哈希函数，默认使用 hash<Value>
    class EqualKey = equal_to<Value>,            // 判断键是否相等的函数对象，默认使用 equal_to
    class Alloc = alloc                          // 内存分配器
>
class hash_set {
private:
    // identity<T>：恒等函数对象，返回参数本身。
    // 在 set 中，键值即实值，所以 keyExtractor 直接用 identity
    typedef hashtable<
        Value,              // 节点存储的类型（即 value_type）
        Value,              // key_type（这里与 value_type 相同）
        HashFcn,            // 哈希函数
        identity<Value>,    // 从 value 提取 key 的方式（直接返回）
        EqualKey,           // 键值比较方式
        Alloc               // 内存分配器
    > ht;

    ht rep;  // 底层用 hashtable 实现所有功能

public:
    // 一堆 typedef，直接复用 hashtable 的类型定义
    typedef typename ht::key_type        key_type;
    typedef typename ht::value_type      value_type;
    typedef typename ht::hasher          hasher;
    typedef typename ht::key_equal       key_equal;

    typedef typename ht::size_type       size_type;
    typedef typename ht::difference_type difference_type;
    typedef typename ht::const_pointer   pointer;
    typedef typename ht::const_pointer   const_pointer;
    typedef typename ht::const_reference reference;
    typedef typename ht::const_reference const_reference;
    typedef typename ht::const_iterator  iterator;        // 注意：const_iterator（set 元素不可修改）
    typedef typename ht::const_iterator  const_iterator;

    // 获取当前使用的哈希函数对象
    hasher hash_funct() const { return rep.hash_funct(); }
    // 获取当前使用的键比较函数对象
    key_equal key_eq() const { return rep.key_eq(); }

public:
    // ===============================
    // 构造函数
    // ===============================
    // 默认构造：初始容量 100（hashtable 会调整为 >=100 的最小质数）
    hash_set() : rep(100, hasher(), key_equal()) {}

    explicit hash_set(size_type n)
        : rep(n, hasher(), key_equal()) {}

    hash_set(size_type n, const hasher& hf)
        : rep(n, hf, key_equal()) {}

    hash_set(size_type n, const hasher& hf, const key_equal& eql)
        : rep(n, hf, eql) {}

    // 迭代器区间构造（插入时调用 insert_unique，不允许重复键）
    template <class InputIterator>
    hash_set(InputIterator f, InputIterator l)
        : rep(100, hasher(), key_equal()) { rep.insert_unique(f, l); }

    template <class InputIterator>
    hash_set(InputIterator f, InputIterator l, size_type n)
        : rep(n, hasher(), key_equal()) { rep.insert_unique(f, l); }

    template <class InputIterator>
    hash_set(InputIterator f, InputIterator l, size_type n, const hasher& hf)
        : rep(n, hf, key_equal()) { rep.insert_unique(f, l); }

    template <class InputIterator>
    hash_set(InputIterator f, InputIterator l, size_type n,
             const hasher& hf, const key_equal& eql)
        : rep(n, hf, eql) { rep.insert_unique(f, l); }

public:
    // ===============================
    // 容量相关
    // ===============================
    size_type size() const { return rep.size(); }
    size_type max_size() const { return rep.max_size(); }
    bool empty() const { return rep.empty(); }

    // 交换两个 hash_set 的内容
    void swap(hash_set& hs) { rep.swap(hs.rep); }

    // 友元声明（定义在类外）
    friend bool operator== __STL_NULL_TMPL_ARGS
        (const hash_set& hs1, const hash_set& hs2);

    // ===============================
    // 迭代器相关
    // ===============================
    iterator begin() const { return rep.begin(); }
    iterator end() const { return rep.end(); }

public:
    // ===============================
    // 插入操作（不允许重复）
    // ===============================
    pair<iterator, bool> insert(const value_type& obj) {
        // 调用底层 hashtable 的 insert_unique
        pair<typename ht::iterator, bool> p = rep.insert_unique(obj);
        return pair<iterator, bool>(p.first, p.second);
    }

    template <class InputIterator>
    void insert(InputIterator f, InputIterator l) {
        rep.insert_unique(f, l);
    }

    pair<iterator, bool> insert_noresize(const value_type& obj) {
        // 与 insert 类似，但不会自动扩容
        pair<typename ht::iterator, bool> p = rep.insert_unique_noresize(obj);
        return pair<iterator, bool>(p.first, p.second);
    }

    // ===============================
    // 查找 / 统计
    // ===============================
    iterator find(const key_type& key) const { return rep.find(key); }
    size_type count(const key_type& key) const { return rep.count(key); }

    pair<iterator, iterator> equal_range(const key_type& key) const {
        return rep.equal_range(key);
    }

    // ===============================
    // 删除
    // ===============================
    size_type erase(const key_type& key) { return rep.erase(key); }
    void erase(iterator it) { rep.erase(it); }
    void erase(iterator f, iterator l) { rep.erase(f, l); }

    // 清空容器
    void clear() { rep.clear(); }

public:
    // ===============================
    // 桶相关操作（hash table 专有）
    // ===============================
    void resize(size_type hint) { rep.resize(hint); }
    size_type bucket_count() const { return rep.bucket_count(); }
    size_type max_bucket_count() const { return rep.max_bucket_count(); }
    size_type elems_in_bucket(size_type n) const { return rep.elems_in_bucket(n); }
};

// 比较运算符重载
template <class Value, class HashFcn, class EqualKey, class Alloc>
inline bool operator==(
    const hash_set<Value, HashFcn, EqualKey, Alloc>& hs1,
    const hash_set<Value, HashFcn, EqualKey, Alloc>& hs2) {
    return hs1.rep == hs2.rep;
}
```

