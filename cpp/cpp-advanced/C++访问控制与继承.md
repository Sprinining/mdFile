##  C++ 访问控制与继承

### 访问控制（Access Control）

C++ 提供三种访问控制修饰符，用于控制类成员（属性和方法）的可见性：

| 访问控制符  | 类内部 | 派生类 | 外部代码 |
| ----------- | ------ | ------ | -------- |
| `public`    | ✅      | ✅      | ✅        |
| `protected` | ✅      | ✅      | ❌        |
| `private`   | ✅      | ❌      | ❌        |

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

### 继承（Inheritance）

C++ 支持三种继承方式：

| 继承方式         | 基类 public 成员 | 基类 protected 成员 | 基类 private 成员 |
| ---------------- | ---------------- | ------------------- | ----------------- |
| `public` 继承    | public           | protected           | 不可访问          |
| `protected` 继承 | protected        | protected           | 不可访问          |
| `private` 继承   | private          | private             | 不可访问          |

### 派生类构造函数中使用基类的构造函数

#### **显式在派生类构造函数的初始化列表中调用基类构造函数**（最常用）

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

#### **使用 `using Base::Base;` 继承构造函数**（C++11 起）

```cpp
struct Base {
    Base(int x) { std::cout << "Base(" << x << ")\n"; }
};

struct Derived : Base {
    using Base::Base;  // 继承构造函数
    // 现在 Derived(int x) 自动存在，等效于调用 Base(x)
};
```

这会让 `Derived` 自动拥有与 `Base` 构造函数相同的构造函数（合成形式），例如：

```cpp
Derived d(10);  // 实际调用的是 Base(10)
```

此时派生类自己的成员变量 **会按正常规则初始化**：

- 如果给成员变量提供了默认初始值（C++11 起支持），它会被使用。
- 否则就是默认构造（`T{}`）或未初始化（POD 类型如 `int`）的状态。

| 特性                                 | 说明                           |
| ------------------------------------ | ------------------------------ |
| 自动继承构造函数                     | 无需显式写构造函数             |
| 不会继承拷贝/移动构造、析构函数      | 仍需自定义或默认生成           |
| 不会继承构造函数体中的逻辑           | 若要附加逻辑仍需自己写构造函数 |
| 基类构造函数为 `explicit` 也会被继承 | 同样保留 `explicit`            |

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
        cout << a << endl;           // ✅ OK，仍是 public
        cout << b << endl;           // ✅ OK，仍是 protected
        // cout << c << endl;       // ❌ 编译错误，c 是 private，派生类不可见

        showPublic();                // ✅ OK
        showProtected();            // ✅ OK
        // showPrivate();           // ❌ 编译错误
    }
};

//------------------ 2. protected 继承 ------------------
class ProtectedDerived : protected Base {
public:
    void accessMembers() {
        cout << "ProtectedDerived access:\n";
        cout << a << endl;           // ✅ OK，a 成为 protected
        cout << b << endl;           // ✅ OK，b 保持 protected
        // cout << c << endl;       // ❌ 编译错误

        showPublic();                // ✅ OK，变为 protected
        showProtected();            // ✅ OK
        // showPrivate();           // ❌ 编译错误
    }
};

//------------------ 3. private 继承 ------------------
class PrivateDerived : private Base {
public:
    void accessMembers() {
        cout << "PrivateDerived access:\n";
        cout << a << endl;           // ✅ OK，a 成为 private
        cout << b << endl;           // ✅ OK，b 成为 private
        // cout << c << endl;       // ❌ 编译错误

        showPublic();                // ✅ OK，变为 private
        showProtected();            // ✅ OK
        // showPrivate();           // ❌ 编译错误
    }
};

