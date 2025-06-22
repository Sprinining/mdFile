## C++ allocator

`allocator` 是 C++ 标准库定义的一个内存分配器模板类，位于 `<memory>` 头文件中。它负责为容器（如 `std::vector`, `std::list` 等）分配和释放内存，以及构造和析构对象。

简单来说，`allocator` 把“内存管理”和“对象构造/析构”工作拆开，使得 STL 容器能灵活高效地管理内存。

### 为什么需要 `allocator`

- **解耦内存管理和容器逻辑**：容器只关心如何存储元素，不关心具体怎么分配内存。
- **允许自定义内存分配策略**：你可以用自己的 allocator 替代默认的 `std::allocator`，例如使用内存池、共享内存或特殊对齐分配等。
- **提升性能**：在某些场景自定义 allocator 可以减少内存碎片，提高性能。

### 核心接口

以 `std::allocator<T>` 为例，主要成员函数和类型如下：

```cpp
template <typename T>
struct allocator {
    // 类型别名
    using value_type = T;
    using pointer = T*;
    using const_pointer = const T*;
    using reference = T&;
    using const_reference = const T&;
    using size_type = size_t;
    using difference_type = ptrdiff_t;

    // 分配内存（未构造对象）
    pointer allocate(size_type n);

    // 释放内存（未调用析构函数）
    void deallocate(pointer p, size_type n);

    // 在指定内存上调用构造函数
    template<typename... Args>
    void construct(pointer p, Args&&... args);

    // 调用析构函数
    void destroy(pointer p);

    // 返回最大可分配对象数量
    size_type max_size() const noexcept;
};
```

#### 1. allocate

- 负责从堆上分配一块足够存储 `n` 个 `T` 的连续内存空间，**不调用构造函数**。
- 返回的是原始的内存地址指针，类型是 `T*`。
- 底层一般调用 `operator new`（非构造版本）或者平台相关的低层分配接口。

示例：

```cpp
T* p = alloc.allocate(5); // 分配5个T大小的原始内存
```

#### 2. deallocate

- 负责释放之前分配的内存块，不调用析构函数。
- 需要传入指向内存的指针和之前分配的对象数量（必须与 allocate 时的数量对应）。

示例：

```cpp
alloc.deallocate(p, 5); // 释放5个T对象大小的内存
```

#### 3. construct （构造对象）

- 作用是在已分配的内存上 **调用构造函数** 来构造一个对象。
- 参数是指向内存地址的指针 `p`，和传递给构造函数的参数包 `Args&&... args`。
- **它并不分配内存，只是构造对象。**

示例：

```cpp
alloc.construct(p, arg1, arg2);  // 在 p 指向的内存上调用构造函数 T(arg1, arg2)
```

##### C++17 以前

`std::allocator` 直接提供 `construct`，通常实现是：

```cpp
template <typename U, typename... Args>
void construct(U* p, Args&&... args) {
    ::new((void*)p) U(std::forward<Args>(args)...);  // 直接调用定位 new
}
```

##### C++17 变化

- C++17 标准中，`std::allocator::construct` **被弃用（deprecated）**，改用 `std::allocator_traits::construct` 来调用构造函数。
- 这是为了支持自定义 allocator 也能统一实现构造行为（可以更灵活地定义如何构造）。
- 所以在 C++17 及以后，通常写：

```cpp
std::allocator_traits<decltype(alloc)>::construct(alloc, p, args...);
```

而不是直接调用 `alloc.construct(...)`。

#### 4. destroy （销毁对象）

- 作用是调用指针 `p` 指向对象的析构函数，但**不释放内存**。
- 即调用 `p->~T()`。
- 和 `construct` 一样，C++17 之后推荐使用 `std::allocator_traits` 里的 `destroy`。

示例：

```cpp
alloc.destroy(p); // 调用 p 所指对象的析构函数
```

#### 5. max_size

