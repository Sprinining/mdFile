## Qt 文件系统概述

### QDir

`QDir` 是 Qt 框架中用于处理 **目录（文件夹）操作** 的核心类，位于模块 `QtCore` 中。它提供了跨平台的方式来操作文件系统的目录，比如：列出目录内容、创建/删除目录、路径拼接、路径规范化、文件过滤等。

#### 基本概念

```cpp
#include <QDir>
```

`QDir` 代表一个目录路径，并提供在该目录下操作的接口。其内部保存的是一个路径字符串，它可以代表一个**绝对路径**或**相对路径**。

#### 构造函数

```cpp
QDir();
QDir(const QString &path);
QDir(const QString &path, const QString &nameFilter, SortFlags sort = Name | IgnoreCase, Filters filters = AllEntries);
```

- `QDir()`：默认构造，表示当前工作目录。

- `QDir(path)`：表示指定路径。

- 第三个构造参数支持设置排序方式和过滤器。

#### 常用方法详解

##### 路径相关

| 方法                                                | 功能                           |
| --------------------------------------------------- | ------------------------------ |
| `QString absolutePath()`                            | 返回绝对路径                   |
| `QString canonicalPath()`                           | 返回规范化路径（解析符号链接） |
| `QString path()`                                    | 获取设置的目录路径             |
| `void setPath(const QString &path)`                 | 设置目录路径                   |
| `QString filePath(const QString &fileName)`         | 拼接路径                       |
| `QString absoluteFilePath(const QString &fileName)` | 获取文件的绝对路径             |
| `QString dirName()`                                 | 获取目录名（最后一级）         |
| `QString rootPath()`                                | 获取根路径（例如 C:/ 或 /）    |

```cpp
QDir dir("/home/user/docs");
qDebug() << dir.absolutePath();         // /home/user/docs
qDebug() << dir.filePath("file.txt");   // /home/user/docs/file.txt
```

##### 目录创建/删除

| 方法                                  | 功能                   |
| ------------------------------------- | ---------------------- |
| `bool mkdir(const QString &dirName)`  | 创建子目录             |
| `bool mkpath(const QString &dirPath)` | 递归创建路径           |
| `bool rmdir(const QString &dirName)`  | 删除子目录（必须为空） |
| `bool rmpath(const QString &dirPath)` | 递归删除路径           |

```cpp
QDir dir("/tmp");
dir.mkpath("project/build"); // 递归创建目录
dir.rmpath("project/build"); // 删除目录
```

##### 列出文件/目录

```cpp
QFileInfoList entryInfoList(
    const QStringList &nameFilters = QStringList(),
    Filters filters = NoFilter,
    SortFlags sort = NoSort
);
```

`Filters` 过滤器（QDir::Filter）：

- `QDir::Files`：只列出文件
- `QDir::Dirs`：只列出目录
- `QDir::NoDotAndDotDot`：排除 `.` 和 `..`
- `QDir::Readable | QDir::Writable`：过滤可读/写的文件

`SortFlags` 排序方式（QDir::SortFlag）：

- `QDir::Name`：按名称排序
- `QDir::Time`：按修改时间排序
- `QDir::Size`：按大小排序
- `QDir::DirsFirst`：目录排前
- `QDir::IgnoreCase`：忽略大小写

```cpp
QDir dir("/home/user");
QStringList filters;
filters << "*.cpp" << "*.h";
QFileInfoList files = dir.entryInfoList(filters, QDir::Files | QDir::NoDotAndDotDot);
for (const QFileInfo &fileInfo : files) {
    qDebug() << fileInfo.fileName() << fileInfo.size();
}
```

##### 改变目录

| 方法                                   | 功能             |
| -------------------------------------- | ---------------- |
| `bool cd(const QString &dirName)`      | 进入子目录       |
| `bool cdUp()`                          | 回到上级目录     |
| `QDir current()`                       | 获取当前工作目录 |
| `void setCurrent(const QString &path)` | 设置当前工作目录 |

