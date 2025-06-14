## 通用对话框：QColorDialog、QFontDialog、QInputDialog

### QColorDialog

`QColorDialog` 是 Qt 提供的标准颜色选择对话框类，允许用户通过图形界面选择颜色。在图像编辑、文本颜色设置、界面个性化等场景中广泛使用。

#### 使用方式

##### 静态函数（最常用）

```cpp
QColor selectedColor = QColorDialog::getColor(Qt::white, this, "选择颜色");
if (selectedColor.isValid()) {
    // 使用选中的颜色
}
```

参数说明：

- `Qt::white`：初始颜色。
- `this`：父窗口指针。
- `"选择颜色"`：对话框标题。

##### 创建实例（适用于自定义行为）

```cpp
QColorDialog *dlg = new QColorDialog(this);
dlg->setCurrentColor(Qt::blue);
dlg->setOption(QColorDialog::ShowAlphaChannel); // 显示透明度选项
connect(dlg, &QColorDialog::colorSelected, this, &YourClass::onColorChosen);
dlg->open(); // 非模态
```

#### 主要函数和选项

| 成员函数/选项                         | 说明                             |
| ------------------------------------- | -------------------------------- |
| `getColor()`                          | 弹出颜色对话框并返回颜色（模态） |
| `currentColor()`                      | 获取当前选择的颜色               |
| `selectedColor()`                     | 获取最终选择的颜色               |
| `setCurrentColor(const QColor &)`     | 设置初始颜色                     |
| `setOption(QColorDialog::Option)`     | 设置对话框行为（如显示透明度）   |
| `open()`                              | 非模态显示对话框                 |
| `exec()`                              | 模态显示并阻塞等待               |
| `colorSelected(const QColor &)`       | 用户点击“确定”时发送的信号       |
| `currentColorChanged(const QColor &)` | 实时改变颜色时发送的信号         |

#### 常用选项（`QColorDialog::Option`）

| 枚举值                | 说明                               |
| --------------------- | ---------------------------------- |
| `ShowAlphaChannel`    | 显示透明度通道                     |
| `NoButtons`           | 不显示“确定/取消”按钮              |
| `DontUseNativeDialog` | 使用 Qt 自绘界面而非平台原生对话框 |

#### 示例：带透明度的颜色选择器

```cpp
QColorDialog dlg(this);
dlg.setOption(QColorDialog::ShowAlphaChannel);
dlg.setCurrentColor(Qt::red);

if (dlg.exec() == QDialog::Accepted) {
    QColor color = dlg.selectedColor();
    // 使用颜色 color
}
```

#### 注意事项

- `getColor()` 是阻塞式调用，适用于简单使用场景。
- `open()` 配合信号槽更灵活，适合复杂交互。
- `selectedColor()` 只有在用户点击“确定”后才有效。
- 使用 `DontUseNativeDialog` 可确保在所有平台表现一致。

### QFont

`QFont` 是 Qt 中用于描述字体属性的类，它封装了字体的**家族（family）**、**大小（point size）**、**粗细（weight）**、**斜体（italic）**、**下划线（underline）**等信息，可用于设置界面控件的字体样式，比如 `QLabel`、`QTextEdit`、`QPushButton` 等。

#### 常用构造函数

```cpp
QFont(); // 使用默认字体
QFont(const QString &family, int pointSize = -1, int weight = -1, bool italic = false);
```

示例：

```cpp
QFont font("Arial", 12, QFont::Bold, true); // Arial，12pt，加粗，斜体
```

#### 常用设置函数

| 方法                     | 说明                                |
| ------------------------ | ----------------------------------- |
| `setFamily(QString)`     | 设置字体家族                        |
| `setPointSize(int)`      | 设置字体大小（pt）                  |
| `setPixelSize(int)`      | 设置字体大小（像素）                |
| `setBold(bool)`          | 设置加粗                            |
| `setItalic(bool)`        | 设置斜体                            |
| `setUnderline(bool)`     | 设置下划线                          |
| `setStrikeOut(bool)`     | 设置删除线                          |
| `setWeight(int)`         | 设置字体权重（粗细）                |
| `setStyle(QFont::Style)` | 设置风格（Normal、Italic、Oblique） |
| `setFixedPitch(bool)`    | 是否为等宽字体                      |

#### 示例代码

##### 设置控件字体

```cpp
QFont font("Courier New", 10);
font.setItalic(true);
font.setBold(true);
ui->textEdit->setFont(font);
```

##### 动态调整大小

```cpp
QFont font = ui->label->font();
font.setPointSize(font.pointSize() + 2);
ui->label->setFont(font);
```

#### 读取字体信息

