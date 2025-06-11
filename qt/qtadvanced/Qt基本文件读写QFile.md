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
