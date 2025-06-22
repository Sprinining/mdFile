## C++链接属性

C++ 中的**链接属性（Linkage）**是指名字（如变量名、函数名）在多个翻译单元中的可见性与共享性，是理解 **头文件引用规则**、**多文件编译**、**extern/static关键字作用** 的基础。

### C++中名字的链接属性分类

C++中，**名字（Name）**有三种链接属性：

| 链接属性                     | 含义说明                                                 | 示例                               |
| ---------------------------- | -------------------------------------------------------- | ---------------------------------- |
| 无链接（no linkage）         | 名字只在定义它的作用域内可见，不能被其他文件访问         | 局部变量、类的成员函数参数等       |
| 内部链接（internal linkage） | 名字只在当前翻译单元（即当前 `.cpp` 文件）可见           | 使用 `static` 修饰的全局变量/函数  |
| 外部链接（external linkage） | 名字可跨多个翻译单元访问（即可以被其他 `.cpp` 文件使用） | 普通全局变量、非静态函数、`extern` |

### 局部变量、全局变量和函数的链接属性举例

1. 局部变量：无链接

```cpp
void func() {
    int x = 10; // x 为局部变量，无链接
}
```

2. 全局变量：默认外部链接

```cpp
int g = 100;   // g 是全局变量，具有 external linkage，可被其他 cpp 文件引用
```

3. 使用 `static` 修饰：内部链接

```cpp
static int s = 42;  // s 是静态全局变量，仅当前 cpp 文件可见，具有 internal linkage
```

### `extern` 关键字与链接属性

在声明变量时使用 `extern`：声明外部变量

```cpp
// a.cpp
int g = 123; // 定义，具有 external linkage

// b.cpp
extern int g; // extern 并不会“增加”外部链接，而只是“声明”某个已经具有外部链接的变量存在于别的翻译单元。
```

注意：`extern` 本身不创建变量，只是告诉编译器「这个变量在别的地方定义了」。

只有以下情况会**真正影响变量的链接属性**：

| 修饰符                             | 效果                                                         |
| ---------------------------------- | ------------------------------------------------------------ |
| `static`                           | 将变量/函数的链接属性变为 **内部链接（internal linkage）**，仅当前 `.cpp` 可见 |
| `const`（顶层，非 `extern const`） | 默认是内部链接（因为 C++ 语义中 `const` 视为不共享）         |
| `inline`（变量/函数）              | 会影响 One Definition Rule 的应用，但仍需注意链接规则        |
| `extern`                           | ❗**不改变链接属性**，只是进行引用声明                        |

### `const` 与链接属性（常见易错点）

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

### 常见错误案例

❌ 多个 cpp 文件重复定义全局变量

```cpp
// a.cpp
int g = 1; // global.cpp
// b.cpp
int g = 2; // error: multiple definitions of `g`
```

应改为：

```cpp
// common.h
extern int g;
// common.cpp
int g = 1;
```

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