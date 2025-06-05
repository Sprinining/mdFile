## Qt 按钮类控件

### QAbstractButton

`QAbstractButton` 是 Qt 中所有按钮类的基类，提供了按钮的通用接口和功能。它本身是一个抽象类，不能直接实例化，而是被具体的按钮类（如 `QPushButton`、`QRadioButton`、`QCheckBox`、`QCommandLinkButton` 等）继承，实现具体的按钮表现和行为。

#### qabstractbutton.h 源码

```cpp
// Copyright (C) 2016 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only

#ifndef QABSTRACTBUTTON_H
#define QABSTRACTBUTTON_H

#include <QtWidgets/qtwidgetsglobal.h>
#include <QtGui/qicon.h>
#if QT_CONFIG(shortcut)
#  include <QtGui/qkeysequence.h>
#endif
#include <QtWidgets/qwidget.h>

QT_REQUIRE_CONFIG(abstractbutton); // 编译条件检查，确保启用了 abstractbutton 模块

QT_BEGIN_NAMESPACE

// 前向声明，减少头文件依赖
class QButtonGroup;
class QAbstractButtonPrivate;

// QAbstractButton 是所有按钮类（如 QPushButton, QRadioButton, QCheckBox）的基类
class Q_WIDGETS_EXPORT QAbstractButton : public QWidget
{
    Q_OBJECT

    // ====== Qt 属性系统 ======
    Q_PROPERTY(QString text READ text WRITE setText)                    // 按钮文本
    Q_PROPERTY(QIcon icon READ icon WRITE setIcon)                      // 图标
    Q_PROPERTY(QSize iconSize READ iconSize WRITE setIconSize)         // 图标尺寸
#ifndef QT_NO_SHORTCUT
    Q_PROPERTY(QKeySequence shortcut READ shortcut WRITE setShortcut)  // 快捷键
#endif
    Q_PROPERTY(bool checkable READ isCheckable WRITE setCheckable)     // 是否可切换状态（复选框/单选）
    Q_PROPERTY(bool checked READ isChecked WRITE setChecked NOTIFY toggled USER true) // 当前是否被选中
    Q_PROPERTY(bool autoRepeat READ autoRepeat WRITE setAutoRepeat)    // 是否自动重复点击（长按）
    Q_PROPERTY(bool autoExclusive READ autoExclusive WRITE setAutoExclusive) // 是否互斥（单选按钮组）
    Q_PROPERTY(int autoRepeatDelay READ autoRepeatDelay WRITE setAutoRepeatDelay)     // 自动重复延迟
    Q_PROPERTY(int autoRepeatInterval READ autoRepeatInterval WRITE setAutoRepeatInterval) // 自动重复间隔
    Q_PROPERTY(bool down READ isDown WRITE setDown DESIGNABLE false)   // 是否处于“按下”状态（仅视觉表现）

public:
    explicit QAbstractButton(QWidget *parent = nullptr); // 构造函数
    ~QAbstractButton();                                  // 析构函数

    // ========== 文本与图标 ==========
    void setText(const QString &text);    // 设置按钮文字
    QString text() const;                 // 获取按钮文字

    void setIcon(const QIcon &icon);     // 设置图标
    QIcon icon() const;                  // 获取图标

    QSize iconSize() const;              // 获取图标尺寸

#ifndef QT_NO_SHORTCUT
    void setShortcut(const QKeySequence &key);  // 设置快捷键（如 Ctrl+S）
    QKeySequence shortcut() const;              // 获取快捷键
#endif

    // ========== 勾选状态 ==========
    void setCheckable(bool);            // 设置按钮是否可切换状态
    bool isCheckable() const;           // 获取是否可切换状态

    bool isChecked() const;             // 获取是否当前为选中状态

    void setDown(bool);                 // 设置是否“按下”
    bool isDown() const;                // 获取是否“按下”

    // ========== 自动重复点击 ==========
    void setAutoRepeat(bool);           // 设置长按是否重复触发 clicked
    bool autoRepeat() const;

    void setAutoRepeatDelay(int);       // 设置第一次重复点击前延迟（毫秒）
    int autoRepeatDelay() const;

    void setAutoRepeatInterval(int);    // 设置每次重复点击之间的间隔（毫秒）
    int autoRepeatInterval() const;

    // ========== 自动互斥 ==========
    void setAutoExclusive(bool);        // 设置是否互斥（比如单选按钮只能选一个）
    bool autoExclusive() const;

#if QT_CONFIG(buttongroup)
    QButtonGroup *group() const;        // 获取所在按钮组
#endif

public Q_SLOTS:
    // 可被信号或外部调用的接口
    void setIconSize(const QSize &size);  // 设置图标尺寸
    void animateClick();                  // 模拟点击（带动画）
    void click();                         // 模拟点击（立即）
    void toggle();                        // 切换选中状态（checked ↔ unchecked）
    void setChecked(bool);               // 设置是否选中

Q_SIGNALS:
    // ========== 信号 ==========
    void pressed();                          // 按下
    void released();                         // 释放
    void clicked(bool checked = false);      // 点击（若是 checkable，包含是否选中）
    void toggled(bool checked);              // 勾选状态变化

protected:
    // ========== 事件相关 ==========
    void paintEvent(QPaintEvent *e) override = 0; // 纯虚函数，子类必须实现绘制逻辑
    virtual bool hitButton(const QPoint &pos) const;  // 判断是否命中按钮（鼠标位置）
    virtual void checkStateSet();              // 手动设置勾选状态
    virtual void nextCheckState();             // 设置下一个勾选状态（多选状态切换）

    bool event(QEvent *e) override;
    void keyPressEvent(QKeyEvent *e) override;
    void keyReleaseEvent(QKeyEvent *e) override;
    void mousePressEvent(QMouseEvent *e) override;
    void mouseReleaseEvent(QMouseEvent *e) override;
    void mouseMoveEvent(QMouseEvent *e) override;
    void focusInEvent(QFocusEvent *e) override;
    void focusOutEvent(QFocusEvent *e) override;
    void changeEvent(QEvent *e) override;
    void timerEvent(QTimerEvent *e) override;

protected:
    // protected 构造函数，供子类使用
    QAbstractButton(QAbstractButtonPrivate &dd, QWidget* parent = nullptr);

private:
    Q_DECLARE_PRIVATE(QAbstractButton)  // 使用 Qt 的 d-ptr（私有数据指针）机制
    Q_DISABLE_COPY(QAbstractButton)     // 禁止拷贝构造与赋值操作
    friend class QButtonGroup;          // QButtonGroup 可以访问其私有成员
};

QT_END_NAMESPACE

#endif // QABSTRACTBUTTON_H
```

