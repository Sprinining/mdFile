## 手动编译Qt项目

Qt 6.9.0 的 MinGW 64-bit 控制台环境里，默认会配置好环境变量，包含：

- `moc`
- `uic`
- `rcc`
- `g++`（MinGW 编译器）

直接打开 Qt 控制台（Qt 6.9.0 (MinGW 13.1.0 64-bit) Command Prompt），执行编译命令。

### 目录结构

```css
项目根目录/
├─ main.cpp
├─ wizard.cpp
├─ wizard.h
├─ confirmpage.cpp
├─ confirmpage.h
├─ prosetpage.cpp
├─ prosetpage.h
├─ mainwindow.cpp
├─ mainwindow.h
├─ wizard.ui
├─ confirmpage.ui
├─ prosetpage.ui
├─ mainwindow.ui
├─ icons/
│   ├─ icons.qrc
│   ├─ createpro.png
│   ├─ openpro.png
└─ build/        <--- 进入这里执行命令，生成编译产物
```

### 生成 ui 头文件

```bash
uic ../wizard.ui -o ui_wizard.h
uic ../confirmpage.ui -o ui_confirmpage.h
uic ../prosetpage.ui -o ui_prosetpage.h
uic ../mainwindow.ui -o ui_mainwindow.h
```

- `.ui` 文件是 Qt Designer 设计的界面布局（XML 格式）。

- `uic` 会把 `.ui` 文件转换成对应的 C++ 头文件（例如 `ui_mainwindow.h`），

- 这个头文件里包含了生成界面控件的代码（比如按钮、标签、布局等），方便你在程序里直接用 `ui->setupUi(this)` 来加载界面。

### 生成 moc 文件

```bash
moc ../wizard.h -o moc_wizard.cpp
moc ../confirmpage.h -o moc_confirmpage.cpp
moc ../prosetpage.h -o moc_prosetpage.cpp
moc ../mainwindow.h -o moc_mainwindow.cpp
```

- Qt 的信号槽机制是基于元对象系统（Meta-Object System）。
- 带有 `Q_OBJECT` 宏的类，需要用 `moc` 生成额外的 C++ 源文件（`moc_*.cpp`），
- 这些源文件实现了信号槽连接、运行时类型信息等功能。
- 编译这些 `moc_*.cpp` 文件并链接，才能让信号槽机制正常工作。

### 生成资源文件代码

```bash
rcc ../icons/icons.qrc -o qrc_icons.cpp
```

- `rcc` 是 Qt 的资源编译器（Resource Compiler）。
- 它将 Qt 资源文件 `.qrc`（一个 XML 文件，里面列出了一组资源，比如图片、音频、字体等）编译成一个 C++ 源文件 `qrc_icons.cpp`。
- 生成的 `qrc_icons.cpp` 文件会包含这些资源的二进制数据，并注册到 Qt 的资源系统中。
- 程序编译时把这个 `.cpp` 文件编译进去，就能通过 `:/icons/createpro.png` 这样的路径访问资源，而不用依赖外部文件。
- 简单来说，`rcc` 把资源打包进程序，让程序访问内置资源变得方便且跨平台。

### 编译所有 cpp 文件（包括生成的 moc、ui、qrc 文件）

```bash
g++ -fPIC -std=c++17 ^
    -I"%QTDIR%/include" ^
    -I"%QTDIR%/include/QtWidgets" ^
    -I"%QTDIR%/include/QtGui" ^
    -I"%QTDIR%/include/QtCore" ^
    -I"." ^
    -I".." ^
    -c ../main.cpp ../wizard.cpp ../confirmpage.cpp ../prosetpage.cpp ../mainwindow.cpp ^
       moc_wizard.cpp moc_confirmpage.cpp moc_prosetpage.cpp moc_mainwindow.cpp qrc_icons.cpp
```

- `%QTDIR%` 为 `安装目录\Qt\6.9.0\mingw_64`

### 链接生成可执行文件

```bash
g++ -o myapp.exe main.o wizard.o confirmpage.o prosetpage.o mainwindow.o ^
    moc_wizard.o moc_confirmpage.o moc_prosetpage.o moc_mainwindow.o qrc_icons.o ^
    -L"%QTDIR%/lib" ^
    -lQt6Widgets -lQt6Gui -lQt6Core -lole32 -loleaut32 -luser32 -lgdi32 -lwinmm -lws2_32 -limm32 -lopengl32
```

- 注意：Qt 6 默认库名是 `Qt6Widgets` 而不是 `Qt5Widgets`，请根据你实际 Qt 版本确认库名（`-lQt6Widgets` 或 `-lQt5Widgets`）

### 运行

```bash
.\myapp.exe
```

### 说明

- `-I` 指定头文件目录

- `-L` 指定库文件目录

- `-l` 链接对应的 Qt 库和系统库

- `^` 是 Windows cmd 下的换行符，写成一行时可以去掉换行和 `^`

总体顺序：

```css
1. uic 生成 ui_xxx.h
2. moc 生成 moc_xxx.cpp
3. rcc 生成 qrc_xxx.cpp
4. 编译所有 cpp 为 o 文件
5. 链接生成可执行文件
```

