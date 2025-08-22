## C++ 返回值优化（RVO）

当函数返回一个对象时，按照传统理解，编译器会：

- 在函数内部创建一个临时对象（返回值对象）。
- 通过拷贝构造函数或移动构造函数，将临时对象拷贝或移动到调用者的变量。

这可能导致一次或多次额外的对象构造、拷贝、移动，影响性能。

**返回值优化（RVO，Return Value Optimization）**就是编译器的一个优化技术，目的是：直接在调用者提供的存储空间中构造返回对象，省去临时对象的创建和拷贝/移动，从而提升性能。

### 示例

```cpp
class MyClass {
public:
    MyClass() { std::cout << "Constructed\n"; }
    MyClass(const MyClass&) { std::cout << "Copy Constructed\n"; }
    MyClass(MyClass&&) noexcept { std::cout << "Move Constructed\n"; }
};

MyClass create() {
    MyClass obj;
    return obj;
}

int main() {
    MyClass a = create();
}
```

- **没有 RVO：**
  - `create()` 内部先构造 `obj`
  - 返回时调用拷贝构造（或移动构造）将 `obj` 拷贝/移动给 `a`

- **有 RVO：**
  - 编译器直接在 `a` 的内存空间中构造 `obj`
  - 没有额外的拷贝或移动构造调用

```cpp
MyClass f1() {
    MyClass a;
    return a;       // NRVO 可能生效
}

MyClass f2() {
    return MyClass();  // 无名临时对象，RVO 通常生效
}

MyClass f3() {
    MyClass a;
    MyClass b;
    if (some_condition) {
        return a;    // NRVO 可能生效
    } else {
        return b;    // NRVO 可能无法生效，依赖编译器
    }
}
```

- 其中 `f3` 中因为有多个返回变量，NRVO 可能失效，编译器会退回使用移动构造。

### RVO 的两种主要形式

- **NRVO（Named Return Value Optimization）**
  函数返回的是一个具名变量，比如上面例子中的 `obj`，编译器可以直接在调用者提供的空间构造 `obj`。
- **Unnamed RVO**
  返回的是一个临时对象，比如 `return MyClass();`，编译器也可以直接在调用者空间构造该临时对象。

### C++ 标准对 RVO 的支持

- **C++03**：RVO 是一种允许的优化，但不是必须，编译器可选实现。
- **C++11**：引入了移动语义，减少了拷贝开销，但 RVO 依然是编译器优化。
- **C++17**：对某些情形下的返回值，标准强制执行所谓的**拷贝省略**，即 RVO 成为必需。

简言之，C++17 以后部分情况下编译器必须进行返回值优化，禁止调用拷贝或移动构造。


