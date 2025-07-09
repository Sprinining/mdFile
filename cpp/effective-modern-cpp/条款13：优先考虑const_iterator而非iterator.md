## 条款13：优先考虑 const_iterator 而非 iterator

- **只要不需要修改元素，就应优先使用 `const_iterator`。**
  - `const_iterator` **只保证不能通过它修改元素本身**
  - **不限制操作容器结构**（如插入、删除）
- 理由同“能加 `const` 就加”的通用准则：可读性更高、语义更明确、避免误用。

### C++98 与 C++11 的差异

#### C++98 的限制

- **`const_iterator` 不易获得**：只能通过 `const` 容器调用 `begin()`、`end()`。

- **无法直接使用 `const_iterator` 进行插入/删除**：

  ```cpp
  std::vector<int>::const_iterator ci = ...;
  values.insert(ci, 123);  // ❌ C++98 不允许
  ```

- **`const_iterator` 无法转换为 `iterator`**（即便用 `static_cast` / `reinterpret_cast`）。

所以：C++98 中，即便想用 `const_iterator`，实践上很麻烦。

#### C++11 的改进

- 提供 `.cbegin()` / `.cend()` 成员函数：即使容器是 non-const，也能获取 `const_iterator`。

- STL 支持 `insert()` / `erase()` 接收 `const_iterator`。

- `auto` 推导更便捷：

  ```cpp
  auto it = std::find(values.cbegin(), values.cend(), 1983);
  values.insert(it, 1998);  // 合法
  ```

### 高通用性的做法（泛型代码）

为了兼容 **原生数组** 和 **仅支持非成员函数的容器（如第三方库）**，优先使用：

```cpp
using std::cbegin;
using std::cend;
auto it = std::find(cbegin(container), cend(container), val);
```

这让模板代码能处理 STL 容器、原生数组、第三方容器等各种类型。

### C++11 的不足（后在 C++14 修复）

C++11 **未提供非成员函数版本的 `cbegin` / `cend` / `crbegin` / `crend`**，只能手动实现：

自己实现 `cbegin`（兼容 C++11）：

```cpp
template <class C>
auto cbegin(const C& container) -> decltype(std::begin(container)) {
    return std::begin(container);  // 对 const 容器返回 const_iterator
}
```

注意：并非调用 `.cbegin()`，而是借助 `const C&` + `std::begin()` 达到效果。

### 推荐实践

#### 一般代码中

- **用 `cbegin()` / `cend()` 代替 `begin()` / `end()`**，只要不打算修改元素。
- 使用 `auto` 推导，配合 `const_iterator` 更方便。

#### 泛型模板代码中

- 用非成员版本的 `cbegin()` / `cend()`（`using std::cbegin;`）。
- 如使用 C++11，手动提供缺失的非成员版本。

### 总结

| C++版本 | const_iterator 实用性 | 获取方式              | 能否用于 insert/erase |
| ------- | --------------------- | --------------------- | --------------------- |
| C++98   | 低                    | 不便（需转换/绕路）   | 否（需转为 iterator） |
| C++11   | 高                    | `cbegin()`/`cend()`   | 支持                  |
| C++14   | 完善                  | 增加非成员 `cbegin()` | 支持                  |