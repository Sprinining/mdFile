## Qt 串行化数据流 QDataStream

### QDataStream

`QDataStream` 是 Qt 框架中用于对二进制数据进行序列化和反序列化的类。它提供了一种方便的方法，把各种数据类型（如基本类型、Qt 类型、甚至自定义类型）以平台无关的格式写入或从设备（如文件、内存、网络套接字）中读取。

#### 主要用途

- **数据持久化**：将数据结构以二进制形式写入文件，便于后续读取。

- **网络传输**：在网络通信中对数据进行打包和解包。

- **跨平台数据交换**：保证不同系统间数据的兼容性，避免字节序（大小端）问题。

#### 核心特点

- 支持 **内置数据类型**（int、float、QString、QByteArray、QList 等）序列化。

- 支持用户自定义类型（通过重载操作符）。

- 自动处理数据的字节序（默认使用大端序，Qt::BigEndian）。

- 方便的操作符重载 `<<` 和 `>>`，类似流式写入和读取。

#### 常用接口示例

```cpp
#include <QFile>
#include <QDataStream>
#include <QString>
#include <QList>

void writeData(const QString& filename) {
    QFile file(filename);
    if (!file.open(QIODevice::WriteOnly))
        return;

    QDataStream out(&file);
    out.setVersion(QDataStream::Qt_6_0);  // 设置版本，保证兼容性

    int number = 42;
    QString text = "Hello QDataStream";
    QList<int> list = {1, 2, 3, 4, 5};

    out << number << text << list;  // 序列化写入
}

void readData(const QString& filename) {
    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly))
        return;

    QDataStream in(&file);
    in.setVersion(QDataStream::Qt_6_0);  // 与写入时保持版本一致

    int number;
    QString text;
    QList<int> list;

    in >> number >> text >> list;  // 反序列化读取

    qDebug() << number << text << list;
}
```

#### 自定义类型支持

如果需要序列化自定义类型，需要重载 `<<` 和 `>>` 操作符：

```cpp
struct Point {
    int x;
    int y;
};

QDataStream& operator<<(QDataStream& out, const Point& p) {
    out << p.x << p.y;
    return out;
}

QDataStream& operator>>(QDataStream& in, Point& p) {
    in >> p.x >> p.y;
    return in;
}
```

- **版本控制**：`QDataStream::setVersion()` 重要，防止不同 Qt 版本间的兼容性问题。

- **字节序**：Qt 默认使用大端字节序，如果与其他系统交互，注意设置。

- **错误检测**：通过 `QDataStream::status()` 方法检查流状态，判断是否读取成功。

### 示例：自定义文件格式输入输出

#### 自定义文件格式结构

| 字节偏移 | 数据内容                    | 类型                            | 说明                                             |
| -------- | --------------------------- | ------------------------------- | ------------------------------------------------ |
| 0        | 0x4453                      | `qint16`                        | 文件魔数，用于识别是 `.ds` 文件（"DS" 两个字符） |
| 2        | 0x0100                      | `qint16`                        | 文件版本号（v1.0）                               |
| 4        | 行数（数据条目数）          | `qint32`                        | 总共有几行数据                                   |
| 8~...    | 每行的三项数据（循环 N 次） | `QString` + `qint32` + `double` | 分别表示 姓名、年龄、体重                        |