#### 常用接口表

| 类别     | 原型                                         | 功能说明                                |
| -------- | -------------------------------------------- | --------------------------------------- |
| 构造     | `QAbstractButton(QWidget *parent = nullptr)` | 构造一个按钮（通常由子类调用）          |
| 文本     | `void setText(const QString &text)`          | 设置按钮的显示文本                      |
|          | `QString text() const`                       | 获取按钮的显示文本                      |
| 图标     | `void setIcon(const QIcon &icon)`            | 设置按钮图标                            |
|          | `QIcon icon() const`                         | 获取按钮图标                            |
|          | `void setIconSize(const QSize &size)`        | 设置图标大小                            |
|          | `QSize iconSize() const`                     | 获取图标大小                            |
| 勾选状态 | `void setCheckable(bool checkable)`          | 设置按钮是否支持切换（选中 / 未选中）   |
|          | `bool isCheckable() const`                   | 判断按钮是否支持切换                    |
|          | `void setChecked(bool checked)`              | 设置当前是否被选中                      |
|          | `bool isChecked() const`                     | 判断是否被选中                          |
|          | `void toggle()`                              | 切换选中状态（选中 ↔ 未选中）           |
| 点击状态 | `void click()`                               | 模拟点击按钮（会立即触发 clicked 信号） |
|          | `void animateClick(int msecs = 100)`         | 模拟点击动画                            |
|          | `void setDown(bool down)`                    | 设置按钮是否处于“按下”状态              |
|          | `bool isDown() const`                        | 判断是否处于“按下”状态                  |
| 排他性   | `void setAutoExclusive(bool)`                | 设置是否自动互斥（常用于单选按钮）      |
|          | `bool autoExclusive() const`                 | 判断是否设置了自动互斥                  |
| 快捷键   | `void setShortcut(const QKeySequence &key)`  | 设置按钮的快捷键                        |
|          | `QKeySequence shortcut() const`              | 获取当前按钮的快捷键                    |
| 工具提示 | `void setToolTip(const QString &tip)`        | 设置鼠标悬浮提示                        |
| 信号     | `void clicked(bool checked = false)`         | 被点击时发出（可选参数表示是否勾选）    |
|          | `void pressed()`                             | 被按下时发出                            |
|          | `void released()`                            | 被释放时发出                            |
|          | `void toggled(bool checked)`                 | 勾选状态切换时发出                      |

### QButtonGroup

`QButtonGroup` 是 Qt 中用于将多个按钮（通常是单选按钮 `QRadioButton` 或复选按钮 `QCheckBox`）组织到一个逻辑组中的类。它不负责按钮的显示，而是管理按钮的状态和信号，方便处理多个按钮之间的互斥或批量操作。

#### qbuttongroup.h 源码

