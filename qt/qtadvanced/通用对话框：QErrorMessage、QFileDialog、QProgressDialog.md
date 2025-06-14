## 通用对话框：QErrorMessage、QFileDialog、QProgressDialog

### QErrorMessage

`QErrorMessage` 是 Qt 提供的一个专用对话框类，用于显示错误消息（通常是运行时错误），并带有“不再显示此消息”的功能。这对于向用户提示非致命性错误（如输入错误、文件加载失败等）非常有用，能够有效防止同一个错误提示反复打扰用户。

- 提供一个标准的错误提示窗口。

- 自动维护“消息记录”，对于重复错误可以勾选“不再显示此消息”。

- 支持 `showMessage()` 动态显示错误文本。

- 是 **模态对话框**（默认），会阻塞用户对其他窗口的操作。

#### 常用函数说明

| 函数名                                     | 说明                                   |
| ------------------------------------------ | -------------------------------------- |
| `void showMessage(const QString &message)` | 显示错误信息；重复信息会自动合并。     |
| `static QErrorMessage *qtHandler()`        | 获取 Qt 全局的错误处理器（单例模式）。 |

#### 示例代码

```cpp
#include <QApplication>
#include <QPushButton>
#include <QErrorMessage>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QPushButton button("触发错误");
    QErrorMessage *errorDialog = new QErrorMessage();

    QObject::connect(&button, &QPushButton::clicked, [&]() {
        errorDialog->showMessage("文件加载失败：文件不存在。");
        errorDialog->exec(); // 模态显示对话框（非必须）
    });

    button.show();
    return app.exec();
}
```

#### 与 `QMessageBox` 区别

| 特性     | `QErrorMessage`        | `QMessageBox`                      |
| -------- | ---------------------- | ---------------------------------- |
| 用途     | 显示可忽略的错误信息   | 显示各种提示（信息、警告、问题等） |
| 特点     | 内建“下次不再提示”选项 | 无记录功能                         |
| 是否模态 | 默认模态               | 可选模态                           |
| 适合场景 | 经常性错误、重复错误   | 单次确认性提示                     |

#### 高级用法：使用 Qt 全局错误处理器

```cpp
QErrorMessage::qtHandler()->showMessage("这是一个全局错误提示！");
```

在大型应用中，可以通过 `qtHandler()` 实现统一的错误提示策略。

#### 常见注意事项

- `showMessage()` 是 **非阻塞** 的，如果希望阻塞用户操作，需调用 `exec()`。
- 多次调用 `showMessage()` 会**合并相同内容**，除非关闭对话框或内容不同。
- 适合用在用户可以选择忽略的错误提示上，而不是强制必须处理的错误。

### QFileDialog

`QFileDialog` 是 Qt 提供的标准文件选择对话框，用于让用户浏览文件系统，选择文件或目录。它支持多种文件类型过滤、选择单个或多个文件、选择目录等功能。

#### 主要功能

- 打开文件选择对话框（Open File）
- 保存文件选择对话框（Save File）
- 选择文件夹对话框（Select Directory）
- 支持过滤文件类型（比如只显示图片文件）
- 支持多文件选择
- 支持自定义对话框标题、初始路径
- 支持本地文件系统和虚拟文件系统

#### 构造函数

```cpp
QFileDialog(QWidget *parent = nullptr, Qt::WindowFlags flags = Qt::WindowFlags());
QFileDialog(const QString &parent, const QString &caption = QString(), const QString &directory = QString(), const QString &filter = QString());
```

- `parent`：父窗口

- `caption`：对话框标题

- `directory`：初始打开路径

- `filter`：过滤文件类型字符串，比如 `"Images (*.png *.xpm *.jpg);;Text files (*.txt);;All files (*.*)"`

#### 常用静态函数（简易使用）

| 函数                                                         | 功能                                           | 备注 |
| ------------------------------------------------------------ | ---------------------------------------------- | ---- |
| `QString getOpenFileName(QWidget *parent = nullptr, const QString &caption = QString(), const QString &dir = QString(), const QString &filter = QString(), QString *selectedFilter = nullptr, Options options = 0)` | 打开单文件选择对话框，返回选中的文件路径。     |      |
| `QStringList getOpenFileNames(QWidget *parent = nullptr, const QString &caption = QString(), const QString &dir = QString(), const QString &filter = QString(), QString *selectedFilter = nullptr, Options options = 0)` | 打开多文件选择对话框，返回选中的文件路径列表。 |      |
| `QString getSaveFileName(QWidget *parent = nullptr, const QString &caption = QString(), const QString &dir = QString(), const QString &filter = QString(), QString *selectedFilter = nullptr, Options options = 0)` | 打开保存文件对话框，返回用户输入的文件路径。   |      |
| `QString getExistingDirectory(QWidget *parent = nullptr, const QString &caption = QString(), const QString &dir = QString(), Options options = 0)` | 打开目录选择对话框，返回选中的目录路径。       |      |

