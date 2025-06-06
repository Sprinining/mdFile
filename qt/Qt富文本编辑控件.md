## Qt 富文本编辑控件

### 继承关系图

```css
QObject
└── QWidget
    ├── QLineEdit
    └── QFrame
        └── QAbstractScrollArea
            ├── QPlainTextEdit
            └── QTextEdit
                └── QTextBrowser
```

### QFrame

`QFrame` 是 Qt 框架中的一个基础控件类，继承自 `QWidget`，它的主要作用是为界面元素提供一个带边框的容器，常用于分隔或包装其他控件。`QFrame` 既可以独立使用，也经常作为其他控件（比如 `QGroupBox`、`QLabel`）的基类。

#### 主要功能

**显示边框**： `QFrame` 可以显示不同风格的边框，如线型框、凹陷/凸起框等。

**分隔内容**： 常用于布局中作为分隔线（横线或竖线），起到视觉上的分隔作用。

**包裹控件**： 可以作为容器包裹其他控件，带上统一的外观样式。

#### 常用属性和方法

##### 边框样式相关

```cpp
void setFrameStyle(int style);
int frameStyle() const;
```

- `frameStyle()` 设置框的样式，由两部分组成：
  - 线条样式（Shape）：例如 `QFrame::Box`、`QFrame::Panel`、`QFrame::HLine`、`QFrame::VLine` 等
  - 阴影效果（Shadow）：例如 `QFrame::Plain`、`QFrame::Raised`、`QFrame::Sunken`

例如：

```cpp
frame->setFrameStyle(QFrame::Panel | QFrame::Raised);
```

##### 线宽和中线宽

```cpp
void setLineWidth(int width);
int lineWidth() const;

void setMidLineWidth(int width);
int midLineWidth() const;
```

- `lineWidth()` 设置边框线的宽度
- `midLineWidth()` 仅对某些样式（如 `QFrame::Panel`）有效，表示中间阴影线宽度

#### 常用子类

- `QLabel`、`QGroupBox` 等控件都继承自 `QFrame`，因此可以使用其边框功能。
- `QFrame` 本身不会显示文本或交互内容，常与布局管理器或子控件配合使用。

#### 示例代码

```cpp
QFrame *frame = new QFrame(this);
frame->setFrameStyle(QFrame::Box | QFrame::Raised);
frame->setLineWidth(2);
frame->setMidLineWidth(1);
frame->setFixedSize(200, 100);
```

#### 用作分隔线

```cpp
QFrame *line = new QFrame(this);
line->setFrameShape(QFrame::HLine);  // 水平线
line->setFrameShadow(QFrame::Sunken);
```

### QAbstractScrollArea

`QAbstractScrollArea` 是 Qt 中用于实现**可滚动区域控件**的抽象基类，位于 `QtWidgets` 模块中。它为具有滚动条的界面控件（如 `QTextEdit`, `QTableView`, `QGraphicsView`, `QPlainTextEdit` 等）提供了统一的框架支持。

#### 核心概念

`QAbstractScrollArea` 本身不会显示任何内容，但它提供了以下结构：

1. **视口区域（viewport）**
    内容真正绘制的区域，是一个 `QWidget*`，可以通过 `viewport()` 获取。
2. **滚动条（scroll bars）**
    提供垂直/水平滚动条（`QScrollBar* verticalScrollBar()` 和 `horizontalScrollBar()`），并能自动控制它们的显示/隐藏。
3. **内容区管理**
    提供了处理滚动事件、鼠标事件、键盘事件的接口，使子类可以实现复杂的自定义滚动逻辑。

#### 常用接口

##### 滚动条控制

```cpp
QScrollBar* horizontalScrollBar() const;
QScrollBar* verticalScrollBar() const;
void setVerticalScrollBarPolicy(Qt::ScrollBarPolicy policy);
void setHorizontalScrollBarPolicy(Qt::ScrollBarPolicy policy);
```

