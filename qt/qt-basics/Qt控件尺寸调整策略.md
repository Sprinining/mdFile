## Qt 控件尺寸调整策略

### 布局器

Qt 的 **布局器（Layout Manager）** 是用来自动管理控件（QWidget）在窗口中**尺寸和位置**的机制。其工作原理核心是：根据每个控件的 `QSizePolicy`、`sizeHint()`、`minimumSize()` 等信息，结合父容器的大小，自动计算和分配控件的显示区域。

#### Qt 布局器的工作流程

##### 1. **收集控件信息**

布局器收集每个子控件的：

- `sizeHint()`：推荐尺寸
- `minimumSizeHint()`：最小推荐尺寸
- `minimumSize()` / `maximumSize()`
- `QSizePolicy`：是否可以扩展、收缩

##### 2. **分析剩余空间**

父容器提供总空间，布局器计算：

```css
总可用空间 = 父窗口尺寸 - 布局的 margin/padding
```

##### 3. **计算控件尺寸和位置**

根据控件的 **尺寸策略（QSizePolicy）** 和 **stretch 因子**：

- 将控件的空间进行分配
- 保证基本的对齐、间距要求（如 `spacing()`）
- 保证控件不会超出其最大尺寸，也不会小于其最小尺寸

##### 4. **重绘与响应变化**

当窗口大小改变、控件显示/隐藏，或者手动调用 `updateGeometry()` 时，布局器会**重新计算**并应用所有控件的布局。

#### 关键参数的作用

| 参数                   | 说明                                               |
| ---------------------- | -------------------------------------------------- |
| `sizeHint()`           | 控件的推荐尺寸（通常由内容决定）                   |
| `QSizePolicy`          | 控件是否允许拉伸/收缩                              |
| `stretch` 因子         | 控件在多余空间中所占比例                           |
| `spacing()`            | 控件之间的间距                                     |
| `setContentsMargins()` | 布局与外边界之间的间距（top, left, right, bottom） |

#### 示例演示

```cpp
QWidget *window = new QWidget();
QPushButton *btn1 = new QPushButton("A");
QPushButton *btn2 = new QPushButton("B");

QHBoxLayout *layout = new QHBoxLayout();
layout->addWidget(btn1);
layout->addWidget(btn2);
layout->setStretch(0, 1);  // A 占1份
layout->setStretch(1, 2);  // B 占2份

window->setLayout(layout);
window->show();
```

在这个例子中，`btn2` 会占据更多空间，因为 stretch 因子更大。

#### 布局相关函数小结

| 函数名                                   | 说明                         |
| ---------------------------------------- | ---------------------------- |
| `setLayout(QLayout*)`                    | 给 QWidget 设置布局器        |
| `layout()->addWidget()`                  | 添加子控件                   |
| `updateGeometry()`                       | 手动通知重新计算控件尺寸     |
| `setStretch(int index, int)`             | 设置控件在多余空间中所占比例 |
| `setContentsMargins(int, int, int, int)` | 设置布局边距                 |
| `setSpacing(int)`                        | 设置控件间间距               |

#### 工作原理

（1）**初始布局：**

- 布局器在初始化时，会读取每个控件的 `QWidget::sizePolicy()` 和 `QWidget::sizeHint()`。
  - `sizePolicy()`：决定控件是否可以拉伸或缩小，例如：
    - `QSizePolicy::Fixed` —— 尺寸固定，不拉伸；
    - `QSizePolicy::Expanding` —— 能拉多大就拉多大；
  - `sizeHint()`：控件的推荐尺寸（由内容自动计算得出，比如按钮上的文字有多长，标签显示多少内容）。

布局器根据这些信息，合理分配控件初始空间。

（2）**窗口放大时：**

- 如果控件设置了非零的**伸展因子（stretch factor）**，新增的空闲空间会**按比例分配**给这些控件。
- 示例：一个控件设置伸展因子 1，另一个是 2，则额外空间按 1:2 分配。

