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

#### 示例：创建一个富文本编辑器

```cpp
QTextEdit *textEdit = new QTextEdit(this);
textEdit->setHtml("<h2>欢迎使用 <i>QTextEdit</i></h2><p>支持<b>富文本</b>和<font color='red'>颜色</font></p>");
textEdit->setFont(QFont("Arial", 12));
textEdit->setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
```

