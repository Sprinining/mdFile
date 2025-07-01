## Qt 基本文件读写 QFile

### Qt 文件类及 IO 类继承和关联图

```css
QObject
│
├── QIODevice                          // 所有 I/O 设备的抽象基类
│   │
│   ├── QFileDevice                    // 文件设备抽象基类
│   │   │
│   │   ├── QFile                      // 用于读写真实文件
│   │   └── QTemporaryFile            // 用于读写临时文件（自动删除）
│   │
│   ├── QBuffer                        // 内存缓冲区（读写 QByteArray）
│   ├── QProcess                       // 管理子进程的 stdin/stdout
│   └── QTcpSocket / QTcpServer / ... // 网络设备（继承自 QIODevice）
│
├── QTextStream                        // 面向文本的读写流，操作 QIODevice
├── QDataStream                        // 面向二进制的读写流，操作 QIODevice
└── QSaveFile                          // 原子保存文件（常配合 QFile 使用）
```

`QIODevice`

- 抽象基类，定义了所有设备的通用接口，如 `open()`, `read()`, `write()`, `seek()` 等。
- 所有读写类都继承自它。

`QFileDevice`

- 提供具体的文件设备接口，封装了文件权限、文件指针、同步等底层操作。
- 不能直接使用，实际使用的是其子类。

`QFile`

- 实际用于打开和操作磁盘文件（支持文本/二进制/随机访问等）。

`QBuffer`

- 在内存中读写 `QByteArray`，常用于模拟文件或网络传输。

`QProcess`

- 处理子进程的标准输入输出（也是 `QIODevice`），可以像文件一样读写。

`QTextStream`

- 用于以 **文本格式** 操作 `QIODevice`（支持编码、换行、格式控制等）。

`QDataStream`

- 用于以 **二进制格式** 操作 `QIODevice`（常用于 Qt 对象序列化）。

`QSaveFile`

- 提供一种原子保存文件的方法（避免写到一半中断导致文件损坏）。
- 通常和 `QTextStream` / `QDataStream` 配合使用。

### QIODevice

`QIODevice` 是 Qt 中所有**输入/输出设备类的抽象基类**，用于统一管理数据的读取、写入、打开、关闭等操作。

它是 `QFile`、`QBuffer`、`QProcess`、`QTcpSocket` 等类的父类，提供了通用的数据传输接口。无论是读写文件、内存、网络还是子进程，都可以通过 `QIODevice` 的统一 API 进行处理。

#### 常用操作方法

| 方法                            | 说明                                 |
| ------------------------------- | ------------------------------------ |
| `open(OpenMode mode)`           | 打开设备，例如 `QIODevice::ReadOnly` |
| `isOpen()`                      | 检查设备是否打开                     |
| `isReadable()` / `isWritable()` | 检查是否可读/写                      |
| `read(qint64 maxSize)`          | 读取数据，返回 `QByteArray`          |
| `readAll()`                     | 一次性读取全部数据                   |
| `write(const QByteArray &)`     | 写入数据                             |
| `seek(qint64 pos)`              | 移动读写指针                         |
| `pos()` / `size()`              | 获取当前位置 / 总大小                |
| `close()`                       | 关闭设备                             |
| `bytesAvailable()`              | 返回可读取的字节数                   |
| `atEnd()`                       | 是否读取到末尾                       |

#### 打开模式（OpenMode）

`QIODevice::OpenMode` 是一个枚举，可以组合使用：

| 标志         | 含义                                      |
| ------------ | ----------------------------------------- |
| `ReadOnly`   | 只读模式                                  |
| `WriteOnly`  | 只写模式                                  |
| `ReadWrite`  | 读写模式                                  |
| `Append`     | 写入时追加到末尾                          |
| `Text`       | 以文本模式读写（自动处理 `\n` -> `\r\n`） |
| `Unbuffered` | 不使用缓冲（每次操作直接生效）            |

#### 示例代码

```cpp
QFile file("data.txt");
if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    QByteArray content = file.readAll(); // 使用 QIODevice 的方法
    file.close();
}
```

