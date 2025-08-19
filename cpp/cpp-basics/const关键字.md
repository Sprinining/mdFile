## const 关键字

### 修饰变量

当 `const` 用于普通变量时，它表示该变量的值在初始化后不能被修改。

```c++
const int x = 10;
x = 20; // 错误，不能修改常量变量

const int arr[3] = {1, 2, 3};
arr[0] = 4;  // 错误，不能修改数组内容
```

### 修饰成员函数

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

### 修饰函数参数

值传递 + const：一般没意义（参数是副本）

```c++
void f(const int x); // x 是副本，写 const 不影响调用方
```

引用传递 + const：**推荐**，可防止误修改，且避免拷贝开销

```c++
void print(const std::string& s); // 最常见的用法
```

### 修饰返回值

适用于不希望调用者修改返回结果的场景。

```c++
const int& getValue(); // 返回只读引用（防止修改返回值）
```

### 常量指针与常量引用

#### 常量指针

```c++
int* const p = &x;
```

- `p` 是一个**常量指针**，**指针地址不能变**，但**可以修改指向的值**。
- 换句话说，**不能让 p 指向别的地方**，但可以做 `*p = xx`。

对比：

| 声明                  | 指针本身可变？ | 指向值可变？ | 含义                                                         |
| --------------------- | -------------- | ------------ | ------------------------------------------------------------ |
| `const int* p;`       | 是             | 否           | 指向常量的指针（pointer to const）                           |
| `int* const p;`       | 否             | 是           | 常量指针（const pointer）                                    |
| `const int* const p;` | 否             | 否           | 指向常量的常量指针（const pointer to const），p 是一个常量指针，指向一个常量 int。 |

快速记忆小技巧：

- `const` 在 `*` 的 **左边**：指向的内容是常量。
- `const` 在 `*` 的 **右边**：指针本身是常量。

```c++
// *p 是 const，p 可变
const int* p;    
const int *p;
int const *p;

// p 是 const，*p 可变
int* const p;    
int *const p;
```
#### 常量引用

```c++
const int &ref = x;
```

- `ref` 是 `x` 的一个引用，但是只读的。
- **不能通过 `ref` 修改 `x` 的值**。

```c++
int a = 10;
const int &ref = a;
ref = 20; // 错误，ref 是常量引用，不能修改 a
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

在 C++ 里，引用（reference）本质上只是某个已有对象的别名，并不是真正独立的对象，也不是指针。所以**不能像指针那样说“指向常量的引用”**，因为引用本身不“指向”任何东西，它只是绑定到一个对象上。

#### 顶层 const 和底层 const

##### 顶层 const（Top-level const）

修饰**变量本身**，表示该变量是只读的，**不能修改变量本身的值或指向**。

```c++
const int a = 10;       // a 是顶层 const，a 不能被修改
int* const p1 = ptr;    // p1 是顶层 const，p1 不能指向别处，但 *p1 可改，p1 是个常量指针
```

- 顶层 `const` 修饰的是对象本身（包括指针变量本身）。

- 在函数参数传递时，**顶层 const 不会影响传参（因为是按值传递，const 会被忽略）**。

##### 底层 const（Low-level const）

修饰的是**通过指针或引用访问到的对象**，表示该对象是只读的。

```c++
const int* p2 = &a;     // 底层 const，p2 可以指向别的地方，但不能通过 p2 修改 *p2 的值
int const* p3 = &a;     // 同上，const 在前在后都一样
const int& r = a;       // 引用的底层 const，r 不能修改 a 的值
```

- 底层 `const` 修饰的是指针/引用**所指向的数据**。

- 在指针传递中，底层 `const` 体现对数据的只读保护。

- 函数参数中如果是引用/指针类型的 `const`，则不会被忽略。

在函数参数中

```c++
void foo1(const int x);         // 顶层 const：传值，const 会被忽略
void foo2(const int* p);        // 底层 const：函数内不能修改 *p
void foo3(int* const p);        // 顶层 const：函数内不能修改 p 的指向
void foo4(const int* const p);  // 顶层 + 底层 const：都不能改
```

### const 和宏的区别

```c++
#define PI 3.14        // 宏替换，不是类型安全的
const double pi = 3.14; // 推荐，类型安全
```

### const 和 constexpr

#### `const`（常量）

表示变量在程序运行期间**只读**，不可修改。

- 变量值不一定在编译期已知，可以在运行时赋值。
- **不是编译期常量**，所以在需要编译期常量的地方（如数组大小）可能不合法。

```cpp
const int n = 10;
int arr[n];       // C++98 不允许（GCC 扩展允许）

int input;
cin >> input;
// 运行时赋值的 `const` 变量是**只读变量**，不是编译期常量
const int x = input; 
int arr[x];       // 错，x 的值直到运行时才确定
```

#### `constexpr`（编译期常量，C++11 起）

变量或函数在编译期就必须求值，结果在编译时已知。

- 可用于数组大小、模板参数等需要编译期常量的场景。
- `constexpr` 函数在编译期可计算出结果，如果参数在编译期已知，则生成代码时直接用结果，不会调用函数。

```cpp
constexpr int m = 10;
int arr2[m];       // 合法

constexpr int square(int n) {
    return n * n;
}

int arr[square(5)];  // 编译期求值，等价于 int arr[25];
```

#### `constexpr` 替换条件

1. 所有参数在编译期已知；
2. 表达式不依赖运行时数据；
3. 函数语法受限：不能有动态分配（`new`/`malloc`）、IO、异常、虚函数等操作。

反例：

```cpp
constexpr int get_val(bool b) {
    return b ? 1 : 2;
}

int x = get_val(cin.get() == 'a');  
// 运行时参数 ⇒ 编译期不能替换，get_val 会按普通函数处理
```