```css
[文件头]
- 0x4453            (qint16 魔数)
- 0x0100            (qint16 版本号)
- nCount            (qint32 总行数)

[数据部分] × nCount
- QString 姓名
- qint32 年龄
- double 体重
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
        <string>年龄</string>
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
      <widget class="QPushButton" name="btnAdd">
       <property name="text">
        <string>添加行</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QListWidget" name="listWidget"/>
     </item>
     <item>
      <layout class="QVBoxLayout" name="verticalLayout">
       <item>
        <widget class="QPushButton" name="btnDel">
         <property name="text">
          <string>删除行</string>
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
        <widget class="QPushButton" name="btnSaveDS">
         <property name="text">
          <string>保存DS</string>
         </property>
        </widget>
       </item>
       <item>
        <widget class="QPushButton" name="btnLoadDS">
         <property name="text">
          <string>加载DS</string>
         </property>
        </widget>
       </item>
      </layout>
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
    void on_btnAdd_clicked();
    void on_btnDel_clicked();
    void on_btnSaveDS_clicked();
    void on_btnLoadDS_clicked();
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
#include <QDataStream>
#include <QDebug>
#include <QFile>
#include <QFileDialog>
#include <QListWidgetItem>
#include <QMessageBox>
#include <QTextStream>

// 构造函数，初始化 UI 和列表控件选择模式
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);
    // 设置列表控件只能单选
    ui->listWidget->setSelectionMode(QAbstractItemView::SingleSelection);
}

// 析构函数，释放 UI 资源
Widget::~Widget() {
    delete ui;
}

// 点击“添加”按钮的槽函数
void Widget::on_btnAdd_clicked() {
    // 获取输入框中的数据
    QString strName = ui->lineEditName->text().trimmed();
    QString strAge = ui->lineEditAge->text().trimmed();
    QString strWeight = ui->lineEditWeight->text().trimmed();

    // 检查三个数据项是否为空
    if (strName.isEmpty() || strAge.isEmpty() || strWeight.isEmpty()) {
        QMessageBox::warning(this, tr("添加行"), tr("请填好姓名、年龄、体重三个数据项再添加。"));
        return;
    }

    // 将年龄和体重字符串转换为数值
    qint32 nAge = strAge.toInt();
    double dblWeight = strWeight.toDouble();

    // 年龄和体重范围校验
    if ((nAge < 0) || (nAge > 600)) {
        QMessageBox::warning(this, tr("添加行"), tr("年龄数值不对，应该 0~600 "));
        return;
    }
    if (dblWeight < 0.1) {
        QMessageBox::warning(this, tr("添加行"), tr("体重数值不对，至少 0.1kg "));
        return;
    }

    // 构造用于显示的字符串行
    QString strAll;
    QTextStream tsLine(&strAll);
    tsLine << strName << "\t" << nAge << "\t" << Qt::fixed << qSetRealNumberPrecision(2) << dblWeight;

    // 添加到 listWidget 控件中
    ui->listWidget->addItem(strAll);
}

// 点击“删除”按钮的槽函数
void Widget::on_btnDel_clicked() {
    // 获取当前选中行
    int nCurRow = ui->listWidget->currentRow();
    if (nCurRow < 0) return; // 未选中任何行则不操作

    // 删除该行
    ui->listWidget->takeItem(nCurRow);
}

// 点击“保存 DS 文件”按钮的槽函数
void Widget::on_btnSaveDS_clicked() {
    int nCount = ui->listWidget->count();
    // 无数据不保存
    if (nCount < 1) return;

    // 弹出保存文件对话框
    QString strFileName = QFileDialog::getSaveFileName(this, tr("保存为 DS 文件"), tr("."), tr("DS files(*.ds);;All files(*)"));
    if (strFileName.isEmpty()) return;

    // 打开文件写入
    QFile fileOut(strFileName);
    if (!fileOut.open(QIODevice::WriteOnly)) {
        QMessageBox::warning(this, tr("无法打开文件"), tr("无法打开要写入的文件：") + fileOut.errorString());
        return;
    }

    // 使用 QDataStream 写入二进制数据
    QDataStream dsOut(&fileOut);
    dsOut.setVersion(QDataStream::Qt_6_9); // 设置版本，确保兼容性

    // 写入文件头部（魔数 + 版本 + 行数）
    dsOut << qint16(0x4453); // 'D''S' 文件标识
    dsOut << qint16(0x0100); // 文件版本 1.0
    dsOut << qint32(nCount); // 总行数

    // 写入每行的姓名、年龄、体重数据
    QString strCurName;
    qint32 nCurAge;
    double dblCurWeight;

    for (int i = 0; i < nCount; i++) {
        QString strLine = ui->listWidget->item(i)->text();
        QTextStream tsLine(&strLine);
        tsLine >> strCurName >> nCurAge >> dblCurWeight;
        dsOut << strCurName << nCurAge << dblCurWeight;
    }

    // 写入完成提示
    QMessageBox::information(this, tr("保存DS文件"), tr("保存为 .ds 文件成功！"));
}

// 点击“加载 DS 文件”按钮的槽函数
void Widget::on_btnLoadDS_clicked() {
    // 弹出打开文件对话框
    QString strFileName = QFileDialog::getOpenFileName(this, tr("打开DS文件"), tr("."), tr("DS files(*.ds);;All files(*)"));
    if (strFileName.isEmpty()) return;

    // 打开文件
    QFile fileIn(strFileName);
    if (!fileIn.open(QIODevice::ReadOnly)) {
        QMessageBox::warning(this, tr("打开DS文件"), tr("打开DS文件失败: ") + fileIn.errorString());
        return;
    }

    // 创建数据流读取文件
    QDataStream dsIn(&fileIn);

    // 读取头部数据
    qint16 nDS;
    qint16 nVersion;
    qint32 nCount;
    dsIn >> nDS >> nVersion >> nCount;

    // 检查标识是否合法
    if (0x4453 != nDS) {
        QMessageBox::warning(this, tr("打开文件"), tr("指定的文件不是 .ds 文件类型，无法加载。"));
        return;
    }

    // 检查版本是否支持
    if (0x0100 != nVersion) {
        QMessageBox::warning(this, tr("打开文件"), tr("指定的 .ds 文件格式版本不是 1.0，暂时不支持。"));
        return;
    } else {
        dsIn.setVersion(QDataStream::Qt_6_9); // 设置流版本
    }

    // 检查行数是否有效
    if (nCount < 1) {
        QMessageBox::warning(this, tr("打开文件"), tr("指定的 .ds 文件内数据行计数小于 1，无数据加载。"));
        return;
    }

    // 清空原有内容
    ui->listWidget->clear();

    // 读取每行数据
    QString strCurName;
    qint32 nCurAge;
    double dblCurWeight;

    for (int i = 0; i < nCount; i++) {
        // 检查流状态
        if (dsIn.status() != QDataStream::Ok) {
            qDebug() << tr("第 %1 行读取前的状态出错：%2").arg(i).arg(dsIn.status());
            break;
        }

        // 读取数据项
        dsIn >> strCurName >> nCurAge >> dblCurWeight;

        // 构造显示字符串
        QString strLine = tr("%1\t%2\t%3").arg(strCurName).arg(nCurAge).arg(dblCurWeight, 0, 'f', 2);
        ui->listWidget->addItem(strLine);
    }

    // 提示完成
    QMessageBox::information(this, tr("加载DS文件"), tr("加载DS文件完成！"));
}

// 列表控件选中项变化的槽函数
void Widget::on_listWidget_currentRowChanged(int currentRow) {
    if (currentRow < 0) return; // 无选中项

    // 读取该行数据
    QString strLine = ui->listWidget->item(currentRow)->text();
    QTextStream tsLine(&strLine);

    // 拆分成三个字段
    QString strName;
    int nAge;
    double dblWeight;
    tsLine >> strName >> nAge >> dblWeight;

    // 显示到输入框中
    ui->lineEditName->setText(strName);
    ui->lineEditAge->setText(tr("%1").arg(nAge));
    ui->lineEditWeight->setText(tr("%1").arg(dblWeight));
}
```

