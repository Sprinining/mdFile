## C++ invoke

`std::invoke` 是 C++17 引入的一个工具函数，用来以统一的方式调用任意可调用对象（函数、函数指针、成员函数指针、函数对象、lambda 表达式等），它会自动处理调用方式的差异，提供一种「泛用式」调用接口。

### 使用背景

在模板编程中，我们可能会面对不同类型的可调用对象。比如：

- 普通函数
- 函数对象（重载 `operator()` 的类）
- Lambda 表达式
- 类的成员函数指针
- 类的成员变量指针（读取成员）

如果想对它们一视同仁地调用，直接写模板代码会比较繁琐，`std::invoke` 正是为了解决这一点。

### 基本语法

```cpp
std::invoke(callable, args...);
```

这只是一个简化形式，**真正的标准函数原型**（来自 `<functional>` 头文件中）是这样定义的（以 C++17 为基准）：

```cpp
namespace std {
    template<class F, class... Args>
    constexpr invoke_result_t<F, Args...> invoke(F&& f, Args&&... args)
        noexcept(is_nothrow_invocable_v<F, Args...>);
}
```

#### template<class F, class... Args>

- `F` 表示 **可调用对象的类型**，可以是：

  - 普通函数或函数指针

  - 函数对象（重载 `operator()` 的类）

  - 成员函数指针 `T (Class::*)(...)`

  - 成员变量指针 `T Class::*`

  - lambda 表达式

- `Args...` 是 **参数包**，表示传给 `f` 的调用参数（包括类对象本身）

#### constexpr invoke_result_t<F, Args...>

- `invoke_result_t<F, Args...>` 是一个 **类型萃取工具**，用于推导 `invoke(f, args...)` 的**返回类型**

- 等价于：

```cpp
typename std::invoke_result<F, Args...>::type
```

- 比如：

```cpp
std::invoke_result_t<decltype(&MyClass::foo), MyClass, int> // 推导出返回类型为 int
```

- `constexpr` 表示如果 `f(args...)` 是编译期可计算的，那 `std::invoke` 也可以在编译期调用（C++20 开始是 `constexpr` 的）

#### noexcept(is_nothrow_invocable_v<F, Args...>)

- 判断 `f(args...)` 的调用是否是 **不抛异常的**

- `is_nothrow_invocable_v<F, Args...>` 是一个编译期常量表达式，如果 `true`，就表示调用 `f(args...)` 不会抛出异常

- 用于编译器优化和 noexcept 函数检查

#### invoke(F&& f, Args&&... args)

##### `F&& f`

- 这是一个**万能引用（Forwarding Reference）**，也叫**完美转发引用**。
- 它能接受：
  - **左值引用**（比如函数对象 `obj`）
  - **右值引用**（比如临时的 lambda、临时函数对象）

> 注意：在模板中 `F&&` 不是“右值引用”，而是“万能引用”——它可以根据实参的类型保持引用类型。

```cpp
auto foo = [](){ std::cout << "hi\n"; };
std::invoke(foo);          // 传的是左值
std::invoke([](){...});    // 传的是右值（临时 lambda）
```

#####  `Args&&... args`

- 参数包 `Args...` 表示“任意多个参数的类型”

- `Args&&...` 同样是**万能引用包**，能保持传入参数的引用性质

它能处理：

| 传入参数类型 | 保持原样        |
| ------------ | --------------- |
| 左值         | 作为左值转发    |
| 右值         | 作为右值转发    |
| 引用         | 保持引用类型    |
| const 引用   | 保持 const 限定 |

##### 与 `std::forward` 配合使用

完整实现中，会看到类似：

```cpp
return std::forward<F>(f)(std::forward<Args>(args)...);
```

这叫**完美转发**技术，它的作用是：

- 保持所有传入参数的值类别（左值 / 右值）
- 防止拷贝或移动的性能开销

### 支持的调用类型

| 类型         | 示例                                        |
| ------------ | ------------------------------------------- |
| 普通函数     | `std::invoke(f, args...)`                   |
| Lambda       | `std::invoke([](int x){ return x+1; }, 2)`  |
| 函数对象     | `std::invoke(std::plus<>(), 1, 2)`          |
| 成员函数指针 | `std::invoke(&Class::method, obj, args...)` |
| 成员变量指针 | `std::invoke(&Class::member, obj)`          |

### 示例详解

#### 1. 普通函数

```cpp
int add(int a, int b) { return a + b; }

int main() {
    int result = std::invoke(add, 2, 3);  // result = 5
}
```

#### 2. Lambda 表达式

```cpp
auto lam = [](int x, int y) { return x * y; };

int main() {
    int result = std::invoke(lam, 4, 5);  // result = 20
}
```

#### 3. 成员函数指针

```cpp
struct MyClass {
    int multiply(int x) { return x * 2; }
};

int main() {
    MyClass obj;
    int result = std::invoke(&MyClass::multiply, obj, 3);  // result = 6
}
```

⚠️ 注意：可以传 `obj`（值/引用），也可以传 `&obj`，都可以。

#### 4. 成员变量指针

```cpp
struct MyStruct {
    int value = 42;
};

int main() {
    MyStruct s;
    int val = std::invoke(&MyStruct::value, s);  // val = 42
}
```

### 与 `std::bind`、`std::function` 区别

| 工具            | 功能                             | 是否调用          |
| --------------- | -------------------------------- | ----------------- |
| `std::invoke`   | **立即调用** 任意可调用对象      | ✅                 |
| `std::bind`     | 绑定函数并返回一个新的可调用对象 | ❌（延迟调用）     |
| `std::function` | 保存可调用对象，做泛型函数封装   | ❌（需要手动调用） |

### 实现原理简化（伪代码）

标准库中 `std::invoke` 的实际实现使用了大量的 `std::enable_if`、SFINAE 以及重载匹配逻辑，下面是一个简化版逻辑：

```cpp
template<typename F, typename... Args>
decltype(auto) my_invoke(F&& f, Args&&... args) {
    return std::forward<F>(f)(std::forward<Args>(args)...);
}
```

### 注意事项

1. 如果是成员函数指针，必须传类对象或指针作为第一个参数。

2. 如果是成员变量指针，也是一样。

3. C++20 中 `std::invoke` 成为 `constexpr`，可以在编译期使用。

4. `std::invoke_result` 可用于获取调用后返回值类型：

   ```cpp
   std::invoke_result_t<decltype(&MyClass::multiply), MyClass, int> // int
   ```

### 适用场景

- 实现通用调度器、函数包装器（如 `std::apply`, `std::visit`）

- 模板元编程中统一处理所有可调用对象

- 写通用回调/事件系统等