```cpp
QBuffer buffer;
buffer.open(QIODevice::ReadWrite);
buffer.write("hello");    // 写入到内存中
buffer.seek(0);
qDebug() << buffer.readAll(); // 输出：hello
```

### QFile

`QFile` 是 Qt 提供的一个用于操作本地文件的类，继承自 `QFileDevice` 和 `QIODevice`，属于 **低层 I/O 类别**，可用于读取、写入、创建、删除等文件操作，兼容所有主流平台（Windows、Linux、macOS 等）。

#### 常用成员函数

##### 构造与文件名设置

| 函数                                    | 说明                      |
| --------------------------------------- | ------------------------- |
| `QFile()`                               | 创建一个空的 `QFile` 对象 |
| `QFile(const QString &name)`            | 创建并指定文件名的对象    |
| `void setFileName(const QString &name)` | 设置文件路径              |
| `QString fileName() const`              | 返回当前文件路径          |

注意：`QFile` 构造后需要调用 `open()` 才能进行操作。

##### 打开 / 关闭 / 状态检查

这些函数大部分来自 `QIODevice`，`QFile` 继承后直接使用：

| 函数                       | 说明                            |
| -------------------------- | ------------------------------- |
| `bool open(OpenMode mode)` | 打开文件，`OpenMode` 是组合标志 |
| `void close()`             | 关闭文件                        |
| `bool isOpen() const`      | 判断文件是否已打开              |
| `bool isReadable() const`  | 是否可读                        |
| `bool isWritable() const`  | 是否可写                        |
| `bool atEnd() const`       | 是否读到文件末尾                |
| `bool seek(qint64 pos)`    | 设置文件读写指针位置            |
| `qint64 pos() const`       | 当前读写指针的位置              |
| `qint64 size() const`      | 文件大小（字节数）              |

##### 读写函数（继承自 QIODevice）

| 函数                                          | 说明                             |
| --------------------------------------------- | -------------------------------- |
| `qint64 read(char *data, qint64 maxSize)`     | 读取数据到缓冲区                 |
| `QByteArray read(qint64 maxSize)`             | 读取 `maxSize` 字节数据          |
| `QByteArray readAll()`                        | 读取整个文件内容                 |
| `qint64 write(const char *data, qint64 size)` | 写入数据                         |
| `qint64 write(const QByteArray &byteArray)`   | 写入 QByteArray 数据             |
| `qint64 bytesAvailable() const`               | 当前可读取的字节数               |
| `qint64 bytesToWrite() const`                 | 尚未写入的字节数（用于缓冲流）   |
| `bool flush()`                                | 刷新写入缓冲区（适用于某些设备） |

配合 `QTextStream` / `QDataStream` 使用，进行更方便的文本或二进制格式写入。

##### 文件路径与基础属性（QFile 专属）

| 函数                               | 说明                       |
| ---------------------------------- | -------------------------- |
| `QString fileName() const`         | 当前文件路径               |
| `void unsetError()`                | 清除文件错误状态           |
| `bool exists() const` *(静态也可)* | 文件是否存在               |
| `bool resize(qint64 sz)`           | 修改文件大小（截断或扩展） |

##### 文件操作（静态/非静态均可）

| 函数                                                         | 类型 | 说明                   |
| ------------------------------------------------------------ | ---- | ---------------------- |
| `static bool exists(const QString &fileName)`                | 静态 | 判断文件是否存在       |
| `static bool remove(const QString &fileName)`                | 静态 | 删除文件               |
| `bool remove()`                                              | 成员 | 删除当前对象指向的文件 |
| `static bool copy(const QString &src, const QString &dest)`  | 静态 | 复制文件               |
| `bool copy(const QString &dest)`                             | 成员 | 复制当前文件到目标路径 |
| `static bool rename(const QString &oldName, const QString &newName)` | 静态 | 重命名文件             |
| `bool rename(const QString &newName)`                        | 成员 | 重命名当前文件         |
| `static QFile::Permissions permissions(const QString &fileName)` | 静态 | 获取权限标志           |
| `static bool setPermissions(const QString &fileName, QFile::Permissions perms)` | 静态 | 修改权限               |