```cpp
QDir dir("/home/user");
dir.cd("Documents"); // 进入子目录
qDebug() << dir.path(); // /home/user/Documents
```

##### 静态方法（常用工具）

| 方法                               | 功能             |
| ---------------------------------- | ---------------- |
| `bool exists(const QString &path)` | 路径是否存在     |
| `QString currentPath()`            | 当前工作目录路径 |
| `QString homePath()`               | 用户主目录       |
| `QString tempPath()`               | 临时目录路径     |
| `QString rootPath()`               | 根目录           |

```cpp
qDebug() << QDir::homePath();     // /home/yourname
qDebug() << QDir::tempPath();     // /tmp
qDebug() << QDir::currentPath();  // 当前工作目录
```

#### 示例：复制目录下所有文件

```cpp
// 递归复制目录中的所有文件和子目录
void copyDir(const QString &fromDir, const QString &toDir) {
    // 创建源目录对象
    QDir sourceDir(fromDir);
    // 创建目标目录对象
    QDir targetDir(toDir);

    // 如果目标目录不存在，则创建
    if (!targetDir.exists()) {
        targetDir.mkpath(".");  // 创建当前路径所代表的目录（即 toDir）
    }

    // 获取源目录中所有文件和目录的信息（排除 "." 和 ".."）
    QFileInfoList entries = sourceDir.entryInfoList(
        QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);

    // 遍历每个文件或子目录
    for (const QFileInfo &fileInfo : entries) {
        // 获取源文件/目录的完整路径
        QString srcPath = fileInfo.absoluteFilePath();
        // 构建目标文件/目录的完整路径
        QString destPath = toDir + "/" + fileInfo.fileName();

        if (fileInfo.isDir()) {
            // 如果是目录，则递归调用 copyDir 复制子目录
            copyDir(srcPath, destPath);
        } else {
            // 如果是文件，则直接复制
            QFile::copy(srcPath, destPath);
        }
    }
}
```

### QFileInfo

`QFileInfo` 是 Qt 提供的一个非常常用的类，用于**访问文件或目录的元信息**。可以用它来判断文件是否存在、是否是目录、获取文件大小、修改时间、权限等属性。

#### 基本概念

```cpp
#include <QFileInfo>
```

`QFileInfo` 提供一个**跨平台的方式**来访问文件系统中某个文件或目录的信息，而不需要手动去调用操作系统 API。

#### 构造函数

```cpp
QFileInfo();
QFileInfo(const QString &file);
QFileInfo(const QFile &file);
QFileInfo(const QDir &dir, const QString &file);
```

- `QFileInfo()`：默认构造函数，需后续 setFile。

- `QFileInfo("path/to/file.txt")`：直接传入路径。

- `QFileInfo(QDir("/dir"), "file.txt")`：路径拼接方式。

#### 常用方法详解

##### 判断类型和状态

| 方法                  | 含义              |
| --------------------- | ----------------- |
| `bool exists()`       | 文件/目录是否存在 |
| `bool isFile()`       | 是否是普通文件    |
| `bool isDir()`        | 是否是目录        |
| `bool isSymLink()`    | 是否是符号链接    |
| `bool isReadable()`   | 是否可读          |
| `bool isWritable()`   | 是否可写          |
| `bool isExecutable()` | 是否可执行        |

```cpp
QFileInfo info("/home/user/test.txt");
if (info.exists() && info.isFile()) {
    qDebug() << "是一个普通文件";
}
```

##### 获取路径相关信息

| 方法                          | 含义                         |
| ----------------------------- | ---------------------------- |
| `QString filePath()`          | 原始路径（可相对）           |
| `QString absoluteFilePath()`  | 绝对路径                     |
| `QString canonicalFilePath()` | 解析符号链接后的真实绝对路径 |
| `QString fileName()`          | 文件名（不含路径）           |
| `QString suffix()`            | 后缀名（例如 txt）           |
| `QString completeSuffix()`    | 完整后缀（例如 tar.gz）      |
| `QString baseName()`          | 主文件名（去掉后缀）         |
| `QString completeBaseName()`  | 多后缀主文件名               |