- 返回分配器最多能分配多少个对象的大小，通常是 `std::numeric_limits<size_type>::max() / sizeof(T)`。
- 这是理论上最大分配容量，用于边界检查。

#### 额外说明

- 直接使用定位 new (`::new((void*)p) T(args...)`) 是构造对象的根本操作。
- `allocator_traits` 提供统一接口，能适配自定义 allocator，增强泛型代码的灵活性。
- `allocator` 只是内存分配和对象生命周期管理的工具，`construct` 和 `destroy` 是构造和析构的桥梁。

### 定位 new

定位 new（Placement new）是 C++ 中一个特殊的 `new` 操作符重载形式，它允许程序员在已分配的内存地址上直接构造对象，而不是像普通 `new` 那样先分配内存再构造对象。

#### 定位 new 的语法

```cpp
void* buffer = std::malloc(sizeof(MyClass)); // 手动申请一块原始内存

MyClass* obj = new (buffer) MyClass(constructor_args...);
```

这里 `(buffer)` 就是“定位参数”，告诉编译器“不要分配内存，就用这块已有的内存构造对象”。

#### 作用

- **分离分配内存和构造对象**：在某些需要手动管理内存的场景（比如自定义分配器、容器实现等），你先通过 `malloc`、`allocator.allocate()` 等方式申请内存，之后用定位 new 在那块内存上构造对象。
- **效率更高**：避免重复的内存分配，减少开销。
- **灵活控制对象生命周期**：可以更精细地控制内存和对象的构造/析构时机。

####  内存和对象生命周期的区别

普通 `new`：

- 先分配内存（`operator new`）
- 再调用构造函数

定位 new：

- 不分配内存，直接调用构造函数
- 需要程序员保证传入的内存足够且有效

#### 使用示例

```cpp
#include <iostream>
#include <new> // 需要包含

struct MyClass {
    int x;
    MyClass(int val) : x(val) { std::cout << "Constructed with " << x << std::endl; }
    ~MyClass() { std::cout << "Destroyed " << x << std::endl; }
};

int main() {
    // 1. 先申请原始内存
    void* buffer = std::malloc(sizeof(MyClass));

    // 2. 在 buffer 上构造对象
    MyClass* p = new (buffer) MyClass(42);

    // 3. 使用对象
    std::cout << p->x << std::endl;

    // 4. 手动调用析构函数（因为用的定位 new，不用 delete）
    p->~MyClass();

    // 5. 释放内存
    std::free(buffer);

    return 0;
}
```

#### 注意事项

- 定位 new 不会分配内存，只调用构造函数。
- 使用定位 new 后，**必须手动调用析构函数**，比如 `p->~MyClass()`，否则对象资源不会释放。
- 定位 new 的内存管理必须由程序员负责（`malloc/free`，或 `allocator`）。
- 定位 new 通常用于实现自定义内存池、容器内存管理等。

#### 标准库中的关系

`std::allocator<T>::construct` 内部就是用定位 new 来构造对象：

```cpp
void construct(pointer p, Args&&... args) {
    ::new((void *)p) T(std::forward<Args>(args)...);
}
```

### 简单使用示例

```cpp
#include <memory>
#include <iostream>

int main() {
    std::allocator<int> alloc;

    // 分配5个int的内存
    int* p = alloc.allocate(5);

    // 使用construct构造对象
    for (int i = 0; i < 5; ++i) {
        alloc.construct(p + i, i * 10);
    }

    // 打印元素
    for (int i = 0; i < 5; ++i) {
        std::cout << p[i] << " ";
    }
    std::cout << "\n";

    // 销毁对象
    for (int i = 0; i < 5; ++i) {
        alloc.destroy(p + i);
    }

    // 释放内存
    alloc.deallocate(p, 5);

    return 0;
}
```

### allocator 与 STL 容器

