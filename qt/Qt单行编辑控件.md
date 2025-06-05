## Qt 单行编辑控件

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

| 类名               | 单行/多行 | 纯文本/富文本 | 编辑/只读 | 滚动条支持 | 主要用途                                   |
| ------------------ | --------- | ------------- | --------- | ---------- | ------------------------------------------ |
| **QLineEdit**      | 单行      | 纯文本        | 编辑      | 无         | 短文本输入，如表单、搜索框                 |
| **QPlainTextEdit** | 多行      | 纯文本        | 编辑      | 有         | 大文本、代码编辑、日志查看                 |
| **QTextEdit**      | 多行      | 富文本        | 编辑      | 有         | 富文本编辑器，邮件、文本排版               |
| **QTextBrowser**   | 多行      | 富文本        | 只读      | 有         | 富文本浏览，支持超链接，类似小型网页浏览器 |

### 常用接口表

| 功能类别      | 方法/属性                                       | 说明                                     |
| ------------- | ----------------------------------------------- | ---------------------------------------- |
| **文本操作**  | `text()`                                        | 获取当前文本内容                         |
|               | `setText(const QString &text)`                  | 设置文本内容                             |
|               | `clear()`                                       | 清空文本                                 |
|               | `insert(const QString &text)`                   | 在光标位置插入文本                       |
|               | `setPlaceholderText(const QString &text)`       | 设置占位符文本（灰色提示文字）           |
|               | `placeholderText()`                             | 获取占位符文本                           |
|               | `setMaxLength(int length)`                      | 设置文本最大长度                         |
|               | `maxLength()`                                   | 获取最大长度                             |
|               | `selectedText()`                                | 获取被选中的文本                         |
|               | `setSelection(int start, int length)`           | 选中指定范围的文本                       |
|               | `deselect()`                                    | 取消选中文本                             |
|               | `cursorPosition()`                              | 获取光标位置                             |
|               | `setCursorPosition(int position)`               | 设置光标位置                             |
|               | `home(bool mark = false)`                       | 光标移动到开头                           |
|               | `end(bool mark = false)`                        | 光标移动到结尾                           |
| **输入限制**  | `setInputMask(const QString &inputMask)`        | 设置输入掩码（格式限制）                 |
|               | `inputMask()`                                   | 获取输入掩码                             |
|               | `setValidator(const QValidator *validator)`     | 设置输入校验器（限制输入合法性）         |
|               | `validator()`                                   | 获取校验器                               |
| **编辑属性**  | `setReadOnly(bool)`                             | 设置是否只读                             |
|               | `isReadOnly()`                                  | 判断是否只读                             |
|               | `setEchoMode(QLineEdit::EchoMode)`              | 设置显示模式（普通文本、密码等）         |
|               | `echoMode()`                                    | 获取当前显示模式                         |
|               | `setAlignment(Qt::Alignment)`                   | 设置文本对齐方式                         |
|               | `alignment()`                                   | 获取文本对齐方式                         |
| **信号**      | `textChanged(const QString &)`                  | 文本内容改变时触发                       |
|               | `textEdited(const QString &)`                   | 用户编辑文本时触发（区别于程序设置文本） |
|               | `editingFinished()`                             | 编辑完成（回车或失焦触发）               |
|               | `returnPressed()`                               | 用户按回车键时触发                       |
|               | `selectionChanged()`                            | 选中文本改变时触发                       |
|               | `cursorPositionChanged(int oldPos, int newPos)` | 光标位置变化时触发                       |
| **撤销/重做** | `undo()`                                        | 撤销上一步操作                           |
|               | `redo()`                                        | 重做操作                                 |
|               | `isUndoAvailable()`                             | 是否可以撤销                             |
|               | `isRedoAvailable()`                             | 是否可以重做                             |

### EchoMode 枚举常用值