### 示例：串行化

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
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QLabel" name="label">
       <property name="text">
        <string>源头端口</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditSrcPort"/>
     </item>
     <item>
      <widget class="QLabel" name="label_2">
       <property name="text">
        <string>目的端口</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditDstPort"/>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QLabel" name="label_3">
       <property name="text">
        <string>报文消息</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditMsg"/>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_3">
     <item>
      <widget class="QListWidget" name="listWidget"/>
     </item>
     <item>
      <layout class="QVBoxLayout" name="verticalLayout">
       <item>
        <widget class="QPushButton" name="btnAddUDP">
         <property name="text">
          <string>添加UDP包</string>
         </property>
        </widget>
       </item>
       <item>
        <widget class="QPushButton" name="btnDelUDP">
         <property name="text">
          <string>删除UDP包</string>
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
        <widget class="QPushButton" name="btnSave">
         <property name="text">
          <string>保存UDP</string>
         </property>
        </widget>
       </item>
       <item>
        <widget class="QPushButton" name="btnLoad">
         <property name="text">
          <string>加载UDP</string>
         </property>
        </widget>
       </item>
      </layout>
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

// 设置结构体按 1 字节对齐，避免编译器自动填充字节造成结构体大小不一致
#pragma pack(1)

// 定义一个 UDP 报文的结构体，用于模拟 UDP 数据包的头部与数据部分
struct UDPPacker {
    quint16 m_srcPort;  // 源端口号
    quint16 m_dstPort;  // 目标端口号
    quint16 m_length;   // 报文长度（包含头部8字节 + 数据长度）
    quint16 m_checksum; // UDP 校验和（本示例中未进行实际计算，默认为0）
    QByteArray m_data;  // 报文数据内容