- STL 容器默认使用 `std::allocator<T>` 作为内存分配器。
- 容器内部使用 `allocate` 申请未构造的内存，再用 `construct` 构造元素。
- 删除元素时先 `destroy`，最后用 `deallocate` 释放内存。
- 也可以为容器指定自定义 allocator：

```cpp
std::vector<int, MyAllocator<int>> v;
```

### C++17 以后 allocator 的变化

- `construct` 和 `destroy` 在 C++17 后不再是 `allocator` 的成员函数，而是放到了全局命名空间，作为模板函数调用。
- `std::allocator` 也简化了很多，主要聚焦于内存分配和释放。
- 但是自定义 allocator 可以继续定义 `construct` 和 `destroy`。

```cpp
#include <memory>
#include <iostream>

int main() {
    std::allocator<int> alloc;

    // 通过 allocator_traits 访问 allocator 的相关操作
    using AllocTraits = std::allocator_traits<std::allocator<int>>;

    // 分配5个int的内存
    int* p = alloc.allocate(5);

    // 使用 allocator_traits::construct 构造对象
    for (int i = 0; i < 5; ++i) {
        AllocTraits::construct(alloc, p + i, i * 10);
    }

    // 打印元素
    for (int i = 0; i < 5; ++i) {
        std::cout << p[i] << " ";
    }
    std::cout << "\n";

    // 使用 allocator_traits::destroy 销毁对象
    for (int i = 0; i < 5; ++i) {
        AllocTraits::destroy(alloc, p + i);
    }

    // 释放内存
    alloc.deallocate(p, 5);

    return 0;
}
```

### 对比 free，delete，destroy

#### `free(void* p)`

- 来自 C 标准库，原型在 `<cstdlib>`。

- 释放用 `malloc` / `calloc` / `realloc` 分配的内存。

- **不调用析构函数**，因此不能用于释放有类类型对象的内存（会导致资源泄漏）。

- 只能释放纯内存块。

- 用例：

  ```cpp
  int* p = (int*)malloc(sizeof(int) * 10);
  free(p);  // 仅释放内存
  ```

####  `delete` / `delete[]`

- C++ 关键字运算符，配合 `new` 使用。

- 先调用指针指向对象的析构函数，执行清理操作。

- 然后释放 `new` 分配的内存。

- 区分 `delete`（单对象）和 `delete[]`（数组）。

- 用例：

  ```cpp
  MyClass* p = new MyClass;
  delete p;  // 调用析构函数 + 释放内存
  
  MyClass* arr = new MyClass[5];
  delete[] arr;  // 调用每个对象析构函数 + 释放内存
  ```

####  `destroy`（通常指 `std::allocator_traits::destroy`）

- STL 内存管理中使用的函数，用于调用对象的析构函数。

- **只调用析构函数，不释放内存**，内存释放由 `deallocate` 或其他机制负责。

- 适合于分离“构造/析构对象”和“分配/释放内存”的场景，容器经常这样做。

- 用例（假设使用 allocator）：

  ```cpp
  std::allocator<int> alloc;
  int* p = alloc.allocate(1);
  std::allocator_traits<std::allocator<int>>::construct(alloc, p, 42);
  
  // 只调用析构函数，内存还在
  std::allocator_traits<std::allocator<int>>::destroy(alloc, p);
  
  // 手动释放内存
  alloc.deallocate(p, 1);
  ```

| 名称      | 类型         | 功能                         | 作用对象                 | 是否调用析构函数 | 是否释放内存 | 典型用法                              |
| --------- | ------------ | ---------------------------- | ------------------------ | ---------------- | ------------ | ------------------------------------- |
| `free`    | C 标准库函数 | 释放用 `malloc` 分配的内存   | 原始内存块（无对象语义） | 不调用析构函数   | 是           | 释放 `malloc`、`calloc` 分配的内存    |
| `delete`  | C++ 运算符   | 调用对象析构函数，释放内存   | 由 `new` 分配的对象      | 是               | 是           | `delete p;` 销毁单个对象              |
| `destroy` | STL 函数     | 调用对象析构函数，不释放内存 | 已经分配好的对象内存     | 是               | 否           | 调用对象析构，但内存由 allocator 管理 |

