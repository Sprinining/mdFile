## Qt 文本流 QTextStream

 ### QTextStream

`QTextStream` 是 Qt 提供的一个用于 **文本输入输出的类**，主要用于从文件、字符串、标准输入输出等文本流中读写数据。它提供了与 `iostream` 类似的接口，但更适用于 Qt 风格的开发。

#### 基本用途

`QTextStream` 主要用于：

- 读写 `QFile`
- 读写 `QString`
- 读写标准输入输出（`stdin`, `stdout`）

#### 常用构造函数

```cpp
QTextStream();                            // 空构造函数
QTextStream(QIODevice *device);          // 从设备构造，如 QFile
QTextStream(QString *string);            // 绑定字符串，适合构造字符串输出流
```

#### 示例 1：从文件读取文本

```cpp
QFile file("data.txt");
if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine();
        qDebug() << line;
    }
    file.close();
}
```

#### 示例 2：写入文件

```cpp
QFile file("output.txt");
if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
    QTextStream out(&file);
    out << "Hello, Qt!" << Qt::endl;
    file.close();
}
```

#### 示例 3：标准输入输出

```cpp
QTextStream cin(stdin);
QTextStream cout(stdout);

cout << "请输入名字: " << flush;
QString name = cin.readLine();
cout << "你好，" << name << Qt::endl;
```

#### 常用函数

| 方法                       | 功能                 |
| -------------------------- | -------------------- |
| `readLine()`               | 读取一行文本         |
| `readAll()`                | 读取全部内容         |
| `read(int maxlen)`         | 读取指定字符数       |
| `operator<<`               | 写入数据             |
| `operator>>`               | 读取数据             |
| `setCodec()`               | 设置编码（如 UTF-8） |
| `setFieldAlignment()`      | 设置字段对齐方式     |
| `setFieldWidth()`          | 设置字段宽度         |
| `setPadChar()`             | 设置填充字符         |
| `setRealNumberPrecision()` | 设置浮点数精度       |

#### 设置编码（默认是本地编码）

```cpp
QTextStream out(&file);
out.setCodec("UTF-8");  // Qt5 及以前
```

在 Qt6 中，编码设置方式略有不同（通过 `setEncoding()`）。

#### 格式操作符（操纵器）

| 操作子 / 方法                                                | 说明                                    | 示例                                                         |
| ------------------------------------------------------------ | --------------------------------------- | ------------------------------------------------------------ |
| **进制相关**                                                 |                                         |                                                              |
| `Qt::dec`                                                    | 十进制（默认）                          | `ts << Qt::dec << 255;`                                      |
| `Qt::oct`                                                    | 八进制                                  | `ts << Qt::oct << 255;`                                      |
| `Qt::hex`                                                    | 十六进制                                | `ts << Qt::hex << 255;`                                      |
| **符号显示**                                                 |                                         |                                                              |
| `QTextStream::showbase`                                      | 显示进制前缀（如 `0x`、`0`）            | `ts.setIntegerBase(16); ts.setFieldAlignment(QTextStream::AlignLeft); ts << 255;` 需结合显示前缀 |
| `QTextStream::showpos`                                       | 显示正号（+）                           | `ts << QTextStream::showpos << 123;`                         |
| **浮点数格式**                                               |                                         |                                                              |
| `QTextStream::fixed`                                         | 固定小数点格式                          | `ts << QTextStream::fixed << 3.14;`                          |
| `QTextStream::scientific`                                    | 科学计数法格式                          | `ts << QTextStream::scientific << 3.14;`                     |
| `QTextStream::realNumberNotation()`                          | 设置浮点数格式（fixed/scientific/auto） | `ts.setRealNumberNotation(QTextStream::FixedNotation);`      |
| `QTextStream::setRealNumberPrecision(int)`                   | 设置小数位数                            | `ts.setRealNumberPrecision(2);`                              |
| **域宽和对齐**                                               |                                         |                                                              |
| `QTextStream::setFieldWidth(int)`                            | 设置输出域宽                            | `ts.setFieldWidth(10);`                                      |
| `QTextStream::setFieldAlignment(QTextStream::FieldAlignment)` | 设置域对齐方式（左/右/中心）            | `ts.setFieldAlignment(QTextStream::AlignRight);`             |
| **填充字符**                                                 |                                         |                                                              |
| `QTextStream::setPadChar(QChar)`                             | 设置填充字符（默认空格）                | `ts.setPadChar('0');`                                        |
| **其他**                                                     |                                         |                                                              |
| `QTextStream::reset()`                                       | 重置流状态和格式                        | `ts.reset();`                                                |
| `QTextStream::skipWhiteSpace()`                              | 跳过输入流的空白字符                    | `ts.skipWhiteSpace();`                                       |