> 滚动条策略包括：
>
> - `Qt::ScrollBarAlwaysOn`：始终显示滚动条（即使内容不溢出也显示）
> - `Qt::ScrollBarAlwaysOff`：始终隐藏滚动条（不允许用户滚动）
> - `Qt::ScrollBarAsNeeded`：根据需要显示滚动条（当内容超出视口时才显示）

##### 视口相关

```cpp
QWidget* viewport() const;
void setViewport(QWidget* widget);
```

视口（viewport）是绘制内容的区域，所有内容都应该绘制在这个区域内。

##### 事件处理（通常在子类中重写）

```cpp
virtual void scrollContentsBy(int dx, int dy);
virtual void resizeEvent(QResizeEvent* event);
virtual void paintEvent(QPaintEvent* event);
virtual void mousePressEvent(QMouseEvent* event);
// 等等
```

#### 自定义可滚动区域

```cpp
class MyScrollArea : public QAbstractScrollArea {
public:
    MyScrollArea(QWidget *parent = nullptr) {
        setViewport(new QWidget);
        // 设置内容大小，手动控制滚动
        viewport()->setMinimumSize(1000, 1000);
    }

protected:
    void paintEvent(QPaintEvent* event) override {
        QPainter p(viewport());
        p.drawText(10, 20, "Hello Scroll Area");
    }

    void scrollContentsBy(int dx, int dy) override {
        viewport()->scroll(dx, dy);
    }
};
```

### QTextEdit

`QTextEdit` 是 Qt 提供的一个功能强大的**富文本编辑控件**，支持编辑和显示 HTML、富文本（Rich Text）、纯文本，并具有内建的滚动条和多种文本格式控制能力。它是继承自 `QAbstractScrollArea` 的子类，适合用于需要用户输入或展示大量格式化文本的场景。

#### 常用构造函数

```cpp
QTextEdit(QWidget *parent = nullptr);
QTextEdit(const QString &text, QWidget *parent = nullptr); // 设置初始内容
```

#### 设置和获取内容

设置内容

```cpp
textEdit->setPlainText("纯文本内容");
textEdit->setHtml("<b>加粗文本</b>");
```

获取内容

```cpp
QString plain = textEdit->toPlainText();  // 获取纯文本
QString html = textEdit->toHtml();        // 获取富文本（HTML 格式）
```

#### 文本格式设置

```cpp
textEdit->setFont(QFont("Courier New", 12));
textEdit->setTextColor(Qt::blue);
textEdit->setAlignment(Qt::AlignCenter);
```

也可以用光标对象 (`QTextCursor`) 精确控制插入和格式：

```cpp
QTextCursor cursor = textEdit->textCursor();
cursor.insertText("插入文字");
```

Qt `QTextEdit` 文本格式控制综合表：

| 🎯 作用范围              | 🎨 格式项     | 🛠️ 设置函数（所属类）                           |
| ----------------------- | ------------ | ---------------------------------------------- |
| 字符（选区或光标）      | 字体         | `QTextCharFormat::setFont(QFont)`              |
|                         | 字体族       | `QTextCharFormat::setFontFamily(QString)`      |
|                         | 字号（磅）   | `QTextCharFormat::setFontPointSize(qreal)`     |
|                         | 加粗         | `QTextCharFormat::setFontWeight(int)`          |
|                         | 斜体         | `QTextCharFormat::setFontItalic(bool)`         |
|                         | 下划线       | `QTextCharFormat::setFontUnderline(bool)`      |
|                         | 删除线       | `QTextCharFormat::setFontStrikeOut(bool)`      |
|                         | 字体颜色     | `QTextCharFormat::setForeground(QBrush)`       |
|                         | 背景色       | `QTextCharFormat::setBackground(QBrush)`       |
|                         | 字间距       | `QTextCharFormat::setFontLetterSpacing(qreal)` |
|                         | 超链接       | `setAnchor(true)` + `setAnchorHref(QString)`   |
|                         | 应用字符样式 | `QTextCursor::mergeCharFormat(format)`         |
| 新输入文本（默认格式）  | 字体颜色     | `QTextEdit::setTextColor(QColor)`              |
|                         | 字号（磅）   | `QTextEdit::setFontPointSize(qreal)`           |
|                         | 当前字体     | `QTextEdit::setCurrentFont(QFont)`             |
| 段落（光标所在行/选段） | 对齐方式     | `QTextEdit::setAlignment(Qt::AlignmentFlag)`   |

