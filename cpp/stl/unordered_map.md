## unordered_map

`std::unordered_map` 是 C++11 引入

的关联容器，实现了 **哈希表（Hash Table）**。它基于**key-value 对存储数据**，通过哈希函数将 key 映射到桶数组（bucket）的位置，支持**快速插入、查找、删除**。

### 底层原理

#### 数据结构

底层主要由：

- **哈希桶数组（bucket array）**：数组中每个元素是一个桶，桶可以是一个链表或其他结构（如 C++20 可能为链式 + 开放寻址混合结构）。
- **哈希函数（Hash Function）**：将 key 映射成哈希值。
- **相等函数（Equality Function）**：用于判断 key 是否“等价”。

例如，插入 key 为 `"abc"` 的数据：

1. 使用 `std::hash<std::string>` 计算哈希值 `h`。
2. 计算桶索引：`bucket_index = h % bucket_count`
3. 插入到对应的桶中（链表或桶内结构）。

#### 时间复杂度（平均 vs 最坏）

| 操作        | 平均时间复杂度 | 最坏时间复杂度（哈希冲突严重） |
| ----------- | -------------- | ------------------------------ |
| 插入 insert | O(1)           | O(n)                           |
| 查找 find   | O(1)           | O(n)                           |
| 删除 erase  | O(1)           | O(n)                           |

### 常见成员函数

#### 插入元素

```cpp
// 方法1：operator[]
unordered_map<string, int> m;
m["apple"] = 10;  // 不存在则插入，存在则更新

// 方法2：insert
m.insert({"banana", 20});
m.insert(make_pair("cherry", 30));

// 方法3：emplace（推荐，避免多次拷贝）
m.emplace("peach", 40);
```

| 方法         | 是否插入默认值 | 是否允许重复 key | 是否覆盖已有值 | 拷贝构造次数         | 使用场景               |
| ------------ | -------------- | ---------------- | -------------- | -------------------- | ---------------------- |
| `operator[]` | 是             | 是               | 是             | 至少一次             | 常用写法，但可能副作用 |
| `insert`     | 否             | 否               | 否             | 至少一次             | 不想覆盖已有 key 的值  |
| `emplace`    | 否             | 否               | 否             | **最少（构造一次）** | 推荐方式，效率最佳     |

`unordered_map::operator[]` 的副作用：

```cpp
#include <unordered_map>
#include <iostream>

using namespace std;

int main() {
    unordered_map<int, int> st;

    // 这里插入 key = 0，值为 1
    st[0] = 1;  // 如果 key 不存在就插入；存在就更新

    // 这里会触发副作用：
    // 尝试访问 st[1]，因为 key=1 不存在，会自动插入一条 {1, 0}
    // 然后判断 st[1] == 9，自然是 false
    if (st[1] == 9)  // 副作用：插入了一个无用的默认值 key=1, value=0
        cout << "x";

    // 打印当前 map 中的元素数量
    // 实际上是 2，因为 key=1 被“无意中插入”了
    cout << st.size();  // 输出：2，而不是预期的 1！

    return 0;
}
```

- `unordered_map::operator[]` **会插入默认值**，不适用于“只查找”的场景。
- 要查值请用 `find()`，不要用 `[]`，否则你以为在“看”，实际在“写”。

#### 查找元素

```cpp
// 方法1：find
auto it = m.find("banana");
if (it != m.end()) {
    cout << it->second << endl;
}

// 方法2：operator[]（有副作用，会插入 key）
cout << m["apple"];  // 若不存在，会插入默认值0
```

#### 判断是否存在

```cpp
if (m.count("apple") > 0) {
    // 存在
}
```

#### 删除元素

```cpp
m.erase("banana");        // 根据 key 删除
m.erase(m.find("apple")); // 根据迭代器删除
```

#### 遍历所有元素（无序）

```cpp
for (auto& [key, val] : m) {
    cout << key << ": " << val << endl;
}
```

#### 其他操作

| 操作                    | 示例                     | 说明                    |
| ----------------------- | ------------------------ | ----------------------- |
| 清空                    | `m.clear()`              | 删除所有元素            |
| 当前元素个数            | `m.size()`               | 元素数量                |
| 是否为空                | `m.empty()`              | 是否为空                |
| 获取 bucket 数          | `m.bucket_count()`       | 当前桶的个数            |
| 查看某个 key 属于哪个桶 | `m.bucket("key")`        | 返回桶编号              |
| 修改负载因子阈值        | `m.max_load_factor()`    | 默认 1.0，可自定义      |
| 预留空间                | `m.reserve(n)`           | 提前分配空间避免 rehash |
| 重新哈希                | `m.rehash(bucket_count)` | 强制设置桶数量          |

