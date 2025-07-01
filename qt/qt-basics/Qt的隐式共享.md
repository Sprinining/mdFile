## Qt 的隐式共享

Qt 中很多数据类型（字符串 `QString`、字节数组 `QByteArray`、图片 `QImage`、容器类等）都涉及大量内存数据的复制。传统的“值拷贝”如果直接深拷贝，会导致性能开销非常大。

隐式共享技术结合了：

- **引用计数（Reference Counting）**
- **写时复制（Copy-On-Write, COW）**

来实现**高效的值语义**，即：

- 拷贝对象时只增加引用计数，不复制数据；
- 只有在修改数据时才复制底层数据，保证对象间互不影响。

### 核心概念

| 术语       | 说明                           |
| ---------- | ------------------------------ |
| 共享数据块 | 实际数据存储和引用计数的结构体 |
| 引用计数   | 记录有多少对象共享此数据块     |
| 写时复制   | 修改时复制数据，保持数据独立   |
| detach()   | 保证当前对象持有独立数据的操作 |

### 隐式共享的典型结构

#### 共享数据类

```cpp
class SharedData {
public:
    QAtomicInt ref;  // 原子引用计数，支持多线程
    // 数据成员...

    SharedData() : ref(1) {}
    SharedData(const SharedData& other) : ref(1) {
        // 复制数据成员
    }
};
```

- `QAtomicInt` 用于线程安全地管理引用计数。

- 构造时引用计数初始化为 1。

#### 使用共享数据的外部类（如 QString）

```cpp
class MyString {
private:
    SharedData* d;  // 指向共享数据块的指针

public:
    MyString(const char* str) {
        d = new SharedData();
        // 初始化数据
    }

    MyString(const MyString& other) {
        d = other.d;
        d->ref.ref();  // 引用计数加一
    }

    ~MyString() {
        if (!d->ref.deref())  // 引用计数减一，若为0释放内存
            delete d;
    }

    MyString& operator=(const MyString& other) {
        if (d != other.d) {
            if (!d->ref.deref())
                delete d;
            d = other.d;
            d->ref.ref();
        }
        return *this;
    }

    // 写时复制调用点
    void detach() {
        if (d->ref > 1) {   // 多个对象共享数据时，复制数据
            SharedData* newData = new SharedData(*d); // 复制构造
            d->ref.deref();
            d = newData;
        }
        // 引用计数此时必为1，表示独立拥有数据
    }

    // 修改成员前调用detach()
    void setChar(int index, char c) {
        detach();
        // 修改 d->data[index]
    }
};
```

### 工作流程详解

#### 拷贝构造/赋值

- 仅复制指针 `d`
- 调用 `d->ref.ref()` 增加引用计数
- 不复制数据本身

#### 修改数据前（写时复制）

- 调用 `detach()`
- 检查引用计数：若 >1，说明数据被多个对象共享，需要复制数据块
- 创建数据块副本，引用计数减一，当前对象指向新数据
- 若引用计数 == 1，直接修改，无需复制

#### 对象析构

- 调用 `d->ref.deref()`，引用计数减一
- 若引用计数为 0，释放共享数据块

### 为什么用 `QAtomicInt`

- 在多线程环境中，多个线程可能访问同一共享数据块
- 引用计数的递增和递减操作必须是原子操作
- `QAtomicInt` 保证了线程安全

### 隐式共享示意流程图

```css
创建 s1 (ref=1)
     |
拷贝 s2 = s1 (ref=2)
     |
s2 修改数据 -> 调用 detach()
     |          |
     |       复制数据，s2 拥有新数据(ref=1)
     |       s1 仍指向原数据(ref=1)
```

### Qt 内置隐式共享类举例

| 类名         | 用途       |
| ------------ | ---------- |
| `QString`    | 字符串     |
| `QByteArray` | 字节数组   |
| `QImage`     | 图像       |
| `QPixmap`    | 显示用图像 |
| `QVector`    | 向量       |
| `QList`      | 列表       |
| `QVariant`   | 变体类型   |

这些类都采用隐式共享设计，避免频繁深拷贝。

### 示例代码（简化版）

