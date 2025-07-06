## 条款18：使用 std::unique_ptr 管理独占资源

###  智能指针为何重要？

原始指针的缺点：

1. **无法区分单个对象还是数组**（影响 delete 方式）
2. **不清楚是否应销毁资源**（是否拥有所有权）
3. **不知道如何销毁资源**（`delete`、`delete[]` 或其他机制）
4. **容易出现资源泄露或重复释放**
5. **难以处理异常或分支路径中的释放**
6. **容易产生悬空指针**

> 原始指针容易“背刺”程序员，智能指针可防止这些灾难性问题。

### `std::unique_ptr` 的特点

核心语义：**独占所有权（exclusive ownership）**

- 不能拷贝，只能移动
- 析构时自动调用 `delete` 销毁所拥有对象
- 通常与裸指针大小相同，性能开销极小
- 适合资源敏感、控制粒度高的场景
- 支持自定义删除器（如记录日志）

```cpp
std::unique_ptr<Foo> ptr(new Foo);
```

### 工厂函数示例：适合返回 `unique_ptr`

```cpp
template<typename... Ts>
std::unique_ptr<Investment> makeInvestment(Ts&&... params);
```

- 调用者负责销毁资源，恰好匹配 `unique_ptr` 语义

- 可安全转移所有权：如存入容器或成员变量

- 自动处理异常导致的提前 return 或 break

### 自定义删除器支持

```cpp
auto delInvmt = [](Investment* p) {
    makeLogEntry(p);
    delete p;
};

std::unique_ptr<Investment, decltype(delInvmt)> pInv(nullptr, delInvmt);
```

- 删除器类型必须成为 `unique_ptr` 的第二个模板参数

- 可使用 lambda，更紧凑、高效

- 注意基类需要**虚析构函数**：

```cpp
class Investment {
public:
    virtual ~Investment();
};
```

### 大小对比

| 删除器形式           | 对象大小             |
| -------------------- | -------------------- |
| 默认删除器（delete） | 与裸指针相同         |
| 函数指针删除器       | 增加一个指针大小     |
| 无状态 lambda 删除器 | 与裸指针相同（推荐） |
| 有状态 lambda 删除器 | 视捕获内容大小而定   |

> **推荐使用不捕获状态的 lambda** 作为删除器以避免空间膨胀。

### 适用场景总结

| 场景                     | 是否适合用 `unique_ptr` |
| ------------------------ | ----------------------- |
| 独占所有权资源管理       | ✅                       |
| 工厂函数返回对象         | ✅                       |
| 异常安全的自动销毁       | ✅                       |
| 拥有对象生命周期的类成员 | ✅                       |
| 需要共享所有权           | ❌（请用 `shared_ptr`）  |
| 拷贝语义                 | ❌                       |

### 与 `shared_ptr` 的转换

`unique_ptr` 可以**轻松转为** `shared_ptr`。

假设：

```cpp
std::unique_ptr<Investment> makeInvestment(args);
```

那么：

```cpp
std::shared_ptr<Investment> sp = makeInvestment(args);
```

相当于：

```cpp
std::unique_ptr<Investment> up = makeInvestment(args);
std::shared_ptr<Investment> sp = std::move(up); // 显式转移
```

- `std::shared_ptr` 提供了一个接受 `std::unique_ptr` 的构造函数，用于**获取其资源的所有权**：

  ```cpp
  template<class T>
  shared_ptr(unique_ptr<T>&&) noexcept;
  ```

  此时 `std::shared_ptr` 会接管 `unique_ptr` 中的对象资源，同时 `unique_ptr` 被置空。

- 工厂函数只需返回 `unique_ptr`，由调用者决定是否转换。

- 如果 `makeInvestment` 返回的 `unique_ptr` 使用了 **自定义删除器**，要确保它对 `shared_ptr` 也是适用的（否则可能触发删除错误）。

### 关于数组形式

```cpp
std::unique_ptr<T[]> arr(new T[n]);
```

- 拥有 `operator[]`，但不推荐常用

- 更推荐使用 `std::vector` 或 `std::array`