| 方法          | 说明             |
| ------------- | ---------------- |
| `family()`    | 获取字体家族名   |
| `pointSize()` | 获取字体 pt 大小 |
| `pixelSize()` | 获取像素大小     |
| `bold()`      | 是否加粗         |
| `italic()`    | 是否斜体         |
| `underline()` | 是否下划线       |
| `weight()`    | 返回字体权重     |
| `style()`     | 返回字体风格     |

#### 权重值 QFont::Weight

| 枚举值            | 效果         |
| ----------------- | ------------ |
| `QFont::Thin`     | 极细         |
| `QFont::Light`    | 细           |
| `QFont::Normal`   | 正常（默认） |
| `QFont::DemiBold` | 半粗         |
| `QFont::Bold`     | 加粗         |
| `QFont::Black`    | 极粗         |

### QFontDialog

`QFontDialog` 是 Qt 提供的标准字体选择对话框，用于让用户选择字体家族、样式、大小等属性。它通常用于文本编辑器、富文本控件、绘图工具等场景中。

#### 使用方式

##### 静态函数（最常见）

```cpp
bool ok;
QFont font = QFontDialog::getFont(&ok, this);
if (ok) {
    // 使用用户选择的字体
}
```

#### 参数说明：

- `&ok`：返回值，表示用户是否点击“确定”。
- `this`：父窗口。

也可以设置初始字体：

```cpp
QFont initialFont("Arial", 12);
QFont font = QFontDialog::getFont(&ok, initialFont, this, "选择字体");
```

##### 非模态使用（更灵活）

```cpp
QFontDialog *dialog = new QFontDialog(this);
dialog->setCurrentFont(QFont("Courier", 10));
dialog->setOption(QFontDialog::NoButtons); // 不显示“确定/取消”按钮
connect(dialog, &QFontDialog::currentFontChanged, this, &YourClass::onFontChanged);
dialog->open(); // 非模态显示
```

#### 主要函数和信号

| 函数 / 信号                                | 说明                           |
| ------------------------------------------ | ------------------------------ |
| `getFont(bool *ok, ...)`                   | 静态模态调用，返回用户选择字体 |
| `setCurrentFont(const QFont &)`            | 设置默认显示字体               |
| `currentFont()`                            | 获取当前选择的字体             |
| `selectedFont()`                           | 获取最终选中的字体             |
| `setOption(QFontDialog::FontDialogOption)` | 设置附加选项                   |
| `currentFontChanged(const QFont &)`        | 当前字体变化时发出             |
| `fontSelected(const QFont &)`              | 用户点击“确定”时发出           |

#### 选项设置（`QFontDialog::FontDialogOption`）

| 枚举值                | 说明                                   |
| --------------------- | -------------------------------------- |
| `NoButtons`           | 不显示“确定/取消”按钮（实时生效）      |
| `DontUseNativeDialog` | 使用 Qt 自定义样式对话框而非原生对话框 |
| `MonospacedFonts`     | 仅显示等宽字体                         |
| `ProportionalFonts`   | 仅显示非等宽字体                       |
| `ScalableFonts`       | 显示可缩放字体                         |
| `NonScalableFonts`    | 显示不可缩放字体                       |
| `NoFontMerging`       | 禁止自动字体合并（高级用途）           |

#### 示例代码

##### 模态调用示例

```cpp
bool ok;
QFont font = QFontDialog::getFont(&ok, QFont("Arial", 10), this, "选择字体");
if (ok) {
    ui->textEdit->setFont(font);
}
```

##### 非模态 + 信号槽

```cpp
QFontDialog *dlg = new QFontDialog(this);
connect(dlg, &QFontDialog::fontSelected, this, &YourWidget::applyFont);
dlg->open();
```

#### 注意事项

- 非模态方式（`open()`）适合复杂界面交互，结合信号使用更灵活。
- 使用 `DontUseNativeDialog` 可获得跨平台一致体验。
- `selectedFont()` 仅在点击“确定”后才有效。

### QInputDialog

`QInputDialog` 是 Qt 提供的一个**标准输入对话框类**，用于获取用户简单输入，如字符串、整数、浮点数或从列表中选择一个选项。它无需自定义 UI，非常适合快速交互。

#### 基本用途

`QInputDialog` 提供多种静态函数用于弹出对话框并返回用户输入结果，常见包括：

- `getText()`：获取文本字符串
- `getInt()`：获取整数
- `getDouble()`：获取浮点数
- `getItem()`：从下拉列表中选择一项

#### 常用静态方法详解

##### 获取文本（字符串）

```cpp
QString QInputDialog::getText(
    QWidget *parent,
    const QString &title,
    const QString &label,
    QLineEdit::EchoMode mode = QLineEdit::Normal,
    const QString &text = QString(),
    bool *ok = nullptr,
    Qt::WindowFlags flags = Qt::WindowFlags()
);
```

示例：

