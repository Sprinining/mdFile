## 条款12：使用 override 声明重写函数

- 在 C++ 面向对象中，派生类可以重写（override）基类的虚函数，实现多态。
- 重写与重载不同，重写是基类和派生类中同名、参数、常量性、返回类型兼容的虚函数。
- 重写时，基类函数必须是 `virtual`，派生类函数名、参数、const、引用限定符等必须完全匹配。

### 常见重写错误示例

```cpp
class Base {
public:
    virtual void mf1() const;
    virtual void mf2(int x);
    virtual void mf3() &;
    void mf4() const;
};

class Derived : public Base {
public:
    virtual void mf1();             // 忘写 const，没重写
    virtual void mf2(unsigned int); // 参数类型不匹配
    virtual void mf3() &&;          // 引用限定符不匹配
    void mf4() const;               // 基类没 virtual，非重写
};
```

这些写法编译器不会报错，但派生类并未重写基类函数，导致多态失效。

### C++11 override 关键字

- `override` 明确告诉编译器这是一个重写函数。
- 编译器会校验函数是否真正重写了基类的虚函数，否则报错。
- 使用 `override` 能捕捉上述重写错误，避免意外的行为。

```cpp
class Derived : public Base {
public:
    virtual void mf1() override;          	 // 编译报错，缺 const
    virtual void mf2(unsigned int) override; // 报错，参数不匹配
    virtual void mf3() && override;       	 // 报错，引用限定符不匹配
    void mf4() const override;            	 // 报错，基类无 virtual
};
```

正确写法：

```cpp
class Base {
public:
    virtual void mf1() const;
    virtual void mf2(int x);
    virtual void mf3() &;
    virtual void mf4() const;
};

class Derived : public Base {
public:
    // 在 C++11 及之后的标准中，如果在派生类函数后面已经写了 override，就不需要再写 virtual
    void mf1() const override;
    void mf2(int x) override;
    void mf3() & override;
    void mf4() const override; // 基类有 virtual，override 有效
};
```

- `override` 是**声明时使用的关键字**，告诉编译器你打算重写某个虚函数；
- 在函数定义时（类外实现），不要写 `override`，否则编译失败；
- 只写在类内声明就够了。
- `const` 和**引用限定符（`&`, `&&`）** 和 `override` 不一样，它们**必须同时出现在类外定义中**，否则函数签名不匹配，**会导致不是“实现”，而是定义了一个新函数**。

### 成员函数的引用限定符

C++11引入成员函数引用限定符，限定成员函数只能由左值或右值对象调用。

```cpp
class Widget {
public:
    void doWork() &;   // 只能由左值对象调用
    void doWork() &&;  // 只能由右值对象调用
};
```

- 派生类重写时，引用限定符必须匹配。

### 为什么使用 override

- 防止不小心写成重载，导致多态失效。
- 方便修改基类接口后，能快速发现不匹配的派生类重写。
- 提高代码可读性和维护性。

### 总结

- 派生类重写基类虚函数时，**必须加 `override`**。
- 重写要求完全匹配：函数名、参数、const、引用限定符等。
- 引用限定符是成员函数的重要部分，影响重写与调用。
- 使用 `override` 让编译器捕获错误，避免隐患。