## 条款11：优先考虑使用 deleted 函数，而非使用未定义的私有声明

### 背景与问题

- 在 C++98 中，想禁止某些特殊成员函数（如拷贝构造函数、拷贝赋值运算符）被调用，常用做法是将它们声明为私有（private）且不定义。
- 这样做虽然防止了外部调用，但如果在成员函数或友元中调用这些函数，只能在链接阶段报错，诊断滞后。
- 代码示例（C++98）：

```cpp
class Example {
private:
    Example(const Example&);            // 声明但未定义，禁止拷贝构造
    Example& operator=(const Example&); // 声明但未定义，禁止拷贝赋值
};
```

- **声明了函数但未定义，且没调用它，编译器不会报错。**
- **调用了未定义的函数，会导致链接错误（Linker error），提示找不到函数定义。**

### C++11 的改进：deleted 函数

- C++11 引入了 `= delete`，可以直接将函数声明为 **删除函数**。

- 删除函数不能被调用，无论是外部还是内部（成员、友元）调用都会被编译器拒绝，且错误信息更准确。

- 示例（C++11）：

  ```cpp
  class Example {
  public:
      Example(const Example&) = delete;
      Example& operator=(const Example&) = delete;
  };
  ```

- **deleted 函数通常声明为 public**，这样调用时编译器能给出更明确的错误提示，而非模糊的访问权限错误。

### deleted 函数的优势

1. **禁止调用更彻底**：任何调用都会编译错误，及时诊断。
2. **适用范围更广**：不仅限于成员函数，普通函数和模板实例都可被删除。
3. **避免链接错误**：不再依赖未定义函数导致的链接错误。

### deleted 函数的实际应用举例

#### 1. 禁止拷贝构造和赋值（见上）

#### 2. 禁止某些函数重载（防止隐式类型转换导致的不合理调用）

```cpp
bool isLucky(int number);       // 正常函数
bool isLucky(char) = delete;    // 禁止 char 类型调用
bool isLucky(bool) = delete;    // 禁止 bool 类型调用
bool isLucky(double) = delete;  // 禁止 double 类型调用（含 float 隐式转换）
```

调用 `isLucky('a')`、`isLucky(true)` 或 `isLucky(3.5f)` 都会编译失败。

#### 3. 禁止模板实例化某些类型

```cpp
// 普通模板函数，接受任意类型指针
template<typename T>
void processPointer(T* ptr);

// 删除不希望实例化的模板特化，
// 特化 void 类型指针版本，禁止调用 processPointer<void>(void*)
template<>
void processPointer<void>(void*) = delete;

// 删除 char 类型指针版本，禁止调用 processPointer<char>(char*)
template<>
void processPointer<char>(char*) = delete;

// 同样删除 const void 指针版本，禁止调用 processPointer<const void>(const void*)
template<>
void processPointer<const void>(const void*) = delete;

// 删除 const char 指针版本，禁止调用 processPointer<const char>(const char*)
template<>
void processPointer<const char>(const char*) = delete;
```

为什么 `template<>` 后面没写模板参数？

- `template<>` 表示**完全特化**（full specialization），告诉编译器这是模板的一个具体实例化版本。
- 既然是“完全特化”，模板参数已经确定了（比如 `<void>`），不需要再写模板参数列表了。
- 这和普通模板声明不同，普通模板需要模板参数列表 `<typename T>`。
- 这里省略了模板参数列表，是告诉编译器“这是 `T = void` 的版本”，不再是模板而是具体函数。

作用总结

- 通过特化加 `= delete`，禁止某些具体类型的模板实例被调用。
- 这种写法可以防止用户使用这些类型调用模板函数，提升代码安全性和可读性。

### 注意点

- 模板特化必须在命名空间作用域，不能在类内声明为私有。

  - **模板特化必须写在命名空间作用域，不能写在类内部**。
  - **因此不能用private访问权限控制模板特化**。
  - **用 `= delete` 在类外删除模板特化函数是更好的禁止方式**。
  
- 使用 deleted 函数可以避免 C++98 私有未定义方法带来的链接阶段错误及访问权限错误的模糊提示。

- 建议在替换老代码时，将原先的私有未定义函数替换为 `public` 的 deleted 函数以获得更好的错误信息。

### 总结

- **C++98**：用私有且未定义函数禁止调用，效果有限且错误不及时。
- **C++11**：用 `= delete` 标记函数为删除，禁止调用更彻底且错误提示更清晰。
- **deleted 函数比私有未定义函数更安全且适用范围更广**，推荐使用。