| 枚举值                          | 说明                       |
| ------------------------------- | -------------------------- |
| `QLineEdit::Normal`             | 普通文本显示               |
| `QLineEdit::NoEcho`             | 不显示文本（隐藏）         |
| `QLineEdit::Password`           | 密码模式，显示星号         |
| `QLineEdit::PasswordEchoOnEdit` | 编辑时显示明文，结束后隐藏 |

### 登录框示例

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

private slots:
    void on_loginBtn_clicked();
    void on_exitBtn_clicked();

private:
    Ui::Widget* ui;
    // 用户名字符串
    QString name;
    // 存储密码 hash 值
    QByteArray pwdHash;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"      // 自动生成的 UI 头文件，包含 ui 设计的控件定义
#include <QCryptographicHash> // 提供哈希算法支持（如 SHA3-256）
#include <QMessageBox>        // 用于弹出提示信息框

// 构造函数：初始化 UI 界面
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);                            // 设置 UI，连接 .ui 文件中的控件
    ui->pwdEdt->setEchoMode(QLineEdit::Password); // 设置密码输入框为“密码模式”，隐藏输入内容
}

// 析构函数：释放 UI 占用的资源
Widget::~Widget() {
    delete ui;
}

// 登录按钮点击槽函数
void Widget::on_loginBtn_clicked() {
    // 判断用户名或密码是否为空
    if (ui->userEdt->text().isEmpty() || ui->pwdEdt->text().isEmpty()) {
        // 弹出警告框提示
        QMessageBox::warning(this, tr("警告信息"), tr("用户名或密码为空，不能登录。"));
        return;
    }

    // 获取输入的用户名
    name = ui->userEdt->text();

    // 获取密码并进行 SHA3-256 哈希处理
    pwdHash = QCryptographicHash::hash(ui->pwdEdt->text().toUtf8(), QCryptographicHash::Sha3_256);

    // 构造用户信息字符串，使用 \r\n 实现换行（适用于 Windows）
    QString msg = tr("用户名：") + name + tr("\r\n") + tr("密码Hash：");
    msg.append(pwdHash.toHex()); // 转换为十六进制字符串显示

    qDebug() << msg;                                     // 在控制台输出调试信息
    QMessageBox::information(this, tr("用户信息"), msg); // 弹出信息框显示用户名和密码 Hash
}

