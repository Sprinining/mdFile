## map

`std::map` 是一个**关联容器**，以 **键值对（key-value）** 形式存储数据，具有以下特性：

- 键是唯一的（key 不可重复）
- 元素按 key **自动排序（默认升序）**
- 插入、删除、查找等操作的时间复杂度为 **O(logN)**

### 底层实现

- `std::map` **底层基于红黑树（Red-Black Tree）实现**
  - 红黑树是一种自平衡的二叉搜索树，插入/删除时通过旋转和变色保持树的平衡
  - 保证最坏情况下的操作（查找、插入、删除）为 O(logN)
- 所以：`std::map` 的 key 是**有序的**，不能随机访问

### 常用接口

#### 定义方式

```cpp
#include <map>
std::map<int, std::string> m;  // key: int, value: string
```

#### 插入元素

```cpp
m.insert({1, "apple"}); // 若 key 已经存在，插入操作将失败
m[2] = "banana"; // 如果 key 不存在则插入，存在则修改
m.emplace(3, "orange"); // 更高效的插入
```

#### 查找元素

```cpp
if (m.find(2) != m.end()) {
    std::cout << m[2] << std::endl;
}
```

#### 遍历 map

```cpp
for (auto& [key, value] : m) {
    std::cout << key << " => " << value << std::endl;
}
```

#### 删除元素

```cpp
m.erase(2); // 删除 key 为 2 的元素
```

#### 常用接口汇总

| 方法             | 说明                          |
| ---------------- | ----------------------------- |
| `insert({k, v})` | 插入键值对                    |
| `emplace(k, v)`  | 就地构造键值对（更快）        |
| `operator[]`     | 访问或插入元素                |
| `at(k)`          | 访问元素（若无则抛异常）      |
| `find(k)`        | 查找 key，返回迭代器          |
| `erase(k)`       | 删除 key 对应元素             |
| `clear()`        | 清空 map                      |
| `size()`         | 元素个数                      |
| `count(k)`       | 是否存在该 key（返回 0 或 1） |
| `begin()/end()`  | 迭代器                        |

### 使用示例

```cpp
#include <iostream>
#include <map>
using namespace std;

int main() {
    map<string, int> wordCount;
    string words[] = {"apple", "banana", "apple", "orange", "banana", "apple"};

    for (const auto& word : words) {
        wordCount[word]++;
    }

    for (auto& [word, count] : wordCount) {
        cout << word << ": " << count << endl;
    }

    return 0;
}
```

**输出：**

```css
apple: 3
banana: 2
orange: 1
```

### 常见问题

#### `map` 和 `unordered_map` 的区别？

| 对比项   | `map`               | `unordered_map`         |
| -------- | ------------------- | ----------------------- |
| 底层结构 | 红黑树              | 哈希表                  |
| 元素顺序 | 有序（按 key 排序） | 无序                    |
| 查找效率 | O(logN)             | O(1)（最优），最坏 O(N) |
| 内存占用 | 较少                | 较多                    |
| 使用场景 | 需要有序遍历        | 性能优先，快速查找      |

#### 如何自定义 key 类型？

```cpp
struct Point {
    int x, y;
    bool operator<(const Point& other) const {
        return tie(x, y) < tie(other.x, other.y);
    }
};

map<Point, string> pointMap;
```

`map` 的 key 类型必须能进行 `<` 比较，用于排序。

#### `map` 的 insert 和 operator[] 有什么区别？

| 方法               | 特性                                        |
| ------------------ | ------------------------------------------- |
| `m.insert({k, v})` | 如果 key 已存在，不会修改 value             |
| `m[k] = v`         | 如果 key 不存在，插入新值；否则会修改 value |
| `m.at(k)`          | 若 key 不存在会抛出异常                     |

#### 如何按 value 排序？

`map` 默认只能按 key 排序，若要按 value 排序，可将 map 转为 vector，再排序：

```cpp
vector<pair<string, int>> vec(m.begin(), m.end());
sort(vec.begin(), vec.end(), [](auto& a, auto& b){
    return a.second > b.second; // 降序
});
```

#### `map` 支持重复 key 吗？

- 不支持，key 唯一。
- 如果需要支持重复 key，用 `std::multimap`。

### 拓展建议

- 使用 `map` 时注意不要误用 `m[k]` 来查找是否存在，`m[k]` 会插入默认值
- 若无序 + 高性能需求，建议用 `unordered_map`
- 遇到性能瓶颈时，可考虑 `flat_map`、`sparse_map`（第三方库）