#### 滚动条控制（继承自 QAbstractScrollArea）

```cpp
textEdit->setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
textEdit->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
```

#### 查找文本

```cpp
// 向前查找（默认是向后）
bool found = textEdit->find("目标文本", QTextDocument::FindBackward);

// 区分大小写查找
bool found = textEdit->find("目标文本", QTextDocument::FindCaseSensitively);

// 向前查找 + 区分大小写
bool found = textEdit->find("目标文本", 
                QTextDocument::FindBackward | QTextDocument::FindCaseSensitively);
```

支持方向查找、大小写敏感等选项。

| 标志                  | 含义               |
| --------------------- | ------------------ |
| `FindBackward`        | 向文档前方向查找   |
| `FindCaseSensitively` | 区分大小写查找     |
| `FindWholeWords`      | 全字匹配（非子串） |

可以使用 `|` 运算符组合多个标志。

#### 编辑行为控制

```cpp
textEdit->setReadOnly(true);      // 设置只读
textEdit->setUndoRedoEnabled(true); // 开启撤销重做
textEdit->setWordWrapMode(QTextOption::WordWrap); // 设置自动换行
```

#### 示例：简易文本编辑器

##### widget.ui

```css
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>Widget</class>
 <widget class="QWidget" name="Widget">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>410</width>
    <height>300</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <widget class="QWidget" name="verticalLayoutWidget">
   <property name="geometry">
    <rect>
     <x>0</x>
     <y>10</y>
     <width>403</width>
     <height>221</height>
    </rect>
   </property>
   <layout class="QVBoxLayout" name="verticalLayout">
    <item>
     <layout class="QHBoxLayout" name="horizontalLayout">
      <item>
       <widget class="QPushButton" name="btnBold">
        <property name="text">
         <string>粗体</string>
        </property>
       </widget>
      </item>
      <item>
       <widget class="QPushButton" name="btnItalic">
        <property name="text">
         <string>斜体</string>
        </property>
       </widget>
      </item>
      <item>
       <widget class="QPushButton" name="btnUnderline">
        <property name="text">
         <string>下划线</string>
        </property>
       </widget>
      </item>
      <item>
       <widget class="QPushButton" name="btnColor">
        <property name="text">
         <string>前景色</string>
        </property>
       </widget>
      </item>
      <item>
       <widget class="QPushButton" name="btnBGColor">
        <property name="text">
         <string>背景色</string>
        </property>
       </widget>
      </item>
     </layout>
    </item>
    <item>
     <layout class="QHBoxLayout" name="horizontalLayout_2">
      <item>
       <widget class="QLabel" name="lblFontSize">
        <property name="text">
         <string>字号</string>
        </property>
       </widget>
      </item>
      <item>
       <widget class="QLineEdit" name="edtFontSize"/>
      </item>
      <item>
       <widget class="QLabel" name="lblFontBox">
        <property name="text">
         <string>字体</string>
        </property>
       </widget>
      </item>
      <item>
       <widget class="QFontComboBox" name="fontBox"/>
      </item>
     </layout>
    </item>
    <item>
     <widget class="QTextEdit" name="txtEdt"/>
    </item>
   </layout>
  </widget>
 </widget>
 <resources/>
 <connections/>
</ui>
```

##### widget.h