### 负载因子与 rehash

#### 什么是负载因子（Load Factor）？

负载因子是衡量哈希表“拥挤程度”的指标：

```cpp
load_factor = size() / bucket_count()
```

- `size()`：当前存储的元素个数
- `bucket_count()`：当前哈希桶的个数

例子：

```cpp
unordered_map<int, int> m;
m.insert({1, 100});
m.insert({2, 200});
m.bucket_count();     // 假设为 8
m.size();             // 为 2
m.load_factor();      // = 2 / 8 = 0.25
```

#### 为什么需要负载因子？

负载因子越高，说明：

- 哈希桶里的元素越多，冲突越多
- 查找/插入的效率越差（链表越长）

> **解决方法：扩容 & rehash。**

当负载因子超过一定阈值（默认是 **1.0**），就会触发 rehash：

#### rehash 是什么？什么时候触发？

##### rehash 的触发条件

```cpp
if (size() > max_load_factor() * bucket_count()) {
    rehash();  // 自动扩容 + 重分布
}
```

如果插入一个新元素会让负载因子超过最大值，就自动 rehash

##### rehash 做了什么？

1. 计算新的桶数量（通常是原来 2 倍以上）
2. 重新申请内存（新的桶数组）
3. 把旧元素重新计算哈希值、插入新桶
4. 旧桶释放

##### rehash 的副作用

- 会导致所有迭代器、引用、指针 **失效**
- 是一个昂贵操作（涉及全部元素搬家）

#### 相关函数与手动控制方式

1. 查看负载因子

```cpp
float lf = m.load_factor();
```

2. 设置最大负载因子

```cpp
m.max_load_factor(0.75);  // 降低触发阈值（更快触发 rehash）
```

3. 手动扩容（推荐）

```cpp
m.reserve(10000);  // 自动根据负载因子推算出合理桶数并 rehash
```

等价于：

```cpp
// 容器会根据当前的最大负载因子 max_load_factor() 来计算需要的桶数
size_t target_bucket = ceil(10000 / m.max_load_factor());
// 调用 rehash(required_bucket_count) 来确保桶数足够大
m.rehash(target_bucket);
```

大多数 STL 实现为了哈希性能，会选择一个 **大于等于请求桶数** 的桶数，且是特殊数，比如：

- 素数（减少冲突）
- 2 的幂次方（便于快速计算哈希索引）

4. 强制设置桶数（慎用）

```cpp
m.rehash(2048);
```

- 强行设置桶数（必须 ≥ 当前 size）
- 不推荐手动调用，除非很明确知道要干啥

#### 负载因子 vs 性能

| 负载因子    | 含义                     | 对性能的影响              |
| ----------- | ------------------------ | ------------------------- |
| 低（<0.5）  | 桶多元素少，空间利用率低 | 占内存多，但查找更快      |
| 中（~0.75） | 推荐值                   | 折中性能与空间            |
| 高（>1.0）  | 桶太少元素太多，冲突严重 | 性能下降（链表/链冲突多） |

#### 性能优化建议

| 目的/场景                | 推荐做法                 |
| ------------------------ | ------------------------ |
| 大量插入前已知数量       | `reserve(n)`             |
| 内存敏感（不要求高性能） | 提高 `max_load_factor()` |
| 高性能要求（频繁查找）   | 降低 `max_load_factor()` |
| 小数据 map 初始化        | 初始化后手动 `rehash(n)` |

### 自定义类型作为 key

#### 自定义类型作为 key 的要求

`std::unordered_map` 和 `std::unordered_set` 是基于哈希表实现的，它们需要：

1. **哈希函数（hash function）**：把 key 映射成 `size_t` 类型的哈希值，决定元素存放桶的位置。
2. **相等比较函数（equality function）**：判断两个 key 是否相等，判断是否是同一个元素。

标准库默认只支持基本类型和标准库类型做 key。如果用自定义类型，必须满足这两个条件。

#### 重载 `operator==`

这个操作符用于比较两个 key 是否相等。

```cpp
struct MyKey {
    int a;
    int b;

    bool operator==(const MyKey& other) const {
        return a == other.a && b == other.b;
    }
};
```

- 一定要声明为 `const` 成员函数，且参数是 `const` 引用。
- 只要所有判定 key 等价的成员变量都相等，返回 `true`。

#### 特化 `std::hash` 模板

标准库用 `std::hash<Key>` 对象来计算哈希值。如果用自定义类型，需要自己写特化。