复制/删除/重命名这些操作都是原子性的文件系统操作，平台无差异封装。

##### 权限枚举

```cpp
enum QFile::Permission {
    ReadOwner   = 0x4000, // 文件所有者可读
    WriteOwner  = 0x2000,
    ExeOwner    = 0x1000,
    ReadUser    = 0x0400, // 用户组权限
    WriteUser   = 0x0200,
    ExeUser     = 0x0100,
    ...
};
Q_DECLARE_FLAGS(Permissions, Permission)
```

可以用按位或组合使用，如：

```cpp
QFile::setPermissions("test.txt", QFile::ReadOwner | QFile::WriteOwner);
```

#### 小贴士

| 情况             | 建议                        |
| ---------------- | --------------------------- |
| 频繁写入临时文件 | 使用 `QTemporaryFile` 替代  |
| 要确保写入原子性 | 用 `QSaveFile` 替代 `QFile` |
| 多线程中使用     | 不推荐跨线程共享 `QFile`    |
| 写入失败         | 检查是否有权限或是否已打开  |

### 示例：读写 Unix 风格配置文件

#### testconf.txt

```txt
ip = 192.168.100.222
port = 1234
hostname = mypc
workgroup = ustc
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
    <width>283</width>
    <height>190</height>
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
       <property name="minimumSize">
        <size>
         <width>70</width>
         <height>0</height>
        </size>
       </property>
       <property name="text">
        <string>源文件</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditSrcFile"/>
     </item>
     <item>
      <widget class="QPushButton" name="btnBrowseSrc">
       <property name="text">
        <string>浏览源</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnLoad">
       <property name="text">
        <string>加载配置</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QLabel" name="label_2">
       <property name="minimumSize">
        <size>
         <width>70</width>
         <height>0</height>
        </size>
       </property>
       <property name="text">
        <string>目的文件</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditDstFile"/>
     </item>
     <item>
      <widget class="QPushButton" name="btnBrowseDst">
       <property name="text">
        <string>浏览目的</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnSave">
       <property name="text">
        <string>保存配置</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_3">
     <item>
      <widget class="QLabel" name="label_3">
       <property name="minimumSize">
        <size>
         <width>70</width>
         <height>0</height>
        </size>
       </property>
       <property name="text">
        <string>IP</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditIP"/>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_4">
     <item>
      <widget class="QLabel" name="label_4">
       <property name="minimumSize">
        <size>
         <width>70</width>
         <height>0</height>
        </size>
       </property>
       <property name="text">
        <string>Port</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditPort"/>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_5">
     <item>
      <widget class="QLabel" name="label_5">
       <property name="minimumSize">
        <size>
         <width>70</width>
         <height>0</height>
        </size>
       </property>
       <property name="text">
        <string>HostName</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditHostName"/>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_6">
     <item>
      <widget class="QLabel" name="label_6">
       <property name="minimumSize">
        <size>
         <width>70</width>
         <height>0</height>
        </size>
       </property>
       <property name="text">
        <string>WorkGroup</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditWorkGroup"/>
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
    void on_btnBrowseSrc_clicked();

    void on_btnLoad_clicked();

    void on_btnBrowseDst_clicked();

    void on_btnSave_clicked();

  private:
    Ui::Widget* ui;
    void AnalyzeOneLine(const QByteArray& baLine);
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
#include <QIntValidator>
#include <QMessageBox>
#include <QRegularExpression>
#include <QRegularExpressionValidator>

// 构造函数：初始化 UI 和输入校验
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 设置 IP 地址输入框的正则校验器，确保格式合法
    QRegularExpression re("^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}"
                          "(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$");
    QRegularExpressionValidator* reVail = new QRegularExpressionValidator(re);
    ui->lineEditIP->setValidator(reVail);

    // 设置端口号输入框的整数校验器，范围 0-65535
    QIntValidator* intVali = new QIntValidator(0, 65535);
    ui->lineEditPort->setValidator(intVali);
}

// 析构函数：释放 UI 内存
Widget::~Widget() {
    delete ui;
}

// 浏览选择源配置文件按钮点击事件
void Widget::on_btnBrowseSrc_clicked() {
    QString strSrcName = QFileDialog::getOpenFileName(this, tr("打开配置文件"), tr("."), tr("Text files(*.txt);;All files(*)"));
    if (strSrcName.isEmpty()) return;         // 用户取消选择
    ui->lineEditSrcFile->setText(strSrcName); // 显示到 UI 上
}

// 加载配置文件按钮点击事件
void Widget::on_btnLoad_clicked() {
    QString strSrc = ui->lineEditSrcFile->text();
    if (strSrc.isEmpty()) return;

    QFile fileIn(strSrc);
    if (!fileIn.open(QIODevice::ReadOnly)) {
        // 打开失败，弹出提示框显示错误信息
        QMessageBox::warning(this, tr("打开错误"), tr("打开文件错误：") + fileIn.errorString());
        return;
    }

    // 按行读取文件内容
    while (!fileIn.atEnd()) {
        QByteArray baLine = fileIn.readLine().trimmed();
        if (baLine.startsWith('#')) continue; // 跳过注释行
        AnalyzeOneLine(baLine);               // 解析每一行配置
    }

    QMessageBox::information(this, tr("加载配置"), tr("加载配置项完毕！"));
}

// 浏览保存目标文件按钮点击事件
void Widget::on_btnBrowseDst_clicked() {
    QString strDstName = QFileDialog::getSaveFileName(this, tr("保存配置文件"), tr("."), tr("Text files(*.txt);;All files(*)"));
    if (strDstName.isEmpty()) return;
    ui->lineEditDstFile->setText(strDstName); // 显示保存路径
}

// 保存配置按钮点击事件
void Widget::on_btnSave_clicked() {
    QString strSaveName = ui->lineEditDstFile->text();
    QString strIP = ui->lineEditIP->text();
    QString strPort = ui->lineEditPort->text();
    QString strHostName = ui->lineEditHostName->text();
    QString strWorkGroup = ui->lineEditWorkGroup->text();

    // 检查所有项是否填写完整
    if (strSaveName.isEmpty() || strIP.isEmpty() || strPort.isEmpty() || strHostName.isEmpty() || strWorkGroup.isEmpty()) {
        QMessageBox::warning(this, tr("保存配置"), tr("需要设置好保存文件名和所有配置项数值。"));
        return;
    }

    QFile fileOut(strSaveName);
    // 打开输出文件（覆盖模式）
    if (!fileOut.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        QMessageBox::warning(this, tr("打开文件"), tr("打开目的文件失败：") + fileOut.errorString());
        return;
    }

    // 写入各项配置到文件
    QByteArray baTemp = "ip = ";
    baTemp += strIP.toLocal8Bit() + "\n";
    fileOut.write(baTemp);

    baTemp = "port = ";
    baTemp += strPort.toLocal8Bit() + "\n";
    fileOut.write(baTemp);

    baTemp = "hostname = ";
    baTemp += strHostName.toLocal8Bit() + "\n";
    fileOut.write(baTemp);

    baTemp = "workgroup = ";
    baTemp += strWorkGroup.toLocal8Bit() + "\n";
    fileOut.write(baTemp);

    QMessageBox::information(this, tr("保存配置"), tr("保存配置项成功！"));
}

// 解析一行配置的函数（key=value 格式）
void Widget::AnalyzeOneLine(const QByteArray& baLine) {
    QList<QByteArray> list = baLine.split('=');
    if (list.count() < 2) return; // 非法行

    QByteArray optionName = list[0].trimmed().toLower();    // 统一为小写
    QByteArray optionValue = list[1].trimmed();             // 去除空白
    QString strValue = QString::fromLocal8Bit(optionValue); // 转为 QString

    // 根据字段名设置 UI 中对应输入框
    if ("ip" == optionName) {
        ui->lineEditIP->setText(strValue);
        return;
    }
    if ("port" == optionName) {
        ui->lineEditPort->setText(strValue);
        return;
    }
    if ("hostname" == optionName) {
        ui->lineEditHostName->setText(strValue);
        return;
    }
    if ("workgroup" == optionName) {
        ui->lineEditWorkGroup->setText(strValue);
        return;
    }
}

```