```cpp
#ifndef WIDGET_H
#define WIDGET_H

#include <QTextCharFormat> // 文本格式类
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
    void on_btnItalic_clicked(bool checked);
    void on_btnBold_clicked(bool checked);
    void on_btnUnderline_clicked(bool checked);
    void on_btnColor_clicked();
    void on_btnBGColor_clicked();
    void on_edtFontSize_editingFinished();
    void on_txtEdt_currentCharFormatChanged(const QTextCharFormat& format);
    void on_txtEdt_textChanged();

private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

##### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QColorDialog>

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 设置按钮为可切换状态（点击后可保持按下或弹起）
    ui->btnBold->setCheckable(true);
    ui->btnItalic->setCheckable(true);
    ui->btnUnderline->setCheckable(true);

    // 设置字号输入框为只能输入 0~72 的整数
    QIntValidator* vali = new QIntValidator(0, 72);
    ui->edtFontSize->setValidator(vali);

    // 设置默认字号为 9
    ui->edtFontSize->setText(QString::number(9));

    // 字体下拉框内容变化时设置 QTextEdit 的字体家族（用户选择字体时触发）
    connect(ui->fontBox, &QFontComboBox::currentTextChanged, ui->txtEdt, &QTextEdit::setFontFamily);

    // 初始化富文本内容（显示各种字体效果）
    ui->txtEdt->setHtml("<b>粗体字的行<br></b>"
                        "<i>斜体字的行<br></i>"
                        "<u>下划线的行<br></u>"
                        "<font style=\"color:red;\">文本前景色<br></font>"
                        "<font style=\"background:yellow;\">文字背景色<br></font>"
                        "<font style=\"font-size:18pt;\">字号大小变化的行<br></font>"
                        "<font style=\"font-family:黑体;\">字体家族变化的行<br></font>");
}

Widget::~Widget() {
    delete ui;
}

// ✔ 粗体按钮点击时触发（无论是用户点击或代码 setChecked 都会触发）
void Widget::on_btnBold_clicked(bool checked) {
    if (checked)
        ui->txtEdt->setFontWeight(QFont::Bold);
    else
        ui->txtEdt->setFontWeight(QFont::Normal);
}

// ✔ 斜体按钮点击时触发（设置当前字体是否为斜体）
void Widget::on_btnItalic_clicked(bool checked) {
    ui->txtEdt->setFontItalic(checked);
}

// ✔ 下划线按钮点击时触发（设置当前字体是否有下划线）
void Widget::on_btnUnderline_clicked(bool checked) {
    ui->txtEdt->setFontUnderline(checked);
}

// ✔ 当前槽函数在点击“前景色”按钮时触发（即按钮的 clicked() 信号）
// 功能：弹出颜色选择对话框，获取用户选取的颜色，
// 如果颜色有效，则将该颜色设置为 QTextEdit 当前选中文本（或光标处后续输入）的前景色（文字颜色）
// 同时，把该颜色同步显示在按钮的背景上，作为视觉提示
void Widget::on_btnColor_clicked() {
    // 弹出 QColorDialog 颜色选择对话框，默认颜色为黑色
    QColor clr = QColorDialog::getColor(Qt::black);

    // 判断用户是否选择了有效颜色（点击“取消”则颜色无效）
    if (clr.isValid()) {
        // 设置 QTextEdit 中当前光标所在位置（或选中文本）的前景色为用户选择的颜色
        // 如果没有选中文本，则设置的是“插入格式”，即后续输入的文字将采用该颜色
        ui->txtEdt->setTextColor(clr);

        // 构造用于设置按钮样式的字符串，比如 "color: #ff0000"
        QString str = tr("color: %1").arg(clr.name());

        // 设置按钮的样式，使按钮上显示的颜色和选中的前景色保持一致（增强交互感）
        ui->btnColor->setStyleSheet(str);
    }
}

// ✔ 背景色按钮点击时触发（弹出颜色选择对话框，设置字体背景色）
void Widget::on_btnBGColor_clicked() {
    QColor bgclr = QColorDialog::getColor(Qt::white);
    if (bgclr.isValid()) {
        ui->txtEdt->setTextBackgroundColor(bgclr);
        // 同步按钮颜色样式显示
        QString str = tr("background: %1").arg(bgclr.name());
        ui->btnBGColor->setStyleSheet(str);
    }
}

// ✔ 用户在字体大小输入框中编辑完成（按下 Enter 或焦点移出）时触发
void Widget::on_edtFontSize_editingFinished() {
    int fontSize = ui->edtFontSize->text().toInt();
    ui->txtEdt->setFontPointSize(fontSize);
}

// ✔ QTextEdit 中文本光标位置发生变化时触发（用于同步更新按钮状态和样式）
void Widget::on_txtEdt_currentCharFormatChanged(const QTextCharFormat& format) {
    // 同步加粗按钮状态
    if (format.fontWeight() == QFont::Bold)
        ui->btnBold->setChecked(true);
    else
        ui->btnBold->setChecked(false);

    // 同步斜体、下划线按钮状态
    ui->btnItalic->setChecked(format.fontItalic());
    ui->btnUnderline->setChecked(format.fontUnderline());

    // 当 QTextEdit 的光标位置变化，或选中的字符格式发生变化时，更新“前景色”按钮的样式显示，使其反映当前文字的前景色（字体颜色）
    // 获取当前字符格式中的前景色信息（即文字颜色）
    // foreground() 返回的是一个 QBrush 类型，可能包含颜色、渐变等信息
    QBrush brushText = format.foreground();

    // 判断 brushText 是否有效（非空画刷）
    // Qt::NoBrush 表示未设置颜色；此处要避免在按钮上显示无效颜色
    if (brushText != Qt::NoBrush) {
        // 提取画刷中的颜色值（QColor 类型）
        QColor clrText = brushText.color();

        // 构造用于设置按钮样式的字符串，如 "color: #ff0000"
        // 这里使用的是 CSS 样式格式，让按钮文字颜色与当前光标文本颜色一致
        QString str = tr("color: %1").arg(clrText.name());

        // 设置“前景色”按钮的样式，使其显示当前字体颜色（文字变色，增强交互体验）
        ui->btnColor->setStyleSheet(str);
    } else {
        // 如果没有设置前景色（例如默认样式），则清空按钮样式，使其恢复原状
        ui->btnColor->setStyleSheet("");
    }

    // 更新背景色按钮显示样式
    QBrush brushBG = format.background();
    if (brushBG != Qt::NoBrush) {
        QColor clrBG = brushBG.color();
        QString str = tr("background: %1").arg(clrBG.name());
        ui->btnBGColor->setStyleSheet(str);
    } else {
        ui->btnBGColor->setStyleSheet("");
    }

    // 同步字体大小到输入框
    QFont curFont = format.font();
    int fontSize = curFont.pointSize();
    if (-1 == fontSize) fontSize = (int)(curFont.pixelSize() * 9.0 / 12.0); // 兼容某些格式
    ui->edtFontSize->setText(QString::number(fontSize));

    // 同步字体家族到下拉框
    QString strFontFamily = curFont.family();
    ui->fontBox->setCurrentText(strFontFamily);
}

// ✔ QTextEdit 文本变化时触发（内容有任何编辑都会调用，主要用于调试）
void Widget::on_txtEdt_textChanged() {
    qDebug() << ui->txtEdt->toHtml() << Qt::endl;
}
```

