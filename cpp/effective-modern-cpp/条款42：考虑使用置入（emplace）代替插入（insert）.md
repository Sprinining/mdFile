## 条款42：考虑使用置入（emplace）代替插入（insert）

### 背景

假设有一个 `std::vector<std::string>`，我们想往里面添加字符串。

```cpp
std::vector<std::string> vs;        // std::string的容器
vs.push_back("xyzzy");              // 添加字符串字面量
```

这里，容器元素是 `std::string`，但传入的是字符串字面量 `"xyzzy"`，不是 `std::string` 类型。

`push_back` 有两个重载：

```cpp
void push_back(const T& x);     // 插入左值
void push_back(T&& x);          // 插入右值
```

调用：

```cpp
vs.push_back("xyzzy");
```

会被编译器转换为：

```cpp
vs.push_back(std::string("xyzzy"));
```

编译器先创建了一个临时的 `std::string`（我们称之为 temp），再将这个临时对象移动到 `vector` 内部。

### 这个过程的效率问题

- 先调用一次 `std::string` 构造函数，创建临时对象 temp
- 再调用一次移动构造函数，将 temp 迁移到容器内部
- 最后销毁临时对象 temp

这个过程调用了两次构造函数和一次析构函数，存在不必要的开销。

### 解决方案：使用 `emplace_back`

`emplace_back` 允许我们直接传递构造 `std::string` 所需的参数，在容器内部直接构造对象，避免临时对象产生：

```cpp
vs.emplace_back("xyzzy");       // 直接用字符串字面量构造容器内的std::string
```

`emplace_back` 使用完美转发，允许传入任何参数组合：

```cpp
vs.emplace_back(50, 'x');       // 插入由50个'x'组成的std::string
```

### 置入函数与插入函数的对比

- 插入函数（如 `push_back`）接受 **元素对象**（如 `std::string`）
- 置入函数（如 `emplace_back`）接受 **元素构造参数**

这使得置入函数可以避免临时对象的创建和销毁。

```cpp
std::vector<std::string> vec;

// insert 示例：必须先构造 std::string 对象
std::string name = "Alice";
vec.push_back(name);               // 拷贝
vec.push_back(std::string("Bob")); // 移动

// emplace 示例：直接传构造参数
vec.emplace_back("Charlie");       // 直接在容器内构造 std::string
vec.emplace_back(5, 'x');          // 构造 "xxxxx"
```

| 特性                   | `insert` / `push_back` 等插入函数       | `emplace` / `emplace_back` 等置入函数 |
| ---------------------- | --------------------------------------- | ------------------------------------- |
| **参数类型**           | 只能是容器元素类型的对象                | 是容器元素类型构造函数所需的**参数**  |
| **调用行为**           | 接受一个已构造好的对象，再进行复制/移动 | 直接在容器内部构造对象，避免中间对象  |
| **临时对象开销**       | 可能创建临时对象                        | 避免临时对象（性能更优）              |
| **构造函数调用时机**   | 插入函数外部调用构造函数                | 容器内部调用构造函数（延迟构造）      |
| **支持 explicit 构造** | 不支持（因为是拷贝初始化）              | 支持（因为是直接初始化）              |

### 示例：两种等效写法

```cpp
std::string queenOfDisco("Donna Summer");
vs.push_back(queenOfDisco);      // 拷贝构造queenOfDisco
vs.emplace_back(queenOfDisco);   // 功能相同，效果一致
```

### 置入函数并非总是更快

在有些场景，插入函数比置入函数更快，具体表现依赖于：

- 传递参数类型
- 容器类型
- 插入位置
- 元素构造函数异常安全性
- 容器是否允许重复元素

建议用基准测试来决定。

### 启发式判断是否用置入函数

#### **值通过构造函数添加（而非赋值）**
- 例如，向 `vector` 末尾添加新元素：

```cpp
vs.emplace_back("xyzzy");   // 在容器末尾构造
```

- 如果插入位置已有对象（如 `vs.emplace(vs.begin(), "xyzzy")`），可能会发生移动赋值，置入优势降低。

#### **传递的参数类型与容器元素类型不同**
- 例如传递字符串字面量给 `std::vector<std::string>`。

#### **容器允许重复元素或添加元素通常不重复**
- 因为置入实现可能需要构造节点进行比较，若值已存在会被销毁，导致额外开销。

### 特殊情况一：资源管理类对象（如 `std::shared_ptr`）

假设有：

```cpp
std::list<std::shared_ptr<Widget>> ptrs;
```

插入代码：

```cpp
ptrs.push_back(std::shared_ptr<Widget>(new Widget, killWidget));
ptrs.push_back({new Widget, killWidget});
```

这都会创建一个临时的 `shared_ptr` 对象，传给 `push_back`。

使用 `emplace_back`：

```cpp
ptrs.emplace_back(new Widget, killWidget);
```

这里会直接转发参数构造 `shared_ptr`，但存在异常安全风险：

- 若分配内存失败，`new Widget` 返回的指针无法被管理，导致资源泄漏。

推荐写法是先创建资源管理对象：

```cpp
std::shared_ptr<Widget> spw(new Widget, killWidget);
ptrs.push_back(std::move(spw));       // 或者
ptrs.emplace_back(std::move(spw));
```

这样保证资源安全。

### 特殊情况二：explicit 构造函数与隐式转换

以 `std::regex` 为例：

```cpp
std::vector<std::regex> regexes;
```

下面的调用：

```cpp
regexes.emplace_back(nullptr);    // 可编译
regexes.push_back(nullptr);       // 编译错误
```

原因：

- `std::regex` 有接受 `const char*` 的 explicit 构造函数，
- `push_back` 使用拷贝初始化，禁止使用 explicit 构造函数
- `emplace_back` 使用直接初始化，允许使用 explicit 构造函数
- 所以 `emplace_back(nullptr)` 实际调用 `std::regex(nullptr)`，可能导致运行时错误。

### 总结

- 置入函数有时比插入函数更高效且绝不更慢
- 置入函数适用于：通过构造函数添加元素，参数类型不同，允许重复元素的容器
- 资源管理类对象插入需特别注意异常安全
- 置入函数会调用 explicit 构造函数，需注意隐式转换带来的副作用

