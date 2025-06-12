## Qt 其他文件操作类

### QStorageInfo

`QStorageInfo` 是 Qt 框架中用于获取和操作存储设备信息的类，属于 `QtCore` 模块（从 Qt 5.4 开始引入）。它可以帮助你查询磁盘、分区或挂载点的使用情况，比如容量、剩余空间、文件系统类型等。

#### 基本功能

| 功能                           | 方法                                         |
| ------------------------------ | -------------------------------------------- |
| 获取所有存储设备信息           | `QStorageInfo::mountedVolumes()`（静态方法） |
| 获取设备总容量                 | `qint64 totalBytes() const`                  |
| 获取可用容量                   | `qint64 availableBytes() const`              |
| 获取剩余容量（包括 root 用户） | `qint64 bytesFree() const`                   |
| 获取挂载路径                   | `QString rootPath() const`                   |
| 获取设备名                     | `QString device() const`                     |
| 获取文件系统类型               | `QString fileSystemType() const`             |
| 判断是否可用                   | `bool isValid() const`                       |
| 判断是否只读                   | `bool isReadOnly() const`                    |
| 判断是否已挂载                 | `bool isReady() const`                       |

#### 使用示例

##### 获取当前根目录的磁盘信息

```cpp
#include <QCoreApplication>
#include <QStorageInfo>
#include <QDebug>

int main(int argc, char *argv[]) {
    QCoreApplication a(argc, argv);

    QStorageInfo storage = QStorageInfo::root();

    qDebug() << "Root path:" << storage.rootPath();
    qDebug() << "Device:" << storage.device();
    qDebug() << "Filesystem type:" << storage.fileSystemType();
    qDebug() << "Total bytes:" << storage.totalBytes();
    qDebug() << "Available bytes:" << storage.availableBytes();
    qDebug() << "Is read only:" << storage.isReadOnly();

    return a.exec();
}
```

##### 遍历所有挂载的存储卷

```cpp
#include <QStorageInfo>
#include <QDebug>

void listVolumes() {
    const auto volumes = QStorageInfo::mountedVolumes();
    for (const QStorageInfo &volume : volumes) {
        if (!volume.isValid() || !volume.isReady())
            continue;
        qDebug() << "Device:" << volume.device();
        qDebug() << "Root path:" << volume.rootPath();
        qDebug() << "File system type:" << volume.fileSystemType();
        qDebug() << "Total:" << volume.totalBytes() / (1024 * 1024) << "MB";
        qDebug() << "Available:" << volume.availableBytes() / (1024 * 1024) << "MB";
        qDebug() << "Read only:" << volume.isReadOnly();
        qDebug() << "-----------------------------";
    }
}
```

### QTextDocumentWriter

`QTextDocumentWriter` 是 Qt 中用于将文本文档（`QTextDocument`）保存为文件的类。它支持多种格式（如 HTML、纯文本、ODF），是处理富文本保存的高层接口之一，常用于文字编辑器、报告导出等应用。

#### 常用构造函数与方法

| 方法                                                         | 说明                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| `QTextDocumentWriter()`                                      | 构造一个默认写入器                                           |
| `QTextDocumentWriter(const QString &fileName, const QByteArray &format = QByteArray())` | 构造一个写入到指定文件的写入器，支持指定格式（如 `"plaintext"`、`"html"`） |
| `void setFileName(const QString &fileName)`                  | 设置输出文件路径                                             |
| `void setFormat(const QByteArray &format)`                   | 设置保存格式                                                 |
| `bool write(const QTextDocument *document)`                  | 将 `QTextDocument` 写入文件，成功返回 `true`                 |
| `bool write(const QTextDocumentFragment &fragment)`          | 也可以写 `QTextDocumentFragment`                             |
| `QByteArray format() const`                                  | 获取当前格式                                                 |
| `QString fileName() const`                                   | 获取当前文件名                                               |

#### 支持的格式

