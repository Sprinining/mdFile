## 条款14：如果函数不抛出异常请使用 noexcept

### 为什么使用 noexcept

1. **更安全的接口设计：**
   `noexcept` 是函数接口的一部分，明确告知调用者「不会抛异常」。
2. **启用更多优化：**
   编译器对 `noexcept` 函数可以省略异常处理机制，生成更高效代码。
3. **支持 STL 的强异常安全保证：**
   如 `std::vector::push_back`、`std::swap` 等需要知道操作是否会抛异常，才能决定是否使用移动操作。

### noexcept VS 旧式异常说明

| 写法                 | 说明                     |
| -------------------- | ------------------------ |
| `void f() throw();`  | C++98 写法，已废弃       |
| `void f() noexcept;` | C++11+ 写法，推荐        |
| `void f();`          | 无声明，不清楚是否抛异常 |

### 应该在哪些函数上加 noexcept

- 明确不会抛异常的函数
- 移动构造 / 移动赋值（性能关键）
- `swap` 函数
- 析构函数（默认隐式 `noexcept`，除非成员可能抛异常）
- delete 操作符（默认 `noexcept`）

### STL 是如何利用 noexcept 的

- STL 会使用 `std::move_if_noexcept()`：

  ```cpp
  if (is_nothrow_move_constructible<T>::value || !is_copy_constructible<T>::value)
      std::move(t); // 否则保守地使用复制
  ```

- `std::swap` 是否 `noexcept` 取决于你提供的类型 `T` 的 `swap` 是否 `noexcept`：

  ```cpp
  template<typename T>
  void swap(T& a, T& b) noexcept(noexcept(a.swap(b)));
  ```

  这是一个经典的 **条件 noexcept**：

  - 如果 `a.swap(b)` 本身是 `noexcept` 的，那 `swap` 也是；
  - 如果 `a.swap(b)` 有抛异常的可能，那 `swap` 也不是 `noexcept`。

| 概念                       | 含义                                       |
| -------------------------- | ------------------------------------------ |
| `noexcept`                 | 声明函数不抛异常                           |
| `noexcept(expr)`           | 编译时判断某个表达式是否抛异常，返回布尔值 |
| `noexcept(noexcept(expr))` | 用在函数声明中，形成“条件 noexcept”        |

### 不要滥用 noexcept

不要为“异常中立”函数加上 `noexcept`：

```cpp
void logToFile(const std::string& msg); // 可能内部 I/O 抛异常
void doSomething() noexcept {           // 错误声明
    logToFile("doing work");            // 若抛异常将终止程序
}
```

###  宽泛契约 vs 严格契约

| 类型     | 特征                             | 是否建议加 `noexcept`                           |
| -------- | -------------------------------- | ----------------------------------------------- |
| 宽泛契约 | 没有前置条件，任意状态下都能调用 | 建议加 `noexcept`                               |
| 严格契约 | 有前置条件，违反时可能未定义行为 | 若使用异常报告前置条件冲突，则不要加 `noexcept` |

### C++ 默认 noexcept 的情况

- 析构函数和 `operator delete` 默认隐式 `noexcept`
- 只有当其成员的析构函数为 `noexcept(false)` 才不为 `noexcept`

### 实用建议

- 给移动构造 / 移动赋值 / `swap` 明确加上 `noexcept`
- 如果写的函数真的不会抛异常，一定要加上 `noexcept`
- 但不要为了加 `noexcept` 而故意扭曲实现或隐藏错误（如用状态码替代异常）