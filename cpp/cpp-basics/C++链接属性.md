## C++ 链接属性

C++ 中的**链接属性（Linkage）**是指名字（如变量名、函数名）在多个翻译单元中的可见性与共享性，是理解**头文件引用规则**、**多文件编译**、**extern/static关键字作用**的基础。

### 链接属性分类

C++中，**名字**有三种链接属性：

| 链接属性                     | 含义说明                                                 | 示例                               |
| ---------------------------- | -------------------------------------------------------- | ---------------------------------- |
| 无链接（no linkage）         | 名字只在定义它的作用域内可见，不能被其他文件访问         | 局部变量、类的成员函数参数等       |
| 内部链接（internal linkage） | 名字只在当前翻译单元（即当前 `.cpp` 文件）可见           | 使用 `static` 修饰的全局变量/函数  |
| 外部链接（external linkage） | 名字可跨多个翻译单元访问（即可以被其他 `.cpp` 文件使用） | 普通全局变量、非静态函数、`extern` |

示例：

```cpp
// 1. 局部变量：无链接
void func() {
    int x = 10; // x 为局部变量，无链接
}

// 2. 全局变量：默认外部链接
int g = 100;   // g 是全局变量，具有 external linkage，可被其他 cpp 文件引用

// 3. 使用 static 修饰：内部链接
static int s = 42;  // s 是静态全局变量，仅当前 cpp 文件可见，具有 internal linkage
```

### extern 与链接属性

在声明变量时使用 `extern`：声明外部变量

```cpp
// a.cpp
int g = 123; // 定义，具有 external linkage

// b.cpp
extern int g; // extern 并不会“增加”外部链接，而只是“声明”某个已经具有外部链接的变量存在于别的翻译单元。
```

注意：`extern` 本身不创建变量，只是告诉编译器「这个变量在别的地方定义了」。

### const 与链接属性

默认情况下：

- `const` 全局变量：**内部链接（internal linkage）**
- `constexpr` 全局变量：**内部链接（internal linkage）**

```cpp
const int a = 10;         // 内部链接，其他 cpp 文件无法访问
constexpr int b = 20;     // 同样是内部链接

extern const int a;       // 通过 extern 改为 external linkage
```

因此，如果想在多个文件共享 `const` 常量，需加 `extern` 并在某个文件中定义一次：

```cpp
// common.h
extern const int MAX_SIZE;

// common.cpp
const int MAX_SIZE = 100;
```

### 函数的链接属性

- **非成员函数默认是 external linkage**
- 使用 `static` 修饰的函数为 **internal linkage**

```cpp
void foo() {}             // external linkage
static void bar() {}      // internal linkage，只能当前文件使用
```

### 类成员的链接属性

1. 类的成员函数（定义在类中）：无链接

```cpp
class A {
    void func() {} // func 是 inline 成员函数，无链接
};
```

2. 类的静态成员变量：需要在类外定义，默认 external linkage

```cpp
class B {
public:
    static int count;  // 声明
};

// B.cpp
int B::count = 0;      // 定义，external linkage
```

static 在类里代表“类级别”变量，必须类外定义，且默认外部链接；在全局作用域代表“只对本文件可见”，限制外部访问。

### 总结

| 情况/修饰语        | 链接属性         | 可否跨文件使用  | 示例                    |
| ------------------ | ---------------- | --------------- | ----------------------- |
| 局部变量           | 无链接           | 否              | 函数内定义变量          |
| const 全局变量     | 内部链接         | 否（需 extern） | `const int x = 10;`     |
| constexpr 全局变量 | 内部链接         | 否              | `constexpr int y = 20;` |
| 全局变量           | 外部链接         | 是              | `int g = 10;`           |
| static 全局变量    | 内部链接         | 否              | `static int s = 10;`    |
| extern 声明        | 外部链接         | 是              | `extern int g;`         |
| 函数               | 外部链接（默认） | 是              | `void foo();`           |
| static 函数        | 内部链接         | 否              | `static void foo();`    |

| 情形/修饰符                                               | 链接属性                               | 是否改变默认链接             | 备注                                                         |
| --------------------------------------------------------- | -------------------------------------- | ---------------------------- | ------------------------------------------------------------ |
| **默认（无修饰）**                                        | 变量：**外部链接**；函数：**外部链接** | —                            | 跨翻译单元可见。                                             |
| **static**（顶层）                                        | **内部链接**                           | ✅                            | 仅当前 .cpp 可见；等价于“文件私有”。匿名命名空间也可达成同效。 |
| **const**/**constexpr** 变量（顶层，非 extern/非 inline） | **内部链接**                           | ✅                            | C++ 规定默认内部链接（可放头文件而不冲突）。                 |
| **extern** 变量声明                                       | 一般为**外部链接**                     | **对const/constexpr 会改变** | `extern int x;` 只是声明；对 `const/constexpr`，`extern` 将其从默认**内部**改为**外部**链接（用于跨文件共享常量）。 |
| **extern** 函数声明                                       | **外部链接**                           | ❌                            | 函数本就默认外部链接，`extern` 基本冗余（`extern "C"` 例外是改变“语言链接”而非链接范围）。 |
| **inline 函数**                                           | **外部链接**（除非加 `static`）        | ❌                            | 允许在多个翻译单元出现**相同定义**；使用处需能看到定义。`static inline` 则内部链接。 |
| **inline 变量（C++17+）**                                 | **外部链接**（若未加 `static`）        | ✅                            | 允许在头文件定义一次并多处包含，典型写法 `inline constexpr auto k = ...;`。`static inline` 可做成内部链接。 |