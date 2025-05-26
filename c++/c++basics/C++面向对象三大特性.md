## C++面向对象三大特性

C++ 中的面向对象三大特性是：**封装（Encapsulation）**、**继承（Inheritance）**、**多态（Polymorphism）**。这三者构成了面向对象编程（OOP）的核心理念。

### 一、封装（Encapsulation）

#### 概念：

封装是**将数据和操作数据的函数绑定在一起**，并对外部隐藏实现细节，只暴露必要的接口。这种机制有助于提高代码的安全性和可维护性。

#### 特点：

- 通过 `private`, `protected`, `public` 控制访问权限
- 限制外部直接访问内部状态
- 提供 getter/setter 函数访问或修改私有数据

#### 示例代码：

```cpp
#include <iostream>
using namespace std;

class Person {
private:
    string name;
    int age;

public:
    void setName(const string& n) { name = n; }
    void setAge(int a) { 
        if (a >= 0) age = a; 
    }

    string getName() const { return name; }
    int getAge() const { return age; }

    void showInfo() const {
        cout << "Name: " << name << ", Age: " << age << endl;
    }
};
```

#### 总结：

- 封装的核心是“**隐藏细节，对外提供接口**”
- 有助于防止非法访问，提高模块独立性

### 二、继承（Inheritance）

#### 概念：

继承是指一个类（子类）**继承另一个类（父类）的属性和行为**，从而实现代码复用。

#### 语法形式：

```cpp
class 子类 : 继承方式 父类 {};
```

#### 继承方式：

- `public`：保留 public、protected 成员访问性（最常用）
- `protected`：public -> protected，protected 不变
- `private`：public/protected -> private

#### 示例代码：

```cpp
#include <iostream>
using namespace std;

class Animal {
public:
    void eat() { cout << "Animal eats\n"; }
};

class Dog : public Animal {
public:
    void bark() { cout << "Dog barks\n"; }
};

int main() {
    Dog d;
    d.eat();   // 继承自 Animal
    d.bark();  // 自己的函数
    return 0;
}
```

#### 总结：

- 继承实现了“**代码复用**”与“**逻辑层次结构**”
- 子类可以扩展或重写父类的功能（多态的基础）

### 三、多态（Polymorphism）

#### 概念：

多态是指“**同一个接口，不同的实现**”，它允许用父类指针/引用调用子类的重写方法，分为：

- **静态多态**（编译时）：函数重载 / 运算符重载
- **动态多态**（运行时）：虚函数 + 父类指针或引用

#### 条件（动态多态）：

- 基类函数为 `virtual`
- 子类重写该函数
- 使用基类指针或引用调用

#### 示例代码：

```cpp
#include <iostream>
using namespace std;

class Animal {
public:
    virtual void makeSound() const {
        cout << "Animal sound\n";
    }
};

class Dog : public Animal {
public:
    void makeSound() const override {
        cout << "Woof!\n";
    }
};

class Cat : public Animal {
public:
    void makeSound() const override {
        cout << "Meow!\n";
    }
};

void playSound(const Animal& a) {
    a.makeSound();  // 动态绑定
}

int main() {
    Dog d;
    Cat c;

    playSound(d);  // Woof!
    playSound(c);  // Meow!
    return 0;
}
```

#### 虚析构函数：

如果你希望通过基类指针 `delete` 子类对象，基类应定义虚析构函数：

```cpp
class Animal {
public:
    virtual ~Animal() { cout << "Animal destroyed\n"; }
};
```

#### 总结：

- 多态让程序更灵活，**支持开闭原则（对扩展开放，对修改关闭）**
- 是**面向对象设计模式**的核心基础

### 总结三大特性对比：

| 特性 | 作用                             | 实现手段                   |
| ---- | -------------------------------- | -------------------------- |
| 封装 | 隐藏实现细节，提高安全性         | 访问控制符 + 类成员封装    |
| 继承 | 实现代码复用和层级结构           | `:` 继承语法 + 基类/派生类 |
| 多态 | 接口统一、行为多样化，增强扩展性 | `virtual` 函数 + 重写机制  |