##  C++ 访问控制与继承

### 访问控制

C++ 提供三种访问控制修饰符，用于控制类成员（属性和方法）的可见性：

| 访问控制符 | 类内部 | 派生类 | 外部代码 |
| ---------- | ------ | ------ | -------- |
| public     | 可以   | 可以   | 可以     |
| protected  | 可以   | 可以   | 不可以   |
| private    | 可以   | 不可以 | 不可以   |

```cpp
class Base {
public:
    int publicVar;        // 任何地方都能访问
protected:
    int protectedVar;     // 只能在 Base 和派生类中访问
private:
    int privateVar;       // 只能在 Base 内部访问
};
```

### 继承

C++ 支持三种继承方式：

| 继承方式         | 基类 public 成员 | 基类 protected 成员 | 基类 private 成员 |
| ---------------- | ---------------- | ------------------- | ----------------- |
| `public` 继承    | public           | protected           | 不可访问          |
| `protected` 继承 | protected        | protected           | 不可访问          |
| `private` 继承   | private          | private             | 不可访问          |

### 派生类构造函数中使用基类的构造函数

显式在派生类构造函数的初始化列表中调用基类构造函数：

```cpp
struct Base {
    Base(int x) { std::cout << "Base(" << x << ")\n"; }
};

struct Derived : Base {
    Derived(int x) : Base(x) {  // 显式调用 Base 的构造函数
        std::cout << "Derived(" << x << ")\n";
    }
};
```

使用 using Base::Base; 继承构造函数（C++11 起）：

```cpp
#include <iostream>
using namespace std;

struct Base {
    Base(int x) { cout << "Base(int) " << x << endl; }
    Base(double y, int z) { cout << "Base(double, int) " << y << ", " << z << endl; }
};

struct Derived : Base {
    using Base::Base;  // 继承构造函数
};

int main() {
    Derived d1(10);       // 调用 Base(int)
    Derived d2(3.14, 42); // 调用 Base(double, int)
}
```

这样 `Derived` 会自动拥有 `Base` 的所有构造函数（除了拷贝/移动构造），并且行为就是直接调用对应的 `Base` 构造函数。

此时派生类自己的成员变量**会按正常规则初始化**：

- 如果给成员变量提供了默认初始值（C++11 起支持），它会被使用。
- 否则就是默认构造（`T{}`）或未初始化（POD 类型如 `int`）的状态。

### 访问控制 + 三种继承方式

```cpp
#include <iostream>
using namespace std;

class Base {
public:
    int a = 1;                    // public 成员
protected:
    int b = 2;                    // protected 成员
private:
    int c = 3;                    // private 成员（派生类不可见）

public:
    void showPublic() { cout << "Base::showPublic" << endl; }
protected:
    void showProtected() { cout << "Base::showProtected" << endl; }
private:
    void showPrivate() { cout << "Base::showPrivate" << endl; }
};

//------------------ 1. public 继承 ------------------
class PublicDerived : public Base {
public:
    void accessMembers() {
        cout << "PublicDerived access:\n";
        cout << a << endl;           // 仍是 public
        cout << b << endl;           // 仍是 protected
        // cout << c << endl;        // 编译错误，c 是 private，派生类不可见

        showPublic();                // OK
        showProtected();             // OK
        // showPrivate();            // 编译错误
    }
};

//------------------ 2. protected 继承 ------------------
class ProtectedDerived : protected Base {
public:
    void accessMembers() {
        cout << "ProtectedDerived access:\n";
        cout << a << endl;           // a 成为 protected
        cout << b << endl;           // b 保持 protected
        // cout << c << endl;        // 编译错误

        showPublic();                // 变为 protected
        showProtected();             // OK
        // showPrivate();            // 编译错误
    }
};

//------------------ 3. private 继承 ------------------
class PrivateDerived : private Base {
public:
    void accessMembers() {
        cout << "PrivateDerived access:\n";
        cout << a << endl;           // a 成为 private
        cout << b << endl;           // b 成为 private
        // cout << c << endl;        // 编译错误

        showPublic();                // 变为 private
        showProtected();             // 变为 private
        // showPrivate();            // 编译错误
    }
};

int main() {
    PublicDerived pd;
    pd.accessMembers();
    cout << pd.a << endl;           // public 继承保留 a 为 public
    // cout << pd.b << endl;        // 编译错误，b 是 protected
    // cout << pd.c << endl;        // 编译错误

    pd.showPublic();                // OK
    // pd.showProtected();          // 编译错误
    // pd.showPrivate();            // 编译错误

    ProtectedDerived prot;
    prot.accessMembers();
    // cout << prot.a << endl;     // 编译错误：a 是 protected
    // prot.showPublic();          // 编译错误

    PrivateDerived priv;
    priv.accessMembers();
    // cout << priv.a << endl;     // 编译错误：a 是 private
    // priv.showPublic();          // 编译错误
}
```

