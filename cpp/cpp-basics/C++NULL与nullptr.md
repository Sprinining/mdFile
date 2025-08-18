## C++ NULL 与 nullptr

在 C++ 中，`nullptr` 和 `NULL` 都表示空指针，但它们之间有一些关键区别，特别是在类型安全和现代 C++ 编程中的推荐使用方式上：

### NULL

通常被定义为 `0` 或 `((void*)0)`（依赖于编译器和平台）。

**类型不明确：** 在 C++ 中是一个整数常量，可能导致**函数重载歧义**。在 C++11 之后，应使用 `nullptr` 替代 `NULL`。

```cpp
void func(int);
void func(char*);

func(NULL); // 可能调用 func(int)，产生歧义
```

###   nullptr（C++11 引入）

**类型：**`std::nullptr_t`，是一个专门用于表示空指针的类型。

**类型安全：** 类型安全非常好，不会被误解为整数。

```cpp
void func(int);       // 重载1：接收int
void func(char*);     // 重载2：接收指针

func(nullptr); // 调用 func(char*)，类型清晰
```
