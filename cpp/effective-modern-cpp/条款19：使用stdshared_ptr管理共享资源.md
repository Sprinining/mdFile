## 条款19：使用 std::shared_ptr 管理共享资源

- `std::shared_ptr` 提供**共享所有权**的资源管理方式，其背后使用**引用计数**。
- 在不引入垃圾回收机制的同时，实现了 **自动销毁** 和 **析构时机可预期** 的资源管理。
- 是 C++ 中模拟“垃圾回收”的一种方式，但销毁是**确定性**的。

### 内部机制与实现细节

#### 引用计数（Reference Counting）

- 每个 `std::shared_ptr` 增加引用计数，销毁或重新指向时减少。
- 引用计数归零时，自动销毁资源。

#### 控制块（Control Block）

- 控制块存储：
  - 引用计数值（strong/weak）
  - 删除器（可能是 lambda）
  - 分配器（可选）
- 控制块是动态分配的，并不在 `shared_ptr` 对象内部。
- 大小通常为几个 word，使用虚函数机制确保正确销毁。

### 性能开销

- **大小**：`std::shared_ptr` = 两个指针大小（资源指针 + 控制块指针）
- **操作成本**：
  - 拷贝时原子地修改引用计数（线程安全）
  - 移动操作比拷贝便宜（不改变引用计数）
- **分配成本**：控制块动态分配；若使用 `std::make_shared` 可优化。

### 删除器与灵活性

- 可自定义删除器（函数指针、lambda）。
- 自定义删除器 **不影响** `shared_ptr` 的类型（比 `unique_ptr` 更灵活）。
- 删除器数据存在控制块中，不增加 `shared_ptr` 本体大小。

### 常见陷阱

#### 多个 `shared_ptr` 管理同一原始指针

```cpp
Widget* pw = new Widget;
std::shared_ptr<Widget> sp1(pw);
std::shared_ptr<Widget> sp2(pw); // ⚠️ 错误！控制块重复 -> 重复析构
```

正确用法：

- 直接用 `new` 创建对象交给 `shared_ptr`
- 或使用 `std::make_shared`

#### 用 `this` 构造 `shared_ptr`

- 会创建新的控制块（危险）
- 解决办法：继承 `std::enable_shared_from_this<T>`

```cpp
class Widget : public std::enable_shared_from_this<Widget> {
    void process() {
        auto sp = shared_from_this(); // 安全共享当前对象
    }
};
```

- 必须保证外部已有 `shared_ptr` 管理该对象才能调用 `shared_from_this()`，否则 **未定义行为**。

  - 当调用 `shared_from_this()`，它的内部逻辑会去找**控制块**。

  - 但是只有在对象**已经被 shared_ptr 管理（即它是通过 shared_ptr 创建的）**时，才会有控制块存在。

  - 否则，`shared_from_this()` 找不到控制块，就会导致 **未定义行为**（通常会抛出异常，也可能崩溃）。

  - 错误用法

    ```cpp
    class Widget : public std::enable_shared_from_this<Widget> {
    public:
        void showMyself() {
            auto sp = shared_from_this();  // ❌错误！此时没有控制块！
        }
    };
    
    int main() {
        Widget* raw = new Widget; // ❌ 仅用原始指针创建对象
        raw->showMyself();        // ❌ 调用 shared_from_this() 是未定义行为！
    }
    ```

  - 正确用法
  
    ```cpp
    int main() {
        std::shared_ptr<Widget> sp = std::make_shared<Widget>(); // ✅ shared_ptr 创建对象
        sp->showMyself();  // ✅ 现在调用 shared_from_this() 就是安全的
    }
    ```
  
  - 通常做法：把构造函数设为 private，强制别人用 `shared_ptr` 创建
  
    ```cpp
    class Widget : public std::enable_shared_from_this<Widget> {
    public:
        static std::shared_ptr<Widget> create() {
            return std::shared_ptr<Widget>(new Widget()); // ✅ 确保一开始就用 shared_ptr 创建
        }
    
        void showMyself() {
            auto sp = shared_from_this(); // ✅ 安全
        }
    
    private:
        Widget() = default;
    };
    ```

### 实用建议与最佳实践

推荐用法：

- 使用 `std::make_shared<T>(...)` 创建 `shared_ptr`，避免单独分配控制块和对象。
- 如果需要自定义删除器，使用构造函数传入：

```cpp
auto del = [](T* p) { delete p; };
std::shared_ptr<T> sp(new T, del);
```

避免：

- 从裸指针变量创建 `shared_ptr`
- 使用 `shared_ptr` 管理 C 风格数组（应使用 `std::vector`、`std::array` 等）

### 总结

- `std::shared_ptr` 用于 **共享所有权资源** 的自动生命周期管理。
- 相较于 `std::unique_ptr`，它引入了控制块和原子操作，**性能稍逊但功能更强**。
- 避免从 **裸指针** 和 `this` 创建 `shared_ptr`，否则容易造成 **双重析构和未定义行为**。
- `std::make_shared` 是首选方式，既安全又高效。
- 如果能使用 `unique_ptr`，尽量不要用 `shared_ptr`（性能更好、逻辑更清晰）。