可以通过 `QTextDocumentWriter::supportedDocumentFormats()` 获取当前 Qt 支持的格式。常见的有：

- `"plaintext"`：纯文本
- `"html"`：HTML 格式
- `"odf"`：Open Document Format（.odt）

> 注意：是否支持 `.odf` 取决于 Qt 构建选项，一般桌面版本支持。

#### 使用示例

##### 保存为纯文本

```cpp
#include <QTextDocument>
#include <QTextDocumentWriter>

void savePlainTextDocument(const QString &filePath) {
    QTextDocument doc;
    doc.setPlainText("Hello, world!\nThis is a plain text document.");

    QTextDocumentWriter writer(filePath, "plaintext");
    if (!writer.write(&doc)) {
        qWarning("Failed to save document.");
    }
}
```

##### 保存为 HTML

```cpp
#include <QTextDocumentWriter>
#include <QTextDocument>

void saveHtmlDocument(const QString &filePath) {
    QTextDocument doc;
    doc.setHtml("<h1>Title</h1><p style='color:blue;'>This is <b>HTML</b> content.</p>");

    QTextDocumentWriter writer(filePath, "html");
    if (!writer.write(&doc)) {
        qWarning("Failed to save HTML document.");
    }
}
```

#### 典型应用场景

- 富文本编辑器中保存用户编辑内容（如 QTextEdit 的内容）

- 支持多格式导出功能（HTML、纯文本等）

- 自动保存、模板导出、报告生成

#### 注意事项

- `write()` 不会自动创建目录；确保目录存在。

- 若未设置格式，`QTextDocumentWriter` 会尝试根据文件扩展名自动推断。

- 默认的文件格式推断策略不一定准确，最好明确指定格式。

### QTemporaryDir

`QTemporaryDir` 是 Qt 提供的一个类，用于创建和管理**临时目录**。这个类会自动在系统的临时目录中创建一个唯一的目录，并在对象销毁时自动删除该目录及其内容（除非调用 `setAutoRemove(false)` 取消自动删除）。它非常适合用在需要中间目录的临时文件处理场景，如解压、构建缓存、导出中间文件等。

#### 构造函数与常用方法

| 方法                                              | 说明                                           |
| ------------------------------------------------- | ---------------------------------------------- |
| `QTemporaryDir()`                                 | 创建一个临时目录（系统默认路径）               |
| `QTemporaryDir(const QString &templateName)`      | 使用模板路径创建临时目录，例如 `"temp_XXXXXX"` |
| `QString path() const`                            | 获取创建的临时目录的完整路径                   |
| `bool isValid() const`                            | 是否成功创建临时目录                           |
| `bool autoRemove() const`                         | 是否在析构时自动删除目录                       |
| `void setAutoRemove(bool)`                        | 设置是否在析构时删除目录                       |
| `QString filePath(const QString &fileName) const` | 在临时目录下生成子路径（不创建文件）           |

#### 路径模板说明

模板中 `XXXXXX` 会被替换为唯一的随机字符串：

```cpp
QTemporaryDir dir("my_temp_dir_XXXXXX");
```

例如上面可能创建路径：`/tmp/my_temp_dir_aB3D9z`

#### 示例代码

##### 创建临时目录并写入临时文件

```cpp
#include <QTemporaryDir>
#include <QFile>
#include <QTextStream>
#include <QDebug>

void createTempDirAndFile() {
    QTemporaryDir tempDir;

    if (!tempDir.isValid()) {
        qWarning() << "Failed to create temporary directory.";
        return;
    }

    qDebug() << "Temporary directory created at:" << tempDir.path();

    QString filePath = tempDir.filePath("example.txt");
    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        out << "This is a test file inside a temporary directory.";
        file.close();
        qDebug() << "Temporary file written at:" << filePath;
    }
}
```

##### 保留临时目录用于调试