```cpp
// Copyright (C) 2020 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only

#ifndef QBUTTONGROUP_H
#define QBUTTONGROUP_H

#include <QtWidgets/qtwidgetsglobal.h>
#include <QtCore/qobject.h>

QT_REQUIRE_CONFIG(buttongroup); // 编译条件：需要启用 buttongroup 模块

QT_BEGIN_NAMESPACE

// 前向声明：只声明类名，避免包含不必要的头文件
class QAbstractButton;
class QAbstractButtonPrivate;
class QButtonGroupPrivate;

// QButtonGroup 是 QObject 的子类，用于逻辑上组织一组 QAbstractButton（例如 QRadioButton）
// 它自身不是一个可视控件，仅起到管理作用。
class Q_WIDGETS_EXPORT QButtonGroup : public QObject
{
    Q_OBJECT

    // 属性系统：exclusive 表示是否互斥（默认 true），常用于单选按钮组
    Q_PROPERTY(bool exclusive READ exclusive WRITE setExclusive)

public:
    explicit QButtonGroup(QObject *parent = nullptr); // 构造函数，指定父对象
    ~QButtonGroup();                                  // 析构函数

    // 设置/获取是否互斥（同一时刻只有一个按钮可以被选中）
    void setExclusive(bool);
    bool exclusive() const;

    // 向按钮组中添加按钮，可指定按钮 ID（默认 -1 表示未指定）
    void addButton(QAbstractButton *, int id = -1);

    // 从按钮组中移除按钮
    void removeButton(QAbstractButton *);

    // 获取该组内的所有按钮
    QList<QAbstractButton*> buttons() const;

    // 获取当前被选中的按钮（如果有）
    QAbstractButton * checkedButton() const;
    // 注意：没有 setCheckedButton 接口，是有意设计（通过按钮状态变化触发）

    // 根据 ID 获取按钮
    QAbstractButton *button(int id) const;

    // 为某个按钮设置 ID（可用于区分多个按钮）
    void setId(QAbstractButton *button, int id);

    // 获取某个按钮的 ID
    int id(QAbstractButton *button) const;

    // 获取当前被选中按钮的 ID（若无则为 -1）
    int checkedId() const;

Q_SIGNALS:
    // ========== 信号 ==========
    void buttonClicked(QAbstractButton *);             // 某个按钮被点击
    void buttonPressed(QAbstractButton *);             // 某个按钮被按下
    void buttonReleased(QAbstractButton *);            // 某个按钮被释放
    void buttonToggled(QAbstractButton *, bool);       // 某个按钮状态发生切换

    void idClicked(int);         // 某个 ID 的按钮被点击
    void idPressed(int);         // 某个 ID 的按钮被按下
    void idReleased(int);        // 某个 ID 的按钮被释放
    void idToggled(int, bool);   // 某个 ID 的按钮状态切换

private:
    Q_DISABLE_COPY(QButtonGroup)         // 禁用拷贝构造与赋值（防止意外复制）
    Q_DECLARE_PRIVATE(QButtonGroup)      // 声明 D-Pointer，用于实现私有成员封装
    friend class QAbstractButton;        // QAbstractButton 可访问 QButtonGroup 私有成员
    friend class QAbstractButtonPrivate;
};

QT_END_NAMESPACE

#endif // QBUTTONGROUP_H
```

#### 常用接口表

| 类别         | 原型                                                        | 功能说明                                                     |
| ------------ | ----------------------------------------------------------- | ------------------------------------------------------------ |
| **构造函数** | `explicit QButtonGroup(QObject *parent = nullptr)`          | 创建一个按钮组，`parent` 为其父对象（通常为 QWidget 或 QObject）。 |
| **析构函数** | `~QButtonGroup()`                                           | 析构函数，销毁按钮组并释放相关资源。                         |
| **属性设置** | `void setExclusive(bool exclusive)`                         | 设置按钮组是否为互斥模式（即同一时间只能选中一个按钮）。     |
| **属性获取** | `bool exclusive() const`                                    | 获取按钮组当前是否为互斥模式。                               |
| **按钮管理** | `void addButton(QAbstractButton *button, int id = -1)`      | 向按钮组添加一个按钮，`id` 是可选的标识符，默认为 -1。       |
|              | `void removeButton(QAbstractButton *button)`                | 从按钮组中移除一个按钮。                                     |
|              | `QList<QAbstractButton*> buttons() const`                   | 返回按钮组中所有按钮的列表。                                 |
| **选中状态** | `QAbstractButton* checkedButton() const`                    | 获取当前被选中的按钮指针（如果有）。                         |
|              | `int checkedId() const`                                     | 获取当前被选中按钮的 ID（若无选中则返回 -1）。               |
| **ID 管理**  | `void setId(QAbstractButton *button, int id)`               | 设置按钮对应的 ID。                                          |
|              | `int id(QAbstractButton *button) const`                     | 获取指定按钮的 ID。                                          |
|              | `QAbstractButton* button(int id) const`                     | 根据 ID 获取对应按钮指针。                                   |
| **信号**     | `void buttonClicked(QAbstractButton *button)`               | 某个按钮被点击时发出，传递该按钮指针。                       |
|              | `void buttonPressed(QAbstractButton *button)`               | 某个按钮被按下时发出。                                       |
|              | `void buttonReleased(QAbstractButton *button)`              | 某个按钮被释放时发出。                                       |
|              | `void buttonToggled(QAbstractButton *button, bool checked)` | 某个按钮状态切换时发出。                                     |
|              | `void idClicked(int id)`                                    | 某个按钮被点击时发出，传递按钮 ID。                          |
|              | `void idPressed(int id)`                                    | 某个按钮被按下时发出。                                       |
|              | `void idReleased(int id)`                                   | 某个按钮被释放时发出。                                       |
|              | `void idToggled(int id, bool checked)`                      | 某个按钮状态切换时发出，带按钮 ID 与状态。                   |