```cpp
QFileInfo info("archive.tar.gz");
qDebug() << info.fileName();          // archive.tar.gz
qDebug() << info.baseName();          // archive
qDebug() << info.completeBaseName();  // archive.tar
qDebug() << info.suffix();            // gz
qDebug() << info.completeSuffix();    // tar.gz
```

##### 获取时间戳

| 方法                       | 含义                       |
| -------------------------- | -------------------------- |
| `QDateTime created()`      | 创建时间（可能平台不支持） |
| `QDateTime lastModified()` | 最后修改时间               |
| `QDateTime lastRead()`     | 最后访问时间               |

```cpp
QFileInfo info("file.txt");
qDebug() << "修改时间:" << info.lastModified().toString();
```

##### 文件属性

| 方法                               | 含义                   |
| ---------------------------------- | ---------------------- |
| `qint64 size()`                    | 获取文件大小（字节）   |
| `QString owner()`                  | 所有者用户名           |
| `QString group()`                  | 所属组名               |
| `QFile::Permissions permissions()` | 权限标志位（枚举类型） |

```cpp
QFileInfo info("bigfile.dat");
qDebug() << "大小:" << info.size() << "字节";
```

##### 静态工具方法

```cpp
QFileInfo::exists("path/to/file.txt");  // 快速检查文件是否存在
```

##### 示例：列出目录下所有文件和大小

```cpp
QDir dir("/home/user");
QFileInfoList list = dir.entryInfoList(QDir::Files | QDir::NoDotAndDotDot);

for (const QFileInfo &info : list) {
    qDebug() << "文件:" << info.fileName()
             << "大小:" << info.size()
             << "修改时间:" << info.lastModified().toString();
}
```

#### 注意事项

- `QFileInfo` 是**值类型**，复制开销小。

- 一旦文件发生改变，需要使用 `refresh()` 重新加载。

- 它只**读取元信息**，不修改文件本身（修改需用 `QFile`）。

### 示例：路径查看和判断

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
    <width>600</width>
    <height>300</height>
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
        <string>工作路径</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditWorkPath"/>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QPushButton" name="btnGetWP">
       <property name="text">
        <string>获取工作路径</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnSetWP">
       <property name="text">
        <string>设置工作路径</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnGetEP">
       <property name="text">
        <string>显示环境路径</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_3">
     <item>
      <widget class="QLabel" name="label_2">
       <property name="text">
        <string>测试路径</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditTestPath"/>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_4">
     <item>
      <widget class="QPushButton" name="btnExist">
       <property name="text">
        <string>测试存在性</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnRelative">
       <property name="text">
        <string>测试相对性</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnAbsolute">
       <property name="text">
        <string>显示绝对路径</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_5">
     <item>
      <widget class="QLabel" name="label_3">
       <property name="text">
        <string>显示结果</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPlainTextEdit" name="plainTextEditResult"/>
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
    void on_btnGetWP_clicked();
    void on_btnSetWP_clicked();
    void on_btnGetEP_clicked();
    void on_btnExist_clicked();
    void on_btnRelative_clicked();
    void on_btnAbsolute_clicked();

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
#include <QDir>
#include <QFileInfo>
#include <QMessageBox>

// 构造函数：初始化 UI，设置文本框为只读
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);
    ui->plainTextEditResult->setReadOnly(true); // 结果显示区域不允许手动编辑
}

// 析构函数：释放 UI 对象
Widget::~Widget() {
    delete ui;
}

// 获取当前工作路径（工作目录），显示到 lineEditWorkPath 控件中
void Widget::on_btnGetWP_clicked() {
    QString strWorkPath = QDir::currentPath();  // 获取当前工作路径
    ui->lineEditWorkPath->setText(strWorkPath); // 显示路径
}

