## vector

`std::vector` 是 C++ 标准库中提供的**动态数组容器**，支持快速随机访问，能够自动管理内存，使用灵活，是实际开发中最常用的 STL 容器之一。

### 底层原理

#### 内存结构

```css
data   --> [x][x][x][ ][ ][ ][ ]...
             ↑        ↑        ↑
           begin()   end()   capacity
```

底层通过三个指针管理状态：

- `begin()`：起始位置
- `end()`：最后一个元素之后（逻辑长度）
- `capacity()`：已分配空间的结尾（物理容量）

所有元素是**连续存储的**。

####  扩容机制（增长策略）

当元素数量 > capacity 时：

1. **分配更大的内存**（一般为原容量的约 1.5~2 倍）。
2. **拷贝旧数据到新内存**（调用元素的拷贝构造/移动构造）。
3. **释放旧内存**。

这个过程是**代价较高**的，因此建议预先 `reserve()` 以避免频繁扩容。

**注意**：扩容后原有的指针、引用、迭代器全部失效！

#### 内存管理

如果元素是自定义类型，插入或扩容时会调用：

- 构造函数
- 拷贝构造/移动构造
- 析构函数

所以定义 `struct`/`class` 时务必实现这几个方法！

### 常见接口

#### 构造与赋值

```cpp
vector<int> v1;                      // 默认构造
vector<int> v2(10);                  // 10 个默认值 0
vector<int> v3(5, 42);               // 5 个 42
vector<int> v4 = {1, 2, 3};          // 初始化列表
v1 = v4;                             // 拷贝赋值
v.assign(n, value);       // 重新赋值
```

#### 增删改查

```cpp
v.push_back(100);                   // 末尾添加
v.pop_back();                       // 删除最后一个元素
v.insert(v.begin() + 1, 200);       // 在指定位置插入
v.erase(v.begin() + 1);             // 删除指定位置元素
v.clear();                          // 清空所有元素
v[2] = 999;                         // 修改第3个元素
int x = v[2];                       // 访问元素（不检查越界）
```

#### 容量管理

```cpp
v.size();                           // 当前元素个数
v.capacity();                       // 分配的容量
v.empty();                          // 是否为空
v.reserve(100);                     // 提前分配容量
v.resize(20);                       // 调整大小，多余元素会析构，不足补默认值
```

#### 迭代器

```cpp
begin(), end()         // 普通迭代器
rbegin(), rend()       // 反向迭代器
cbegin(), cend()       // const 迭代器

for (auto it = v.begin(); it != v.end(); ++it) {}
for (int x : v) {}                  // 范围 for
auto r = std::find(v.begin(), v.end(), 42);
```

#### 其他常用操作

```cpp
std::sort(v.begin(), v.end());
std::reverse(v.begin(), v.end());
std::vector<int> v2(v.rbegin(), v.rend()); // 反转拷贝
```

### 使用建议

| 需求           | 建议                                  |
| -------------- | ------------------------------------- |
| 大量插入       | 使用 `reserve()` 预分配               |
| 不需要连续内存 | 考虑用 `list` 或 `deque`              |
| 插入删除频繁   | 尽量避免中间插入/删除，性能差         |
| 指针/引用      | vector 扩容时地址会变，存放指针需谨慎 |

### 底层源码简析（以 libstdc++ 为例）

```cpp
template<typename _Tp, typename _Alloc = std::allocator<_Tp>>
class vector {
    _Tp* _M_start;			// 指向元素的起始地址
    _Tp* _M_finish;			// 指向最后一个元素的“后一个地址”（即 size 末尾）
    _Tp* _M_end_of_storage;	// 指向分配内存块的“末尾地址”（即 capacity 尾部）
    // ...
};
```

`begin()`、`end()`、`capacity()` 是 **对用户暴露的接口**，它们的返回值是基于上面三个指针的：

| 接口         | 实际含义                       |
| ------------ | ------------------------------ |
| `begin()`    | 返回 `_M_start`                |
| `end()`      | 返回 `_M_finish`               |
| `size()`     | `_M_finish - _M_start`         |
| `capacity()` | `_M_end_of_storage - _M_start` |

扩容逻辑：

```cpp
void push_back(const T& val) {
    if (_M_finish == _M_end_of_storage)
        _M_reallocate();
    *_M_finish = val;
    ++_M_finish;
}
```

### 常见问题

#### `emplace_back()` vs `push_back()` 性能差异

| 操作      | `push_back()`          | `emplace_back()`            |
| --------- | ---------------------- | --------------------------- |
| 需求      | 需要现成对象           | 就地构造对象                |
| 拷贝/移动 | 可能触发拷贝或移动构造 | **直接构造，省略拷贝/移动** |
| 性能      | 较慢（多一步构造）     | 较快（就地构造）            |
| 使用场景  | 已有对象               | 直接传构造参数              |

