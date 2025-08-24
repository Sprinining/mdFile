## C++ 文件和流

C++ 的文件和流（File and Stream）是 C++ 标准库中用于输入输出（I/O）的核心机制之一。C++ 提供了一套强大且灵活的类体系来支持文件读写操作，这些类主要定义在 `<fstream>`、`<iostream>` 和 `<sstream>` 等头文件中。

### 流的基础概念

流是一个数据的抽象通道，可以从中读取数据（输入流）或向其中写入数据（输出流）。流的种类包括：

| 类型       | 类名                                             | 用途                 |
| ---------- | ------------------------------------------------ | -------------------- |
| 输入流     | `istream`                                        | 从标准输入读取数据   |
| 输出流     | `ostream`                                        | 向标准输出写入数据   |
| 文件输入流 | `ifstream`                                       | 从文件读取数据       |
| 文件输出流 | `ofstream`                                       | 向文件写入数据       |
| 文件读写流 | `fstream`                                        | 读写同一个文件       |
| 字符串流   | `istringstream`, `ostringstream`, `stringstream` | 用字符串代替输入输出 |

### 文件流的使用

#### 打开文件

```cpp
#include <fstream>
using namespace std;

ifstream fin("input.txt");       // 读取文件
ofstream fout("output.txt");     // 写入文件
fstream fs("data.txt", ios::in | ios::out); // 同时读写文件
```

#### 打开模式（`ios::openmode`）

常用模式如下：

| 模式          | 含义                         |
| ------------- | ---------------------------- |
| `ios::in`     | 读模式                       |
| `ios::out`    | 写模式                       |
| `ios::app`    | 追加模式（写入到末尾）       |
| `ios::ate`    | 初始位置在文件末尾           |
| `ios::trunc`  | 打开时清空文件（默认写模式） |
| `ios::binary` | 二进制模式                   |

组合方式：`ios::in | ios::out | ios::binary`

### 文件流的常见操作

#### 写入文件

```cpp
ofstream fout("example.txt");
if (fout.is_open()) {
    fout << "Hello, file!\n";
    fout << 123 << ' ' << 4.56 << endl;
    fout.close();
}
```

#### 读取文件

```cpp
ifstream fin("example.txt");
string line;
while (getline(fin, line)) {
    cout << line << endl;
}
fin.close();
```

#### 逐词/逐个数据读取

```cpp
ifstream fin("numbers.txt");
int x;
while (fin >> x) {
    cout << "读到: " << x << endl;
}
```

#### 检查文件是否成功打开

```cpp
ifstream fin("data.txt");
if (!fin) {
    cerr << "文件打开失败！" << endl;
}
```

### 流的其他操作

#### 移动文件指针

```cpp
fin.seekg(0);        // 移动到文件开头
fin.seekg(10, ios::beg); // 从开头偏移10个字节
fin.seekg(-5, ios::end); // 从末尾倒数5个字节

streampos pos = fin.tellg(); // 获取当前位置
```

#### 二进制读写

```cpp
ofstream fout("data.bin", ios::binary);
int a = 123;
fout.write((char*)&a, sizeof(a));
fout.close();

ifstream fin("data.bin", ios::binary);
int b;
fin.read((char*)&b, sizeof(b));
cout << "读取的数是: " << b << endl;
fin.close();
```

### 字符串流

用来模拟文件流，但数据存储在内存字符串中，常用于调试或格式化：

```cpp
#include <sstream>
stringstream ss;
ss << "123 45.67 abc";
int a;
double b;
string c;
ss >> a >> b >> c;
cout << a << " " << b << " " << c << endl;
```

### 常见注意事项

- 文件流对象使用完毕应调用 `.close()` 关闭；
- 使用二进制读写时需保证数据结构匹配；
- 字符串流非常适合处理一行数据的拆解；
- 判断是否读到文件结尾：`fin.eof()` 或 `while (fin >> x)`；
- 文件读写失败时应使用 `.fail()` 或 `.good()` 检查流状态。