## C++ 常见内存错误

### 野指针（Dangling Pointer）

指针指向已经被释放或无效的内存。

```cpp
int* p = new int(10);
delete p;
*p = 5; // 使用了悬空指针，未定义行为
```

### 悬挂引用（Dangling Reference）

引用指向已经销毁的对象。

```cpp
int& getRef() {
    int x = 10;
    return x; // 返回局部变量的引用
}
```

### 内存泄漏（Memory Leak）

申请的堆内存未被释放，导致程序运行时内存不断增长。

```cpp
void leak() {
    int* p = new int[100]; // 没有 delete[]
}
```

### 栈溢出（Stack Overflow）

递归过深或栈上分配过大的数组导致栈内存耗尽。

```cpp
void recurse() {
    recurse(); // 无限递归导致栈溢出
}
```

### 越界访问（Out-of-Bounds Access）

访问数组或容器时超出了有效索引范围。

```cpp
int arr[5];
arr[5] = 10; // 越界写入
```

### 重复释放（Double Free）

同一块内存被释放两次，会导致未定义行为。

```cpp
int* p = new int(5);
delete p;
delete p; // 重复释放
```

### 未初始化的指针（Uninitialized Pointer）

指针变量未初始化就使用，可能会指向不可预测的位置。

```cpp
int* p; // 未初始化
*p = 10; // 未定义行为
```

### 使用已释放内存（Use After Free）

内存释放后继续使用该地址。

```cpp
int* p = new int(42);
delete p;
std::cout << *p << std::endl; // 未定义行为
```

### 内存未对齐（Misaligned Access）（架构相关）

在某些硬件平台（如 ARM）中，不对齐的内存访问可能会崩溃或效率低下。

### 忘记使用 delete[]

用 `new[]` 分配的数组，必须用 `delete[]` 释放。

```cpp
int* arr = new int[10];
delete arr; // 应该是 delete[] arr;
```

###  解决办法

- 尽量使用**智能指针**（如 `std::unique_ptr`, `std::shared_ptr`）。
- 使用**RAII**模式管理资源。
- 使用**工具检测**内存错误：
  - `Valgrind`（Linux）
  - `AddressSanitizer`（Clang/GCC/MSVC）
  - `Visual Leak Detector`（Windows）