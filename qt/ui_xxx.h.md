## ui_xxx.h

### QMetaObject 类

`QMetaObject` 是 Qt 元对象系统的核心类之一，提供了对 Qt 对象类型（通常是继承自 `QObject` 的类）的**元信息访问能力**，包括：

- 类名
- 父类信息
- 信号与槽
- 属性（`Q_PROPERTY`）
- 枚举、方法、构造函数等

这使得 Qt 支持反射功能，如运行时动态调用函数、获取属性信息、连接信号与槽等。

#### 基本概念

在 Qt 中，元对象系统是通过 `Q_OBJECT` 宏启用的。任何类只要继承 `QObject` 并声明 `Q_OBJECT` 宏，就会自动生成一个 `static QMetaObject` 成员（编译器会用 `moc` 工具生成）。

例如：

```cpp
class MyObject : public QObject {
    Q_OBJECT
public:
    MyObject(QObject *parent = nullptr);

signals:
    void mySignal();
    
public slots:
    void mySlot();
};
```

编译后，`MyObject` 会自动生成一个 `static const QMetaObject staticMetaObject` 和一个虚函数 `metaObject()` 来访问它。

#### 常用接口

```cpp
const QMetaObject *meta = obj->metaObject();
```

##### 类信息

```cpp
meta->className();        // 类名
meta->superClass();       // 父类的 QMetaObject*
```

##### 方法信息（信号/槽/普通方法）

```cpp
int methodCount = meta->methodCount();
for (int i = 0; i < methodCount; ++i) {
    QMetaMethod method = meta->method(i);
    qDebug() << method.methodSignature();  // 方法签名
}
```

可以根据签名获取某方法并调用：

```cpp
meta->invokeMethod(obj, "mySlot");
```

##### 属性信息

```cpp
int propertyCount = meta->propertyCount();
for (int i = 0; i < propertyCount; ++i) {
    QMetaProperty prop = meta->property(i);
    qDebug() << prop.name() << prop.read(obj);
}
```

##### 信号与槽连接（高级方式）

```cpp
QMetaMethod signal = meta->method(meta->indexOfSignal("mySignal()"));
QMetaMethod slot   = target->metaObject()->method(target->metaObject()->indexOfSlot("mySlot()"));
QObject::connect(obj, signal, target, slot);
```

#### 常用场景举例

1. 动态方法调用

```cpp
QMetaObject::invokeMethod(obj, "mySlot", Qt::DirectConnection);
```

2. 动态属性读写

```cpp
QVariant value = obj->property("name");    // 读取
obj->setProperty("name", QVariant("Qt"));  // 设置
```

3. 自定义事件派发（静态辅助函数）

```cpp
QMetaObject::invokeMethod(obj, "doSomething", Qt::QueuedConnection);
```

#### Qt `QMetaObject` 功能速查表

| 功能类别         | 方法 / 接口                                               | 示例 / 用法说明                                              |
| ---------------- | --------------------------------------------------------- | ------------------------------------------------------------ |
| **类信息**       | `className()`                                             | 获取类名，如 `"MyObject"`                                    |
|                  | `superClass()`                                            | 获取父类的 `QMetaObject*`                                    |
| **方法（函数）** | `methodCount()`                                           | 返回类中方法的总数（含信号、槽、普通方法）                   |
|                  | `method(int index)`                                       | 获取指定索引的 `QMetaMethod`                                 |
|                  | `indexOfMethod("foo()")`                                  | 获取方法索引（也可用 `indexOfSignal()` / `indexOfSlot()`）   |
|                  | `QMetaObject::invokeMethod(obj, "foo")`                   | 动态调用方法                                                 |
| **属性**         | `propertyCount()`                                         | 获取属性总数                                                 |
|                  | `property(int index)`                                     | 获取第 i 个 `QMetaProperty`                                  |
|                  | `QObject::property("name")`                               | 读取对象属性值                                               |
|                  | `QObject::setProperty("name", value)`                     | 设置对象属性值                                               |
| **信号与槽**     | `indexOfSignal("sig()")`                                  | 获取信号的索引                                               |
|                  | `indexOfSlot("slot()")`                                   | 获取槽函数的索引                                             |
|                  | `method(index)` -> `QMetaMethod`                          | 获取信号/槽方法元信息                                        |
|                  | `QObject::connect(obj, signalMethod, target, slotMethod)` | 使用 `QMetaMethod` 高级连接方式                              |
| **动态调用**     | `QMetaObject::invokeMethod()`                             | 支持 `DirectConnection`, `QueuedConnection`, 传参等          |
| **其他功能**     | `enumeratorCount()` / `enumerator(index)`                 | 访问 `Q_ENUM` 枚举信息                                       |
|                  | `constructorCount()` / `constructor(index)`               | 是通过 Q_INVOKABLE 声明的构造函数，获取构造函数信息（较少使用） |

