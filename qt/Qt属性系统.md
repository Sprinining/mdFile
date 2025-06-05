## Qt属性系统

Qt 的属性系统是其元对象系统（Meta-Object System）的一部分，允许开发者以统一方式定义、访问、修改对象属性，并支持特性如信号/槽、对象序列化（如 QML、Qt Designer 支持）、动态属性操作等。

### 属性系统概述

Qt 的属性系统基于宏 `Q_PROPERTY`，用于声明类中的属性，便于 Qt 元对象编译器（`moc`）生成元信息，从而实现如下功能：

- 通过字符串访问属性（`QObject::property/setProperty`）；
- 属性绑定（特别是在 QML 中）；
- UI 设计器、QDataStream 等自动读写；
- 与信号/槽系统联动（如属性更改通知）；
- 动态元对象系统支持 introspection（反射式访问）。

### Q_PROPERTY 宏的语法

```cpp
Q_PROPERTY(type name
           READ getter
           [WRITE setter]
           [RESET resetter]
           [NOTIFY notifySignal]
           [REVISION int]
           [DESIGNABLE bool]
           [SCRIPTABLE bool]
           [STORED bool]
           [USER bool]
           [CONSTANT]
           [FINAL])
```

参数说明：

| 参数       | 含义                                     |
| ---------- | ---------------------------------------- |
| `type`     | 属性类型（如 `int`、`QString` 等）       |
| `name`     | 属性名称（字符串形式用于访问）           |
| `READ`     | 读取属性的方法（必须）                   |
| `WRITE`    | 写入属性的方法（可选）                   |
| `RESET`    | 重置属性的方法（可选）                   |
| `NOTIFY`   | 属性改变时发出的信号（强烈推荐）         |
| `CONSTANT` | 表示属性只读、在构造后不变（可用于优化） |
| `FINAL`    | 表示此属性在派生类中不能被覆盖           |

### 示例代码

```cpp
class MyObject : public QObject {
    Q_OBJECT
    Q_PROPERTY(int age READ age WRITE setAge NOTIFY ageChanged)

public:
    int age() const { return m_age; }
    void setAge(int value) {
        if (m_age != value) {
            m_age = value;
            emit ageChanged();
        }
    }

signals:
    void ageChanged();

private:
    int m_age;
};
```

此类定义了一个整型属性 `age`，可以通过如下方式访问：

```cpp
MyObject obj;
obj.setProperty("age", 25);
qDebug() << obj.property("age").toInt();  // 输出 25
```

### 动态属性（不依赖 Q_PROPERTY）

还可以使用 `QObject::setProperty()` / `property()` 为任意 `QObject` 派生类设置运行时属性：

```cpp
obj.setProperty("nickname", "ChatGPT");
qDebug() << obj.property("nickname").toString();  // 输出 "ChatGPT"
```

这种属性不会被 `moc` 处理，但可以在运行时动态添加、访问、修改。

### 与 QML 绑定配合

Qt 的属性系统是 QML 引擎与 C++ 对象通信的核心机制。如果一个 C++ 对象暴露给 QML 并且使用 `Q_PROPERTY` 声明了属性，QML 中可以自动绑定该属性并响应 `NOTIFY` 信号变化。

### 使用 QMetaObject 反射访问

Qt 提供了 `QMetaObject` 和 `QMetaProperty` ：

```cpp
const QMetaObject *meta = obj.metaObject();
for (int i = 0; i < meta->propertyCount(); ++i) {
    QMetaProperty prop = meta->property(i);
    qDebug() << "Property:" << prop.name() << "Value:" << prop.read(&obj);
}
```

> “反射访问”（**Reflection**）是指**在运行时检查、访问和操作对象的结构和行为**的一种能力。它让程序可以在**不知道类型的前提下动态地获取对象信息**，比如对象有哪些属性、方法、类型等，甚至调用这些方法或读取属性值。
>
> 通常我们在编程时需要写死属性名或方法名：
>
> ```cpp
> obj.setAge(25);  // 编译时就决定调用 setAge()
> ```
>
> 而**反射**允许你在**运行时用字符串**表示属性名、方法名：
>
> ```cpp
> obj.setProperty("age", 25);                // 设置属性（反射）
> qDebug() << obj.property("age").toInt();   // 读取属性（反射）
> ```

### 普通属性示例

#### widget.h