当前的代码中，所有调用诸如 `setFontItalic`、`setFontWeight`、`setTextColor`、`setFontPointSize` 等方法，**作用对象是 QTextEdit 的“光标当前选中的文本”**。

Qt 中的 `QTextEdit` 提供这类方法时，都是**基于当前 QTextCursor 的选择范围**进行设置的。

例如：

- `ui->txtEdt->setFontItalic(true);`
- `ui->txtEdt->setTextColor(clr);`
- `ui->txtEdt->setFontPointSize(18);`

这些方法的行为是：

> 如果有选中的文本，就修改选中部分的格式；
>  如果没有选中任何文本，就设置“当前光标位置后输入的文本”的格式（插入符号样式），但**不会影响已有文本**。

### QTextBrowser

#### 与 QTextEdit 的主要区别

| 特性       | QTextEdit                  | QTextBrowser                           |
| ---------- | -------------------------- | -------------------------------------- |
| 继承关系   | 基类                       | 继承自 QTextEdit                       |
| 主要功能   | 文本编辑（支持富文本格式） | 富文本浏览（只读，带超链接支持）       |
| 是否可编辑 | 默认可编辑                 | 默认只读                               |
| 支持的内容 | 支持文本输入和编辑         | 支持富文本显示，超链接自动处理         |
| 浏览功能   | 无浏览历史、无前进后退导航 | 支持超链接导航、历史记录、前进后退功能 |
| 超链接支持 | 需要自己处理               | 内置对超链接的自动处理和打开支持       |
| 应用场景   | 文本编辑器、富文本编辑控件 | HTML 内容浏览器、帮助文档查看器        |

