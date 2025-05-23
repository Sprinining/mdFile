## C++动态内存

C++ 中的**动态内存**是指在运行时（而不是编译时）根据程序需要分配和释放内存的机制。与静态内存（如栈上分配的变量）相比，动态内存可以提供更大的灵活性，但也更容易出错（如内存泄漏、悬挂指针等）。

### 堆 vs 栈

| 方面     | 栈（Stack）                  | 堆（Heap）                              |
| -------- | ---------------------------- | --------------------------------------- |
| 分配方式 | 编译器自动分配               | 程序员手动分配（`new`/`malloc`）        |
| 生命周期 | 随函数调用自动创建/销毁      | 手动控制（`delete`/`free`），或智能指针 |
| 分配速度 | 非常快                       | 较慢                                    |
| 空间大小 | 较小（几 MB）                | 较大（系统最大空闲内存）                |
| 访问效率 | 高                           | 较低（需要通过指针访问）                |
| 释放风险 | 自动释放，几乎无内存泄漏风险 | 易发生泄漏、悬挂指针等问题              |
| 使用场景 | 临时变量、函数参数           | 大量数据、对象生命周期不确定            |

### 动态内存的基本方式

`new` 和 `delete`，这是 C++ 中分配和释放动态内存的核心操作。

- 单个对象

```cpp
int* p = new int(10);   // 分配一个 int，并初始化为 10
std::cout << *p << std::endl;
delete p;               // 释放内存
```

- 数组

```cpp
int* arr = new int[5];  // 分配一个 int 数组，大小为 5
for (int i = 0; i < 5; ++i) arr[i] = i;
delete[] arr;           // 释放数组（注意使用 delete[]）
```

> ⚠️ 使用 `new` 分配的内存，不会自动释放，需要显式调用 `delete`。

### 与 malloc/free 对比

- `new` 是一个 **运算符**，在分配内存后还会调用构造函数。

- `malloc` 是一个 **函数**，只负责分配原始内存，不调用构造函数。

- `delete` 会调用析构函数并释放内存，`free` 只释放内存。

```cpp
class MyClass {
public:
    MyClass() { std::cout << "Constructor\n"; }
    ~MyClass() { std::cout << "Destructor\n"; }
};

MyClass* obj = new MyClass(); // 调用构造函数
delete obj;                   // 调用析构函数
```

### 常见问题与错误

#### 1. 内存泄漏

```cpp
int* p = new int(42);
// 没有 delete p; => 内存泄漏
```

#### 2. 重复释放（double free）

```cpp
int* p = new int(5);
delete p;
delete p;  // ❌ 未将 p 置为 nullptr，重复释放
```

> 重复释放会导致什么？
>
> 1. 程序崩溃（最常见）
>
> 释放一块已释放的内存是未定义行为，可能会：
>
> - 立即崩溃（如触发段错误 Segmentation Fault）；
> - 或运行时出现 “*** Error in `./a.out`: double free or corruption ***” 等错误。
>
> 2. 隐蔽的 bug
>
> 有些平台上可能“看起来”没出错，但其实破坏了堆结构，**以后某处才崩溃**，更难调试。
>
> 3. 被利用为安全漏洞
>
> 攻击者可利用 double free **篡改内存管理结构**，造成**堆溢出攻击、远程代码执行（RCE）** 等严重后果。

#### 3. 忘记使用 `delete[]` 释放数组

```cpp
int* arr = new int[10];
delete arr;    // ❌ 未使用 delete[]，行为未定义
```

### 使用智能指针（推荐做法）

#### 1. `std::unique_ptr`

自动释放资源，不能共享所有权。

```cpp
#include <memory>
std::unique_ptr<int> p = std::make_unique<int>(10);
```

#### 2. `std::shared_ptr`

可以共享所有权，最后一个引用析构时释放资源。

```cpp
#include <memory>
std::shared_ptr<int> p1 = std::make_shared<int>(20);
std::shared_ptr<int> p2 = p1;
```

#### 3. `std::weak_ptr`

不增加引用计数，用于解决循环引用。

### 动态二维数组的分配与释放

```cpp
int rows = 3, cols = 4;
int** matrix = new int*[rows];
for (int i = 0; i < rows; ++i)
    matrix[i] = new int[cols];

// 使用 matrix[i][j]...

for (int i = 0; i < rows; ++i)
    delete[] matrix[i];
delete[] matrix;
```