### 示例：动态内存管理类

#### StrVec.h

```cpp
#pragma once  // 防止头文件被重复包含
#include <string>
#include <memory>  // std::allocator
#include <utility> // std::pair

// 一个简化版的 string vector 容器，模仿 std::vector<std::string>
class StrVec {
public:
    // 默认构造函数：初始化三个指针为空
    StrVec() : elements(nullptr), first_free(nullptr), cap(nullptr) {}

    // 拷贝构造函数
    StrVec(const StrVec&);

    // 拷贝赋值运算符
    StrVec& operator=(const StrVec&);

    // 析构函数，释放内存
    ~StrVec();

    // 添加一个元素到容器末尾（可能触发扩容）
    void push_back(const std::string&);

    // 返回当前元素个数
    size_t size() const { return first_free - elements; }

    // 返回当前容量（最多能容纳多少个元素）
    size_t capacity() const { return cap - elements; }

    // 返回指向第一个元素的指针（类似 begin()）
    std::string* begin() const { return elements; }

    // 返回指向最后一个元素之后的指针（类似 end()）
    std::string* end() const { return first_free; }

private:
    // 数据区起始指针
    std::string* elements;

    // 第一个空闲位置（下一个插入元素的位置）
    std::string* first_free;

    // 容量末尾位置指针（内存末尾，不可写入）
    std::string* cap;

    // 分配器，用于管理内存和构造/销毁元素
    std::allocator<std::string> alloc;

    // 检查容量是否足够，不足时调用 reallocate()
    void chk_n_alloc() {
        if (size() == capacity())
            reallocate();
    }

    // 分配内存并拷贝 [b, e) 范围的元素，返回 pair<新空间首地址, 拷贝结束地址>
    std::pair<std::string*, std::string*>
        alloc_n_copy(const std::string*, const std::string*);

    // 销毁所有元素并释放内存
    void free();

    // 重新分配更大空间，并移动旧元素到新空间
    void reallocate();
};
```

#### StrVec.cpp

```cpp
#include "StrVec.h"

// 拷贝构造函数：
// 1. 用 alloc_n_copy 申请新内存并拷贝 s 的所有元素
// 2. 初始化 elements 和 first_free，cap 等待之后设置
StrVec::StrVec(const StrVec& s) {
	auto new_data = alloc_n_copy(s.begin(), s.end());
	elements = new_data.first;
	first_free = new_data.second;
	cap = new_data.second; // 注意：cap 应该设置为 new_data.second
}

// 拷贝赋值运算符：
// 1. 用临时变量 copy rhs 的数据
// 2. 释放原有数据
// 3. 设置新的数据地址
StrVec& StrVec::operator=(const StrVec& rhs) {
	auto data = alloc_n_copy(rhs.begin(), rhs.end());
	free();
	elements = data.first;
	first_free = data.second;
	cap = data.second; // 同样 cap 也要设置（与原容器一致）
	return *this;
}

// 析构函数：释放资源
StrVec::~StrVec() {
	free();
}

// 添加一个元素到末尾
void StrVec::push_back(const std::string& s) {
	chk_n_alloc(); // 检查是否需要扩容

	// 使用 allocator_traits 的 construct：推荐写法（C++17）
	// 实际效果相当于：new (first_free) std::string(s);
	std::allocator_traits<decltype(alloc)>::construct(alloc, first_free++, s);
}

// 分配内存并拷贝字符串数组 [b, e)
// 返回 pair：first 是新内存的首地址，second 是拷贝完的尾地址
std::pair<std::string*, std::string*> StrVec::alloc_n_copy(const std::string* b, const std::string* e) {
	auto data = alloc.allocate(e - b); // 分配 (e - b) 个 std::string 的内存（但未构造）

	// 拷贝构造：将 [b, e) 区间的内容拷贝到 data 开始的位置
	// 返回值是 new_end（即 new_data + (e - b)）
	return { data, std::uninitialized_copy(b, e, data) };
}

// 释放所有元素并释放内存
void StrVec::free() {
	if (elements) {
		// 逆序调用 destroy，使用 allocator_traits 方式
		// 销毁构造过的元素（注意要逆序 destroy）
		for (auto p = first_free; p != elements;)
			std::allocator_traits<decltype(alloc)>::destroy(alloc, --p);// 调用析构函数 ~string()
		// 释放内存（注意：只释放分配的总容量，不是当前大小）
		alloc.deallocate(elements, cap - elements);
	}
}

// 扩容并移动已有元素
void StrVec::reallocate() {
	auto new_capacity = size() ? 2 * size() : 1;

	// 分配新的内存区域（new_capacity 个 string 空间，但未构造对象）
	auto new_data = alloc.allocate(new_capacity);

	// 用于记录目标写入位置（dest）和当前读元素（elem）
	auto dest = new_data;
	auto elem = elements;

	// 移动构造已有元素到新内存中
	for (size_t i = 0; i != size(); ++i)
		std::allocator_traits<decltype(alloc)>::construct(alloc, dest++, std::move(*elem++));

	// 释放旧内存
	free();

	// 更新指针
	elements = new_data;
	first_free = dest;
	cap = elements + new_capacity;
}
```