#### 使用示例

##### 打开单文件选择

```cpp
QString fileName = QFileDialog::getOpenFileName(this,
    tr("打开文件"),
    "/home/user",
    tr("文本文件 (*.txt);;所有文件 (*.*)"));

if (!fileName.isEmpty()) {
    // 使用 fileName 做进一步处理
}
```

##### 选择多个文件

```cpp
QStringList files = QFileDialog::getOpenFileNames(this,
    tr("选择多个文件"),
    "/home/user",
    tr("图片文件 (*.png *.jpg);;所有文件 (*.*)"));

for (const QString &file : files) {
    // 处理每个文件
}
```

##### 保存文件

```cpp
QString fileName = QFileDialog::getSaveFileName(this,
    tr("保存文件"),
    "/home/user/untitled.txt",
    tr("文本文件 (*.txt);;所有文件 (*.*)"));

if (!fileName.isEmpty()) {
    // 保存文件
}
```

##### 选择目录

```cpp
QString dir = QFileDialog::getExistingDirectory(this,
    tr("选择目录"),
    "/home/user",
    QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks);

if (!dir.isEmpty()) {
    // 使用目录路径
}
```

#### 常用成员函数（非静态）

- `void setDirectory(const QString &directory)`：设置默认目录。
- `void setNameFilter(const QString &filter)`：设置文件过滤器。
- `void setFileMode(QFileDialog::FileMode mode)`：设置文件选择模式，如单文件、多文件、目录等。
   主要枚举值：
  - `QFileDialog::AnyFile`：允许选择任何文件（即使不存在）
  - `QFileDialog::ExistingFile`：只能选择已存在的单个文件
  - `QFileDialog::ExistingFiles`：可以选择多个已存在的文件
  - `QFileDialog::Directory`：选择目录
- `void setViewMode(QFileDialog::ViewMode mode)`：设置视图模式（列表或详细信息）。
- `QStringList selectedFiles() const`：获取用户选中的文件路径列表。

#### 文件过滤器语法

过滤器字符串由一组过滤条件组成，格式类似：

```css
"Images (*.png *.jpg *.bmp);;Text files (*.txt);;All files (*.*)"
```

- 用 `;;` 分隔不同过滤条件

- 用括号内定义通配符，支持 `*` 和 `?`

- 用户在对话框中可以切换过滤器

#### 自定义和信号

`QFileDialog` 作为 `QDialog`，支持信号和槽，可以监听用户操作：

- `void fileSelected(const QString &file)` — 用户选择文件后触发（单文件）
- `void filesSelected(const QStringList &files)` — 多文件选择后触发
- `void directoryEntered(const QString &directory)` — 用户进入某目录时触发

可以连接这些信号实现更细粒度的处理。

#### 示例：自定义对话框

```cpp
QFileDialog dialog(this);
dialog.setWindowTitle("选择图片");
dialog.setDirectory("/home/user/Pictures");
dialog.setNameFilter("Images (*.png *.xpm *.jpg)");
dialog.setFileMode(QFileDialog::ExistingFiles);
dialog.setViewMode(QFileDialog::Detail);

if (dialog.exec() == QDialog::Accepted) {
    QStringList files = dialog.selectedFiles();
    for (const QString &file : files) {
        qDebug() << "选择文件：" << file;
    }
}
```

### QProgressDialog

`QProgressDialog` 是 Qt 提供的用于显示任务进度的对话框，带有进度条、文本提示和取消按钮，适合耗时操作时向用户反馈进度并允许用户取消操作。

#### 主要功能

- 显示任务当前进度（通过进度条）
- 显示文字信息（如“正在处理中...”）
- 允许用户点击“取消”按钮中断任务
- 支持设置最小和最大进度值
- 支持自动显示和隐藏，避免无意义的闪烁

#### 构造函数

```cpp
QProgressDialog(QWidget *parent = nullptr);
QProgressDialog(const QString &labelText, const QString &cancelButtonText, int minimum, int maximum, QWidget *parent = nullptr, Qt::WindowFlags f = Qt::WindowFlags());
```

- `labelText`：对话框上显示的文字描述
- `cancelButtonText`：取消按钮文本，如“取消”
- `minimum`：进度条最小值，通常是0
- `maximum`：进度条最大值，任务完成时的值
- `parent`：父窗口
- `f`：窗口标志

#### 常用成员函数

