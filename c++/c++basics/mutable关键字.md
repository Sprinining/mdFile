## mutable关键字

在 C++ 中，`mutable` 是一个 **类型修饰符**，用于 **允许某个类的成员变量在 `const` 对象中被修改**。这在一些特殊场景下非常有用，比如需要在 `const` 函数中修改某些缓存变量、统计访问次数等，但又不希望改变类的外部逻辑状态。

### `mutable` 的基本语法

```cpp
class MyClass {
public:
    mutable int counter;

    void increase() const {
        ++counter; // 合法，尽管是 const 函数
    }
};
```

- `counter` 被声明为 `mutable`，即使是在 `const` 成员函数中，也允许对它进行修改。

- `increase()` 是 `const` 函数，它不能修改除 `mutable` 成员以外的任何数据成员。

### 使用场景

#### 在 `const` 成员函数中做缓存或懒加载

```cpp
// 一个带缓存功能的类，使用 mutable 实现懒计算（lazy evaluation）
class CachedValue {
private:
    // 标志变量：表示是否已经计算过结果
    // 因为会在 const 函数中修改，必须加 mutable 修饰
    mutable bool computed = false;

    // 缓存的计算结果，初始值为 0
    // 也是需要在 const 函数中被修改，所以加 mutable
    mutable int cache = 0;

public:
    // 返回计算值的函数，逻辑上是 const 的：对外接口不会改变对象的状态
    int getValue() const {
        // 如果还没计算过，就计算一次并缓存结果
        if (!computed) {
            cache = expensiveCalculation();  // 修改了 mutable 成员
            computed = true;                 // 标记为已计算
        }
        // 返回缓存的结果
        return cache;
    }

private:
    // 实际的计算逻辑（模拟耗时操作）
    int expensiveCalculation() const {
        return 42;
    }
};
```

- 虽然 `getValue()` 是 `const`，但它需要修改 `computed` 和 `cache`，这些变量被声明为 `mutable` 以绕过编译器的限制。

- 这是典型的 **懒计算缓存** 模式。

#### 日志记录或统计访问次数

```cpp
class Logger {
private:
    mutable int accessCount = 0;

public:
    void print() const {
        ++accessCount;
        std::cout << "Access #" << accessCount << std::endl;
    }
};
```

### 为什么需要 `mutable`

在 C++ 中，`const` 成员函数承诺“不修改对象状态”，但这往往是逻辑意义上的不变性（logical constness），而非物理上的不变性（bitwise constness）。
 而 `mutable` 的引入，正是为了在满足逻辑 const 的前提下，允许修改某些内部细节。

### 和 `const_cast` 区别

| 特性         | `mutable`                     | `const_cast`                              |
| ------------ | ----------------------------- | ----------------------------------------- |
| 用途         | 成员变量在 const 对象中可修改 | 去除对象的 const 修饰符                   |
| 编译期安全   | 是                            | 否，若修改真正 const 对象会导致未定义行为 |
| 推荐使用程度 | 安全合理使用没问题            | 小心使用，容易出错                        |

### 常见陷阱

1. **不要滥用 `mutable`**。它破坏了 `const` 的“承诺”，应仅在有充分理由的情况下使用。

2. **线程安全问题**。如果 `mutable` 成员在多线程下被修改，可能导致竞态条件。

3. **`mutable` 只能用于类的非静态成员变量**，不能修饰局部变量、静态变量、函数或参数等。

> #### ❌ 为什么不能用于局部变量？
>
> 局部变量本身没有 `const` 对象约束，根本就不需要 `mutable`：
>
> ```cpp
> void func() {
>     mutable int x = 0; // ❌ 错误：编译不通过
> }
> ```
>
> 局部变量随时可以修改，它从来不会受到 `const` 的约束，所以 `mutable` 没有任何意义，自然也被语言禁止使用。
>
> ------
>
> #### ❌ 为什么不能用于函数？
>
> 函数不是变量，`mutable` 修饰的是**变量的可变性**，不能用于函数。
>
> ```cpp
> mutable int getValue(); // ❌ 错误：语法非法
> ```
>
> 如果想表达“这个函数在 `const` 对象上也能调用”，应该用 `const` 修饰函数，而不是 `mutable`：
>
> ```cpp
> int getValue() const; // ✅ 合法，表示此函数不会修改对象状态
> ```
>
> ------
>
> #### ❌ 为什么不能用于函数参数？
>
> 因为函数参数也是局部变量，它们没有 `const` 对象语义，也不需要 `mutable`。
>
> ```cpp
> void func(mutable int x); // ❌ 错误
> ```
>
> 而如果希望参数不可修改，可以用 `const` 修饰：
>
> ```cpp
> void func(const int x); // ✅ 合法，表示 x 不可修改（传值没意义，传引用才重要）
> ```
>
> ------
>
> #### ❌ 为什么不能用于静态成员变量？
>
> 静态成员变量是**类级别的变量，不依赖于具体对象**，不受 `const` 对象的影响。
>
> ```cpp
> class A {
>     mutable static int count; // ❌ 错误，mutable 不能用于 static 成员
> };
> ```
>
> 解释：
>
> - `const` 对象是指某个具体对象不可修改，而 `static` 变量与具体对象无关。
> - 所以，即使某个对象是 `const`，依然可以修改类的 `static` 变量（前提是没有被 `const` 修饰）。
>
> ```cpp
> class A {
>     static int count;
>     void modify() const {
>         ++count; // ✅ 合法，即使是在 const 函数中
>     }
> };
> ```