int main() {
    PublicDerived pd;
    pd.accessMembers();
    cout << pd.a << endl;           // ✅ OK，public 继承保留 a 为 public
    // cout << pd.b << endl;       // ❌ 编译错误，b 是 protected
    // cout << pd.c << endl;       // ❌ 编译错误

    pd.showPublic();                // ✅ OK
    // pd.showProtected();         // ❌ 编译错误
    // pd.showPrivate();           // ❌ 编译错误

    ProtectedDerived prot;
    prot.accessMembers();
    // cout << prot.a << endl;     // ❌ 编译错误：a 是 protected
    // prot.showPublic();          // ❌ 编译错误

    PrivateDerived priv;
    priv.accessMembers();
    // cout << priv.a << endl;     // ❌ 编译错误：a 是 private
    // priv.showPublic();          // ❌ 编译错误
}
```

继承方式并不影响派生类对基类的访问权限：

- **派生类内部能访问什么，取决于基类中成员的访问修饰符：**

  - `public` 和 `protected` 成员：派生类都可以访问

  - `private` 成员：派生类永远无法访问（除非是友元）

- **继承方式（public / protected / private）影响的是**：
  - 派生类**继承下来**的成员，在“派生类的对象”被“类外部”访问时，显示什么权限。

### 友元（Friend）与访问控制

- `friend` 可以绕过访问控制，用于类、函数、成员函数等声明为友元，具有访问私有/保护成员的权限。

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
        prot_mem = 100;  // ✅ OK：访问自己继承的 protected 成员
        cout << "Sneaky::accessMyOwnProtMem: " << prot_mem << endl;
    }

    void tryAccessBaseProtMem(Base& b) {
        // b.prot_mem = 999;  // ❌ 错误：无法访问 Base 类型对象的 protected 成员
        cout << "Sneaky::tryAccessBaseProtMem: 无法访问 b.prot_mem（会编译失败）" << endl;
    }
};

void clobber(Sneaky& s) {
    s.prot_mem = 200;  // ✅ OK：Sneaky 的友元，可以访问 s 中继承的 prot_mem
    cout << "clobber(Sneaky&): " << s.prot_mem << endl;
}

void clobber(Base& b) {
    // b.prot_mem = 300;  // ❌ 错误：不是 Base 的友元，不能访问 Base 对象的 protected 成员
    cout << "clobber(Base&): 无法访问 b.prot_mem（会编译失败）" << endl;
}

int main() {
    Sneaky s;
    Base b;

    s.accessMyOwnProtMem();     // ✅ 合法
    s.tryAccessBaseProtMem(b); // ❌ 非法访问，注释掉那一行才能编译通过

    clobber(s);  // ✅ 合法
    clobber(b);  // ❌ 若访问 b.prot_mem，会编译失败
}
```

| 对象类型           | 派生类中能访问基类 protected 成员？ | 原因说明                                                  |
| ------------------ | ----------------------------------- | --------------------------------------------------------- |
| 自己 (`this`)      | ✅ 可以                              | 继承而来，属于派生类                                      |
| 其他派生类对象     | ✅ 可以                              | 同一类内部，protected 可访问                              |
| 基类对象 (`Base&`) | ❌ 不可以                            | 不管你是子类还是友元，都不能访问基类对象的 protected 成员 |

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
    // ✅ 合法：Pal 是 Base 的友元类，可以访问 Base 的 protected 成员
    int f(Base b) { 
        return b.prot_mem; // 合法访问 Base 对象中的 prot_mem
    }

    // ❌ 非法：虽然 Sneaky 是 Base 的派生类，但 j 是 Sneaky 的私有成员
    // Pal 不是 Sneaky 的友元类，因此不能访问 s.j
    // int f2(Sneaky s) { return s.j; };

    // ✅ 合法：Pal 是 Base 的友元类
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

### C++ 函数调用的解析过程

#### 静态类型 vs. 动态类型

- **静态类型**：变量声明时的类型，是编译时确定的。
- **动态类型**：对象实际的类型，是运行时才确定的（多态相关）。

函数调用时：

- **名字查找和重载决议都是基于静态类型完成的**，在编译期完成。
- **虚函数调用的实际调用版本**根据动态类型，在运行时绑定。

#### 函数调用的整体过程

假设有一条成员函数调用：

```cpp
expr.f(args);
```

解析过程大致如下：

##### 1. 确定静态类型

- 先确定 `expr` 的静态类型（变量声明时的类型）。
- 只根据静态类型去查找成员函数 `f`。

##### 2. 名字查找（Name Lookup）

- 在静态类型对应的类及其基类中查找名为 `f` 的成员函数。
- 查找时遵循作用域规则：先查找派生类，再向基类查找。
- 如果派生类中有同名成员，会隐藏基类中所有同名成员（不论签名）。

##### 3. 重载解析（Overload Resolution）

- 编译器根据调用参数 `args` 的类型，从查找到的候选函数中选择最佳匹配。
- 候选函数集合只包含名字查找到的成员（受隐藏规则限制）。
- 如果找不到合适的匹配，编译错误。

##### 4. 访问控制检查

- 检查选中的成员函数是否对当前调用点可访问（public/protected/private）。
- 不可访问则编译错误。

##### 5. 绑定调用

- **如果函数是非虚函数**，直接绑定静态类型对应的函数实现。
- **如果函数是虚函数**，运行时根据对象动态类型查找具体重写版本（动态绑定）。

#### 重要说明

- 名字查找和重载解析全部在编译期完成，**只用静态类型信息**，不依赖动态类型。
- 动态类型只影响虚函数的具体调用版本选择。
- 派生类中定义了同名函数后，基类中所有同名函数均被隐藏，必须用 `using` 显式导入。

#### 示例 1

```cpp
#include <iostream>
using namespace std;

class Base {
public:
    void f(int) { cout << "Base::f(int)" << endl; }
    void f(double) { cout << "Base::f(double)" << endl; }
    virtual void v() { cout << "Base::v()" << endl; }
};

class Derived : public Base {
public:
    void f(int) { cout << "Derived::f(int)" << endl; }
    void v() override { cout << "Derived::v()" << endl; }
};

int main() {
    Derived d;
    Base* pb = &d;

    d.f(10);    // 调用 Derived::f(int)
    // d.f(3.14); // 错误，Base::f(double) 被隐藏
    d.f(3.14);  // 如果添加 using Base::f; 在 Derived 内，调用 Base::f(double)

    pb->v();    // 运行时调用 Derived::v()，虚函数动态绑定

    return 0;
}
```