### QPushButton

`QPushButton` 是 Qt 中最基础的按钮控件，用于执行用户点击的操作。它可以显示文本和图标，支持快捷键和切换状态（可设为可按下或释放），适合各种界面中触发命令或事件的按钮需求。

#### 特有接口表

| 类别         | 原型                                                         | 功能说明                                               |
| ------------ | ------------------------------------------------------------ | ------------------------------------------------------ |
| **构造函数** | `explicit QPushButton(QWidget *parent = nullptr)`            | 创建一个空文本按钮，`parent` 为父组件。                |
|              | `explicit QPushButton(const QString &text, QWidget *parent = nullptr)` | 创建一个带文本的按钮。                                 |
|              | `QPushButton(const QIcon &icon, const QString &text, QWidget *parent = nullptr)` | 创建一个带图标和文本的按钮。                           |
| **功能设置** | `void setDefault(bool)`                                      | 设置此按钮是否为窗口的默认按钮（按下回车时自动触发）。 |
|              | `bool isDefault() const`                                     | 检查此按钮是否是默认按钮。                             |
|              | `void setAutoDefault(bool)`                                  | 设置是否自动成为默认按钮（在拥有焦点时）。             |
|              | `bool autoDefault() const`                                   | 获取当前是否自动成为默认按钮。                         |
| **信号**     | *（无 QPushButton 特有信号，全部继承自 QAbstractButton）*    | —                                                      |

#### 示例

##### widget.h

```cpp
#ifndef WIDGET_H
#define WIDGET_H

#include <QPushButton> // 加载QPushButton类
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

private slots:
    void onButtonClicked();                   // 所有按钮共用槽，区分发送者
    void onToggleButtonClicked(bool checked); // 用于演示切换按钮
    void onMenuActionTriggered();             // 通过 sender() 获取触发信号的 QAction 指针，然后弹出一个消息框，显示用户选择的菜单项文本。

private:
    Ui::Widget* ui;

    // 演示多种按钮类型和功能
    QPushButton* btnNormal;   // 普通按钮
    QPushButton* btnDisabled; // 禁用状态按钮
    QPushButton* btnToggle;   // 可切换按钮（按下/弹起）
    QPushButton* btnIcon;     // 带图标按钮
    QPushButton* btnShortcut; // 带快捷键按钮
    QPushButton* btnWithMenu; // 带菜单的按钮
    QMenu* menu;              // 按钮菜单
};

#endif // WIDGET_H
```

##### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"

#include <QIcon>
#include <QMenu>
#include <QMessageBox>

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 1. 普通按钮
    btnNormal = new QPushButton("普通按钮", this);
    btnNormal->setGeometry(50, 50, 120, 40);
    connect(btnNormal, &QPushButton::clicked, this, &Widget::onButtonClicked);

    // 2. 禁用按钮
    btnDisabled = new QPushButton("禁用按钮", this);
    btnDisabled->setGeometry(50, 110, 120, 40);
    btnDisabled->setEnabled(false); // 设置按钮为不可用

    // 3. 切换按钮（可选中状态）
    btnToggle = new QPushButton("切换按钮", this);
    btnToggle->setGeometry(50, 170, 120, 40);
    btnToggle->setCheckable(true); // 允许切换状态
    connect(btnToggle, &QPushButton::toggled, this, &Widget::onToggleButtonClicked);

    // 4. 带图标按钮
    btnIcon = new QPushButton(QIcon(":/icons/sample.jpg"), "带图标", this);
    btnIcon->setGeometry(50, 230, 120, 40);
    btnIcon->setIconSize(QSize(24, 24));
    connect(btnIcon, &QPushButton::clicked, this, &Widget::onButtonClicked);

    // 5. 带快捷键按钮（Alt + S）
    btnShortcut = new QPushButton("快捷键按钮(&S)", this);
    btnShortcut->setGeometry(50, 290, 120, 40);
    connect(btnShortcut, &QPushButton::clicked, this, &Widget::onButtonClicked);

    // 6. 创建带菜单按钮
    btnWithMenu = new QPushButton("带菜单按钮", this);
    btnWithMenu->setGeometry(50, 350, 120, 40);

    // 创建菜单
    menu = new QMenu(this);

    // 添加菜单项
    QAction* action1 = menu->addAction("菜单项 1");
    QAction* action2 = menu->addAction("菜单项 2");
    QAction* action3 = menu->addAction("菜单项 3");

    // 连接菜单项触发信号到槽函数
    connect(action1, &QAction::triggered, this, &Widget::onMenuActionTriggered);
    connect(action2, &QAction::triggered, this, &Widget::onMenuActionTriggered);
    connect(action3, &QAction::triggered, this, &Widget::onMenuActionTriggered);

    // 给按钮设置菜单，按钮点击时会显示菜单
    btnWithMenu->setMenu(menu);
}

