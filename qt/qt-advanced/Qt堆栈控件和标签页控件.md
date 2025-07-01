## Qt 堆栈控件和标签页控件

### Stacked Widget

`QStackedWidget` 是 Qt 提供的一个用于管理多个“堆叠”子窗口的控件，它能在多个子窗口间切换，但同一时刻只显示一个。通常用于实现多页面界面、向导窗口、或者根据用户操作动态切换视图的场景。

#### 主要特点

- **堆叠多个 QWidget**：将多个 QWidget 添加进来，控件会把它们按顺序堆叠在一起。
- **一次只显示一个子窗口**：通过设置当前索引或子窗口，切换显示。
- **支持动态切换**：可以在运行时自由切换当前显示的子窗口。
- **内置管理索引和指针访问子窗口**。

#### 主要 API

| 方法                                       | 说明                                 |
| ------------------------------------------ | ------------------------------------ |
| `addWidget(QWidget *widget)`               | 添加一个子窗口并返回它在堆栈中的索引 |
| `insertWidget(int index, QWidget *widget)` | 在指定位置插入一个子窗口             |
| `removeWidget(QWidget *widget)`            | 移除子窗口，但不会删除窗口本身       |
| `setCurrentIndex(int index)`               | 设置当前显示的子窗口索引             |
| `setCurrentWidget(QWidget *widget)`        | 设置当前显示的子窗口                 |
| `currentIndex()`                           | 获取当前显示子窗口的索引             |
| `currentWidget()`                          | 获取当前显示的子窗口指针             |
| `count()`                                  | 获取子窗口数量                       |

#### 典型用法示例

```cpp
#include <QApplication>
#include <QStackedWidget>
#include <QPushButton>
#include <QVBoxLayout>
#include <QWidget>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QStackedWidget stackedWidget;

    // 创建第一个页面
    QWidget *page1 = new QWidget;
    QVBoxLayout *layout1 = new QVBoxLayout(page1);
    layout1->addWidget(new QPushButton("按钮 1"));

    // 创建第二个页面
    QWidget *page2 = new QWidget;
    QVBoxLayout *layout2 = new QVBoxLayout(page2);
    layout2->addWidget(new QPushButton("按钮 2"));

    // 添加页面到 QStackedWidget
    stackedWidget.addWidget(page1);
    stackedWidget.addWidget(page2);

    // 默认显示第一个页面
    stackedWidget.setCurrentIndex(0);

    stackedWidget.resize(300, 200);
    stackedWidget.show();

    // 3秒后切换到第二个页面
    QTimer::singleShot(3000, [&stackedWidget]() {
        stackedWidget.setCurrentIndex(1);
    });

    return app.exec();
}
```

#### 使用场景示例

- **向导（Wizard）界面**：逐步引导用户完成操作，每步用一个页面，切换显示。

- **多选项卡替代**：不使用标签页控件，而是通过按钮切换多个视图。

- **复杂界面状态切换**：比如根据用户权限或操作不同，显示不同的界面布局。

