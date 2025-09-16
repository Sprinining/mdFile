## 条款10：优先考虑限域 enum 而非未限域 enum

### 作用域区别

#### 未限域枚举（unscoped enum，C++98风格）

枚举值（enumerator）直接泄漏到枚举所在的作用域中，可能导致命名冲突。

```cpp
enum Color { black, white, red };  // black, white, red 在 Color 所在作用域
auto white = false;                // 错误，white 重复定义
```

#### 限域枚举（scoped enum，C++11引入）

枚举值仅在枚举类型内有效，必须通过 `枚举名::枚举值` 访问，不污染外部命名空间。

```cpp
enum class Color { black, white, red };
auto white = false;                // 合法，命名无冲突
Color c = white;                  // 错误，必须 Color::white
Color c = Color::white;           // 正确
```

### 类型安全

#### 未限域 enum

枚举值隐式转换为整数类型，可与整型或浮点数比较，容易引发类型错误或语义混乱。

```cpp
enum Color { black, white, red };
if (c < 14.5) { ... }  // 合法但语义怪异
```

#### 限域 enum

枚举值不会隐式转换为其他类型，防止错误使用，增强类型安全。

```cpp
enum class Color { black, white, red };
if (c < 14.5) { ... }  // 编译错误
```

需要转换时必须显式转换：

```cpp
static_cast<double>(c);
```

### 前置声明支持

#### 未限域 enum

不能直接前置声明，或者必须明确指定底层类型。

```cpp
enum Color;                 // 错误
enum Color : uint8_t;       // 合法，需指定底层类型
```

#### 限域 enum

可以直接前置声明，且默认底层类型为 `int`，也可以指定底层类型。

```cpp
enum class Status;                         // 合法，默认int底层类型
enum class Status : std::uint32_t;         // 指定底层类型
```

前置声明减少编译依赖，提高编译效率。

### 底层类型

- 两者都支持指定底层类型，利于内存和性能优化。

- 默认：

  - 未限域 enum 不一定是 `int`，取决于编译器和枚举值范围。

  - 限域 enum 默认是 `int`。

### 兼容性与实用场景

- **未限域 enum** 在某些情况下有优势，比如与模板参数要求整数类型（如 `std::tuple` 索引）结合使用时，枚举值可隐式转为整数。
- 对于一般用途，**建议使用限域 enum**，以避免命名污染和类型安全问题。

### 使用未限域 enum 索引 std::tuple

```cpp
// 定义一个非限域枚举，枚举成员名直接在作用域内可用
enum UserInfoFields { uiName, uiEmail, uiReputation };

// 使用 std::tuple 来组合用户信息，分别是名字、邮箱和声望值
using UserInfo = std::tuple<std::string, std::string, std::size_t>;

// 创建一个 UserInfo 类型的对象
UserInfo uInfo;

// 使用非限域枚举值作为索引访问 tuple 的对应元素
// 这里 uiEmail 隐式转换成整数 1，表示取 tuple 中的第二个元素（索引从0开始）
auto val = std::get<uiEmail>(uInfo);
```

对应的限域 enum 用法较繁琐：

```cpp
// 定义一个限域枚举（enum class），枚举成员名被限定在 UserInfoFields 作用域内
enum class UserInfoFields { uiName, uiEmail, uiReputation };

// 使用 std::get 访问 tuple 元素时，必须显式将枚举值转换成整数索引
// 这里使用 static_cast 将枚举成员转换为 std::size_t 类型
auto val = std::get<static_cast<std::size_t>(UserInfoFields::uiEmail)>(uInfo);
```

可用辅助函数简化转换：

```cpp
// 模板函数：将任意枚举类型的枚举值转换为其底层整型值
template<typename E>
constexpr typename std::underlying_type<E>::type
toUType(E enumerator) noexcept {
    // std::underlying_type<E>::type 获取枚举 E 的底层整型类型
    // static_cast 将枚举值转换为底层整型值
    return static_cast<typename std::underlying_type<E>::type>(enumerator);
}

// 使用示例：利用toUType函数将限域枚举UserInfoFields的枚举值转为索引，访问tuple元素
auto val = std::get<toUType(UserInfoFields::uiEmail)>(uInfo);
```

### 结论和建议

- C++98的 enum 即未限域 enum，易引发命名冲突和类型隐式转换问题。
- C++11的限域 enum（`enum class`）限定枚举名作用域，避免命名污染，禁止隐式类型转换，更安全。
- 限域 enum 支持前置声明，减少编译依赖。
- 在少数需要枚举值隐式转换为整数的场景，可使用未限域 enum，但通常建议用限域 enum 配合显式转换。
- 建议**默认使用限域 enum**。