```cpp
#include <QAtomicInt>
#include <iostream>

class SharedData {
public:
    QAtomicInt ref;
    char* data;
    int size;

    SharedData(const char* str) {
        ref = 1;
        size = strlen(str);
        data = new char[size + 1];
        strcpy(data, str);
    }
    SharedData(const SharedData& other) {
        ref = 1;
        size = other.size;
        data = new char[size + 1];
        strcpy(data, other.data);
    }
    ~SharedData() {
        delete[] data;
    }
};

class MyString {
private:
    SharedData* d;
public:
    MyString(const char* str) {
        d = new SharedData(str);
    }
    MyString(const MyString& other) {
        d = other.d;
        d->ref.ref();
    }
    ~MyString() {
        if (!d->ref.deref())
            delete d;
    }
    MyString& operator=(const MyString& other) {
        if (d != other.d) {
            if (!d->ref.deref())
                delete d;
            d = other.d;
            d->ref.ref();
        }
        return *this;
    }
    void detach() {
        if (d->ref > 1) {
            SharedData* newData = new SharedData(*d);
            d->ref.deref();
            d = newData;
        }
    }
    void setChar(int index, char c) {
        detach();
        if (index >= 0 && index < d->size) {
            d->data[index] = c;
        }
    }
    void print() {
        std::cout << d->data << std::endl;
    }
};

int main() {
    MyString s1("hello");
    MyString s2 = s1;   // 共享数据
    s2.setChar(0, 'H'); // 写时复制
    s1.print();         // hello
    s2.print();         // Hello
}
```

### 信号槽参数的推荐写法

Qt 官方明确推荐：

> Signal arguments should be passed by value for safety.
>  Slot arguments can use `const &` to avoid unnecessary copies.

#### Qt 推荐写法

```cpp
// 信号：值传递
signals:
    void textChanged(QString text);

// 槽函数：const 引用传递
slots:
    void onTextChanged(const QString &text);
```

#### 信号为什么用值传递？（`QString`）

##### 信号参数必须独立存储，不能用引用

Qt 信号的实现依赖 **元对象系统（Meta-Object System）**，发出信号时会将参数打包成事件，传入事件队列中（跨线程是异步的）：

```cpp
emit textChanged(str);
```

- 如果参数是 `const QString&`，**信号只传引用，可能在事件处理前就失效**，导致悬空引用、崩溃。

- 所以 **必须值传递**，确保信号发出时参数独立存在，与外部变量无关。

##### 隐式共享让值传递变得“便宜”

Qt 的 `QString` 是一个**隐式共享类**：

- 拷贝对象时只是增加引用计数，**不会复制字符串内容**
- 修改时才复制数据（写时复制）

所以信号参数写成 `QString`，虽然是“拷贝”，但成本非常低 

#### 槽函数为什么用 `const QString&`？

槽函数是在信号触发时被调用的函数，作为信号的接收者。

##### 避免不必要的拷贝

- 槽函数只需要**读数据**，不需要修改
- 用 `const QString &` 就可以直接引用信号参数（事件队列中那份），**避免再次拷贝对象**

##### 不影响信号系统的安全性

- 信号已经做了“值传递”，槽拿到的是**安全独立的那一份数据**，用引用不会出错。
- 所以这时候引用使用是**安全 + 高效**的。

#### 图示理解

```cpp
QString str = "hello";

// emit textChanged(str);
         ↓（拷贝构造，仅增加引用计数）
QString param = str;    // param.ref = str.ref + 1

// Qt 内部发出信号，事件队列存 param
// 槽函数接收时：
void onTextChanged(const QString &text) {
    // 直接引用 param，不触发拷贝
}
```

#### 非隐式共享类型的建议

如果传递的是自定义类对象，遵循：

- 有合适的拷贝构造函数
- 或者注册为 `Q_DECLARE_METATYPE` + `qRegisterMetaType<T>()`
- 在信号中使用 **值传递**

**即使担心拷贝成本大，也不能用 `T&` 作为信号参数。** 因为 Qt 的元对象系统只支持值语义。

##### 小技巧：可以用 `QSharedPointer<T>` 值传递

如果传的是自定义大对象，可以用：

```cpp
void resultReady(QSharedPointer<HeavyData> data);
```

它本质上是一个智能指针，值传递也只是引用计数 +1，成本低、线程安全。

#### 信号槽参数类型推荐表

| 类型               | 信号参数写法        | 槽函数写法                 | 说明                             |
| ------------------ | ------------------- | -------------------------- | -------------------------------- |
| `QString`          | `QString`           | `const QString &`          | 隐式共享，值传递成本低           |
| `QByteArray`       | `QByteArray`        | `const QByteArray &`       | 同上                             |
| `QVector<int>`     | `QVector<int>`      | `const QVector<int> &`     | 同上                             |
| 自定义类（轻量）   | `MyType`            | `const MyType &`           | 有拷贝构造，按值传递安全         |
| 自定义类（重量）   | `QSharedPointer<T>` | `const QSharedPointer<T>&` | 减少深拷贝                       |
| 非共享容器、裸指针 | ❌ `T&` 或 `T*`      | ❌ 禁止                     | 生命周期不受控，不能作为信号参数 |