### 示例：图片查看和转换

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
  <layout class="QHBoxLayout" name="horizontalLayout_4" stretch="1,5">
   <item>
    <layout class="QVBoxLayout" name="verticalLayout">
     <item>
      <widget class="QPushButton" name="pushButtonOpen">
       <property name="text">
        <string>打开图片</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QListWidget" name="listWidgetIndex">
       <item>
        <property name="text">
         <string>图片预览</string>
        </property>
       </item>
       <item>
        <property name="text">
         <string>图片信息</string>
        </property>
       </item>
       <item>
        <property name="text">
         <string>图片转换</string>
        </property>
       </item>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <widget class="QStackedWidget" name="stackedWidget">
     <property name="currentIndex">
      <number>2</number>
     </property>
     <widget class="QWidget" name="pageView">
      <layout class="QHBoxLayout" name="horizontalLayout">
       <item>
        <widget class="QScrollArea" name="scrollArea">
         <property name="widgetResizable">
          <bool>true</bool>
         </property>
         <widget class="QWidget" name="scrollAreaWidgetContents">
          <property name="geometry">
           <rect>
            <x>0</x>
            <y>0</y>
            <width>241</width>
            <height>291</height>
           </rect>
          </property>
         </widget>
        </widget>
       </item>
      </layout>
     </widget>
     <widget class="QWidget" name="pageInfo">
      <layout class="QHBoxLayout" name="horizontalLayout_2">
       <item>
        <widget class="QTextBrowser" name="textBrowserInfo"/>
       </item>
      </layout>
     </widget>
     <widget class="QWidget" name="pageConvert">
      <layout class="QHBoxLayout" name="horizontalLayout_3">
       <item>
        <widget class="QLabel" name="label">
         <property name="text">
          <string>扩展名类型</string>
         </property>
        </widget>
       </item>
       <item>
        <widget class="QComboBox" name="comboBoxExtFormat"/>
       </item>
       <item>
        <widget class="QPushButton" name="pushButtonConvert">
         <property name="text">
          <string>转换格式</string>
         </property>
        </widget>
       </item>
      </layout>
     </widget>
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

#include <QFileInfo>
#include <QImage>
#include <QImageWriter> //获取转换输出支持的图片格式
#include <QLabel>
#include <QPixmap>
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
    void initControls();

  private slots:
    void on_pushButtonOpen_clicked();

    void on_pushButtonConvert_clicked();

  private:
    Ui::Widget* ui;
    // 图片预览标签
    QLabel* m_pLabelPreview;
    // 图片文件名
    QString m_strImageName;
    // 加载图片对象
    QImage m_image;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDebug>
#include <QFileDialog>
#include <QMessageBox>

// 构造函数，初始化界面和控件
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 绑定 UI 文件设计的界面
    initControls();    // 初始化自定义控件和信号槽
}

// 析构函数，释放 UI 指针
Widget::~Widget() {
    delete ui;
}

// 初始化控件、填充数据、连接信号槽等
void Widget::initControls() {
    // 创建第 0 号标签页的图片预览控件 QLabel
    m_pLabelPreview = new QLabel();
    // 设置 scrollArea 的内容控件为预览标签，这样图片可以滚动显示
    ui->scrollArea->setWidget(m_pLabelPreview);
    // 设置标签背景颜色为浅灰色，便于区分区域
    m_pLabelPreview->setStyleSheet("background-color: lightgray;");

    // 第 1 号标签页，设置文本浏览框显示初始提示信息
    ui->textBrowserInfo->setText(tr("用于显示图片文件信息。"));

    // 第 2 号标签页，填充支持保存的图片格式到组合框
    QList<QByteArray> listTypes = QImageWriter::supportedImageFormats();
    int nCount = listTypes.count();
    for (int i = 0; i < nCount; i++) {
        // 添加支持的图片格式到扩展名下拉列表（组合框）
        ui->comboBoxExtFormat->addItem(listTypes[i]);
    }

    // 连接列表控件 currentRowChanged 信号到 stackedWidget 的 setCurrentIndex 槽函数
    // 当列表当前行变化时，堆叠窗口切换显示对应页面
    connect(ui->listWidgetIndex, &QListWidget::currentRowChanged, ui->stackedWidget, &QStackedWidget::setCurrentIndex);

    // 默认显示堆叠控件第 0 个页面
    ui->stackedWidget->setCurrentIndex(0);
}

