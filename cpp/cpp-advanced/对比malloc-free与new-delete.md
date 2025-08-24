## 对比 malloc-free 与 new-delete

`malloc/free` 与 `new/delete` 是 C++ 中两种动态内存分配和释放的机制，分别源自 C 和 C++ 语言。它们在底层实现、用途、语义和使用场景上有显著差异。

### 基本语法和用途

| 功能     | `malloc` / `free`                  | `new` / `delete`              |
| -------- | ---------------------------------- | ----------------------------- |
| 来自语言 | C                                  | C++                           |
| 头文件   | `<stdlib.h>`                       | 无需头文件（是 C++ 的关键字） |
| 分配语法 | `void* p = malloc(size)`           | `T* p = new T(...)`           |
| 释放语法 | `free(p)`                          | `delete p`                    |
| 数组分配 | `int* a = malloc(n * sizeof(int))` | `int* a = new int[n]`         |
| 数组释放 | `free(a)`                          | `delete[] a`                  |

### 核心区别

1. 使用 `malloc` 分配结构体（不会调用构造函数）：

```cpp
struct Person {
    Person() { std::cout << "Constructor\n"; }
    ~Person() { std::cout << "Destructor\n"; }
};

Person* p1 = (Person*)malloc(sizeof(Person)); // 不会调用构造函数
free(p1);                                     // 不会调用析构函数
```

2. 使用 `new` 分配结构体（会调用构造函数）：

```cpp
Person* p2 = new Person(); // 会调用构造函数
delete p2;                 // 会调用析构函数
```

| 对比点                    | malloc/free                              | new/delete                                                   |
| ------------------------- | ---------------------------------------- | ------------------------------------------------------------ |
| **是否调用构造/析构函数** | 不调用构造函数和析构函数                 | 调用构造函数分配对象，调用析构函数释放对象                   |
| **返回类型**              | `void*`，需强制类型转换                  | 类型安全，不需要类型转换                                     |
| **失败处理**              | 返回 `NULL`                              | 抛出 `std::bad_alloc` 异常（除非使用 `new (nothrow)`）       |
| 底层函数                  | 通常调用 `brk/sbrk` 或 `mmap` 等         | 底层依赖于 `operator new()`，最终可能也是 malloc             |
| **自定义分配器**          | 不能重载                                 | 可以通过重载 `operator new` 和 `operator delete` 实现自定义分配器 |
| **灵活性**                | 可以方便地实现复杂的内存池等机制         | 更面向对象，适合常规对象的创建和销毁                         |
| **语义层面**              | 只是字节分配器，和类型无关               | 是对象创建工具，包含初始化和类型语义                         |
| 内存对齐                  | 平台相关（现代实现如 `jemalloc` 会处理） | C++ 编译器一般会处理好对齐问题                               |

### 使用场景

| 场景                  | 建议使用                               | 原因                                              |
| --------------------- | -------------------------------------- | ------------------------------------------------- |
| 面向对象编程          | `new/delete`                           | 自动调用构造/析构，类型安全                       |
| C 风格代码/底层内存池 | `malloc/free`                          | 更加灵活，可以与 `memcpy`/`realloc` 等结合使用    |
| STL 容器内部分配      | `new/delete`                           | STL 默认使用 allocator，底层使用 `::operator new` |
| 自定义内存管理器      | `malloc/free` 或更底层                 | 可直接操作字节，对象语义无关                      |
| 希望处理失败情况      | `new (nothrow)` 或检查 `malloc` 返回值 | 分别适用于异常/非异常                             |

### 定位 new

定位 new（placement new）是 C++ 中的一种**内存构造技术**，允许在**指定的内存地址上构造对象**，而不是通过 `new` 自动分配内存再构造对象。

普通 new：

```cpp
T* p = new T(args); // 分配内存 + 调用构造函数
```

定位 new：

```cpp
void* buffer = malloc(sizeof(T));  // 手动分配了内存
T* p = new (buffer) T(args);       // 在指定内存上“就地构造”对象
```

`new (地址) 类型` 是 `placement new` 的语法，它只做“构造”，不会分配内存。

适用场景

- 内存池（memory pool）
- 对象重用（避免频繁 new/delete）
- 嵌入式开发（精细控制内存）
- 需要在某块预分配的内存中构造对象