```cpp
QTemporaryDir tempDir;
tempDir.setAutoRemove(false);  // 防止析构时自动删除
qDebug() << "Preserved temp dir:" << tempDir.path();
```

#### 典型应用场景

- 解压缩工具的中间目录

- 构建临时工作空间

- 单元测试中的临时文件系统模拟

- 不希望污染用户目录的短时文件写入

#### 注意事项

- 默认的临时目录位于系统临时目录中（如 `/tmp`、`C:\Users\<user>\AppData\Local\Temp`）。

- `filePath()` 不会实际创建文件或子目录，它只是构造路径字符串。

- `QTemporaryDir` 会递归删除其目录及子文件，非常适合自动清理。

### QTemporaryFile

`QTemporaryFile` 是 Qt 提供的一个类，用于创建**临时文件**，其作用是在文件系统中创建一个唯一的、可自动清理的临时文件。这个类在处理短生命周期的文件（如缓存、中间文件、日志片段、数据导出等）时非常实用，并且跨平台可靠。

#### 功能概览

| 功能                   | 方法                                                |
| ---------------------- | --------------------------------------------------- |
| 创建临时文件           | 构造函数（可指定模板名）                            |
| 打开文件（会自动创建） | `open()`                                            |
| 获取文件路径           | `fileName()`                                        |
| 自动删除文件           | `setAutoRemove(true)`（默认就是 true）              |
| 是否创建成功           | `isOpen()`、`exists()`、`isValid()`                 |
| 写入数据               | 继承自 `QFile`，可直接使用 `write()`、`QTextStream` |

#### 模板命名规则

模板中必须包含至少六个 `X`，这些 `X` 会被替换成随机字符，以生成唯一文件名：

```cpp
QTemporaryFile tmp("my_temp_XXXXXX.txt");
```

生成文件名示例：

```bash
/tmp/my_temp_iL9pTw.txt
```

如果不提供模板，Qt 会在默认系统临时目录下创建一个名字类似 `/tmp/qt_temp.abc123` 的文件。

#### 使用示例

##### 最简单用法（自动删除）

```cpp
#include <QTemporaryFile>
#include <QTextStream>
#include <QDebug>

void createAndUseTempFile() {
    QTemporaryFile tempFile;
    if (tempFile.open()) {
        QTextStream out(&tempFile);
        out << "Hello from temporary file!" << Qt::endl;
        qDebug() << "Temp file path:" << tempFile.fileName();
        // 文件自动关闭并删除（默认 autoRemove 为 true）
    } else {
        qWarning() << "Failed to create temporary file.";
    }
}
```

##### 保留文件用于调试

```cpp
QTemporaryFile tempFile("debug_output_XXXXXX.txt");
tempFile.setAutoRemove(false);  // 关闭自动删除
if (tempFile.open()) {
    QTextStream out(&tempFile);
    out << "Debug info here\n";
    qDebug() << "Saved at:" << tempFile.fileName();
}
```

##### 写入临时文件后用 `QProcess` 打开

```cpp
QTemporaryFile tempFile;
tempFile.setAutoRemove(false);  // 让 QProcess 能访问
if (tempFile.open()) {
    tempFile.write("Example content");
    tempFile.flush();  // 确保写入磁盘

    QProcess::startDetached("notepad.exe", QStringList() << tempFile.fileName());
}
```

#### 典型应用场景

- 单元测试中写临时数据（避免污染磁盘）
- 使用 `QProcess` 传递临时文件输入输出
- 临时导出数据用于其他程序读取
- 构建缓存系统（编译器、图像处理等）

#### 注意事项

- `QTemporaryFile` 会在调用 `open()` 时自动创建文件。

- 一旦对象销毁或手动关闭并删除，文件即被清除（如果 `autoRemove == true`）。

- 临时文件是物理存在于磁盘的，可在其他进程中读取。

- 在 Windows 上文件可能无法被其他程序打开，除非在 open 之后立即 `close()`（Windows 的文件锁行为）。