### 示例：读写文本

```txt
#姓名	岁数	体重
小明	18	50.50
小萌	19	55.80
小日	17	60.00
小月	16	55.10
小草	18	58.60
```

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
    <width>480</width>
    <height>300</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout_2">
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QListWidget" name="listWidget"/>
     </item>
     <item>
      <layout class="QVBoxLayout" name="verticalLayout">
       <item>
        <widget class="QPushButton" name="btnLoad">
         <property name="text">
          <string>加载表格</string>
         </property>
        </widget>
       </item>
       <item>
        <widget class="QPushButton" name="btnSave">
         <property name="text">
          <string>保存表格</string>
         </property>
        </widget>
       </item>
       <item>
        <spacer name="verticalSpacer">
         <property name="orientation">
          <enum>Qt::Orientation::Vertical</enum>
         </property>
         <property name="sizeHint" stdset="0">
          <size>
           <width>20</width>
           <height>40</height>
          </size>
         </property>
        </spacer>
       </item>
       <item>
        <widget class="QPushButton" name="btnDelRow">
         <property name="text">
          <string>删除行</string>
         </property>
        </widget>
       </item>
      </layout>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QLabel" name="label">
       <property name="text">
        <string>姓名</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditName"/>
     </item>
     <item>
      <widget class="QLabel" name="label_2">
       <property name="text">
        <string>岁数</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditAge"/>
     </item>
     <item>
      <widget class="QLabel" name="label_3">
       <property name="text">
        <string>体重</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditWeight"/>
     </item>
     <item>
      <widget class="QPushButton" name="btnAddRow">
       <property name="text">
        <string>添加行</string>
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
    void on_btnLoad_clicked();

    void on_btnSave_clicked();

    void on_btnDelRow_clicked();

    void on_btnAddRow_clicked();

    void on_listWidget_currentRowChanged(int currentRow);

  private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDebug>
#include <QFile>
#include <QFileDialog>
#include <QListWidgetItem>
#include <QMessageBox>
#include <QTextStream>

// 构造函数：初始化 UI 并设置 listWidget 的选择模式为单选
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);
    ui->listWidget->setSelectionMode(QAbstractItemView::SingleSelection);
}

// 析构函数：释放 UI 指针
Widget::~Widget() {
    delete ui;
}

