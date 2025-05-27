## C++复杂类型声明的阅读

在 C++ 中，复杂类型声明（如指针、数组、函数指针、引用等混合嵌套的声明）确实难读。理解这类声明的核心技巧是掌握“**从标识符出发，遵循优先级规则，使用右左规则（Right-Left Rule）**”进行分析。

### 一、阅读复杂类型声明的基本规则（右左法则 Right-Left Rule）

从变量名（标识符）开始，按照以下优先级顺序分析：

```bash
1. 括号 ()
2. 后缀 []（数组）和 ()（函数）
3. 前缀 *（指针）、&（引用）
```

### 二、例子讲解

#### 例 1：`int *p[10];`

- `p` 是标识符
- `[]` 优先级高于 `*`，所以 `p` 是一个数组
- `p` 是一个包含 10 个元素的数组，数组元素是 `int*` 类型的指针

**解读：p 是一个包含 10 个元素的数组，每个元素是指向 int 的指针**

#### 例 2：`int (*p)[10];`

- 括号改变了优先级，先处理 `(*p)` —— p 是指针
- 然后看 `[]10` —— 指向一个有 10 个 `int` 的数组

**解读：p 是一个指针，指向一个包含 10 个 int 的数组**

#### 例 3：`int *(*pf)(double);`

- `pf` 是指针，指向一个函数
- 这个函数接收一个 `double` 类型的参数
- 返回值是 `int*`

**解读：pf 是一个指向函数的指针，该函数接收 double 参数并返回 int 指针**

#### **例 4：`void (*signal(int, void (*)(int)))(int);`** （经典 Unix 函数声明）

分段理解：

- `signal` 是函数名
- 参数：`int`，`void (*)(int)` → 第二个参数是一个函数指针，接收 int，返回 void
- 返回值是：`void (*)(int)`，即一个函数指针，接收 int，返回 void

**解读：signal 是一个函数，它接收两个参数（一个 int，一个函数指针），返回一个函数指针**

### 三、简化阅读

`typedef` 写法：

```cpp
typedef int (*IntArrayPtr)[10];
typedef IntArrayPtr (*FuncPtr)(double);
FuncPtr foo;
```

`using` 写法（C++11 起）：

```cpp
using IntArrayPtr = int (*)[10];          // 指向10个int的数组的指针
using FuncPtr = IntArrayPtr (*)(double);  // 接受double，返回上述类型的函数指针

FuncPtr foo;
```