### 示例：磁盘分区信息

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
    <width>300</width>
    <height>200</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QHBoxLayout" name="horizontalLayout">
   <item>
    <widget class="QTextEdit" name="textEdit"/>
   </item>
   <item>
    <layout class="QVBoxLayout" name="verticalLayout">
     <item>
      <widget class="QPushButton" name="btnGetDiskInfo">
       <property name="text">
        <string>获取磁盘信息</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnSaveDiskInfo">
       <property name="text">
        <string>保存磁盘信息</string>
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
    void on_btnGetDiskInfo_clicked();

    void on_btnSaveDiskInfo_clicked();

  private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include "ui_widget.h"

#include <QFileDialog>         // 文件选择对话框
#include <QMessageBox>         // 弹出提示框
#include <QStorageInfo>        // 获取磁盘分区信息
#include <QTextDocumentWriter> // 将 QTextDocument 写入文件

// 构造函数，初始化界面
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 初始化 UI 布局
}

// 析构函数，释放资源
Widget::~Widget() {
    delete ui;
}

// 槽函数：点击“获取磁盘信息”按钮后调用
void Widget::on_btnGetDiskInfo_clicked() {
    // 获取当前所有挂载的磁盘分区信息
    QList<QStorageInfo> listDisks = QStorageInfo::mountedVolumes();

    // 用于存储所有磁盘信息的字符串
    QString strInfo;
    QString strTemp;

    // 获取分区数量
    int nCount = listDisks.count();

    // 遍历每个分区
    for (int i = 0; i < nCount; i++) {
        // 添加当前分区编号
        strTemp = tr("分区 %1 信息：<br>").arg(i);
        strInfo += strTemp;

        // 设备名称（如 /dev/sda1）
        strTemp = listDisks[i].device();
        strInfo += tr("设备：") + strTemp + tr("<br>");

        // 挂载点路径（如 /home、C:\）
        strTemp = listDisks[i].rootPath();
        strInfo += tr("挂载点：") + strTemp + tr("<br>");

        // 判断是否为可用分区（加载成功、可访问）
        if (listDisks[i].isValid() && listDisks[i].isReady()) {
            // 卷名（比如 "本地磁盘"）
            strTemp = tr("卷名：%1<br>").arg(listDisks[i].displayName());
            strInfo += strTemp;

            // 文件系统类型（如 NTFS、ext4）
            strTemp = tr("文件系统类型：%1<br>").arg(QString(listDisks[i].fileSystemType()));
            strInfo += strTemp;

            // 是否为系统根目录
            if (listDisks[i].isRoot()) {
                strTemp = tr("<font color=red><b>系统根：是</b></font><br>");
            } else {
                strTemp = tr("系统根：否<br>");
            }
            strInfo += strTemp;

            // 是否只读文件系统
            if (listDisks[i].isReadOnly()) {
                strTemp = tr("只读：是<br>");
            } else {
                strTemp = tr("只读：否<br>");
            }
            strInfo += strTemp;

            // 获取磁盘空间信息（单位：GB）
            double dblAllGB = 1.0 * listDisks[i].bytesTotal() / (1024 * 1024 * 1024);
            double dblFreeGB = 1.0 * listDisks[i].bytesFree() / (1024 * 1024 * 1024);
            strTemp = tr("总空间(GB)：%1 已用：%2 剩余：%3<br>").arg(dblAllGB, 0, 'f', 3).arg(dblAllGB - dblFreeGB, 0, 'f', 3).arg(dblFreeGB, 0, 'f', 3);
            strInfo += strTemp;
        } else {
            // 不可用或未加载的分区
            strTemp = tr("<b>设备不可用或未加载。</b><br>");
            strInfo += strTemp;
        }

        // 每个分区之间增加换行
        strInfo += tr("<br>");
    }

    // 显示收集到的所有磁盘信息（HTML 格式）到 textEdit 中
    ui->textEdit->setText(strInfo);
}