```cpp
#ifndef WIDGET_H
#define WIDGET_H

#include <QWidget>

QT_BEGIN_NAMESPACE
namespace Ui {
class Widget;
}
QT_END_NAMESPACE

class Widget : public QWidget {
    Q_OBJECT

public:
    Widget(QWidget* parent = nullptr);
    ~Widget();

    //
    // Qt 属性声明（Q_PROPERTY）
    //

    // nickName 属性：
    // - 自定义 getter 和 setter
    // - 属性变化时需手动发出 nickNameChanged 信号
    Q_PROPERTY(QString nickName READ nickName WRITE setNickName NOTIFY nickNameChanged)

    // count 属性：
    // - 使用 MEMBER 绑定 m_count，同时自定义 getter/setter
    // - 变化时需手动发出 countChanged 信号
    Q_PROPERTY(int count MEMBER m_count READ count WRITE setCount NOTIFY countChanged)

    // 声明 value 属性：
    // - 使用 MEMBER 绑定成员变量 m_value，moc 会自动生成 getter 和 setter
    // - 自动生成的 setter 在 Qt 5.10 及以上版本会自动发出 valueChanged() 信号
    // - 因此调用 setProperty("value", val) 会自动触发信号，无需手动 emit
    // - 仍然可以通过 property("value") 访问该属性
    Q_PROPERTY(double value MEMBER m_value NOTIFY valueChanged)

    //
    // getter 函数
    //
    const QString& nickName() const; // 返回成员变量的 const 引用，避免拷贝
    int count() const;               // 返回成员变量的值

signals:
    void nickNameChanged(const QString& strNewName);
    void countChanged(int nNewCount);
    void valueChanged(double dblNewValue);

public slots:
    //
    // setter 函数（也可以作为槽函数用来绑定信号）
    //
    void setNickName(const QString& strNewName);
    void setCount(int nNewCount);
    // setValue 由 moc 自动生成，但不会自动发信号，需用户手动 emit valueChanged()

private:
    Ui::Widget* ui;
    QString m_nickName;
    int m_count;
    double m_value;
};

#endif // WIDGET_H
```

- 只有在写了 `MEMBER`，并且没有写 `READ` 或 `WRITE` 的时候，moc 才会自动生成缺失的读/写函数。
  - 如果写了 `READ` 或 `WRITE`，**就必须两者都写完，moc 不会补剩下的那一个**

- `Q_PROPERTY` 本身不关心 `m_nickName`；
  - 它只通过你指定的 `READ` / `WRITE` 函数来访问属性；
  - `m_nickName` 是否存在、命名如何，**完全是你在 getter/setter 函数中自己管理的**。
  - 如果写了 `MEMBER`，才建立自动关联
  - Qt 的属性系统只关心在 `Q_PROPERTY` 中指定的读写函数名（`READ` / `WRITE`），**并不关心在函数里实际访问了哪个成员变量，甚至是否访问了成员变量。**
- `setter` 会不会自动发相应的 `NOTIFY` 信号？
  - 旧版本 Qt 或某些文档说，`MEMBER` 自动 setter 仅做赋值，不发信号。
  - 但新版本 Qt 实现中（Qt5.10+），当属性带有 `NOTIFY` 信号时，自动 setter 也会发信号。

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);
}

Widget::~Widget() {
    delete ui;
}

const QString& Widget::nickName() const {
    return m_nickName;
}

int Widget::count() const {
    return m_count;
}

// 自定义 setter，赋值并发信号
void Widget::setNickName(const QString& strNewName) {
    if (strNewName == m_nickName) return; // 值无变化不发信号
    m_nickName = strNewName;
    emit nickNameChanged(strNewName);
}

void Widget::setCount(int nNewCount) {
    if (nNewCount == m_count) return; // 值无变化不发信号
    m_count = nNewCount;
    emit countChanged(nNewCount);
}
```

#### showchanges.h

```cpp
#ifndef SHOWCHANGES_H
#define SHOWCHANGES_H

#include <QObject>

class ShowChanges : public QObject {
    Q_OBJECT
public:
    explicit ShowChanges(QObject* parent = nullptr);

public slots:
    void recvValue(double v); // 用于接收 valueChanged 信号的槽函数
};

#endif // SHOWCHANGES_H
```

#### showchanges.cpp

```cpp
#include "showchanges.h"
#include <QDebug>

ShowChanges::ShowChanges(QObject* parent) : QObject{parent} {
}

void ShowChanges::recvValue(double v) {
    qDebug() << "recvValue: " << v; // 输出接收到的 value 值
}
```

#### main.cpp

```cpp
#include "showchanges.h"
#include "widget.h"

#include <QApplication>
#include <QDebug>