#### 示例：简易 HTML 查看器

##### widget.h

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

private slots:
    void on_btnOpen_clicked();
    void on_textBrowser_backwardAvailable(bool arg1);
    void on_textBrowser_forwardAvailable(bool arg1);
    void on_textBrowser_textChanged();

private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

##### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QFileDialog>
#include <QUrl>

// 构造函数：初始化 UI 组件并连接信号与槽函数
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 设置 UI

    ui->plainTextEdit->setReadOnly(true);        // 设置 plainTextEdit 为只读，用于显示 HTML 源码
    ui->textBrowser->setOpenExternalLinks(true); // 启用超链接的外部打开功能（在浏览器中打开）
    ui->btnBackward->setEnabled(false);          // 初始化时“后退”按钮禁用
    ui->btnForward->setEnabled(false);           // 初始化时“前进”按钮禁用

    // 连接按钮点击信号与 QTextBrowser 的后退/前进槽函数
    connect(ui->btnBackward, &QPushButton::clicked, ui->textBrowser, &QTextBrowser::backward);
    connect(ui->btnForward, &QPushButton::clicked, ui->textBrowser, &QTextBrowser::forward);
}

// 析构函数：释放 UI 资源
Widget::~Widget() {
    delete ui;
}

// 打开按钮点击事件：选择 HTML 文件并加载到 QTextBrowser 中
void Widget::on_btnOpen_clicked() {
    // 使用 QFileDialog 打开一个文件选择对话框，获取用户选择的 HTML 文件的 URL
    // 参数说明：
    // 1. this：父窗口指针，指定这个对话框的父对象为当前 Widget，确保对话框在当前窗口之上弹出
    // 2. "open HTML"：对话框标题，用于提示用户当前操作是“打开 HTML 文件”
    // 3. QUrl()：初始路径，传入空 QUrl 表示使用默认目录（可用 QUrl::fromLocalFile("路径") 指定初始目录）
    // 4. "HTML files(*.htm *.html)"：过滤器字符串，仅显示 *.htm 和 *.html 后缀的文件
    QUrl urlFile = QFileDialog::getOpenFileUrl(this, "open HTML", QUrl(), "HTML files(*.htm *.html)");

    // 判断用户是否实际选择了文件（即返回的 URL 非空）
    if (!urlFile.isEmpty()) {
        qDebug() << urlFile;                 // 输出选择的文件 URL，用于调试
        ui->textBrowser->setSource(urlFile); // 将选择的 HTML 文件加载到 QTextBrowser 中显示
    }
}

// 当 textBrowser 可以后退时，启用“后退”按钮
void Widget::on_textBrowser_backwardAvailable(bool arg1) {
    ui->btnBackward->setEnabled(arg1);
}

// 当 textBrowser 可以前进时，启用“前进”按钮
void Widget::on_textBrowser_forwardAvailable(bool arg1) {
    ui->btnForward->setEnabled(arg1);
}

// 当 textBrowser 内容变化时，更新 plainTextEdit 显示 HTML 源码
void Widget::on_textBrowser_textChanged() {
    QString strHtml = ui->textBrowser->toHtml(); // 获取 HTML 内容
    ui->plainTextEdit->setPlainText(strHtml);    // 显示在 plainTextEdit 中
}
```