继承方式并不影响派生类对基类的访问权限：

- **派生类内部能访问什么，取决于基类中成员的访问修饰符：**

  - `public` 和 `protected` 成员：派生类都可以访问

  - `private` 成员：派生类永远无法访问（除非是友元）

- **继承方式（public / protected / private）影响的是**：
  - 派生类**继承下来**的成员，在“派生类的对象”被“类外部”访问时，显示什么权限。

### 友元

`friend` 可以绕过访问控制，用于类、函数、成员函数等声明为友元，具有访问私有/保护成员的权限。

#### 示例 1

- 派生类的成员或者友元**只能通过派生类对象**来访问基类的受保护成员。
- 派生类对于一个基类对象中的受保护成员没有任何访问特权。

```cpp
#include <iostream>
using namespace std;

class Base {
protected:
    int prot_mem = 42;
};

class Sneaky : public Base {
    friend void clobber(Sneaky&);
    friend void clobber(Base&);
    int j;

public:
    void accessMyOwnProtMem() {
        prot_mem = 100;  // 访问自己继承的 protected 成员
        cout << "Sneaky::accessMyOwnProtMem: " << prot_mem << endl;
    }

    void tryAccessBaseProtMem(Base& b) {
        // b.prot_mem = 999;  // 错误：无法访问 Base 类型对象的 protected 成员
        cout << "Sneaky::tryAccessBaseProtMem: 无法访问 b.prot_mem（会编译失败）" << endl;
    }
};

void clobber(Sneaky& s) {
    s.prot_mem = 200;  // Sneaky 的友元，可以访问 s 中继承的 prot_mem
    cout << "clobber(Sneaky&): " << s.prot_mem << endl;
}

void clobber(Base& b) {
    // b.prot_mem = 300;  // 错误：不是 Base 的友元，不能访问 Base 对象的 protected 成员
    cout << "clobber(Base&): 无法访问 b.prot_mem（会编译失败）" << endl;
}

int main() {
    Sneaky s;
    Base b;

    s.accessMyOwnProtMem();     // 合法
    s.tryAccessBaseProtMem(b);  // 非法访问，注释掉那一行才能编译通过

    clobber(s);  // 合法
    clobber(b);  // 若访问 b.prot_mem，会编译失败
}
```

| 对象类型           | 派生类中能访问基类 protected 成员？ | 原因说明                                                  |
| ------------------ | ----------------------------------- | --------------------------------------------------------- |
| 自己 (`this`)      | 可以                                | 继承而来，属于派生类                                      |
| 其他派生类对象     | 可以                                | 同一类内部，protected 可访问                              |
| 基类对象 (`Base&`) | 不可以                              | 不管你是子类还是友元，都不能访问基类对象的 protected 成员 |

#### 示例 2

```cpp
class Base {
    // 声明 Pal 为 Base 的友元类，Pal 可以访问 Base 的私有和保护成员
    friend class Pal;
protected:
    int prot_mem; // 受保护成员，派生类可以访问，外部类不能访问，除非是友元
};

class Sneaky : public Base {
    // Sneaky 继承自 Base，因此包含一个 Base 的子对象，包含 prot_mem
    // 但 j 是 Sneaky 自己的私有成员，外部不能访问，除非是 Sneaky 的友元
    int j;
};

class Pal {
public:
    // 合法：Pal 是 Base 的友元类，可以访问 Base 的 protected 成员
    int f(Base b) { 
        return b.prot_mem; // 合法访问 Base 对象中的 prot_mem
    }

    // 非法：虽然 Sneaky 是 Base 的派生类，但 j 是 Sneaky 的私有成员
    // Pal 不是 Sneaky 的友元类，因此不能访问 s.j
    // int f2(Sneaky s) { return s.j; };

    // 合法：Pal 是 Base 的友元类
    // 虽然 s 是 Sneaky 类型，但它内部有一个 Base 子对象
    // Pal 可以访问这个 Base 子对象中的 prot_mem 成员
    int f3(Sneaky s) { 
        return s.prot_mem; // 合法访问 Base 的 protected 成员
    }
};
```

- **友元权限是按声明所在类决定的，和对象的静态类型无关**。
-  如果你是 `Base` 的 friend，你就能访问“任何对象中的 Base 成员”，**不论那个对象是不是 Derived 类型**。

再通俗一点：

假设你是个小偷（friend），你只会撬开 `Base` 牌的保险箱（你不是 `Derived` 的小偷），那你可以对任何“有装 Base 保险箱”的箱子（Derived 对象），通过“Base 的方式”打开它，但你**不能用 Derived 的钥匙打开 Derived 的私人空间（private 成员）**。