// 退出按钮点击槽函数
void Widget::on_exitBtn_clicked() {
    this->close(); // 关闭主窗口
}
```

### 数据验证器和伙伴快捷键

进入伙伴编辑模式，将三个标签都设置为对应的单行编辑控件伙伴。

> 伙伴快捷键 = `QLabel` 中用 `&` 设置快捷键 + 配置 buddy 控件，按 `Alt + 键` 可以快速聚焦到 buddy 控件。

#### 数据验证器

Qt 中的数据验证主要通过继承自 `QValidator` 的类来实现，它是所有验证器的基类。

验证器可用于如 `QLineEdit`、`QComboBox` 等输入控件，通过 `setValidator()` 方法设置。

##### QIntValidator

限制输入为整数，并可设定范围。

```cpp
auto* validator = new QIntValidator(0, 65535, this);
lineEdit->setValidator(validator);
```

##### QDoubleValidator

限制输入为浮点数，并可设置小数点位数和范围。

```cpp
auto* validator = new QDoubleValidator(0.0, 100.0, 2, this);
validator->setNotation(QDoubleValidator::StandardNotation);
lineEdit->setValidator(validator);
```

##### QRegularExpressionValidator（Qt 6）

基于正则表达式的输入验证器（推荐使用，替代 Qt 5 的 QRegExpValidator）。

```cpp
QRegularExpression regex("[a-zA-Z0-9_]+");
auto* validator = new QRegularExpressionValidator(regex, this);
lineEdit->setValidator(validator);
```

> Qt 5 使用的是 `QRegExpValidator`，但它已被 Qt 6 弃用。

##### 验证状态

每个验证器在调用 `validate()` 时会返回一个 `QValidator::State`：

| 状态           | 含义                     |
| -------------- | ------------------------ |
| `Invalid`      | 无效输入                 |
| `Intermediate` | 输入尚未完成，但可能合法 |
| `Acceptable`   | 输入完全合法             |

开发者可以重载 `validate()` 方法自定义验证逻辑。

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

private slots:
    void on_ipEdt_textChanged(const QString& arg1);
    void on_portEdt_textChanged(const QString& arg1);
    void on_macEdt_textChanged(const QString& arg1);

private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QIntValidator>               // 整数输入验证器
#include <QRegularExpression>          // 正则表达式类（Qt 6 推荐）
#include <QRegularExpressionValidator> // 正则表达式验证器类

// 构造函数：初始化界面并设置输入验证规则
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 设置 UI 界面

    // 设置 MAC 地址输入掩码：HH:HH:HH:HH:HH:HH（只允许输入十六进制字符）
    ui->macEdt->setInputMask("HH:HH:HH:HH:HH:HH");

    // 定义 IP 地址的正则表达式（匹配 IPv4 格式，例如 192.168.1.1）
    QRegularExpression re("^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}"
                          "(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$");

    // 创建 IP 验证器，并设置给 ipEdt
    QRegularExpressionValidator* reVali = new QRegularExpressionValidator(re);
    ui->ipEdt->setValidator(reVali);

    // 创建端口号验证器，限制输入范围在 0 到 65535
    QIntValidator* intVali = new QIntValidator(0, 65535);
    ui->portEdt->setValidator(intVali);
}

// 析构函数：释放 UI 对象
Widget::~Widget() {
    delete ui;
}

// 槽函数：当 IP 输入框内容发生变化时打印日志
void Widget::on_ipEdt_textChanged(const QString& arg1) {
    qDebug() << "IP: " << arg1;
}

// 槽函数：当端口号输入框内容发生变化时打印日志
void Widget::on_portEdt_textChanged(const QString& arg1) {
    qDebug() << "Port: " << arg1;
}

// 槽函数：当 MAC 地址输入框内容发生变化时打印日志
void Widget::on_macEdt_textChanged(const QString& arg1) {
    qDebug() << "MAC: " << arg1;
}
```

### 单词补全

Qt 的**单词补全**功能，主要通过 `QCompleter` 类实现。它能为 `QLineEdit`、`QComboBox`、`QTextEdit` 等控件提供**自动补全**（auto-completion）支持。常见场景包括命令提示、文件路径补全、联系人姓名匹配等。

#### QCompleter 简介

`QCompleter` 是 Qt 提供的一个补全框架，支持：

- **从静态列表补全**
- **从 QStringListModel、QAbstractItemModel 衍生类中读取数据**
- 支持 **前缀匹配**、**模糊匹配**、**不区分大小写**
- 支持 **层级补全（如路径）**

#### 基本用法（静态字符串列表）

```cpp
#include <QCompleter>
#include <QStringListModel>
#include <QLineEdit>

// 假设 lineEdit 是某个输入框
QStringList words = {"apple", "banana", "grape", "orange", "pear"};
QCompleter* completer = new QCompleter(words, this);
completer->setCaseSensitivity(Qt::CaseInsensitive); // 不区分大小写
lineEdit->setCompleter(completer);
```

#### 从模型读取数据（QStringListModel）

```cpp
QStringList wordList = {"hello", "hi", "howdy", "hola", "hey"};
QStringListModel* model = new QStringListModel(wordList, this);

QCompleter* completer = new QCompleter(model, this);
completer->setCompletionMode(QCompleter::PopupCompletion); // 弹出建议框
completer->setCaseSensitivity(Qt::CaseInsensitive);
lineEdit->setCompleter(completer);
```

#### 路径/层级补全（如 QFileSystemModel）

```cpp
#include <QFileSystemModel>
#include <QCompleter>

QFileSystemModel* model = new QFileSystemModel(this);
model->setRootPath("");  // 根路径

QCompleter* completer = new QCompleter(model, this);
completer->setCompletionMode(QCompleter::PopupCompletion);
completer->setCaseSensitivity(Qt::CaseInsensitive);

lineEdit->setCompleter(completer);
```

