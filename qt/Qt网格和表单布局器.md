## Qt 网格和表单布局器

### QGridLayout

`QGridLayout` 是 Qt 中用于实现 **网格布局（Grid Layout）** 的类，它允许像操作表格一样将控件布置在窗口中。该布局把区域划分成行和列，每个控件可以被放置在指定的单元格中，甚至可以跨越多行或多列。

#### 基本用法

```cpp
#include <QApplication>
#include <QWidget>
#include <QGridLayout>
#include <QPushButton>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QWidget window;
    QGridLayout *layout = new QGridLayout();

    layout->addWidget(new QPushButton("Button 0,0"), 0, 0); // 第0行第0列
    layout->addWidget(new QPushButton("Button 0,1"), 0, 1); // 第0行第1列
    layout->addWidget(new QPushButton("Button 1,0"), 1, 0); // 第1行第0列
    layout->addWidget(new QPushButton("Button 1,1"), 1, 1); // 第1行第1列

    window.setLayout(layout);
    window.show();

    return app.exec();
}
```

#### 函数说明

##### 添加控件

```cpp
void addWidget(QWidget *widget, int row, int column);
void addWidget(QWidget *widget, int row, int column, int rowSpan, int columnSpan);
```

- `row` / `column`：控件所在的起始行和列。
- `rowSpan` / `columnSpan`：控件占用的行数和列数（默认是 1）。

##### 设置间距

```cpp
void setSpacing(int);
void setHorizontalSpacing(int);
void setVerticalSpacing(int);
```

##### 设置边距（控件到窗口边缘的距离）

```cpp
void setContentsMargins(int left, int top, int right, int bottom);
```

##### 获取行/列的最小尺寸或伸缩因子

```cpp
void setRowMinimumHeight(int row, int minSize);
void setColumnMinimumWidth(int column, int minSize);

void setRowStretch(int row, int stretch);
void setColumnStretch(int column, int stretch);
```

#### 示例：跨行跨列控件

```cpp
layout->addWidget(new QPushButton("Span 2x2"), 0, 0, 2, 2); // 跨越2行2列
```

### QFormLayout

`QFormLayout` 是 Qt 框架中用于构建表单布局（form layout）的一种布局管理器，属于 `QLayout` 的子类，主要用于在 GUI 应用中创建“标签 + 控件”一一对应排列的表单结构，例如常见的“用户名 + 输入框”、“密码 + 输入框”。

#### 排列方式

`QFormLayout` 将控件以“**一行一个字段**”的方式垂直排列，每行由以下几种情况之一构成：

| 排列方式                                  | 示例                            |
| ----------------------------------------- | ------------------------------- |
| 标签 + 控件（常见）                       | `QLabel + QLineEdit`            |
| 控件独占一行（无标签）                    | `QWidget`（如按钮组、说明文字） |
| 标签 + 多控件（例如一个标签对应多个按钮） | `QLabel + QWidget*` 组合容器    |

#### 常用方法

```cpp
QFormLayout *formLayout = new QFormLayout;

// 添加标签 + 控件（最常用）
formLayout->addRow(new QLabel("Username:"), new QLineEdit);

// 添加无标签的控件（控件独占一行）
formLayout->addRow(new QPushButton("Submit"));

// 添加多控件一行（例如两个按钮）
QWidget *container = new QWidget;
QHBoxLayout *hLayout = new QHBoxLayout(container);
hLayout->addWidget(new QPushButton("Yes"));
hLayout->addWidget(new QPushButton("No"));
formLayout->addRow(new QLabel("Confirm:"), container);
```

#### 对齐方式与间距调整

```cpp
formLayout->setLabelAlignment(Qt::AlignRight);  // 标签右对齐
formLayout->setFormAlignment(Qt::AlignTop);     // 整个表单顶部对齐
formLayout->setSpacing(10);                     // 控件之间的间距
formLayout->setHorizontalSpacing(15);           // 标签与控件的水平间距
formLayout->setVerticalSpacing(8);              // 行之间的垂直间距
```

#### QFormLayout::LabelRole

`QFormLayout::ItemRole` 是一个枚举类型，用于描述一个控件在表单布局中所处的角色（位置），有如下几种值：

```cpp
enum QFormLayout::ItemRole {
    LabelRole,      // 表示标签项（左侧）
    FieldRole,      // 表示字段项（右侧）
    SpanningRole,   // 跨越整个行（用于无标签的控件）
    SeparatorRole,  // 分隔线（用于视觉分割，较少用）
    InvalidRole     // 无效项
};
```

获取或操作某个角色上的控件：

```cpp
QLayoutItem *labelItem = formLayout->itemAt(rowIndex, QFormLayout::LabelRole);
QWidget *labelWidget = labelItem ? labelItem->widget() : nullptr;
```

示例：修改第 0 行标签的文本

```cpp
QLayoutItem *labelItem = formLayout->itemAt(0, QFormLayout::LabelRole);
if (labelItem && labelItem->widget()) {
    QLabel *label = qobject_cast<QLabel *>(labelItem->widget());
    if (label) {
        label->setText("New Label:");
    }
}
```

### 对比

| 特性                           | `QGridLayout`                        | `QFormLayout`                          |
| ------------------------------ | ------------------------------------ | -------------------------------------- |
| 结构灵活性                     | 任意控件位置、跨行跨列               | 固定为“标签 + 控件”行对                |
| 水平拉伸（horizontal stretch） | 可对任意列设置拉伸因子，自由控制宽度 | 通常只有字段控件（右侧）可以水平拉伸   |
| 垂直拉伸（vertical stretch）   | 可对任意行设置拉伸因子               | 一般行高由内容决定，不建议用作垂直拉伸 |
| 适合场景                       | 复杂表格、面板、自由网格             | 设置页、配置表单（字段较少、整齐结构） |
| 控件之间间距控制               | 高度自定义（行/列间距）              | 较统一（有统一的水平/垂直间距设置）    |