```cpp
namespace std {
    template<>
    struct hash<MyKey> {
        size_t operator()(const MyKey& k) const {
            // 计算成员变量 a 的哈希值
            size_t h1 = std::hash<int>()(k.a);

            // 计算成员变量 b 的哈希值
            size_t h2 = std::hash<int>()(k.b);

            // 下面这行代码是一个经典的“哈希合并”方法，来自 Boost 库的hash_combine技巧
            // 作用是把两个哈希值 h1 和 h2 混合成一个，减少碰撞的概率

            return h1 ^ (h2 + 0x9e3779b9 + (h1 << 6) + (h1 >> 2));

            /*
             * 详解：
             * - 0x9e3779b9 是一个“黄金分割数”（约为 2^32 / φ），用于散列时扰动，减少模式冲突
             * - (h1 << 6) 和 (h1 >> 2) 是对 h1 进行移位，增加信息混合
             * - h2 + 0x9e3779b9 + (h1 << 6) + (h1 >> 2) 整体扰动 h2
             * - 最后与 h1 做异或（^）操作，将两个哈希值均匀混合
             * 这样合成的哈希值更随机，减少哈希碰撞
             */
        }
    };
}
```

#### 通过模板参数传入 `hash` 和 `==` 函数

语法模板：

```cpp
unordered_set<KeyType, HashFunc, EqualFunc>
unordered_map<KeyType, ValueType, HashFunc, EqualFunc>
```

可以通过**构造函数或模板参数**传入自定义的 hash 和相等比较器。

```cpp
struct MyKey {
    int a, b;
};

// 自定义哈希函数
struct MyKeyHash {
    size_t operator()(const MyKey& k) const {
        return std::hash<int>()(k.a) ^ (std::hash<int>()(k.b) << 1);
    }
};

// 自定义相等比较器
struct MyKeyEqual {
    bool operator()(const MyKey& lhs, const MyKey& rhs) const {
        return lhs.a == rhs.a && lhs.b == rhs.b;
    }
};
```

```cpp
#include <unordered_set>
#include <iostream>

int main() {
    std::unordered_set<MyKey, MyKeyHash, MyKeyEqual> s;

    s.insert({1, 2});
    s.insert({1, 2});  // 不会重复插入

    std::cout << s.size() << std::endl;  // 输出 1
}
```

| 特化 `std::hash` + `operator==` | 传入 `hash` 和 `equal` 类型参数               |
| ------------------------------- | --------------------------------------------- |
| 修改了类型定义（侵入式）        | 不修改类型，适合第三方类型或临时用途          |
| 简洁明了，写一次可复用          | 灵活性高，可以为不同语义使用不同 hash / equal |
| 被 STL 自动识别使用             | 需要手动指定模板参数（稍微麻烦一点）          |

### 与其他容器比较

| 容器                 | 有序性     | 底层结构 | 查找复杂度 |
| -------------------- | ---------- | -------- | ---------- |
| `std::map`           | 有序       | 红黑树   | O(log n)   |
| `std::unordered_map` | 无序       | 哈希表   | O(1) 平均  |
| `std::vector` + find | 有序或无序 | 动态数组 | O(n)       |

### 常见注意事项 / 陷阱

1. 使用 `m["key"]` 会自动插入默认值，即使只是想查找。
   - 推荐 `find` 查找是否存在。
2. 哈希函数必须高质量，避免过多冲突导致性能退化。
3. 如果使用自定义 key，`std::hash` 与 `==` 必须一致：
   - 即相等的对象必须返回相同 hash 值。
4. 容器不稳定：增删元素后，迭代器可能失效（rehash 时尤为明显）。

### 查看桶状态

```cpp
#include <iostream>
#include <unordered_map>
using namespace std;

int main() {
    unordered_map<string, int> m;

    // 向 unordered_map 中插入若干键值对
    m["one"] = 1;
    m["two"] = 2;
    m["three"] = 3;
    m["four"] = 4;

    // 输出哈希表当前桶的数量（即 bucket_count）
    cout << "bucket_count: " << m.bucket_count() << endl;

    // 遍历所有桶，逐个输出每个桶中的元素（即查看哈希冲突分布情况）
    for (size_t i = 0; i < m.bucket_count(); ++i) {
        cout << "Bucket " << i << ": ";

        // 下面这段是“桶级迭代器”
        // m.begin(i) 表示第 i 个桶的起始位置
        // m.end(i) 表示第 i 个桶的结束位置（不包含）
        for (auto it = m.begin(i); it != m.end(i); ++it) {
            // 输出当前桶中的 key
            cout << it->first << " ";
        }

        cout << endl;  // 每个桶一行
    }
}
```

输出：

```cpp
bucket_count: 8
Bucket 0:
Bucket 1: two
Bucket 2:
Bucket 3: three
Bucket 4:
Bucket 5: four
Bucket 6:
Bucket 7: one
```