int main(int argc, char* argv[]) {
    QApplication a(argc, argv);
    Widget w;

    ShowChanges s;
    // 连接 Widget 的 valueChanged 信号和 ShowChanges 的槽
    QObject::connect(&w, &Widget::valueChanged, &s, &ShowChanges::recvValue);

    w.setNickName("Wid");     // 调用自定义 setter，发信号
    qDebug() << w.nickName(); // 输出 nickName: "Wid"

    w.setCount(7);         // 调用自定义 setter，发信号
    qDebug() << w.count(); // 输出 count: 7

    // 使用 QObject::setProperty 调整 value
    // 实际调用的是 moc 自动生成的 setter
    // 在 Qt 5.10 及以上版本，自动 setter 会自动发出 valueChanged 信号
    // 所以 ShowChanges::recvValue 会被调用，打印 "recvValue: 3.14"
    w.setProperty("value", 3.14);
    qDebug() << w.property("value").toDouble(); // 输出 3.14

    w.show();
    return a.exec();
}
```

### 动态属性示例

新建一个项目，只修改 main.cpp。

#### main.cpp

```cpp
#include "widget.h"
#include <QApplication>
#include <QDebug>

int main(int argc, char* argv[]) {
    QApplication a(argc, argv);
    Widget w;

    // 检查对象中是否已有名为 "myValue" 的属性（无论是 Q_PROPERTY 还是动态属性）
    // 如果没有，返回 QVariant::Invalid
    qDebug() << w.property("myValue").isValid(); // 输出 false（尚未设置）

    // 设置一个名为 "myValue" 的动态属性（未通过 Q_PROPERTY 声明）
    // 实际上在内部以 QVariant 形式存在，和成员变量无关
    w.setProperty("myValue", 3.14);

    // 读取刚设置的动态属性值，转换为 double
    qDebug() << w.property("myValue").toDouble(); // 输出 3.14

    // 同样设置另一个动态属性 "myName"
    w.setProperty("myName", "Wid");
    qDebug() << w.property("myName").toString(); // 输出 "Wid"

    // 查看当前对象上的所有动态属性名（即未通过 Q_PROPERTY 声明、setProperty 设置的）
    // 输出格式是 QStringList，例如：("myValue", "myName")
    qDebug() << w.dynamicPropertyNames();

    w.show();
    return a.exec();
}
```

调用 `w.setProperty("myValue", 2.3456)` 的行为，关键取决于 **该属性是否通过 `Q_PROPERTY` 宏声明过**

##### 情况 1：**`Q_PROPERTY` 中声明了 `myValue`**

```cpp
Q_PROPERTY(double myValue MEMBER m_myValue NOTIFY myValueChanged)
```

那么：

- Qt 的元对象系统（通过 moc）**注册了这个属性**；
- `w.setProperty("myValue", 2.3456)` 会：
  - 自动调用由 moc 生成的 `setMyValue(double)` 函数（如果使用了 `MEMBER`，该函数是自动生成的）；
  - 如果 `NOTIFY` 指定了信号，并且是 Qt 5.10+，**setter 内部会自动 emit myValueChanged()**；
  - 否则必须手动写 setter 并 emit。

##### 情况 2：**没有通过 `Q_PROPERTY` 声明 `myValue`**

此时：

- `w.setProperty("myValue", 2.3456)` 调用的是 **`QObject::setProperty()`** 的动态属性机制；
- Qt 会在内部维护一个 `QMap<QString, QVariant>` 存储这些动态属性；
- 它**不会触发任何信号**；
- 你可以用 `w.property("myValue")` 读回这个值；
- 这个属性与类成员变量 `m_myValue` 没有任何绑定关系。

#### .property 的返回值

`.property("属性名")` 返回的是 **一个 `QVariant` 对象**。

##### 函数定义

```cpp
QVariant QObject::property(const char *name) const;
```

这个函数是 `QObject` 的成员函数，作用是：

- **读取名为 `name` 的属性值**
- 如果属性存在（通过 `Q_PROPERTY` 声明，或使用 `setProperty` 设置过），返回其值
- 如果属性不存在，返回一个**无效的 `QVariant`**（即 `.isValid() == false`）

#### QVariant

`QVariant` 是 Qt 框架中的一个非常核心的类，用于**存储任意类型的数据**，是 Qt 实现通用数据传递和属性系统的基础类型。

它有点类似 `Object` + 类型转换；C++ 标准库中相似的是 `std::any`（C++17）或 `std::variant`（C++17）。

##### 简单理解

可以把 `QVariant` 想成 **类型安全的“万能容器”**，它能装下各种 Qt/基本类型，比如：

```cpp
int
double
bool
QString
QColor
QDateTime
QList<QVariant>
QMap<QString, QVariant>
...等等
```

##### QVariant 的基本使用

```cpp
QVariant v1 = 42;
QVariant v2 = 3.14;
QVariant v3 = "hello";
QVariant v4 = QColor(Qt::red);