Widget::~Widget() {
    delete ui;
}

// 所有普通按钮点击都会调用这里，根据发送者区分
void Widget::onButtonClicked() {
    // sender() 返回的只是基类指针（QObject*），需要转换成具体类型（如
    // QPushButton*）才能访问特定控件的方法或属性。
    QPushButton* btn = qobject_cast<QPushButton*>(sender());
    if (!btn) return;

    QString msg = QString("按钮 \"%1\" 被点击").arg(btn->text());
    QMessageBox::information(this, "按钮点击", msg);
}

// 切换按钮状态改变时调用
void Widget::onToggleButtonClicked(bool checked) {
    QString state = checked ? "选中" : "未选中";
    QMessageBox::information(this, "切换按钮", QString("切换按钮状态: %1").arg(state));
}

// 通过 sender() 获取触发信号的 QAction 指针，然后弹出一个消息框，显示用户选择的菜单项文本。
void Widget::onMenuActionTriggered() {
    QAction* action = qobject_cast<QAction*>(sender());
    if (!action) return;

    QMessageBox::information(this, "菜单选择", QString("你选择了: %1").arg(action->text()));
}
```

### QRadioButton

`QRadioButton` 是一种单选按钮控件，通常成组使用时允许用户在多个选项中只选择一个。它支持互斥选择，常用于需要从一组选项中做出唯一选择的场景。

#### 特有接口表

| 类别         | 原型                                                         | 功能说明                                               |
| ------------ | ------------------------------------------------------------ | ------------------------------------------------------ |
| **构造函数** | `explicit QRadioButton(QWidget *parent = nullptr)`           | 创建一个空文本的单选按钮。                             |
|              | `explicit QRadioButton(const QString &text, QWidget *parent = nullptr)` | 创建一个带文本的单选按钮。                             |
| **功能设置** | `void setAutoExclusive(bool exclusive)`                      | 设置该按钮是否在同一父控件内自动保持互斥（默认开启）。 |
| **功能查询** | `bool autoExclusive() const`                                 | 返回该按钮是否启用了自动互斥功能。                     |

#### 示例

##### widget.h

```cpp
#ifndef WIDGET_H
#define WIDGET_H

#include <QWidget>
#include <QRadioButton>
#include <QButtonGroup>

QT_BEGIN_NAMESPACE
namespace Ui {
class Widget;
}
QT_END_NAMESPACE

class Widget : public QWidget
{
    Q_OBJECT

public:
    Widget(QWidget *parent = nullptr);
    ~Widget();

private slots:
    // 单选按钮切换槽，参数为按钮指针和选中状态
    void onRadioButtonToggled(QAbstractButton *button, bool checked);

private:
    Ui::Widget *ui;

    QRadioButton *radio1;
    QRadioButton *radio2;
    QRadioButton *radio3;
    QButtonGroup *radioGroup;
};

#endif // WIDGET_H
```

##### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QMessageBox>

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    radio1 = new QRadioButton("选项 1", this);
    radio1->setGeometry(200, 50, 100, 30);
    radio2 = new QRadioButton("选项 2", this);
    radio2->setGeometry(200, 90, 100, 30);
    radio3 = new QRadioButton("选项 3", this);
    radio3->setGeometry(200, 130, 100, 30);

    radioGroup = new QButtonGroup(this);
    radioGroup->addButton(radio1, 1);
    radioGroup->addButton(radio2, 2);
    radioGroup->addButton(radio3, 3);

    // 连接信号到槽，响应按钮切换
    connect(radioGroup, &QButtonGroup::buttonToggled, this, &Widget::onRadioButtonToggled);

    radio1->setChecked(true);
}

Widget::~Widget() {
    delete ui;
}

/**
 * @brief 响应单选按钮切换
 * @param button 被切换的按钮指针
 * @param checked 是否选中
 */
void Widget::onRadioButtonToggled(QAbstractButton* button, bool checked) {
    if (checked) {
        int id = radioGroup->id(button);
        QMessageBox::information(this, "单选按钮切换", QString("选中了选项 %1").arg(id));
    }
}
```

### QCheckBox

`QCheckBox` 是一种复选框控件，允许用户进行多选操作，同时支持三态模式，可以表示选中、未选中或部分选中状态，适合用来表示开关、选项设置或多项选择。

#### 特有接口表