| 函数                                            | 说明                                     |
| ----------------------------------------------- | ---------------------------------------- |
| `void setLabelText(const QString &text)`        | 设置显示的提示文本                       |
| `void setRange(int minimum, int maximum)`       | 设置进度条范围                           |
| `void setValue(int value)`                      | 设置当前进度值，进度条前进               |
| `int value() const`                             | 获取当前进度值                           |
| `void setCancelButtonText(const QString &text)` | 设置取消按钮文本                         |
| `void setMinimumDuration(int ms)`               | 设置延迟显示对话框的时间，避免短任务闪烁 |
| `bool wasCanceled() const`                      | 返回用户是否点击了取消按钮               |
| `QPushButton* cancelButton() const`             | 获取取消按钮指针，可用于连接信号         |
| `void reset()`                                  | 重置对话框，进度条回到初始状态           |
| `void setAutoClose(bool)`                       | 任务完成时自动关闭对话框（默认 true）    |
| `void setAutoReset(bool)`                       | 任务完成时自动重置进度条（默认 true）    |

#### 信号

| 信号              | 说明                   |
| ----------------- | ---------------------- |
| `void canceled()` | 用户点击取消按钮时发出 |

#### 使用示例

```cpp
#include <QApplication>
#include <QProgressDialog>
#include <QTimer>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QProgressDialog progressDialog("正在处理中...", "取消", 0, 100);
    progressDialog.setWindowModality(Qt::WindowModal);
    progressDialog.setMinimumDuration(500); // 0.5秒后才显示对话框
    progressDialog.setValue(0);

    // 模拟长时间任务
    for (int i = 0; i <= 100; ++i) {
        QThread::msleep(50); // 模拟耗时操作

        progressDialog.setValue(i);
        QApplication::processEvents(); // 保持界面响应

        if (progressDialog.wasCanceled()) {
            qDebug("任务被用户取消");
            break;
        }
    }

    if (!progressDialog.wasCanceled()) {
        qDebug("任务完成");
    }

    return 0;
}
```

#### 使用建议

- **避免闪烁**：使用 `setMinimumDuration()`，只有任务超过指定时间才显示对话框。
- **任务取消**：检查 `wasCanceled()`，支持用户中断任务。
- **自动关闭**：开启 `setAutoClose(true)`，任务完成自动关闭对话框。
- **模态显示**：通常设置为模态对话框，避免用户误操作。

### 示例：计算 MD5

#### widgetcalcmd5.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>WidgetCalcMD5</class>
 <widget class="QWidget" name="WidgetCalcMD5">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>400</width>
    <height>300</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>WidgetCalcMD5</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QLabel" name="label">
       <property name="text">
        <string>文件名</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditFileName"/>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonBrowser">
       <property name="text">
        <string>浏览</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonCalcMD5">
       <property name="text">
        <string>计算MD5</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <widget class="QTextBrowser" name="textBrowserInfo"/>
   </item>
  </layout>
 </widget>
 <resources/>
 <connections/>
</ui>
```

#### widgetcalcmd5.h

```cpp
#ifndef WIDGETCALCMD5_H
#define WIDGETCALCMD5_H

// 用于计算 MD5 值
#include <QCryptographicHash>
// 用于显示错误信息弹窗
#include <QErrorMessage>
// 用于文件操作
#include <QFile>
// 用于弹出文件选择对话框
#include <QFileDialog>
// 用于显示进度对话框
#include <QProgressDialog>
// Qt 窗口基类
#include <QWidget>

// 命名空间 Ui，自动由 Qt Designer 生成，用于访问界面控件
QT_BEGIN_NAMESPACE
namespace Ui {
class WidgetCalcMD5;
}
QT_END_NAMESPACE

// 继承自 QWidget 的主窗口类，用于实现文件 MD5 值计算功能
class WidgetCalcMD5 : public QWidget {
    Q_OBJECT

  public:
    // 构造函数，父对象默认为空
    WidgetCalcMD5(QWidget* parent = nullptr);

    // 析构函数
    ~WidgetCalcMD5();

  private slots:
    // 槽函数：当“浏览文件”按钮被点击时执行
    void on_pushButtonBrowser_clicked();

    // 槽函数：当“计算 MD5”按钮被点击时执行
    void on_pushButtonCalcMD5_clicked();

  private:
    // 指向 UI 界面对象的指针，用于访问界面上的控件
    Ui::WidgetCalcMD5* ui;

    // 错误提示对话框，用于统一显示错误信息
    QErrorMessage m_dlgErrorMsg;

    // 当前选择的文件名（含完整路径）
    QString m_strFileName;

    // 计算传入文件的 MD5 值
    // 参数：
    //   fileIn：输入文件对象（已打开）
    //   nFileSize：文件大小（用于显示进度）
    // 返回值：
    //   计算得到的 MD5 值（16 字节的 QByteArray）
    QByteArray calcFileMD5(QFile& fileIn, qint64 nFileSize);
};

