## string

`std::string` 是 C++ 标准库中用于表示和操作字符串的类，实质上是 `std::basic_string<char>` 的一个特化。它封装了字符数组，提供了丰富的字符串操作接口。

- **属于序列容器的特殊类型**，支持迭代器、索引访问。
- 主要用于存储和管理可变长度的字符序列。

### 底层原理

#### 内存管理

`std::string` 内部通常包含：

- 一个指向字符数组的指针（可能是堆上的）
- 当前字符串长度
- 容量（预分配空间）
- 小字符串优化（Small String Optimization，SSO）

#### 小字符串优化（SSO）

**SSO** 是编译器或库实现的一种性能优化手段：

**当字符串很短时，不使用堆内存，而是将字符串数据直接保存在 `std::string` 对象的内部缓冲区中。**

这样做可以：

- 避免频繁动态分配堆内存（`new` / `malloc`）
- 提高性能（尤其在大量短字符串操作中）
- 降低内存碎片

##### 背后原理

一个典型的 `std::string` 类对象内部结构，通常包括：

- 指向数据的指针
- 当前长度（`size`）
- 总容量（`capacity`）

但在启用 **SSO** 的实现中：

- 会用对象本身的空间（通常是 16~24 字节）存储较短字符串；
- 当字符串变长超出这个固定空间后，才会退化为普通堆分配模式。

##### 示意图

```cpp
struct String {
  union {
    char short_buffer[15];  // 小字符串缓冲
    char* heap_buffer;      // 长字符串指针
  };
  size_t size;
  bool using_sso;
};
```

实际结构因实现不同而异，例如 libstdc++、MSVC 和 libc++ 都不同，但思想类似。


##### string 对象本身分配在哪？

这取决于是怎么定义它的：

| 定义方式   | `std::string` 对象本身的位置 | 举例                                        |
| ---------- | ---------------------------- | ------------------------------------------- |
| 栈上定义   | 分配在 **栈上**              | `std::string s = "abc";`                    |
| `new` 出来 | 分配在 **堆上**              | `std::string* ps = new std::string("abc");` |
| 成员变量   | 随宿主对象分配位置而定       | 类成员、全局变量等                          |

`std::string` 是个普通对象，分配规则和 `int`、`struct` 一样。

##### string 管理的字符串内容在哪？

这个就和 **SSO** 是否生效有关了：

| 内容长度       | 存储位置             | 说明                                  |
| -------------- | -------------------- | ------------------------------------- |
| 较短（如 ≤15） | 存在 string 对象内部 | 启用 Small String Optimization（SSO） |
| 较长（超限）   | 单独堆上分配         | 用 `new` 或 `malloc` 分配字符串缓冲区 |

例如：

```cpp
std::string s1 = "hi";     // 栈上对象，内容可能也在栈（SSO）
std::string s2 = "long string exceeding SSO"; // 栈上对象，但内容堆上
```

所以，即使 `std::string` 是在栈上，它的字符数据**不一定在栈上**，取决于是否触发了 SSO。

##### 示例观察

可以通过观察地址判断 SSO 是否启用：

```cpp
#include <iostream>
#include <string>

int main() {
    std::string s1 = "short";
    std::string s2 = "this is a long string over 15 chars";

    std::cout << "s1.data(): " << static_cast<const void*>(s1.data()) << "\n";
    std::cout << "&s1:        " << static_cast<const void*>(&s1) << "\n";

    std::cout << "s2.data(): " << static_cast<const void*>(s2.data()) << "\n";
    std::cout << "&s2:        " << static_cast<const void*>(&s2) << "\n";
}
```

观察结果（大概率）：

- `s1.data()` 的地址 **与 `&s1` 很近**：说明用了对象内部缓冲
- `s2.data()` 的地址 **远离 `&s2`**：说明是堆上分配的

输出示例：

```css
s1.data(): 00000037238FF880
&s1:        00000037238FF878
s2.data(): 000001697320FEA0
&s2:        00000037238FF8B8
```

##### SSO 的优势

| 优点           | 说明                                     |
| -------------- | ---------------------------------------- |
| 减少堆内存分配 | 堆分配是开销最大的部分之一，SSO 避免了它 |
| 性能更高       | 在复制/构造/销毁短字符串时显著更快       |
| 降低内存碎片   | 特别适合频繁构造/析构小字符串的场景      |

##### 注意事项

- **SSO 是实现相关的**，C++ 标准并不要求一定启用 SSO，但主流实现都支持。
- 你不能依赖它的具体行为，比如 SSO 长度上限（一般是 15~23 字节）。
- 如果你写的是性能敏感代码，**注意短字符串的优化空间**。

### 主要接口

#### 构造与赋值

- `string s;`
- `string s("hello");`
- `string s2 = s;`
- 支持从 C 风格字符串、字符、重复字符构造。

#### 访问元素

- `s[i]`、`at(i)` 访问元素，带越界检查的为 `at()`
- `front()`、`back()`

#### 容量相关

- `size()`, `length()` 返回长度
- `capacity()` 返回分配容量
- `reserve(n)` 预分配空间
- `shrink_to_fit()` 尝试收缩容量

#### 修改操作

- `operator+=`、`append()`
- `insert()`, `erase()`
- `replace()`
- `clear()`
- `push_back(char c)`

#### 查找

- `find()`, `rfind()`
- `find_first_of()`, `find_last_of()`
- `substr(pos, len)`

#### 比较

- `compare()`
- 重载 `==`, `<`, `>` 等

#### 迭代器

- `begin()`, `end()`
- 支持标准算法

### 性能相关

- **动态扩容**：容量扩展时通常按倍数增长，摊销复杂度为 O(1)。
- **SSO 减少小字符串堆分配，显著提升性能。**
- **多线程环境下，字符串对象本身不保证线程安全。**

### 示例代码

```cpp
#include <iostream>
#include <string>
using namespace std;

int main() {
    string s = "hello";
    s += " world";
    cout << s << endl;             // hello world
    cout << s.size() << endl;      // 11

    cout << s.substr(6, 5) << endl; // world

    s.insert(5, ",");
    cout << s << endl;             // hello, world

    s.erase(5, 1);
    cout << s << endl;             // hello world

    if (s.find("world") != string::npos)
        cout << "Found world" << endl;

    return 0;
}
```

### 常见问题

1. **`std::string` 内存管理？**
    小字符串优化（SSO）是重点。
2. **`string` 和 C 字符串区别？**
    `string` 安全、自动管理内存；C 字符串是裸指针。
3. **如何避免内存复制？**
    使用 `reserve()` 预分配，避免频繁扩容。
4. **`string` 是不是线程安全？**
    不是，多个线程写同一对象需同步。
5. **`c_str()` 和 `data()` 有啥区别？**
    C++11 起两者几乎等价，`c_str()` 保证以 null 结尾。
6. **为什么不能直接返回指向内部缓冲区的指针用于修改？**
    因为可能导致未定义行为，且内部可能实现共享或只读优化。