// 槽函数：点击“保存信息”按钮后调用
void Widget::on_btnSaveDiskInfo_clicked() {
    // 弹出“另存为”对话框，让用户选择保存路径和格式
    QString strFileName = QFileDialog::getSaveFileName(this,
                                                       tr("保存信息"),                                              // 对话框标题
                                                       tr("."),                                                     // 默认路径
                                                       tr("Html files(*.htm);;Text files(*.txt);;ODF files(*.odf)") // 文件类型过滤器
                                                       );

    // 如果用户没有选择文件名，直接返回
    if (strFileName.length() < 1) return;

    // 创建 QTextDocumentWriter 对象，用于写入 QTextDocument 到文件
    QTextDocumentWriter tw(strFileName);

    // 执行写入操作，参数是 QTextEdit 的文档对象
    bool bRes = tw.write(ui->textEdit->document());

    // 根据写入结果显示提示框
    if (bRes) {
        QMessageBox::information(this, tr("保存成功"), tr("信息已成功保存到文件。"));
    } else {
        QMessageBox::warning(this, tr("保存出错"), tr("保存到文件出错！"));
    }
}
```

### 示例：临时文件

#### calcpi.h

```cpp
#ifndef CALCPI_H
#define CALCPI_H

#include <QFile> // 支持文件写入功能，配合 Qt 使用

// 计算圆周率类 CalcPI
class CalcPI {
  public:
    // 构造函数
    CalcPI();

    // 析构函数
    ~CalcPI();

    // 主函数：计算圆周率到指定长度
    void Calc(int length);

    // 打印结果到命令行（例如 qDebug）
    void PrintPI();

    // 写入计算结果到文件
    void WriteToFile(QFile& fileOut);

  private:
    int L; // 要计算的 π 的位数（精度）
    int N; // 内部数组的实际长度（与位数 L 有关，可能大于 L）

    // 用于高精度计算的整数数组
    int* s; // 最终结果数组
    int* w; // 临时工作数组
    int* v; // 中间计算用数组
    int* q; // 辅助数组

    // 初始化数组，分配内存并设置初值
    void InitArrays(int length);

    // 清理所有动态数组，释放内存
    void ClearAll();

    // 高精度加法：res = a + b
    void add(int* a, int* b, int* res);

    // 高精度减法：res = a - b
    void sub(int* a, int* b, int* res);

    // 高精度除法：res = a / b（b 是普通整数）
    void div(int* a, int b, int* res);
};

#endif // CALCPI_H
```

#### calcpi.cpp

```cpp
#include "calcpi.h"
#include <QByteArray>
#include <QString>
#include <cstdio>
#include <cstdlib>
using namespace std;

// 构造函数：初始化所有成员变量为默认状态
CalcPI::CalcPI() {
    L = 0;
    N = 0;
    s = nullptr;
    w = nullptr;
    v = nullptr;
    q = nullptr;
}

// 析构函数：释放动态分配的数组
CalcPI::~CalcPI() {
    ClearAll();
}

// 主计算函数，计算圆周率到指定长度
void CalcPI::Calc(int length) {
    if (length < 1) return; // 长度非法则返回

    ClearAll();         // 释放之前的数组
    InitArrays(length); // 重新初始化数组

    // 根据 Machin 公式计算 π：
    // π = 16 * arctan(1/5) - 4 * arctan(1/239)
    int n = static_cast<int>(L / 1.39793 + 1); // 推测需要多少项级数展开
    int k;

    w[0] = 16 * 5;  // 表示 16 / 5
    v[0] = 4 * 239; // 表示 4 / 239

    for (k = 1; k <= n; k++) {
        div(w, 25, w);        // w /= 25 => 相当于 1/(5^2)
        div(v, 239, v);       // v /= 239
        div(v, 239, v);       // v /= 239 再次除 => 相当于 1/(239^2)
        sub(w, v, q);         // q = w - v
        div(q, 2 * k - 1, q); // q /= (2k - 1)

        if (k % 2) {
            add(s, q, s); // 奇数项加
        } else {
            sub(s, q, s); // 偶数项减
        }
    }
}

