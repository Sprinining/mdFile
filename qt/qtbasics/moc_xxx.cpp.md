## moc_xxx.cpp

### 源文件

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

### Q_OBJECT 宏

#### Q_OBJECT 宏定义

```cpp
/* qmake ignore Q_OBJECT */
#define Q_OBJECT \
public: \
    QT_WARNING_PUSH \
    Q_OBJECT_NO_OVERRIDE_WARNING \
    static const QMetaObject staticMetaObject; \
    virtual const QMetaObject *metaObject() const; \
    virtual void *qt_metacast(const char *); \
    virtual int qt_metacall(QMetaObject::Call, int, void **); \
    QT_TR_FUNCTIONS \
private: \
    QT_OBJECT_GADGET_COMMON \
    QT_DEFINE_TAG_STRUCT(QPrivateSignal); \
    QT_WARNING_POP \
    QT_ANNOTATE_CLASS(qt_qobject, "")
```

这段代码是 Qt 的 `Q_OBJECT` 宏的展开形式之一（用于说明 Qt 元对象系统如何工作的内部机制）。该宏是 Qt 元对象系统的核心部分，通常用于 `QObject` 的子类，以启用信号和槽、属性系统、反射等特性。

在 Qt 编译过程中，`moc`（Meta-Object Compiler）会读取包含 `Q_OBJECT` 宏的头文件并生成对应的元对象代码（如元信息注册、信号槽机制等）。

#### 宏展开解释

- `QT_WARNING_PUSH`
  - 保存当前的编译器警告状态（比如 MSVC 的 `/W4`、GCC 的 `-Wall`）。
- `Q_OBJECT_NO_OVERRIDE_WARNING`
  - 临时禁用关于“虚函数未使用 override” 的警告

- `static const QMetaObject staticMetaObject;`

  -  定义静态元对象信息，用于描述类的元数据（类名、信号槽、属性等）。

- ` virtual const QMetaObject *metaObject() const;`

  - 返回当前对象的元对象指针，类似于反射的类型信息。

- ` virtual void *qt_metacast(const char *);`

  - `qt_metacast` 用于实现运行时类型转换，通常配合 `qobject_cast` 实现类型安全的指针转换。

- ` virtual int qt_metacall(QMetaObject::Call, int, void **);`

  - 这是 Qt 内部用于处理动态信号、槽调用、属性访问的核心函数，moc 会为它生成具体的逻辑。

- `QT_TR_FUNCTIONS`

  - 引入 Qt 的翻译函数，比如 `tr()`，用于国际化字符串翻译。

- `QT_OBJECT_GADGET_COMMON`
  - 包含一些必要的辅助函数或变量，支持 `Q_GADGET` 特性。
  
- `QT_DEFINE_TAG_STRUCT(QPrivateSignal);`
  - 定义一个标记结构 `QPrivateSignal`，用于防止用户手动调用 `emit`。

- `QT_WARNING_POP`
  - 恢复之前保存的警告状态（`QT_WARNING_PUSH`）。

- `QT_ANNOTATE_CLASS(qt_qobject, "")`
  - 为类做注解，通常用于工具链识别该类为 Qt 对象。


#### 总结

这个宏最终使得 Qt 的对象系统支持：

1. **反射机制（`metaObject()`、`qt_metacast()`）**
2. **信号与槽（`qt_metacall()`）**
3. **属性系统（`Q_PROPERTY`）**
4. **国际化支持（`tr()`）**
5. **moc 能够识别并生成辅助代码**

### singals 宏

```cpp
#ifdef signals
#  define signals public __attribute__((annotate("qt_signal")))
#endif
```

如果定义了 `signals` 宏，就把它定义为 `public` 加上 Clang/GCC 特有的注解 `__attribute__((annotate("qt_signal")))`，这样 Qt 的工具链和分析器可以识别出这是真正的“信号函数”，而不是普通的 `public` 成员函数。

### slots 宏

```cpp
#ifdef slots
#  define slots __attribute__((annotate("qt_slot")))
#endif
```

在支持注解的编译器中（如 Clang/GCC），通过 `__attribute__((annotate("qt_slot")))` 标记槽函数，使得工具链可以识别并处理这些函数是“槽”，支持代码分析、代码补全、UI 设计器自动连接等功能。

### 信号的实体代码

在 `moc_widget.cpp` 中能找到信号的实体代码：

```cpp
// SIGNAL 0
void Widget::nickNameChanged(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 0, nullptr, _t1);
}

// SIGNAL 1
void Widget::countChanged(int _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 1, nullptr, _t1);
}

// SIGNAL 2
void Widget::valueChanged(double _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 2, nullptr, _t1);
}
```