### Q_INVOKABLE 宏

`Q_INVOKABLE` 是 Qt 提供的一个宏，用于标记一个成员函数，使其能通过 **`QMetaObject` 系统在运行时被动态调用**，也就是支持反射（类似 Java 的 `public` + `@Reflectable`）。它常与 `QMetaObject::invokeMethod()`、QML、Qt 的脚本系统一起使用。

**`Q_INVOKABLE` 的作用：**

> 将类中的普通成员函数注册到 Qt 的元对象系统中，使其可以被动态查找、调用，或被 QML / 脚本访问。

如果有一个 `public` 函数，但没有使用 `Q_INVOKABLE` 或将其声明为 `public slots:`，它不会被元对象系统识别，不能用 `invokeMethod()` 动态调用。

#### 使用示例

##### 基本用法

```cpp
class MyObject : public QObject {
    Q_OBJECT

public:
    MyObject(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void sayHello() {
        qDebug() << "Hello from Q_INVOKABLE function!";
    }
};
```

动态调用：

```cpp
MyObject obj;
QMetaObject::invokeMethod(&obj, "sayHello");
```

没有 `Q_INVOKABLE` 的话，这里会调用失败。

##### 与参数一起使用

```cpp
Q_INVOKABLE QString greet(const QString &name) {
    return "Hello, " + name;
}
```

调用（支持传参）：

```cpp
#include "widget.h"
#include <QApplication>
#include <QMetaObject>
#include <QVariant>

int main(int argc, char *argv[]) {
    QApplication a(argc, argv);
    Widget w;

    // 构造参数
    QString name = "ChatGPT";
    QString  returnValue;

    // 正确调用 greet(QString)
    bool success = QMetaObject::invokeMethod(
        &w,                      // 对象指针
        "greet",                // 方法名
        Q_RETURN_ARG(QString , returnValue),  // 返回值
        Q_ARG(QString, name)                 // 参数类型必须精确匹配
        );

    if (success) {
        qDebug() << "Return value:" << returnValue;
    } else {
        qDebug() << "invokeMethod failed!";
    }

    w.show();
    return a.exec();
}
```

#### 与 slots 的区别

| 特性               | `Q_INVOKABLE`            | `slots`                   |
| ------------------ | ------------------------ | ------------------------- |
| 可动态调用         | ✅ 是                     | ✅ 是                      |
| 可连接为槽函数     | ❌ 否（不能自动 connect） | ✅ 是                      |
| 可被 QML 调用      | ✅ 是                     | ✅ 是（仅 `public slots`） |
| 是否影响运行时性能 | 否，完全静态编译时注册   | 否                        |

- `Q_INVOKABLE` 更适合那些**不是槽，但希望能动态调用或暴露给 QML** 的函数。

- `slots` 是为**信号响应机制**设计的；`Q_INVOKABLE` 更接近于“公开反射”。

#### QMetaObject::invokeMethod() 

##### 函数原型（最常用的重载）

```cpp
bool QMetaObject::invokeMethod(
    QObject *obj,                        // 【1】目标对象，必须继承 QObject
    const char *member,                 // 【2】要调用的成员函数名称（函数名字符串，不含参数类型）
    Qt::ConnectionType type = Qt::AutoConnection,  // 【3】连接类型（控制是同步调用还是异步调用等）
    QGenericReturnArgument ret = QGenericReturnArgument(), // 【4】返回值参数（使用 Q_RETURN_ARG 封装）
    QGenericArgument val0 = QGenericArgument(),    // 【5~14】函数参数（最多支持 10 个参数）
    QGenericArgument val1 = QGenericArgument(),
    QGenericArgument val2 = QGenericArgument(),
    QGenericArgument val3 = QGenericArgument(),
    QGenericArgument val4 = QGenericArgument(),
    QGenericArgument val5 = QGenericArgument(),
    QGenericArgument val6 = QGenericArgument(),
    QGenericArgument val7 = QGenericArgument(),
    QGenericArgument val8 = QGenericArgument(),
    QGenericArgument val9 = QGenericArgument()
);
```

##### 常用简洁版本（Qt 5/6 常用）

```cpp
QMetaObject::invokeMethod(
    obj,
    "methodName",
    Q_RETURN_ARG(Type, returnValue),
    Q_ARG(ParamType, param)
);
```

### Q_ENUMS 宏

