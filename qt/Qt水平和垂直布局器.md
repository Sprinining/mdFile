## Qt 水平和垂直布局器

### 布局类的继承关系图

```css
QObject
  └── QLayoutItem
        ├── QSpacerItem        // 占位用“空白空间项”
        └── QLayout
              ├── QBoxLayout
              │     ├── QHBoxLayout   // 水平排列
              │     └── QVBoxLayout   // 垂直排列
              ├── QGridLayout         // 表格布局（二维）
              ├── QFormLayout         // 表单布局（label + field）
              └── QStackedLayout      // 类似 QStackedWidget，堆叠显示一个控件
```

- `QLayoutItem` 是所有布局项（控件、间隔、嵌套布局）的抽象基类；

- `QSpacerItem` 表示一个**不可见的空白项**；

- `QLayout` 是所有布局管理器的基类；

- `QBoxLayout` 是实现线性布局的抽象基类，`QHBoxLayout` 与 `QVBoxLayout` 是它的子类；

- `QGridLayout` 是二维网格布局（常用于表格形式）；

- `QFormLayout` 是一行两个元素（如 QLabel + QLineEdit）的布局；

- `QStackedLayout` 可用于在同一个区域中切换多个控件（常用于多页面切换）。

### QBoxLayout

`QBoxLayout` 是 Qt 框架中用于**控件布局管理**的基类，它可以沿着一个方向（水平或垂直）自动排列子控件。它不是直接使用的类，而是 `QHBoxLayout` 和 `QVBoxLayout` 的父类：

- `QHBoxLayout`：水平排列子控件（从左到右）
- `QVBoxLayout`：垂直排列子控件（从上到下）

`QBoxLayout` 提供了通用的布局能力，并允许更灵活地控制控件的添加、伸缩因子、对齐方式等。

#### 构造函数

```cpp
QBoxLayout::QBoxLayout(Direction dir);
```

`dir` 参数指定排列方向：

- `QBoxLayout::LeftToRight`（水平）
- `QBoxLayout::TopToBottom`（垂直）
- `QBoxLayout::RightToLeft`
- `QBoxLayout::BottomToTop`

#### 常用函数

| 函数                                                         | 说明                   |
| ------------------------------------------------------------ | ---------------------- |
| `addWidget(QWidget *widget, int stretch = 0, Qt::Alignment alignment = 0)` | 添加控件               |
| `addLayout(QLayout *layout, int stretch = 0)`                | 添加嵌套布局           |
| `addSpacing(int size)`                                       | 添加固定间隔           |
| `addStretch(int stretch = 0)`                                | 添加可伸缩空间（弹簧） |
| `insertWidget(int index, QWidget *widget, int stretch = 0, Qt::Alignment alignment = 0)` | 在指定位置插入控件     |
| `setSpacing(int)`                                            | 设置控件间的默认间隔   |
| `setContentsMargins(int left, int top, int right, int bottom)` | 设置布局边距           |
| `setStretch(int index, int stretch)`                         | 设置某个子项的伸缩因子 |

#### 示例：水平布局

```cpp
QWidget *window = new QWidget;

QHBoxLayout *layout = new QHBoxLayout; // 继承自 QBoxLayout
layout->addWidget(new QPushButton("Button 1"));
layout->addWidget(new QPushButton("Button 2"));
layout->addStretch();  // 将 Button 推到左边

window->setLayout(layout);
window->show();
```

#### 示例：嵌套布局（Box + Grid）

```cpp
QVBoxLayout *mainLayout = new QVBoxLayout;
QHBoxLayout *topLayout = new QHBoxLayout;
QGridLayout *grid = new QGridLayout;

topLayout->addWidget(new QLabel("Name:"));
topLayout->addWidget(new QLineEdit);

grid->addWidget(new QLabel("Age:"), 0, 0);
grid->addWidget(new QSpinBox, 0, 1);

mainLayout->addLayout(topLayout);
mainLayout->addLayout(grid);
mainLayout->addStretch();

window->setLayout(mainLayout);
```

###  `ui_*.h` 文件中布局器的内幕代码

#### ASCII 图

```css
+---------------------------------------------------------------+
| +-------------------------+   +-----------------------------+ |
| |                         |   |                             | |
| |      QTextBrowser       |   |       QPlainTextEdit        | |
| |                         |   |                             | |
| +-------------------------+   +-----------------------------+ |
| | [← Back] [→ Forward]                    [ 打开HTML按钮 ] | |
| +-------------------------+   +-----------------------------+ |
+---------------------------------------------------------------+

```

#### ui_widget.h