这些函数是 Qt 元对象系统为信号（`signals`）生成的 **实际实现代码**，在编译阶段由 MOC（Meta-Object Compiler）生成，作用是通过 Qt 的元对象系统通知信号的所有连接者。

#### 函数参数解释

```cpp
QMetaObject::activate<void>(this, &staticMetaObject, 0, nullptr, _t1);
```

| 参数                | 含义                                                         |
| ------------------- | ------------------------------------------------------------ |
| `this`              | 当前对象指针，用于找到对象内部的连接表                       |
| `&staticMetaObject` | 当前类的元对象信息（包含所有信号槽信息）                     |
| `0`                 | 信号在元对象中注册的编号（这个编号由 MOC 分配，比如 `nickNameChanged` 是第 0 个信号） |
| `nullptr`           | 通常用于动态参数数组（老版 Qt 可能用参数类型列表）           |
| `_t1`               | 实际的信号参数（这里是传入的 QString）                       |

#### 信号底层工作机制

用户视角：

```cpp
emit nickNameChanged("NewName");
```

展开后：

```cpp
Widget::nickNameChanged("NewName");
```

实际执行：

```cpp
QMetaObject::activate(this, &staticMetaObject, 0, nullptr, "NewName");
```

Qt 内部做的事：

- 查找信号 0 绑定的所有槽；
- 用参数 `"NewName"` 依次调用所有槽函数；
- 如果是跨线程连接，还会投递事件队列；
- 如果是阻塞连接，还会阻塞调用线程直到执行完。

### emit 宏

```cpp
# define Q_EMIT
#ifndef QT_NO_EMIT
# define emit
#endif
```

`emit` 是 Qt 中用于 **发送信号（signal）** 的一个关键字，其实它本质上是一个 **空宏**，不会在预处理阶段做任何实际替换，主要是为了 **语义清晰** 和 **增强代码可读性**。

### moc_widget.cpp