`Q_ENUMS` 是 Qt 早期（Qt 5 及以前）用于将枚举类型注册到元对象系统中的宏，**使得枚举值可以通过反射访问、打印、与 QML 或调试工具交互**。

不过，它已经被 **`Q_ENUM`（注意少了一个 S）取代**，并且后者功能更强、类型安全更高，是 Qt 5.5 起推荐的用法。

#### 使用方式（老版）

```cpp
class MyClass : public QObject {
    Q_OBJECT
    Q_ENUMS(Status)  // 注册枚举类型到元对象系统

public:
    enum Status {
        Idle,
        Running,
        Finished
    };
};
```

- `Q_ENUMS` 是宏展开为字符串注册，编译时不直接依赖枚举类型本身

  - `Q_ENUMS` 是 Qt 4.x 时代的旧写法，传入的是 **枚举名字的字符串**，例如 `"Status"`。

  - 它并不直接使用枚举类型，编译时不会检查枚举是否已经定义。

  - 所以可以先写 `Q_ENUMS(Status)`，然后再定义枚举。

  - 编译器不会报错，因为 `Q_ENUMS` 只是告诉元对象系统“稍后会有一个名字叫 Status 的枚举”。

使用 `QMetaEnum` 获取枚举信息：

```cpp
// 通过枚举名字 "Status" 获取该枚举在 MyClass 元对象中的索引（编号）
int index = MyClass::staticMetaObject.indexOfEnumerator("Status");

// 用枚举索引获取对应的 QMetaEnum 对象，QMetaEnum 提供枚举反射功能
QMetaEnum metaEnum = MyClass::staticMetaObject.enumerator(index);

// 使用 QMetaEnum 的 valueToKey 方法，将枚举值转换为对应的字符串名称
// 这里传入的是枚举值 MyClass::Running，返回字符串 "Running"
qDebug() << metaEnum.valueToKey(MyClass::Running);  // 输出： "Running"
```

#### 推荐：使用 `Q_ENUM`（Qt 5.5+）

```cpp
class MyClass : public QObject {
    Q_OBJECT

public:
    enum Status {
        Idle,
        Running,
        Finished
    };
    Q_ENUM(Status)  // 推荐写法（类型安全，更现代）
};
```

- `Q_ENUM` 是宏展开后会用到枚举类型符号，必须枚举类型已经定义

  - `Q_ENUM` 是基于 C++11 特性的写法，宏内部会直接使用枚举类型 `Status`。

  - 因此编译时，枚举类型必须已经可见（即定义在它之前）。

  - 否则会报错找不到类型。

| 项目                   | `Q_ENUMS` | ✅ `Q_ENUM`                          |
| ---------------------- | --------- | ----------------------------------- |
| 自动注册               | 否        | 是                                  |
| 支持 QMetaEnum 反射    | 是        | 是                                  |
| 类型安全（编译期检查） | 否        | ✅ 是                                |
| QML 自动识别           | 否        | ✅ 是（搭配 `Q_GADGET` / `QObject`） |
| Qt 6 是否推荐          | ❌ 否      | ✅ 是                                |

### Q_FLAGS 宏

`Q_FLAGS` 是 Qt 用来将 **枚举组合类型（flags）** 注册到元对象系统的宏。它可以把基于位掩码的枚举类型（通常用于表示多选状态的组合）注册进 Qt 元对象系统，支持反射、调试输出、QML 使用等。

#### 什么是 Flags

Flags 是一种通过位运算（按位或 `|`）组合多个枚举值的技术。常见用法：

```cpp
enum Option {
    OptionA = 0x01,
    OptionB = 0x02,
    OptionC = 0x04,
};
Q_DECLARE_FLAGS(Options, Option)  // 定义 Options 为 Option 的组合类型
```

这样就可以写：

```cpp
Options opts = OptionA | OptionC;
```

#### 示例

##### myclass.h

```cpp
#ifndef MYCLASS_H
#define MYCLASS_H

#include <QObject>

// MyClass 继承自 QObject，支持 Qt 元对象系统
class MyClass : public QObject {
    Q_OBJECT

public:
    // 定义枚举 Option，表示不同选项，使用位掩码方便组合
    enum Option {
        OptionA = 0x01,
        OptionB = 0x02,
        OptionC = 0x04,
    };

    // 定义 Flags 类型，允许多个 Option 位组合在一起
    Q_DECLARE_FLAGS(Options, Option)

    // 将 Flags 类型注册到元对象系统，支持反射和信号槽等特性
    Q_FLAGS(Options)

    explicit MyClass(QObject* parent = nullptr);

    // 设置选项，接收多个枚举值的组合
    void setOptions(Options opts);

    // 获取当前选项组合
    Options options() const;

private:
    Options m_options; // 保存当前选项组合
};

// 启用按位操作符（|、&、^ 等）支持 Options 类型
Q_DECLARE_OPERATORS_FOR_FLAGS(MyClass::Options)

#endif // MYCLASS_H
```