```cpp
bool ok;
QString name = QInputDialog::getText(this, "输入名字", "请输入您的姓名：", QLineEdit::Normal, "", &ok);
if (ok && !name.isEmpty()) {
    ui->label->setText("你好，" + name);
}
```

##### 获取整数

```cpp
int QInputDialog::getInt(
    QWidget *parent,
    const QString &title,
    const QString &label,
    int value = 0,
    int min = -2147483647,
    int max = 2147483647,
    int step = 1,
    bool *ok = nullptr,
    Qt::WindowFlags flags = Qt::WindowFlags()
);
```

示例：

```cpp
bool ok;
int age = QInputDialog::getInt(this, "年龄输入", "请输入年龄：", 18, 0, 150, 1, &ok);
if (ok) {
    ui->label->setText(QString("年龄：%1").arg(age));
}
```

##### 获取浮点数

```cpp
double QInputDialog::getDouble(
    QWidget *parent,
    const QString &title,
    const QString &label,
    double value = 0,
    double min = -2147483647,
    double max = 2147483647,
    int decimals = 1,
    bool *ok = nullptr,
    Qt::WindowFlags flags = Qt::WindowFlags()
);
```

示例：

```cpp
bool ok;
double price = QInputDialog::getDouble(this, "价格输入", "请输入价格：", 9.99, 0.0, 10000.0, 2, &ok);
if (ok) {
    ui->label->setText(QString("价格为：%1 元").arg(price));
}
```

##### 获取枚举项（从列表选择）

```cpp
QString QInputDialog::getItem(
    QWidget *parent,
    const QString &title,
    const QString &label,
    const QStringList &items,
    int current = 0,
    bool editable = true,
    bool *ok = nullptr,
    Qt::WindowFlags flags = Qt::WindowFlags()
);
```

示例：

```cpp
QStringList colors = {"红色", "绿色", "蓝色"};
bool ok;
QString color = QInputDialog::getItem(this, "颜色选择", "请选择颜色：", colors, 0, false, &ok);
if (ok && !color.isEmpty()) {
    ui->label->setText("您选择了：" + color);
}
```

#### 注意事项

| 特性                     | 说明                   |
| ------------------------ | ---------------------- |
| 所有方法均为静态         | 可直接调用             |
| 返回值通常配合 `ok` 检查 | 避免用户取消后误用数据 |
| 可设置默认值和范围       | 限定用户输入范围       |
| 支持编辑或非编辑下拉     | 提高灵活性             |

#### 小例子组合应用

```cpp
QString name = QInputDialog::getText(this, "注册", "请输入用户名：");
int age = QInputDialog::getInt(this, "注册", "请输入年龄：");
QStringList levels = {"初级", "中级", "高级"};
QString level = QInputDialog::getItem(this, "注册", "请选择等级：", levels);
```

### 示例：自定义标签

#### widgetcustomizelabel.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>WidgetCustomizeLabel</class>
 <widget class="QWidget" name="WidgetCustomizeLabel">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>400</width>
    <height>300</height>
   </rect>
  </property>
  <property name="sizePolicy">
   <sizepolicy hsizetype="Expanding" vsizetype="Expanding">
    <horstretch>0</horstretch>
    <verstretch>0</verstretch>
   </sizepolicy>
  </property>
  <property name="windowTitle">
   <string>WidgetCustomizeLabel</string>
  </property>
  <layout class="QHBoxLayout" name="horizontalLayout" stretch="4,1">
   <item>
    <widget class="QLabel" name="labelSample">
     <property name="text">
      <string>显示样例</string>
     </property>
    </widget>
   </item>
   <item>
    <layout class="QVBoxLayout" name="verticalLayout">
     <item>
      <widget class="QPushButton" name="pushButtonForeground">
       <property name="text">
        <string>设置前景色</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonBackground">
       <property name="text">
        <string>设置背景色</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonFont">
       <property name="text">
        <string>设置字体</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonText">
       <property name="text">
        <string>设置文本</string>
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

#### widgetcustomizelabel.h