### 示例：BMP 头文件解析

#### BMP 文件大致结构

```css
| Offset | 大小（字节） | 名称                     | 描述
|--------|---------------|--------------------------|----------------------------------------
| 0      | 2             | 文件类型标识符 (bfType)   | 固定为 'BM'（0x42 0x4D）
| 2      | 4             | 文件大小 (bfSize)         | 整个 BMP 文件的大小（单位字节）
| 6      | 2             | 保留1 (bfReserved1)       | 保留，一般为 0
| 8      | 2             | 保留2 (bfReserved2)       | 保留，一般为 0
| 10     | 4             | 像素数据偏移 (bfOffBits)  | 从文件头到像素数据的偏移量

| 14     | 4             | 信息头大小 (biSize)       | 位图信息头的大小（通常为 40）
| 18     | 4             | 图像宽度 (biWidth)        | 以像素为单位
| 22     | 4             | 图像高度 (biHeight)       | 以像素为单位（正数：倒置，负数：正置）
| 26     | 2             | 色平面数 (biPlanes)       | 必须为 1
| 28     | 2             | 每像素位数 (biBitCount)   | 如 1, 4, 8, 16, 24, 32
| 30     | 4             | 压缩方式 (biCompression)  | 0（BI_RGB）表示不压缩
| 34     | 4             | 图像大小 (biSizeImage)    | 实际图像数据大小（可能为 0）
| 38     | 4             | 水平分辨率 (biXPelsPerMeter)| 像素/米
| 42     | 4             | 垂直分辨率 (biYPelsPerMeter)| 像素/米
| 46     | 4             | 使用颜色数 (biClrUsed)    | 调色板颜色数（0表示全部）
| 50     | 4             | 重要颜色数 (biClrImportant)| 0 表示全部重要

| ...    | 可变大小       | 调色板（可选）             | 如果是 1、4 或 8 位图会有调色板
| ...    | 可变大小       | 位图像素数据               | 按行从下往上，BGR 顺序存储
```