// 打开图片按钮槽函数
void Widget::on_pushButtonOpen_clicked() {
    // 弹出文件选择对话框，限制图片格式
    QString strFileName = QFileDialog::getOpenFileName(this, tr("打开图片文件"), "", "Images (*.png *.bmp *.jpg);;All files(*)");

    // 如果没有选择文件则直接返回
    if (strFileName.isEmpty()) return;

    // 尝试加载选中的图片文件
    QImage imgTemp;
    if (!imgTemp.load(strFileName)) {
        // 加载失败弹窗提示
        QMessageBox::warning(this, tr("打开文件失败"), tr("加载图片数据失败，不支持该格式。"));
        return;
    }

    // 加载成功，保存图片路径和图片对象
    m_strImageName = strFileName;
    m_image = imgTemp;

    // 在第 0 号标签页的预览 QLabel 中显示图片
    m_pLabelPreview->setPixmap(QPixmap::fromImage(m_image));

    // 构造文件信息字符串
    QString strInfo = m_strImageName + tr("\r\n");
    strInfo += tr("图片尺寸： %1 x %2\r\n").arg(m_image.width()).arg(m_image.height());
    strInfo += tr("颜色深度： %1\r\n").arg(m_image.depth());

    // 显示文件信息到第 1 号标签页的文本浏览框
    ui->textBrowserInfo->setText(strInfo);
}