（3）**默认情况下（所有控件 stretch = 0）：**

- 控件**不主动抢空间**，布局器只会优先放大那些 `QSizePolicy::Expanding` 的控件；
- 如果多个控件都设置了 `Expanding`，则它们平均分配空闲区域；
- 如果控件既不想拉伸，也不设置伸展因子，它们不会增长，空间可能被浪费。

（4）**窗口缩小时：**

- 控件不会无限缩小，布局器会根据控件的**最小尺寸**设置下限：
  - 如果程序设置了 `minimumSize()`，以它为准；
  - 否则使用 Qt 自动计算的 `minimumSizeHint()`；
  - 如果控件完全靠 stretch factor 来控制大小，则可能**没有下限**（可压缩为0）。

（5）**窗口继续放大时：**

- 控件也不会无限增长，布局器参考控件的**最大尺寸**设置上限：
  - 如果程序设置了 `maximumSize()`，以它为准；
  - 如果未设置，则控件可以继续增长，直到布局器分配完所有空间；
  - 同样地，如果控件完全靠 stretch factor 控制，可能**没有上限**（直到父容器限制）。

### 伸展因子 Stretch Factor

**伸展因子**是 Qt 布局器（如 `QHBoxLayout`, `QVBoxLayout`）在分配“额外空间”时用来决定**哪个控件分多一点、哪个分少一点**的一个整数权重值。

它本质上是一种“相对比例”，决定了子控件在父窗口放大时多出来的空间如何分配。

#### 工作原理

布局器会遵循以下步骤来使用伸展因子：

1. 初始布局时，按控件的 `sizeHint()` 分配空间；
2. 窗口变大时，多出来的空间叫做“**剩余空间**”；
3. 布局器将这些空间按**各控件的伸展因子比例**进行分配。

例如：

```cpp
layout->setStretch(0, 1);
layout->setStretch(1, 2);
```

如果剩余空间为 300 像素，控件0 分得 100 像素，控件1 分得 200 像素（1:2）。

#### 默认行为

- 默认情况下，所有控件的伸展因子都是 **0**；
- 如果都为 0，布局器会：
  - **优先扩展那些 `QSizePolicy::Expanding` 的控件**；
  - 否则剩余空间就可能被浪费或均匀分配；
- 如果某些控件设置了非零的 stretch，那么**只有这些控件参与空间分配**，其他控件默认保持不变。

#### 设置方法

##### 设置单个控件的伸展因子

推荐方式是**通过布局器设置**：

```cpp
layout->addWidget(widget1);
layout->addWidget(widget2);
layout->setStretch(0, 1);
layout->setStretch(1, 2);
```

##### 添加控件时直接指定

```cpp
layout->addWidget(widget, stretch);
```

适用于 `addWidget()` 和 `addLayout()`。

#### 注意事项

| 注意点                        | 说明                                                    |
| ----------------------------- | ------------------------------------------------------- |
| 不要对控件直接设置“stretch”   | 控件本身没有这个属性，应该让布局器设置                  |
| 默认所有控件 stretch = 0      | 所以不设置时通常不会参与剩余空间分配                    |
| stretch 只是影响多出来的空间  | 不影响初始大小，初始大小仍由 `sizeHint()` 控制          |
| stretch 不能限制最小/最大大小 | 控件可能拉太大/太小，配合 `setMinimumSize()` 使用更稳妥 |

### 伸展策略 QSizePolicy

`QSizePolicy` 是 Qt 中用于控制 **控件尺寸调整行为** 的类，它指导布局管理器如何根据控件的建议尺寸、内容和布局策略来分配空间。简单来说，`QSizePolicy` 决定了控件在父布局中是否拉伸、是否可以缩小、以及在多大程度上伸展。

#### 基本定义（头文件）

```cpp
#include <QSizePolicy>
```