把 BMPFileHeader 定义如下：

```cpp
struct BMPFileHeader {
    quint16 bfType;      // 文件类型，原始两字节 'BM'
    quint32 bfSize;      // BMP图片文件大小
    quint16 bfReserved1; // 保留字段1，数值为 0
    quint16 bfReserved2; // 保留字段2，数值为 0
    quint32 bfOffBits;   // 像素点数据起始位置，相对于 BMPFileHeader 的偏移量，以字节为单位
};
```

信息头 BMPInfoHeader：

```cpp
struct BMPInfoHeader {
    quint32 biSize;          // 本结构体长度，占用字节数
    quint32 biWidth;         // 图片宽度，像素点数
    quint32 biHeight;        // 图片高度，像素点数
    quint16 biPlanes;        // 目标设备级别，数值为 1 (图层数或叫帧数)
    quint16 biBitCount;      // 每个像素点占用的位数，就是颜色深度 (位深度)
    quint32 biCompression;   // 是否压缩，一般为 0 不压缩
    quint32 biSizeImage;     // 像素点数据总共占用的字节数，因为每行像素点数据末尾会按4字节对齐，对齐需要的字节数也算在内
    quint32 biXPelsPerMeter; // 水平分辨率，像素点数每米(== 水平DPI * 39.3701)
    quint32 biYPelsPerMeter; // 垂直分辨率，像素点数每米(== 垂直DPI * 39.3701)
    quint32 biClrUsed;       // 颜色表中实际用到的颜色数目
    quint32 biClrImportant;  // 图片显示中重要颜色数目
};
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
    <height>360</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QLabel" name="label">
       <property name="text">
        <string>文件名</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditName"/>
     </item>
     <item>
      <widget class="QPushButton" name="btnBrowser">
       <property name="text">
        <string>浏览</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QPushButton" name="btnShowPic">
       <property name="text">
        <string>显示图片</string>
       </property>
      </widget>
     </item>
     <item>
      <spacer name="horizontalSpacer">
       <property name="orientation">
        <enum>Qt::Orientation::Horizontal</enum>
       </property>
       <property name="sizeHint" stdset="0">
        <size>
         <width>40</width>
         <height>20</height>
        </size>
       </property>
      </spacer>
     </item>
     <item>
      <widget class="QPushButton" name="btnReadHeader">
       <property name="text">
        <string>读取头部</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_4">
     <item>
      <widget class="QScrollArea" name="scrollArea">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Expanding" vsizetype="Expanding">
         <horstretch>3</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
       </property>
       <property name="widgetResizable">
        <bool>true</bool>
       </property>
       <widget class="QWidget" name="scrollAreaWidgetContents">
        <property name="geometry">
         <rect>
          <x>0</x>
          <y>0</y>
          <width>339</width>
          <height>276</height>
         </rect>
        </property>
        <layout class="QHBoxLayout" name="horizontalLayout_3">
         <item>
          <widget class="QLabel" name="labelShowPic">
           <property name="sizePolicy">
            <sizepolicy hsizetype="Expanding" vsizetype="Expanding">
             <horstretch>0</horstretch>
             <verstretch>0</verstretch>
            </sizepolicy>
           </property>
           <property name="text">
            <string>显示图片区域</string>
           </property>
           <property name="alignment">
            <set>Qt::AlignmentFlag::AlignCenter</set>
           </property>
          </widget>
         </item>
        </layout>
       </widget>
      </widget>
     </item>
     <item>
      <widget class="QTextBrowser" name="textBrowser">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Expanding" vsizetype="Expanding">
         <horstretch>1</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
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

// ==================== BMP 头结构定义区域 ==================== //

// 为了避免结构体因为字节对齐而产生错误的大小，强制使用 1 字节对齐
// BMP 文件头长度应为 14 字节，信息头长度应为 40 字节
#pragma pack(1)

// BMP 文件头结构（Bitmap File Header），共 14 字节
struct BMPFileHeader {
    quint16 bfType;      // 文件类型标志，必须为 'BM' (0x4D42)，表示为位图文件
    quint32 bfSize;      // 文件大小（单位：字节），包括文件头、信息头、颜色表和像素数据
    quint16 bfReserved1; // 保留字段，必须为 0
    quint16 bfReserved2; // 保留字段，必须为 0
    quint32 bfOffBits;   // 像素数据的起始偏移（单位：字节），相对于文件开头的偏移量
};

// BMP 信息头结构（Bitmap Info Header），共 40 字节
struct BMPInfoHeader {
    quint32 biSize;          // 信息头结构体大小（应为 40）
    quint32 biWidth;         // 图像宽度（单位：像素）
    quint32 biHeight;        // 图像高度（单位：像素），正值表示从下到上绘制，负值为从上到下绘制
    quint16 biPlanes;        // 色彩平面数，必须为 1（始终为 1）
    quint16 biBitCount;      // 每像素所占位数（即色深），常见值为 1, 4, 8, 24, 32
    quint32 biCompression;   // 压缩方式（0 = BI_RGB 不压缩，1 = BI_RLE8，2 = BI_RLE4 等）
    quint32 biSizeImage;     // 图像数据所占字节数（不包括头和调色板，可能为 0）
    quint32 biXPelsPerMeter; // 水平分辨率（像素/米）
    quint32 biYPelsPerMeter; // 垂直分辨率（像素/米）
    quint32 biClrUsed;       // 实际使用的调色板颜色数（0 表示使用所有）
    quint32 biClrImportant;  // 重要颜色数（0 表示所有颜色都重要）
};

// ==================== Qt UI 主窗口类定义 ==================== //

QT_BEGIN_NAMESPACE
namespace Ui {
class Widget;
}
QT_END_NAMESPACE

// 主窗口类定义，继承自 QWidget
class Widget : public QWidget {
    Q_OBJECT

  public:
    Widget(QWidget* parent = nullptr);
    ~Widget();

  private slots:
    // 槽函数：点击 “浏览文件” 按钮
    void on_btnBrowser_clicked();
    // 槽函数：点击 “显示图片” 按钮
    void on_btnShowPic_clicked();
    // 槽函数：点击 “读取 BMP 头部” 按钮
    void on_btnReadHeader_clicked();

  private:
    // UI 指针，用于访问界面上的控件
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
#include <QMessageBox>
#include <QPixmap>

// 构造函数：初始化 UI 并打印 BMP 文件头、信息头大小
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 打印 BMP 文件头（14 字节）和信息头（40 字节）的大小
    qDebug() << tr("BFH: %1 B").arg(sizeof(BMPFileHeader));
    qDebug() << tr("BIH: %1 B").arg(sizeof(BMPInfoHeader));
}

Widget::~Widget() {
    delete ui;
}

// 浏览 BMP 文件按钮槽函数
void Widget::on_btnBrowser_clicked() {
    // 打开文件选择对话框，过滤为 .bmp 文件
    QString strName = QFileDialog::getOpenFileName(this, tr("打开BMP"), tr("."), tr("BMP Files(*.bmp);;All Files(*)"));
    if (strName.isEmpty()) return; // 用户取消则直接返回

    // 显示所选文件路径到行编辑框
    ui->lineEditName->setText(strName);
}

// 显示图片按钮槽函数
void Widget::on_btnShowPic_clicked() {
    QString strName = ui->lineEditName->text();
    if (strName.isEmpty()) return;

    // 加载 BMP 图片到 QLabel 中
    ui->labelShowPic->setPixmap(QPixmap(strName));
}

// 读取 BMP 文件头按钮槽函数
void Widget::on_btnReadHeader_clicked() {
    QString strName = ui->lineEditName->text();
    if (strName.isEmpty()) return;

    // 打开 BMP 文件
    QFile fileIn(strName);
    if (!fileIn.open(QIODevice::ReadOnly)) {
        QMessageBox::warning(this, tr("打开文件"), tr("打开文件失败：") + fileIn.errorString());
        return;
    }

    // 定义 BMP 文件头和信息头结构体
    BMPFileHeader bfh;
    BMPInfoHeader bih;

    // 从文件中读取 BMP 文件头和信息头
    qint64 nReadBFH = fileIn.read((char*)&bfh, sizeof(bfh));
    qint64 nReadBIH = fileIn.read((char*)&bih, sizeof(bih));

    // 检查是否成功读取全部头部内容
    if ((nReadBFH < sizeof(bfh)) || (nReadBIH < sizeof(bih))) {
        QMessageBox::warning(this, tr("读取 BMP"), tr("读取 BMP 头部失败，头部字节数不够！"));
        return;
    }

    // 构建信息字符串用于显示
    QString strInfo = tr("文件名：%1\r\n\r\n").arg(strName);
    QString strTemp;

    // 检查 BMP 标识（'BM' = 0x4D42）
    if (bfh.bfType != 0x4D42) {
        strTemp = tr("类型：不是 BMP 图片\r\n");
        strInfo += strTemp;
    } else {
        strTemp = tr("类型：是 BMP 图片\r\n");
        strInfo += strTemp;

        // 显示宽度
        strTemp = tr("宽度：%1\r\n").arg(bih.biWidth);
        strInfo += strTemp;

        // 显示高度（注意 BMP 高度可能为负，表示倒序）
        strTemp = tr("高度：%1\r\n").arg(bih.biHeight);
        strInfo += strTemp;

        // 显示水平分辨率（像素/米 -> DPI）
        strTemp = tr("水平分辨率：%1 DPI\r\n").arg((int)(bih.biXPelsPerMeter / 39.3701));
        strInfo += strTemp;

        // 显示垂直分辨率（像素/米 -> DPI）
        strTemp = tr("垂直分辨率：%1 DPI\r\n").arg((int)(bih.biYPelsPerMeter / 39.3701));
        strInfo += strTemp;

        // 显示颜色位数
        strTemp = tr("颜色深度：%1 位\r\n").arg(bih.biBitCount);
        strInfo += strTemp;

        // 显示颜色平面数（通常为 1）
        strTemp = tr("帧数：%1\r\n").arg(bih.biPlanes);
        strInfo += strTemp;
    }

    // 显示信息到界面 textBrowser 控件
    ui->textBrowser->setText(strInfo);
}
```

