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

```cpp
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

```cpp
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