#### QSizePolicy 的核心成员

构造函数

```cpp
QSizePolicy();
QSizePolicy(QSizePolicy::Policy horizontal, QSizePolicy::Policy vertical);
```

- `horizontal`：水平方向的策略。
- `vertical`：垂直方向的策略。

#### QSizePolicy::Policy 枚举值（控制行为）

| 枚举值             | 最小限制                     | 最大限制            | 拉伸能力   | 对 sizeHint 的依赖 | 常见用途/适用场景                                      |
| ------------------ | ---------------------------- | ------------------- | ---------- | ------------------ | ------------------------------------------------------ |
| `Fixed`            | 不能缩小                     | 不能变大            | ❌ 无       | ✅ 严格依赖         | 需要固定大小的控件，如图标、按钮、Logo 等              |
| `Minimum`          | 最小为 `sizeHint()`          | 没有限制（可变大）  | ✅ 被动扩展 | ✅ 使用             | 希望控件尽量小但在必要时可放大，如紧凑型文本标签       |
| `Maximum`          | 没有限制（可变小）           | 最大为 `sizeHint()` | ✅ 被动缩小 | ✅ 使用             | 控件默认希望大，但允许缩小，如装饰性容器或信息区       |
| `Preferred` (默认) | 使用 `minimumSizeHint()`     | 可缩可扩            | ✅ 中性扩展 | ✅ 使用             | 大多数控件的默认选择，平衡性好，如输入框、普通按钮等   |
| `Expanding`        | 可缩小到 `minimumSizeHint()` | 无限扩展            | ✅ 主动扩展 | ✅ 使用             | 希望控件尽量占据更多空间，如编辑器、表格、列表等       |
| `MinimumExpanding` | 使用 `sizeHint()`            | 可扩展              | ✅ 温和扩展 | ✅ 使用             | 控件不主动抢空间，但愿意扩展，如状态栏项、可展开区域等 |
| `Ignored`          | 忽略 sizeHint                | 无任何限制          | ✅ 任意扩展 | ❌ 忽略             | 完全交由布局器决定尺寸，如自绘控件、图形视图等         |

#### 常用函数

```cpp
void setHorizontalPolicy(QSizePolicy::Policy);
void setVerticalPolicy(QSizePolicy::Policy);
void setHeightForWidth(bool);
bool hasHeightForWidth() const;

QSizePolicy::Policy horizontalPolicy() const;
QSizePolicy::Policy verticalPolicy() const;
```

#### 示例：设置控件的 QSizePolicy

```cpp
QPushButton *button = new QPushButton("Click Me");
QSizePolicy policy(QSizePolicy::Expanding, QSizePolicy::Fixed);
button->setSizePolicy(policy);
```

- 表示水平方向可以拉伸，垂直方向固定不变。

#### 使用建议

##### ① **尺寸固定不变**

如果希望控件的尺寸在水平或垂直方向保持固定，不随窗口缩放变化，
 那么就将该方向的策略设置为：

```cpp
QSizePolicy::Fixed
```

- 控件尺寸由 `setFixedSize()` 或 `sizeHint()` 决定，布局器不会改变它。
- 适用于：Logo、图标、分隔线、小按钮等不希望变形的控件。

##### ② **被动拉伸（别人不要空间我才扩展）**

如果希望控件尺寸默认维持适当大小，在没有其他控件抢空间的情况下可以扩展，
 使用以下策略之一：

```cpp
QSizePolicy::Preferred
QSizePolicy::Minimum
```

- `Preferred`：使用 `sizeHint()` 作为基础尺寸，允许变大或变小（默认策略）。
- `Minimum`：倾向于保持最小尺寸（`minimumSizeHint()`），更紧凑。

适用于：标签、按钮、输入框等可变大小但不主动扩展的控件。

##### ③ **主动扩张，积极填充空间**

如果希望控件**尽可能拉伸填满剩余空间**，就使用：