| 类别     | 原型                                                         | 功能说明                                                     |
| -------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 构造函数 | `explicit QCheckBox(QWidget *parent = nullptr)`              | 创建一个空文本的复选框控件。                                 |
|          | `explicit QCheckBox(const QString &text, QWidget *parent = nullptr)` | 创建一个带文本的复选框控件。                                 |
| 状态设置 | `void setTristate(bool)`                                     | 设置是否启用三态（未选中、部分选中、选中）。                 |
| 状态查询 | `bool isTristate() const`                                    | 查询是否启用了三态功能。                                     |
| 状态获取 | `Qt::CheckState checkState() const`                          | 获取当前三态状态（`Qt::Unchecked`、`Qt::PartiallyChecked`、`Qt::Checked`）。 |
| 状态设置 | `void setCheckState(Qt::CheckState state)`                   | 设置当前三态状态。                                           |

#### 示例

##### widget.h

```cpp
#ifndef WIDGET_H
#define WIDGET_H

#include <QCheckBox> // 添加QCheckBox头文件
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

private slots:
    void onCheckBoxStateChanged(int state); // 状态改变槽函数

private:
    Ui::Widget* ui;

    QCheckBox* checkBox; // 声明QCheckBox指针
};

#endif // WIDGET_H
```

##### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"

#include <QDebug> // 用于输出调试信息

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 创建QCheckBox，显示文本“勾选我”，父对象为this
    checkBox = new QCheckBox("勾选我", this);

    // 设置位置和大小
    checkBox->setGeometry(50, 50, 150, 30);

    // 设置初始状态为未选中（Qt::Unchecked）
    checkBox->setCheckState(Qt::Unchecked);

    // 连接状态改变信号到槽函数
    connect(checkBox, &QCheckBox::stateChanged, this, &Widget::onCheckBoxStateChanged);

    // 设置是否允许三态（Checked, Unchecked, PartiallyChecked）
    checkBox->setTristate(true);

    // 设置的是控件的悬浮提示文本（tooltip）
    checkBox->setToolTip("这是一个演示QCheckBox三态和状态变化的例子");
}

Widget::~Widget() {
    delete ui;
}

// 槽函数：响应复选框状态变化
void Widget::onCheckBoxStateChanged(int state) {
    switch (state) {
    case Qt::Unchecked:
        qDebug() << "复选框状态: 未选中";
        break;
    case Qt::PartiallyChecked:
        qDebug() << "复选框状态: 部分选中（中间态）";
        break;
    case Qt::Checked:
        qDebug() << "复选框状态: 选中";
        break;
    default:
        break;
    }
}
```

### QCommandLinkButton

`QCommandLinkButton` 是一种带有标题和描述的按钮，外观类似于命令链接，通常用于引导用户执行特定操作或在对话框中提供更详细的按钮说明，便于用户理解按钮的功能。

#### 特有接口表

| 类别     | 原型                                                         | 功能说明                                            |
| -------- | ------------------------------------------------------------ | --------------------------------------------------- |
| 构造函数 | `explicit QCommandLinkButton(QWidget *parent = nullptr)`     | 创建一个空的命令链接按钮。                          |
|          | `explicit QCommandLinkButton(const QString &text, QWidget *parent = nullptr)` | 创建一个带主标题的命令链接按钮。                    |
|          | `QCommandLinkButton(const QString &text, const QString &description, QWidget *parent = nullptr)` | 创建一个带主标题和副标题说明的命令链接按钮。        |
| 文本设置 | `void setDescription(const QString &description)`            | 设置按钮下方的描述文本（副标题）。                  |
| 文本获取 | `QString description() const`                                | 获取按钮的描述文本。                                |
| 默认按钮 | `void setCommandLinkButtonType(CommandLinkButtonType type)`  | 设置按钮类型（`Normal` 或 `Start`），影响样式显示。 |
| 默认按钮 | `CommandLinkButtonType commandLinkButtonType() const`        | 获取按钮当前的类型。                                |

#### 示例

##### widget.h

```cpp
// widget.h

#ifndef WIDGET_H
#define WIDGET_H

#include <QCommandLinkButton>
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

private:
    Ui::Widget* ui;

    QCommandLinkButton* cmdLinkBtn;        // 普通命令链接按钮
    QCommandLinkButton* cmdLinkBtnFolder;  // 打开文件夹按钮
    QCommandLinkButton* cmdLinkBtnBrowser; // 打开浏览器按钮

private slots:
    void onCommandLinkClicked();
    void onOpenFolderClicked();
    void onOpenBrowserClicked();
};

#endif // WIDGET_H
```

##### widget.cpp

```cpp
// widget.cpp

#include "widget.h"
#include "./ui_widget.h"

