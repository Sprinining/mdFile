## 条款 8：优先考虑 nullptr 而非 0 和 NULL

### 原因一：**0 和 NULL 本质是整型，不是指针**

| 表达式    | 实际类型                                             |
| --------- | ---------------------------------------------------- |
| `0`       | `int`                                                |
| `NULL`    | 实现相关，通常是 `int` 或 `long`，但**不是指针类型** |
| `nullptr` | `std::nullptr_t`，可以隐式转换为**任意类型的指针**   |

### 原因二：**函数重载中容易选错**

```cpp
void f(int);
void f(bool);
void f(void*);

f(0);        // 调用 f(int)，不是你想的 f(void*)
f(NULL);     // 一般调用 f(int)，也不会调用 f(void*)
f(nullptr);  // 正确调用 f(void*)
```

`nullptr` 避免了因为整型优先级导致的错误重载决议。

### 原因三：**更明确的语义**

```cpp
auto result = findRecord(...);
if (result == 0)       // 不知道 result 是 int 还是指针
if (result == nullptr) // 明确：result 是指针类型
```

`nullptr` 让代码更具**可读性和意图表达性**。

### 原因四：**模板参数推导中的正确行为**

模板定义：

```cpp
template<typename Func, typename Mutex, typename Ptr>
auto lockAndCall(Func func, Mutex& mtx, Ptr ptr) -> decltype(func(ptr)) {
    std::lock_guard<Mutex> g(mtx);
    return func(ptr);
}
```

三种调用：

```cpp
lockAndCall(f1, m1, 0);         // 0 推导为 int，类型错误
lockAndCall(f2, m2, NULL);      // NULL 也被推导为整型，类型错误
lockAndCall(f3, m3, nullptr);   // 推导为 std::nullptr_t，可转换为任意指针
```

`nullptr` 是**模板友好型空指针常量**，不会因类型推导错误导致编译失败。

### nullptr 的类型特性

- 类型：`std::nullptr_t`。
- 能**隐式转换为任意指针类型**。
- **不能转换为整数类型**，因此不会误选 `int` 重载版本。