```cpp
#ifndef UI_WIDGET_H
#define UI_WIDGET_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QPlainTextEdit>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QTextBrowser>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_Widget
{
public:
    // 最外层布局（横向），把左侧和右侧两个垂直区域并排显示
    QHBoxLayout *horizontalLayout_3;

    // 左侧垂直布局区域（包含 QTextBrowser + 按钮区域）
    QVBoxLayout *verticalLayout;

    // 显示 HTML 内容的文本浏览器
    QTextBrowser *textBrowser;

    // 左侧按钮区域（横向）包含两个按钮 + 弹簧
    QHBoxLayout *horizontalLayout;
    QPushButton *btnBackward; // “后退”按钮
    QPushButton *btnForward;  // “前进”按钮
    QSpacerItem *horizontalSpacer; // 推动按钮靠左的横向弹簧

    // 右侧垂直布局区域（包含文本输入框 + 打开按钮）
    QVBoxLayout *verticalLayout_2;
    QPlainTextEdit *plainTextEdit; // 输入 HTML 的文本框

    // “打开按钮”区域的底部水平布局（按钮靠右）
    QHBoxLayout *horizontalLayout_2;
    QSpacerItem *horizontalSpacer_2; // 推动按钮靠右的横向弹簧
    QPushButton *btnOpen; // “打开HTML”按钮

    // 在自己的窗口类构造函数中显式调用 ui.setupUi(this)
    // 初始化 UI 元素（控件、布局等）并添加到窗口中
    void setupUi(QWidget *Widget)
    {
        if (Widget->objectName().isEmpty())
            Widget->setObjectName("Widget");
        Widget->resize(630, 350);

        // 最外层主布局：水平布局，左边是显示内容，右边是输入区域
        horizontalLayout_3 = new QHBoxLayout(Widget);
        horizontalLayout_3->setObjectName("horizontalLayout_3");

        // 左边区域：垂直布局（textBrowser + 操作按钮）
        verticalLayout = new QVBoxLayout();
        verticalLayout->setObjectName("verticalLayout");

        textBrowser = new QTextBrowser(Widget);
        textBrowser->setObjectName("textBrowser");
        verticalLayout->addWidget(textBrowser);

        // 下方按钮行：btnBackward + btnForward + spacer
        horizontalLayout = new QHBoxLayout();
        horizontalLayout->setObjectName("horizontalLayout");

        btnBackward = new QPushButton(Widget);
        btnBackward->setObjectName("btnBackward");
        horizontalLayout->addWidget(btnBackward);

        btnForward = new QPushButton(Widget);
        btnForward->setObjectName("btnForward");
        horizontalLayout->addWidget(btnForward);

        horizontalSpacer = new QSpacerItem(40, 20, QSizePolicy::Expanding, QSizePolicy::Minimum);
        horizontalLayout->addItem(horizontalSpacer);

        // 按钮区域添加到底部
        verticalLayout->addLayout(horizontalLayout);

        // 将左侧垂直布局加入主布局
        horizontalLayout_3->addLayout(verticalLayout);

        // 右边区域：垂直布局（plainTextEdit + 打开按钮）
        verticalLayout_2 = new QVBoxLayout();
        verticalLayout_2->setObjectName("verticalLayout_2");

        plainTextEdit = new QPlainTextEdit(Widget);
        plainTextEdit->setObjectName("plainTextEdit");
        verticalLayout_2->addWidget(plainTextEdit);

        // 打开按钮区域（按钮靠右）
        horizontalLayout_2 = new QHBoxLayout();
        horizontalLayout_2->setObjectName("horizontalLayout_2");

        horizontalSpacer_2 = new QSpacerItem(40, 20, QSizePolicy::Expanding, QSizePolicy::Minimum);
        horizontalLayout_2->addItem(horizontalSpacer_2);

        btnOpen = new QPushButton(Widget);
        btnOpen->setObjectName("btnOpen");
        horizontalLayout_2->addWidget(btnOpen);

        verticalLayout_2->addLayout(horizontalLayout_2);

        // 将右侧垂直布局加入主布局
        horizontalLayout_3->addLayout(verticalLayout_2);

        // 设置窗口标题和按钮文本
        retranslateUi(Widget);

        QMetaObject::connectSlotsByName(Widget);
    }

    void retranslateUi(QWidget *Widget)
    {
        Widget->setWindowTitle(QCoreApplication::translate("Widget", "Widget", nullptr));
        btnBackward->setText(QCoreApplication::translate("Widget", "后退", nullptr));
        btnForward->setText(QCoreApplication::translate("Widget", "前进", nullptr));
        btnOpen->setText(QCoreApplication::translate("Widget", "打开HTML", nullptr));
    }
};

namespace Ui {
    class Widget: public Ui_Widget {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_WIDGET_H
```