| 关键语法                                                   | 含义                                                         |
| ---------------------------------------------------------- | ------------------------------------------------------------ |
| `alloc.allocate(n)`                                        | 分配 n 个对象的原始内存（但未构造对象）                      |
| `std::allocator_traits<A>::construct(alloc, ptr, args...)` | 在 ptr 上使用 alloc 构造对象（推荐 C++17 写法）              |
| `std::uninitialized_copy(b, e, dest)`                      | 将 `[b,e)` 区间内容用拷贝构造的方式复制到 dest 开始的位置（需保证 dest 未构造） |
| `alloc.destroy(ptr)`                                       | 调用 ptr 指向对象的析构函数                                  |
| `alloc.deallocate(ptr, n)`                                 | 释放从 ptr 开始、大小为 n 的内存块                           |

#### Test.cpp

```cpp
#include "StrVec.h"
#include <iostream>

int main() {
    StrVec sv;

    std::cout << "初始 size: " << sv.size() << ", capacity: " << sv.capacity() << "\n";

    // 连续添加元素，触发多次 reallocate
    for (int i = 0; i < 10; ++i) {
        sv.push_back("str_" + std::to_string(i));
        std::cout << "push_back: " << sv.size() << ", capacity: " << sv.capacity() << "\n";
    }

    // 访问元素确认正确
    for (auto p = sv.begin(); p != sv.end(); ++p) {
        std::cout << *p << " ";
    }
    std::cout << "\n";

    // 拷贝构造
    StrVec sv2 = sv;
    std::cout << "复制后 sv2 size: " << sv2.size() << ", capacity: " << sv2.capacity() << "\n";

    // 拷贝赋值
    StrVec sv3;
    sv3 = sv;
    std::cout << "赋值后 sv3 size: " << sv3.size() << ", capacity: " << sv3.capacity() << "\n";

    return 0;
}
```

输出：

```css
初始 size: 0, capacity: 0
push_back: 1, capacity: 1
push_back: 2, capacity: 2
push_back: 3, capacity: 4
push_back: 4, capacity: 4
push_back: 5, capacity: 8
push_back: 6, capacity: 8
push_back: 7, capacity: 8
push_back: 8, capacity: 8
push_back: 9, capacity: 16
push_back: 10, capacity: 16
str_0 str_1 str_2 str_3 str_4 str_5 str_6 str_7 str_8 str_9
复制后 sv2 size: 10, capacity: 10
赋值后 sv3 size: 10, capacity: 1
```