// 设置当前工作路径为 lineEditWorkPath 中输入的路径
void Widget::on_btnSetWP_clicked() {
    QString strNewPath = ui->lineEditWorkPath->text(); // 获取用户输入路径
    if (strNewPath.length() < 1) return;               // 如果输入为空，则不处理

    QDir dirNew(strNewPath);
    QString strResult;

    if (dirNew.exists()) {                           // 如果路径存在
        bool bRes = QDir::setCurrent(dirNew.path()); // 尝试设置为当前工作路径
        if (!bRes) {
            strResult = tr("设置工作路径为 %1 失败。").arg(strNewPath);
            QMessageBox::warning(this, tr("设置错误"), strResult); // 设置失败时弹出警告
        } else {
            strResult = tr("设置工作路径成功，新的路径为：\r\n%1").arg(QDir::currentPath());
        }
    } else {
        // 如果路径不存在，弹出错误提示
        strResult = tr("设置工作路径为 %1 失败，该路径不存在！").arg(strNewPath);
        QMessageBox::warning(this, tr("路径不存在"), strResult);
    }

    ui->plainTextEditResult->setPlainText(strResult); // 显示操作结果
}

// 获取 Qt 提供的几个常用路径信息：工作目录、可执行文件目录、用户主目录、根目录、临时目录
void Widget::on_btnGetEP_clicked() {
    QString strWorkPath = QDir::currentPath();                   // 当前工作路径
    QString strAppPath = QCoreApplication::applicationDirPath(); // 可执行程序所在目录
    QString strHomePath = QDir::homePath();                      // 用户主目录
    QString strRootPath = QDir::rootPath();                      // 根目录（Windows 是 C:/，Linux 是 /）
    QString strTempPath = QDir::tempPath();                      // 临时目录路径

    QString strResult;
    strResult += tr("工作路径：%1\r\n").arg(strWorkPath);
    strResult += tr("可执行程序目录：%1\r\n\r\n").arg(strAppPath);
    strResult += tr("用户主文件夹：%1\r\n").arg(strHomePath);
    strResult += tr("系统根目录：%1\r\n").arg(strRootPath);
    strResult += tr("临时目录：%1\r\n").arg(strTempPath);

    ui->plainTextEditResult->setPlainText(strResult); // 显示所有路径信息
}

// 判断 lineEditTestPath 中填写的路径是否存在
void Widget::on_btnExist_clicked() {
    QString strTestPath = ui->lineEditTestPath->text(); // 获取用户输入路径
    if (strTestPath.length() < 1) return;

    QDir dirWork;
    QString strResult;

    if (dirWork.exists(strTestPath)) { // 判断路径是否存在（可以是相对路径）
        strResult = tr("路径 %1 是存在的。").arg(strTestPath);
    } else {
        strResult = tr("路径 %1 不存在。").arg(strTestPath);
    }

    ui->plainTextEditResult->setPlainText(strResult); // 显示判断结果
}

// 判断 lineEditTestPath 输入的路径是相对路径还是绝对路径
void Widget::on_btnRelative_clicked() {
    QString strTestPath = ui->lineEditTestPath->text(); // 获取路径
    if (strTestPath.length() < 1) return;

    QDir dirTest(strTestPath);
    QString strResult;

    if (dirTest.isRelative()) { // 判断是否是相对路径
        strResult = tr("路径 %1 是相对路径").arg(strTestPath);
    } else {
        strResult = tr("路径 %1 是绝对路径").arg(strTestPath);
    }

    ui->plainTextEditResult->setPlainText(strResult); // 显示路径类型
}

