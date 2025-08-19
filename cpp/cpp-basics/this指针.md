## this 指针

在 C++ 中，每个非静态成员函数（普通成员函数）都有一个隐式的指针参数 `this`，它指向**调用该成员函数的对象本身**。

```cpp
class Person {
public:
    string name;

    void setName(string name) {
        this->name = name;  // 用 this 区分成员变量和参数
    }
};
```

- `this->name` 是成员变量。
- `name` 是函数参数。
- 使用 `this->name` 表示当前对象的 `name` 成员。

### this 指针的关键特性

1. **只在非静态成员函数中可用**。
   - 因为静态成员函数不属于具体对象，它们无法访问 `this`。

2. **`this` 是一个常量指针**，类型是 `ClassName* const`。
   - 指针本身不能被修改（不能让 `this` 指向其他对象），但可以通过它修改对象成员。

3. **在链式调用中尤为重要**（返回 `*this` 实现链式调用）。

### this 的常见用途

#### 区分成员变量与参数名冲突

```cpp
class Student {
private:
    int age;
public:
    void setAge(int age) {
        this->age = age; // 明确表示赋值给成员变量
    }
};
```

#### 返回当前对象（支持链式调用）

```cpp
class Person {
private:
    string name;
    int age;
public:
    Person& setName(const string& name) {
        this->name = name;
        return *this;  // 返回当前对象的引用
    }

    Person& setAge(int age) {
        this->age = age;
        return *this;
    }
};

// 使用
Person p;
p.setName("Tom").setAge(25);
```

#### 实现对象比较

```cpp
class Box {
    int length;
public:
    Box(int l) : length(l) {}
    bool isLongerThan(Box& other) {
        return this->length > other.length;
    }
};
```

#### 在拷贝赋值运算符中处理自赋值

```cpp
class MyClass {
private:
    int* data;
public:
    MyClass& operator=(const MyClass& other) {
        if (this == &other) return *this;  // 检查是否是自赋值
        delete data;
        data = new int(*other.data);
        return *this;
    }
};
```

### 易错点

| 情况              | 是否可以使用 `this`               |
| ----------------- | --------------------------------- |
| 非静态成员函数    | 可以                              |
| 静态成员函数      | 不可以（无对象上下文）            |
| 构造函数/析构函数 | 可以（对象已构造/尚未销毁）       |
| lambda 表达式     | 默认不捕获，需要显式捕获 `[this]` |

### 底层实现原理

非静态成员函数在编译时会被转换为一个**多了一个隐式参数的普通函数**：

```cpp
// 逻辑上相当于：
void setName(Person* this, string name) {
    this->name = name;
}
```

因此 `this` 本质上就是一个隐藏的指针参数。