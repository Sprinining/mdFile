## const关键字

### 1. 常量变量

当 `const` 用于普通变量时，它表示该变量的值在初始化后不能被修改。

```c++
const int x = 10;
x = 20; // 错误，不能修改常量变量
```

### 2. 常量成员函数

当 `const` 用于成员函数时，表示该函数不会修改对象的状态。通常用于 getter 函数。

```c++
class MyClass {
public:
    int value;
    MyClass(int v) : value(v) {}

    int getValue() const {  // const 成员函数
        return value;
    }

    void setValue(int v) {
        value = v;
    }
};

int main() {
    const MyClass obj(10);  // obj 是常量对象
    int val = obj.getValue();  // 合法，可以调用 const 成员函数
    obj.setValue(20);  // 错误，不能调用非 const 成员函数
}
```

### 3. 常量数组

```c++
const int arr[3] = {1, 2, 3};
arr[0] = 4;  // 错误，不能修改数组内容
```

### 4.修饰函数参数

值传递 + const：一般没意义（参数是副本）

```c++
void f(const int x); // x 是副本，写 const 不影响调用方
```

引用传递 + const：**推荐**，可防止误修改，且避免拷贝开销

```c++
void print(const std::string& s); // 最常见的用法
```

### 5. 修饰返回值

适用于不希望调用者修改返回结果的场景。

```c++
const int& getValue(); // 返回只读引用（防止修改返回值）
```


### 6. 常量指针

```c++
int* const p = &x;
```

- `p` 是一个**常量指针**，**指针地址不能变**，但**可以修改指向的值**。
- 换句话说，**不能让 p 指向别的地方**，但可以做 `*p = xx`。

示例：

```c++
int a = 10, b = 20;
int* const p = &a;  // 指针是常量，不能再指向别的变量

*p = 30;     // ✅ 可以改 a 的值
p = &b;      // ❌ 错误，p 是 const，不能修改地址
```

对比：

| 声明                  | 指针本身可变？ | 指向值可变？ | 含义                                                         |
| --------------------- | -------------- | ------------ | ------------------------------------------------------------ |
| `const int* p;`       | ✅ 是           | ❌ 否         | 指向常量的指针（pointer to const）                           |
| `int* const p;`       | ❌ 否           | ✅ 是         | 常量指针（const pointer）                                    |
| `const int* const p;` | ❌ 否           | ❌ 否         | 指向常量的常量指针（const pointer to const），p 是一个常量指针，指向一个常量 int。 |

快速记忆小技巧：

> `const` 在 `*` 的 **左边**：指向的内容是常量。
>
> `const` 在 `*` 的 **右边**：指针本身是常量。

比如：

```c++
// *p 是 const，p 可变
const int* p;    
const int *p;
int const *p;

// p 是 const，*p 可变
int* const p;    
int *const p;
```
### 7. 常量引用

```c++
const int &ref = x;
```

- `ref` 是 `x` 的一个引用，但是只读的。
- **不能通过 `ref` 修改 `x` 的值**。

示例：

```c++
int a = 10;
const int &ref = a;
ref = 20; // ❌ 错误，ref 是常量引用，不能修改 a
```

常用场景：

- **函数参数传递**，防止修改，提升效率：

  ```c++
  void print(const std::string& s); // 传大对象的推荐方式
  ```

- **延长临时变量生命周期**：

  ```c++
  const int& r = 1 + 2; // 绑定临时变量
  ```

在 C++ 中没有“**指向常量的引用**”这种合法说法。因为引用本身不是对象，也不是指针，它只是一个别名。

### 8. 顶层 const 和底层 const

#### 顶层 `const`（Top-level const）

修饰**变量本身**，表示该变量是只读的，**不能修改变量本身的值或指向**。

```c++
const int a = 10;       // a 是顶层 const，a 不能被修改
int* const p1 = ptr;    // p1 是顶层 const，p1 不能指向别处，但 *p1 可改，p1 是个常量指针
```

- 顶层 `const` 修饰的是对象本身（包括指针变量本身）。

- 在函数参数传递时，**顶层 const 不会影响传参（因为是按值传递，const 会被忽略）**。

#### 底层 `const`（Low-level const）

修饰的是**通过指针或引用访问到的对象**，表示该对象是只读的。

```c++
const int* p2 = &a;     // 底层 const，p2 可以指向别的地方，但不能通过 p2 修改 *p2 的值
int const* p3 = &a;     // 同上，const 在前在后都一样
const int& r = a;       // 引用的底层 const，r 不能修改 a 的值
```

- 底层 `const` 修饰的是指针/引用**所指向的数据**。

- 在指针传递中，底层 `const` 体现对数据的只读保护。

- 函数参数中如果是引用/指针类型的 `const`，则不会被忽略。

#### 在函数参数中

```c++
void foo1(const int x);         // 顶层 const：传值，const 会被忽略
void foo2(const int* p);        // 底层 const：函数内不能修改 *p
void foo3(int* const p);        // 顶层 const：函数内不能修改 p 的指向
void foo4(const int* const p);  // 顶层 + 底层 const：都不能改
```

### 9. 补充

#### const 和宏（`#define`）的区别：

```c++
#define PI 3.14        // 宏替换，不是类型安全的
const double pi = 3.14; // 推荐，类型安全
```

#### const 不是 compile-time 常量（用不了在数组大小里）：

除非加上 `constexpr`（C++11 起）

```c++
const int n = 10;
int arr[n]; // C++98 不允许（GCC 扩展允许），C++11 中必须：

constexpr int m = 10;
int arr2[m]; // ✅ OK
```

`const` 是运行时常量，表示在运行时赋值的变量。

```c++
int input;
cin >> input;
const int x = input; // ❌ 不是编译期常量
int arr[x];          // ❌ 错，数组长度必须是常量表达式（C++ 标准）
// 这里 x 虽然是 const，但它的值直到程序运行时才知道 —— 所以它是运行时只读变量，不是编译期常量。
```

`constexpr` 是编译时常量，表示在编译时必须已知的常量。在编译期就会被求值并替换进代码中 —— 如果条件允许。

```c++
constexpr int square(int n) {
    return n * n;
}

int arr[square(5)];  // 等价于 int arr[25];
// 编译器会在编译期间直接计算出 square(5) == 25；
// 最终生成代码时，根本没有 square() 的函数调用，直接用结果。
```

能被 `constexpr` 替换的前提：

- 所有参数和上下文都是编译期已知的；

- 表达式没有运行时依赖；

- `constexpr` 函数的语法必须受限（不能有 `new`、`malloc`、IO、异常、虚函数等操作）。

反例：

```c++
constexpr int get_val(bool b) {
    return b ? 1 : 2;
}

int x = get_val(cin.get() == 'a');  // ❌ 运行期参数 ⇒ 不能替换
// 此时虽然 get_val() 是 constexpr，但因为参数取决于运行时输入，编译器不会在编译期替换，会按普通函数处理。
```

