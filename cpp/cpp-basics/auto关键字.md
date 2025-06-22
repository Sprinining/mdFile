## auto关键字

`auto` 是 C++ 中一个非常有用的关键字，用于**自动类型推断（type inference）**。从 C++11 开始引入，在 C++14 和 C++17 中功能不断增强。

### 一、`auto` 是什么？

`auto` 让编译器根据变量的**初始值**自动推导其类型，避免显式地写出复杂冗长的类型名。

示例

```cpp
auto x = 10;       // int
auto y = 3.14;     // double
auto z = "hello";  // const char*
```

### 二、典型用法

#### 1. 简化类型推导（特别是模板和复杂类型）

```cpp
std::map<std::string, std::vector<int>> mp;
// 不用写 std::map<std::string, std::vector<int>>::iterator
for (auto it = mp.begin(); it != mp.end(); ++it) {
    std::cout << it->first << "\n";
}
```

#### 2. 简化迭代器声明

```cpp
std::vector<int> vec = {1, 2, 3, 4};
for (auto it = vec.begin(); it != vec.end(); ++it) {
    std::cout << *it << " ";
}
```

#### 3. 用于函数返回值

```cpp
auto getValue() {
    return 42; // 推导为 int
}
```

注意：这种形式必须有 return 语句，编译器才能推导出类型。

### 三、细节与注意事项

#### 1. `auto` 推导会**忽略 const/reference/volatile**，除非显式指定

```cpp
int a = 5;
const int& b = a;
auto x = b;     // x 是 int，不是 const int&
auto& y = b;    // y 是 const int&，因为用了 &
```

> 记住：是否保留引用/const，取决于是否显式使用 `&` 或 `const auto&`

#### 2. 和指针、引用搭配使用

```cpp
int a = 10;
auto* p = &a;    // int*
auto& r = a;     // int&
```

#### 3. `auto` 不支持函数参数类型声明（C++20 前）

```cpp
void func(auto x); // 错误！C++20 才允许
```

但可在 lambda 中使用 `auto`：

```cpp
auto lambda = [](auto x, auto y) { return x + y; }; // C++14 OK
```

### 四、C++14: `auto` 返回类型简写

C++11：支持 `auto` 推导返回值类型（仅限**尾返回类型**语法）

```cpp
auto func() -> int {
    return 42;
}
```

在 C++11 中，lambda 必须显式指定参数类型，例如：

```cpp
auto lambda = [](int x, int y) { return x + y; }; // C++11 OK
```

C++14：支持**从 return 自动推导**返回类型（更常见的写法）

```cpp
auto add(int a, int b) {
    return a + b; // 编译器推导为 int
}
```

也支持：

```cpp
auto lambda = [](auto x, auto y) { return x + y; };
```

### 五、C++17: 结构化绑定 + `auto`

```cpp
std::pair<int, std::string> p = {1, "hello"};
auto [id, name] = p;  // id 是 int，name 是 std::string
```

编译器会做的事情：

- 自动识别 `p` 是一个 `std::pair<int, std::string>`。
- 自动推导 `id` 是 `int`，`name` 是 `std::string`。
- 自动绑定 `id = p.first`，`name = p.second`。

等价于写了：

```cpp
int id = p.first;
std::string name = p.second;
```

但写法更清晰、紧凑。

### 六、`auto` 的陷阱

#### 1. 推导精度不匹配

```cpp
auto x = 3.0f;  // x 是 float
auto y = 3.0;   // y 是 double

auto z = x + y; // 发生了 float + double
```

`auto` 推导的结果**依赖右值的字面量类型**，像 `3.0f` 推导成 `float`，`3.0` 推导成 `double`，这在混用时会导致**精度不匹配**，容易产生意料之外的类型转换，应加以留意或显式指定类型。

#### 2. 容易忽略拷贝 vs 引用

```cpp
std::vector<int> v = {1, 2, 3};
for (auto x : v) { x = 0; }       // 改变的是副本
for (auto& x : v) { x = 0; }      // 改变原始容器
```

当用 `auto` 声明变量时，**可能会无意中复制对象（拷贝）**，而不是本意想要的**引用（引用/别名）**，从而导致性能下降、逻辑错误或修改无效等问题。

### 七、和 `decltype` 的关系

`auto` 是“编译器根据值推导类型”，`decltype` 是“编译器根据表达式**本身**判断类型”。

| 特性       | 含义                                                         |
| ---------- | ------------------------------------------------------------ |
| `auto`     | 编译器根据 **右值的结果（赋值的值）** 来推导变量类型（通常是去掉引用、cv 修饰的“值”） |
| `decltype` | 编译器根据 **表达式本身的类型** 推导（包括是否是引用、常量等） |

#### 1. 例子对比

```cpp
int i = 0;
int& ri = i;

auto a = ri;      // a 是 int（引用被忽略）
decltype(ri) b = i; // b 是 int&（引用保留）
```

再复杂一点：

```cpp
int x = 10;
decltype((x)) a = x;  // 注意：a 是 int&（因为 (x) 是一个 lvalue 表达式）
decltype(x)  b = x;   // b 是 int（变量名是 lvalue，但 decltype 不加括号只看类型声明）
```

> `decltype((x))` 会返回引用类型，而 `decltype(x)` 返回值类型。这是 `decltype` 的一个关键点。

#### 2. 使用场景


| 你想做什么                       | 用哪个？                    | 说明                             |
| -------------------------------- | --------------------------- | -------------------------------- |
| 自动声明变量（不关心引用/const） | `auto`                      | 简洁、方便                       |
| 精确获取表达式类型（保留引用等） | `decltype`                  | 精度高、适合模板、泛型编程等场景 |
| 用于泛型函数返回值（C++11 起）   | `decltype`                  | `decltype(f(x))` 推导返回值类型  |
| 与 `auto` 搭配做尾返回类型       | `auto f() -> decltype(...)` | 用于需要明确函数返回类型的场景   |

### 八、推荐使用场景

- 不想写复杂类型（特别是模板、STL 迭代器等）
- 泛型编程中需要类型灵活性
- 和 `for-range`、Lambda、结构化绑定配合使用

### 九、总结

| 用法                      | 功能                 |
| ------------------------- | -------------------- |
| `auto x = expr;`          | 自动推导类型         |
| `auto& x = expr;`         | 保留引用             |
| `const auto& x = expr;`   | 保留常引用           |
| `auto* x = &expr;`        | 自动推导指针         |
| `auto func() -> 返回类型` | C++11 函数返回值占位 |
| `auto [a, b] = pair;`     | C++17 结构化绑定     |