// 转换图片格式按钮槽函数
void Widget::on_pushButtonConvert_clicked() {
    // 获取用户选中的新格式扩展名
    QString strNewExt = ui->comboBoxExtFormat->currentText();

    // 判断原文件扩展名是否与目标格式相同（忽略大小写）
    if (m_strImageName.endsWith(strNewExt, Qt::CaseInsensitive)) {
        QMessageBox::warning(this, tr("转换图片格式"), tr("新旧图片扩展名一样，不需要转换。"));
        return;
    }

    // 构造新文件路径（同目录，文件名不变，仅扩展名变）
    QFileInfo fi(m_strImageName);
    QString strNewName = fi.absolutePath() + tr("/") + fi.completeBaseName() + tr(".") + strNewExt;
    qDebug() << strNewName; // 输出调试信息

    // 保存图片为新格式文件
    if (m_image.save(strNewName)) {
        // 成功提示
        QMessageBox::information(this, tr("转换图片格式"), tr("转换成功，新文件为：\r\n") + strNewName);
    } else {
        // 失败提示
        QMessageBox::warning(this, tr("转换图片格式"), tr("转换失败！"));
    }
}
```

### Tab Widget

`QTabWidget` 是 Qt 框架中用于实现多标签页切换界面的控件。它可以让你在同一个窗口中，通过点击不同的标签页切换不同的内容视图，常用于设置界面、多文档界面等场景。

#### 主要特点

- **多页面管理**：每个标签页对应一个 `QWidget` 页面，多个页面统一管理。
- **标签支持文本和图标**：标签页可以设置显示文本，也可以配合图标使用。
- **支持动态添加和移除标签**：运行时可以增删标签页。
- **支持信号与槽**：可监听标签页切换事件，方便动态更新界面。
- **可设置标签页是否可关闭**（Qt 5.6 及以上支持）。

#### 关键类和方法

| 类/成员             | 类型 | 说明                                                         |
| ------------------- | ---- | ------------------------------------------------------------ |
| `QTabWidget`        | 类   | Qt 提供的标签页控件类，管理多个页面（`QWidget`）             |
| `addTab()`          | 方法 | `int addTab(QWidget *widget, const QString &label)`添加一个新标签页，返回索引 |
| `insertTab()`       | 方法 | `int insertTab(int index, QWidget *widget, const QString &label)`在指定位置插入标签页 |
| `removeTab()`       | 方法 | `void removeTab(int index)`删除指定索引的标签页              |
| `setCurrentIndex()` | 方法 | `void setCurrentIndex(int index)`设置当前显示的标签页索引    |
| `currentIndex()`    | 方法 | `int currentIndex() const`获取当前显示标签页的索引           |
| `widget()`          | 方法 | `QWidget* widget(int index) const`获取某一标签页对应的 QWidget |
| `setTabText()`      | 方法 | `void setTabText(int index, const QString &label)`修改标签页的显示文本 |
| `setTabIcon()`      | 方法 | `void setTabIcon(int index, const QIcon &icon)`设置标签页图标 |
| `setTabsClosable()` | 方法 | `void setTabsClosable(bool closable)`是否显示可关闭按钮      |
| `setMovable()`      | 方法 | `void setMovable(bool movable)`设置标签是否可拖动调整顺序    |
| `tabBar()`          | 方法 | `QTabBar* tabBar() const`获取底层标签栏（高级自定义使用）    |

#### 重要信号

| 信号                           | 参数        | 说明                                                    |
| ------------------------------ | ----------- | ------------------------------------------------------- |
| `currentChanged(int index)`    | `int index` | 当前显示的标签页发生变化时触发                          |
| `tabCloseRequested(int index)` | `int index` | 用户点击关闭按钮请求关闭标签页时触发（需开启 closable） |

#### 简单示例

```cpp
#include <QApplication>
#include <QTabWidget>
#include <QLabel>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QTabWidget tabWidget;

    QWidget *page1 = new QWidget;
    QLabel *label1 = new QLabel("这是第一个标签页", page1);

    QWidget *page2 = new QWidget;
    QLabel *label2 = new QLabel("这是第二个标签页", page2);

    tabWidget.addTab(page1, "标签页1");
    tabWidget.addTab(page2, "标签页2");

    tabWidget.resize(400, 300);
    tabWidget.show();

    return app.exec();
}
```

#### 进阶用法

- **设置标签页图标**：

```cpp
tabWidget.setTabIcon(0, QIcon(":/icons/home.png"));
```

- **允许标签页可关闭**：

```cpp
tabWidget.setTabsClosable(true);
QObject::connect(&tabWidget, &QTabWidget::tabCloseRequested, [&](int index){
    tabWidget.removeTab(index);
});
```

- **嵌入复杂控件**：标签页内容不仅限于简单控件，可以是自定义的复杂界面。

### 示例：文件属性

#### tabpreview.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>TabPreview</class>
 <widget class="QWidget" name="TabPreview">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>578</width>
    <height>415</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Form</string>
  </property>
  <layout class="QHBoxLayout" name="horizontalLayout">
   <item>
    <layout class="QVBoxLayout" name="verticalLayout_4">
     <item>
      <widget class="QPushButton" name="pushButtonTextPreview">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Minimum" vsizetype="Expanding">
         <horstretch>0</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
       </property>
       <property name="maximumSize">
        <size>
         <width>52</width>
         <height>16777215</height>
        </size>
       </property>
       <property name="text">
        <string>文
本
预
览</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonImagePreview">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Minimum" vsizetype="Expanding">
         <horstretch>0</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
       </property>
       <property name="maximumSize">
        <size>
         <width>52</width>
         <height>16777215</height>
        </size>
       </property>
       <property name="text">
        <string>图
像
预
览</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonBytePreview">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Minimum" vsizetype="Expanding">
         <horstretch>0</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
       </property>
       <property name="maximumSize">
        <size>
         <width>52</width>
         <height>16777215</height>
        </size>
       </property>
       <property name="text">
        <string>字
节
预
览</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <widget class="QStackedWidget" name="stackedWidget">
     <property name="currentIndex">
      <number>0</number>
     </property>
     <widget class="QWidget" name="pageTextPreview">
      <layout class="QVBoxLayout" name="verticalLayout">
       <property name="leftMargin">
        <number>0</number>
       </property>
       <property name="topMargin">
        <number>0</number>
       </property>
       <property name="rightMargin">
        <number>0</number>
       </property>
       <property name="bottomMargin">
        <number>0</number>
       </property>
       <item>
        <widget class="QTextBrowser" name="textBrowserText"/>
       </item>
      </layout>
     </widget>
     <widget class="QWidget" name="pageImagePreview">
      <layout class="QVBoxLayout" name="verticalLayout_2">
       <property name="leftMargin">
        <number>0</number>
       </property>
       <property name="topMargin">
        <number>0</number>
       </property>
       <property name="rightMargin">
        <number>0</number>
       </property>
       <property name="bottomMargin">
        <number>0</number>
       </property>
       <item>
        <widget class="QLabel" name="labelImagePreview">
         <property name="text">
          <string>图像预览区域</string>
         </property>
         <property name="alignment">
          <set>Qt::AlignmentFlag::AlignCenter</set>
         </property>
        </widget>
       </item>
      </layout>
     </widget>
     <widget class="QWidget" name="pageBytePreview">
      <layout class="QVBoxLayout" name="verticalLayout_3">
       <property name="leftMargin">
        <number>0</number>
       </property>
       <property name="topMargin">
        <number>0</number>
       </property>
       <property name="rightMargin">
        <number>0</number>
       </property>
       <property name="bottomMargin">
        <number>0</number>
       </property>
       <item>
        <widget class="QTextBrowser" name="textBrowserByte"/>
       </item>
      </layout>
     </widget>
    </widget>
   </item>
  </layout>
 </widget>
 <resources/>
 <connections/>
</ui>
```