// 加载按钮点击槽函数：从文件加载数据到 listWidget 中
void Widget::on_btnLoad_clicked() {
    // 弹出文件选择对话框
    QString strFile = QFileDialog::getOpenFileName(this, tr("打开文件"), tr("."), tr("Text Files(*.txt);;All files(*)"));
    if (strFile.isEmpty()) return;

    QFile fileIn(strFile);
    // 打开文件失败提示
    if (!fileIn.open(QIODevice::ReadOnly)) {
        QMessageBox::warning(this, tr("打开文件"), tr("打开文件失败：") + fileIn.errorString());
        return;
    }

    QTextStream tsIn(&fileIn);
    QString strCurName;
    int nCurAge;
    double dblCurWeight;
    ui->listWidget->clear(); // 清空现有项

    // 逐行读取文件内容
    while (!tsIn.atEnd()) {
        tsIn >> strCurName;
        if (strCurName.isEmpty()) {
            tsIn.skipWhiteSpace(); // 跳过空白
            continue;
        }
        if (strCurName.startsWith('#')) {
            tsIn.readLine(); // 跳过注释行
            continue;
        }

        tsIn >> nCurAge >> dblCurWeight;

        // 使用 QTextStream 格式化输出为固定小数点两位
        QString strOut;
        QTextStream tsOut(&strOut);
        tsOut.setRealNumberNotation(QTextStream::FixedNotation);
        tsOut.setRealNumberPrecision(2);
        tsOut << strCurName << "\t" << nCurAge << "\t" << dblCurWeight;

        ui->listWidget->addItem(strOut); // 添加到列表
    }

    QMessageBox::information(this, tr("加载表格"), tr("加载自定义表格完毕。"));
}

// 保存按钮点击槽函数：将 listWidget 中的数据保存到文件
void Widget::on_btnSave_clicked() {
    int nCount = ui->listWidget->count();
    if (nCount < 1) return;

    QString strFileSave = QFileDialog::getSaveFileName(this, tr("保存文件"), tr("."), tr("XLS files(*.xls);;Text Files(*.txt)"));
    if (strFileSave.isEmpty()) return;

    QFile fileOut(strFileSave);
    if (!fileOut.open(QIODevice::WriteOnly)) {
        QMessageBox::warning(this, tr("保存文件"), tr("打开保存文件失败：") + fileOut.errorString());
        return;
    }

    QTextStream tsOut(&fileOut);
    tsOut.setRealNumberNotation(QTextStream::FixedNotation);
    tsOut.setRealNumberPrecision(2);

    // 写入表头
    tsOut << tr("#姓名\t岁数\t体重") << Qt::endl;

    // 写入每一行数据
    for (int i = 0; i < nCount; i++) {
        QString strCurAll = ui->listWidget->item(i)->text();
        QTextStream tsLine(&strCurAll);
        QString strName;
        int nAge;
        double dblWeight;
        tsLine >> strName >> nAge >> dblWeight;
        tsOut << strName << "\t" << nAge << "\t" << dblWeight << Qt::endl;
    }

    QMessageBox::information(this, tr("保存文件"), tr("保存表格文件成功。"));
}

// 删除按钮点击槽函数：删除当前选中的行
void Widget::on_btnDelRow_clicked() {
    int nCurIndex = ui->listWidget->currentRow(); // 获取当前行索引
    if (nCurIndex < 0) return;                    // 没有选中则返回
    ui->listWidget->takeItem(nCurIndex);          // 删除该项
}

// 添加按钮点击槽函数：添加新行数据到 listWidget
void Widget::on_btnAddRow_clicked() {
    QString strName = ui->lineEditName->text().trimmed();
    QString strAge = ui->lineEditAge->text().trimmed();
    QString strWeight = ui->lineEditWeight->text().trimmed();

    // 检查输入项是否为空
    if (strName.isEmpty() || strAge.isEmpty() || strWeight.isEmpty()) {
        QMessageBox::warning(this, tr("添加行"), tr("请先填好三项数据再添加！"));
        return;
    }

    int nAge = strAge.toInt();
    double dblWeight = strWeight.toDouble();

    // 检查年龄与体重范围
    if ((nAge < 0) || (nAge > 600)) {
        QMessageBox::warning(this, tr("添加行"), tr("年龄不能是负数或超过600！"));
        return;
    }
    if (dblWeight < 0.1) {
        QMessageBox::warning(this, tr("添加行"), tr("重量不能低于 0.1 kg ！"));
        return;
    }

    // 使用 QString::arg 格式化为两位小数
    QString strCurAll = tr("%1\t%2\t%3").arg(strName).arg(nAge).arg(dblWeight, 0, 'f', 2);
    ui->listWidget->addItem(strCurAll); // 添加新项
}