```cpp
QSizePolicy::Expanding
```

- 控件会向布局器“表达意愿”抢占空间，适用于：文本编辑器、表格、图形视图等。
- 搭配 `setStretch()` 效果更佳，可以决定扩展的相对比例。

##### ④ **尽量大，但可以压缩**

如果希望控件通常保持较大尺寸，但允许被压缩让其他控件获得空间，可以使用：

```cpp
QSizePolicy::Maximum
```

- 控件会倾向于占据推荐尺寸或更大，但在空间紧张时可以缩小。
- 适用于：提示区、可折叠面板、状态信息等不抢空间但需要“显示完整内容”的控件。

##### ⑤ **希望最小为 sizeHint，同时愿意扩张但不强求**

如果你希望控件有一个合理的最小尺寸，但在空间足够时也可以扩展（但不是抢），使用：

```cpp
QSizePolicy::MinimumExpanding
```

- 相比 `Expanding` 更保守，适用于：表格单元格、设置面板、信息块等。

##### ⑥ **完全交由布局器决定尺寸**

如果控件的大小不由 `sizeHint()` 控制，完全由布局器说了算，使用：

```cpp
QSizePolicy::Ignored
```

- 常用于：绘图区域、自定义组件、OpenGL/视频渲染窗口等。

### 示例：伸展策略对比

#### widget.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>Widget</class>
 <widget class="QWidget" name="Widget">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>477</width>
    <height>304</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QPushButton" name="pushButtonFixed">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Fixed" vsizetype="Fixed">
         <horstretch>0</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
       </property>
       <property name="text">
        <string>Fixed</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonPreferred">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Preferred" vsizetype="Fixed">
         <horstretch>0</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
       </property>
       <property name="text">
        <string>Preferred</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QPushButton" name="pushButtonPreferred2">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Preferred" vsizetype="Fixed">
         <horstretch>0</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
       </property>
       <property name="text">
        <string>Preferred2</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonMinimum">
       <property name="text">
        <string>Minimum</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_3">
     <item>
      <widget class="QPushButton" name="pushButtonMinimum2">
       <property name="text">
        <string>Minimum2</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonExpanding">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Expanding" vsizetype="Fixed">
         <horstretch>0</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
       </property>
       <property name="text">
        <string>Expanding</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
  </layout>
 </widget>
 <resources/>
 <connections/>
</ui>
```

#### widget.h

``` cpp
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

  private slots:
    void on_pushButtonFixed_clicked();

  private:
    Ui::Widget* ui;
    QWidget* widget = nullptr;
    void createWidget();
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDebug>
#include <QHBoxLayout>
#include <QLineEdit>
#include <QVBoxLayout>

// 构造函数
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 输出 UI 中已有按钮的 sizeHint 和 minimumSizeHint
    qDebug() << tr("Preferred 按钮：") << ui->pushButtonPreferred->sizeHint() << ui->pushButtonPreferred->minimumSizeHint();
    qDebug() << tr("Expanding 按钮：") << ui->pushButtonExpanding->sizeHint() << ui->pushButtonExpanding->minimumSizeHint();

    // 创建演示不同 size policy 的小窗口
    createWidget();
}

// 析构函数
Widget::~Widget() {
    if (widget != nullptr) {
        delete widget;
        widget = nullptr;
    }
    delete ui;
}