```cpp
/****************************************************************************
** Meta object code from reading C++ file 'widget.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.9.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

// 这是 moc 自动生成的 meta-object 代码，它将 Qt 对象系统的信息（signals、slots、properties）生成元信息，
// 供 Qt 的反射系统和事件系统使用。

#include "../../../../widget.h"
#include <QtCore/qmetatype.h>
#include <QtCore/qtmochelpers.h>
#include <memory>
#include <QtCore/qxptype_traits.h>

#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'widget.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.9.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")

namespace {
// 这个结构体作为模板特化标记，用于静态 metaobject 构建。
struct qt_meta_tag_ZN6WidgetE_t {};
} // unnamed namespace

// Qt 6 的新机制：使用模板构造 staticMetaObject 的元数据
// 包含字符串表、信号槽描述、属性、枚举等元信息。
template <> constexpr inline auto Widget::qt_create_metaobjectdata<qt_meta_tag_ZN6WidgetE_t>()
{
    namespace QMC = QtMocConstants;

    // 字符串表，对应方法名、属性名、参数名等，用于索引。
    QtMocHelpers::StringRefStorage qt_stringData {
        "Widget",
        "nickNameChanged",
        "",
        "strNewName",
        "countChanged",
        "nNewCount",
        "valueChanged",
        "dblNewValue",
        "setNickName",
        "setCount",
        "nickName",
        "count",
        "value"
    };

    // 方法描述，包括信号槽信息（参数类型、返回值、访问权限、位置索引等）
    QtMocHelpers::UintData qt_methods {
        // Signal 'nickNameChanged'
        QtMocHelpers::SignalData<void(const QString &)>(1, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 3 }, // 参数类型 QString，名字索引 3："strNewName"
        }}),
        // Signal 'countChanged'
        QtMocHelpers::SignalData<void(int)>(4, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 5 }, // int 类型
        }}),
        // Signal 'valueChanged'
        QtMocHelpers::SignalData<void(double)>(6, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Double, 7 },
        }}),
        // Slot 'setNickName'
        QtMocHelpers::SlotData<void(const QString &)>(8, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 3 },
        }}),
        // Slot 'setCount'
        QtMocHelpers::SlotData<void(int)>(9, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 5 },
        }}),
    };

    // 属性描述，每个属性包括：名称索引、类型、flags、是否有 setter、绑定的信号槽索引
    QtMocHelpers::UintData qt_properties {
        QtMocHelpers::PropertyData<QString>(10, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        QtMocHelpers::PropertyData<int>(11, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 1),
        QtMocHelpers::PropertyData<double>(12, QMetaType::Double, QMC::DefaultPropertyFlags | QMC::Writable, 2),
    };

    QtMocHelpers::UintData qt_enums {
    }; // 当前无枚举

    return QtMocHelpers::metaObjectData<Widget, qt_meta_tag_ZN6WidgetE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}

// staticMetaObject 的定义，连接基类的 metaObject 与构造出的元数据结构体
Q_CONSTINIT const QMetaObject Widget::staticMetaObject = { {
    QMetaObject::SuperData::link<QWidget::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN6WidgetE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN6WidgetE_t>.data,
    qt_static_metacall, // 调用实际成员函数的 dispatcher
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN6WidgetE_t>.metaTypes,
    nullptr
} };

// meta call dispatcher，执行 slot 调用、属性访问等
void Widget::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<Widget *>(_o);

    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->nickNameChanged((*reinterpret_cast<QString*>(_a[1]))); break;
        case 1: _t->countChanged((*reinterpret_cast<int*>(_a[1]))); break;
        case 2: _t->valueChanged((*reinterpret_cast<double*>(_a[1]))); break;
        case 3: _t->setNickName((*reinterpret_cast<QString*>(_a[1]))); break;
        case 4: _t->setCount((*reinterpret_cast<int*>(_a[1]))); break;
        default: ;
        }
    }

    // 查找信号索引（connect 时使用）
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (Widget::*)(const QString & )>(_a, &Widget::nickNameChanged, 0)) return;
        if (QtMocHelpers::indexOfMethod<void (Widget::*)(int )>(_a, &Widget::countChanged, 1)) return;
        if (QtMocHelpers::indexOfMethod<void (Widget::*)(double )>(_a, &Widget::valueChanged, 2)) return;
    }

    // 属性读取
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<QString*>(_v) = _t->nickName(); break;
        case 1: *reinterpret_cast<int*>(_v) = _t->count(); break;
        case 2: *reinterpret_cast<double*>(_v) = _t->m_value; break;
        default: break;
        }
    }

    // 属性写入
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setNickName(*reinterpret_cast<QString*>(_v)); break;
        case 1: _t->setCount(*reinterpret_cast<int*>(_v)); break;
        case 2:
            if (QtMocHelpers::setProperty(_t->m_value, *reinterpret_cast<double*>(_v)))
                Q_EMIT _t->valueChanged(_t->m_value); // emit 对应 signal
            break;
        default: break;
        }
    }
}

// 返回 metaObject 指针（支持动态 metaobject）
const QMetaObject *Widget::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

// meta cast，用于 dynamic_cast 替代机制（反射式类型识别）
void *Widget::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN6WidgetE_t>.strings))
        return static_cast<void*>(this);
    return QWidget::qt_metacast(_clname);
}

// meta call wrapper，分发到静态 dispatcher
int Widget::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QWidget::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;

    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 5)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 5;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 5)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 5;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 3;
    }
    return _id;
}

// 以下是各个信号的实现，实际是调用 QMetaObject::activate 触发信号连接的槽

// SIGNAL 0
void Widget::nickNameChanged(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 0, nullptr, _t1);
}

// SIGNAL 1
void Widget::countChanged(int _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 1, nullptr, _t1);
}

// SIGNAL 2
void Widget::valueChanged(double _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 2, nullptr, _t1);
}

QT_WARNING_POP

```

### 简易的 C++ 信号槽机制实现

```cpp
#include <iostream>
#include <vector>
#include <functional>
#include <algorithm>

// 简易信号类，支持一个参数，参数类型用模板
template<typename ArgType>
class Signal {
public:
    using SlotType = std::function<void(ArgType)>;

    // 连接槽函数，支持普通函数和成员函数包装成 std::function
    void connect(const SlotType& slot) {
        slots.push_back(slot);
    }

    // 断开槽函数，注意这里只能通过函数地址断开，简单示例
    void disconnect(const SlotType& slot) {
        auto it = std::remove_if(slots.begin(), slots.end(),
            [&](const SlotType& s) {
                // 简单比较函数地址，不完美，但示意用
                return s.target<void(ArgType)>() == slot.target<void(ArgType)>();
            });
        slots.erase(it, slots.end());
    }

    // 发射信号，调用所有槽
    void emit(ArgType arg) {
        for (auto& slot : slots) {
            slot(arg);
        }
    }

private:
    std::vector<SlotType> slots;
};

// 下面是测试代码

// 普通函数槽
void onValueChanged(int v) {
    std::cout << "Value changed to " << v << std::endl;
}

// 包含成员槽的类
class Receiver {
public:
    void memberSlot(int v) {
        std::cout << "Receiver got value " << v << std::endl;
    }
};

int main() {
    Signal<int> sig;

    // 连接普通函数
    sig.connect(onValueChanged);

    // 连接成员函数，需要用 std::bind 或 lambda 包装
    Receiver r;
    sig.connect([&r](int v){ r.memberSlot(v); });

    // 触发信号
    sig.emit(42);

    return 0;
}
```