// 提取原始类型：
int i = v1.toInt();
double d = v2.toDouble();
QString str = v3.toString();
QColor color = v4.value<QColor>();
```

### 类的附加信息

#### widget.h

```cpp
#ifndef WIDGET_H
#define WIDGET_H

#include <QWidget>

// Ui 命名空间：由 Qt Designer 生成的 UI 类定义在此
QT_BEGIN_NAMESPACE
namespace Ui {
class Widget;
}
QT_END_NAMESPACE

// Widget 类：继承自 QWidget，是一个 Qt 控件窗口类
class Widget : public QWidget {
    Q_OBJECT  // 必须宏，启用 Qt 的元对象系统（支持信号槽、反射、属性等）

public:
    Widget(QWidget* parent = nullptr);  // 构造函数，默认父对象为空
    ~Widget();                          // 析构函数

    // Q_CLASSINFO 用于给类添加自定义的元信息（键值对）
    // 这些信息可通过 QMetaObject 在运行时读取（如反射、插件等场景）
    Q_CLASSINFO("Version", "1.0.0")              // 自定义版本号信息
    Q_CLASSINFO("Author", "Sylvan")              // 自定义作者信息
    Q_CLASSINFO("Site", "https://n1ce2cu.com/")  // 自定义网站信息

private:
    Ui::Widget* ui;  // 指向 UI 界面的指针，由 Qt Designer 自动生成
};

#endif // WIDGET_H
```

#### main.cpp

```cpp
#include "widget.h"

#include <QApplication>
#include <QMetaClassInfo>

int main(int argc, char* argv[]) {
    QApplication a(argc, argv);
    Widget w;

    // 获取 Widget 对象的元对象（包含类的元信息，比如类名、属性、信号等）
    const QMetaObject* obj = w.metaObject();

    // 获取类中 Q_CLASSINFO 定义的信息数量
    int nInfoCount = obj->classInfoCount();

    // 遍历所有 classInfo 项（这些是通过 Q_CLASSINFO 宏定义的键值对）
    for (int i = 0; i < nInfoCount; i++) {
        QMetaClassInfo info = obj->classInfo(i);
        // 输出 info 的 name（键）和 value（值）
        qDebug() << info.name() << "\t" << info.value();
    }

    // 输出类名（通过 Q_OBJECT 自动生成的元信息）
    qDebug() << "Class Name: " << obj->className();

    // 输出对象名，默认是空字符串，除非 setObjectName 设置过
    qDebug() << "Object Name: " << w.objectName();

    // 判断当前对象是否继承自某个类（名称以字符串形式提供）
    qDebug() << w.inherits("QWidget");   // true，Widget 是 QWidget 子类
    qDebug() << w.inherits("nothing");   // false，不存在该类名

    w.show();  // 显示窗口
    return a.exec();  // 进入 Qt 主事件循环
}
```

#### QMetaObject

`QMetaObject` 是 Qt 元对象系统（Meta-Object System）的核心类之一，用来在运行时提供 **类型的元信息**。

`QMetaObject` 描述了一个 **QObject 派生类的类信息**，包括：

| 功能                 | 描述                                                        |
| -------------------- | ----------------------------------------------------------- |
| **类名**             | `className()` 返回类名字符串                                |
| **父类**             | `superClass()` 返回父类的 QMetaObject                       |
| **属性信息**         | `propertyCount()`、`property(i)` 获取类的 Q_PROPERTY 元数据 |
| **信号与槽**         | `methodCount()`、`method(i)` 遍历信号、槽、普通成员函数等   |
| **classInfo**        | `classInfoCount()`、`classInfo(i)` 访问 `Q_CLASSINFO` 数据  |
| **动态调用函数**     | `invokeMethod()` 支持反射式函数调用                         |
| **查找名称对应索引** | 如 `indexOfProperty("value")`                               |
| **读取对象属性值**   | 通过 `QMetaProperty::read(obj)` 获取属性值（结合对象指针）  |

#### QMetaClassInfo

`QMetaClassInfo` 是 Qt 提供的一个类，用于 **表示通过 `Q_CLASSINFO` 宏声明的类级元信息**。

| 函数                        | 说明                              |
| --------------------------- | --------------------------------- |
| `const char* name() const`  | 返回类信息的键名（如 `"Author"`） |
| `const char* value() const` | 返回类信息的值（如 `"Sylvan"`）   |

- `Q_CLASSINFO` 只能用于 **类定义内部**，并且类必须包含 `Q_OBJECT` 宏。

- `QMetaClassInfo` 是只读的，**不能在运行时添加/修改**。

- 和 `Q_PROPERTY` 不同，它不是属性，而是类级别信息。