// 显示 lineEditTestPath 路径的绝对路径
void Widget::on_btnAbsolute_clicked() {
    QString strTestPath = ui->lineEditTestPath->text(); // 获取路径
    if (strTestPath.length() < 1) return;

    QDir dirTest(strTestPath);
    QString strResult;

    // 获取该路径的绝对路径表示形式
    strResult = tr("测试路径 %1 的绝对路径为：%2").arg(strTestPath).arg(dirTest.absolutePath());

    ui->plainTextEditResult->setPlainText(strResult); // 显示结果
}
```

### 示例：文件系统浏览

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
    <width>400</width>
    <height>400</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QLineEdit" name="lineEditDir"/>
     </item>
     <item>
      <widget class="QPushButton" name="btnEnter">
       <property name="text">
        <string>进入</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
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
      <widget class="QPushButton" name="btnDrivers">
       <property name="text">
        <string>获取分区根</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnParent">
       <property name="text">
        <string>进入父目录</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <widget class="QListWidget" name="listWidget"/>
   </item>
   <item>
    <widget class="QPlainTextEdit" name="plainTextEditInfo"/>
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

// 引入 Qt 中操作目录和文件的类
#include <QDir>        // QDir 提供目录的创建、遍历、路径操作等功能
#include <QFileInfo>   // QFileInfo 用于获取文件/目录的详细信息
#include <QIcon>       // QIcon 用于设置图标
#include <QListWidget> // QListWidget 是列表控件，用于显示文件列表
#include <QWidget>     // QWidget 是所有窗口部件的基类

// Qt UI 命名空间宏（防止命名冲突）
QT_BEGIN_NAMESPACE
namespace Ui {
class Widget; // 前向声明 UI 类
}
QT_END_NAMESPACE

// Widget 类是主窗口类，继承自 QWidget
class Widget : public QWidget {
    Q_OBJECT // 启用 Qt 的元对象系统（支持信号槽）

  public :
    // 构造函数和析构函数
    Widget(QWidget* parent = nullptr); // 构造函数，默认无父窗口
    ~Widget();                           // 析构函数

  private slots:
    // 槽函数：用于处理 UI 中的信号

    // 点击“进入”按钮，跳转到输入路径
    void on_btnEnter_clicked();

    // 点击“驱动器”按钮，列出系统中的所有磁盘（如 C:\ D:\）
    void on_btnDrivers_clicked();

    // 点击“上级目录”按钮，跳转到当前目录的上一级
    void on_btnParent_clicked();

    // 双击列表项时触发（如果是文件夹，则进入）
    void on_listWidget_itemDoubleClicked(QListWidgetItem* item);

    // 当列表当前选中项发生改变时触发（用于显示文件信息等）
    void on_listWidget_currentItemChanged(QListWidgetItem* current, QListWidgetItem* previous);

  private:
    Ui::Widget* ui; // 自动生成的 UI 类指针，用于访问界面控件

    // 三个图标：磁盘图标、文件夹图标、文件图标
    QIcon iconDriver;
    QIcon iconFolder;
    QIcon iconFile;

    QDir dirCur; // 当前目录对象，表示用户正在浏览的目录

    // 显示指定目录中的文件和子目录
    void showItems(const QDir& dir);

    // 获取某个文件的信息（如大小、修改时间等）
    QString getFileInfo(const QFileInfo& fi);

    // 获取某个文件夹的信息（如子文件个数等）
    QString getFolderInfo(const QFileInfo& fi);

    enum ItemType {
        IDriver = QListWidgetItem::UserType + 1,
        IFolder,
        IFile
    };
};

#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDateTime> // 日期时间处理
#include <QDebug>
#include <QDesktopServices> // 打开本地文件或 URL
#include <QMessageBox>      // 消息框

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 设置只读信息显示框
    ui->plainTextEditInfo->setReadOnly(true);

    // 加载图标资源
    iconDriver = QIcon(":/images/driver.png");
    iconFolder = QIcon(":/images/folder.png");
    iconFile = QIcon(":/images/file.png");

    // 默认显示驱动器列表
    on_btnDrivers_clicked();
}

Widget::~Widget() {
    delete ui;
}

/**
 * @brief 根据目录内容更新列表控件
 * @param dir 当前目录对象
 */
void Widget::showItems(const QDir& dir) {
    if (!dir.exists()) return;

    // 获取目录内容，目录优先排序
    QFileInfoList fileInfoList = dir.entryInfoList(QDir::NoFilter, QDir::DirsFirst);
    ui->listWidget->clear();

    for (const QFileInfo& fi : fileInfoList) {
        QString name = fi.fileName();

        if (fi.isDir()) {
            // 文件夹项，type自定义为IFolder
            QListWidgetItem* itemFolder = new QListWidgetItem(iconFolder, name, nullptr, IFolder);
            ui->listWidget->addItem(itemFolder);
        } else {
            // 普通文件项，type自定义为IFile
            QListWidgetItem* itemFile = new QListWidgetItem(iconFile, name, nullptr, IFile);
            ui->listWidget->addItem(itemFile);
        }
    }
}

/**
 * @brief 点击“进入”按钮，切换到输入路径的目录
 */
void Widget::on_btnEnter_clicked() {
    QString strNewDir = ui->lineEditDir->text();
    QDir dirNew(strNewDir);

    if (dirNew.exists()) {
        dirCur = QDir(dirNew.canonicalPath());
        showItems(dirCur);
        ui->lineEditDir->setText(dirCur.absolutePath());
        ui->plainTextEditInfo->setPlainText(tr("进入成功"));
    } else {
        QMessageBox::warning(this, tr("目录不存在"), tr("目录 %1 不存在").arg(strNewDir));
    }
}

/**
 * @brief 点击“驱动器”按钮，显示系统分区根目录
 */
void Widget::on_btnDrivers_clicked() {
    // 获取磁盘根分区
    QFileInfoList drives = QDir::drives();
    // 手动添加程序资源根路径
    drives.append(QFileInfo(":/"));

    ui->listWidget->clear();

    for (const QFileInfo& fi : drives) {
        QString strPath = fi.absolutePath();
        QListWidgetItem* item = new QListWidgetItem(iconDriver, strPath, nullptr, IDriver);
        ui->listWidget->addItem(item);
    }

    dirCur = QDir::root();
    ui->lineEditDir->setText(dirCur.absolutePath());
    ui->plainTextEditInfo->setPlainText(tr("已获取分区根"));
}

/**
 * @brief 点击“上一级”按钮，切换到上级目录
 */
void Widget::on_btnParent_clicked() {
    if (dirCur.cdUp()) {
        ui->lineEditDir->setText(dirCur.absolutePath());
        showItems(dirCur);
        ui->plainTextEditInfo->setPlainText(tr("进入父目录成功"));
    } else {
        ui->plainTextEditInfo->setPlainText(tr("已到根目录"));
    }
}

/**
 * @brief 双击列表项时触发，进入目录或打开文件
 */
void Widget::on_listWidget_itemDoubleClicked(QListWidgetItem* item) {
    if (!item) return;

    int theType = item->type();

    if (theType == IDriver) {
        // 进入分区根目录
        QString strFullPath = item->text();
        dirCur = QDir(strFullPath);
        ui->lineEditDir->setText(dirCur.absolutePath());
        showItems(dirCur);

    } else if (theType == IFolder) {
        QString strName = item->text();
        if (strName == tr(".")) {
            // 当前目录，无需操作
            return;
        } else if (strName == tr("..")) {
            // 进入上级目录
            on_btnParent_clicked();
            return;
        }
        // 进入子目录
        QString strFullPath = QDir::cleanPath(dirCur.absolutePath() + "/" + strName);
        dirCur = QDir(strFullPath);
        ui->lineEditDir->setText(dirCur.absolutePath());
        showItems(dirCur);

    } else {
        // 打开普通文件
        QString strFilePath = QDir::cleanPath(dirCur.absolutePath() + "/" + item->text());

        // 不是资源文件，打开本地文件
        if (!strFilePath.startsWith(":/")) {
            QDesktopServices::openUrl(QUrl::fromLocalFile(strFilePath));
        }
    }
}

/**
 * @brief 当前列表项改变时，显示详细信息
 */
void Widget::on_listWidget_currentItemChanged(QListWidgetItem* current, QListWidgetItem* previous) {
    Q_UNUSED(previous);
    if (!current) return;

    QString strResult;
    int theType = current->type();
    QString strName = current->text();

    QFileInfo fi;
    if (theType == IDriver) {
        fi = QFileInfo(strName);
        if (strName.startsWith(":/")) {
            strResult = tr("资源根 %1").arg(strName);
        } else {
            strResult = tr("分区根 %1").arg(strName);
        }
    } else if (theType == IFolder) {
        QString strFullPath = QDir::cleanPath(dirCur.absolutePath() + "/" + strName);
        strResult = tr("文件夹 %1\r\n").arg(strFullPath);
        fi = QFileInfo(strFullPath);
        strResult += getFolderInfo(fi);
    } else {
        QString strFilePath = QDir::cleanPath(dirCur.absolutePath() + "/" + strName);
        strResult = tr("文件 %1\r\n").arg(strFilePath);
        fi = QFileInfo(strFilePath);
        strResult += getFileInfo(fi);
    }

    ui->plainTextEditInfo->setPlainText(strResult);
}

/**
 * @brief 获取文件夹详细信息
 * @param fi 文件信息对象
 * @return 格式化的文件夹信息字符串
 */
QString Widget::getFolderInfo(const QFileInfo& fi) {
    QString strResult;

    // 读写权限
    strResult += tr("可读：%1\r\n").arg(fi.isReadable() ? tr("是") : tr("否"));
    strResult += tr("可写：%1\r\n").arg(fi.isWritable() ? tr("是") : tr("否"));

    // 创建时间 & 修改时间 (Qt 5.10及以上支持 birthTime)
#if (QT_VERSION >= QT_VERSION_CHECK(5, 10, 0))
    QDateTime dtCreate = fi.birthTime();
    strResult += tr("创建时间：%1\r\n").arg(dtCreate.toString("yyyy-MM-dd HH:mm:ss"));
#else
    strResult += tr("创建时间：不可用（Qt版本低于5.10）\r\n");
#endif

    QDateTime dtModify = fi.lastModified();
    strResult += tr("修改时间：%1\r\n").arg(dtModify.toString("yyyy-MM-dd HH:mm:ss"));

    return strResult;
}

/**
 * @brief 获取文件详细信息
 * @param fi 文件信息对象
 * @return 格式化的文件信息字符串
 */
QString Widget::getFileInfo(const QFileInfo& fi) {
    QString strResult;

    // 读写及执行权限
    strResult += tr("可读：%1\r\n").arg(fi.isReadable() ? tr("是") : tr("否"));
    strResult += tr("可写：%1\r\n").arg(fi.isWritable() ? tr("是") : tr("否"));
    strResult += tr("可执行：%1\r\n").arg(fi.isExecutable() ? tr("是") : tr("否"));

    // 类型和大小
    strResult += tr("类型：%1\r\n").arg(fi.suffix());
    strResult += tr("大小：%1 B\r\n").arg(fi.size());

#if (QT_VERSION >= QT_VERSION_CHECK(5, 10, 0))
    QDateTime dtCreate = fi.birthTime();
    strResult += tr("创建时间：%1\r\n").arg(dtCreate.toString("yyyy-MM-dd HH:mm:ss"));
#else
    strResult += tr("创建时间：不可用（Qt版本低于5.10）\r\n");
#endif

    QDateTime dtModify = fi.lastModified();
    strResult += tr("修改时间：%1\r\n").arg(dtModify.toString("yyyy-MM-dd HH:mm:ss"));

    return strResult;
}
```

