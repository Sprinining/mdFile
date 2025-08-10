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

### 源码

- **排序规则**：元素按键值自动排序，键值不可重复。
- **元素结构**：每个元素是 `pair<const Key, T>`，`first` 是键值，`second` 是实值。
- **迭代器修改权限**：
  - 不能修改键值（会破坏排序规则）。
  - 可以修改实值（不影响排序）。
- **迭代器稳定性**：插入/删除其他元素不会使已有迭代器失效（被删除元素除外）。
- **底层实现**：基于红黑树（RB-tree），map 的大部分操作都是直接调用红黑树的方法。

#### `stl_pair.h` 中 `pair` 的定义

```cpp
// 模板结构 pair，用于存储两个类型不同的数据
template <class T1, class T2>
struct pair {
    // 类型别名，方便外部获取成员类型
    typedef T1 first_type;   // 第一个元素类型
    typedef T2 second_type;  // 第二个元素类型

    T1 first;   // 键值（public，可直接访问）
    T2 second;  // 实值（public，可直接访问）

    // 默认构造函数
    // 将 first 和 second 初始化为各自类型的默认值
    pair() : first(T1()), second(T2()) {}

    // 有参构造函数
    // 用传入的参数初始化 first 和 second
    pair(const T1& a, const T2& b) : first(a), second(b) {}
};
```

- `map` 的迭代器解引用时返回 `pair<const Key, T>`。

  - `first`（键）是 `const`，禁止修改。

  - `second`（值）可修改。

- 修改键会破坏红黑树的有序性，因此禁止。

- 修改值不影响排序规则，因此允许。

#### `map` 源码

 ```cpp
 // 注意：Key 为键值(key)型别，T 为实值(value)型别
 template <class Key, class T,
           class Compare = less<Key>, // 缺省采用递增排序
           class Alloc = alloc>
 class map {
 public:
     // --------------------
     // typedefs
     // --------------------
     typedef Key key_type;         // 键值类型
     typedef T data_type;          // 数据(实值)类型
     typedef T mapped_type;        // 同 data_type，映射值类型
     typedef pair<const Key, T> value_type; // 元素类型(键值/实值)，键为 const，值可变
     typedef Compare key_compare;  // 键值比较函数
 
     // value_compare 是一个仿函数，用来比较两个元素（其实比较的是它们的键）
     class value_compare
         : public binary_function<value_type, value_type, bool> {
         friend class map<Key, T, Compare, Alloc>;
     protected:
         Compare comp;
         value_compare(Compare c) : comp(c) {}
     public:
         bool operator()(const value_type& x, const value_type& y) const {
             return comp(x.first, y.first); // 只比较键
         }
     };
 
 private:
     // --------------------
     // 表述型别（底层容器类型）
     // --------------------
     // select1st<value_type>：取出 value_type 的 first 作为键值
     typedef rb_tree<key_type, value_type,
                     select1st<value_type>, // 从 pair 中取出键值
                     key_compare,
                     Alloc> rep_type;
     rep_type t; // 用红黑树(RB-tree)实现 map
 
 public:
     // --------------------
     // 指针与引用类型
     // --------------------
     typedef typename rep_type::pointer pointer;
     typedef typename rep_type::const_pointer const_pointer;
     typedef typename rep_type::reference reference;
     typedef typename rep_type::const_reference const_reference;
 
     // 注意：map 的 iterator 不是 const_iterator
     // 因为允许通过迭代器修改元素的实值(value)
     typedef typename rep_type::iterator iterator;
     typedef typename rep_type::const_iterator const_iterator;
     typedef typename rep_type::reverse_iterator reverse_iterator;
     typedef typename rep_type::const_reverse_iterator const_reverse_iterator;
     typedef typename rep_type::size_type size_type;
     typedef typename rep_type::difference_type difference_type;
 
     // --------------------
     // 构造与赋值
     // --------------------
     // 注意：map 一定使用底层 RB-tree 的 insert_unique()，不允许重复键
     // multimap 才使用 insert_equal()
     map() : t(Compare()) {}
     explicit map(const Compare& comp) : t(comp) {}
 
     template <class InputIterator>
     map(InputIterator first, InputIterator last)
         : t(Compare()) { t.insert_unique(first, last); }
 
     template <class InputIterator>
     map(InputIterator first, InputIterator last, const Compare& comp)
         : t(comp) { t.insert_unique(first, last); }
 
     map(const map<Key, T, Compare, Alloc>& x) : t(x.t) {}
 
     map<Key, T, Compare, Alloc>& operator=(
         const map<Key, T, Compare, Alloc>& x) {
         t = x.t;
         return *this;
     }
 
     // --------------------
     // 访问器
     // --------------------
     key_compare key_comp() const { return t.key_comp(); }
     value_compare value_comp() const { return value_compare(t.key_comp()); }
 
     iterator begin() { return t.begin(); }
     const_iterator begin() const { return t.begin(); }
     iterator end() { return t.end(); }
     const_iterator end() const { return t.end(); }
     reverse_iterator rbegin() { return t.rbegin(); }
     const_reverse_iterator rbegin() const { return t.rbegin(); }
     reverse_iterator rend() { return t.rend(); }
     const_reverse_iterator rend() const { return t.rend(); }
 
     bool empty() const { return t.empty(); }
     size_type size() const { return t.size(); }
     size_type max_size() const { return t.max_size(); }
 
     // 下标(subscript)操作符
     // 如果 key 不存在，则插入 {key, T()}，并返回其 value 的引用
     T& operator[](const key_type& k) {
         return (*((insert(value_type(k, T()))).first)).second;
     }
 
     void swap(map<Key, T, Compare, Alloc>& x) { t.swap(x.t); }
 
     // --------------------
     // 插入 / 删除
     // --------------------
     pair<iterator, bool> insert(const value_type& x) {
         return t.insert_unique(x);
     }
 
     iterator insert(iterator position, const value_type& x) {
         return t.insert_unique(position, x);
     }
 
     template <class InputIterator>
     void insert(InputIterator first, InputIterator last) {
         t.insert_unique(first, last);
     }
 
     void erase(iterator position) { t.erase(position); }
     size_type erase(const key_type& x) { return t.erase(x); }
     void erase(iterator first, iterator last) { t.erase(first, last); }
 
     void clear() { t.clear(); }
 
     // --------------------
     // 查找与范围
     // --------------------
     iterator find(const key_type& x) { return t.find(x); }
     const_iterator find(const key_type& x) const { return t.find(x); }
     size_type count(const key_type& x) const { return t.count(x); }
 
     iterator lower_bound(const key_type& x) { return t.lower_bound(x); }
     const_iterator lower_bound(const key_type& x) const {
         return t.lower_bound(x);
     }
 
     iterator upper_bound(const key_type& x) { return t.upper_bound(x); }
     const_iterator upper_bound(const key_type& x) const {
         return t.upper_bound(x);
     }
 
     pair<iterator, iterator> equal_range(const key_type& x) {
         return t.equal_range(x);
     }
 
     pair<const_iterator, const_iterator> equal_range(const key_type& x) const {
         return t.equal_range(x);
     }
 
     // --------------------
     // 比较运算符声明（原 SGI STL 格式）
     // --------------------
     friend bool operator== __STL_NULL_TMPL_ARGS (const map&, const map&);
     friend bool operator<  __STL_NULL_TMPL_ARGS (const map&, const map&);
 };
 
 // 比较运算符定义
 template <class Key, class T, class Compare, class Alloc>
 inline bool operator==(const map<Key, T, Compare, Alloc>& x,
                        const map<Key, T, Compare, Alloc>& y) {
     return x.t == y.t; // 直接调用底层红黑树的比较
 }
 
 template <class Key, class T, class Compare, class Alloc>
 inline bool operator<(const map<Key, T, Compare, Alloc>& x,
                       const map<Key, T, Compare, Alloc>& y) {
     return x.t < y.t;  // 直接调用底层红黑树的比较
 }
 ```