#### vector 的内存释放为什么不一定及时？

因为 `capacity()` 大于 `size()`，即使 `clear()` 也不会释放已分配内存，除非用 `shrink_to_fit()`。

`shrink_to_fit()` 的行为与实际效果：

尝试将 `vector` 的容量缩小到等于其大小，**释放多余的内存**。

```cpp
std::vector<int> v = {1, 2, 3, 4, 5};
v.reserve(1000);          // 容量变大
v.resize(5);              // 元素变少，但内存仍大
v.shrink_to_fit();        // 请求回收未用内存
```

注意：它是 **non-binding request**

- **标准并不保证一定释放内存**。
- 实际是否释放取决于实现（libc++、libstdc++）和系统内存管理。
- 一般通过新分配内存再拷贝元素实现（可能引发移动构造或拷贝构造）。

#### 插入后使用原迭代器 / 指针

**vector 的扩容或中间插入，会导致内存重新分配**，原来的指针、引用、迭代器就不再指向合法位置，**变成了“悬空指针/迭代器”**，继续使用会导致未定义行为（可能崩溃、访问垃圾值等）。

```cpp
#include <iostream>
#include <vector>

int main() {
    std::vector<int> v;
    v.reserve(1);  // 先留一点空间，确保后续插入会触发扩容
    v.push_back(1);
    
    int* p = &v[0];          // 获取元素地址
    std::vector<int>::iterator it = v.begin();  // 获取迭代器

    v.push_back(2);          // 扩容发生，vector 内部地址可能变了！

    std::cout << *p << "\n"; // ❌ 悬空指针，未定义行为
    std::cout << *it << "\n";// ❌ 悬空迭代器，未定义行为
}
```

正确做法：

1. 插入或扩容后重新获取迭代器/指针

```cpp
auto it = v.begin();
v.push_back(42);       // 可能导致迭代器失效
it = v.begin();        // 重新获取！
```

2. 不在迭代过程中插入或删除

```cpp
for (auto it = v.begin(); it != v.end(); ++it) {
    if (*it == 3) {
        // v.push_back(100); // ❌ 迭代器失效
    }
}
```

3. 如果必须插入，先收集再操作

```cpp
std::vector<int> v = {1, 2, 3};
std::vector<int> to_add;

for (int x : v) {
    if (x % 2 == 1)
        to_add.push_back(x * 10);  // 不在原 vector 中操作
}

v.insert(v.end(), to_add.begin(), to_add.end());  // 统一处理
```

#### `vector<bool>` 奇葩在哪里？

##### bool 占 1 字节太浪费

在标准 `std::vector<T>` 中，每个元素是一个完整的 `T` 对象。

但对 `bool` 类型来说，每个布尔值其实只需要 1 位，而 `sizeof(bool)` 是 1 字节，也就是 **用了 8 倍空间**，太浪费了！

##### 设计目的：节省空间

为了节省空间，标准库特意对 `vector<bool>` 做了**模板特化**（不是偏特化，是完整特化）：

它不是 `vector<bool>` 的普通版本，而是这样的结构：

```cpp
template <>
class vector<bool> {
    // 使用位图压缩存储 bool（通常是 unsigned char 或 uint32_t）
    std::vector<uint8_t> data_;
    ...
};
```

它不是真的存储了 `bool` 类型，而是用一个**按位压缩的位容器**来模拟布尔数组。

比如：

```cpp
std::vector<bool> v = {true, false, true};
```

实际上在内部变成了一组位操作，比如：

```cpp
data_[0] = 0b00000101;
```

##### 带来的副作用

###### 无法返回 `bool&`

```cpp
std::vector<bool> v = {true};
bool* p = &v[0];  // 编译错误：不能取地址
```

因为它根本没有 `bool` 类型的内存，所以不能返回 `bool&`，也不能取地址。

为了解决这个问题，标准库搞了一个**代理对象** `vector<bool>::reference`，实现 `operator bool()`、`operator=` 等，但依然不是原生 bool。

###### 与泛型算法兼容性差

```cpp
template<typename T>
void test(std::vector<T>& v) {
    T* p = &v[0];  // vector<bool> 会报错
}
```

###### 不能安全和并发使用

由于多个 `bool` 被压缩进一个 `byte`，单个元素修改涉及位操作，因此并发修改两个 `bool` 也可能互相影响（**位竞争条件**），不像 `vector<int>` 是原子独立的。

##### 替代方案

| 场景         | 推荐替代                                      |
| ------------ | --------------------------------------------- |
| 简单用法     | `std::vector<char>` or `std::vector<uint8_t>` |
| 固定大小位集 | `std::bitset<N>`                              |
| 可变大小位集 | `boost::dynamic_bitset`                       |