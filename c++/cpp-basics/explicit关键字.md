## explicit关键字

`explicit` 是 C++ 中的一个关键字，用于修饰 **只能通过显式方式调用的构造函数或转换函数**。它的主要作用是**防止隐式类型转换带来的错误或歧义**。

主要用于：

1. 构造函数（特别是单参数构造函数）
2. 类型转换函数（如 `operator T()`）

### 为什么需要 `explicit`？

C++ 的语言规则中，只要一个类有**非显式的单参数构造函数**，就会被编译器视为一个可以执行**隐式类型转换**的“转换通道”。

如果定义了一个带一个参数的构造函数，它可以被用作隐式类型转换。例如：

```cpp
class MyClass {
public:
    MyClass(int x) {
        std::cout << "Constructing with x = " << x << std::endl;
    }
};

void func(MyClass obj) {
    // ...
}

int main() {
    func(5);  // ⚠️ 隐式构造 MyClass(5)
}
```

上面 `func(5)` 实际上隐式构造了 `MyClass(5)`，虽然编译器允许，但在大型项目中可能会引起不易察觉的 bug。

#### 1. **非预期的类型转换**

你调用 `func(5)`，原本是想传入 `int` 吗？还是忘记构造？C++ 编译器**默默地帮你做了类型转换**，这就是隐式转换的风险。

比如：

```cpp
func(true); // 你想传 bool，但却转成了 int，再构造成了 MyClass
```

这在某些时候会出现“**代码能跑，但逻辑错了**”的问题。

#### 2. **重载/模糊调用时更易出错**

```cpp
void func(int x);
void func(MyClass obj);

func(5); // 模糊调用，编译器可能报错或选择错误的函数
```

如果存在多个重载，`func(5)` 到底调用哪个就可能变得模糊不清。

#### 3. **编写 API 时破坏接口约束**

比如你设计 `func(MyClass)` 是只允许接受 `MyClass` 类型的人调用，而隐式转换却允许别人传 `int`，这会破坏封装性、接口的意图表达。

### 使用 `explicit` 限制隐式转换

```cpp
class MyClass {
public:
    explicit MyClass(int x) {
        std::cout << "Explicit construct with x = " << x << std::endl;
    }
};

void func(MyClass obj) {
    // ...
}

int main() {
    func(5);         // ❌ 编译错误：不能隐式转换 int -> MyClass
    func(MyClass(5)); // ✅ 正确：显式构造
}
```

###  `explicit` 和 类型转换函数

也可以用于转换操作符，防止自动类型转换：

```cpp
class MyClass {
public:
    explicit operator int() const {
        return 42;
    }
};

int main() {
    MyClass obj;
    int x = obj;             // ❌ 错误，不能隐式转换
    int y = static_cast<int>(obj); // ✅ 正确
}
```

### C++11 之后的新用法

#### 多参数构造函数也可以用 `explicit`（C++11 起）

```cpp
class MyClass {
public:
    explicit MyClass(int a, int b) {
        // ...
    }
};
```

#### `explicit` 也可用于默认和删除的构造函数（C++11 起）

```cpp
class MyClass {
public:
    explicit MyClass() = default;
};
```

#### C++20：`explicit(bool)` 支持条件显式

```cpp
template <bool B>
class MyClass {
public:
    explicit(B) MyClass(int x) {
        // ...
    }
};
```

等价于下面两种写法的自动切换：

- 如果 `B == true`，那么构造函数是 `explicit`（**禁止隐式转换**）；
- 如果 `B == false`，那么构造函数是非 `explicit`（**允许隐式转换**）。

```cpp
MyClass<true> obj1 = 10;     // ❌ 错误，构造函数是 explicit，不允许隐式转换
MyClass<false> obj2 = 10;    // ✅ 正确，允许隐式转换
```

### 总结

| 构造函数参数数目 | 是否容易被隐式转换 | 是否建议加 `explicit`         |
| ---------------- | ------------------ | ----------------------------- |
| 单参数           | ✅ 高风险           | ✅ 强烈建议                    |
| 多参数（无 {}）  | ❌ 通常没事         | ❌ 不强求，但视情况而定        |
| 多参数（可 {}）  | ✅ 可能被列表初始化 | ✅ 推荐（特别是在 API 中使用） |