#### `map` 测试程序

```cpp
#include <map>
#include <iostream>
#include <string>
using namespace std;

int main() {
    map<string, int> simap;

    // 下标操作符（作为左值）
    simap[string("jjhou")] = 1;
    simap[string("jerry")] = 2;
    simap[string("jason")] = 3;
    simap[string("jimmy")] = 4;

    // insert() 插入
    pair<string, int> value("david", 5);
    simap.insert(value);

    // 遍历
    for (map<string, int>::iterator it = simap.begin(); it != simap.end(); ++it)
        cout << it->first << " " << it->second << endl;
    // david 5
    // jason 3
    // jerry 2
    // jimmy 4
    // jjhou 1

    // 下标操作符（作为右值）
    int number = simap[string("jjhou")];
    cout << number << endl; // 1

    // find() 搜索（比 STL 算法 find() 高效，因为底层是红黑树查找）
    map<string, int>::iterator itel;
    itel = simap.find("mchen");
    if (itel == simap.end())
        cout << "mchen not found" << endl;

    itel = simap.find("jerry");
    if (itel != simap.end())
        cout << "jerry found" << endl;

    // 通过迭代器修改 value（不能改 key）
    itel->second = 9;
    cout << simap["jerry"] << endl; // 9
}
```

##### `insert()` 函数

```cpp
pair<iterator, bool> insert(const value_type& x) {
    return t.insert_unique(x); 
}
```

- 调用底层 **RB-tree** 的 `insert_unique()`。
- 返回值是 `pair<iterator, bool>`：
  - `iterator` → 指向插入的元素（新元素或已有元素）
  - `bool` → 是否插入成功

##### 下标操作符 `operator[]`

- 可作 **左值**（插入或修改 value）或 **右值**（读取 value）。
- 返回值类型是 **引用**（by reference），保证可以读写。

实现关键代码（节选）：

```cpp
T& operator[](const key_type& k) {
    return (*((insert(value_type(k, T()))).first)).second;
}
```

执行过程：

1. 构造一个元素 `value_type(k, T())`（key = k，value = 默认值）。
2. 调用 `insert()` 尝试插入。
3. `insert()` 返回的 `pair.first` 是迭代器，指向新插入或已存在的元素。
4. 通过 `(*iterator).second` 获取 value 的引用。
5. 因为是引用，可以作为左值修改，也可以作为右值读取。

##### **要点**

- `map` 底层用红黑树，自动排序，`insert()` 和 `find()` 都是对红黑树的直接调用。
- 迭代器可修改 **value**，不可修改 **key**。
- `insert()` 返回插入位置和成功标志。
- `operator[]` 可能触发插入（当 key 不存在时）。