#include <QDesktopServices>
#include <QFileDialog>
#include <QMessageBox>
#include <QUrl>

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 普通命令链接按钮
    cmdLinkBtn = new QCommandLinkButton("普通按钮", "点击显示提示", this);
    cmdLinkBtn->setGeometry(50, 50, 300, 60);
    // 设置图标（可以用系统图标或自定义图标）
    cmdLinkBtn->setIcon(QIcon(":/icons/sample.jpg")); 
    cmdLinkBtn->setIconSize(QSize(32, 32));
    connect(cmdLinkBtn, &QCommandLinkButton::clicked, this, &Widget::onCommandLinkClicked);

    // 打开文件夹按钮
    cmdLinkBtnFolder = new QCommandLinkButton("打开文件夹", "点击弹出选择文件夹对话框", this);
    cmdLinkBtnFolder->setGeometry(50, 130, 300, 60);
    connect(cmdLinkBtnFolder, &QCommandLinkButton::clicked, this, &Widget::onOpenFolderClicked);

    // 打开浏览器按钮
    cmdLinkBtnBrowser = new QCommandLinkButton("打开浏览器", "点击打开指定网址", this);
    cmdLinkBtnBrowser->setGeometry(50, 210, 300, 60);
    connect(cmdLinkBtnBrowser, &QCommandLinkButton::clicked, this, &Widget::onOpenBrowserClicked);
}

Widget::~Widget() {
    delete ui;
}

void Widget::onCommandLinkClicked() {
    QMessageBox::information(this, "提示", "你点击了普通命令链接按钮！");
}

void Widget::onOpenFolderClicked() {
    // 弹出文件夹选择对话框，选中文件夹路径打印出来
    QString dir = QFileDialog::getExistingDirectory(this, "选择文件夹", "", QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks);
    if (!dir.isEmpty()) {
        QMessageBox::information(this, "选中文件夹", "你选择的文件夹路径是:\n" + dir);
    }
}

void Widget::onOpenBrowserClicked() {
    // 打开默认浏览器访问指定网址
    QUrl url("https://n1ce2cu.com/");
    QDesktopServices::openUrl(url);
}
```

### QDialogButtonBox

`QDialogButtonBox` 是 Qt 提供的一个标准按钮容器，用于在对话框中统一管理按钮布局和角色（如确定、取消、应用等），简化对话框按钮的创建和事件处理，使界面风格统一且易于维护。

#### 特有接口表

| 类别         | 原型                                                         | 功能说明                                            |
| ------------ | ------------------------------------------------------------ | --------------------------------------------------- |
| 构造函数     | `explicit QCommandLinkButton(QWidget *parent = nullptr)`     | 创建一个空的命令链接按钮。                          |
|              | `explicit QCommandLinkButton(const QString &text, QWidget *parent = nullptr)` | 创建一个带主标题的命令链接按钮。                    |
|              | `QCommandLinkButton(const QString &text, const QString &description, QWidget *parent = nullptr)` | 创建一个带主标题和副标题说明的命令链接按钮。        |
| 文本设置     | `void setDescription(const QString &description)`            | 设置按钮下方的描述文本（副标题）。                  |
| 文本获取     | `QString description() const`                                | 获取按钮的描述文本。                                |
| 按钮类型设置 | `void setCommandLinkButtonType(CommandLinkButtonType type)`  | 设置按钮类型（`Normal` 或 `Start`），影响样式显示。 |
| 按钮类型获取 | `CommandLinkButtonType commandLinkButtonType() const`        | 获取按钮当前的类型。                                |
| 信号         | `void clicked()`                                             | 当按钮被点击时发出信号。                            |

#### 示例

##### widget.h

```cpp
// widget.h
#ifndef WIDGET_H
#define WIDGET_H

#include <QDialogButtonBox> // 添加头文件
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

private slots:
    void onButtonClicked(QAbstractButton* button); // QDialogButtonBox 信号槽

private:
    Ui::Widget* ui;

    QDialogButtonBox* buttonBox; // 声明 QDialogButtonBox 指针
};

#endif // WIDGET_H
```

##### widget.cpp

```cpp
// widget.cpp
#include "widget.h"
#include "./ui_widget.h"

#include <QDebug>
#include <QPushButton>

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 创建 QDialogButtonBox，使用标准按钮
    buttonBox = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel | QDialogButtonBox::Save, this);
    buttonBox->setGeometry(50, 50, 300, 40);

    // 连接按钮点击信号
    connect(buttonBox, &QDialogButtonBox::clicked, this, &Widget::onButtonClicked);

    // 设置按钮的文本自定义（可选）
    buttonBox->button(QDialogButtonBox::Ok)->setText("确认");
    buttonBox->button(QDialogButtonBox::Cancel)->setText("取消");
    buttonBox->button(QDialogButtonBox::Save)->setText("保存");
}

Widget::~Widget() {
    delete ui;
}