// 当前列表项变化时触发：同步数据到编辑框
void Widget::on_listWidget_currentRowChanged(int currentRow) {
    if (currentRow < 0) return;

    QString strCurAll = ui->listWidget->item(currentRow)->text();
    QTextStream tsLine(&strCurAll);
    QString strName;
    int nAge;
    double dblWeight;

    tsLine >> strName >> nAge >> dblWeight;

    // 设置文本框内容
    ui->lineEditName->setText(strName);
    ui->lineEditAge->setText(tr("%1").arg(nAge));
    ui->lineEditWeight->setText(tr("%1").arg(dblWeight));
}
```

### 示例：命令行输入输出

#### main.cpp

```cpp
#include <QCoreApplication>
#include <QTextStream>

// 函数声明：根据功能代码执行对应逻辑
void funcs(int nCode, QTextStream& tsIn, QTextStream& tsOut);

int main(int argc, char* argv[]) {
    QCoreApplication a(argc, argv);

    QTextStream tsIn(stdin);   // 用于从标准输入读取（相当于 cin）
    QTextStream tsOut(stdout); // 用于向标准输出写入（相当于 cout）

    while (true) {
        // 显示功能菜单
        QString strFuns = a.tr("功能代码：\n"
                               "1. 输入整型数\n"
                               "2. 输入浮点数\n"
                               "3. 输入单词\n"
                               "4. 输入整行句子\n"
                               "9. 退出程序\n"
                               "请输入功能代码： ");
        tsOut << strFuns << Qt::flush; // 显示菜单并立即刷新缓冲区（避免不显示）

        int nCode;
        tsIn >> nCode; // 读取用户输入的功能编号

        if (nCode == 9) {
            tsOut << a.tr("程序结束。") << Qt::endl;
            return 0; // 用户选择退出
        } else {
            funcs(nCode, tsIn, tsOut); // 执行对应功能
        }
    }

    return a.exec(); // 实际不会执行到这里
}