// 创建演示窗口
void Widget::createWidget() {
    // 创建一个新窗口用于展示不同 QLineEdit 的尺寸策略行为
    widget = new QWidget(this, Qt::Window);
    widget->resize(480, 360);
    widget->setWindowTitle(tr("单行编辑器的布局"));

    // 使用垂直布局作为主布局
    QVBoxLayout* mainLayout = new QVBoxLayout(widget);

    // -------- 第一行：Fixed 和 Preferred --------
    QLineEdit* leFixed = new QLineEdit(widget);
    leFixed->setText(tr("Fixed"));

    // 设置为 Fixed，表示：不参与布局器的尺寸调整，保持原大小
    QSizePolicy sp = leFixed->sizePolicy();
    sp.setHorizontalPolicy(QSizePolicy::Fixed);
    leFixed->setSizePolicy(sp);

    QLineEdit* lePreferred = new QLineEdit(widget);
    lePreferred->setText(tr("Preferred"));

    // 设置为 Preferred，表示：布局器会参考控件的 sizeHint，但在空间足够时允许变大
    sp = lePreferred->sizePolicy();
    sp.setHorizontalPolicy(QSizePolicy::Preferred);
    lePreferred->setSizePolicy(sp);

    // 水平布局，加入两个控件
    QHBoxLayout* lay1 = new QHBoxLayout();
    lay1->addWidget(leFixed);     // 尺寸固定
    lay1->addWidget(lePreferred); // 尺寸可拉伸（被动）

    mainLayout->addLayout(lay1);

    // -------- 第二行：Preferred 与 Minimum --------
    QLineEdit* lePreferred2 = new QLineEdit(widget);
    lePreferred2->setText(tr("Preferred2"));

    sp = lePreferred->sizePolicy();
    sp.setHorizontalPolicy(QSizePolicy::Preferred);
    lePreferred2->setSizePolicy(sp);

    QLineEdit* leMinimum = new QLineEdit(widget);
    leMinimum->setText(tr("Minimum"));

    // 设置为 Minimum：优先保持 minimumSizeHint，但允许空间不足时被压缩
    sp = leMinimum->sizePolicy();
    sp.setHorizontalPolicy(QSizePolicy::Minimum);
    leMinimum->setSizePolicy(sp);

    QHBoxLayout* lay2 = new QHBoxLayout();
    lay2->addWidget(lePreferred2); // 可以被动拉伸
    lay2->addWidget(leMinimum);    // 更倾向于压缩至最小

    mainLayout->addLayout(lay2);

    // -------- 第三行：Minimum 与 Expanding --------
    QLineEdit* leMinimum2 = new QLineEdit(widget);
    leMinimum2->setText(tr("Minimum2"));

    sp = leMinimum2->sizePolicy();
    sp.setHorizontalPolicy(QSizePolicy::Minimum);
    leMinimum2->setSizePolicy(sp);

    QLineEdit* leExpanding = new QLineEdit(widget);
    leExpanding->setText(tr("Expanding"));

    // 设置为 Expanding：主动参与布局器的空间分配，尽可能拉伸占满可用空间
    sp = leExpanding->sizePolicy();
    sp.setHorizontalPolicy(QSizePolicy::Expanding);
    leExpanding->setSizePolicy(sp);

    QHBoxLayout* lay3 = new QHBoxLayout();
    lay3->addWidget(leMinimum2);  // 保持最小但可以拉伸
    lay3->addWidget(leExpanding); // 会尽量抢占剩余空间

    mainLayout->addLayout(lay3);

    // 设置主布局
    widget->setLayout(mainLayout);

    // 输出各控件的建议尺寸
    qDebug() << tr("Fixed 编辑器建议尺寸：") << leFixed->sizeHint();
    qDebug() << tr("Preferred 编辑器建议尺寸：") << lePreferred->sizeHint();
    qDebug() << tr("Preferred 编辑器最小建议尺寸：") << lePreferred->minimumSizeHint();
    qDebug() << tr("Minimum 编辑器建议尺寸：") << leMinimum->sizeHint();
    qDebug() << tr("Expanding 编辑器建议尺寸：") << leExpanding->sizeHint();
    qDebug() << tr("Expanding 编辑器最小建议尺寸：") << leExpanding->minimumSizeHint();
}

// 按钮点击槽函数：弹出演示窗口
void Widget::on_pushButtonFixed_clicked() {
    if (widget != nullptr) widget->show();
}
```