#endif // WIDGETCALCMD5_H
```

#### widgetcalcmd5.cpp

```cpp
#include "widgetcalcmd5.h"
#include "./ui_widgetcalcmd5.h"

// 构造函数，初始化 UI 界面
WidgetCalcMD5::WidgetCalcMD5(QWidget* parent) : QWidget(parent), ui(new Ui::WidgetCalcMD5) {
    ui->setupUi(this); // 绑定 UI 界面
}

// 析构函数，释放 UI 内存
WidgetCalcMD5::~WidgetCalcMD5() {
    delete ui;
}

// 点击“浏览”按钮：弹出文件选择对话框
void WidgetCalcMD5::on_pushButtonBrowser_clicked() {
    // 打开文件选择对话框
    QString strFileName = QFileDialog::getOpenFileName(this, tr("选择文件"), "", "All files (*)");

    // 用户未选择文件
    if (strFileName.isEmpty()) {
        m_dlgErrorMsg.showMessage(tr("文件名为空，未选择文件！"));
        return;
    }

    // 记录文件名并显示在界面上
    m_strFileName = strFileName;
    ui->lineEditFileName->setText(m_strFileName);

    // 清空之前的显示信息
    ui->textBrowserInfo->clear();
}

// 点击“计算MD5”按钮，执行校验计算
void WidgetCalcMD5::on_pushButtonCalcMD5_clicked() {
    // 获取用户输入的文件路径
    QString strFileName = ui->lineEditFileName->text().trimmed();

    // 检查是否为空
    if (strFileName.isEmpty()) {
        m_dlgErrorMsg.showMessage(tr("文件名编辑框内容为空！"));
        return;
    }

    m_strFileName = strFileName;

    // 创建 QFile 对象
    QFile fileIn(m_strFileName);

    // 尝试打开文件
    if (!fileIn.open(QIODevice::ReadOnly)) {
        m_dlgErrorMsg.showMessage(tr("打开指定文件失败！"));
        return;
    }

    // 获取文件大小
    qint64 nFileSize = fileIn.size();
    if (nFileSize < 1) {
        m_dlgErrorMsg.showMessage(tr("文件大小为 0，没有数据！"));
        fileIn.close();
        return;
    }

    // 调用函数计算 MD5 值
    QByteArray baMD5 = calcFileMD5(fileIn, nFileSize);

    // 构造显示信息
    QString strInfo = tr("文件名：") + m_strFileName;
    strInfo += tr("\n文件大小：%1 字节").arg(nFileSize);
    strInfo += tr("\nMD5校验值：\n");
    strInfo += baMD5.toHex().toUpper(); // 转为十六进制并大写

    // 显示信息到文本框
    ui->textBrowserInfo->setText(strInfo);

    fileIn.close(); // 关闭文件
}

// 实际计算 MD5 值的函数，支持大文件分块读取 + 进度显示
QByteArray WidgetCalcMD5::calcFileMD5(QFile& fileIn, qint64 nFileSize) {
    QByteArray baRet;                                   // 返回值：最终的 MD5 校验结果
    QCryptographicHash algMD5(QCryptographicHash::Md5); // MD5 计算器
    QByteArray baCurData;                               // 用于临时存储读取的数据块

    // 小文件（<100KB）直接一次性读取计算
    if (nFileSize < 100 * 1000) {
        baCurData = fileIn.readAll(); // 一次读完
        algMD5.addData(baCurData);    // 添加到哈希器中
        baRet = algMD5.result();      // 获取最终结果
        return baRet;
    }

    // 对于大文件，进行分块读取
    qint64 oneBlockSize = nFileSize / 100; // 每块大小（大概分成 100 块）
    int nBlocksCount = 100;
    if (nFileSize % oneBlockSize != 0) {
        // 如果不能整除，块数 +1
        nBlocksCount += 1;
    }

    // 初始化进度对话框
    QProgressDialog dlgProgress(tr("正在计算MD5 ..."), tr("取消计算"), 0, nBlocksCount, this);
    dlgProgress.setWindowModality(Qt::WindowModal); // 模态，阻止用户其他操作
    dlgProgress.setMinimumDuration(0);              // 立即显示

    // 开始分块读取 + 更新进度条
    for (int i = 0; i < nBlocksCount; i++) {
        dlgProgress.setValue(i); // 设置当前进度

        // 判断用户是否取消
        if (dlgProgress.wasCanceled()) break;

        // 读取一个数据块并添加到 MD5 计算中
        baCurData = fileIn.read(oneBlockSize);
        algMD5.addData(baCurData);
    }

    // 如果没有被取消，则取出计算结果
    if (!dlgProgress.wasCanceled()) baRet = algMD5.result();

    dlgProgress.setValue(nBlocksCount); // 完成时设置为最大值，关闭进度框
    return baRet;
}
```