```cpp
#ifndef WIDGETCUSTOMIZELABEL_H
#define WIDGETCUSTOMIZELABEL_H

#include <QColorDialog>
#include <QFontDialog>
#include <QInputDialog>
#include <QWidget>

QT_BEGIN_NAMESPACE
namespace Ui {
class WidgetCustomizeLabel;
}
QT_END_NAMESPACE

// 自定义控件类：用于实时调整 QLabel 的样式，如字体、前景色、背景色、文本等
class WidgetCustomizeLabel : public QWidget {
    Q_OBJECT

  public:
    // 构造函数，初始化界面和控件
    WidgetCustomizeLabel(QWidget* parent = nullptr);
    // 析构函数，释放资源
    ~WidgetCustomizeLabel();

  public slots:
    // 自定义槽函数：接收颜色变化信号，动态设置前景色
    void recvAndSetForegroundColor(QColor color);

  private slots:
    // 点击“前景色”按钮触发的槽函数，显示颜色选择对话框
    void on_pushButtonForeground_clicked();

    // 点击“背景色”按钮触发的槽函数，弹出颜色对话框并应用背景色
    void on_pushButtonBackground_clicked();

    // 点击“字体”按钮触发的槽函数，打开字体选择对话框
    void on_pushButtonFont_clicked();

    // 点击“文本”按钮触发的槽函数，弹出多行输入对话框修改文本
    void on_pushButtonText_clicked();

  private:
    Ui::WidgetCustomizeLabel* ui; // UI 控件对象指针
    QColor m_clrForeground;       // 保存前景色（字体颜色）
    QColor m_clrBackground;       // 保存背景色
    QFont m_font;                 // 保存当前字体样式
    QString m_strText;            // 保存标签显示的文本

    QColorDialog* m_pDlgForeground; // 自定义的颜色选择对话框（用于前景色）

    void init(); // 初始化函数，设置默认样式并连接信号槽
};

#endif // WIDGETCUSTOMIZELABEL_H
```

#### widgetcustomizelabel.cpp

```cpp
#include "widgetcustomizelabel.h"
#include "./ui_widgetcustomizelabel.h"
#include <QDebug>

// 构造函数
WidgetCustomizeLabel::WidgetCustomizeLabel(QWidget* parent) : QWidget(parent), ui(new Ui::WidgetCustomizeLabel) {
    ui->setupUi(this); // 初始化 UI
    init();            // 初始化逻辑
}

// 析构函数，释放资源
WidgetCustomizeLabel::~WidgetCustomizeLabel() {
    delete m_pDlgForeground; // 释放前景色对话框资源
    m_pDlgForeground = nullptr;
    delete ui;
}

// 初始化函数
void WidgetCustomizeLabel::init() {
    // 设置默认背景色为浅灰色，前景色为黑色
    m_clrBackground = QColor(240, 240, 240);
    m_clrForeground = QColor(0, 0, 0);
    m_strText = tr("显示样例"); // 默认显示文本

    // 创建颜色选择对话框，用于选择前景色
    m_pDlgForeground = new QColorDialog(this);
    m_pDlgForeground->setOptions(QColorDialog::NoButtons); // 去除对话框按钮
    m_pDlgForeground->setModal(false);                     // 设置为非模态（不阻塞主窗口）

    // 当颜色发生变化时，更新标签前景色
    connect(m_pDlgForeground, &QColorDialog::currentColorChanged, this, &WidgetCustomizeLabel::recvAndSetForegroundColor);
}

// 点击“前景色”按钮，弹出颜色选择对话框
void WidgetCustomizeLabel::on_pushButtonForeground_clicked() {
    m_pDlgForeground->show();  // 显示对话框
    m_pDlgForeground->raise(); // 提升窗口层级，防止被遮挡
}

// 点击“背景色”按钮，使用静态函数获取颜色
void WidgetCustomizeLabel::on_pushButtonBackground_clicked() {
    QColor clr = QColorDialog::getColor(); // 弹出颜色选择框
    if (!clr.isValid()) return;            // 用户取消则不处理

    m_clrBackground = clr; // 保存新背景色

    // 设置 label 的样式表（前景 + 背景）
    QString strQSS = tr("color: %1; background-color: %2;").arg(m_clrForeground.name()).arg(m_clrBackground.name());
    ui->labelSample->setStyleSheet(strQSS);
}

// 点击“字体”按钮，弹出字体选择对话框
void WidgetCustomizeLabel::on_pushButtonFont_clicked() {
    bool bOK = false;
    QFont ft = QFontDialog::getFont(&bOK, m_font); // 获取字体
    if (!bOK) return;                              // 用户取消则不处理

    m_font = ft;                      // 保存新字体
    ui->labelSample->setFont(m_font); // 应用新字体到 label
}

// 点击“文本”按钮，弹出多行文本输入框
void WidgetCustomizeLabel::on_pushButtonText_clicked() {
    bool bOK = false;
    QString strText = QInputDialog::getMultiLineText(this, tr("设置文本"), tr("请输入文本："), m_strText, &bOK);
    if (!bOK) return; // 用户取消则不处理

    m_strText = strText;                 // 保存文本
    ui->labelSample->setText(m_strText); // 显示新文本
}

// 槽函数：接收前景色并更新 label 样式
void WidgetCustomizeLabel::recvAndSetForegroundColor(QColor color) {
    if (!color.isValid()) return; // 判断颜色合法性

    m_clrForeground = color; // 保存新前景色

    // 应用前景+背景样式
    QString strQSS = tr("color: %1; background-color: %2;").arg(m_clrForeground.name()).arg(m_clrBackground.name());
    ui->labelSample->setStyleSheet(strQSS);
}
```