    // 声明两个友元函数，用于支持 QDataStream 的序列化和反序列化操作
    friend QDataStream& operator<<(QDataStream& stream, const UDPPacker& udp);
    friend QDataStream& operator>>(QDataStream& stream, UDPPacker& udp);
};

QT_BEGIN_NAMESPACE
namespace Ui {
class Widget; // 前向声明 UI 类，避免包含 ui_widget.h（由 uic 自动生成）
}
QT_END_NAMESPACE

// 主窗口类，继承自 QWidget
class Widget : public QWidget {
    Q_OBJECT

  public:
    // 构造函数和析构函数
    Widget(QWidget* parent = nullptr);
    ~Widget();

  private slots:
    // 添加一个 UDP 报文到列表
    void on_btnAddUDP_clicked();

    // 删除选中的 UDP 报文
    void on_btnDelUDP_clicked();

    // 保存 UDP 报文列表到文件
    void on_btnSave_clicked();

    // 从文件加载 UDP 报文列表
    void on_btnLoad_clicked();

    // 当前列表选中项变化时触发，用于更新显示到输入框
    void on_listWidget_currentRowChanged(int currentRow);

  private:
    Ui::Widget* ui; // UI 指针，用于访问界面控件
};

#endif // WIDGET_H

```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDataStream>     // 用于对象串行化（序列化）和反串行化
#include <QDebug>          // 用于调试输出
#include <QFile>           // 文件操作类
#include <QFileDialog>     // 文件选择对话框
#include <QIntValidator>   // 整数范围验证器，用于端口号输入
#include <QListWidgetItem> // 用于操作列表控件的行
#include <QMessageBox>     // 消息弹窗

// 构造函数：初始化界面和控件设置
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);                                                    // 设置 UI
    ui->listWidget->setSelectionMode(QAbstractItemView::SingleSelection); // 列表只能单选

    // 设置两个端口输入框只能输入 0-65535 之间的整数
    QIntValidator* valSrc = new QIntValidator(0, 65535);
    ui->lineEditSrcPort->setValidator(valSrc);
    QIntValidator* valDst = new QIntValidator(0, 65535);
    ui->lineEditDstPort->setValidator(valDst);
}

// 析构函数：释放 UI
Widget::~Widget() {
    delete ui;
}

// 重载运算符：将 UDP 包写入数据流中（用于保存）
QDataStream& operator<<(QDataStream& stream, const UDPPacker& udp) {
    stream << udp.m_srcPort;
    stream << udp.m_dstPort;
    stream << udp.m_length;
    stream << udp.m_checksum;
    stream.writeRawData(udp.m_data.data(), udp.m_data.size()); // 写入报文数据部分
    return stream;
}

// 重载运算符：从数据流中读取 UDP 包（用于加载）
QDataStream& operator>>(QDataStream& stream, UDPPacker& udp) {
    stream >> udp.m_srcPort;
    stream >> udp.m_dstPort;
    stream >> udp.m_length;
    stream >> udp.m_checksum;
    int nMsgLen = udp.m_length - 8;       // UDP 包数据区长度 = 总长度 - 头部长度
    char* buff = new char[nMsgLen];       // 分配内存缓冲区
    stream.readRawData(buff, nMsgLen);    // 读入数据区
    udp.m_data.setRawData(buff, nMsgLen); // 设置 QByteArray 的原始数据指针
    return stream;
}

// 添加 UDP 包按钮点击槽函数
void Widget::on_btnAddUDP_clicked() {
    QString strSrcPort = ui->lineEditSrcPort->text().trimmed();
    QString strDstPort = ui->lineEditDstPort->text().trimmed();
    QString strMsg = ui->lineEditMsg->text().trimmed();

    // 若任一输入为空，提示警告
    if (strSrcPort.isEmpty() || strDstPort.isEmpty() || strMsg.isEmpty()) {
        QMessageBox::warning(this, tr("添加包"), tr("请先填写两个端口和消息字符串。"));
        return;
    }

    UDPPacker udp;
    QByteArray baMsg = strMsg.toUtf8();    // 消息转为字节数组
    udp.m_srcPort = strSrcPort.toUShort(); // 源端口
    udp.m_dstPort = strDstPort.toUShort(); // 目的端口
    udp.m_length = 8 + baMsg.size();       // 总长度 = 头部 + 数据
    udp.m_checksum = 0;                    // UDP 校验和可省略为 0
    udp.m_data = baMsg;                    // 设置数据字段

    QByteArray baAll;
    QDataStream dsOut(&baAll, QIODevice::ReadWrite); // 将数据写入内存字节数组
    dsOut << udp;

    QString strAll = baAll.toHex();  // 转为十六进制字符串显示
    ui->listWidget->addItem(strAll); // 添加到列表控件中
}

// 删除 UDP 包按钮点击槽函数
void Widget::on_btnDelUDP_clicked() {
    int nCurRow = ui->listWidget->currentRow(); // 获取当前行号
    if (nCurRow < 0) return;                    // 无选中项，直接返回
    ui->listWidget->takeItem(nCurRow); // 删除该行项
}

// 保存按钮槽函数
void Widget::on_btnSave_clicked() {
    int nCount = ui->listWidget->count(); // 获取 UDP 包数量
    if (nCount < 1) return;

    QString strFileName = QFileDialog::getSaveFileName(this, tr("保存UDP文件"), tr("."), tr("UDP files(*.udp);;All files(*)"));
    if (strFileName.isEmpty()) return;

    QFile fileOut(strFileName);
    if (!fileOut.open(QIODevice::WriteOnly)) {
        QMessageBox::warning(this, tr("保存UDP文件"), tr("打开要保存的文件失败：") + fileOut.errorString());
        return;
    }

    QDataStream dsOut(&fileOut); // 输出数据流
    dsOut << qint32(nCount);     // 首先写入包个数

    UDPPacker udpCur;
    for (int i = 0; i < nCount; i++) {
        QString strHex = ui->listWidget->item(i)->text();        // 提取十六进制字符串
        QByteArray baCur = QByteArray::fromHex(strHex.toUtf8()); // 转为字节数组
        QDataStream dsIn(baCur);
        dsIn >> udpCur; // 提取结构体
        dsOut << udpCur; // 写入文件
    }

    QMessageBox::information(this, tr("保存UDP包"), tr("保存UDP包到文件完毕！"));
}

// 加载按钮槽函数
void Widget::on_btnLoad_clicked() {
    QString strFileName = QFileDialog::getOpenFileName(this, tr("打开UDP文件"), tr("."), tr("UDP files(*.udp);;All files(*)"));
    if (strFileName.isEmpty()) return;

    QFile fileIn(strFileName);
    if (!fileIn.open(QIODevice::ReadOnly)) {
        QMessageBox::warning(this, tr("打开UDP文件"), tr("打开指定UDP文件失败：") + fileIn.errorString());
        return;
    }

    QDataStream dsIn(&fileIn); // 输入数据流
    qint32 nCount;
    dsIn >> nCount; // 读取包数量
    if (nCount < 1) {
        QMessageBox::warning(this, tr("加载UDP包"), tr("指定UDP文件内数据包计数小于1，无法加载。"));
        return;
    }

    ui->listWidget->clear(); // 清空列表控件
    UDPPacker udpCur;
    for (int i = 0; i < nCount; i++) {
        if (dsIn.status() != QDataStream::Ok) {
            qDebug() << tr("读取第 %1 个数据包前的状态错误：%2").arg(i).arg(dsIn.status());
            break;
        }

        dsIn >> udpCur;

        QByteArray baCur;
        QDataStream dsOut(&baCur, QIODevice::ReadWrite); // 把 UDP 包写回字节流
        dsOut << udpCur;

        QString strHex = baCur.toHex();  // 转为十六进制字符串
        ui->listWidget->addItem(strHex); // 添加显示
    }

    QMessageBox::information(this, tr("加载UDP包"), tr("加载文件中的UDP包完成！"));
}

// 当前行变更槽函数：选中某行时，更新界面显示
void Widget::on_listWidget_currentRowChanged(int currentRow) {
    if (currentRow < 0) return;

    QString strHex = ui->listWidget->item(currentRow)->text();
    QByteArray baAll = QByteArray::fromHex(strHex.toUtf8());
    QDataStream dsIn(baAll);
    UDPPacker udp;
    dsIn >> udp; // 提取结构体

    // 更新界面三个编辑框的内容
    ui->lineEditSrcPort->setText(tr("%1").arg(udp.m_srcPort));
    ui->lineEditDstPort->setText(tr("%1").arg(udp.m_dstPort));
    ui->lineEditMsg->setText(QString::fromUtf8(udp.m_data));
}
```