// 释放所有动态分配的数组
void CalcPI::ClearAll() {
    delete[] s;
    s = nullptr;
    delete[] w;
    w = nullptr;
    delete[] v;
    v = nullptr;
    delete[] q;
    q = nullptr;
}

// 初始化所有数组，并清零
void CalcPI::InitArrays(int length) {
    L = length;    // 要计算的位数
    N = L / 4 + 1; // 每个数组元素存储 4 位十进制数，因此长度为 L/4 + 1

    s = new int[N + 3]; // 多分配几个用于安全边界
    w = new int[N + 3];
    v = new int[N + 3];
    q = new int[N + 3];

    for (int i = 0; i < N + 3; i++) {
        s[i] = 0;
        w[i] = 0;
        v[i] = 0;
        q[i] = 0;
    }
}

// 高精度加法：c = a + b
void CalcPI::add(int* a, int* b, int* c) {
    int carry = 0;
    for (int i = N + 1; i >= 0; i--) {
        c[i] = a[i] + b[i] + carry;
        if (c[i] < 10000) {
            carry = 0;
        } else {
            c[i] -= 10000;
            carry = 1;
        }
    }
}

// 高精度减法：c = a - b
void CalcPI::sub(int* a, int* b, int* c) {
    int borrow = 0;
    for (int i = N + 1; i >= 0; i--) {
        c[i] = a[i] - b[i] - borrow;
        if (c[i] >= 0) {
            borrow = 0;
        } else {
            c[i] += 10000;
            borrow = 1;
        }
    }
}

// 高精度整数除法：c = a / b
void CalcPI::div(int* a, int b, int* c) {
    int remain = 0;
    for (int i = 0; i <= N + 1; i++) {
        int tmp = a[i] + remain;
        c[i] = tmp / b;
        remain = (tmp % b) * 10000; // 保留余数乘进位
    }
}

// 打印 π 到控制台（如终端）
void CalcPI::PrintPI() {
    if (L < 1) return;
    printf("%d.", s[0]); // 整数部分
    for (int k = 1; k < N; k++) {
        printf("%04d", s[k]); // 每段补齐4位
    }
    printf("\n");
}

// 将 π 写入到指定的 QFile 文件
void CalcPI::WriteToFile(QFile& fileOut) {
    if (L < 1) return;

    // 打头的整数部分 + 小数点
    QString strTemp = QFile::tr("%1.").arg(s[0]);
    fileOut.write(strTemp.toUtf8());

    // 写入小数部分
    for (int k = 1; k < N; k++) {
        strTemp = QFile::tr("%1").arg(s[k], 4, 10, QChar('0')); // 补足4位，不足前导0
        fileOut.write(strTemp.toUtf8());
    }
}
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
    <width>330</width>
    <height>233</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QLabel" name="label">
       <property name="text">
        <string>长度</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QRadioButton" name="radioButton1k">
       <property name="text">
        <string>1000位</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QRadioButton" name="radioButton2k">
       <property name="text">
        <string>2000位</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QRadioButton" name="radioButton4k">
       <property name="text">
        <string>4000位</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QRadioButton" name="radioButton8k">
       <property name="text">
        <string>8000位</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QPushButton" name="btnCalcPI">
       <property name="text">
        <string>计算PI</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnCalcAll">
       <property name="text">
        <string>计算四种PI</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <widget class="QTextEdit" name="textEdit"/>
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