这个适用于用户输入路径时，自动补全文件或文件夹名。

#### 补全模式

通过 `QCompleter::setCompletionMode()` 设置行为：

| 模式名                      | 说明                     |
| --------------------------- | ------------------------ |
| `InlineCompletion`          | 光标后直接补全（如 IDE） |
| `PopupCompletion`           | 弹出列表建议（最常用）   |
| `UnfilteredPopupCompletion` | 所有选项直接弹出，不过滤 |

#### 进阶功能

设置过滤行为：

```cpp
completer->setFilterMode(Qt::MatchContains); // 包含匹配（默认是前缀匹配）
```

设置最大显示项数：

```cpp
completer->setMaxVisibleItems(10);
```

#### 常见控件支持

| 控件           | 是否支持补全                        |
| -------------- | ----------------------------------- |
| QLineEdit      | ✅ 支持                              |
| QComboBox      | ✅ 支持（需设置 `setEditable(true)`) |
| QTextEdit      | ⛔ 需手动实现                        |
| QPlainTextEdit | ⛔ 需手动实现                        |

对于 `QTextEdit` 或 `QPlainTextEdit` 的补全（如代码编辑器），需要手动处理输入事件、光标位置、自定义弹出框等，较为复杂。

#### 示例

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
    void on_edtDay_textChanged(const QString& arg1);
    void on_edtYear_textChanged(const QString& arg1);
    void on_edtKasa_textChanged(const QString& arg1);

private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

##### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QCompleter>

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 创建星期几列表
    QStringList listDayOfWeek;
    listDayOfWeek << "Monday" << "Tuesday" << "Wednesday"
                  << "Thursday" << "Friday" << "Saturday" << "Sunday";

    // 创建星期几自动补全器，设置为弹出匹配列表（PopupCompletion），默认模式
    QCompleter* cpDayOfWeek = new QCompleter(listDayOfWeek);
    cpDayOfWeek->setCaseSensitivity(Qt::CaseInsensitive);  // 不区分大小写
    cpDayOfWeek->setCompletionMode(QCompleter::PopupCompletion);  // 弹出匹配列表
    ui->edtDay->setCompleter(cpDayOfWeek);  // 设置到对应的编辑框

    // 创建年份列表
    QStringList listYear;
    listYear << "2016" << "2015"
             << "2008" << "2006"
             << "1999" << "1991";

    listYear.sort();  // 排序，方便补全匹配

    // 创建年份自动补全器，设置为内联补全（InlineCompletion）
    QCompleter* cpYear = new QCompleter(listYear);
    cpYear->setCompletionMode(QCompleter::InlineCompletion);  // 在编辑框内自动补全剩余部分
    ui->edtYear->setCompleter(cpYear);

    // 创建卡萨相关字符串列表
    QStringList listHeXi;
    listHeXi << "卡萨甲" << "卡萨乙" << "卡萨丙" << "卡萨丁"
             << "卡萨甲2" << "卡萨乙3" << "卡萨乙2" << "卡萨丁2";

    // 创建卡萨补全器，设置为不过滤，弹出所有项（UnfilteredPopupCompletion）
    QCompleter* cpHexi = new QCompleter(listHeXi);
    cpHexi->setCompletionMode(QCompleter::UnfilteredPopupCompletion);  // 弹出全部项，不过滤匹配
    ui->edtKasa->setCompleter(cpHexi);
}

Widget::~Widget() {
    delete ui;
}

// 以下槽函数用于接收编辑框文本变化的信号，打印当前文本内容方便调试

void Widget::on_edtDay_textChanged(const QString& arg1) {
    qDebug() << "星期几: " << arg1;
}

void Widget::on_edtYear_textChanged(const QString& arg1) {
    qDebug() << "哪一年: " << arg1;
}

void Widget::on_edtKasa_textChanged(const QString& arg1) {
    qDebug() << "卡萨什么: " << arg1;
}
```