在头文件中这行代码定义了 `Options` 这个名字:

```cpp
Q_DECLARE_FLAGS(Options, Option)
```

这行宏展开后等价于：

```cpp
typedef QFlags<Option> Options;
```

`Options` 是 `QFlags<Option>` 类型，用来优雅地处理 `Option` 枚举的位组合，并能被 Qt 的元对象系统识别和操作。

##### myclass.cpp

```cpp
#include "myclass.h"

// 构造函数，初始化 m_options 为0（无选项）
MyClass::MyClass(QObject* parent) : QObject(parent), m_options(0) {
}

// 设置选项组合
void MyClass::setOptions(Options opts) {
    m_options = opts;
}

// 获取当前选项组合
MyClass::Options MyClass::options() const {
    return m_options;
}
```

##### main.cpp

```cpp
#include "myclass.h"
#include <QCoreApplication>
#include <QDebug>
#include <QMetaEnum>

int main(int argc, char* argv[]) {
    QCoreApplication app(argc, argv);

    MyClass obj;

    // 使用按位或组合多个选项，设置 OptionA 和 OptionC
    obj.setOptions(MyClass::OptionA | MyClass::OptionC);

    // 直接打印枚举组合，会显示字符串形式（依赖 Q_FLAGS 宏）
    qDebug() << "Options set:" << obj.options();

    // 通过元对象系统获取枚举信息
    int index = MyClass::staticMetaObject.indexOfEnumerator("Option");
    QMetaEnum metaEnum = MyClass::staticMetaObject.enumerator(index);

    // 把枚举值（包含组合位）转换成字符串，多个选项用 '|' 连接
    QString flagsString = metaEnum.valueToKeys(obj.options());
    qDebug() << "Flags as string via QMetaEnum:" << flagsString;

    return 0;
}
```

### 元对象系统综合示例

打开 widget.ui 文件，拖入一个标签和三个编辑栏。进入信号和槽的编辑模式，鼠标左键从一个编辑框拖到标签，松开后会弹出配置连接的对话框，选择信号 textEdited(QString) 和槽 setText(QString)。进入伙伴编辑模式，鼠标左键从标签拖到编辑框。进入 Tab 顺序编辑模式，依次点击控件的顺序。

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

    Q_PROPERTY(QString nickName READ nickName WRITE setNickName NOTIFY nickNameChanged)
    Q_PROPERTY(int count MEMBER m_count READ count WRITE setCount NOTIFY countChanged)
    Q_PROPERTY(double value MEMBER m_value NOTIFY valueChanged)

    const QString& nickName() const;
    int count() const;

signals:
    void nickNameChanged(const QString& strNewName);
    void countChanged(int nNewCount);
    void valueChanged(double dblNewValue);

public slots:
    void setNickName(const QString& strNewName);
    void setCount(int nNewCount);

private:
    Ui::Widget* ui;
    QString m_nickName;
    int m_count;
    double m_value;
};

#endif // WIDGET_H
```

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

void Widget::setNickName(const QString& strNewName) {
    if (strNewName == m_nickName) return;
    m_nickName = strNewName;
    emit nickNameChanged(strNewName);
}

void Widget::setCount(int nNewCount) {
    if (nNewCount == m_count) return;
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
    void recvNickName(const QString& strNewName);
    void recvCount(int nNewCount);
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
    qDebug() << "recvValue: " << v;
}

void ShowChanges::recvNickName(const QString& strNewName) {
    qDebug() << "recvNickName: " << strNewName;
}

void ShowChanges::recvCount(int nNewCount) {
    qDebug() << "recvCount: " << nNewCount;
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
    QObject::connect(&w, &Widget::valueChanged, &s, &ShowChanges::recvValue);
    QObject::connect(&w, &Widget::nickNameChanged, &s, &ShowChanges::recvNickName);
    QObject::connect(&w, &Widget::countChanged, &s, &ShowChanges::recvCount);

    w.setNickName("Wid");
    qDebug() << w.nickName();
    w.setCount(7);
    qDebug() << w.count();

    w.setProperty("value", 3.14);
    qDebug() << w.property("value").toDouble();

    w.show();
    return a.exec();
}
```

#### ui_widget.h