#include "calcpi.h"
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
    void on_btnCalcPI_clicked();

    void on_btnCalcAll_clicked();

  private:
    Ui::Widget* ui;
    // 用于计算pi的类对象
    CalcPI m_calcPI;
    // 获取单选按钮对应的PI长度
    int getPILength();
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDebug>
#include <QDir>
#include <QElapsedTimer> // 用于计算耗时
#include <QMessageBox>
#include <QTemporaryDir>  // 用于创建临时文件夹
#include <QTemporaryFile> // 用于创建临时文件

// 构造函数，初始化 UI 界面
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);
    ui->radioButton1k->setChecked(true);                         // 默认选择 1k 精度
    qDebug() << tr("应用程序名称：") << qApp->applicationName(); // 打印程序名
    qDebug() << tr("系统临时文件路径：") << QDir::tempPath();    // 打印临时目录路径
}

// 析构函数，释放 UI 资源
Widget::~Widget() {
    delete ui;
}

// 获取用户在界面中选择的 PI 精度长度
int Widget::getPILength() {
    if (ui->radioButton1k->isChecked()) {
        return 1000;
    } else if (ui->radioButton2k->isChecked()) {
        return 2000;
    } else if (ui->radioButton4k->isChecked()) {
        return 4000;
    } else {
        return 8000;
    }
}

// “计算 PI” 按钮的槽函数
void Widget::on_btnCalcPI_clicked() {
    int nPILength = getPILength(); // 获取计算位数
    QElapsedTimer eTimer;
    eTimer.start(); // 启动计时器

    m_calcPI.Calc(nPILength); // 执行 PI 计算

    qint64 nms = eTimer.elapsed(); // 获取耗时（单位：毫秒）

    // 创建一个临时文件保存计算结果
    QTemporaryFile tf;
    if (!tf.open()) {
        QMessageBox::information(this, tr("打开临时文件"), tr("打开临时文件失败！"));
        return;
    }

    tf.setAutoRemove(false); // 设置为不自动删除（为了查看生成结果）

    m_calcPI.WriteToFile(tf); // 将结果写入临时文件

    // 构造输出信息并展示到文本框
    QString strInfo;
    strInfo += tr("计算 %1 位 PI 耗时 %2 毫秒\r\n").arg(nPILength).arg(nms);
    strInfo += tr("保存到临时文件：\r\n%1\r\n").arg(tf.fileName());

    ui->textEdit->setText(strInfo);
}

// “计算所有精度 PI” 按钮的槽函数
void Widget::on_btnCalcAll_clicked() {
    // 创建一个临时目录用于保存所有精度的结果文件
    QTemporaryDir td("PI-"); // 文件夹前缀 PI-
    QString strTempDir;

    if (td.isValid()) {
        strTempDir = td.path();
    } else {
        QMessageBox::warning(this, tr("新建临时文件夹"), tr("新建临时文件夹失败！"));
        return;
    }

    td.setAutoRemove(false); // 设置为不自动删除目录

    QString strInfo; // 最终展示到文本框的信息

    // 依次计算 1000、2000、4000、8000 位的 PI
    for (int i = 1; i <= 8; i *= 2) {
        int nPILength = i * 1000;

        QElapsedTimer eTimer;
        eTimer.start();
        m_calcPI.Calc(nPILength);      // 计算 PI
        qint64 nms = eTimer.elapsed(); // 计算耗时

        // 构造当前输出文件路径
        QString strCurName = strTempDir + tr("/%1.txt").arg(nPILength);
        QFile fileCur(strCurName);

        // 打开文件写入
        if (!fileCur.open(QIODevice::WriteOnly)) {
            QMessageBox::warning(this, tr("新建文件"), tr("新建存储 PI 的文件失败！"));
            return;
        }

        m_calcPI.WriteToFile(fileCur); // 写入 PI 到文件

        // 构造结果字符串
        strInfo += tr("计算 %1 位 PI，耗时 %2 毫秒\r\n存到 %3 \r\n\r\n").arg(nPILength).arg(nms).arg(fileCur.fileName());
    }

    // 显示所有结果到文本框
    ui->textEdit->setText(strInfo);
}
```