// 功能函数，根据编号执行对应任务
void funcs(int nCode, QTextStream& tsIn, QTextStream& tsOut) {
    tsOut << Qt::endl; // 开始前空一行

    QString strOut;  // 输出用字符串
    QString strIn;   // 用于接收单词或整行输入
    int nNum;        // 用于接收整数
    double dblValue; // 用于接收浮点数

    switch (nCode) {
    case 1: {
        // 输入整数
        strOut = qApp->tr("请输入整数： ");
        tsOut << strOut << Qt::flush;
        tsIn >> nNum;
        strOut = qApp->tr("您刚输入的是：%1").arg(nNum);
        tsOut << strOut << Qt::endl;
        break;
    }
    case 2: {
        // 输入浮点数
        strOut = qApp->tr("请输入浮点数： ");
        tsOut << strOut << Qt::flush;
        tsIn >> dblValue;
        strOut = qApp->tr("您刚输入的是：%1").arg(dblValue);
        tsOut << strOut << Qt::endl;
        break;
    }
    case 3: {
        // 输入单词（空格分隔的一个词）
        strOut = qApp->tr("请输入一个单词： ");
        tsOut << strOut << Qt::flush;
        tsIn >> strIn;
        strOut = qApp->tr("您刚输入的是： %1").arg(strIn);
        tsOut << strOut << Qt::endl;
        break;
    }
    case 4: {
        // 输入一整行
        strOut = qApp->tr("请输入一行字符串： ");
        tsOut << strOut << Qt::flush;
        tsIn.skipWhiteSpace();   // 跳过前面回车等空白字符
        strIn = tsIn.readLine(); // 读取整行（包括空格）
        strOut = qApp->tr("您刚输入的是： %1").arg(strIn);
        tsOut << strOut << Qt::endl;
        break;
    }
    default: {
        // 未知功能代码
        strOut = qApp->tr("未知功能代码 %1 ，不处理。").arg(nCode);
        tsOut << strOut << Qt::endl;
        break;
    }
    }

    tsOut << Qt::endl; // 功能处理完后空一行

    // 错误处理：如果输入出错，比如输入字母给数字字段
    if (tsIn.status() != QTextStream::Ok) {
        tsIn.readLine();    // 跳过当前输入行，防止错误遗留
        tsIn.resetStatus(); // 重置输入流状态为正常
    }
}
```

### 示例：图形程序和命令行输入输出协作

要让 **Qt GUI 项目**支持 `stdin`、`stdout`、`stderr` 这样的 **命令行输入输出**，需要做两件事：

####  一、修改 `CMakeLists.txt` 中的这一句

把：

```cmake
set_target_properties(guicui PROPERTIES
    ...
    WIN32_EXECUTABLE TRUE
)
```

改为：

```cmake
set_target_properties(guicui PROPERTIES
    ...
    WIN32_EXECUTABLE FALSE
)
```

或者**直接删除这一行**也可以。

`WIN32_EXECUTABLE TRUE` 会告诉 Windows 把程序当成 GUI 应用程序启动，这样它在运行时就不会打开控制台窗口，也无法访问 `stdin/stdout`。

如果你希望程序在 **命令行中运行、能读写控制台**，就必须去掉这个属性，或者设为 `FALSE`。

#### 二、在 Qt Creator 中设置「在终端运行」

如果是用 Qt Creator 启动程序，还需要额外做一件事（只影响 IDE 内运行效果）：

1. 打开 Qt Creator
2. 左边点 **Projects** → 选择构建配置（如 Debug）
3. 右侧找到 **Run** → 找到 **Run in terminal**（或“在终端运行”）
4. 打上勾！

这样才能让 `stdin/stdout` 显示在弹出的终端窗口中（比如 `QTextStream tsIn(stdin)` 才能读取输入）。

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
    <width>305</width>
    <height>51</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QHBoxLayout" name="horizontalLayout">
   <item>
    <widget class="QPushButton" name="btnIn">
     <property name="text">
      <string>接收输入</string>
     </property>
    </widget>
   </item>
   <item>
    <widget class="QLineEdit" name="lineEditMsg"/>
   </item>
   <item>
    <widget class="QPushButton" name="btnOut">
     <property name="text">
      <string>打印输出</string>
     </property>
    </widget>
   </item>
  </layout>
 </widget>
 <resources/>
 <connections/>
</ui>
```

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
    void on_btnIn_clicked();

    void on_btnOut_clicked();

  private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDebug>
#include <QTextStream>

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 设置 UI 布局
}

Widget::~Widget() {
    delete ui;
}

// “输入”按钮点击事件处理函数
void Widget::on_btnIn_clicked() {
    // 创建输入输出流对象（绑定到标准输入和输出）
    QTextStream tsIn(stdin);   // 标准输入，等同于 std::cin
    QTextStream tsOut(stdout); // 标准输出，等同于 std::cout

    // 提示用户在命令行输入一行字符串
    QString strOut = tr("请输入一行字符串：");
    tsOut << strOut << Qt::endl;

    // 从命令行读取一整行用户输入（遇到回车结束）
    QString strMsg = tsIn.readLine();

    // 将用户输入显示到界面上的 QLineEdit 控件中
    ui->lineEditMsg->setText(strMsg);
}

// “输出”按钮点击事件处理函数
void Widget::on_btnOut_clicked() {
    // 创建输出流对象，用于写入标准输出
    QTextStream tsOut(stdout); // 标准输出

    // 从界面上的 QLineEdit 中获取用户输入的字符串
    QString strMsg = ui->lineEditMsg->text();

    // 输出一行信息到命令行
    tsOut << Qt::endl << tr("输出信息：") << strMsg << Qt::endl;

    // 使用 Qt 的调试输出（会自动输出到调试终端）
    qDebug() << Qt::endl << tr("这行是调试信息。") << Qt::endl;
}
```