// 按钮点击响应槽函数
void Widget::onButtonClicked(QAbstractButton* button) {
    // 判断点击的是哪个标准按钮
    QDialogButtonBox::StandardButton sb = buttonBox->standardButton(button);
    switch (sb) {
    case QDialogButtonBox::Ok:
        qDebug() << "点击了 确认 按钮";
        break;
    case QDialogButtonBox::Cancel:
        qDebug() << "点击了 取消 按钮";
        break;
    case QDialogButtonBox::Save:
        qDebug() << "点击了 保存 按钮";
        break;
    default:
        qDebug() << "点击了 其他按钮";
        break;
    }
}
```

### QToolButton

`QToolButton` 是一种轻量级按钮控件，通常用于工具栏或紧凑界面，支持显示图标、文本或两者结合，并且可以弹出菜单或切换状态，适合用作快速操作按钮。

#### 特有接口表

| 类别         | 原型                                                 | 功能说明                                                     |
| ------------ | ---------------------------------------------------- | ------------------------------------------------------------ |
| 构造函数     | `explicit QToolButton(QWidget *parent = nullptr)`    | 创建一个空的工具按钮。                                       |
| 弹出模式设置 | `void setPopupMode(PopupMode mode)`                  | 设置弹出菜单模式（`DelayedPopup`、`MenuButtonPopup`、`InstantPopup`）。 |
| 弹出模式获取 | `PopupMode popupMode() const`                        | 获取当前的弹出菜单模式。                                     |
| 菜单设置     | `void setMenu(QMenu *menu)`                          | 设置工具按钮关联的菜单。                                     |
| 菜单获取     | `QMenu *menu() const`                                | 获取关联的菜单。                                             |
| 自动提升     | `void setAutoRaise(bool enable)`                     | 设置按钮是否自动提升（无边框样式）。                         |
| 自动提升获取 | `bool autoRaise() const`                             | 获取自动提升状态。                                           |
| 按钮样式设置 | `void setToolButtonStyle(Qt::ToolButtonStyle style)` | 设置按钮的文本和图标显示样式（如只显示图标、图标和文本等）。 |
| 按钮样式获取 | `Qt::ToolButtonStyle toolButtonStyle() const`        | 获取当前按钮的显示样式。                                     |
| 信号         | `void triggered(QAction *action)`                    | 当菜单项被触发时发出信号。                                   |

#### 示例

##### widget.cpp

```cpp
#include "widget.h"
#include <QAction>
#include <QMenu>
#include <QToolButton>
#include <QVBoxLayout>

Widget::Widget(QWidget* parent) : QWidget(parent) {
    QVBoxLayout* layout = new QVBoxLayout(this);

    // 创建 QToolButton
    QToolButton* toolButton = new QToolButton(this);
    toolButton->setText("工具按钮");
    toolButton->setIcon(QIcon(":/icons/sample.jpg")); // 设置图标
    toolButton->setToolTip("这是一个工具按钮");
    toolButton->setToolButtonStyle(Qt::ToolButtonTextUnderIcon); // 图标在上，文字在下

    // 创建菜单
    QMenu* menu = new QMenu(this);
    QAction* openAction = new QAction("打开", this);
    QAction* saveAction = new QAction("保存", this);
    menu->addAction(openAction);
    menu->addAction(saveAction);

    toolButton->setMenu(menu);                              // 设置菜单
    toolButton->setPopupMode(QToolButton::MenuButtonPopup); // 设置弹出方式（只点击右侧三角弹出）

    // 信号连接（点击菜单项）
    connect(openAction, &QAction::triggered, this, []() { qDebug("点击了：打开"); });
    connect(saveAction, &QAction::triggered, this, []() { qDebug("点击了：保存"); });

    layout->addWidget(toolButton);
}

Widget::~Widget() {
}
```

### 按钮用途对比

| 按钮类型               | 简介与用途说明                                               |
| ---------------------- | ------------------------------------------------------------ |
| **QPushButton**        | 最常用的按钮，用于触发某个操作或事件，比如“确定”、“取消”、“提交”等。通常是一个短暂动作，按下即触发信号。适用于表单提交、功能触发等场景。 |
| **QRadioButton**       | 单选按钮，用于在一组选项中选择其中一个。多个按钮配合 `QButtonGroup` 使用可实现互斥选择。适用于“性别选择”、“支付方式选择”等只有一个选项可选的场景。 |
| **QCheckBox**          | 复选框，用于表示开关状态，用户可以勾选或取消勾选，也可设置为三态（选中、未选中、不确定）。适用于“我已阅读协议”、“启用高级功能”等可多选场景。 |
| **QCommandLinkButton** | 命令链接按钮，外观更现代，类似网页上的大按钮，支持副标题描述，常用于引导用户进行推荐操作或导航。适用于“立即注册”、“开始体验”等引导型操作。 |
| **QToolButton**        | 工具按钮，通常用于工具栏或小图标按钮。可以设置菜单、箭头、图标等。适用于“保存”、“撤销”等图标快捷操作。 |
| **QDialogButtonBox**   | 对话框按钮容器，用于标准化“确定”、“取消”、“应用”等按钮的布局和处理逻辑。通常配合 `QDialog` 使用，自动管理键盘导航、默认按钮等。 |