```cpp
/********************************************************************************
** Form generated from reading UI file 'widget.ui'
**
** Created by: Qt User Interface Compiler version 6.9.0
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_WIDGET_H
#define UI_WIDGET_H

// 包含必要的 Qt 模块头文件，用于界面元素
#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

// 自动生成的 UI 类，用于描述界面结构和初始化控件
class Ui_Widget {
public:
    // 控件声明
    QWidget* verticalLayoutWidget;
    QVBoxLayout* verticalLayout;
    QLineEdit* lineEdit;
    QLabel* label;
    QLineEdit* lineEdit_2;
    QLineEdit* lineEdit_3;

    // 设置 UI 元素（由 Qt 自动生成）
    void setupUi(QWidget* Widget) {
        // 设置窗口对象名和大小
        if (Widget->objectName().isEmpty())
            Widget->setObjectName("Widget");
        Widget->resize(479, 290);

        // 创建一个布局容器部件（内部 QWidget）
        verticalLayoutWidget = new QWidget(Widget);
        verticalLayoutWidget->setObjectName("verticalLayoutWidget");
        verticalLayoutWidget->setGeometry(QRect(110, 20, 231, 181)); // 设置位置和大小

        // 创建垂直布局器，挂在到 verticalLayoutWidget 上
        verticalLayout = new QVBoxLayout(verticalLayoutWidget);
        verticalLayout->setObjectName("verticalLayout");
        verticalLayout->setContentsMargins(0, 0, 0, 0); // 去除边距

        // 创建第一个文本框
        lineEdit = new QLineEdit(verticalLayoutWidget);
        lineEdit->setObjectName("lineEdit");
        verticalLayout->addWidget(lineEdit); // 加入布局

        // 创建标签
        label = new QLabel(verticalLayoutWidget);
        label->setObjectName("label");
        verticalLayout->addWidget(label); // 加入布局

        // 第二个文本框
        lineEdit_2 = new QLineEdit(verticalLayoutWidget);
        lineEdit_2->setObjectName("lineEdit_2");
        verticalLayout->addWidget(lineEdit_2);

        // 第三个文本框
        lineEdit_3 = new QLineEdit(verticalLayoutWidget);
        lineEdit_3->setObjectName("lineEdit_3");
        verticalLayout->addWidget(lineEdit_3);

#if QT_CONFIG(shortcut)
        // 设置 label 的快捷键对应控件（此处是 lineEdit）
        label->setBuddy(lineEdit);
#endif // QT_CONFIG(shortcut)

        // 设置 Tab 键的切换顺序
        QWidget::setTabOrder(lineEdit, lineEdit_2);
        QWidget::setTabOrder(lineEdit_2, lineEdit_3);

        // 设置翻译文本（界面文字）
        retranslateUi(Widget);

        // 设置当 lineEdit 编辑文本时，将文本设置到 label 上
        QObject::connect(lineEdit, &QLineEdit::textEdited, label, &QLabel::setText);

        // 自动连接 Qt Designer 中设置的信号与槽
        QMetaObject::connectSlotsByName(Widget);
    } // setupUi

    // 设置界面文本内容（可用于多语言翻译）
    void retranslateUi(QWidget* Widget) {
        Widget->setWindowTitle(QCoreApplication::translate("Widget", "Widget", nullptr));
        label->setText(QCoreApplication::translate("Widget", "TextLabel", nullptr));
    } // retranslateUi
};

// Ui 命名空间中定义了一个 Widget 类，继承自动生成的 Ui_Widget
// 这样我们可以在主程序中使用 Ui::Widget 来访问所有 UI 元素
namespace Ui {
class Widget : public Ui_Widget {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_WIDGET_H
```

 `ui_widget.h` 是 Qt **自动生成的文件**，由 **`uic`（User Interface Compiler）** 工具根据 Qt Designer 设计的 `.ui` 文件生成。

这个文件中定义了一个 `Ui::Widget` 类，包含所有在 Designer 里拖拽的控件，以及 `setupUi()` 函数。

`QT_CONFIG(shortcut)` 是 Qt 的配置宏，判断当前构建是否启用了 **快捷键（shortcut）功能模块**。

- 如果启用了（大多数桌面 Qt 默认开启），这段代码会编译。
- 如果未启用（如一些嵌入式 Qt 精简配置中），这段代码被忽略。

#### 小结

| 文件名        | 说明                                          |
| ------------- | --------------------------------------------- |
| `widget.ui`   | 在 Qt Designer 中创建的界面文件               |
| `ui_widget.h` | Qt 自动生成的头文件，包含界面控件和初始化函数 |
| `Widget` 类   | 手写的逻辑类，通过 `setupUi()` 使用界面控件   |