#### tabpreview.h

```cpp
#ifndef TABPREVIEW_H
#define TABPREVIEW_H

#include <QButtonGroup>
#include <QFile>
#include <QPixmap>
#include <QWidget>

namespace Ui {
class TabPreview;
}

class TabPreview : public QWidget {
    Q_OBJECT

  public:
    explicit TabPreview(QWidget* parent = nullptr); // 构造函数，支持传入父窗口指针，默认空指针
    ~TabPreview();                                  // 析构函数，释放资源
    void initControls();                            // 初始化控件及界面设置

  public slots:
    // 槽函数，响应文件名改变信号，更新预览内容
    void onFileNameChanged(const QString& fileName);

  private:
    Ui::TabPreview* ui;         // 指向 UI 界面对象的指针，由 Qt Designer 生成的类
    QString m_strFileName;      // 用于保存当前预览的文件名
    QButtonGroup m_buttonGroup; // 按钮分组，管理多个互斥的按钮
    QPixmap m_image;            // 用于保存当前加载的预览图像
};

#endif // TABPREVIEW_H
```

#### tabpreview.cpp

```cpp
#include "tabpreview.h"
#include "ui_tabpreview.h"

TabPreview::TabPreview(QWidget* parent) : QWidget(parent), ui(new Ui::TabPreview) {
    ui->setupUi(this);
    initControls(); // 初始化控件，设置按钮组、样式等
}

TabPreview::~TabPreview() {
    delete ui; // 释放 UI 指针资源
}

void TabPreview::initControls() {
    // 设置三个按钮为可切换状态（类似复选框的选中与未选中状态）
    ui->pushButtonTextPreview->setCheckable(true);
    ui->pushButtonImagePreview->setCheckable(true);
    ui->pushButtonBytePreview->setCheckable(true);

    // 按钮分组，分组内按钮互斥（只能选中一个）
    // 为每个按钮分配唯一 ID（0, 1, 2）
    m_buttonGroup.addButton(ui->pushButtonTextPreview, 0);
    m_buttonGroup.addButton(ui->pushButtonImagePreview, 1);
    m_buttonGroup.addButton(ui->pushButtonBytePreview, 2);

    // 绑定按钮分组的点击信号到堆栈控件，切换不同的页面
    connect(&m_buttonGroup, &QButtonGroup::idClicked, ui->stackedWidget, &QStackedWidget::setCurrentIndex);
    // 设置所有被选中按钮的样式，背景色为黄色
    this->setStyleSheet("QPushButton:checked { background-color: yellow }");

    // 设置字节浏览区背景颜色为浅蓝色
    ui->textBrowserByte->setStyleSheet("background-color: #AAEEFF");

    // 设置图片预览标签背景颜色为浅灰色
    ui->labelImagePreview->setStyleSheet("background-color: #E0E0E0");
}

void TabPreview::onFileNameChanged(const QString& fileName) {
    m_strFileName = fileName;
    // 尝试将文件作为图片加载
    bool isImage = m_image.load(m_strFileName);

    if (isImage) {
        // 是图片时，清空文字提示，显示图片
        ui->labelImagePreview->setText("");
        ui->labelImagePreview->setPixmap(m_image);
    } else {
        // 不是图片时，清空显示的图片，显示提示文字
        m_image = QPixmap(); // 清空图片
        ui->labelImagePreview->setPixmap(m_image);
        ui->labelImagePreview->setText(tr("不是支持的图片，无法以图片预览。"));
    }

    // 打开文件，读取前200字节做文本和十六进制预览
    QFile fileIn(m_strFileName);
    if (!fileIn.open(QIODevice::ReadOnly)) {
        // 无法打开文件，打印调试信息
        qDebug() << tr("文件无法打开：") << m_strFileName;
    } else {
        QByteArray baData = fileIn.read(200); // 读取前200字节
        // 转为本地编码的文本显示
        QString strText = QString::fromLocal8Bit(baData);
        ui->textBrowserText->setText(strText);

        // 转为大写十六进制字符串显示
        QString strHex = baData.toHex().toUpper();
        ui->textBrowserByte->setText(strHex);
    }

    // 根据文件类型，默认切换到对应预览页
    if (isImage) {
        // 图片文件，切换到图片预览按钮（触发 clicked 信号）
        ui->pushButtonImagePreview->click();
    } else {
        // 非图片文件
        if (m_strFileName.endsWith(".txt", Qt::CaseInsensitive) || m_strFileName.endsWith(".h", Qt::CaseInsensitive) || m_strFileName.endsWith(".cpp", Qt::CaseInsensitive) ||
            m_strFileName.endsWith(".c", Qt::CaseInsensitive)) {
            // 纯文本相关文件，切换到文本预览页
            ui->pushButtonTextPreview->click();
        } else {
            // 其他文件，切换到字节预览页
            ui->pushButtonBytePreview->click();
        }
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
    <width>416</width>
    <height>267</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <widget class="QTabWidget" name="tabWidget">
     <property name="currentIndex">
      <number>1</number>
     </property>
     <widget class="QWidget" name="tabFileName">
      <attribute name="title">
       <string>文件名称</string>
      </attribute>
      <layout class="QGridLayout" name="gridLayout">
       <item row="0" column="0">
        <widget class="QLabel" name="label">
         <property name="text">
          <string>文件全名</string>
         </property>
        </widget>
       </item>
       <item row="0" column="1">
        <widget class="QLineEdit" name="lineEditFullName"/>
       </item>
       <item row="0" column="2">
        <widget class="QPushButton" name="pushButtonSelectFile">
         <property name="text">
          <string>选择文件</string>
         </property>
        </widget>
       </item>
       <item row="1" column="0">
        <widget class="QLabel" name="label_2">
         <property name="text">
          <string>文件短名</string>
         </property>
        </widget>
       </item>
       <item row="1" column="1">
        <widget class="QLineEdit" name="lineEditShortName"/>
       </item>
       <item row="2" column="0">
        <widget class="QLabel" name="label_3">
         <property name="text">
          <string>文件大小</string>
         </property>
        </widget>
       </item>
       <item row="2" column="1">
        <widget class="QLineEdit" name="lineEditFileSize"/>
       </item>
      </layout>
     </widget>
     <widget class="QWidget" name="tabFileTime">
      <attribute name="title">
       <string>文件时间</string>
      </attribute>
      <layout class="QGridLayout" name="gridLayout_2">
       <item row="0" column="0">
        <widget class="QLabel" name="label_4">
         <property name="text">
          <string>创建时间</string>
         </property>
        </widget>
       </item>
       <item row="0" column="1">
        <widget class="QLineEdit" name="lineEditTimeCreated"/>
       </item>
       <item row="1" column="0">
        <widget class="QLabel" name="label_5">
         <property name="text">
          <string>访问时间</string>
         </property>
        </widget>
       </item>
       <item row="1" column="1">
        <widget class="QLineEdit" name="lineEditTimeRead"/>
       </item>
       <item row="2" column="0">
        <widget class="QLabel" name="label_6">
         <property name="text">
          <string>修改时间</string>
         </property>
        </widget>
       </item>
       <item row="2" column="1">
        <widget class="QLineEdit" name="lineEditTimeModified"/>
       </item>
      </layout>
     </widget>
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

#include "tabpreview.h" // 自定义的文件预览标签页类
#include <QFile>        // 文件操作相关类
#include <QFileDialog>  // 文件选择对话框类
#include <QFileInfo>    // 文件信息类，获取文件大小、路径、时间等属性
#include <QWidget>

QT_BEGIN_NAMESPACE
namespace Ui {
class Widget; // 自动生成的UI类声明
}
QT_END_NAMESPACE

class Widget : public QWidget {
    Q_OBJECT

  public:
    // 构造函数，parent为父窗口指针，默认空指针
    explicit Widget(QWidget* parent = nullptr);

    // 析构函数，负责清理资源
    ~Widget();

  signals:
    // 当文件名发生变化时触发该信号，参数是新的文件名
    void fileNameChanged(const QString& fileName);

  private slots:
    // 按钮点击槽函数，响应“选择文件”按钮的点击事件
    void on_pushButtonSelectFile_clicked();

  private:
    Ui::Widget* ui;            // 界面UI对象指针，由Qt Designer生成和管理
    TabPreview* m_pTabPreview; // 自定义的文件预览标签页指针，用于显示文件预览内容
    QString m_strFileName;     // 保存当前选择的文件全路径
    QFileInfo m_fileInfo;      // QFileInfo对象，用于获取文件详细信息，如大小、修改时间等
};

#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDebug>
#include <QMessageBox>

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);
    // 创建自定义的文件预览标签页对象
    m_pTabPreview = new TabPreview();
    // 将文件预览标签页添加到主界面的 tabWidget 中，标签名称为“文件预览”
    ui->tabWidget->addTab(m_pTabPreview, tr("文件预览"));
    // 连接当前类发出的文件名改变信号与文件预览页接收文件名改变槽函数
    connect(this, &Widget::fileNameChanged, m_pTabPreview, &TabPreview::onFileNameChanged);
}

Widget::~Widget() {
    delete ui; // 释放 UI 对象内存
}

void Widget::on_pushButtonSelectFile_clicked() {
    // 弹出文件选择对话框，允许用户选择任意文件
    QString strName = QFileDialog::getOpenFileName(this, tr("选择文件"), tr(""), tr("All files(*)"));
    strName = strName.trimmed();   // 去除文件名字符串首尾空格
    if (strName.isEmpty()) return; // 如果没有选择文件，直接返回

    // 设置成员变量，保存选择的文件名
    m_strFileName = strName;
    // 使用 QFileInfo 设置当前文件信息对象
    m_fileInfo.setFile(m_strFileName);
    // 获取文件大小（单位：字节）
    qint64 nFileSize = m_fileInfo.size();

    // 更新界面上显示的完整文件路径文本框
    ui->lineEditFullName->setText(m_strFileName);
    // 更新界面上显示的文件名（不带路径）文本框
    ui->lineEditShortName->setText(m_fileInfo.fileName());
    // 更新界面上显示的文件大小文本框，格式为“xxx 字节”
    ui->lineEditFileSize->setText(tr("%1 字节").arg(nFileSize));

    // 获取文件的三个时间属性（创建时间、最后访问时间、最后修改时间），格式化为字符串
    QString strTimeCreated = m_fileInfo.birthTime().toString("yyyy-MM-dd  HH:mm:ss");
    QString strTimeRead = m_fileInfo.lastRead().toString("yyyy-MM-dd  HH:mm:ss");
    QString strTimeModified = m_fileInfo.lastModified().toString("yyyy-MM-dd  HH:mm:ss");

    // 更新界面上显示的文件时间文本框
    ui->lineEditTimeCreated->setText(strTimeCreated);
    ui->lineEditTimeRead->setText(strTimeRead);
    ui->lineEditTimeModified->setText(strTimeModified);

    // 发射信号，通知关联的控件文件名已改变，可以更新预览等操作
    emit fileNameChanged(m_strFileName);
}
```