#### 示例 2

```cpp
#include <iostream>
using namespace std;

class Base {
public:
	virtual int fcn();  // 虚函数，基类版本，可被派生类覆盖
};

class D1 : public Base {
public:
	// 继承了 Base::fcn() 的定义（未覆盖）

	int fcn(int);       // 重载，不是覆盖。名字相同，但参数不同，隐藏 Base::fcn()
	virtual void f2();  // 新增虚函数
};

class D2 : public D1 {
public:
	int fcn(int);       // 重载 D1::fcn(int)，隐藏了 D1::fcn(int)
	int fcn() override; // 覆盖 Base::fcn()
	void f2() override; // 覆盖 D1::f2()
};

// 函数定义：
int Base::fcn() {
	cout << "Base::fcn()" << endl;
	return 0;
}
int D1::fcn(int) {
	cout << "D1::fcn(int)" << endl;
	return 1;
}
void D1::f2() {
	cout << "D1::f2()" << endl;
}
int D2::fcn(int) {
	cout << "D2::fcn(int)" << endl;
	return 2;
}
int D2::fcn() {
	cout << "D2::fcn()" << endl;
	return 3;
}
void D2::f2() {
	cout << "D2::f2()" << endl;
}

int main() {
	Base bobj;
	D1 d1obj;
	D2 d2obj;

	// d1obj.fcn();  // 错误：没有匹配的 fcn()，因为 D1::fcn(int) 隐藏了 Base::fcn()

	Base* bp1 = &bobj, * bp2 = &d1obj, * bp3 = &d2obj;

	// 静态类型 Base*，调用 virtual int fcn()
	// 虚函数动态绑定，根据动态类型：
	bp1->fcn();   // 调用 Base::fcn()
	bp2->fcn();   // 调用 Base::fcn()（D1 没有覆盖它）
	bp3->fcn();   // 调用 D2::fcn()，因为 D2 覆盖了 Base::fcn()

	D1* d1p = &d1obj;
	D2* d2p = &d2obj;

	// f2 是虚函数
	// 调用的函数版本根据对象的动态类型确定
	// bp2->f2();    // 错误：Base 中没有 f2，名字查找阶段就失败
	d1p->f2();    // 静态类型 D1*，调用 D1::f2()
	d2p->f2();    // 静态类型 D2*，调用 D2::f2()（重写了 D1::f2()）

	Base* p1 = &d2obj;
	D1* p2 = &d2obj;
	D2* p3 = &d2obj;
	// p1->fcn(2);  // 编译错误：Base 中没有 fcn(int)，名字查找失败
	p2->fcn(2);  // 静态类型 D1*，调用 D1::fcn(int)，非虚函数
	p3->fcn(2);  // 静态类型 D2*，调用 D2::fcn(int)，非虚函数

	return 0;
}
```

- 每个类中声明的新同名函数会**隐藏整个基类中同名但不同签名的函数集**（名字隐藏）

如果想恢复访问 `Base::fcn()`，就要加：

```cpp
class D1 : public Base {
public:
    using Base::fcn;     // 👈 明确把 Base::fcn() 引入到 D1 的作用域中
    int fcn(int);
    virtual void f2();
};
```

然后就可以在 `main` 里写：

```cpp
d1obj.fcn();     // 调用 Base::fcn()
d1obj.fcn(10);   // 调用 D1::fcn(int)
```

| 现象                      | 原因                                            |
| ------------------------- | ----------------------------------------------- |
| `d1obj.fcn()` 无法编译    | `D1::fcn(int)` 隐藏了 `Base::fcn()`             |
| 隐藏发生在 *名字查找阶段* | 编译器只看到 `D1` 中的 `fcn`，Base 的版本被跳过 |
| 想恢复访问隐藏的函数      | 使用 `using Base::fcn;` 引入基类成员            |

#### 小结

| 步骤                | 说明                               | 备注                                   |
| ------------------- | ---------------------------------- | -------------------------------------- |
| **1. 静态类型确定** | 确定调用对象的静态类型             | 例如`Derived d;`的静态类型是`Derived`  |
| **2. 名字查找**     | 在静态类型作用域中查找函数名       | 从派生类开始查，派生类同名隐藏基类同名 |
| **3. 重载解析**     | 参数类型匹配确定函数               | 只在查找到的候选中选最佳匹配           |
| **4. 访问权限检查** | 检查访问权限                       | private/protected 访问规则             |
| **5. 绑定调用**     | 静态函数直接调用，虚函数运行时绑定 | 多态的关键                             |